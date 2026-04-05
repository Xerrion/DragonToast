-------------------------------------------------------------------------------
-- HonorListener_Shared.lua
-- Shared honor listener implementation with version wrapper factories
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
local UnitFactionGroup = UnitFactionGroup
local UnitName = UnitName
local tonumber = tonumber
local string_format = string.format
local string_match = string.match

local PLAYER_UNIT = "player"
local HONOR_FALLBACK_PATTERN = "(%d+)%s+[Hh]onor"

local owner

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local HONOR_QUALITY = 1

-------------------------------------------------------------------------------
-- Pattern Building
-------------------------------------------------------------------------------

local function BuildPatterns()
    return {
        honorGain = COMBATLOG_HONORGAIN and Utils.BuildPattern(COMBATLOG_HONORGAIN, true) or nil,
        honorAward = COMBATLOG_HONORAWARD and Utils.BuildPattern(COMBATLOG_HONORAWARD, true) or nil,
    }
end

-------------------------------------------------------------------------------
-- Honor Parsing
-------------------------------------------------------------------------------

local function ParseHonorText(patterns, text)
    if not text or text == "" then return nil, nil end

    if patterns.honorGain then
        local victimName, _, honorAmount = string_match(text, patterns.honorGain)
        if victimName and honorAmount then
            return tonumber(honorAmount), victimName
        end
    end

    if patterns.honorAward then
        local honorAmount = string_match(text, patterns.honorAward)
        if honorAmount then
            return tonumber(honorAmount), nil
        end
    end

    local honorAmount = string_match(text, HONOR_FALLBACK_PATTERN)
    if honorAmount then
        return tonumber(honorAmount), nil
    end

    return nil, nil
end

-------------------------------------------------------------------------------
-- Toast Data
-- Builds a toast data table representing a single honor gain event.
-- @param honorAmount The amount of honor gained.
-- @param victimName The name of the victim credited for the honor, or nil if not applicable.
-- @param honorIcon The icon to display for the honor toast.
-- @return A table with toast fields:
--         `isHonor` (true), `honorAmount`, `victimName`, `itemIcon`, `itemName` (formatted display name),
--         `itemQuality`, `itemLevel`, `itemType`, `itemSubType`, `quantity`, `looter` (player name or localized "YOU"),
--         `isSelf` (true), `isCurrency` (false), and `timestamp` (seconds since epoch).

local function BuildHonorToast(honorAmount, victimName, honorIcon)
    return {
        isHonor = true,
        honorAmount = honorAmount,
        victimName = victimName,
        itemIcon = honorIcon,
        itemName = string_format(L["+%s Honor"], ns.FormatNumber(honorAmount)),
        itemQuality = HONOR_QUALITY,
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

-------------------------------------------------------------------------------
-- Factory
-------------------------------------------------------------------------------

function ns.HonorListenerShared.Create(config)
    config = config or {}

    local iconByFaction = config.iconByFaction or {}
    local fallbackIcon = config.iconFallback or Utils.QUESTION_MARK_ICON
    local honorIcon = fallbackIcon
    local patterns = {}

    local function ResolveHonorIcon()
        local factionName = UnitFactionGroup("player")
        return iconByFaction[factionName] or fallbackIcon
    end

    local function OnChatMsgCombatHonorGain(_, text)
        local db = owner.db.profile
        if not db.enabled then return end
        if not db.filters.showHonor then return end

        local honorAmount, victimName = ParseHonorText(patterns, text)
        if not honorAmount or honorAmount <= 0 then return end

        ns.ToastManager.QueueToast(BuildHonorToast(honorAmount, victimName, honorIcon))
    end

    local listener = {}

    function listener.Initialize(addon)
        owner = addon
        honorIcon = ResolveHonorIcon()
        patterns = BuildPatterns()
        addon:RegisterEvent("CHAT_MSG_COMBAT_HONOR_GAIN", OnChatMsgCombatHonorGain)
        ns.DebugPrint("HonorListener initialized")
    end

    function listener.Shutdown()
        owner:UnregisterEvent("CHAT_MSG_COMBAT_HONOR_GAIN")
        ns.DebugPrint("HonorListener shutdown")
    end

    function listener.GetHonorIcon()
        return honorIcon or fallbackIcon
    end

    return listener
end
