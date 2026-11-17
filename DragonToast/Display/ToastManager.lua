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
local flushStaggerTimer = nil  -- single pending admission timer
local admissionPending = false -- reserve the entry row before revealing a toast
local nextAdmissionTime = 0
local layoutSpacing, layoutDirection
local ScheduleFlush
local POSITION_EPSILON = 0.00001

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local TOAST_SPACING = 8    -- pixels between toasts
local DUPLICATE_WINDOW = 2 -- seconds to consider same item a duplicate

local DUPLICATE_KIND_ITEM = "item"
local DUPLICATE_KIND_XP = "xp"
local DUPLICATE_KIND_HONOR = "honor"
local DUPLICATE_KIND_REPUTATION = "reputation"
local DUPLICATE_KIND_GOLD_GAIN = "goldGain"
local DUPLICATE_KIND_GOLD_LOSS = "goldLoss"
local DUPLICATE_KIND_CURRENCY = "currency"
local ANCHOR_FRAME_SIZE = 1
local DRAG_OVERLAY_WIDTH = 120
local DRAG_OVERLAY_HEIGHT = 20
local DRAG_OVERLAY_COLOR = { r = 1, g = 0.82, b = 0, a = 0.5 }
local DEFAULT_ANCHOR_POINT = "RIGHT"
local DEFAULT_ANCHOR_X = -20
local DEFAULT_ANCHOR_Y = 0

local function NormalizeReputationDirection(direction)
    return direction == "loss" and "loss" or "gain"
end

local function IsRecentLoot(timestamp, now)
    return timestamp and (now - timestamp) < DUPLICATE_WINDOW
end

local function GetDuplicateKind(existingLootData, incomingLootData)
    -- Mass-loot previews keep real item metadata but each occupies its own
    -- toast. Ordinary loot has no test identity and retains normal stacking.
    if existingLootData._testToastID ~= incomingLootData._testToastID then return nil end

    if incomingLootData.isXP and existingLootData.isXP then
        return DUPLICATE_KIND_XP
    end

    if incomingLootData.isHonor and existingLootData.isHonor then
        return DUPLICATE_KIND_HONOR
    end

    if incomingLootData.isReputation and existingLootData.isReputation
        and NormalizeReputationDirection(existingLootData.reputationDirection)
            == NormalizeReputationDirection(incomingLootData.reputationDirection) then
        if existingLootData.factionID and incomingLootData.factionID then
            if existingLootData.factionID == incomingLootData.factionID then return DUPLICATE_KIND_REPUTATION end
        elseif existingLootData.factionName == incomingLootData.factionName then
            return DUPLICATE_KIND_REPUTATION
        end
    end

    if incomingLootData.copperAmount and existingLootData.copperAmount then
        local incomingDirection = incomingLootData.moneyDirection or "gain"
        local existingDirection = existingLootData.moneyDirection or "gain"
        if incomingDirection == existingDirection then
            return incomingDirection == "loss" and DUPLICATE_KIND_GOLD_LOSS or DUPLICATE_KIND_GOLD_GAIN
        end
    end

    if incomingLootData.currencyID and existingLootData.currencyID == incomingLootData.currencyID then
        return DUPLICATE_KIND_CURRENCY
    end

    if not incomingLootData.isXP and not existingLootData.isXP
        and not incomingLootData.isHonor and not existingLootData.isHonor
        and not incomingLootData.isReputation and not existingLootData.isReputation
        and not incomingLootData.copperAmount and not existingLootData.copperAmount
        and not incomingLootData.currencyID and not existingLootData.currencyID
        and existingLootData.itemID == incomingLootData.itemID
        and existingLootData.isSelf == incomingLootData.isSelf then
        return DUPLICATE_KIND_ITEM
    end

    return nil
end

