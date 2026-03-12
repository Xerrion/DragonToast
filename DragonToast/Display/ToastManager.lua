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
local UIParent = UIParent
local CreateFrame = CreateFrame
local LSM = LibStub("LibSharedMedia-3.0")
local L = ns.L
local QueueUtils = ns.QueueUtils
local string_format = string.format

-------------------------------------------------------------------------------
-- State
-------------------------------------------------------------------------------

local activeToasts = {}                        -- currently visible toast frames (ordered, [1] = newest)
local toastQueue = QueueUtils.New()            -- overflow queue (FIFO, O(1) push/pop)
local combatQueue = QueueUtils.New()           -- deferred-during-combat queue (FIFO, O(1) push/pop)
local anchorFrame = nil    -- invisible anchor frame for positioning
local isInitialized = false

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local TOAST_SPACING = 4    -- pixels between toasts
local DUPLICATE_WINDOW = 2 -- seconds to consider same item a duplicate

local DUPLICATE_KIND_ITEM = "item"
local DUPLICATE_KIND_XP = "xp"
local DUPLICATE_KIND_HONOR = "honor"
local DUPLICATE_KIND_REPUTATION = "reputation"
local DUPLICATE_KIND_GOLD = "gold"
local DUPLICATE_KIND_CURRENCY = "currency"
local ANCHOR_FRAME_SIZE = 1
local DRAG_OVERLAY_WIDTH = 120
local DRAG_OVERLAY_HEIGHT = 20
local DRAG_OVERLAY_COLOR = { r = 1, g = 0.82, b = 0, a = 0.5 }
local DEFAULT_ANCHOR_POINT = "RIGHT"
local DEFAULT_ANCHOR_X = -20
local DEFAULT_ANCHOR_Y = 0

local function IsRecentLoot(timestamp, now)
    return timestamp and (now - timestamp) < DUPLICATE_WINDOW
end

local function GetDuplicateKind(existingLootData, incomingLootData)
    if incomingLootData.isXP and existingLootData.isXP then
        return DUPLICATE_KIND_XP
    end

    if incomingLootData.isHonor and existingLootData.isHonor then
        return DUPLICATE_KIND_HONOR
    end

    if incomingLootData.isReputation and existingLootData.isReputation
        and existingLootData.factionName == incomingLootData.factionName then
        return DUPLICATE_KIND_REPUTATION
    end

    if incomingLootData.copperAmount and existingLootData.copperAmount then
        return DUPLICATE_KIND_GOLD
    end

    if incomingLootData.currencyID and existingLootData.currencyID == incomingLootData.currencyID then
        return DUPLICATE_KIND_CURRENCY
    end

    if not incomingLootData.isXP and not existingLootData.isXP
        and not incomingLootData.isHonor and not existingLootData.isHonor
        and not incomingLootData.isReputation and not existingLootData.isReputation
        and not incomingLootData.currencyID and not existingLootData.currencyID
        and existingLootData.itemID == incomingLootData.itemID
        and existingLootData.isSelf == incomingLootData.isSelf then
        return DUPLICATE_KIND_ITEM
    end

    return nil
end

local function ApplyDuplicateStack(targetLootData, incomingLootData, duplicateKind, timestamp)
    if duplicateKind == DUPLICATE_KIND_XP then
        targetLootData.xpAmount = (targetLootData.xpAmount or 0) + (incomingLootData.xpAmount or 0)
        targetLootData.itemName = string_format(L["+%s XP"], ns.ToastManager.FormatNumber(targetLootData.xpAmount))
    elseif duplicateKind == DUPLICATE_KIND_HONOR then
        targetLootData.honorAmount = (targetLootData.honorAmount or 0) + (incomingLootData.honorAmount or 0)
        targetLootData.itemName = string_format(L["+%s Honor"],
            ns.ToastManager.FormatNumber(targetLootData.honorAmount))
    elseif duplicateKind == DUPLICATE_KIND_REPUTATION then
        targetLootData.reputationAmount = (targetLootData.reputationAmount or 0)
            + (incomingLootData.reputationAmount or 0)
        targetLootData.itemName = string_format(L["+%s Reputation"],
            ns.ToastManager.FormatNumber(targetLootData.reputationAmount))
    elseif duplicateKind == DUPLICATE_KIND_GOLD then
        targetLootData.copperAmount = targetLootData.copperAmount + incomingLootData.copperAmount
    elseif duplicateKind == DUPLICATE_KIND_CURRENCY then
        targetLootData.quantity = (targetLootData.quantity or 1) + (incomingLootData.quantity or 1)
    elseif duplicateKind == DUPLICATE_KIND_ITEM then
        targetLootData.quantity = (targetLootData.quantity or 1) + (incomingLootData.quantity or 1)
    end

    if timestamp then
        targetLootData.timestamp = timestamp
    end
end

