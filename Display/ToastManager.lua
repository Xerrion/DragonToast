-------------------------------------------------------------------------------
-- ToastManager.lua
-- Feed management: queue, stacking, positioning, recycling, combat deferral
--
-- Supported versions: TBC Anniversary, Retail
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

-------------------------------------------------------------------------------
-- Cached WoW API
-------------------------------------------------------------------------------

local GetTime = GetTime
local InCombatLockdown = InCombatLockdown
local PlaySoundFile = PlaySoundFile
local UnitName = UnitName
local UIParent = UIParent
local CreateFrame = CreateFrame
local LSM = LibStub("LibSharedMedia-3.0")

-------------------------------------------------------------------------------
-- State
-------------------------------------------------------------------------------

local activeToasts = {}    -- currently visible toast frames (ordered, [1] = newest)
local toastQueue = {}      -- overflow queue (FIFO)
local combatQueue = {}     -- deferred-during-combat queue
local anchorFrame = nil    -- invisible anchor frame for positioning
local isInitialized = false

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local TOAST_SPACING = 4    -- pixels between toasts
local DUPLICATE_WINDOW = 2 -- seconds to consider same item a duplicate

-------------------------------------------------------------------------------
-- Anchor Frame
-------------------------------------------------------------------------------

local function CreateAnchorFrame()
    if anchorFrame then return end

    anchorFrame = CreateFrame("Frame", "DragonToastAnchor", UIParent)
    anchorFrame:SetSize(10, 10)
    anchorFrame:SetMovable(true)
    anchorFrame:SetClampedToScreen(true)
    anchorFrame:Hide()

    -- Position from saved settings
    local db = ns.Addon.db.profile.display
    anchorFrame:ClearAllPoints()
    anchorFrame:SetPoint(db.anchorPoint, UIParent, db.anchorPoint, db.anchorX, db.anchorY)

    -- Drag handle (visible when unlocked)
    anchorFrame.dragBg = anchorFrame:CreateTexture(nil, "BACKGROUND")
    anchorFrame.dragBg:SetAllPoints()
    anchorFrame.dragBg:SetColorTexture(1, 0.82, 0, 0.5) -- gold

    anchorFrame.dragText = anchorFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    anchorFrame.dragText:SetPoint("CENTER")
    anchorFrame.dragText:SetText("DragonToast\nDrag to move")

    anchorFrame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            self:StartMoving()
        end
    end)

    anchorFrame:SetScript("OnMouseUp", function(self)
        self:StopMovingOrSizing()
        -- Save position
        local point, _, _, x, y = self:GetPoint()
        local displayDb = ns.Addon.db.profile.display
        displayDb.anchorPoint = point
        displayDb.anchorX = x
        displayDb.anchorY = y
    end)
end

-------------------------------------------------------------------------------
-- Positioning
-------------------------------------------------------------------------------

local function GetToastPosition(index)
    local db = ns.Addon.db.profile.display
    local spacing = db.toastHeight + (db.spacing or TOAST_SPACING)
    local offset = (index - 1) * spacing

    if db.growDirection == "UP" then
        return "BOTTOMRIGHT", anchorFrame, "BOTTOMRIGHT", 0, offset
    else
        return "TOPRIGHT", anchorFrame, "TOPRIGHT", 0, -offset
    end
end

function ns.ToastManager.UpdatePositions()
    if not isInitialized then return end

    for i, toast in ipairs(activeToasts) do
        local point, relativeTo, relativePoint, x, y = GetToastPosition(i)

        if toast._isEntering then
            -- Toast is mid-entrance animation; update its final target coordinates
            -- The OnUpdate in PlayEntrance reads these each frame
            toast._entranceFinalX = x
            toast._entranceFinalY = y
        else
            -- Capture old position for smooth sliding
            local oldY = 0
            local _, _, _, _, prevY = toast:GetPoint()
            if prevY then
                oldY = prevY
            end

            -- Capture remaining slide displacement before stopping
            local slideRemainingY = 0
            if toast:IsShown() and toast._slideTranslation
                and toast.animGroups.slide:IsPlaying() then
                local progress = toast._slideTranslation:GetSmoothProgress()
                local _, oldOffsetY = toast._slideTranslation:GetOffset()
                slideRemainingY = oldOffsetY * (1 - progress)
            end

            toast:ClearAllPoints()
            toast:SetPoint(point, relativeTo, relativePoint, x, y)

            -- Animate existing (visible) toasts to new position
            if toast:IsShown() and prevY and prevY ~= y then
                local deltaY = (oldY - y) + slideRemainingY
                if math.abs(deltaY) > 0.5 then
                    ns.ToastAnimations.PlaySlide(toast, 0, deltaY)
                end
            end
        end
    end
