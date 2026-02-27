-------------------------------------------------------------------------------
-- HonorListener.lua
-- Honor gain toast notifications
--
-- Supported versions: TBC Anniversary, Retail, MoP Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

-------------------------------------------------------------------------------
-- Cached WoW API
-------------------------------------------------------------------------------

local GetTime = GetTime
local UnitName = UnitName
local UnitFactionGroup = UnitFactionGroup
local tonumber = tonumber
local string_match = string.match


-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

-- Honor icon - resolved at runtime in Initialize() based on player faction
-- Uses Blizzard's faction-specific PVP currency icons from Constants.CurrencyConsts
local HONOR_ICON
local HONOR_ICON_FALLBACK = "Interface\\Icons\\Achievement_LegionPVPTier4"
-- Honor quality color
local HONOR_QUALITY = 1  -- Common quality (white) — we override color in ToastFrame

-------------------------------------------------------------------------------
-- Honor Icon Resolution
-- On Classic, numeric FileDataIDs (e.g. 1455894) render as green squares.
-- We resolve a string-path icon from Constants.CurrencyConsts at runtime,
-- falling back to the Retail texture path when the table is unavailable.
-------------------------------------------------------------------------------

local function ResolveHonorIcon()
    local consts = Constants and Constants.CurrencyConsts
    if consts then
        local faction = UnitFactionGroup("player")
        if faction == "Alliance" then
            return consts.PVP_CURRENCY_HONOR_ALLIANCE_INV_ICON or HONOR_ICON_FALLBACK
        elseif faction == "Horde" then
            return consts.PVP_CURRENCY_HONOR_HORDE_INV_ICON or HONOR_ICON_FALLBACK
        end
    end
    return HONOR_ICON_FALLBACK
end

-------------------------------------------------------------------------------
-- Pattern Building
-- WoW global strings use %s for strings and %d for numbers.
-- We convert them to Lua patterns for matching.
-------------------------------------------------------------------------------

local function BuildPattern(globalString)
    if not globalString then return nil end
    -- Escape magic pattern characters
    local pattern = globalString:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
    -- Replace %d with number capture, %s with string capture
    pattern = pattern:gsub("%%%%d", "(%%d+)")
    pattern = pattern:gsub("%%%%s", "(.+)")
    return "^" .. pattern .. "$"
end

-- Build patterns from WoW global strings (available in both TBC and Retail)
-- These globals are set by Blizzard's localization system
local PATTERNS = {}

local function InitPatterns()
    -- "%s dies, honorable kill Rank: %s (Estimated Honor Points: %d)"
    if COMBATLOG_HONORGAIN then
        PATTERNS.honorGain = BuildPattern(COMBATLOG_HONORGAIN)
    end

    -- "You have been awarded %d honor points."
    if COMBATLOG_HONORAWARD then
        PATTERNS.honorAward = BuildPattern(COMBATLOG_HONORAWARD)
    end
end

-------------------------------------------------------------------------------
-- Honor Parsing
-------------------------------------------------------------------------------

local function ParseHonorText(text)
    if not text or text == "" then return nil, nil end

    -- Try honorGain first (victim name + rank + honor amount)
    -- COMBATLOG_HONORGAIN: "%s dies, honorable kill Rank: %s (Estimated Honor Points: %d)"
    -- Captures: victim, rank, honor
    if PATTERNS.honorGain then
        local victim, _rank, honor = string_match(text, PATTERNS.honorGain)
        if victim and honor then return tonumber(honor), victim end
    end

    -- Try honorAward (honor amount only, no victim)
    -- COMBATLOG_HONORAWARD: "You have been awarded %d honor points."
    -- Captures: honor
    if PATTERNS.honorAward then
        local honor = string_match(text, PATTERNS.honorAward)
        if honor then return tonumber(honor), nil end
    end

    -- Fallback: try to find any number followed by "honor" in the text
    local honor = string_match(text, "(%d+)%s+[Hh]onor")
    if honor then return tonumber(honor), nil end

    return nil, nil
end

-------------------------------------------------------------------------------
-- Event Handler
-------------------------------------------------------------------------------

local function OnChatMsgCombatHonorGain(_event, text)
    local db = ns.Addon.db.profile
    if not db.enabled then return end
    if not db.filters.showHonor then return end

    local honorAmount, victimName = ParseHonorText(text)
    if not honorAmount or honorAmount <= 0 then return end

    local lootData = {
        isHonor = true,
        honorAmount = honorAmount,
        victimName = victimName,
        itemIcon = HONOR_ICON,
        itemName = "+" .. ns.FormatNumber(honorAmount) .. " Honor",
        itemQuality = HONOR_QUALITY,
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

ns.HonorListener = ns.HonorListener or {}

function ns.HonorListener.Initialize(addon)
    HONOR_ICON = ResolveHonorIcon()
    InitPatterns()
    addon:RegisterEvent("CHAT_MSG_COMBAT_HONOR_GAIN", OnChatMsgCombatHonorGain)
    ns.DebugPrint("HonorListener initialized")
end

function ns.HonorListener.Shutdown()
    ns.Addon:UnregisterEvent("CHAT_MSG_COMBAT_HONOR_GAIN")
    ns.DebugPrint("HonorListener shutdown")
end

function ns.HonorListener.GetHonorIcon()
    return HONOR_ICON or HONOR_ICON_FALLBACK
end
