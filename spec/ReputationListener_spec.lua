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
    local savedGlobals
    local savedFactionRows

    local function CreateListener()
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
    end

    before_each(function()
        savedGlobals = {
            C_Reputation = _G.C_Reputation,
            GetNumFactions = _G.GetNumFactions,
            GetFactionInfo = _G.GetFactionInfo,
            FACTION_STANDING_INCREASED = _G.FACTION_STANDING_INCREASED,
            FACTION_STANDING_INCREASED_BONUS = _G.FACTION_STANDING_INCREASED_BONUS,
            FACTION_STANDING_INCREASED_ACH_BONUS = _G.FACTION_STANDING_INCREASED_ACH_BONUS,
        }
        savedFactionRows = mock._factionRows
        mock._factionRows = {}
        _G.C_Reputation = nil
        CreateListener()
    end)

    after_each(function()
        _G.C_Reputation = savedGlobals.C_Reputation
        _G.GetNumFactions = savedGlobals.GetNumFactions
        _G.GetFactionInfo = savedGlobals.GetFactionInfo
        _G.FACTION_STANDING_INCREASED = savedGlobals.FACTION_STANDING_INCREASED
        _G.FACTION_STANDING_INCREASED_BONUS = savedGlobals.FACTION_STANDING_INCREASED_BONUS
        _G.FACTION_STANDING_INCREASED_ACH_BONUS = savedGlobals.FACTION_STANDING_INCREASED_ACH_BONUS
        mock._factionRows = savedFactionRows
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

    it("emits modern-only reputation changes while skipping absent and invalid rows", function()
        local rows = {
            [1] = { factionID = 1, name = "Header", currentStanding = 100, isHeader = true },
            [3] = { factionID = 2590, name = "Council of Dornogal", currentStanding = 500 },
            [4] = { name = "Missing ID", currentStanding = 100 },
            [5] = { factionID = 2, name = "", currentStanding = 100 },
            [6] = { factionID = 3, name = "Missing Standing" },
        }
        _G.C_Reputation = {
            GetNumFactions = function() return 6 end,
            GetFactionDataByIndex = function(index) return rows[index] end,
        }
        _G.GetNumFactions = nil
        _G.GetFactionInfo = nil
        CreateListener()

        listener.Initialize(addon)
        assert.equal(0, #queued)

        rows[1].currentStanding = 50
        rows[3].currentStanding = 375
        rows[4].currentStanding = 50
        rows[5].currentStanding = 50
        handlers.UPDATE_FACTION()

        assert.equal(1, #queued)
        assert.equal(125, queued[1].reputationAmount)
        assert.equal("loss", queued[1].reputationDirection)
        assert.equal(2590, queued[1].factionID)
        assert.equal("Council of Dornogal", queued[1].factionName)

        handlers.CHAT_MSG_COMBAT_FACTION_CHANGE(nil, "Reputation with Council of Dornogal increased by 250.")

        assert.equal(2, #queued)
        assert.equal(250, queued[2].reputationAmount)
        assert.equal("gain", queued[2].reputationDirection)
        assert.equal(2590, queued[2].factionID)
        assert.equal("Council of Dornogal", queued[2].factionName)
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
