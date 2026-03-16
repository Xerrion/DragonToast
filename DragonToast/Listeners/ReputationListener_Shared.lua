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
local UnitName = UnitName
local tonumber = tonumber
local string_format = string.format
local string_match = string.match

local PLAYER_UNIT = "player"

local owner

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local REPUTATION_ICON_FALLBACK = Utils.QUESTION_MARK_ICON
local REPUTATION_QUALITY = 1

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
-- Create a toast data table representing a reputation gain.
-- @param reputationAmount number The amount of reputation gained.
-- @param factionName string The name of the faction whose reputation changed.
-- @param icon string|nil The icon texture to display for the toast; may be nil to use a fallback.
-- @return table A table containing toast fields:
--   - isReputation: true
--   - reputationAmount: number
--   - factionName: string
--   - itemIcon: string|nil
--   - itemName: string (localized formatted reputation text)
--   - itemQuality: number
--   - itemLevel: number
--   - itemType: nil
--   - itemSubType: nil
--   - quantity: number
--   - looter: string
--   - isSelf: boolean
--   - isCurrency: boolean
--   - timestamp: number (seconds since epoch from GetTime)

local function BuildReputationToast(reputationAmount, factionName, icon)
    return {
        isReputation = true,
        reputationAmount = reputationAmount,
        factionName = factionName,
        itemIcon = icon,
        itemName = string_format(L["FORMAT_PLUS_REPUTATION"], ns.FormatNumber(reputationAmount)),
        itemQuality = REPUTATION_QUALITY,
        itemLevel = 0,
        itemType = nil,
        itemSubType = nil,
        quantity = 1,
        looter = UnitName(PLAYER_UNIT) or L["YOU"],
        isSelf = true,
        isCurrency = false,
        timestamp = GetTime(),
    }
end

-------------------------------------------------------------------------------
-- Factory
-------------------------------------------------------------------------------

function ns.ReputationListenerShared.Create(config)
    config = config or {}

    local reputationIcon = config.icon or REPUTATION_ICON_FALLBACK
    local patterns = {}

    local function OnChatMsgCombatFactionChange(_, text)
        local db = owner.db.profile
        if not db.enabled then return end
        if not db.filters.showReputation then return end

        local reputationAmount, factionName = ParseReputationText(patterns, text)
        if not reputationAmount or reputationAmount <= 0 then return end
        if not factionName or factionName == "" then return end

        ns.ToastManager.QueueToast(BuildReputationToast(reputationAmount, factionName, reputationIcon))
    end

    local listener = {}

    function listener.Initialize(addon)
        owner = addon
        patterns = BuildPatterns()
        addon:RegisterEvent("CHAT_MSG_COMBAT_FACTION_CHANGE", OnChatMsgCombatFactionChange)
        ns.DebugPrint("ReputationListener initialized")
    end

    function listener.Shutdown()
        owner:UnregisterEvent("CHAT_MSG_COMBAT_FACTION_CHANGE")
        ns.DebugPrint("ReputationListener shutdown")
    end

    function listener.GetReputationIcon()
        return reputationIcon
    end

    return listener
end
