-------------------------------------------------------------------------------
-- ToastAnimations.lua
-- Animation sequences for toast frames using LibAnimate
--
-- Supported versions: TBC Anniversary, Retail
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

-------------------------------------------------------------------------------
-- LibAnimate reference
-------------------------------------------------------------------------------

local lib = LibStub("LibAnimate")
ns.LibAnimate = lib

-------------------------------------------------------------------------------
-- Register the identity ("none") animation for the hold phase.
-- No-op animation: keeps the frame fully visible at its current position.
-------------------------------------------------------------------------------

lib:RegisterAnimation("none", {
    type = "attention",
    defaultDuration = 1,
    keyframes = {
        { progress = 0, alpha = 1, scale = 1, translateX = 0, translateY = 0 },
        { progress = 1, alpha = 1, scale = 1, translateX = 0, translateY = 0 },
    },
})

-------------------------------------------------------------------------------
-- Role constants
-------------------------------------------------------------------------------

local ROLE_ENTRANCE  = "entrance"
local ROLE_ATTENTION = "attention"
local ROLE_HOLD      = "hold"
local ROLE_EXIT      = "exit"

-------------------------------------------------------------------------------
-- Role tracking helpers
--
-- Each frame maintains frame._queueRoles = { [index] = role, ... }
-- This map mirrors the LibAnimate queue indices without accessing internals.
-- It is rebuilt on PlayLifecycle and kept in sync during UpdateLifecycle.
-------------------------------------------------------------------------------

--- Build entries and the corresponding role map for a full lifecycle.
---@param frame table The toast frame (needed for onFinished closure)
---@param db table Profile settings (ns.Addon.db.profile)
---@param lootData table Loot data for quality gating
---@return table entries Queue entries array
---@return table roles Index-to-role map
local function BuildLifecycle(frame, db, lootData)
    local entries = {}
    local roles = {}
    local idx = 0

    -- 1. Entrance
    idx = idx + 1
    entries[idx] = {
        name = db.animation.entranceAnimation,
        duration = db.animation.entranceDuration,
        distance = db.animation.entranceDistance,
    }
    roles[idx] = ROLE_ENTRANCE

    -- 2. Attention (conditional on quality threshold)
    local wantsAttention = db.animation.attentionAnimation ~= "none"
        and lootData
        and lootData.itemQuality
        and lootData.itemQuality >= db.animation.attentionMinQuality

    if wantsAttention then
        idx = idx + 1
        entries[idx] = {
            name = db.animation.attentionAnimation,
            delay = db.animation.attentionDelay or 0,
            repeatCount = db.animation.attentionRepeatCount or 2,
        }
        roles[idx] = ROLE_ATTENTION
    end

    -- 3. Hold (identity animation; its duration IS the display time)
    idx = idx + 1
    entries[idx] = {
        name = "none",
        duration = db.animation.holdDuration,
        onFinished = function()
            frame._isExiting = true
        end,
    }
    roles[idx] = ROLE_HOLD

    -- 4. Exit
    idx = idx + 1
    entries[idx] = {
        name = db.animation.exitAnimation,
        duration = db.animation.exitDuration,
        distance = db.animation.exitDistance,
    }
    roles[idx] = ROLE_EXIT

    return entries, roles
end

--- Build tail entries for lifecycle extension (attention -> hold -> exit).
---@param frame table The toast frame (needed for onFinished closure)
---@param db table Profile settings
---@return table entries
---@return table roles Partial role map (keys starting at 1)
local function BuildTail(frame, db)
    local entries = {}
    local roles = {}

    -- Always show a feedback animation when stacking
    local attentionName = db.animation.attentionAnimation
    if attentionName == "none" then
        attentionName = "pulse"
    end

    entries[1] = {
        name = attentionName,
        delay = 0,
        repeatCount = 1,
    }
    roles[1] = ROLE_ATTENTION

    entries[2] = {
        name = "none",
        duration = db.animation.holdDuration,
        onFinished = function()
            frame._isExiting = true
        end,
    }
    roles[2] = ROLE_HOLD

    entries[3] = {
        name = db.animation.exitAnimation,
        duration = db.animation.exitDuration,
        distance = db.animation.exitDistance,
    }
    roles[3] = ROLE_EXIT

    return entries, roles
end

--- Find the queue index of the exit entry by scanning the role map forward
--- from the current queue position.
---@param frame table The toast frame
---@return number|nil exitIndex
local function FindExitIndex(frame)
    local roles = frame._queueRoles
    if not roles then return nil end

    local currentIndex = lib:GetQueueInfo(frame)
    if not currentIndex then return nil end

    for i = currentIndex, #roles do
        if roles[i] == ROLE_EXIT then
            return i
        end
    end
    return nil
end

-------------------------------------------------------------------------------
-- Play full toast lifecycle (entrance -> [attention] -> hold -> exit)
-------------------------------------------------------------------------------

