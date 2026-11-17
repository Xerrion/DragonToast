-------------------------------------------------------------------------------
-- ToastAnimations_spec.lua
-- Integration regressions for burst admission, animation motion, and recycling.
-- These exercise the real LibAnimate driver and real toast frames with a clock.
-- Supported versions: TBC Anniversary, Retail, MoP Classic
-------------------------------------------------------------------------------

local Harness = require("spec.animation_harness")
local EPSILON = 0.001

if not Harness.IsAvailable() then
    describe("Toast animation integration", function()
        pending("LibAnimate submodule missing: git submodule update --init DragonToast/Libs/LibAnimate")
    end)
    return
end

describe("Toast animation integration", function()
    local h

    local function Start(overrides)
        h = Harness.New(overrides)
        return h.ns.ToastManager
    end

    local function LayoutY(frame)
        local _, y = h:Position(frame.layoutFrame or frame)
        return y
    end

    local function Spacing()
        local profile = h.ns.Addon.db.profile
        return profile.display.toastHeight + profile.display.spacing + profile.appearance.borderSize
    end

    local function AssertNear(expected, actual, message)
        assert.is_true(math.abs(expected - actual) < EPSILON,
            (message or "Unexpected position") .. ": expected " .. expected .. ", got " .. actual)
    end

    local function AssertSeparated()
        local positions = {}
        for _, frame in ipairs(h:Visible()) do positions[#positions + 1] = LayoutY(frame) end
        table.sort(positions)
        for i = 2, #positions do
            assert.is_true(positions[i] - positions[i - 1] >= Spacing() - EPSILON,
                "Visible toasts overlap at t=" .. h.now .. ": " .. positions[i - 1] .. ", " .. positions[i])
        end
    end

    local function Sample(seconds, callback)
        local finish = h.now + seconds
        while h.now < finish - 1e-9 do
            h:Advance(math.min(1 / 120, finish - h.now))
            callback()
        end
    end

    local function RecordAdmissions()
        local admissions = {}
        local play = h.ns.ToastAnimations.PlayLifecycle
        h.ns.ToastAnimations.PlayLifecycle = function(frame, data)
            admissions[#admissions + 1] = { id = data.itemID, time = h.now, frame = frame }
            play(frame, data)
        end
        return admissions
    end

    after_each(function()
        if h then h:Restore(); h = nil end
    end)

    for _, direction in ipairs({ "UP", "DOWN" }) do
        it("keeps a seven-item burst separated while growing " .. direction, function()
            Start({ display = { growDirection = direction }, animation = { holdDuration = 20 } })
            local admissions = RecordAdmissions()
            for id = 1, 7 do h:Queue(id) end
            AssertSeparated()
            Sample(3, AssertSeparated)
            assert.equal(7, #h:Visible())
            assert.equal(7, #admissions)
            for i, admission in ipairs(admissions) do assert.equal(i, admission.id) end
            local sign = direction == "UP" and 1 or -1
            assert.is_true(sign * (LayoutY(h:Find(1)) - LayoutY(h:Find(7))) > 0)
        end)
    end

    it("retargets an in-progress stack movement without a position jump", function()
        Start({ animation = { holdDuration = 20 } })
        local first = h:Queue(1)
        h:Advance(0.5)
        h:Queue(2)
        h:Advance(0.05)
        local before = LayoutY(first)
        h:Queue(3)
        h:Step(0)
        AssertNear(before, LayoutY(first), "Another arrival jumped an existing toast")
        Sample(1, AssertSeparated)
        assert.equal(3, #h:Visible())
    end)

    it("finishes stack movement across the hold-to-exit transition", function()
        Start({ animation = { entranceDuration = 0.1, holdDuration = 0.5, exitDuration = 1 } })
        local first = h:Queue(1)
        h:Advance(0.55)
        local initialY = LayoutY(first)
        h:Queue(2)
        h:Advance(0.3)
        assert.equal("exit", first._phase)
        AssertNear(initialY + Spacing(), LayoutY(first), "Exit transition abandoned a slide")
        AssertSeparated()
    end)

    for _, attention in ipairs({ "pulse", "flash", "bounce" }) do
        it("moves the layout while " .. attention .. " attention continues", function()
            Start({ animation = {
                entranceDuration = 0.1, holdDuration = 20, attentionAnimation = attention,
                attentionDelay = 0, attentionRepeatCount = 1,
            } })
            local first = h:Queue(1)
            h:Advance(0.4)
            assert.equal("attention", first._phase)
            local phaseStart = h.lib.activeAnimations[first].startTime
            local initialY = LayoutY(first)
            h:Queue(2)
            h:Advance(0.4)
            assert.equal("attention", first._phase)
            AssertNear(initialY + Spacing(), LayoutY(first), "Attention prevented layout movement")
            AssertNear(phaseStart, h.lib.activeAnimations[first].startTime, "Attention restarted")
            AssertSeparated()
        end)
    end

    it("honors the admission stagger when several toasts finish together", function()
        local manager = Start({
            display = { maxToasts = 3, queueStagger = 0.15 },
            animation = { holdDuration = 20, entranceDuration = 0.1, slideSpeed = 0.1 },
        })
        local admissions = RecordAdmissions()
        for id = 1, 6 do h:Queue(id) end
        h:Advance(1)
        assert.equal(3, #admissions)
        local old = h:Visible()
        for _, frame in ipairs(old) do manager.OnToastFinished(frame) end
        assert.is_true(#admissions <= 4, "Concurrent completions bypassed admission pacing")
        Sample(1, AssertSeparated)
        assert.equal(6, #admissions)
        for i = 5, 6 do
            assert.is_true(admissions[i].time - admissions[i - 1].time >= 0.15 - EPSILON)
        end
        for i, admission in ipairs(admissions) do assert.equal(i, admission.id) end
    end)

    it("keeps an exiting toast separate from newly admitted items", function()
        Start({ animation = { entranceDuration = 0.1, holdDuration = 1, exitDuration = 1 } })
        local first = h:Queue(1)
        h:Advance(0.35)
        h:Queue(2)
        h:Advance(0.35)
        h:Queue(3)
        h:Advance(0.5)
        assert.equal("exit", first._phase)
        h:Queue(4)
        Sample(0.7, AssertSeparated)
        assert.is_not_nil(h:Find(4))
    end)

    it("pins a hovered fractional position and resumes admissions after leaving", function()
        Start({ animation = { holdDuration = 20 } })
        local first = h:Queue(1)
        h:Advance(0.5)
        h:Queue(2)
        h:Advance(0.05)
        local pinnedY = LayoutY(first)
        h:Enter(first)
        assert.is_true(first._isHovered)
        h:Queue(3)
        Sample(0.5, function()
            AssertNear(pinnedY, LayoutY(first), "Hover moved to a rounded slot")
            AssertSeparated()
        end)
        h:Leave(first)
        h:Step(0)
        AssertNear(pinnedY, LayoutY(first), "Unhover snapped to the target position")
        Sample(1.5, AssertSeparated)
        assert.equal(3, #h:Visible())
    end)

    it("lets other toast lifecycles finish while one toast is hovered", function()
        Start({ animation = { entranceDuration = 0.1, holdDuration = 1, exitDuration = 0.2 } })
        local first = h:Queue(1)
        h:Queue(2)
        h:Advance(0.6)
        local second = h:Find(2)
        assert.is_not_nil(second)
        h:Enter(first)
        local pinnedY = LayoutY(first)
        h:Advance(2)
        assert.equal(first, h:Find(1))
        assert.is_nil(h:Find(2))
        assert.is_true(second._isPooled)
        AssertNear(pinnedY, LayoutY(first))
        h:Leave(first)
        h:Advance(0.3)
        assert.equal(0, #h:Visible())
    end)

    it("ignores hover during entrance without freezing later admissions", function()
        Start({ animation = { holdDuration = 20 } })
        local first = h:Queue(1)
        h:Advance(0.1)
        h:Enter(first)
        assert.is_not_true(first._isHovered)
        h:Queue(2)
        Sample(0.7, AssertSeparated)
        assert.equal(2, #h:Visible())
    end)

    it("preserves lifetime when a duplicate updates a visible toast", function()
        Start({ animation = { entranceDuration = 0.1, holdDuration = 0.6, exitDuration = 0.2 } })
        local admissions = RecordAdmissions()
        local first = h:Queue(1)
        h:Advance(0.5)
        h:Queue(1, { quantity = 3 })
        assert.equal(4, first.lootData.quantity)
        assert.equal(1, #admissions)
        h:Advance(0.5)
        assert.is_nil(h:Find(1))
        assert.equal(0, #h:Visible())
    end)

    it("pauses and resumes a no-animation toast without leaking its timer", function()
        Start({ animation = { enableAnimations = false, holdDuration = 1 } })
        local first = h:Queue(1)
        h:Advance(0.4)
        h:Enter(first)
        assert.equal(0, h:PendingTimerCount())
        h:Advance(2)
        assert.equal(first, h:Find(1))
        h:Leave(first)
        h:Advance(0.5)
        assert.equal(first, h:Find(1))
        h:Advance(0.2)
        assert.equal(0, #h:Visible())
        assert.equal(0, h:PendingTimerCount())
    end)

    it("clears in-flight admissions and safely reuses frames across repeated clears", function()
        local manager = Start({ animation = { holdDuration = 20 } })
        local original = h:Queue(1)
        for id = 2, 10 do h:Queue(id) end
        h:Advance(0.05)
        manager.ClearAll()
        manager.ClearAll()
        assert.equal(0, #h:Visible())
        assert.equal(0, h:PendingTimerCount())
        assert.is_nil(next(h.lib.activeAnimations))
        h:Advance(1)
        assert.equal(0, #h:Visible())
        local reused = h:Queue(100)
        assert.equal(original, reused)
        assert.is_false(reused._isPooled)
        h:Advance(0.4)
        assert.equal("hold", reused._phase)
        for id = 101, 103 do h:Queue(id) end
        Sample(1.5, AssertSeparated)
        assert.equal(4, #h:Visible())
        local seen = {}
        for _, frame in ipairs(h:Visible()) do
            assert.is_nil(seen[frame], "A pooled frame was acquired twice")
            seen[frame] = true
        end
    end)

    it("drains a long mixed burst in FIFO order without stranded frames or timers", function()
        Start({
            display = { maxToasts = 4, queueStagger = 0.08 },
            animation = { entranceDuration = 0.1, holdDuration = 0.7, exitDuration = 0.3, slideSpeed = 0.12 },
        })
        local admissions = RecordAdmissions()
        for id = 1, 30 do
            local fields = id % 3 == 0 and { isCurrency = true, currencyID = id } or nil
            h:Queue(id, fields)
            if id % 5 == 0 then Sample(0.075, AssertSeparated) end
        end
        Sample(15, function()
            AssertSeparated()
            assert.is_true(#h:Visible() <= 4)
        end)
        assert.equal(30, #admissions)
        for i, admission in ipairs(admissions) do assert.equal(i, admission.id) end
        assert.equal(0, #h:Visible())
        assert.equal(0, h:PendingTimerCount())
        assert.is_nil(next(h.lib.activeAnimations))
    end)

    it("cleans up old work when animations are toggled off and back on", function()
        local manager = Start({ animation = { holdDuration = 0.8 } })
        local first = h:Queue(1)
        h:Advance(0.4)
        h:Enter(first)
        h.ns.Addon.db.profile.animation.enableAnimations = false
        h:Leave(first)
        manager.ClearAll()
        assert.equal(0, h:PendingTimerCount())
        assert.is_nil(next(h.lib.activeAnimations))
        h:Queue(2)
        h:Advance(1)
        assert.equal(0, #h:Visible())
        h.ns.Addon.db.profile.animation.enableAnimations = true
        local third = h:Queue(3)
        h:Advance(0.4)
        assert.equal("hold", third._phase)
        h:Advance(1.5)
        assert.equal(0, #h:Visible())
        assert.equal(0, h:PendingTimerCount())
    end)

    it("resumes a hovered animated exit after animations are disabled", function()
        Start({ animation = { entranceDuration = 0.1, holdDuration = 0.2, exitDuration = 0.3 } })
        local frame = h:Queue(1)
        h:Advance(0.4)
        assert.equal("exit", frame._phase)
        h:Enter(frame)
        local alpha = frame:GetAlpha()
        h:Advance(1)
        AssertNear(alpha, frame:GetAlpha(), "Hovered exit kept fading")
        h.ns.Addon.db.profile.animation.enableAnimations = false
        h:Leave(frame)
        h:Advance(0.4)
        assert.equal(0, #h:Visible())
        assert.is_nil(next(h.lib.activeAnimations))
    end)

    it("resumes a hovered timer after animations are enabled", function()
        Start({ animation = { enableAnimations = false, holdDuration = 1 } })
        local frame = h:Queue(1)
        h:Advance(0.4)
        h:Enter(frame)
        h.ns.Addon.db.profile.animation.enableAnimations = true
        h:Leave(frame)
        h:Advance(0.7)
        assert.equal(0, #h:Visible())
        assert.equal(0, h:PendingTimerCount())
    end)

    it("releases a hovered toast after pause-on-hover is disabled", function()
        Start({ animation = { entranceDuration = 0.1, holdDuration = 0.2, exitDuration = 0.2 } })
        local frame = h:Queue(1)
        h:Advance(0.15)
        h:Enter(frame)
        h:Advance(0.4)
        h.ns.Addon.db.profile.animation.pauseOnHover = false
        h:Leave(frame)
        h:Advance(0.3)
        assert.equal(0, #h:Visible())
        assert.is_nil(next(h.lib.activeAnimations))
    end)

    it("restores normal strata when a hovered frame is cleared and reused", function()
        local manager = Start({ animation = { holdDuration = 20 } })
        local frame = h:Queue(1)
        h:Advance(0.4)
        h:Enter(frame)
        assert.equal("HIGH", frame:GetFrameStrata())
        manager.ClearAll()
        h:Leave(frame)
        local reused = h:Queue(2)
        assert.equal(frame, reused)
        assert.equal("MEDIUM", reused:GetFrameStrata())
        assert.is_not_true(reused._isHovered)
    end)

    for _, enabled in ipairs({ true, false }) do
        it("ignores a stale " .. (enabled and "effect" or "timer") .. " callback after pool reuse", function()
            local manager = Start({ animation = { enableAnimations = enabled, holdDuration = 1 } })
            local frame = h:Queue(1)
            local callback
            if enabled then
                h:Advance(1.4)
                assert.equal("exit", frame._phase)
                callback = h.lib.activeAnimations[frame].onFinished
            else
                callback = frame._noAnimTimer.callback
            end
            manager.ClearAll()
            local reused = h:Queue(2)
            assert.equal(frame, reused)
            local phase = reused._phase
            callback(frame)
            assert.equal(reused, h:Find(2))
            assert.equal(phase, reused._phase)
            assert.is_false(reused._isPooled)
            assert.equal(1, #h:Visible())
            h:Advance(2)
            assert.equal(0, #h:Visible())
        end)
    end

    it("changes the first row anchor and resizes both layout and visual frames", function()
        local manager = Start({ animation = { holdDuration = 20, attentionAnimation = "pulse" } })
        local first = h:Queue(1)
        h:Advance(0.5)
        assert.equal("BOTTOMRIGHT", (first.layoutFrame:GetPoint()))
        h.ns.Addon.db.profile.display.growDirection = "DOWN"
        manager.UpdatePositions()
        assert.equal("TOPRIGHT", (first.layoutFrame:GetPoint()))
        local profile = h.ns.Addon.db.profile
        profile.display.toastWidth = 420
        profile.display.toastHeight = 60
        manager.UpdateLayout()
        assert.equal(420, first:GetWidth())
        assert.equal(420, first.layoutFrame:GetWidth())
        assert.equal(60, first:GetHeight())
        assert.equal(60, first.layoutFrame:GetHeight())
        h:Queue(2)
        Sample(0.5, AssertSeparated)
        assert.equal(2, #h:Visible())
        assert.is_true(LayoutY(first) < LayoutY(h:Find(2)))
    end)

    it("preserves queued duplicate quantities while admitting entries in FIFO order", function()
        local manager = Start({ display = { maxToasts = 1 }, animation = { holdDuration = 20 } })
        local admissions = RecordAdmissions()
        local first = h:Queue(1)
        h:Queue(2)
        h:Queue(2, { quantity = 4 })
        h:Queue(3)
        manager.OnToastFinished(first)
        h:Advance(0.5)
        local second = h:Find(2)
        assert.is_not_nil(second)
        assert.equal(5, second.lootData.quantity)
        manager.OnToastFinished(second)
        h:Advance(0.5)
        assert.is_not_nil(h:Find(3))
        assert.equal(3, #admissions)
        for i, admission in ipairs(admissions) do assert.equal(i, admission.id) end
    end)

    it("pumps combat-deferred and live arrivals through one FIFO admission path", function()
        Start({ combat = { deferInCombat = true }, animation = { holdDuration = 20 } })
        local admissions = RecordAdmissions()
        h.inCombat = true
        for id = 1, 3 do h:Queue(id) end
        assert.equal(0, #h:Visible())
        h.inCombat = false
        h:FireEvent("PLAYER_REGEN_ENABLED")
        h:Queue(4)
        Sample(2, AssertSeparated)
        assert.equal(4, #admissions)
        for i, admission in ipairs(admissions) do assert.equal(i, admission.id) end
    end)

    it("retargets shrinking rows continuously when another toast finishes mid-slide", function()
        local manager = Start({ animation = { holdDuration = 20 } })
        for id = 1, 4 do h:Queue(id) end
        h:Advance(1.5)
        manager.OnToastFinished(h:Find(4))
        h:Advance(0.05)
        local first, second = h:Find(1), h:Find(2)
        local firstY, secondY = LayoutY(first), LayoutY(second)
        manager.OnToastFinished(h:Find(3))
        h:Step(0)
        AssertNear(firstY, LayoutY(first), "Older row jumped during a second removal")
        AssertNear(secondY, LayoutY(second), "Newer row jumped during a second removal")
        Sample(0.3, function()
            AssertSeparated()
            local visualX, visualY = h:Position(first)
            local layoutX, layoutY = h:Position(first.layoutFrame)
            AssertNear(layoutX, visualX, "Visual toast did not follow its layout parent")
            AssertNear(layoutY, visualY, "Visual toast did not follow its layout parent")
        end)
        assert.equal(2, #h:Visible())
    end)

    it("resumes queued admissions when a geometry edit ends blocking hover", function()
        local manager = Start({ animation = { holdDuration = 20 } })
        local first = h:Queue(1)
        h:Advance(0.5)
        h:Enter(first)
        h:Queue(2)
        assert.equal(0, h:PendingTimerCount())
        h.ns.Addon.db.profile.display.toastHeight = 80
        manager.UpdateLayout()
        Sample(1, AssertSeparated)
        assert.is_not_nil(h:Find(2))
        assert.equal(2, #h:Visible())
    end)

    it("applies a larger row height promptly while a middle toast is hovered", function()
        local manager = Start({ animation = { holdDuration = 20 } })
        for id = 1, 3 do h:Queue(id) end
        h:Advance(1)
        h:Enter(h:Find(2))
        h.ns.Addon.db.profile.display.toastHeight = 120
        manager.UpdateLayout()
        AssertSeparated()
        for _, frame in ipairs(h:Visible()) do
            assert.equal(120, frame:GetHeight())
            assert.equal(120, frame.layoutFrame:GetHeight())
        end
        h:Leave(h:Find(2))
        Sample(0.4, AssertSeparated)
    end)

    it("applies a new growth direction promptly while a middle toast is hovered", function()
        local manager = Start({ animation = { holdDuration = 20 } })
        for id = 1, 3 do h:Queue(id) end
        h:Advance(1)
        h:Enter(h:Find(2))
        h.ns.Addon.db.profile.display.growDirection = "DOWN"
        manager.UpdatePositions()
        for _, frame in ipairs(h:Visible()) do assert.equal("TOPRIGHT", (frame.layoutFrame:GetPoint())) end
        AssertSeparated()
        assert.is_true(LayoutY(h:Find(1)) < LayoutY(h:Find(3)))
        h:Leave(h:Find(2))
        Sample(0.4, AssertSeparated)
    end)
end)
