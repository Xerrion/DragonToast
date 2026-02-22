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
-- Cached WoW API
-------------------------------------------------------------------------------

local math_abs = math.abs

-------------------------------------------------------------------------------
-- Play entrance animation
-------------------------------------------------------------------------------

function ns.ToastAnimations.PlayEntrance(frame)
    -- Defensive: clear any stale animation state from previous use
    ns.ToastAnimations.StopAll(frame)

    local db = ns.Addon.db.profile

    if not db.animation.enableAnimations then
        frame:SetAlpha(1)
        frame:Show()
        return
    end

    frame._isEntering = true
    frame:Show()

    lib:Animate(frame, db.animation.entranceAnimation, {
        duration = db.animation.entranceDuration,
        distance = db.animation.entranceDistance,
        onFinished = function()
            frame._isEntering = false
        end,
    })
end

-------------------------------------------------------------------------------
-- Play exit animation
-------------------------------------------------------------------------------

function ns.ToastAnimations.PlayExit(frame)
    -- Guard against double-play
    if frame._isExiting and lib:IsAnimating(frame) then
        return
    end

    -- Clean up entrance if still running
    if frame._isEntering then
        frame._isEntering = false
        lib:Stop(frame)
    end

    local db = ns.Addon.db.profile

    if not db.animation.enableAnimations then
        if ns.ToastManager.OnToastFinished then
            ns.ToastManager.OnToastFinished(frame)
        end
        return
    end

    frame._isExiting = true

    lib:Animate(frame, db.animation.exitAnimation, {
        duration = db.animation.exitDuration,
        distance = db.animation.exitDistance,
        onFinished = function()
            frame._isExiting = false
            if ns.ToastManager.OnToastFinished then
                ns.ToastManager.OnToastFinished(frame)
            end
        end,
    })
end

-------------------------------------------------------------------------------
-- Play slide animation (reposition in stack)
-------------------------------------------------------------------------------

function ns.ToastAnimations.PlaySlide(frame, fromY, toY, point, relativeTo, relativePoint, x)
    local db = ns.Addon.db.profile
    if not db.animation.enableAnimations then
        frame:ClearAllPoints()
        frame:SetPoint(point, relativeTo, relativePoint, x, toY)
        return
    end

    -- If currently animating a slide, capture visual position before stopping
    local actualFromY = fromY
    if lib:IsAnimating(frame) and frame._isSliding then
        local _, _, _, _, currentY = frame:GetPoint()
        if currentY then
            actualFromY = currentY
        end
        lib:Stop(frame)
    end

    -- Set anchor to TARGET position
    frame:ClearAllPoints()
    frame:SetPoint(point, relativeTo, relativePoint, x, toY)

    local deltaY = toY - actualFromY
    local distance = math_abs(deltaY)
    if distance < 0.5 then return end

    local animName = deltaY > 0 and "moveUp" or "moveDown"

    frame._isSliding = true
    frame._slideToY = toY

    lib:Animate(frame, animName, {
        duration = db.animation.slideSpeed or 0.2,
        distance = distance,
        onFinished = function()
            frame._isSliding = false
        end,
    })
end

-------------------------------------------------------------------------------
-- Stop all animations on a frame
-------------------------------------------------------------------------------

function ns.ToastAnimations.StopAll(frame)
    frame._isEntering = false
    frame._isExiting = false
    frame._isSliding = false

    lib:Stop(frame)
end
