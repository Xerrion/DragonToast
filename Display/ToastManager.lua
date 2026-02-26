-------------------------------------------------------------------------------
-- ToastManager.lua
-- Feed management: queue, stacking, positioning, recycling, combat deferral
--
-- Supported versions: TBC Anniversary, Retail, MoP Classic
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

local activeToasts = {}                        -- currently visible toast frames (ordered, [1] = newest)
local toastQueue = { first = 1, last = 0 }     -- overflow queue (FIFO, O(1) push/pop)
local combatQueue = { first = 1, last = 0 }    -- deferred-during-combat queue (FIFO, O(1) push/pop)
local anchorFrame = nil    -- invisible anchor frame for positioning
local isInitialized = false

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local TOAST_SPACING = 4    -- pixels between toasts
local DUPLICATE_WINDOW = 2 -- seconds to consider same item a duplicate

-------------------------------------------------------------------------------
-- Queue Helpers (O(1) push / pop / size)
-------------------------------------------------------------------------------

local function QueuePush(queue, item)
    queue.last = queue.last + 1
    queue[queue.last] = item
end

local function QueuePop(queue)
    if queue.first > queue.last then return nil end
    local item = queue[queue.first]
    queue[queue.first] = nil
    queue.first = queue.first + 1
    return item
end

local function QueueSize(queue)
    return queue.last - queue.first + 1
end

local function QueueReset(queue)
    for i = queue.first, queue.last do
        queue[i] = nil
    end
    queue.first = 1
    queue.last = 0
end

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

        if toast._targetY == nil then
            toast._targetY = y
            toast:ClearAllPoints()
            toast:SetPoint(point, relativeTo, relativePoint, x, y)
        elseif toast._targetY ~= y then
            local _, _, _, _, currentY = toast:GetPoint()
            local startY = currentY or toast._targetY or y
            toast._targetY = y
            ns.ToastAnimations.PlaySlide(
                toast, startY, y, point, relativeTo, relativePoint, x
            )
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

    -- Search active toasts first
    for i, toast in ipairs(activeToasts) do
        if toast.lootData and (now - toast.lootData.timestamp) < DUPLICATE_WINDOW then
            -- XP/honor toast stacking: merge consecutive XP or honor gains
            if lootData.isXP and toast.lootData.isXP then
                return toast, i
            elseif lootData.isHonor and toast.lootData.isHonor then
                return toast, i
            end

            -- Normal item stacking
            if not lootData.isXP and not toast.lootData.isXP
                and not lootData.isHonor and not toast.lootData.isHonor
                and toast.lootData.itemID == lootData.itemID
                and toast.lootData.isSelf == lootData.isSelf then
                return toast, i
            end
        end
    end

    -- Search pending queues (toastQueue, then combatQueue)
    local queues = { toastQueue, combatQueue }
    for _, queue in ipairs(queues) do
        for idx = queue.first, queue.last do
            local entry = queue[idx]
            if entry and (now - entry.timestamp) < DUPLICATE_WINDOW then
                if lootData.isXP and entry.isXP then
                    -- Stack XP in-place
                    entry.xpAmount = (entry.xpAmount or 0) + (lootData.xpAmount or 0)
                    entry.itemName = "+" .. ns.ToastManager.FormatNumber(entry.xpAmount) .. " XP"
                    entry.timestamp = now
                    return entry, nil -- nil index signals queued (not active)
                elseif lootData.isHonor and entry.isHonor then
                    entry.honorAmount = (entry.honorAmount or 0) + (lootData.honorAmount or 0)
                    entry.itemName = "+" .. ns.ToastManager.FormatNumber(entry.honorAmount) .. " Honor"
                    entry.timestamp = now
                    return entry, nil -- nil index signals queued (not active)
                end

                if not lootData.isXP and not entry.isXP
                    and not lootData.isHonor and not entry.isHonor
                    and entry.itemID == lootData.itemID
                    and entry.isSelf == lootData.isSelf then
                    -- Stack quantity in-place
                    entry.quantity = (entry.quantity or 1) + (lootData.quantity or 1)
                    return entry, nil
                end
            end
        end
    end

    return nil