end

function ns.ToastManager.UpdateLayout()
    if not isInitialized then return end

    local db = ns.Addon.db.profile
    for _, toast in ipairs(activeToasts) do
        toast:SetSize(db.display.toastWidth, db.display.toastHeight)
        if toast.icon then
            toast.icon:SetSize(db.appearance.iconSize, db.appearance.iconSize)
        end
        -- Re-populate to apply font/color changes
        if toast.lootData then
            ns.ToastFrame.Populate(toast, toast.lootData)
        end
    end
    ns.ToastManager.UpdatePositions()
end

-------------------------------------------------------------------------------
-- Duplicate Detection
-------------------------------------------------------------------------------

local function FindDuplicate(lootData)
    if lootData.isCurrency then return nil end

    local now = GetTime()
    for i, toast in ipairs(activeToasts) do
        if toast.lootData and (now - toast.lootData.timestamp) < DUPLICATE_WINDOW then
            -- XP toast stacking: merge consecutive XP gains
            if lootData.isXP and toast.lootData.isXP then
                return toast, i
            end

            -- Normal item stacking
            if not lootData.isXP and not toast.lootData.isXP
                and toast.lootData.itemID == lootData.itemID
                and toast.lootData.isSelf == lootData.isSelf then
                return toast, i
            end
        end
    end
    return nil
end

-------------------------------------------------------------------------------
-- Fade Timer
-------------------------------------------------------------------------------

local function StartFadeTimer(toast)
    local db = ns.Addon.db.profile
    local holdDuration = db.animation.holdDuration

    -- Cancel existing timer (CancelTimer is a no-op if handle is nil)
    ns.Addon:CancelTimer(toast.fadeTimer)
    toast.fadeTimer = nil

    toast.fadeTimerStart = GetTime()
    toast.fadeTimerRemaining = holdDuration

    toast.fadeTimer = ns.Addon:ScheduleTimer(function()
        if toast.isHovered then
            -- Don't fade while hovered; ResumeFadeTimer will handle it
            return
        end
        ns.ToastAnimations.PlayExit(toast)
    end, holdDuration)
end

function ns.ToastManager.ResumeFadeTimer(toast)
    if not toast.fadeTimerStart then return end

    -- Calculate remaining time
    local elapsed = GetTime() - toast.fadeTimerStart
    local remaining = (toast.fadeTimerRemaining or ns.Addon.db.profile.animation.holdDuration) - elapsed

    if remaining <= 0 then
        -- Time already expired, start exit now
        ns.ToastAnimations.PlayExit(toast)
        return
    end

    -- Cancel old timer and start new one with remaining time
    ns.Addon:CancelTimer(toast.fadeTimer)

    toast.fadeTimer = ns.Addon:ScheduleTimer(function()
        if toast.isHovered then return end
        ns.ToastAnimations.PlayExit(toast)
    end, remaining)
end

-------------------------------------------------------------------------------
-- Utilities
-------------------------------------------------------------------------------

function ns.ToastManager.FormatNumber(num)
    if num >= 1000000 then
        return string.format("%.1fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.1fK", num / 1000)
    end
    return tostring(num)
end

-------------------------------------------------------------------------------
-- Display a Toast
-------------------------------------------------------------------------------

