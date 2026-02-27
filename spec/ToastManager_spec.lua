-------------------------------------------------------------------------------
-- ToastManager_spec.lua
-- Unit tests for ToastManager stacking, queue, and dedup logic
-------------------------------------------------------------------------------

local mock = require("spec.wow_mock")

-- Load the module under test
local ns = mock.CreateNamespace()
local TM = mock.LoadToastManager(ns)
local T  -- _test internals (assigned after Initialize)

-------------------------------------------------------------------------------
-- Test helpers
-------------------------------------------------------------------------------

local function makeItemData(overrides)
    local data = {
        itemID = 32837,
        itemName = "Warglaive of Azzinoth",
        itemQuality = 5,
        itemLevel = 156,
        itemType = "Weapon",
        itemSubType = "Sword",
        itemIcon = 135562,
        quantity = 1,
        looter = "TestPlayer",
        isSelf = true,
        isCurrency = false,
        timestamp = GetTime(),
    }
    if overrides then
        for k, v in pairs(overrides) do data[k] = v end
    end
    return data
end

local function makeXPData(overrides)
    local data = {
        isXP = true,
        xpAmount = 500,
        itemIcon = 894556,
        itemName = "+500 XP",
        itemQuality = 1,
        itemLevel = 0,
        quantity = 1,
        looter = "TestPlayer",
        isSelf = true,
        isCurrency = false,
        timestamp = GetTime(),
    }
    if overrides then
        for k, v in pairs(overrides) do data[k] = v end
    end
    return data
end

local function makeHonorData(overrides)
    local data = {
        isHonor = true,
        honorAmount = 100,
        victimName = "Enemy Player",
        itemIcon = 463450,
        itemName = "+100 Honor",
        itemQuality = 1,
        itemLevel = 0,
        quantity = 1,
        looter = "TestPlayer",
        isSelf = true,
        isCurrency = false,
        timestamp = GetTime(),
    }
    if overrides then
        for k, v in pairs(overrides) do data[k] = v end
    end
    return data
end

local function makeGoldData(overrides)
    local data = {
        itemLink = nil,
        itemID = nil,
        copperAmount = 50000,
        itemName = "50000c",
        itemQuality = 1,
        itemLevel = 0,
        itemType = "Currency",
        itemSubType = "Gold",
        itemIcon = 133784,
        quantity = 1,
        looter = "TestPlayer",
        isSelf = true,
        isCurrency = true,
        timestamp = GetTime(),
    }
    if overrides then
        for k, v in pairs(overrides) do data[k] = v end
    end
    return data
end

local function makeCurrencyData(overrides)
    local data = {
        itemID = 99999,
        itemName = "Valor Points",
        itemQuality = 1,
        itemIcon = 123456,
        quantity = 1,
        looter = "TestPlayer",
        isSelf = true,
        isCurrency = true,
        timestamp = GetTime(),
    }
    if overrides then
        for k, v in pairs(overrides) do data[k] = v end
    end
    return data
end

-------------------------------------------------------------------------------
-- Setup
-------------------------------------------------------------------------------

