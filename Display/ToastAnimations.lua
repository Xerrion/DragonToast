-------------------------------------------------------------------------------
-- ToastAnimations.lua
-- Animation groups and sequences for toast frames
--
-- Supported versions: TBC Anniversary, Retail
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

-------------------------------------------------------------------------------
-- Cached WoW API
-------------------------------------------------------------------------------

local GetTime = GetTime

-------------------------------------------------------------------------------
-- Setup animation groups on a toast frame
-------------------------------------------------------------------------------

function ns.ToastAnimations.SetupAnimations(frame)
    -- Entrance animation group
    local entrance = frame:CreateAnimationGroup()

    -- Entrance: Alpha fade in
    local entranceAlpha = entrance:CreateAnimation("Alpha")
    entranceAlpha:SetFromAlpha(0)
    entranceAlpha:SetToAlpha(1)
    entranceAlpha:SetSmoothing("OUT")
    entranceAlpha:SetOrder(1)
    frame._entranceAlpha = entranceAlpha

    -- Entrance: Scale up
    local entranceScale = entrance:CreateAnimation("Scale")
    entranceScale:SetScaleFrom(0.95, 0.95)
    entranceScale:SetScaleTo(1.0, 1.0)
    entranceScale:SetSmoothing("OUT")
    entranceScale:SetOrder(1)
    entranceScale:SetOrigin("LEFT", 0, 0)
    frame._entranceScale = entranceScale

    entrance:SetScript("OnFinished", function()
        frame:SetAlpha(1)
    end)

    frame.animGroups.entrance = entrance

    -- Exit animation group
    local exit = frame:CreateAnimationGroup()

    -- Exit: Alpha fade out
    local exitAlpha = exit:CreateAnimation("Alpha")
    exitAlpha:SetFromAlpha(1)
    exitAlpha:SetToAlpha(0)
    exitAlpha:SetSmoothing("IN")
    exitAlpha:SetOrder(1)
    frame._exitAlpha = exitAlpha

    exit:SetScript("OnFinished", function()
        -- Recycle the toast
        if ns.ToastManager.OnToastFinished then
            ns.ToastManager.OnToastFinished(frame)
        end
    end)

    frame.animGroups.exit = exit
end

-------------------------------------------------------------------------------
-- Play entrance animation
-------------------------------------------------------------------------------

function ns.ToastAnimations.PlayEntrance(frame)
    -- Defensive: clear any stale animation state from previous frame use
    ns.ToastAnimations.StopAll(frame)

    local db = ns.Addon.db.profile

    if not db.animation.enableAnimations then
        frame:SetAlpha(1)
        frame:Show()
        return
    end

    local duration = db.animation.entranceDuration
    frame._entranceAlpha:SetDuration(duration)
    frame._entranceScale:SetDuration(duration)

    -- Calculate entrance slide direction
    local direction = db.animation.entranceDirection or "RIGHT"
    local distance = db.animation.entranceDistance or 300
    local slideX, slideY = 0, 0
    if direction == "RIGHT" then
        slideX = distance
    elseif direction == "LEFT" then
        slideX = -distance
    elseif direction == "TOP" then
        slideY = distance
    elseif direction == "BOTTOM" then
        slideY = -distance
    end

    -- Save final anchor coordinates (set by UpdatePositions before this call)
    local point, relativeTo, relativePoint, finalX, finalY = frame:GetPoint()

    -- Store entrance state for OnUpdate interpolation
    frame._isEntering = true
    frame._entranceStartTime = GetTime()
    frame._entranceDuration = duration
    frame._entranceSlideX = slideX
    frame._entranceSlideY = slideY
    frame._entranceFinalX = finalX
    frame._entranceFinalY = finalY

    -- Move frame to START position (offset from final)
    frame:ClearAllPoints()
    frame:SetPoint(point, relativeTo, relativePoint, finalX + slideX, finalY + slideY)

    -- OnUpdate interpolates position from start toward final
    frame:SetScript("OnUpdate", function(self)
        if not self._isEntering then
            self:SetScript("OnUpdate", nil)
            return
        end

        local progress = math.min((GetTime() - self._entranceStartTime) / self._entranceDuration, 1.0)
        -- OUT easing: 1 - (1-t)^2
        local smooth = 1 - (1 - progress) * (1 - progress)

        -- Remaining offset decreases from full to zero as smooth goes 0→1
        local currentX = (self._entranceFinalX or 0) + self._entranceSlideX * (1 - smooth)
        local currentY = (self._entranceFinalY or 0) + self._entranceSlideY * (1 - smooth)

        local pt, rel, relPt = self:GetPoint()
        self:ClearAllPoints()
        self:SetPoint(pt, rel, relPt, currentX, currentY)

        if progress >= 1.0 then
            self._isEntering = false
            self:SetScript("OnUpdate", nil)
        end
    end)

    -- Show frame (invisible due to alpha=0)
    frame:SetAlpha(0)
    frame:Show()

    -- Play alpha + scale animations (no translation in the group anymore)
    frame.animGroups.entrance:Play()

    -- Safety: if animation didn't start, show frame immediately at final position
    if not frame.animGroups.entrance:IsPlaying() then
        frame:SetAlpha(1)
        frame._isEntering = false
        frame:SetScript("OnUpdate", nil)
        frame:ClearAllPoints()
        frame:SetPoint(point, relativeTo, relativePoint, finalX, finalY)
    end
