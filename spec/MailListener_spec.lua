-------------------------------------------------------------------------------
-- MailListener_spec.lua
-- Unit tests for mail collection hooks and deferred toast metadata
-------------------------------------------------------------------------------

local mock = require("spec.wow_mock")

local ITEM_ID = 12345
local ITEM_NAME = "Amani Training Dummy"
local ITEM_LINK = "|cff0070dd|Hitem:12345::::::::|h[Amani Training Dummy]|h|r"
local ITEM_DESCRIPTION = "An item description, not the attachment hyperlink"
local ITEM_ICON = 134400
local ITEM_COUNT = 3
local MONEY = 12345
local MONEY_TEXT = "1|Tgold|t23|Tsilver|t45|Tcopper|t"
local SOURCE_LABEL = "Mail - TestSender"

local MAIL_GLOBALS = {
    "C_Item", "C_CurrencyInfo", "GetItemInfo", "GetCoinTextureString",
    "GetInboxHeaderInfo", "GetInboxItem", "GetInboxInvoiceInfo", "GetInboxText", "hooksecurefunc",
    "GOLD_AMOUNT", "SILVER_AMOUNT", "COPPER_AMOUNT",
    "GOLD_AMOUNT_TEXTURE", "SILVER_AMOUNT_TEXTURE", "COPPER_AMOUNT_TEXTURE",
}

local function LoadModule(path, ns)
    local chunk, err = loadfile(path)
    if not chunk then
        error("Failed to load " .. path .. ": " .. (err or "unknown error"))
    end
    chunk("DragonToast", ns)
end

