std = "lua51"
max_line_length = 120
codes = true
exclude_files = {
    "Libs/",
}

ignore = {
    "212/self",
    "211/ADDON_NAME",
    "211/_.*",  -- unused variables prefixed with underscore
    "213/_.*",  -- unused loop variables prefixed with underscore
}

globals = {
    "DragonToastDB",
    "SLASH_DRAGONTOAST1",
    "SLASH_DRAGONTOAST2",
    "SlashCmdList",
}

read_globals = {
    -- Lua
    "table", "string", "math", "pairs", "ipairs", "type", "tostring", "tonumber",
    "select", "unpack", "wipe", "strsplit", "strmatch", "format",

    -- WoW API
    "CreateFrame", "GetTime", "IsInInstance", "UnitName", "UnitClass",
    "GetItemInfo", "GetItemQualityColor", "C_Timer", "C_Item", "C_Container",
    "GameTooltip", "UIParent", "PlaySound", "PlaySoundFile",
    "ChatFrame_OpenChat", "IsShiftKeyDown",
    "InCombatLockdown", "hooksecurefunc",
    "InterfaceOptionsFrame_OpenToCategory", "Settings","GetTime",

    -- WoW Globals
    "Enum", "RAID_CLASS_COLORS", "ITEM_QUALITY_COLORS", "STANDARD_TEXT_FONT",
    "WOW_PROJECT_ID", "WOW_PROJECT_MAINLINE",
    "WOW_PROJECT_BURNING_CRUSADE_CLASSIC", "WOW_PROJECT_MISTS_CLASSIC",
    "LOOT_ITEM_SELF", "LOOT_ITEM_SELF_MULTIPLE",
    "LOOT_ITEM", "LOOT_ITEM_MULTIPLE",
    "LOOT_MONEY", "YOU_LOOT_MONEY",
    "CURRENCY_GAINED", "CURRENCY_GAINED_MULTIPLE",
    "GOLD_AMOUNT", "SILVER_AMOUNT", "COPPER_AMOUNT",
    "GOLD_AMOUNT_TEXTURE", "SILVER_AMOUNT_TEXTURE", "COPPER_AMOUNT_TEXTURE",
    "GetCoinTextureString",
    "UNKNOWN",
    "COMBATLOG_XPGAIN_FIRSTPERSON",
    "COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED",
    "COMBATLOG_XPGAIN_EXHAUSTION1",
    "COMBATLOG_XPGAIN_EXHAUSTION2",
    "COMBATLOG_XPGAIN_EXHAUSTION1_UNNAMED",
    "COMBATLOG_XPGAIN_EXHAUSTION2_UNNAMED",
    "COMBATLOG_XPGAIN_FIRSTPERSON_GUILD",
    "COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED_GUILD",
    "COMBATLOG_HONORGAIN",
    "COMBATLOG_HONORAWARD",

    -- Ace3
    "LibStub",

    -- ElvUI
    "ElvUI",
}
