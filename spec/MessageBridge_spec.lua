-------------------------------------------------------------------------------
-- MessageBridge_spec.lua
-- Unit tests for cross-addon toast payload validation
-------------------------------------------------------------------------------

local mock = require("spec.wow_mock")

local function LoadMessageBridge(ns)
    local chunk, err = loadfile("DragonToast/Listeners/MessageBridge.lua")
    if not chunk then
        error("Failed to load DragonToast/Listeners/MessageBridge.lua: " .. (err or "unknown error"))
    end

    chunk("DragonToast", ns)
end

local function CreateHarness()
    local ns = mock.CreateNamespace()
    local messageHandlers = {}
    local queuedToasts = {}

    ns.Addon.RegisterMessage = function(_, message, handler)
        messageHandlers[message] = handler
    end
    ns.ToastManager.QueueToast = function(toastData)
        queuedToasts[#queuedToasts + 1] = toastData
    end

    LoadMessageBridge(ns)
    ns.MessageBridge.Initialize(ns.Addon)

    return messageHandlers.DRAGONTOAST_QUEUE_TOAST, queuedToasts
end

local function MakeToastData(overrides)
    local data = {
        itemName = "Test Money",
        itemIcon = 133784,
        itemQuality = 1,
        copperAmount = 100,
    }
    if overrides then
        for key, value in pairs(overrides) do data[key] = value end
    end
    return data
end

describe("MessageBridge toast payload validation", function()
    it("rejects an invalid money direction", function()
        local queueToast, queuedToasts = CreateHarness()

        queueToast(nil, MakeToastData({ moneyDirection = "refund" }))

        assert.equal(0, #queuedToasts)
    end)

    it("accepts an omitted money direction as a backward-compatible gain", function()
        local queueToast, queuedToasts = CreateHarness()

        queueToast(nil, MakeToastData())

        assert.equal(1, #queuedToasts)
        assert.is_nil(queuedToasts[1].moneyDirection)
    end)
end)
