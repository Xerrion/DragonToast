-------------------------------------------------------------------------------
-- ToastAnimations.lua
-- Independent stack movement and visual effects for toast frames
--
-- Supported versions: TBC Anniversary, Retail, MoP Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

local lib = LibStub("LibAnimate")
ns.LibAnimate = lib

local GetTime = GetTime
local DEFAULT_SLIDE_SPEED = 0.2

-- Effects animate the visual child only. Its parent owns the stack position,
-- so a phase change, pause, or scale-only effect cannot discard stack movement.
lib:RegisterAnimation("none", {
    type = "attention",
    defaultDuration = 1,
    keyframes = {
        { progress = 0, alpha = 1, scale = 1, translateX = 0, translateY = 0 },
        { progress = 1, alpha = 1, scale = 1, translateX = 0, translateY = 0 },
    },
})

-------------------------------------------------------------------------------
-- Stack movement (layout parent only)
-------------------------------------------------------------------------------

local function ApplyLayoutPosition(frame, point, relativeTo, relativePoint, x, y)
    local layout = frame.layoutFrame
    layout:ClearAllPoints()
    layout:SetPoint(point, relativeTo, relativePoint, x, y)
    frame._layoutPoint = point
    frame._layoutRelativeTo = relativeTo
    frame._layoutRelativePoint = relativePoint
    frame._layoutX = x
    frame._anchorY = y
end

local function SampleSlide(frame)
    local slide = frame._layoutSlide
    if not slide then return end

    local progress = math.min(math.max((GetTime() - slide.startTime) / slide.duration, 0), 1)
    ApplyLayoutPosition(frame, slide.point, slide.relativeTo, slide.relativePoint,
        slide.fromX + (slide.toX - slide.fromX) * progress,
        slide.fromY + (slide.toY - slide.fromY) * progress)
    if progress >= 1 then
        frame._layoutSlide = nil
        frame.layoutFrame:SetScript("OnUpdate", nil)
    end
end

function ns.ToastAnimations.GetLayoutY(frame)
    SampleSlide(frame)
    return frame._anchorY
end

function ns.ToastAnimations.StopSlide(frame)
    SampleSlide(frame)
    frame._layoutSlide = nil
    frame.layoutFrame:SetScript("OnUpdate", nil)
end

function ns.ToastAnimations.GetSlideRemaining(frame)
    SampleSlide(frame)
    local slide = frame._layoutSlide
    return slide and math.max(slide.startTime + slide.duration - GetTime(), 0) or 0
end

function ns.ToastAnimations.SetPosition(frame, point, relativeTo, relativePoint, x, y)
    ns.ToastAnimations.StopSlide(frame)
    frame._targetY = y
    ApplyLayoutPosition(frame, point, relativeTo, relativePoint, x, y)
end

function ns.ToastAnimations.PlaySlide(frame, _, toY, point, relativeTo, relativePoint, x)
    ns.ToastAnimations.StopSlide(frame)
    local fromY = frame._anchorY
    local db = ns.Addon.db.profile.animation
    local duration = db.enableAnimations and (db.slideSpeed or DEFAULT_SLIDE_SPEED) or 0
    frame._targetY = toY

    -- A changed anchor basis (for example UP -> DOWN) is a layout edit, not
    -- movement between coordinates in the same space.
    if fromY == nil or frame._layoutPoint ~= point
        or frame._layoutRelativeTo ~= relativeTo or frame._layoutRelativePoint ~= relativePoint
        or duration <= 0 or (fromY == toY and frame._layoutX == x) then
        ns.ToastAnimations.SetPosition(frame, point, relativeTo, relativePoint, x, toY)
        return 0
    end

    if frame._isHovered then
        frame._targetY = fromY
        return 0
    end

    frame._layoutSlide = {
        point = point,
        relativeTo = relativeTo,
        relativePoint = relativePoint,
        fromX = frame._layoutX,
        fromY = fromY,
        toX = x,
        toY = toY,
        startTime = GetTime(),
        duration = duration,
    }
    frame.layoutFrame:SetScript("OnUpdate", function() SampleSlide(frame) end)
    return duration
end

-------------------------------------------------------------------------------
-- Lifecycle ownership
-------------------------------------------------------------------------------

local function IsCurrent(frame, generation)
    return not frame._isPooled and frame._lifecycleID == generation and not frame._lifecycleFinished
end

local function Finish(frame, generation)
    if not IsCurrent(frame, generation) then return end
    frame._lifecycleFinished = true
    frame._phase = nil
    ns.ToastManager.OnToastFinished(frame)
end

local function Animate(frame, name, options, callback)
    local generation = frame._lifecycleID
    frame._effectGeneration = (frame._effectGeneration or 0) + 1
    local effectGeneration = frame._effectGeneration
    options.onFinished = function()
        if IsCurrent(frame, generation) and frame._effectGeneration == effectGeneration then callback() end
    end
    lib:Animate(frame, name, options)
end

local function PlayExit(frame)
    local animation = frame._lifecycleConfig
    local generation = frame._lifecycleID
    frame._phase = "exit"
    frame._isEntering = false
    frame._isExiting = true
    Animate(frame, animation.exitAnimation, {
        duration = animation.exitDuration,
        distance = animation.exitDistance,
    }, function() Finish(frame, generation) end)