function ns.ToastAnimations.PlayLifecycle(frame, lootData)
    ns.ToastAnimations.StopAll(frame)

    local db = ns.Addon.db.profile

    frame:Show()

    -- No-animation fallback: just show for holdDuration then finish
    if not db.animation.enableAnimations then
        frame:SetAlpha(1)
        frame._noAnimTimer = ns.Addon:ScheduleTimer(function()
            frame._noAnimTimer = nil
            ns.ToastManager.OnToastFinished(frame)
        end, db.animation.holdDuration)
        return
    end

    local entries, roles = BuildLifecycle(frame, db, lootData)
    frame._queueRoles = roles

    lib:Queue(frame, entries, {
        onFinished = function()
            ns.ToastManager.OnToastFinished(frame)
        end,
    })
end

-------------------------------------------------------------------------------
-- Update lifecycle for duplicate/stacking items
--
-- Surgically modifies the running queue using GetQueueInfo, RemoveQueueEntry,
-- and InsertQueueEntry. Strips remaining entries after the current one and
-- appends a fresh attention -> hold -> exit tail, giving visual feedback
-- (pulse/bounce) and resetting the hold timer without restarting the entrance.
-------------------------------------------------------------------------------

function ns.ToastAnimations.UpdateLifecycle(frame, lootData)
    local db = ns.Addon.db.profile

    -- No-animation mode: just reset the hold timer
    if not db.animation.enableAnimations then
        if frame._noAnimTimer then
            ns.Addon:CancelTimer(frame._noAnimTimer)
        end
        frame._noAnimTimer = ns.Addon:ScheduleTimer(function()
            frame._noAnimTimer = nil
            ns.ToastManager.OnToastFinished(frame)
        end, db.animation.holdDuration)
        return
    end

    -- If exiting or no active queue, restart fully
    if frame._isExiting or not lib:IsQueued(frame) then
        ns.ToastAnimations.PlayLifecycle(frame, lootData)
        return
    end

    local currentIndex, totalEntries = lib:GetQueueInfo(frame)
    if not currentIndex then
        ns.ToastAnimations.PlayLifecycle(frame, lootData)
        return
    end

    -- Determine current phase from our role map
    local roles = frame._queueRoles
    if not roles then
        ns.ToastAnimations.PlayLifecycle(frame, lootData)
        return
    end

    local currentRole = roles[currentIndex]

    -- Still in entrance: restart cleanly (toast hasn't settled into position)
    if currentRole == ROLE_ENTRANCE then
        ns.ToastAnimations.PlayLifecycle(frame, lootData)
        return
    end

    -- In attention, hold, or unknown phase: strip future entries, append tail
    frame._isExiting = false

    -- Remove all entries after the current one (iterate backwards for stability)
    for i = totalEntries, currentIndex + 1, -1 do
        lib:RemoveQueueEntry(frame, i)
        roles[i] = nil
    end

    -- Build and append the new tail
    local tailEntries, tailRoles = BuildTail(frame, db)

    -- Re-query total after removals to compute correct offsets
    local _, newTotal = lib:GetQueueInfo(frame)
    if not newTotal then
        ns.ToastAnimations.PlayLifecycle(frame, lootData)
        return
    end

    for j = 1, #tailEntries do
        lib:InsertQueueEntry(frame, tailEntries[j])
        roles[newTotal + j] = tailRoles[j]
    end
end

-------------------------------------------------------------------------------
-- Play slide animation (reposition in stack)
-------------------------------------------------------------------------------

function ns.ToastAnimations.PlaySlide(frame, _, toY, point, relativeTo,
                                      relativePoint, x)
    if frame._isExiting then return end

    local db = ns.Addon.db.profile

    if not db.animation.enableAnimations then
        frame:ClearAllPoints()
        frame:SetPoint(point, relativeTo, relativePoint, x, toY)
        return
    end

    lib:SlideAnchor(frame, x, toY, db.animation.slideSpeed or 0.2)
end

-------------------------------------------------------------------------------
-- Dismiss (user click)
-------------------------------------------------------------------------------

function ns.ToastAnimations.Dismiss(frame)
    local exitIndex = FindExitIndex(frame)

    if exitIndex and lib:IsQueued(frame) then
        frame._isExiting = true
        lib:SkipToEntry(frame, exitIndex)
    elseif lib:IsAnimating(frame) or lib:IsPaused(frame) then
        ns.ToastAnimations.StopAll(frame)
        ns.ToastManager.OnToastFinished(frame)
    else
        ns.ToastManager.OnToastFinished(frame)
    end
end

-------------------------------------------------------------------------------
-- Pause / Resume (hover)
-------------------------------------------------------------------------------

function ns.ToastAnimations.Pause(frame)
    lib:PauseQueue(frame)
end

function ns.ToastAnimations.Resume(frame)
    lib:ResumeQueue(frame)
end

-------------------------------------------------------------------------------
-- Stop all animations on a frame
-------------------------------------------------------------------------------

function ns.ToastAnimations.StopAll(frame)
    frame._isExiting = false
    frame._queueRoles = nil

    if frame._noAnimTimer then
        ns.Addon:CancelTimer(frame._noAnimTimer)
        frame._noAnimTimer = nil
    end

    lib:ClearQueue(frame)
end
