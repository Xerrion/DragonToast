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
local string_match = string.match


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

local function InitPatterns()
    -- "You gain %d experience." (no mob)
    if COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED then
        PATTERNS.unnamed = Utils.BuildPattern(COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED, true)
    end

    -- "%s dies, you gain %d experience." (with mob)
    if COMBATLOG_XPGAIN_FIRSTPERSON then
        PATTERNS.named = Utils.BuildPattern(COMBATLOG_XPGAIN_FIRSTPERSON, true)
    end

    -- Rested bonus variants: "%s dies, you gain %d experience. (%s exp %s bonus)"
    if COMBATLOG_XPGAIN_EXHAUSTION1 then
        PATTERNS.rested1 = Utils.BuildPattern(COMBATLOG_XPGAIN_EXHAUSTION1, true)
    end
    if COMBATLOG_XPGAIN_EXHAUSTION2 then
        PATTERNS.rested2 = Utils.BuildPattern(COMBATLOG_XPGAIN_EXHAUSTION2, true)
    end

    -- Rested unnamed: "You gain %d experience. (%s exp %s bonus)"
    if COMBATLOG_XPGAIN_EXHAUSTION1_UNNAMED then
        PATTERNS.restedUnnamed1 = Utils.BuildPattern(COMBATLOG_XPGAIN_EXHAUSTION1_UNNAMED, true)
    end
    if COMBATLOG_XPGAIN_EXHAUSTION2_UNNAMED then
        PATTERNS.restedUnnamed2 = Utils.BuildPattern(COMBATLOG_XPGAIN_EXHAUSTION2_UNNAMED, true)
    end

    -- Guild bonus: "%s dies, you gain %d experience. (+%d exp Guild Bonus)"
    if COMBATLOG_XPGAIN_FIRSTPERSON_GUILD then
        PATTERNS.guild = Utils.BuildPattern(COMBATLOG_XPGAIN_FIRSTPERSON_GUILD, true)
    end

    -- Unnamed guild bonus: "You gain %d experience. (+%d exp Guild Bonus)"
    if COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED_GUILD then
        PATTERNS.guildUnnamed = Utils.BuildPattern(COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED_GUILD, true)
    end

    -- Quest XP: "You gain %d experience." (same as unnamed, quest context handled by event)
end

-------------------------------------------------------------------------------
-- XP Parsing
-------------------------------------------------------------------------------

local function ParseXPText(text)
    if not text or text == "" then return nil, nil end

    -- Try named patterns first (mob name + XP)
    -- Rested named: mob, xp, bonusXP, bonusType
    if PATTERNS.rested1 then
        local mob, xp = string_match(text, PATTERNS.rested1)
        if mob and xp then return tonumber(xp), mob end
    end
    if PATTERNS.rested2 then
        local mob, xp = string_match(text, PATTERNS.rested2)
        if mob and xp then return tonumber(xp), mob end
    end

    -- Guild named: mob, xp, guildXP
    if PATTERNS.guild then
        local mob, xp = string_match(text, PATTERNS.guild)
        if mob and xp then return tonumber(xp), mob end
    end

    -- Standard named: mob, xp
    if PATTERNS.named then
        local mob, xp = string_match(text, PATTERNS.named)
        if mob and xp then return tonumber(xp), mob end
    end

    -- Try unnamed patterns (XP only, no mob)
    -- Rested unnamed: xp, bonusXP, bonusType
    if PATTERNS.restedUnnamed1 then
        local xp = string_match(text, PATTERNS.restedUnnamed1)
        if xp then return tonumber(xp), nil end
    end
    if PATTERNS.restedUnnamed2 then
        local xp = string_match(text, PATTERNS.restedUnnamed2)
        if xp then return tonumber(xp), nil end
    end

    -- Guild unnamed: xp, guildXP
    if PATTERNS.guildUnnamed then
        local xp = string_match(text, PATTERNS.guildUnnamed)
        if xp then return tonumber(xp), nil end
    end

    -- Standard unnamed: xp
    if PATTERNS.unnamed then
        local xp = string_match(text, PATTERNS.unnamed)
        if xp then return tonumber(xp), nil end
    end

    -- Fallback: try to find any number in the text
    local xp = string_match(text, "(%d+)%s+experience")
    if xp then return tonumber(xp), nil end

    return nil, nil
end

-------------------------------------------------------------------------------
-- Event Handler
-------------------------------------------------------------------------------

local function OnChatMsgCombatXPGain(_event, text)
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
        itemName = "+" .. ns.FormatNumber(xpAmount) .. " XP",
        itemQuality = XP_QUALITY,
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
