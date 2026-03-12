std = "lua51"
max_line_length = 120
codes = true
exclude_files = {
    "DragonToast/Libs/",
    ".release/",
}

ignore = {
    "212/self",
    "211/ADDON_NAME",
    "211/ns",
    "211/_.*",  -- unused variables prefixed with underscore
    "213/_.*",  -- unused loop variables prefixed with underscore
}

read_globals = {
    -- Lua
    "table", "string", "math", "pairs", "ipairs", "type", "tostring", "tonumber",
    "select", "unpack", "wipe", "strsplit", "strmatch", "strtrim", "format",
    "pcall", "sort",

    -- WoW API - General
    "CreateFrame", "GetTime", "UIParent", "GameTooltip",
    "PlaySound", "PlaySoundFile",
    "C_Timer",

    -- Libraries
    "LibStub",

    -- WoW Globals
    "STANDARD_TEXT_FONT",
}

-----------------------------------------------------------------------
-- DragonToast (main addon)
-----------------------------------------------------------------------
files["DragonToast/"] = {
    globals = {
        "DragonToastDB",
        "DragonToastNS",
        "SLASH_DRAGONTOAST1",
        "SLASH_DRAGONTOAST2",
        "SlashCmdList",
    },

    read_globals = {
        -- WoW API
        "IsInInstance", "UnitName", "UnitClass",
        "UnitFactionGroup",
        "GetItemInfo", "GetItemQualityColor", "C_Item", "C_Container",
        "C_CurrencyInfo",
        "GetInboxHeaderInfo", "GetInboxItem", "GetInboxInvoiceInfo", "GetInboxText",
        "TakeInboxItem", "TakeInboxMoney", "AutoLootMailItem",
        "ChatFrame_OpenChat", "IsShiftKeyDown",
        "InCombatLockdown", "hooksecurefunc",
        "InterfaceOptionsFrame_OpenToCategory", "Settings",

        -- WoW Globals
        "Enum", "RAID_CLASS_COLORS", "ITEM_QUALITY_COLORS",
        "WOW_PROJECT_ID", "WOW_PROJECT_MAINLINE",
        "WOW_PROJECT_BURNING_CRUSADE_CLASSIC", "WOW_PROJECT_MISTS_CLASSIC",
        "LOOT_ITEM_SELF", "LOOT_ITEM_SELF_MULTIPLE",
        "LOOT_ITEM", "LOOT_ITEM_MULTIPLE",
        "LOOT_ITEM_PUSHED_SELF", "LOOT_ITEM_PUSHED_SELF_MULTIPLE",
        "LOOT_ITEM_PUSHED", "LOOT_ITEM_PUSHED_MULTIPLE",
        "LOOT_ITEM_BONUS_ROLL_SELF", "LOOT_ITEM_BONUS_ROLL_SELF_MULTIPLE",
        "LOOT_ITEM_BONUS_ROLL", "LOOT_ITEM_BONUS_ROLL_MULTIPLE",
        "LOOT_ITEM_CREATED_SELF", "LOOT_ITEM_CREATED_SELF_MULTIPLE",
        "LOOT_ITEM_REFUND", "LOOT_ITEM_REFUND_MULTIPLE",
        "LOOT_MONEY", "YOU_LOOT_MONEY",
        "YOU_LOOT_MONEY_MOD", "LOOT_MONEY_SPLIT_MOD", "LOOT_MONEY_REFUND",
        "LOOT_MONEY_SPLIT", "LOOT_MONEY_SPLIT_GUILD", "YOU_LOOT_MONEY_GUILD",
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

        -- LoadOnDemand
        "_G", "C_AddOns", "DragonToast_Options",

        -- ElvUI
        "ElvUI",
    },
}

-----------------------------------------------------------------------
-- DragonToast_Options (companion addon)
-----------------------------------------------------------------------
files["DragonToast_Options/"] = {
    globals = {
        "DragonToast_Options",
        "StaticPopupDialogs",
        "ColorPickerFrame",
    },

    read_globals = {
        -- WoW API
        "SOUNDKIT", "ShowUIPanel",
        "StaticPopup_Show",
        "_G",

        -- WoW Globals
        "UISpecialFrames",
        "GameFontNormal", "GameFontNormalSmall", "GameFontNormalLarge",
        "GameFontHighlight", "GameFontHighlightSmall",

        -- DragonToast bridge
        "DragonToastNS",
    },
}

-----------------------------------------------------------------------
-- Tests
-----------------------------------------------------------------------
files["spec/**"] = {
    std = "+busted",
    globals = {
        -- WoW API mocks (set as globals in wow_mock.lua)
        "GetTime", "InCombatLockdown", "PlaySoundFile", "UnitName",
        "GetCoinTextureString", "CreateFrame", "UIParent", "LibStub", "wipe",

        -- WoW money globals (set in ListenerUtils_spec.lua)
        "GOLD_AMOUNT", "SILVER_AMOUNT", "COPPER_AMOUNT",
        "GOLD_AMOUNT_TEXTURE", "SILVER_AMOUNT_TEXTURE", "COPPER_AMOUNT_TEXTURE",
    },
}
