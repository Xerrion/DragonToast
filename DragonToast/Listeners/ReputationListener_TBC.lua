-------------------------------------------------------------------------------
-- ReputationListener_TBC.lua
-- Reputation gain toast notifications
--
-- Supported versions: TBC Anniversary
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...
local Utils = ns.ListenerUtils

-------------------------------------------------------------------------------
-- Version guard: only run on TBC Anniversary
-------------------------------------------------------------------------------

local WOW_PROJECT_ID = WOW_PROJECT_ID
local WOW_PROJECT_BURNING_CRUSADE_CLASSIC = WOW_PROJECT_BURNING_CRUSADE_CLASSIC

if WOW_PROJECT_ID ~= WOW_PROJECT_BURNING_CRUSADE_CLASSIC then return end

-------------------------------------------------------------------------------
-- Cached WoW API
-------------------------------------------------------------------------------

local GetTime = GetTime
local UnitName = UnitName
local tonumber = tonumber
local string_match = string.match

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local REPUTATION_ICON_FALLBACK = Utils.QUESTION_MARK_ICON
local REPUTATION_QUALITY = 1
local PATTERNS = {}

local function AddPattern(globalName)
    local pattern, captureOrder = Utils.BuildCapturePattern(_G[globalName], true)
    if not pattern then return end

    PATTERNS[#PATTERNS + 1] = {
        pattern = pattern,
        captureOrder = captureOrder,
    }
end

-------------------------------------------------------------------------------
-- Pattern Building
-------------------------------------------------------------------------------

local function InitPatterns()
    PATTERNS = {}

    AddPattern("FACTION_STANDING_INCREASED")
    AddPattern("FACTION_STANDING_INCREASED_BONUS")
    AddPattern("FACTION_STANDING_INCREASED_ACH_BONUS")
end

-------------------------------------------------------------------------------
-- Reputation Parsing
-------------------------------------------------------------------------------

local function ParseReputationText(text)
    if not text or text == "" then return nil, nil end

    for _, entry in ipairs(PATTERNS) do
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
-- Event Handler
-------------------------------------------------------------------------------

local function OnChatMsgCombatFactionChange(_event, text)
    local db = ns.Addon.db.profile
    if not db.enabled then return end
    if not db.filters.showReputation then return end

    local reputationAmount, factionName = ParseReputationText(text)
    if not reputationAmount or reputationAmount <= 0 then return end
    if not factionName or factionName == "" then return end

    local lootData = {
        isReputation = true,
        reputationAmount = reputationAmount,
        factionName = factionName,
        itemIcon = REPUTATION_ICON_FALLBACK,
        itemName = "+" .. ns.FormatNumber(reputationAmount) .. " Reputation",
        itemQuality = REPUTATION_QUALITY,
        itemLevel = 0,
        itemType = nil,
        itemSubType = nil,
        quantity = 1,
        looter = UnitName("player") or "You",
        isSelf = true,
        isCurrency = false,
        timestamp = GetTime(),
    }

    ns.ToastManager.QueueToast(lootData)
end

-------------------------------------------------------------------------------
-- Public Interface
-------------------------------------------------------------------------------

ns.ReputationListener = ns.ReputationListener or {}

function ns.ReputationListener.Initialize(addon)
    InitPatterns()
    addon:RegisterEvent("CHAT_MSG_COMBAT_FACTION_CHANGE", OnChatMsgCombatFactionChange)
    ns.DebugPrint("ReputationListener initialized")
end

function ns.ReputationListener.Shutdown()
    ns.Addon:UnregisterEvent("CHAT_MSG_COMBAT_FACTION_CHANGE")
    ns.DebugPrint("ReputationListener shutdown")
end

function ns.ReputationListener.GetReputationIcon()
    return REPUTATION_ICON_FALLBACK
end
