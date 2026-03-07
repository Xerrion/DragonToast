-------------------------------------------------------------------------------
-- HonorListener_TBC.lua
-- Honor gain toast notifications
--
-- Supported versions: TBC Anniversary, Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...
local Utils = ns.ListenerUtils

local WOW_PROJECT_ID = WOW_PROJECT_ID
local WOW_PROJECT_BURNING_CRUSADE_CLASSIC = WOW_PROJECT_BURNING_CRUSADE_CLASSIC

if WOW_PROJECT_ID ~= WOW_PROJECT_BURNING_CRUSADE_CLASSIC then return end

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

-- Faction-specific honor icons (PVP banner FileDataIDs, present in all clients)
local HONOR_ICONS = {
    Alliance = 132486,  -- interface/icons/inv_bannerpvp_02 (blue Alliance PVP banner)
    Horde    = 132485,  -- interface/icons/inv_bannerpvp_01 (red Horde PVP banner)
}
local HONOR_ICON_FALLBACK = 132486
-- Honor quality color
local HONOR_QUALITY = 1  -- Common quality (white) -- we override color in ToastFrame
local HONOR_ICON

local function ResolveHonorIcon()
    local faction = UnitFactionGroup("player")
    return HONOR_ICONS[faction] or HONOR_ICON_FALLBACK
end

-------------------------------------------------------------------------------
-- Pattern Building
-- Uses shared BuildPattern with anchor=true for honor patterns.
-------------------------------------------------------------------------------

-- Build patterns from WoW global strings (available in both TBC and Retail)
-- These globals are set by Blizzard's localization system
local PATTERNS = {}

local function InitPatterns()
    -- "%s dies, honorable kill Rank: %s (Estimated Honor Points: %d)"
    if COMBATLOG_HONORGAIN then
        PATTERNS.honorGain = Utils.BuildPattern(COMBATLOG_HONORGAIN, true)
    end

    -- "You have been awarded %d honor points."
    if COMBATLOG_HONORAWARD then
        PATTERNS.honorAward = Utils.BuildPattern(COMBATLOG_HONORAWARD, true)
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
