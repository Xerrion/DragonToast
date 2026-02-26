-------------------------------------------------------------------------------
-- ToastAnimations.lua
-- Animation sequences for toast frames using LibAnimate
--
-- Supported versions: TBC Anniversary, Retail, MoP Classic
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
-- Callback reference
--
-- ToastManager.OnToastFinished is the single lifecycle-completion handler.
-- Captured as a local after module tables are initialized (see PlayLifecycle).
-------------------------------------------------------------------------------

local OnToastFinished = function(frame)
    ns.ToastManager.OnToastFinished(frame)
end

-------------------------------------------------------------------------------
-- Phase-start functions (chained via onFinished callbacks)
--
-- Ordering matters: each function calls the next in the chain, so they
-- are declared bottom-up: PlayExit -> PlayHold -> PlayAttention ->
-- PlayAttentionOrHold -> PlayEntrance.
-------------------------------------------------------------------------------

--- After lib:Stop() restores the pre-animation anchor (which may be stale
--- if slides happened), re-anchor the frame to its logical target position.
local function RestoreLogicalAnchor(frame)
    if frame._targetY == nil then return end
    local point, relativeTo, relativePoint, x, _y = frame:GetPoint()
    if point then
        frame:ClearAllPoints()
        frame:SetPoint(point, relativeTo, relativePoint, x, frame._targetY)
    end
end

--- Exit phase: fade/slide out, then signal lifecycle complete.
local function PlayExit(frame, db, onLifecycleFinished)
    frame._phase = "exit"
    frame._isExiting = true
    lib:Animate(frame, db.animation.exitAnimation, {
        duration = db.animation.exitDuration,
        distance = db.animation.exitDistance,
        onFinished = onLifecycleFinished,
    })
end

--- Hold phase: identity animation whose duration IS the display time.
local function PlayHold(frame, db, onLifecycleFinished)
    frame._phase = "hold"
    lib:Animate(frame, "none", {
        duration = db.animation.holdDuration,
        onFinished = function()
            PlayExit(frame, db, onLifecycleFinished)
        end,
    })
end

--- Attention phase: quality-gated bounce/pulse before the hold.
local function PlayAttention(frame, db, onLifecycleFinished)
    frame._phase = "attention"
    lib:Animate(frame, db.animation.attentionAnimation, {
        delay = db.animation.attentionDelay,
        repeatCount = db.animation.attentionRepeatCount,
        onFinished = function()
            PlayHold(frame, db, onLifecycleFinished)
        end,
    })
end

--- Route to attention or hold based on config and item quality.
local function PlayAttentionOrHold(frame, db, lootData, onLifecycleFinished)
    local hasAttention = db.animation.attentionAnimation ~= "none"
    local meetsQuality = lootData.itemQuality >= (db.animation.attentionMinQuality or 0)
    if hasAttention and meetsQuality then
        PlayAttention(frame, db, onLifecycleFinished)
    else
        PlayHold(frame, db, onLifecycleFinished)
    end
end

--- Entrance phase: slide/fade in, then chain to attention or hold.
local function PlayEntrance(frame, db, lootData, onLifecycleFinished)
    frame._phase = "entrance"
    frame._isEntering = true
    lib:Animate(frame, db.animation.entranceAnimation, {
        duration = db.animation.entranceDuration,
        distance = db.animation.entranceDistance,
        onFinished = function()
            frame._isEntering = false
            -- Deferred slide catch-up: if the target moved while entrance
            -- was playing, issue the slide now that the frame has landed.
            local args = frame._deferredSlideArgs
            if args and frame._targetY ~= nil then
                frame:ClearAllPoints()
                frame:SetPoint(args[1], args[2], args[3], args[4], frame._targetY)
                frame._anchorY = frame._targetY
                frame._deferredSlideArgs = nil
            end
            PlayAttentionOrHold(frame, db, lootData, onLifecycleFinished)
        end,
    })
end

-------------------------------------------------------------------------------
-- Play full toast lifecycle (entrance -> [attention] -> hold -> exit)
-------------------------------------------------------------------------------

function ns.ToastAnimations.PlayLifecycle(frame, lootData)
    ns.ToastAnimations.StopAll(frame)

    local db = ns.Addon.db.profile

    -- No-animation fallback: show immediately, hold via timer, then finish
    if not db.animation.enableAnimations then
        frame:Show()
        frame:SetAlpha(1)
        frame._phase = "hold"
        frame._noAnimTimer = ns.Addon:ScheduleTimer(function()
            frame._noAnimTimer = nil
            frame._phase = nil
            OnToastFinished(frame)
        end, db.animation.holdDuration)
        return
    end

    frame:Show()
    PlayEntrance(frame, db, lootData, function() OnToastFinished(frame) end)
end

-------------------------------------------------------------------------------
-- Update lifecycle for duplicate/stacking items
--
-- Restarts from the attention-or-hold phase when possible, giving visual
-- feedback and resetting the hold timer without replaying the entrance.
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
            frame._phase = nil
            OnToastFinished(frame)
        end, db.animation.holdDuration)
        return
    end

    -- If exiting, no phase, or still in entrance: full restart
    if frame._isExiting or frame._phase == nil or frame._phase == "entrance" then
        ns.ToastAnimations.PlayLifecycle(frame, lootData)
        return
    end

    -- In attention or hold: stop current animation, restart from attention
    frame._isExiting = false
    lib:Stop(frame)
    RestoreLogicalAnchor(frame)
    PlayAttentionOrHold(frame, db, lootData, function() OnToastFinished(frame) end)
end

-------------------------------------------------------------------------------
-- Play slide animation (reposition in stack)
-------------------------------------------------------------------------------

function ns.ToastAnimations.PlaySlide(frame, _startY, toY, point, relativeTo,
                                      relativePoint, x)
    if frame._isExiting then return end

    local db = ns.Addon.db.profile

    if not db.animation.enableAnimations then
        frame:ClearAllPoints()
        frame:SetPoint(point, relativeTo, relativePoint, x, toY)
        return
    end

    -- SlideAnchor handles in-progress slides correctly: it snaps any existing
    -- slide to completion, then starts a new slide from the completed position.
    -- Do NOT call UpdateAnchor before SlideAnchor -- it would clobber the
    -- in-progress interpolated anchor with a stale value, causing visual jumps.
    lib:SlideAnchor(frame, x, toY, db.animation.slideSpeed or 0.2)
end

-------------------------------------------------------------------------------
-- Dismiss (user click)
-------------------------------------------------------------------------------

function ns.ToastAnimations.Dismiss(frame)
    if frame._phase == "exit" then return end -- already exiting

    local db = ns.Addon.db.profile

    if frame._phase ~= nil and db.animation.enableAnimations then
        lib:Stop(frame)
        -- lib:Stop restores the anchor to whatever position was captured when
        -- Animate started, which may be stale if slides happened since then.
        -- Re-anchor to the current logical position before starting the exit.
        RestoreLogicalAnchor(frame)
        PlayExit(frame, db, function() OnToastFinished(frame) end)
    else
        ns.ToastAnimations.StopAll(frame)
        OnToastFinished(frame)
    end
end

-------------------------------------------------------------------------------
-- Stop all animations on a frame
-------------------------------------------------------------------------------

function ns.ToastAnimations.StopAll(frame)
    frame._isExiting = false
    frame._isEntering = false
    frame._phase = nil

    if frame._noAnimTimer then
        ns.Addon:CancelTimer(frame._noAnimTimer)
        frame._noAnimTimer = nil
    end

    lib:Stop(frame)
end