end

local function PlayHoverHold(frame)
    local generation = frame._lifecycleID
    frame._hoverHoldCallback = function()
        if IsCurrent(frame, generation) then PlayExit(frame) end
    end
    Animate(frame, "none", { duration = 1 }, function()
        frame._hoverHoldCallback = nil
        PlayExit(frame)
    end)
    lib:PauseQueue(frame)
end

local function PlayHold(frame)
    frame._phase = "hold"
    Animate(frame, "none", { duration = frame._lifecycleConfig.holdDuration }, function()
        if frame._isHovered then
            PlayHoverHold(frame)
        else
            PlayExit(frame)
        end
    end)
end

local function PlayAttentionOrHold(frame, lootData)
    local animation = frame._lifecycleConfig
    if animation.attentionAnimation ~= "none"
        and lootData.itemQuality >= (animation.attentionMinQuality or 0) then
        frame._phase = "attention"
        Animate(frame, animation.attentionAnimation, {
            delay = animation.attentionDelay,
            repeatCount = animation.attentionRepeatCount,
        }, function() PlayHold(frame) end)
    else
        PlayHold(frame)
    end
end

local function ScheduleHoldTimer(frame, duration)
    local generation = frame._lifecycleID
    frame._holdTimerGeneration = (frame._holdTimerGeneration or 0) + 1
    local timerGeneration = frame._holdTimerGeneration
    frame._holdEndTime = GetTime() + duration
    frame._noAnimTimer = ns.Addon:ScheduleTimer(function()
        if not IsCurrent(frame, generation) or frame._holdTimerGeneration ~= timerGeneration then return end
        frame._noAnimTimer = nil
        frame._holdEndTime = nil
        Finish(frame, generation)
    end, duration)
end

function ns.ToastAnimations.PlayLifecycle(frame, lootData)
    ns.ToastAnimations.StopAll(frame)
    local animation = ns.Addon.db.profile.animation
    frame._animationsEnabled = animation.enableAnimations
    frame._lifecycleConfig = animation
    frame._lifecycleFinished = false
    frame.layoutFrame:Show()
    frame:Show()

    if not frame._animationsEnabled then
        frame:SetAlpha(1)
        frame._phase = "hold"
        ScheduleHoldTimer(frame, animation.holdDuration)
        return
    end

    frame._phase = "entrance"
    frame._isEntering = true
    Animate(frame, animation.entranceAnimation, {
        duration = animation.entranceDuration,
        distance = animation.entranceDistance,
    }, function()
        frame._isEntering = false
        PlayAttentionOrHold(frame, lootData)
    end)
end

-- Stacking updates content without replaying effects or extending lifetime.
function ns.ToastAnimations.UpdateLifecycle() end

-------------------------------------------------------------------------------
-- Hover and dismissal
-------------------------------------------------------------------------------

function ns.ToastAnimations.PauseForHover(frame)
    ns.ToastAnimations.StopSlide(frame)
    if frame._animationsEnabled then
        if frame._isExiting then lib:PauseQueue(frame) end
    elseif frame._noAnimTimer and frame._holdEndTime then
        frame._holdRemaining = math.max(frame._holdEndTime - GetTime(), 0)
        frame._holdEndTime = nil
        frame._holdTimerGeneration = (frame._holdTimerGeneration or 0) + 1
        ns.Addon:CancelTimer(frame._noAnimTimer)
        frame._noAnimTimer = nil
    end
end

function ns.ToastAnimations.ResumeFromHoverHold(frame)
    local callback = frame._hoverHoldCallback
    if not callback then return false end
    frame._hoverHoldCallback = nil
    lib:Stop(frame)
    callback()
    return true
end

function ns.ToastAnimations.ResumeFromHover(frame)
    if frame._animationsEnabled then
        if frame._isExiting then
            lib:ResumeQueue(frame)
        else
            ns.ToastAnimations.ResumeFromHoverHold(frame)
        end
    elseif frame._holdRemaining ~= nil then
        local remaining = frame._holdRemaining
        frame._holdRemaining = nil
        ScheduleHoldTimer(frame, remaining)
    end
end

function ns.ToastAnimations.Dismiss(frame)
    if frame._isPooled or frame._phase == nil or frame._phase == "exit" then return end
    frame._hoverHoldCallback = nil
    if frame._animationsEnabled then
        lib:Stop(frame)
        PlayExit(frame)
    else
        Finish(frame, frame._lifecycleID)
    end
end

function ns.ToastAnimations.StopAll(frame)
    frame._lifecycleID = (frame._lifecycleID or 0) + 1
    frame._effectGeneration = (frame._effectGeneration or 0) + 1
    frame._holdTimerGeneration = (frame._holdTimerGeneration or 0) + 1
    frame._isExiting = false
    frame._isEntering = false
    frame._phase = nil
    frame._holdEndTime = nil
    frame._holdRemaining = nil
    frame._hoverHoldCallback = nil
    frame._animationsEnabled = nil
    frame._lifecycleConfig = nil

    if frame._noAnimTimer then
        ns.Addon:CancelTimer(frame._noAnimTimer)
        frame._noAnimTimer = nil
    end
    ns.ToastAnimations.StopSlide(frame)
    lib:Stop(frame)
end