-- Merges an incoming loot entry into an existing target entry by aggregating amounts and updating display fields.
-- @param targetLootData Table to be updated in-place with aggregated
--   values (e.g., quantities, amounts, itemName, timestamp).
-- @param incomingLootData Table containing the new loot values to merge into targetLootData.
-- @param duplicateKind Identifier of the duplicate category; one of
--   DUPLICATE_KIND_XP, DUPLICATE_KIND_HONOR, DUPLICATE_KIND_REPUTATION,
--   DUPLICATE_KIND_GOLD_GAIN, DUPLICATE_KIND_GOLD_LOSS,
--   DUPLICATE_KIND_CURRENCY, or
--   DUPLICATE_KIND_ITEM. Determines which fields are aggregated and
--   whether the display name is updated.
-- @param timestamp Optional numeric time value to assign to
--   targetLootData.timestamp; if provided, it replaces the existing
--   timestamp.
local function ApplyDuplicateStack(targetLootData, incomingLootData, duplicateKind, timestamp)
    if duplicateKind == DUPLICATE_KIND_XP then
        targetLootData.xpAmount = (targetLootData.xpAmount or 0) + (incomingLootData.xpAmount or 0)
        targetLootData.itemName = string_format(L["+%s XP"],
            ns.ToastManager.FormatNumber(targetLootData.xpAmount))
    elseif duplicateKind == DUPLICATE_KIND_HONOR then
        targetLootData.honorAmount = (targetLootData.honorAmount or 0) + (incomingLootData.honorAmount or 0)
        targetLootData.itemName = string_format(L["+%s Honor"],
            ns.ToastManager.FormatNumber(targetLootData.honorAmount))
    elseif duplicateKind == DUPLICATE_KIND_REPUTATION then
        targetLootData.reputationAmount = (targetLootData.reputationAmount or 0)
            + (incomingLootData.reputationAmount or 0)
        local direction = NormalizeReputationDirection(targetLootData.reputationDirection)
        targetLootData.reputationDirection = direction
        local label = direction == "loss" and L["-%s Reputation"] or L["+%s Reputation"]
        targetLootData.itemName = string_format(label,
            ns.ToastManager.FormatNumber(targetLootData.reputationAmount))
    elseif duplicateKind == DUPLICATE_KIND_GOLD_GAIN or duplicateKind == DUPLICATE_KIND_GOLD_LOSS then
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

    if duplicateKind == DUPLICATE_KIND_GOLD_GAIN or duplicateKind == DUPLICATE_KIND_GOLD_LOSS then
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
-- Creates the invisible 1x1 anchor frame used for toast positioning and a draggable overlay to reposition it.
-- If the anchor already exists the function returns immediately.
-- The anchor is placed using saved values from `ns.Addon.db.profile.display` (`anchorPoint`, `anchorX`, `anchorY`).
-- The overlay is hidden by default, shows the localized `DRAG_TO_MOVE`
-- text when visible, allows left-button dragging to move the anchor,
-- and saves the updated `anchorPoint`, `anchorX`, and `anchorY` back
-- to the same profile keys on mouse release.

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

local function GetToastSpacing()
    local db = ns.Addon.db.profile.display
    return db.toastHeight + (db.spacing or TOAST_SPACING)
        + (ns.Addon.db.profile.appearance.borderSize or 0)
end

local function GetToastPosition(index)
    local db = ns.Addon.db.profile.display
    local spacing = GetToastSpacing()
    local offset = (index - 1) * spacing

    if db.growDirection == "UP" then
        return "BOTTOMRIGHT", anchorFrame, "BOTTOMRIGHT", 0, offset
    else
        return "TOPRIGHT", anchorFrame, "TOPRIGHT", 0, -offset
    end
end

