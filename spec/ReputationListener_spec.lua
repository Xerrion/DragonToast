-------------------------------------------------------------------------------
-- ReputationListener_spec.lua
-- Unit tests for reputation snapshots, parsing, and listener lifecycle
-------------------------------------------------------------------------------

local mock = require("spec.wow_mock")

local function LoadListener()
    local ns = mock.CreateNamespace()
    ns.ListenerUtils = {
        BuildCapturePattern = function()
            return "^Reputation with (.-) increased by (%d+)%.$", { 1, 2 }
        end,
    }
    ns.ReputationListenerShared = {}

    _G.FACTION_STANDING_INCREASED = "Reputation with %s increased by %d."
    _G.FACTION_STANDING_INCREASED_BONUS = nil
    _G.FACTION_STANDING_INCREASED_ACH_BONUS = nil

    local chunk = assert(loadfile("DragonToast/Listeners/ReputationListener_Shared.lua"))
    chunk("DragonToast", ns)
    return ns
end

local function Row(factionID, name, barValue, isHeader)
    return { factionID = factionID, name = name, barValue = barValue, isHeader = isHeader }
end

describe("ReputationListener", function()
    local ns
    local listener
    local addon
    local queued
    local handlers

    before_each(function()
        mock._factionRows = {}
        ns = LoadListener()
        queued = {}
        handlers = {}
        ns.ToastManager.QueueToast = function(toast) queued[#queued + 1] = toast end
        addon = {
            db = ns.Addon.db,
            RegisterEvent = function(_, event, handler) handlers[event] = handler end,
            UnregisterEvent = function(_, event) handlers[event] = nil end,
        }
        listener = ns.ReputationListenerShared.Create()
    end)

    it("captures a silent initial baseline", function()
        mock._factionRows = { Row(1, "A", 100) }
        listener.Initialize(addon)
        assert.equal(0, #queued)
    end)

    it("skips headers and malformed snapshot rows", function()
        mock._factionRows = {
            Row(1, "Valid", 100),
            Row(2, "Header", 100, true),
            Row(nil, "Missing ID", 100),
            Row(3, "", 100),
            Row(4, "Missing Value", nil),
        }
        local snapshot = ns.ReputationListenerShared._test.BuildFactionSnapshot()
        assert.same({ [1] = { factionID = 1, factionName = "Valid", barValue = 100 } }, snapshot)
    end)

    it("defaults invalid reputation direction to gain", function()
        local toast = ns.ReputationListenerShared._test.BuildReputationToast(25, "A", "invalid", 1)
        assert.equal("gain", toast.reputationDirection)
        assert.equal("+25 Reputation", toast.itemName)
        assert.equal("Interface\\AddOns\\DragonToast\\Media\\ReputationGain", toast.itemIcon)
    end)

    it("retains chat-derived gain parsing and identity lookup", function()
        mock._factionRows = { Row(7, "The Sha'tar", 100) }
        listener.Initialize(addon)
        handlers.CHAT_MSG_COMBAT_FACTION_CHANGE(nil, "Reputation with The Sha'tar increased by 250.")
        assert.equal(1, #queued)
        assert.equal("gain", queued[1].reputationDirection)
        assert.equal(250, queued[1].reputationAmount)
        assert.equal(7, queued[1].factionID)
    end)

    it("omits faction ID when a parsed name is ambiguous", function()
        mock._factionRows = { Row(7, "Shared", 100), Row(8, "Shared", 200) }
        listener.Initialize(addon)
        handlers.CHAT_MSG_COMBAT_FACTION_CHANGE(nil, "Reputation with Shared increased by 25.")
        assert.is_nil(queued[1].factionID)
    end)

    it("does not emit positive or zero snapshot changes", function()
        mock._factionRows = { Row(1, "A", 100), Row(2, "B", 50) }
        listener.Initialize(addon)
        mock._factionRows = { Row(1, "A", 125), Row(2, "B", 50) }
        handlers.UPDATE_FACTION()
        assert.equal(0, #queued)
    end)

    it("emits losses by ascending faction ID with positive magnitudes", function()
        mock._factionRows = { Row(9, "Nine", 500), Row(2, "Two", 300) }
        listener.Initialize(addon)
        mock._factionRows = { Row(9, "Nine", 450), Row(2, "Two", 200) }
        handlers.UPDATE_FACTION()
        assert.equal(2, #queued)
        assert.equal(2, queued[1].factionID)
        assert.equal(100, queued[1].reputationAmount)
        assert.equal("loss", queued[1].reputationDirection)
        assert.equal(9, queued[2].factionID)
    end)

    it("advances snapshots while filters or addon are disabled", function()
        mock._factionRows = { Row(1, "A", 100) }
        listener.Initialize(addon)
        addon.db.profile.filters.showReputationLoss = false
        mock._factionRows = { Row(1, "A", 80) }
        handlers.UPDATE_FACTION()
        addon.db.profile.filters.showReputationLoss = true
        addon.db.profile.enabled = false
        mock._factionRows = { Row(1, "A", 60) }
        handlers.UPDATE_FACTION()
        addon.db.profile.enabled = true
        mock._factionRows = { Row(1, "A", 50) }
        handlers.UPDATE_FACTION()
        assert.equal(1, #queued)
        assert.equal(10, queued[1].reputationAmount)
    end)

    it("silently baselines disappeared, reappeared, new, and malformed rows", function()
        mock._factionRows = { Row(1, "A", 100), Row(2, "B", 100), Row(nil, "Bad", 100), Row(3, "Header", 100, true) }
        listener.Initialize(addon)
        mock._factionRows = { Row(2, "B", 100), Row(4, "New", 25) }
        handlers.UPDATE_FACTION()
        mock._factionRows = { Row(1, "A", 50), Row(2, "B", 100), Row(4, "New", 25) }
        handlers.UPDATE_FACTION()
        assert.equal(0, #queued)
    end)

    it("handles standing values that cross zero", function()
        mock._factionRows = { Row(1, "A", 10) }
        listener.Initialize(addon)
        mock._factionRows = { Row(1, "A", -10) }
        handlers.UPDATE_FACTION()
        assert.equal(20, queued[1].reputationAmount)
    end)

    it("clears state on shutdown and silently reinitializes", function()
        mock._factionRows = { Row(1, "A", 100) }
        listener.Initialize(addon)
        listener.Shutdown()
        mock._factionRows = { Row(1, "A", 50) }
        listener.Initialize(addon)
        assert.equal(0, #queued)
    end)
end)