local function GetQueuedStackTimestamp(duplicateKind, incomingLootData, now)
    if duplicateKind == DUPLICATE_KIND_ITEM then
        return nil
    end

    if duplicateKind == DUPLICATE_KIND_GOLD then
        return incomingLootData.timestamp
    end

    return now
end

local function GetActiveStackTimestamp(duplicateKind)
    if duplicateKind == DUPLICATE_KIND_ITEM or duplicateKind == DUPLICATE_KIND_CURRENCY then
        return nil
    end

    return GetTime()
end

-------------------------------------------------------------------------------
-- Anchor Frame
-------------------------------------------------------------------------------

local function CreateAnchorFrame()
    if anchorFrame then return end

    -- Invisible 1x1 positioning reference -- never shown, never resized
    anchorFrame = CreateFrame("Frame", "DragonToastAnchor", UIParent)
    anchorFrame:SetSize(ANCHOR_FRAME_SIZE, ANCHOR_FRAME_SIZE)
    anchorFrame:SetMovable(true)
    anchorFrame:SetClampedToScreen(true)

    -- Position from saved settings
    local db = ns.Addon.db.profile.display
    anchorFrame:ClearAllPoints()
    anchorFrame:SetPoint(db.anchorPoint, UIParent, db.anchorPoint, db.anchorX, db.anchorY)

    -- Visual drag overlay (child of anchor, HIGH strata so it renders above toasts)
    local overlay = CreateFrame("Frame", nil, anchorFrame)
    overlay:SetSize(DRAG_OVERLAY_WIDTH, DRAG_OVERLAY_HEIGHT)
    overlay:SetPoint("CENTER", anchorFrame, "CENTER")
    overlay:SetFrameStrata("HIGH")
    overlay:SetMovable(true)
    overlay:EnableMouse(false)
    overlay:Hide()

    local dragBg = overlay:CreateTexture(nil, "BACKGROUND")
    dragBg:SetAllPoints()
    dragBg:SetColorTexture(DRAG_OVERLAY_COLOR.r, DRAG_OVERLAY_COLOR.g, DRAG_OVERLAY_COLOR.b, DRAG_OVERLAY_COLOR.a)

    local dragText = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    dragText:SetPoint("CENTER")
    dragText:SetText(L["Drag to move"])

    overlay:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" then
            anchorFrame:StartMoving()
        end
    end)

    overlay:SetScript("OnMouseUp", function()
        anchorFrame:StopMovingOrSizing()
        -- Save position
        local point, _, _, x, y = anchorFrame:GetPoint()
        local displayDb = ns.Addon.db.profile.display
        displayDb.anchorPoint = point
        displayDb.anchorX = x
        displayDb.anchorY = y
    end)

    anchorFrame.overlay = overlay
end

-------------------------------------------------------------------------------
-- Positioning
-------------------------------------------------------------------------------

local function GetToastPosition(index)
    local db = ns.Addon.db.profile.display
    local borderSize = ns.Addon.db.profile.appearance.borderSize or 0
    local spacing = db.toastHeight + (db.spacing or TOAST_SPACING) + borderSize
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
            -- First positioning: hard-set the frame and record logical anchor
            toast._targetY = y
            toast._anchorY = y
            toast:ClearAllPoints()
            toast:SetPoint(point, relativeTo, relativePoint, x, y)
        elseif toast._targetY ~= y then
            -- Skip repositioning for exiting toasts to avoid stale position data
            if not toast._isExiting then
                if toast._isEntering then
                    -- Entrance still playing: defer the slide until entrance finishes.
                    -- Store anchor args so the onFinished callback can issue the catch-up slide.
                    toast._targetY = y
                    toast._deferredSlideArgs = { point, relativeTo, relativePoint, x }
                else
                    -- Normal slide: use logical anchor instead of GetPoint() which
                    -- returns the animated position, not the base position.
                    local currentY = toast._anchorY
                    local startY = currentY or toast._targetY or y
                    toast._targetY = y
                    toast._anchorY = y
                    ns.ToastAnimations.PlaySlide(
                        toast, startY, y, point, relativeTo, relativePoint, x
                    )
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
    if lootData.isCurrency and not lootData.copperAmount and not lootData.currencyID then return nil end

    local now = GetTime()

    -- Search active toasts first
    for i, toast in ipairs(activeToasts) do
        if not toast._isExiting and toast.lootData and IsRecentLoot(toast.lootData.timestamp, now) then
            local duplicateKind = GetDuplicateKind(toast.lootData, lootData)
            if duplicateKind then
                return toast, i, duplicateKind
            end
        end
    end

    -- Search pending queues (toastQueue, then combatQueue)
    local queues = { toastQueue, combatQueue }
    for _, queue in ipairs(queues) do
        for idx = queue.first, queue.last do
            local entry = queue[idx]
            if entry and IsRecentLoot(entry.timestamp, now) then
                local duplicateKind = GetDuplicateKind(entry, lootData)
                if duplicateKind then
                    local timestamp = GetQueuedStackTimestamp(duplicateKind, lootData, now)
                    ApplyDuplicateStack(entry, lootData, duplicateKind, timestamp)
                    return entry, nil, duplicateKind -- nil index signals queued (not active)
                end
            end
        end
    end

    return nil
