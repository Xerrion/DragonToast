-------------------------------------------------------------------------------
-- TestToasts_spec.lua
-- Mass loot previews exercise the real queue without collapsing into stacks
--
-- Supported versions: TBC Anniversary, Retail, MoP Classic
-------------------------------------------------------------------------------

local Harness = require("spec.animation_harness")

if not Harness.IsAvailable() then
    describe("Mass loot test", function()
        pending("LibAnimate submodule missing: git submodule update --init DragonToast/Libs/LibAnimate")
    end)
    return
end

describe("Mass loot test", function()
    local h

    local function AllLoot()
        local entries = {}
        local state = h.ns.ToastManager._test
        for _, frame in ipairs(state.activeToasts) do entries[#entries + 1] = frame.lootData end
        for index = state.toastQueue.first, state.toastQueue.last do
            entries[#entries + 1] = state.toastQueue[index]
        end
        return entries
    end

    before_each(function()
        h = Harness.New()
        assert(loadfile("DragonToast/Display/TestToasts.lua"))("DragonToast", h.ns)
    end)

    after_each(function() h:Restore() end)

    it("queues 30 varied, distinct entries in one burst by default", function()
        assert.is_true(h.ns.TestToasts.RunMassLootTest())
        local entries = AllLoot()
        assert.equal(30, #entries)
        assert.equal(1, #h:Visible())
        assert.equal(29, h.ns.ToastManager._test.QueueSize(h.ns.ToastManager._test.toastQueue))
        local seen, kinds = {}, {}
        for _, data in ipairs(entries) do
            assert.is_not_nil(data._testToastID)
            assert.is_nil(seen[data._testToastID])
            seen[data._testToastID] = true
            assert.equal(0, data.timestamp)
            if data.itemLink then
                assert.is_not_nil(data.itemLink:find("|Hitem:" .. data.itemID .. ":", 1, true))
                kinds.item = true
            end
            if data.copperAmount then kinds.money = true end
            if data.isXP then kinds.xp = true end
            if data.isHonor then kinds.honor = true end
            if data.isReputation then kinds.reputation = true end
        end
        assert.same({ item = true, money = true, xp = true, honor = true, reputation = true }, kinds)
        assert.equal(1, h:PendingTimerCount())
    end)

    it("accepts a custom count up to 100", function()
        assert.is_true(h.ns.TestToasts.RunMassLootTest("100"))
        assert.equal(100, #AllLoot())
    end)

    it("does not merge repeated batches or contaminate ordinary loot stacking", function()
        h.ns.TestToasts.RunMassLootTest(1)
        h.ns.TestToasts.RunMassLootTest(1)
        local entries = AllLoot()
        local itemID = entries[1].itemID
        assert.equal(itemID, entries[2].itemID)
        assert.are_not.equal(entries[1]._testToastID, entries[2]._testToastID)
        h:Queue(itemID, { quantity = 2 })
        h:Queue(itemID, { quantity = 3 })
        entries = AllLoot()
        assert.equal(3, #entries)
        local ordinary
        for _, data in ipairs(entries) do
            if not data._testToastID then ordinary = data end
        end
        assert.is_not_nil(ordinary)
        assert.equal(5, ordinary.quantity)
    end)

    it("rejects invalid counts without queuing any entries", function()
        local message
        h.ns.Print = function(value) message = value end
        for _, count in ipairs({ "0", "101", "-1", "1.5", "many", "10 extra", "inf", "nan" }) do
            assert.is_false(h.ns.TestToasts.RunMassLootTest(count))
            assert.equal("Usage: /dt massloot [count] (1-100, default 30).", message)
        end
        assert.equal(0, #AllLoot())
        assert.equal(0, h:PendingTimerCount())
    end)

    it("admits every generated toast through the normal capacity and stagger", function()
        local admissions = {}
        local play = h.ns.ToastAnimations.PlayLifecycle
        h.ns.ToastAnimations.PlayLifecycle = function(frame, data)
            admissions[#admissions + 1] = { id = data._testToastID, time = h.now }
            play(frame, data)
        end
        h.ns.TestToasts.RunMassLootTest()
        for _ = 1, 400 do
            h:Advance(0.1)
            assert.is_true(#h:Visible() <= h.ns.Addon.db.profile.display.maxToasts)
        end
        assert.equal(30, #admissions)
        for i, admission in ipairs(admissions) do
            assert.equal(i, admission.id)
            if i > 1 then
                assert.is_true(admission.time - admissions[i - 1].time >= 0.1 - 0.00001)
            end
        end
        assert.equal(0, #AllLoot())
        assert.equal(0, h:PendingTimerCount())
    end)

    it("clears the batch without delayed test generators bringing it back", function()
        h.ns.TestToasts.RunMassLootTest()
        h:Advance(0.5)
        h.ns.ToastManager.ClearAll()
        h:Advance(30)
        assert.equal(0, #AllLoot())
        assert.equal(0, #h:Visible())
        assert.equal(0, h:PendingTimerCount())
        assert.is_nil(next(h.lib.activeAnimations))
    end)
end)
