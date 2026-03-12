-------------------------------------------------------------------------------
-- XPListener.lua
-- Experience gain toast notifications
--
-- Supported versions: TBC Anniversary, Retail, MoP Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...
local Utils = ns.ListenerUtils

-------------------------------------------------------------------------------
-- Cached WoW API
-------------------------------------------------------------------------------

local GetTime = GetTime
local UnitName = UnitName
local tonumber = tonumber
local string_format = string.format
local string_match = string.match
local L = ns.L

local PLAYER_UNIT = "player"
local XP_FALLBACK_PATTERN = "(%d+)%s+experience"


-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

-- XP icon (a generic XP/level-up style icon)
local XP_ICON = 894556   -- Interface\Icons\UI_Chat (chat bubble icon, common for XP)
-- XP quality color (gold/amber)
local XP_QUALITY = 1  -- Common quality (white) -- we override color in ToastFrame

-------------------------------------------------------------------------------
-- Pattern Building
-- Uses shared BuildPattern with anchor=true for XP patterns.
-------------------------------------------------------------------------------

-- Build patterns from WoW global strings (available in both TBC and Retail)
-- These globals are set by Blizzard's localization system
local PATTERNS = {}

local PATTERN_MAP = {
    { global = "COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED",       key = "unnamed" },
    { global = "COMBATLOG_XPGAIN_FIRSTPERSON",               key = "named" },
    { global = "COMBATLOG_XPGAIN_EXHAUSTION1",               key = "rested1" },
    { global = "COMBATLOG_XPGAIN_EXHAUSTION2",               key = "rested2" },
    { global = "COMBATLOG_XPGAIN_EXHAUSTION1_UNNAMED",       key = "restedUnnamed1" },
    { global = "COMBATLOG_XPGAIN_EXHAUSTION2_UNNAMED",       key = "restedUnnamed2" },
    { global = "COMBATLOG_XPGAIN_FIRSTPERSON_GUILD",         key = "guild" },
    { global = "COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED_GUILD", key = "guildUnnamed" },
}

local function InitPatterns()
    for _, entry in ipairs(PATTERN_MAP) do
        local globalValue = _G[entry.global]
        if globalValue then
            PATTERNS[entry.key] = Utils.BuildPattern(globalValue, true)
        end
    end
end

-------------------------------------------------------------------------------
-- XP Parsing
-------------------------------------------------------------------------------

-- Ordered lists: try named patterns (2 captures) first, then unnamed (1 capture)
local NAMED_PATTERNS = { "rested1", "rested2", "guild", "named" }
local UNNAMED_PATTERNS = { "restedUnnamed1", "restedUnnamed2", "guildUnnamed", "unnamed" }

local function ParseXPText(text)
    if not text or text == "" then return nil, nil end

    for _, key in ipairs(NAMED_PATTERNS) do
        if PATTERNS[key] then
            local mob, xp = string_match(text, PATTERNS[key])
            if xp then return tonumber(xp), mob end
        end
    end

    for _, key in ipairs(UNNAMED_PATTERNS) do
        if PATTERNS[key] then
            local xp = string_match(text, PATTERNS[key])
            if xp then return tonumber(xp), nil end
        end
    end

    -- Fallback: try to find any number in the text
    local xp = string_match(text, XP_FALLBACK_PATTERN)
    if xp then return tonumber(xp), nil end

    return nil, nil
end

-------------------------------------------------------------------------------
-- Event Handler
-------------------------------------------------------------------------------

local function OnChatMsgCombatXPGain(_, text)
    local db = ns.Addon.db.profile
    if not db.enabled then return end
    if not db.filters.showXP then return end

    local xpAmount, mobName = ParseXPText(text)
    if not xpAmount or xpAmount <= 0 then return end

    local lootData = {
        isXP = true,
        xpAmount = xpAmount,
        mobName = mobName,
        itemIcon = XP_ICON,
        itemName = string_format(L["+%s XP"], ns.FormatNumber(xpAmount)),
        itemQuality = XP_QUALITY,
        itemLevel = 0,
        itemType = nil,
        itemSubType = nil,
        quantity = 1,
        looter = UnitName(PLAYER_UNIT) or L["You"],
        isSelf = true,
        isCurrency = false,
        timestamp = GetTime(),
    }

    ns.ToastManager.QueueToast(lootData)
end

-------------------------------------------------------------------------------
-- Public Interface
-------------------------------------------------------------------------------

ns.XPListener = ns.XPListener or {}

function ns.XPListener.Initialize(addon)
    InitPatterns()
    addon:RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN", OnChatMsgCombatXPGain)
    ns.DebugPrint("XPListener initialized")
end

function ns.XPListener.Shutdown()
    ns.Addon:UnregisterEvent("CHAT_MSG_COMBAT_XP_GAIN")
    ns.DebugPrint("XPListener shutdown")
end