local function CreateMailListenerHarness()
    local itemState = { cached = true }
    local hooks = {}
    local eventHandlers = {}
    local queuedToasts = {}

    rawset(_G, "GetItemInfo", nil)
    rawset(_G, "GetCoinTextureString", nil)
    rawset(_G, "C_Item", {
        GetItemInfo = function(itemID)
            if itemID ~= ITEM_ID or not itemState.cached then return nil end

            return ITEM_NAME, ITEM_LINK, 3, 80, 70, "Miscellaneous", "Junk", 20, "", ITEM_ICON,
                0, 15, 0, 0, 0, false, false, ITEM_DESCRIPTION
        end,
    })
    rawset(_G, "C_CurrencyInfo", {
        GetCoinTextureString = function(copper)
            assert.equal(MONEY, copper)
            return MONEY_TEXT
        end,
    })
    rawset(_G, "GetInboxHeaderInfo", function()
        return nil, nil, "TestSender", nil, MONEY
    end)
    rawset(_G, "GetInboxItem", function(index, attachIndex)
        if index ~= 1 or attachIndex ~= 2 then return nil end
        return ITEM_NAME, ITEM_ID, ITEM_ICON, ITEM_COUNT, 3, true, false
    end)
    rawset(_G, "GetInboxInvoiceInfo", function() end)
    rawset(_G, "GetInboxText", function() return "" end)
    rawset(_G, "hooksecurefunc", function(name, callback)
        hooks[name] = callback
    end)
    rawset(_G, "GOLD_AMOUNT", "%dg")
    rawset(_G, "SILVER_AMOUNT", "%ds")
    rawset(_G, "COPPER_AMOUNT", "%dc")
    rawset(_G, "GOLD_AMOUNT_TEXTURE", "%d|Tgold|t")
    rawset(_G, "SILVER_AMOUNT_TEXTURE", "%d|Tsilver|t")
    rawset(_G, "COPPER_AMOUNT_TEXTURE", "%d|Tcopper|t")

    local ns = mock.CreateNamespace()
    ns.ListenerUtils = {}
    ns.MailListenerShared = {}
    ns.ToastManager.QueueToast = function(lootData)
        queuedToasts[#queuedToasts + 1] = lootData
    end

    LoadModule("DragonToast/Core/ListenerUtils.lua", ns)
    LoadModule("DragonToast/Core/QueueUtils.lua", ns)
    LoadModule("DragonToast/Listeners/MailListener_Shared.lua", ns)

    local addon = {
        db = {
            profile = {
                enabled = true,
                filters = {
                    minQuality = 0,
                    showMail = true,
                    showGold = true,
                },
            },
        },
        RegisterEvent = function(_, eventName, handler)
            eventHandlers[eventName] = handler
        end,
        UnregisterEvent = function(_, eventName)
            eventHandlers[eventName] = nil
        end,
    }
    local listener = ns.MailListenerShared.Create({
        versionName = "Spec",
        supportsAttachmentCurrencyFlag = true,
    })
    listener.Initialize(addon)

    return {
        hooks = hooks,
        eventHandlers = eventHandlers,
        queuedToasts = queuedToasts,
        itemState = itemState,
    }
end

local function AssertItemToast(harness)
    assert.equal(1, #harness.queuedToasts)
    assert.same({
        itemLink = ITEM_LINK,
        itemID = ITEM_ID,
        itemName = ITEM_NAME,
        itemQuality = 3,
        itemLevel = 80,
        itemType = SOURCE_LABEL,
        itemSubType = "Junk",
        itemIcon = ITEM_ICON,
        quantity = ITEM_COUNT,
        looter = "TestPlayer",
        isSelf = true,
        isCurrency = false,
        isMail = true,
        timestamp = 100,
    }, harness.queuedToasts[1])
end

describe("MailListenerShared", function()
    local savedGlobals
    local savedTime

    before_each(function()
        savedGlobals = {}
        for _, name in ipairs(MAIL_GLOBALS) do
            savedGlobals[name] = rawget(_G, name)
        end
        savedTime = GetTime()
        mock.SetTime(100)
    end)

    after_each(function()
        for _, name in ipairs(MAIL_GLOBALS) do
            rawset(_G, name, savedGlobals[name])
        end
        mock.SetTime(savedTime)
    end)

    it("queues cached attachments with the hyperlink rather than the item description after mail success", function()
        local harness = CreateMailListenerHarness()
        harness.eventHandlers.MAIL_SHOW()
        harness.hooks.TakeInboxItem(1, 2)

        assert.equal(0, #harness.queuedToasts)
        harness.eventHandlers.MAIL_SUCCESS()

        AssertItemToast(harness)
    end)

    it("defers uncached attachments until their item metadata arrives and preserves the hyperlink", function()
        local harness = CreateMailListenerHarness()
        harness.itemState.cached = false
        harness.eventHandlers.MAIL_SHOW()
        harness.hooks.TakeInboxItem(1, 2)
        harness.eventHandlers.MAIL_SUCCESS()

        assert.equal(0, #harness.queuedToasts)
        assert.is_function(harness.eventHandlers.GET_ITEM_INFO_RECEIVED)

        harness.itemState.cached = true
        harness.eventHandlers.GET_ITEM_INFO_RECEIVED(nil, ITEM_ID + 1, true)
        assert.equal(0, #harness.queuedToasts)
        harness.eventHandlers.GET_ITEM_INFO_RECEIVED(nil, ITEM_ID, true)

        AssertItemToast(harness)
        assert.is_nil(harness.eventHandlers.GET_ITEM_INFO_RECEIVED)
    end)

    it("queues positive mail money using the namespaced currency formatter after mail success", function()
        local harness = CreateMailListenerHarness()
        harness.eventHandlers.MAIL_SHOW()
        harness.hooks.TakeInboxMoney(1)

        assert.equal(0, #harness.queuedToasts)
        harness.eventHandlers.MAIL_SUCCESS()

        assert.equal(1, #harness.queuedToasts)
        assert.same({
            itemName = MONEY_TEXT,
            itemQuality = 1,
            itemLevel = 0,
            itemType = SOURCE_LABEL,
            itemSubType = "Gold",
            itemIcon = 133784,
            quantity = 1,
            copperAmount = MONEY,
            moneyDirection = "gain",
            looter = "TestPlayer",
            isSelf = true,
            isCurrency = true,
            isMail = true,
            timestamp = 100,
        }, harness.queuedToasts[1])
    end)
end)