end

-------------------------------------------------------------------------------
-- Utilities
-------------------------------------------------------------------------------

ns.ToastManager.FormatNumber = ns.FormatNumber

-------------------------------------------------------------------------------
-- Display a Toast
-------------------------------------------------------------------------------

local function ShowToast(lootData)
    local db = ns.Addon.db.profile

    -- Check for duplicate
    local existing, activeIndex, duplicateKind = FindDuplicate(lootData)
    if existing then
        -- nil activeIndex means the duplicate was found in a pending queue
        -- and has already been updated in-place by FindDuplicate
        if activeIndex == nil then return end

        ApplyDuplicateStack(existing.lootData, lootData, duplicateKind, GetActiveStackTimestamp(duplicateKind))
        ns.ToastFrame.Populate(existing, existing.lootData)
        -- Preserve the current lifecycle - stacked active toasts only update content.
        ns.ToastAnimations.UpdateLifecycle(existing, existing.lootData)
        return
    end

    -- Check max visible
    if #activeToasts >= db.display.maxToasts then
        -- Queue for later
        QueueUtils.Push(toastQueue, lootData)
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

ns.ToastManager.ShowToast = ShowToast

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
        and not lootData.isReputation
        and not lootData.isCurrency
        and not lootData.isRollWin then
        return
    end

    -- Combat deferral
    if db.combat.deferInCombat and InCombatLockdown() then
        QueueUtils.Push(combatQueue, lootData)
        return
    end

    ShowToast(lootData)
end

function ns.ToastManager.FlushQueue()
    -- Process overflow queue
    while QueueUtils.Size(toastQueue) > 0 and #activeToasts < ns.Addon.db.profile.display.maxToasts do
        local lootData = QueueUtils.Pop(toastQueue)
        ShowToast(lootData)
    end
end

local function FlushCombatQueue()
    while QueueUtils.Size(combatQueue) > 0 do
        local lootData = QueueUtils.Pop(combatQueue)
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
    ns.TestToasts.StopTestMode()
    -- Cancel all animations and hide all toasts
    for _, toast in ipairs(activeToasts) do
        ns.ToastAnimations.StopAll(toast)
        ns.ToastFrame.Release(toast)
    end
    wipe(activeToasts)
    QueueUtils.Reset(toastQueue)
    QueueUtils.Reset(combatQueue)
end

-------------------------------------------------------------------------------
-- Anchor Lock/Unlock
-------------------------------------------------------------------------------

function ns.ToastManager.ToggleLock()
    if not anchorFrame then return end
    local overlay = anchorFrame.overlay

    if overlay:IsShown() then
        overlay:EnableMouse(false)
        overlay:Hide()
        ns.Print("Anchor " .. ns.COLOR_RED .. "locked" .. ns.COLOR_RESET)
    else
        overlay:EnableMouse(true)
        overlay:Show()
        ns.Print("Anchor " .. ns.COLOR_GREEN .. "unlocked" .. ns.COLOR_RESET
            .. " -- drag to reposition")
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
    db.display.anchorPoint = DEFAULT_ANCHOR_POINT
    db.display.anchorX = DEFAULT_ANCHOR_X
    db.display.anchorY = DEFAULT_ANCHOR_Y
    ns.ToastManager.SetAnchor(DEFAULT_ANCHOR_POINT, DEFAULT_ANCHOR_X, DEFAULT_ANCHOR_Y)
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
        if QueueUtils.Size(combatQueue) > 0 then
            FlushCombatQueue()
        end
    end)

    ns.DebugPrint("ToastManager initialized")
end

-------------------------------------------------------------------------------
-- Test Harness (exposes internals for busted unit tests)
-------------------------------------------------------------------------------

ns.ToastManager._test = {
    -- State references (live tables, not copies)
    activeToasts = activeToasts,
    toastQueue = toastQueue,
    combatQueue = combatQueue,
    -- Internal functions
    FindDuplicate = FindDuplicate,
    ShowToast = ShowToast,
    QueuePush = QueueUtils.Push,
    QueuePop = QueueUtils.Pop,
    QueueSize = QueueUtils.Size,
    QueueReset = QueueUtils.Reset,
    GetToastPosition = GetToastPosition,
    FlushCombatQueue = FlushCombatQueue,
    -- Constants
    DUPLICATE_WINDOW = DUPLICATE_WINDOW,
    TOAST_SPACING = TOAST_SPACING,
}