describe("ToastManager", function()

    setup(function()
        -- Initialize once (creates anchor frame, sets isInitialized)
        TM.Initialize()
        T = TM._test
    end)

    before_each(function()
        mock.Reset(ns)
        mock.SetTime(100) -- Start at t=100 to avoid edge cases at 0
    end)

    -- =================================================================
    -- Queue Helpers
    -- =================================================================

    describe("Queue helpers", function()

        it("QueuePush adds items in order", function()
            local q = { first = 1, last = 0 }
            T.QueuePush(q, "a")
            T.QueuePush(q, "b")
            T.QueuePush(q, "c")
            assert.equal(3, T.QueueSize(q))
            assert.equal("a", q[1])
            assert.equal("b", q[2])
            assert.equal("c", q[3])
        end)

        it("QueuePop returns items in FIFO order", function()
            local q = { first = 1, last = 0 }
            T.QueuePush(q, "a")
            T.QueuePush(q, "b")
            T.QueuePush(q, "c")
            assert.equal("a", T.QueuePop(q))
            assert.equal("b", T.QueuePop(q))
            assert.equal("c", T.QueuePop(q))
        end)

        it("QueuePop returns nil on empty queue", function()
            local q = { first = 1, last = 0 }
            assert.is_nil(T.QueuePop(q))
        end)

        it("QueueSize returns correct count", function()
            local q = { first = 1, last = 0 }
            assert.equal(0, T.QueueSize(q))
            T.QueuePush(q, "a")
            assert.equal(1, T.QueueSize(q))
            T.QueuePush(q, "b")
            assert.equal(2, T.QueueSize(q))
            T.QueuePop(q)
            assert.equal(1, T.QueueSize(q))
        end)

        it("QueueReset clears all entries", function()
            local q = { first = 1, last = 0 }
            T.QueuePush(q, "a")
            T.QueuePush(q, "b")
            T.QueueReset(q)
            assert.equal(0, T.QueueSize(q))
            assert.is_nil(T.QueuePop(q))
        end)

        it("Multiple push/pop cycles maintain FIFO", function()
            local q = { first = 1, last = 0 }
            T.QueuePush(q, 1)
            T.QueuePush(q, 2)
            assert.equal(1, T.QueuePop(q))
            T.QueuePush(q, 3)
            assert.equal(2, T.QueuePop(q))
            assert.equal(3, T.QueuePop(q))
            assert.is_nil(T.QueuePop(q))
        end)

    end)

    -- =================================================================
    -- FindDuplicate - Active toast matching
    -- =================================================================

    describe("FindDuplicate - active toasts", function()

        it("returns nil when no active toasts exist", function()
            assert.is_nil(T.FindDuplicate(makeItemData()))
        end)

        it("matches XP toast to active XP toast", function()
            -- Create an active XP toast
            T.ShowToast(makeXPData())
            assert.equal(1, #T.activeToasts)

            -- Second XP should find duplicate
            local existing, idx = T.FindDuplicate(makeXPData())
            assert.is_not_nil(existing)
            assert.equal(1, idx)
        end)

        it("matches Honor toast to active Honor toast", function()
            T.ShowToast(makeHonorData())
            local existing, idx = T.FindDuplicate(makeHonorData())
            assert.is_not_nil(existing)
            assert.equal(1, idx)
        end)

        it("matches Gold toast to active Gold toast", function()
            T.ShowToast(makeGoldData())
            local existing, idx = T.FindDuplicate(makeGoldData())
            assert.is_not_nil(existing)
            assert.equal(1, idx)
        end)

        it("matches item by itemID and isSelf", function()
            T.ShowToast(makeItemData())
            local existing, idx = T.FindDuplicate(makeItemData())
            assert.is_not_nil(existing)
            assert.equal(1, idx)
        end)

        it("returns nil when timestamp exceeds DUPLICATE_WINDOW", function()
            T.ShowToast(makeXPData())
            mock.AdvanceTime(T.DUPLICATE_WINDOW + 0.1)
            assert.is_nil(T.FindDuplicate(makeXPData()))
        end)

        it("returns nil when itemIDs differ", function()
            T.ShowToast(makeItemData({ itemID = 111 }))
            assert.is_nil(T.FindDuplicate(makeItemData({ itemID = 222 })))
        end)

        it("returns nil when isSelf differs", function()
            T.ShowToast(makeItemData({ isSelf = true }))
            assert.is_nil(T.FindDuplicate(makeItemData({ isSelf = false })))
        end)

        it("returns nil for non-gold currency", function()
            assert.is_nil(T.FindDuplicate(makeCurrencyData()))
        end)

    end)

    -- =================================================================
    -- FindDuplicate - Queue matching
    -- =================================================================

    describe("FindDuplicate - queue matching", function()

        it("merges XP in-place in toastQueue", function()
            -- Fill active toasts to max so next goes to queue
            ns.Addon.db.profile.display.maxToasts = 0
            T.ShowToast(makeXPData({ xpAmount = 200 }))
            assert.equal(1, T.QueueSize(T.toastQueue))

            -- Second XP should merge in queue
            local existing, idx = T.FindDuplicate(makeXPData({ xpAmount = 300 }))
            assert.is_not_nil(existing)
            assert.is_nil(idx) -- nil = queued
            assert.equal(500, existing.xpAmount)

            -- Restore
            ns.Addon.db.profile.display.maxToasts = 5
        end)

        it("merges Honor in-place in toastQueue", function()
            ns.Addon.db.profile.display.maxToasts = 0
            T.ShowToast(makeHonorData({ honorAmount = 50 }))

            local existing, idx = T.FindDuplicate(makeHonorData({ honorAmount = 75 }))
            assert.is_not_nil(existing)
            assert.is_nil(idx)
            assert.equal(125, existing.honorAmount)

            ns.Addon.db.profile.display.maxToasts = 5
        end)

        it("merges Gold in-place in toastQueue", function()
            ns.Addon.db.profile.display.maxToasts = 0
            T.ShowToast(makeGoldData({ copperAmount = 10000 }))

            local existing, idx = T.FindDuplicate(makeGoldData({ copperAmount = 20000 }))
            assert.is_not_nil(existing)
            assert.is_nil(idx)
            assert.equal(30000, existing.copperAmount)

            ns.Addon.db.profile.display.maxToasts = 5
        end)

        it("merges item quantity in-place in toastQueue", function()
            ns.Addon.db.profile.display.maxToasts = 0
            T.ShowToast(makeItemData({ quantity = 2 }))

            local existing, idx = T.FindDuplicate(makeItemData({ quantity = 3 }))
            assert.is_not_nil(existing)
            assert.is_nil(idx)
            assert.equal(5, existing.quantity)

            ns.Addon.db.profile.display.maxToasts = 5
        end)

        it("merges in combatQueue when not in toastQueue", function()
            -- Put item in combat queue
            T.QueuePush(T.combatQueue, makeItemData({ quantity = 1 }))

            local existing, idx = T.FindDuplicate(makeItemData({ quantity = 2 }))
            assert.is_not_nil(existing)
            assert.is_nil(idx)
            assert.equal(3, existing.quantity)
        end)

        it("returns nil index for queue matches", function()
            ns.Addon.db.profile.display.maxToasts = 0
            T.ShowToast(makeXPData())

            local _, idx = T.FindDuplicate(makeXPData())
            assert.is_nil(idx)

            ns.Addon.db.profile.display.maxToasts = 5
        end)

    end)

    -- =================================================================
    -- ShowToast - Stacking on active toasts
    -- =================================================================

    describe("ShowToast - stacking", function()

        it("stacks XP: sums xpAmount and updates itemName", function()
            T.ShowToast(makeXPData({ xpAmount = 200 }))
            assert.equal(1, #T.activeToasts)

            T.ShowToast(makeXPData({ xpAmount = 300 }))
            assert.equal(1, #T.activeToasts) -- still 1 toast
            assert.equal(500, T.activeToasts[1].lootData.xpAmount)
            assert.truthy(T.activeToasts[1].lootData.itemName:find("500"))
        end)

        it("stacks Honor: sums honorAmount and updates itemName", function()
            T.ShowToast(makeHonorData({ honorAmount = 50 }))
            T.ShowToast(makeHonorData({ honorAmount = 75 }))
            assert.equal(1, #T.activeToasts)
            assert.equal(125, T.activeToasts[1].lootData.honorAmount)
            assert.truthy(T.activeToasts[1].lootData.itemName:find("125"))
        end)

        it("stacks Gold: sums copperAmount", function()
            T.ShowToast(makeGoldData({ copperAmount = 10000 }))
            T.ShowToast(makeGoldData({ copperAmount = 20000 }))
            assert.equal(1, #T.activeToasts)
            assert.equal(30000, T.activeToasts[1].lootData.copperAmount)
        end)

        it("stacks items: increments quantity", function()
            T.ShowToast(makeItemData({ quantity = 2 }))
            T.ShowToast(makeItemData({ quantity = 3 }))
            assert.equal(1, #T.activeToasts)
            assert.equal(5, T.activeToasts[1].lootData.quantity)
        end)

        it("early returns for queue duplicates", function()
            ns.Addon.db.profile.display.maxToasts = 0
            T.ShowToast(makeXPData({ xpAmount = 100 }))
            assert.equal(0, #T.activeToasts) -- went to queue

            T.ShowToast(makeXPData({ xpAmount = 200 }))
            assert.equal(0, #T.activeToasts) -- merged in queue, no new toast

            ns.Addon.db.profile.display.maxToasts = 5
        end)

        it("creates new toast when no duplicate found", function()
            T.ShowToast(makeItemData({ itemID = 111 }))
            T.ShowToast(makeItemData({ itemID = 222 }))
            assert.equal(2, #T.activeToasts)
        end)

    end)

    -- =================================================================
    -- ShowToast - Overflow
    -- =================================================================

    describe("ShowToast - overflow", function()

        it("pushes to toastQueue when at maxToasts", function()
            ns.Addon.db.profile.display.maxToasts = 2
            T.ShowToast(makeItemData({ itemID = 1 }))
            T.ShowToast(makeItemData({ itemID = 2 }))
            T.ShowToast(makeItemData({ itemID = 3 }))
            assert.equal(2, #T.activeToasts)
            assert.equal(1, T.QueueSize(T.toastQueue))

            ns.Addon.db.profile.display.maxToasts = 5
        end)

        it("FlushQueue drains toastQueue up to maxToasts", function()
            ns.Addon.db.profile.display.maxToasts = 1
            T.ShowToast(makeItemData({ itemID = 1 }))
            T.ShowToast(makeItemData({ itemID = 2 }))
            assert.equal(1, #T.activeToasts)
            assert.equal(1, T.QueueSize(T.toastQueue))

            -- Simulate toast finishing (free up a slot)
            ns.Addon.db.profile.display.maxToasts = 5
            TM.FlushQueue()
            assert.equal(2, #T.activeToasts)
            assert.equal(0, T.QueueSize(T.toastQueue))

            ns.Addon.db.profile.display.maxToasts = 5
        end)

    end)

    -- =================================================================
    -- QueueToast - Guards
    -- =================================================================

    describe("QueueToast - guards", function()

        it("skips when addon disabled", function()
            ns.Addon.db.profile.enabled = false
            TM.QueueToast(makeItemData())
            assert.equal(0, #T.activeToasts)
            ns.Addon.db.profile.enabled = true
        end)

        it("defers to combatQueue during combat", function()
            ns.Addon.db.profile.combat.deferInCombat = true
            mock._inCombat = true
            TM.QueueToast(makeItemData())
            assert.equal(0, #T.activeToasts)
            assert.equal(1, T.QueueSize(T.combatQueue))
            ns.Addon.db.profile.combat.deferInCombat = false
            mock._inCombat = false
        end)

        it("skips when suppressed for normal items", function()
            mock._suppressed = true
            TM.QueueToast(makeItemData())
            assert.equal(0, #T.activeToasts)
            mock._suppressed = false
        end)

        it("bypasses suppression for XP toasts", function()
            mock._suppressed = true
            TM.QueueToast(makeXPData())
            assert.equal(1, #T.activeToasts)
            mock._suppressed = false
        end)

        it("bypasses suppression for Honor toasts", function()
            mock._suppressed = true
            TM.QueueToast(makeHonorData())
            assert.equal(1, #T.activeToasts)
            mock._suppressed = false
        end)

        it("bypasses suppression for currency toasts", function()
            mock._suppressed = true
            TM.QueueToast(makeGoldData())
            assert.equal(1, #T.activeToasts)
            mock._suppressed = false
        end)

    end)

    -- =================================================================
    -- Integration - End-to-end stacking
    -- =================================================================

    describe("Integration - end-to-end stacking", function()

        it("5 rapid XP events produce 1 toast with summed XP", function()
            for i = 1, 5 do
                TM.QueueToast(makeXPData({ xpAmount = 100 * i }))
            end
            assert.equal(1, #T.activeToasts)
            -- 100 + 200 + 300 + 400 + 500 = 1500
            assert.equal(1500, T.activeToasts[1].lootData.xpAmount)
        end)

        it("3 identical items produce 1 toast with quantity 3", function()
            TM.QueueToast(makeItemData({ quantity = 1 }))
            TM.QueueToast(makeItemData({ quantity = 1 }))
            TM.QueueToast(makeItemData({ quantity = 1 }))
            assert.equal(1, #T.activeToasts)
            assert.equal(3, T.activeToasts[1].lootData.quantity)
        end)

        it("3 gold events produce 1 toast with summed copper", function()
            TM.QueueToast(makeGoldData({ copperAmount = 10000 }))
            TM.QueueToast(makeGoldData({ copperAmount = 20000 }))
            TM.QueueToast(makeGoldData({ copperAmount = 30000 }))
            assert.equal(1, #T.activeToasts)
            assert.equal(60000, T.activeToasts[1].lootData.copperAmount)
        end)

        it("event after DUPLICATE_WINDOW creates separate toast", function()
            TM.QueueToast(makeXPData({ xpAmount = 100 }))
            assert.equal(1, #T.activeToasts)

            mock.AdvanceTime(T.DUPLICATE_WINDOW + 0.1)
            TM.QueueToast(makeXPData({ xpAmount = 200 }))
            assert.equal(2, #T.activeToasts)
        end)

    end)

end)