end

-------------------------------------------------------------------------------
-- Utilities (delegates to shared ns.FormatNumber)
-------------------------------------------------------------------------------

ns.ToastManager.FormatNumber = function(num)
    return ns.FormatNumber(num)
end

-------------------------------------------------------------------------------
-- Display a Toast
-------------------------------------------------------------------------------

local function ShowToast(lootData)
    local db = ns.Addon.db.profile

    -- Check for duplicate
    local existing, activeIndex = FindDuplicate(lootData)
    if existing then
        -- nil activeIndex means the duplicate was found in a pending queue
        -- and has already been updated in-place by FindDuplicate
        if activeIndex == nil then return end

        if lootData.isXP then
            -- Stack XP: sum amounts and update display name
            existing.lootData.xpAmount = (existing.lootData.xpAmount or 0) + (lootData.xpAmount or 0)
            existing.lootData.itemName = "+" .. ns.ToastManager.FormatNumber(existing.lootData.xpAmount) .. " XP"
            existing.lootData.timestamp = GetTime()
        elseif lootData.isHonor then
            existing.lootData.honorAmount = (existing.lootData.honorAmount or 0) + (lootData.honorAmount or 0)
            existing.lootData.itemName = "+" .. ns.ToastManager.FormatNumber(existing.lootData.honorAmount) .. " Honor"
            existing.lootData.timestamp = GetTime()
        else
            -- Increment quantity on existing toast
            existing.lootData.quantity = (existing.lootData.quantity or 1) + (lootData.quantity or 1)
        end
        ns.ToastFrame.Populate(existing, existing.lootData)
        -- Update the running lifecycle without restarting from scratch
        ns.ToastAnimations.UpdateLifecycle(existing, existing.lootData)
        return
    end

    -- Check max visible
    if #activeToasts >= db.display.maxToasts then
        -- Queue for later
        QueuePush(toastQueue, lootData)
        return
    end

    -- Acquire and populate a frame
    local toast = ns.ToastFrame.Acquire()
    ns.ToastFrame.Populate(toast, lootData)

    -- Insert at position 1 (newest on top/bottom)
    table.insert(activeToasts, 1, toast)

    -- Position all toasts
    ns.ToastManager.UpdatePositions()

    -- Play full toast lifecycle (entrance -> hold -> exit)
    ns.ToastAnimations.PlayLifecycle(toast, lootData)

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

    -- Suppress normal item toasts while any source has active suppression
    if ns.MessageBridge.IsSuppressed()
        and not lootData.isXP
        and not lootData.isHonor
        and not lootData.isCurrency
        and not lootData.isRollWin then
        return
    end

    -- Combat deferral
    if db.combat.deferInCombat and InCombatLockdown() then
        QueuePush(combatQueue, lootData)
        return
    end

    ShowToast(lootData)
end

function ns.ToastManager.FlushQueue()
    -- Process overflow queue
    while QueueSize(toastQueue) > 0 and #activeToasts < ns.Addon.db.profile.display.maxToasts do
        local lootData = QueuePop(toastQueue)
        ShowToast(lootData)
    end
end

local function FlushCombatQueue()
    while QueueSize(combatQueue) > 0 do
        local lootData = QueuePop(combatQueue)
        ns.ToastManager.QueueToast(lootData)
    end
end

-------------------------------------------------------------------------------
-- Dismiss / Recycle
-------------------------------------------------------------------------------

function ns.ToastManager.DismissToast(toast)
    ns.ToastAnimations.Dismiss(toast)
end