-- Plan in growth-direction coordinates. A hovered toast pins its exact
-- physical position; never move a neighbor across it or reserve a rounded row.
local function PlanPositions(reserveEntry)
    local db = ns.Addon.db.profile.display
    local spacing = GetToastSpacing()
    local direction = db.growDirection == "UP" and 1 or -1
    local nextOffset = reserveEntry and spacing or 0
    local positions = {}
    for i, toast in ipairs(activeToasts) do
        local current = ns.ToastAnimations.GetLayoutY(toast)
        local offset = nextOffset
        if toast._isHovered and current ~= nil then
            offset = current * direction
            if offset + POSITION_EPSILON < nextOffset then return nil end
        end
        positions[i] = offset * direction
        nextOffset = offset + spacing
    end
    return positions, spacing, db.growDirection
end

function ns.ToastManager.UpdatePositions()
    if not isInitialized then return false end

    local spacing = GetToastSpacing()
    local direction = ns.Addon.db.profile.display.growDirection
    local geometryChanged = layoutSpacing ~= nil
        and (layoutSpacing ~= spacing or layoutDirection ~= direction)
    if geometryChanged then
        -- A new row size/direction cannot preserve a pin in the old geometry.
        -- End hover before planning so resized cards cannot remain overlapping.
        for _, toast in ipairs(activeToasts) do
            if toast._isHovered then ns.ToastFrame.ClearHover(toast) end
        end
    end
    local positions = PlanPositions(admissionPending)
    if not positions then return false end
    local point, relativeTo, relativePoint, x = GetToastPosition(1)
    local changed = geometryChanged
    for i, toast in ipairs(activeToasts) do
        if toast._targetY ~= positions[i] then changed = true end
    end

    local remaining = 0
    for i, toast in ipairs(activeToasts) do
        local y = positions[i]
        if toast._anchorY == nil or geometryChanged then
            ns.ToastAnimations.SetPosition(toast, point, relativeTo, relativePoint, x, y)
        elseif toast._isHovered then
            ns.ToastAnimations.StopSlide(toast)
            toast._targetY = y
        elseif changed then
            -- All moving rows share a start time and duration. Interpolating
            -- two ordered, spaced layouts preserves the gap between neighbors.
            ns.ToastAnimations.PlaySlide(toast, nil, y, point, relativeTo, relativePoint, x)
        end
        remaining = math.max(remaining, ns.ToastAnimations.GetSlideRemaining(toast))
    end
    layoutSpacing, layoutDirection = spacing, direction
    if geometryChanged and QueueUtils.Size(toastQueue) > 0 then
        -- Clearing a geometry-incompatible hover may unblock admission. Wake
        -- the single pump asynchronously; UpdatePositions also runs inside it.
        ScheduleFlush(0)
    end
    return true, remaining
end

function ns.ToastManager.OnHoverChanged()
    if admissionPending and not PlanPositions(true) then
        admissionPending = false
        if flushStaggerTimer then
            ns.Addon:CancelTimer(flushStaggerTimer)
            flushStaggerTimer = nil
        end
    end
    ns.ToastManager.UpdatePositions()
    ns.ToastManager.FlushQueue()
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

local function FindDuplicate(lootData, activeOnly)
    if lootData.isCurrency and not lootData.copperAmount and not lootData.currencyID then return nil end

    -- Active toasts stack for their full visible lifetime (until _isExiting).
    -- No time window is applied here - if the toast is still on screen, it accepts stacks.
    for i, toast in ipairs(activeToasts) do
        if not toast._isExiting and toast.lootData then
            local duplicateKind = GetDuplicateKind(toast.lootData, lootData)
            if duplicateKind then
                return toast, i, duplicateKind
            end
        end
    end

    if activeOnly then return nil end

    -- Queued entries are time-gated: entries older than DUPLICATE_WINDOW do not receive
    -- stacks and a new entry is queued instead. This intentionally differs from the active
    -- path - queued items have no visible frame to signal liveness, so the time window
    -- acts as a staleness guard.
    local now = GetTime()
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

