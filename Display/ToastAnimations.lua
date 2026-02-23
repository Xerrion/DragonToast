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
-- Helpers
-------------------------------------------------------------------------------

--- Build the queue entries table for a toast lifecycle.
--- Returns the entries array and the index of the exit entry within it.
---@param db table Profile settings (ns.Addon.db.profile)
---@param lootData table Loot data for quality gating
---@return table entries Queue entries
---@return number exitIndex 1-based index of the exit entry
local function BuildLifecycleEntries(db, lootData)
    local entries = {}

    -- 1. Entrance
    entries[#entries + 1] = {
        name = db.animation.entranceAnimation,
        duration = db.animation.entranceDuration,
        distance = db.animation.entranceDistance,
    }

    -- 2. Attention (conditional on item quality)
    if db.animation.attentionAnimation ~= "none"
        and lootData
        and lootData.itemQuality
        and lootData.itemQuality >= db.animation.attentionMinQuality
    then
        entries[#entries + 1] = {
            name = db.animation.attentionAnimation,
            delay = db.animation.attentionDelay or 0,
            repeatCount = db.animation.attentionRepeatCount or 2,
        }
    end

    -- 3. Hold (identity animation whose duration IS the display time)
    entries[#entries + 1] = {
        name = "none",
        duration = db.animation.holdDuration,
        onFinished = function(frame)
            frame._isExiting = true
        end,
    }

    -- 4. Exit
    entries[#entries + 1] = {
        name = db.animation.exitAnimation,
        duration = db.animation.exitDuration,
        distance = db.animation.exitDistance,
        delay = 0,
    }

    return entries, #entries
end

-------------------------------------------------------------------------------
-- Play full toast lifecycle (entrance -> [attention] -> hold -> exit)
-------------------------------------------------------------------------------

function ns.ToastAnimations.PlayLifecycle(frame, lootData)
    -- Defensive: clear any stale animation state from previous use
    ns.ToastAnimations.StopAll(frame)

    local db = ns.Addon.db.profile

    frame:Show()

    if not db.animation.enableAnimations then
        frame:SetAlpha(1)
        frame._noAnimTimer = ns.Addon:ScheduleTimer(function()
            frame._noAnimTimer = nil
            ns.ToastManager.OnToastFinished(frame)
        end, db.animation.holdDuration)
        return
    end

    local entries, exitIndex = BuildLifecycleEntries(db, lootData)

    frame._exitEntryIndex = exitIndex

    lib:Queue(frame, entries, {
        onFinished = function()
            ns.ToastManager.OnToastFinished(frame)
        end,
    })
end

-------------------------------------------------------------------------------
-- Update lifecycle for duplicate/stacking items
--
-- Called when a duplicate item is looted and an existing toast is updated.
-- Instead of restarting the full lifecycle, this surgically modifies the
-- running queue to renew the hold timer and play a brief attention pulse.
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

    -- If the toast is already exiting, stop everything and restart
    if frame._isExiting then
        ns.ToastAnimations.PlayLifecycle(frame, lootData)
        return
    end

    local currentIndex, totalEntries = lib:GetQueueInfo(frame)

    -- No active queue (shouldn't happen, but be safe)
    if not currentIndex then
        ns.ToastAnimations.PlayLifecycle(frame, lootData)
        return
    end

    -- If still in entrance phase (index 1), just restart the full lifecycle.
    -- The entrance animation hasn't finished so a clean restart looks best.
    if currentIndex <= 1 then
        ns.ToastAnimations.PlayLifecycle(frame, lootData)
        return
    end

    -- Past the entrance: currently in attention or hold phase.
    -- Remove all entries after the currently-playing one (hold + exit),
    -- then append a new attention -> hold -> exit sequence.

    -- Remove from the end backwards so indices stay valid
    for i = totalEntries, currentIndex + 1, -1 do
        lib:RemoveQueueEntry(frame, i)
    end

    -- Build the new tail: attention pulse -> hold -> exit
    local attentionName = db.animation.attentionAnimation
    if attentionName == "none" then
        -- Use pulse as a fallback so there's visible feedback
        attentionName = "pulse"
    end

    -- Insert attention pulse after the current entry
    lib:InsertQueueEntry(frame, {
        name = attentionName,
        delay = 0,
        repeatCount = 1,
    })

    -- Insert renewed hold
    lib:InsertQueueEntry(frame, {
        name = "none",
        duration = db.animation.holdDuration,
        onFinished = function(f)
            f._isExiting = true
        end,
    })

    -- Insert exit
    local exitEntry = {
        name = db.animation.exitAnimation,
        duration = db.animation.exitDuration,
        distance = db.animation.exitDistance,
        delay = 0,
    }
    lib:InsertQueueEntry(frame, exitEntry)

    -- Update the cached exit index (it's now the last entry)
    local _, newTotal = lib:GetQueueInfo(frame)
    frame._exitEntryIndex = newTotal
end

-------------------------------------------------------------------------------
-- Play slide animation (reposition in stack)
-------------------------------------------------------------------------------

function ns.ToastAnimations.PlaySlide(frame, _, toY, point, relativeTo,
                                      relativePoint, x)
    -- Don't slide a toast that's mid-exit; let it finish disappearing
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
    if frame._exitEntryIndex and lib:IsQueued(frame) then
        frame._isExiting = true
        lib:SkipToEntry(frame, frame._exitEntryIndex)
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
    frame._exitEntryIndex = nil

    if frame._noAnimTimer then
        ns.Addon:CancelTimer(frame._noAnimTimer)
        frame._noAnimTimer = nil
    end

    lib:ClearQueue(frame)
end