local function ShowToast(lootData)
    local db = ns.Addon.db.profile

    -- Check for duplicate
    local existing = FindDuplicate(lootData)
    if existing then
        if lootData.isXP then
            -- Stack XP: sum amounts and update display name
            existing.lootData.xpAmount = (existing.lootData.xpAmount or 0) + (lootData.xpAmount or 0)
            existing.lootData.itemName = "+" .. ns.ToastManager.FormatNumber(existing.lootData.xpAmount) .. " XP"
            existing.lootData.timestamp = GetTime()
        else
            -- Increment quantity on existing toast
            existing.lootData.quantity = (existing.lootData.quantity or 1) + (lootData.quantity or 1)
        end
        ns.ToastFrame.Populate(existing, existing.lootData)
        -- Reset fade timer
        StartFadeTimer(existing)
        return
    end

    -- Check max visible
    if #activeToasts >= db.display.maxToasts then
        -- Queue for later
        table.insert(toastQueue, lootData)
        return
    end

    -- Acquire and populate a frame
    local toast = ns.ToastFrame.Acquire()
    ns.ToastFrame.Populate(toast, lootData)

    -- Insert at position 1 (newest on top/bottom)
    table.insert(activeToasts, 1, toast)

    -- Position all toasts
    ns.ToastManager.UpdatePositions()

    -- Play entrance animation
    ns.ToastAnimations.PlayEntrance(toast)

    -- Start fade timer
    StartFadeTimer(toast)

    -- Play sound if enabled
    if db.sound.enabled and db.sound.soundFile and db.sound.soundFile ~= "None" then
        local soundPath = LSM:Fetch("sound", db.sound.soundFile)
        if soundPath then
            PlaySoundFile(soundPath, "SFX")
        end
    end
end

-------------------------------------------------------------------------------
-- Queue Management
-------------------------------------------------------------------------------

function ns.ToastManager.QueueToast(lootData)
    if not isInitialized then return end

    local db = ns.Addon.db.profile
    if not db.enabled then return end

    -- Combat deferral
    if db.combat.deferInCombat and InCombatLockdown() then
        table.insert(combatQueue, lootData)
        return
    end

    ShowToast(lootData)
end

function ns.ToastManager.FlushQueue()
    -- Process overflow queue
    while #toastQueue > 0 and #activeToasts < ns.Addon.db.profile.display.maxToasts do
        local lootData = table.remove(toastQueue, 1)
        ShowToast(lootData)
    end
end

local function FlushCombatQueue()
    for _, lootData in ipairs(combatQueue) do
        ns.ToastManager.QueueToast(lootData)
    end
    wipe(combatQueue)
end

-------------------------------------------------------------------------------
-- Dismiss / Recycle
-------------------------------------------------------------------------------

function ns.ToastManager.DismissToast(toast)
    -- Cancel fade timer
    ns.Addon:CancelTimer(toast.fadeTimer)
    toast.fadeTimer = nil

    -- Play exit animation (which calls OnToastFinished when done)
    ns.ToastAnimations.PlayExit(toast)
end

function ns.ToastManager.OnToastFinished(toast)
    -- Remove from active list
    for i, t in ipairs(activeToasts) do
        if t == toast then
            table.remove(activeToasts, i)
            break
        end
    end

    -- Safety: cancel any pending fade timer before releasing
    if toast.fadeTimer then
        ns.Addon:CancelTimer(toast.fadeTimer)
        toast.fadeTimer = nil
    end

    -- Release frame back to pool
    ns.ToastAnimations.StopAll(toast)
    ns.ToastFrame.Release(toast)

    -- Reposition remaining toasts
    ns.ToastManager.UpdatePositions()

    -- Process queue
    ns.ToastManager.FlushQueue()
end

function ns.ToastManager.ClearAll()
    -- Cancel all fade timers and hide all toasts
    for _, toast in ipairs(activeToasts) do
        ns.Addon:CancelTimer(toast.fadeTimer)
        toast.fadeTimer = nil
        ns.ToastAnimations.StopAll(toast)
        ns.ToastFrame.Release(toast)
    end
    wipe(activeToasts)
    wipe(toastQueue)
    wipe(combatQueue)
end

-------------------------------------------------------------------------------
-- Test Toast
-------------------------------------------------------------------------------

local testCounter = 0