local function StackDuplicate(lootData, activeOnly)
    local existing, activeIndex, duplicateKind = FindDuplicate(lootData, activeOnly)
    if not existing then return false end
    if activeIndex then
        ApplyDuplicateStack(existing.lootData, lootData, duplicateKind, GetActiveStackTimestamp(duplicateKind))
        ns.ToastFrame.Populate(existing, existing.lootData)
        ns.ToastAnimations.UpdateLifecycle(existing, existing.lootData)
    end
    return true
end

-- Only the admission pump may acquire a visible frame. Its row is already
-- clear, including when several older toasts finish in the same render tick.
local function ActivateToast(lootData)
    local db = ns.Addon.db.profile
    local toast = ns.ToastFrame.Acquire()
    ns.ToastFrame.Populate(toast, lootData)
    table.insert(activeToasts, 1, toast)
    ns.ToastManager.UpdatePositions()
    ns.ToastAnimations.PlayLifecycle(toast, lootData)

    if db.sound.enabled and db.sound.soundFile and db.sound.soundFile ~= "None" then
        local soundPath = LSM:Fetch("sound", db.sound.soundFile)
        if soundPath then PlaySoundFile(soundPath, "SFX") end
    end
end

local function ShowToast(lootData)
    if StackDuplicate(lootData) then return end
    QueueUtils.Push(toastQueue, lootData)
    ns.ToastManager.FlushQueue()
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

ScheduleFlush = function(delay)
    if flushStaggerTimer then return end
    flushStaggerTimer = ns.Addon:ScheduleTimer(function()
        flushStaggerTimer = nil
        ns.ToastManager.FlushQueue()
    end, delay)
end

function ns.ToastManager.FlushQueue()
    if not isInitialized or flushStaggerTimer then return end
    local db = ns.Addon.db.profile

    while QueueUtils.Size(toastQueue) > 0 and #activeToasts < db.display.maxToasts do
        local wait = nextAdmissionTime - GetTime()
        if wait > POSITION_EPSILON then
            ScheduleFlush(wait)
            return
        end

        if not admissionPending then
            -- If making room would cross a hovered toast, wait for a removal
            -- or hover change. Other visible lifecycles continue normally.
            if not PlanPositions(true) then return end
            admissionPending = true
        end
        local possible, remaining = ns.ToastManager.UpdatePositions()
        if not possible then
            admissionPending = false
            ns.ToastManager.UpdatePositions()
            return
        end
        if remaining > POSITION_EPSILON then
            ScheduleFlush(remaining)
            return
        end

        local lootData = QueueUtils.Pop(toastQueue)
        if not StackDuplicate(lootData, true) then
            admissionPending = false
            ActivateToast(lootData)
            nextAdmissionTime = GetTime() + math.max(db.display.queueStagger or 0, 0)
        end
    end

    if admissionPending then
        admissionPending = false
        ns.ToastManager.UpdatePositions()
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
    -- Ignore stale/duplicate completions; only an active toast owns a slot.
    local found = false
    for i, t in ipairs(activeToasts) do
        if t == toast then
            table.remove(activeToasts, i)
            found = true
            break
        end
    end
    if not found then return end

    -- Release frame back to pool
    ns.ToastAnimations.StopAll(toast)
    ns.ToastFrame.Release(toast)

    -- Reposition remaining toasts
    ns.ToastManager.UpdatePositions()

    -- Process queue
    ns.ToastManager.FlushQueue()
end

function ns.ToastManager.ClearAll()
    if flushStaggerTimer then
        ns.Addon:CancelTimer(flushStaggerTimer)
        flushStaggerTimer = nil
    end
    admissionPending = false
    nextAdmissionTime = 0
    layoutSpacing, layoutDirection = nil, nil
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
        ns.Print(L["Anchor locked"])
    else
        overlay:EnableMouse(true)
        overlay:Show()
        ns.Print(L["Anchor unlocked -- drag to reposition"])
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
    ns.Print(L["Anchor position reset to default."])
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
