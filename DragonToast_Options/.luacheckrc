std = "lua51"
max_line_length = 120
codes = true

ignore = {
    "212/self",
    "211/ADDON_NAME",
    "211/_.*",
    "213/_.*",
}

globals = {
    "DragonToast_Options",
    "StaticPopupDialogs",
    "ColorPickerFrame",
}

read_globals = {
    -- Lua
    "table", "string", "math", "pairs", "ipairs", "type", "tostring", "tonumber",
    "select", "unpack", "wipe", "strsplit", "strmatch", "strtrim", "format",
    "pcall", "sort",

    -- WoW API - General
    "CreateFrame", "GetTime", "UIParent", "GameTooltip",
    "PlaySound", "SOUNDKIT", "ShowUIPanel",
    "C_Timer", "StaticPopup_Show",
    "_G",

    -- Libraries
    "LibStub",

    -- WoW Globals
    "STANDARD_TEXT_FONT", "UISpecialFrames",
    "GameFontNormal", "GameFontNormalSmall", "GameFontNormalLarge",
    "GameFontHighlight", "GameFontHighlightSmall",

    -- DragonToast bridge
    "DragonToastNS",
}
