-------------------------------------------------------------------------------
-- ReputationListener_Shared.lua
-- Shared reputation listener implementation with version wrapper factories
--
-- Supported versions: TBC Anniversary, Retail, MoP Classic
-------------------------------------------------------------------------------

local _, ns = ...
local Utils = ns.ListenerUtils
local L = ns.L

-------------------------------------------------------------------------------
-- Cached WoW API
-------------------------------------------------------------------------------

local GetTime = GetTime
local GetFactionInfo = GetFactionInfo
local GetNumFactions = GetNumFactions
local UnitName = UnitName
local ipairs = ipairs
local pairs = pairs
local table_sort = table.sort
local tonumber = tonumber
local type = type
local string_format = string.format
local string_match = string.match

local PLAYER_UNIT = "player"

local owner

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local REPUTATION_GAIN_ICON = "Interface\\AddOns\\DragonToast\\Media\\ReputationGain"
local REPUTATION_LOSS_ICON = "Interface\\AddOns\\DragonToast\\Media\\ReputationLoss"
local REPUTATION_QUALITY = 1
local REPUTATION_DIRECTION_GAIN = "gain"
local REPUTATION_DIRECTION_LOSS = "loss"

-------------------------------------------------------------------------------
-- Pattern Building
-------------------------------------------------------------------------------

local function BuildPatternEntry(globalName)
    local pattern, captureOrder = Utils.BuildCapturePattern(_G[globalName], true)
    if not pattern then return nil end

    return {
        pattern = pattern,
        captureOrder = captureOrder,
    }
end