end

-------------------------------------------------------------------------------
-- Play exit animation
-------------------------------------------------------------------------------

function ns.ToastAnimations.PlayExit(frame)
    -- Guard against double-play
    if frame.animGroups.exit:IsPlaying() then
        return
    end

    -- Clean up entrance if still running
    if frame._isEntering then
        frame._isEntering = false
        frame:SetScript("OnUpdate", nil)
        -- Restore to final position
        if frame._entranceFinalX then
            local pt, rel, relPt = frame:GetPoint()
            frame:ClearAllPoints()
            frame:SetPoint(pt, rel, relPt, frame._entranceFinalX, frame._entranceFinalY)
        end
    end

    local db = ns.Addon.db.profile

    if not db.animation.enableAnimations then
        -- No animation: just hide and recycle instantly
        if ns.ToastManager.OnToastFinished then
            ns.ToastManager.OnToastFinished(frame)
        end
        return
    end

    -- Stop any running entrance animations
    if frame.animGroups.entrance:IsPlaying() then
        frame.animGroups.entrance:Stop()
    end

    -- Set duration from config
    frame._exitAlpha:SetDuration(db.animation.exitDuration)

    -- Ensure we're fully visible before fading
    frame:SetAlpha(1)

    -- Play exit
    frame.animGroups.exit:Play()
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

    local slideSpeed = db.animation.slideSpeed or 0.2

    frame._isSliding = true
    frame._slideStartTime = GetTime()
    frame._slideDuration = slideSpeed
    frame._slideFromY = fromY
    frame._slideToY = toY
    frame._slidePoint = point
    frame._slideRelativeTo = relativeTo
    frame._slideRelativePoint = relativePoint
    frame._slideX = x

    frame:SetScript("OnUpdate", function(self)
        if not self._isSliding then
            self:SetScript("OnUpdate", nil)
            return
        end

        local elapsed = GetTime() - self._slideStartTime
        local progress = math.min(elapsed / self._slideDuration, 1.0)
        local smooth = 1 - (1 - progress) * (1 - progress)

        local currentY = self._slideFromY + (self._slideToY - self._slideFromY) * smooth

        self:ClearAllPoints()
        self:SetPoint(self._slidePoint, self._slideRelativeTo, self._slideRelativePoint,
                      self._slideX, currentY)

        if progress >= 1.0 then
            self._isSliding = false
            self:SetScript("OnUpdate", nil)
        end
    end)
end

-------------------------------------------------------------------------------
-- Stop all animations on a frame
-------------------------------------------------------------------------------

function ns.ToastAnimations.StopAll(frame)
    frame._isEntering = false
    frame._isSliding = false
    frame:SetScript("OnUpdate", nil)

    for _, group in pairs(frame.animGroups) do
        group:Stop()
    end

    -- Guarantee clean visual state after stopping all groups
    frame:SetAlpha(1)
    frame:SetScale(1)
end
