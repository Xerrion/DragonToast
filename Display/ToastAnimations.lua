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

    local entries = {}

    -- 1. Entrance
    entries[#entries + 1] = {
        name = db.animation.entranceAnimation,
        duration = db.animation.entranceDuration,
        distance = db.animation.entranceDistance,
    }

    -- 2. Attention (conditional)
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

    -- 3. Exit (delay = hold period)
    entries[#entries + 1] = {
        name = db.animation.exitAnimation,
        duration = db.animation.exitDuration,
        distance = db.animation.exitDistance,
        delay = db.animation.holdDuration,
    }

    frame._exitEntryIndex = #entries

    lib:Queue(frame, entries, {
        onFinished = function()
            ns.ToastManager.OnToastFinished(frame)
        end,
    })
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