function ns.ToastManager.OnToastFinished(toast)
    -- Remove from active list
    for i, t in ipairs(activeToasts) do
        if t == toast then
            table.remove(activeToasts, i)
            break
        end
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
    ns.ToastManager.StopTestMode()
    -- Cancel all animations and hide all toasts
    for _, toast in ipairs(activeToasts) do
        ns.ToastAnimations.StopAll(toast)
        ns.ToastFrame.Release(toast)
    end
    wipe(activeToasts)
    QueueReset(toastQueue)
    QueueReset(combatQueue)
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
        { name = "Gold Loot", quality = 1, level = 0, type = "Currency", subType = "Gold",
          icon = 133784, id = 99998, isMoney = true, copperAmount = 12345 },
        { name = "+1,234 XP", quality = 1, level = 0, type = nil, subType = nil,
          icon = 894556, id = 99999, isXP = true, xpAmount = 1234 },
        { name = "+150 Honor", quality = 1, level = 0, type = nil, subType = nil,
          icon = 1455894, id = 99997, isHonor = true, honorAmount = 150, victimName = "Enemy Player" },
    }

    local test = testItems[math.random(#testItems)]

    local lootData
    if test.isXP then
        local amount = test.xpAmount + math.random(0, 500)
        lootData = {
            isXP = true,
            xpAmount = amount,
            mobName = (math.random(2) == 1) and "Test Creature" or nil,
            itemIcon = test.icon,
            itemName = "+" .. ns.ToastManager.FormatNumber(amount) .. " XP",
            itemQuality = test.quality,
            itemLevel = 0,
            quantity = 1,
            looter = UnitName("player") or "TestPlayer",
            isSelf = true,
            isCurrency = false,
            timestamp = GetTime(),
        }
    elseif test.isHonor then
        local amount = test.honorAmount + math.random(0, 100)
        lootData = {
            isHonor = true,
            honorAmount = amount,
            victimName = test.victimName,
            itemIcon = test.icon,
            itemName = "+" .. ns.ToastManager.FormatNumber(amount) .. " Honor",
            itemQuality = test.quality,
            itemLevel = 0,
            itemType = nil,
            itemSubType = nil,
            quantity = 1,
            looter = UnitName("player") or "TestPlayer",
            isSelf = true,
            isCurrency = false,
            timestamp = GetTime(),
        }
    elseif test.isMoney then
        lootData = {
            itemLink = nil,
            itemID = nil,
            copperAmount = test.copperAmount,
            itemName = GetCoinTextureString(test.copperAmount),
            itemQuality = test.quality,
            itemLevel = test.level,
            itemType = test.type,
            itemSubType = test.subType,
            itemIcon = test.icon,
            quantity = 1,
            looter = UnitName("player") or "TestPlayer",
            isSelf = true,
            isCurrency = true,
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
-- Test Mode (continuous toast generation)
-------------------------------------------------------------------------------

local testModeTimer = nil

function ns.ToastManager.IsTestModeActive()
    return testModeTimer ~= nil
end

function ns.ToastManager.StartTestMode()
    if testModeTimer then return end -- already running

    -- Fire one immediately
    ns.ToastManager.ShowTestToast()

    -- Schedule repeating timer
    testModeTimer = ns.Addon:ScheduleRepeatingTimer(function()
        ns.ToastManager.ShowTestToast()
    end, 2.5)

    ns.Print("Test mode " .. ns.COLOR_GREEN .. "started" .. ns.COLOR_RESET .. " — toasts will keep appearing.")
end

function ns.ToastManager.StopTestMode()
    if not testModeTimer then return end

    ns.Addon:CancelTimer(testModeTimer)
    testModeTimer = nil

    ns.Print("Test mode " .. ns.COLOR_RED .. "stopped" .. ns.COLOR_RESET)
end

function ns.ToastManager.ToggleTestMode()
    if testModeTimer then
        ns.ToastManager.StopTestMode()
    else
        ns.ToastManager.StartTestMode()
    end
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
        if QueueSize(combatQueue) > 0 then
            FlushCombatQueue()
        end
    end)

    ns.DebugPrint("ToastManager initialized")
end