local function BuildPatterns()
    local patterns = {}
    local globalNames = {
        "FACTION_STANDING_INCREASED",
        "FACTION_STANDING_INCREASED_BONUS",
        "FACTION_STANDING_INCREASED_ACH_BONUS",
    }

    for _, globalName in ipairs(globalNames) do
        local entry = BuildPatternEntry(globalName)
        if entry then
            patterns[#patterns + 1] = entry
        end
    end

    return patterns
end

-------------------------------------------------------------------------------
-- Reputation Parsing
-------------------------------------------------------------------------------

local function ParseReputationText(patterns, text)
    if not text or text == "" then return nil, nil end

    for _, entry in ipairs(patterns) do
        local captures = { string_match(text, entry.pattern) }
        if #captures > 0 then
            local capturedValues = {}

            for index, placeholderIndex in ipairs(entry.captureOrder) do
                capturedValues[placeholderIndex] = captures[index]
            end

            local factionName = capturedValues[1]
            local amount = tonumber(capturedValues[2])
            if factionName and amount then
                return amount, factionName
            end
        end
    end

    return nil, nil
end

-------------------------------------------------------------------------------
-- Toast Data

local function NormalizeDirection(direction)
    if direction == REPUTATION_DIRECTION_LOSS then return REPUTATION_DIRECTION_LOSS end
    return REPUTATION_DIRECTION_GAIN
end

local function GetDefaultReputationIcon(direction)
    if NormalizeDirection(direction) == REPUTATION_DIRECTION_LOSS then return REPUTATION_LOSS_ICON end
    return REPUTATION_GAIN_ICON
end

local function BuildReputationToast(reputationAmount, factionName, direction, factionID, icon)
    local normalizedDirection = NormalizeDirection(direction)
    local label = normalizedDirection == REPUTATION_DIRECTION_LOSS and L["-%s Reputation"] or L["+%s Reputation"]

    return {
        isReputation = true,
        reputationAmount = reputationAmount,
        reputationDirection = normalizedDirection,
        factionID = factionID,
        factionName = factionName,
        itemIcon = icon or GetDefaultReputationIcon(normalizedDirection),
        itemName = string_format(label, ns.FormatNumber(reputationAmount)),
        itemQuality = REPUTATION_QUALITY,
        itemLevel = 0,
        itemType = nil,
        itemSubType = nil,
        quantity = 1,
        looter = UnitName(PLAYER_UNIT) or L["You"],
        isSelf = true,
        isCurrency = false,
        timestamp = GetTime(),
    }
end

local function BuildFactionSnapshot()
    local snapshot = {}

    for index = 1, GetNumFactions() do
        local factionName, _, _, _, _, barValue, _, _, isHeader, _, _, _, _, factionID = GetFactionInfo(index)
        if not isHeader and type(factionID) == "number" and factionName and factionName ~= ""
            and type(barValue) == "number" then
            snapshot[factionID] = {
                factionID = factionID,
                factionName = factionName,
                barValue = barValue,
            }
        end
    end

    return snapshot
end

local function DiffFactionSnapshots(previousSnapshot, currentSnapshot)
    local changes = {}

    for factionID, current in pairs(currentSnapshot) do
        local previous = previousSnapshot[factionID]
        if previous then
            local delta = current.barValue - previous.barValue
            if delta ~= 0 then
                changes[#changes + 1] = {
                    factionID = factionID,
                    factionName = current.factionName,
                    amount = delta < 0 and -delta or delta,
                    reputationDirection = delta < 0 and REPUTATION_DIRECTION_LOSS or REPUTATION_DIRECTION_GAIN,
                }
            end
        end
    end

    table_sort(changes, function(left, right) return left.factionID < right.factionID end)
    return changes
end

local function FindFactionIDByName(snapshot, factionName)
    local matchedFactionID
    for factionID, faction in pairs(snapshot) do
        if faction.factionName == factionName then
            if matchedFactionID then return nil end
            matchedFactionID = factionID
        end
    end
    return matchedFactionID
end

-------------------------------------------------------------------------------
-- Factory
-------------------------------------------------------------------------------

function ns.ReputationListenerShared.Create(config)
    config = config or {}

    local reputationGainIcon = config.gainIcon or config.icon or REPUTATION_GAIN_ICON
    local reputationLossIcon = config.lossIcon or REPUTATION_LOSS_ICON
    local patterns = {}
    local factionSnapshot = {}

    local function OnChatMsgCombatFactionChange(_, text)
        local db = owner.db.profile
        if not db.enabled then return end
        if not db.filters.showReputation then return end

        local reputationAmount, factionName = ParseReputationText(patterns, text)
        if not reputationAmount or reputationAmount <= 0 then return end
        if not factionName or factionName == "" then return end

        local factionID = FindFactionIDByName(factionSnapshot, factionName)
        ns.ToastManager.QueueToast(BuildReputationToast(
            reputationAmount, factionName, REPUTATION_DIRECTION_GAIN, factionID, reputationGainIcon
        ))
    end

    local function OnUpdateFaction()
        local previousSnapshot = factionSnapshot
        local currentSnapshot = BuildFactionSnapshot()
        local changes = DiffFactionSnapshots(previousSnapshot, currentSnapshot)
        factionSnapshot = currentSnapshot

        local db = owner.db.profile
        if not db.enabled or not db.filters.showReputationLoss then return end

        for _, change in ipairs(changes) do
            if change.reputationDirection == REPUTATION_DIRECTION_LOSS then
                ns.ToastManager.QueueToast(BuildReputationToast(
                    change.amount, change.factionName, change.reputationDirection,
                    change.factionID, reputationLossIcon
                ))
            end
        end
    end

    local listener = {}

    function listener.Initialize(addon)
        owner = addon
        patterns = BuildPatterns()
        addon:RegisterEvent("CHAT_MSG_COMBAT_FACTION_CHANGE", OnChatMsgCombatFactionChange)
        addon:RegisterEvent("UPDATE_FACTION", OnUpdateFaction)
        factionSnapshot = BuildFactionSnapshot()
        ns.DebugPrint("ReputationListener initialized")
    end

    function listener.Shutdown()
        if owner then
            owner:UnregisterEvent("CHAT_MSG_COMBAT_FACTION_CHANGE")
            owner:UnregisterEvent("UPDATE_FACTION")
        end
        owner = nil
        patterns = {}
        factionSnapshot = {}
        ns.DebugPrint("ReputationListener shutdown")
    end

    function listener.GetReputationIcon(direction)
        if NormalizeDirection(direction) == REPUTATION_DIRECTION_LOSS then return reputationLossIcon end
        return reputationGainIcon
    end

    return listener
end

ns.ReputationListenerShared._test = {
    BuildFactionSnapshot = BuildFactionSnapshot,
    DiffFactionSnapshots = DiffFactionSnapshots,
    BuildReputationToast = BuildReputationToast,
}
