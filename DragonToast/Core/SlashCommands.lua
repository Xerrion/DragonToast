-------------------------------------------------------------------------------
-- SlashCommands.lua
-- Slash command handler for DragonToast
--
-- Supported versions: TBC Anniversary, Retail, MoP Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

-------------------------------------------------------------------------------
-- Cached references
-------------------------------------------------------------------------------

local print = print
local string_lower = string.lower
local string_match = string.match

-------------------------------------------------------------------------------
-- Quality names for status display
-------------------------------------------------------------------------------

local QUALITY_NAMES = {
    [0] = "|cff9d9d9dPoor|r",
    [1] = "|cffffffffCommon|r",
    [2] = "|cff1eff00Uncommon|r",
    [3] = "|cff0070ddRare|r",
    [4] = "|cffa335eeEpic|r",
    [5] = "|cffff8000Legendary|r",
}

-------------------------------------------------------------------------------
-- Status Display
-------------------------------------------------------------------------------

local function PrintStatus()
    local db = ns.Addon.db.profile

    print(ns.COLOR_GOLD .. "--- DragonToast Status ---" .. ns.COLOR_RESET)
    print("  Enabled: " .. (db.enabled and ns.COLOR_GREEN .. "Yes" or ns.COLOR_RED .. "No") .. ns.COLOR_RESET)
    print("  Min Quality: " .. (QUALITY_NAMES[db.filters.minQuality] or "Unknown"))
    print("  Self Loot: " .. (db.filters.showSelfLoot and "Yes" or "No"))
    print("  Group Loot: " .. (db.filters.showGroupLoot and "Yes" or "No"))
    print("  Currency: " .. (db.filters.showCurrency and "Yes" or "No"))
    print("  Gold: " .. (db.filters.showGold and "Yes" or "No"))
    print("  Quest Items: " .. (db.filters.showQuestItems and "Yes" or "No"))
    print("  XP Gains: " .. (db.filters.showXP and "Yes" or "No"))
    print("  Reputation Gains: " .. (db.filters.showReputation and "Yes" or "No"))
    print("  Max Toasts: " .. db.display.maxToasts)
    print("  Growth: " .. db.display.growDirection)
    print("  Animations: " .. (db.animation.enableAnimations and "Yes" or "No"))
    print("  Hold Duration: " .. db.animation.holdDuration .. "s")
    print("  Sound: " .. (db.sound.enabled and "Yes" or "No"))
    print("  Defer in Combat: " .. (db.combat.deferInCombat and "Yes" or "No"))
    print("  ElvUI Skin: " .. (db.elvui.useSkin and "Yes" or "No"))
    print("  Minimap Icon: " .. (not db.minimap.hide and "Yes" or "No"))
    print("  Anchor: " .. db.display.anchorPoint
        .. " (" .. math.floor(db.display.anchorX) .. ", " .. math.floor(db.display.anchorY) .. ")")
    local tmStatus = ns.TestToasts.IsTestModeActive()
        and ns.COLOR_GREEN .. "Active" or "Inactive"
    print("  Test Mode: " .. tmStatus .. ns.COLOR_RESET)
end

-------------------------------------------------------------------------------
-- Help Display
-------------------------------------------------------------------------------

local HELP_ENTRIES = {
    { "",                "Show this help" },
    { " toggle",         "Toggle addon on/off" },
    { " config",         "Open settings panel" },
    { " lock",           "Toggle anchor lock (drag to move)" },
    { " test",           "Show a test toast" },
    { " test stack",     "Test item stacking (3 rapid items)" },
    { " test xp",        "Test XP accumulation" },
    { " test gold",      "Test gold accumulation" },
    { " test honor",     "Test honor accumulation" },
    { " test reputation", "Test reputation accumulation" },
    { " test all",       "Run all stacking tests" },
    { " testmode",       "Toggle continuous test toast generation" },
    { " clear",          "Dismiss all toasts" },
    { " reset",          "Reset anchor position to default" },
    { " status",         "Show current settings" },
    { " help",           "Show this help" },
}

local function PrintHelp()
    print(ns.COLOR_GOLD .. "--- DragonToast Commands ---" .. ns.COLOR_RESET)
    for _, entry in ipairs(HELP_ENTRIES) do
        print("  " .. ns.COLOR_WHITE .. "/dt" .. entry[1] .. ns.COLOR_RESET .. " -- " .. entry[2])
    end
end

-------------------------------------------------------------------------------
-- Command Router
-------------------------------------------------------------------------------

local function NormalizeCommand(input)
    local trimmedInput = string_match(input or "", "^%s*(.-)%s*$")
    return string_lower(trimmedInput)
end

local function ToggleAddon()
    local db = ns.Addon.db.profile
    db.enabled = not db.enabled

    if db.enabled then
        ns.Addon:OnEnable()
        ns.Print("Addon " .. ns.COLOR_GREEN .. "enabled" .. ns.COLOR_RESET)
        return
    end

    ns.Addon:OnDisable()
    ns.Print("Addon " .. ns.COLOR_RED .. "disabled" .. ns.COLOR_RESET)
end

function ns.HandleSlashCommand(input)
    local cmd = NormalizeCommand(input)

    if cmd == "" then
        PrintHelp()

    elseif cmd == "toggle" then
        ToggleAddon()

    elseif cmd == "config" or cmd == "options" or cmd == "settings" then
        -- Open options panel
        if ns.ToggleOptions then
            ns.ToggleOptions()
        end

    elseif cmd == "lock" or cmd == "unlock" or cmd == "move" then
        ns.ToastManager.ToggleLock()

    elseif cmd == "test" then
        ns.TestToasts.ShowTestToast()

    elseif cmd:find("^test ") then
        local subCmd = cmd:match("^test (.+)$")
        ns.TestToasts.RunStackTest(subCmd)

    elseif cmd == "testmode" then
        ns.TestToasts.ToggleTestMode()

    elseif cmd == "clear" then
        ns.ToastManager.ClearAll()
        ns.Print("All toasts cleared.")

    elseif cmd == "reset" then
        ns.ToastManager.ResetAnchor()

    elseif cmd == "status" then
        PrintStatus()

    elseif cmd == "help" or cmd == "?" then
        PrintHelp()

    else
        ns.Print("Unknown command: " .. ns.COLOR_WHITE .. cmd .. ns.COLOR_RESET)
        PrintHelp()
    end
end