function ns.ToastManager.ShowTestToast()
    testCounter = testCounter + 1

    -- Create a fake loot entry for testing
    local testItems = {
        { name = "Warglaive of Azzinoth", quality = 5, level = 156, type = "Weapon", subType = "Sword",
          icon = 135562, id = 32837 },
        { name = "Bulwark of Azzinoth", quality = 4, level = 154, type = "Armor", subType = "Shield",
          icon = 132351, id = 32375 },
        { name = "Tier 6 Helm Token", quality = 4, level = 154, type = "Miscellaneous", subType = "Junk",
          icon = 134240, id = 31097 },
        { name = "Nethervoid Cloak", quality = 4, level = 141, type = "Armor", subType = "Cloth",
          icon = 133772, id = 32331 },
        { name = "Pattern: Sunfire Robe", quality = 4, level = 75, type = "Recipe", subType = "Tailoring",
          icon = 132744, id = 32754 },
        { name = "+1,234 XP", quality = 1, level = 0, type = nil, subType = nil,
          icon = 894556, id = 99999, isXP = true, xpAmount = 1234 },
    }

    local test = testItems[math.random(#testItems)]

    local lootData
    if test.isXP then
        lootData = {
            isXP = true,
            xpAmount = test.xpAmount + math.random(0, 500),
            mobName = (math.random(2) == 1) and "Test Creature" or nil,
            itemIcon = test.icon,
            itemName = "+" .. ns.ToastManager.FormatNumber(test.xpAmount + math.random(0, 500)) .. " XP",
            itemQuality = test.quality,
            itemLevel = 0,
            quantity = 1,
            looter = UnitName("player") or "TestPlayer",
            isSelf = true,
            isCurrency = false,
            timestamp = GetTime(),
        }
    else
        lootData = {
            itemLink = "|cff" .. (test.quality == 5 and "ff8000" or "a335ee") .. "|Hitem:" .. test.id
                .. "::::::::70::::::|h[" .. test.name .. "]|h|r" .. testCounter,
            itemID = test.id + testCounter * 100000,
            itemName = test.name,
            itemQuality = test.quality,
            itemLevel = test.level,
            itemType = test.type,
            itemSubType = test.subType,
            itemIcon = test.icon,
            quantity = math.random(1, 3),
            looter = UnitName("player") or "TestPlayer",
            isSelf = true,
            isCurrency = false,
            timestamp = GetTime(),
        }
    end

    ShowToast(lootData)
end

-------------------------------------------------------------------------------
-- Anchor Lock/Unlock
-------------------------------------------------------------------------------

function ns.ToastManager.ToggleLock()
    if not anchorFrame then return end

    if anchorFrame:IsShown() then
        anchorFrame:EnableMouse(false)
        anchorFrame:SetSize(10, 10) -- Reset to default size
        anchorFrame:Hide()
        ns.Print("Anchor " .. ns.COLOR_RED .. "locked" .. ns.COLOR_RESET)
    else
        anchorFrame:SetSize(200, 50)
        anchorFrame:EnableMouse(true)
        anchorFrame:Show()
        ns.Print("Anchor " .. ns.COLOR_GREEN .. "unlocked" .. ns.COLOR_RESET .. " — drag to reposition")
    end
end

function ns.ToastManager.SetAnchor(point, x, y)
    if not anchorFrame then return end
    local db = ns.Addon.db.profile.display
    db.anchorPoint = point
    db.anchorX = x
    db.anchorY = y
    anchorFrame:ClearAllPoints()
    anchorFrame:SetPoint(point, UIParent, point, x, y)
    ns.ToastManager.UpdatePositions()
end

function ns.ToastManager.ResetAnchor()
    local db = ns.Addon.db.profile
    db.display.anchorPoint = "RIGHT"
    db.display.anchorX = -20
    db.display.anchorY = 0
    ns.ToastManager.SetAnchor("RIGHT", -20, 0)
    ns.Print("Anchor position reset to default.")
end

-------------------------------------------------------------------------------
-- Initialize
-------------------------------------------------------------------------------

function ns.ToastManager.Initialize()
    if isInitialized then return end

    CreateAnchorFrame()
    isInitialized = true

    -- Register for combat end to flush deferred queue
    ns.Addon:RegisterEvent("PLAYER_REGEN_ENABLED", function()
        if #combatQueue > 0 then
            FlushCombatQueue()
        end
    end)

    ns.DebugPrint("ToastManager initialized")
end
