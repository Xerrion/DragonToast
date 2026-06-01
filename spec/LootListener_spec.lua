-------------------------------------------------------------------------------
-- LootListener_spec.lua
-- Unit tests for shared loot listener message parsing
-------------------------------------------------------------------------------

local mock = require("spec.wow_mock")

local ITEM_LINK = "|cffffffff|Hitem:12345::::::::|h[Amani Training Dummy]|h|r"
local ITEM_NAME = "Amani Training Dummy"

local function SetLootGlobals()
    rawset(_G, "GOLD_AMOUNT", "%dg")
    rawset(_G, "SILVER_AMOUNT", "%ds")
    rawset(_G, "COPPER_AMOUNT", "%dc")
    rawset(_G, "GOLD_AMOUNT_TEXTURE", "%d|Tgold|t")
    rawset(_G, "SILVER_AMOUNT_TEXTURE", "%d|Tsilver|t")
    rawset(_G, "COPPER_AMOUNT_TEXTURE", "%d|Tcopper|t")
    rawset(_G, "UNKNOWN", "Unknown")
    rawset(_G, "GetItemInfo", function(itemLink)
        local itemName = itemLink and itemLink:match("%[(.-)%]")
        if not itemName then return nil end

        return itemName, itemLink, 1, 1, 1, "Miscellaneous", "Junk", 1, "", 134400
    end)
    rawset(_G, "geterrorhandler", function()
        return function(message) error(message, 0) end
    end)
end

local function LoadListenerUtils(ns)
    local chunk, err = loadfile("DragonToast/Core/ListenerUtils.lua")
    if not chunk then
        error("Failed to load DragonToast/Core/ListenerUtils.lua: " .. (err or "unknown error"))
    end

    chunk("DragonToast", ns)
end

local function LoadLootListenerShared(ns)
    local chunk, err = loadfile("DragonToast/Listeners/LootListener_Shared.lua")
    if not chunk then
        error("Failed to load DragonToast/Listeners/LootListener_Shared.lua: " .. (err or "unknown error"))
    end

    chunk("DragonToast", ns)
end

local function CreateAddon(eventHandlers)
    return {
        db = {
            profile = {
                enabled = true,
                filters = {
                    minQuality = 0,
                    showSelfLoot = true,
                    showGroupLoot = true,
                    showGold = true,
                    showQuestItems = true,
                },
            },
        },
        RegisterEvent = function(_, eventName, handler)
            eventHandlers[eventName] = handler
        end,
        UnregisterEvent = function(_, eventName)
            eventHandlers[eventName] = nil
        end,
        ScheduleTimer = function(_, callback)
            callback()
        end,
    }
end

local function CreateLootListenerHarness(lootCategories)
    SetLootGlobals()

    local ns = mock.CreateNamespace()
    local queuedToasts = {}
    local eventHandlers = {}

    ns.ListenerUtils = {}
    ns.LootListenerShared = {}
    ns.ToastManager.QueueToast = function(lootData)
        queuedToasts[#queuedToasts + 1] = lootData
    end

    LoadListenerUtils(ns)
    LoadLootListenerShared(ns)

    local listener = ns.LootListenerShared.Create({
        versionName = "Spec",
        lootCategories = lootCategories,
    })
    listener.Initialize(CreateAddon(eventHandlers))

    return {
        queuedToasts = queuedToasts,
        chatLoot = eventHandlers.CHAT_MSG_LOOT,
    }
end

local function CreateDefaultHarness()
    return CreateLootListenerHarness({
        {
            name = "loot",
            self = {
                single = { fallbackString = "You receive loot: %s" },
                multi = { fallbackString = "You receive loot: %s x%d" },
            },
            other = {
                single = { fallbackString = "%s receives loot: %s." },
                multi = { fallbackString = "%s receives loot: %s x%d." },
            },
        },
    })
end

local function CreateCleanerLootMessagesHarness()
    return CreateLootListenerHarness({
        {
            name = "loot",
            self = {
                single = { globalString = "+ %s", fallbackString = "You receive loot: %s" },
                multi = { globalString = "+ %s x%d", fallbackString = "You receive loot: %s x%d" },
            },
            other = {
                single = { globalString = "+ %s : %s", fallbackString = "%s receives loot: %s." },
                multi = { globalString = "+ %s : %s x%d", fallbackString = "%s receives loot: %s x%d." },
            },
        },
    })
end

local function DispatchLoot(harness, message)
    harness.chatLoot(nil, message)
    assert.equal(1, #harness.queuedToasts)
    return harness.queuedToasts[1]
end

describe("LootListenerShared loot parsing", function()
    before_each(function()
        mock.SetTime(100)
    end)

    it("parses CleanerLootMessages other-player loot without self attribution", function()
        local harness = CreateCleanerLootMessagesHarness()
        local lootData = DispatchLoot(harness, "+ Orwyn : " .. ITEM_LINK)

        assert.equal("Orwyn", lootData.looter)
        assert.is_false(lootData.isSelf)
        assert.equal(ITEM_LINK, lootData.itemLink)
        assert.equal(ITEM_NAME, lootData.itemName)
        assert.equal(1, lootData.quantity)
    end)

    it("parses CleanerLootMessages self loot as the local player", function()
        local harness = CreateCleanerLootMessagesHarness()
        local lootData = DispatchLoot(harness, "+ " .. ITEM_LINK)

        assert.equal("TestPlayer", lootData.looter)
        assert.is_true(lootData.isSelf)
        assert.equal(ITEM_LINK, lootData.itemLink)
        assert.equal(ITEM_NAME, lootData.itemName)
        assert.equal(1, lootData.quantity)
    end)

    it("parses CleanerLootMessages other-player loot quantities", function()
        local harness = CreateCleanerLootMessagesHarness()
        local lootData = DispatchLoot(harness, "+ Orwyn : " .. ITEM_LINK .. " x3")

        assert.equal("Orwyn", lootData.looter)
        assert.is_false(lootData.isSelf)
        assert.equal(3, lootData.quantity)
    end)

    it("parses CleanerLootMessages self loot quantities", function()
        local harness = CreateCleanerLootMessagesHarness()
        local lootData = DispatchLoot(harness, "+ " .. ITEM_LINK .. " x2")

        assert.equal("TestPlayer", lootData.looter)
        assert.is_true(lootData.isSelf)
        assert.equal(2, lootData.quantity)
    end)

    it("parses Blizzard other-player loot", function()
        local harness = CreateDefaultHarness()
        local lootData = DispatchLoot(harness, "Orwyn receives loot: " .. ITEM_LINK .. ".")

        assert.equal("Orwyn", lootData.looter)
        assert.is_false(lootData.isSelf)
        assert.equal(ITEM_LINK, lootData.itemLink)
        assert.equal(ITEM_NAME, lootData.itemName)
        assert.equal(1, lootData.quantity)
    end)

    it("parses Blizzard self loot", function()
        local harness = CreateDefaultHarness()
        local lootData = DispatchLoot(harness, "You receive loot: " .. ITEM_LINK)

        assert.equal("TestPlayer", lootData.looter)
        assert.is_true(lootData.isSelf)
        assert.equal(ITEM_LINK, lootData.itemLink)
        assert.equal(ITEM_NAME, lootData.itemName)
        assert.equal(1, lootData.quantity)
    end)
end)
