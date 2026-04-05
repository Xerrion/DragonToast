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
local L = LibStub("AceLocale-3.0"):GetLocale("DragonToast")

-------------------------------------------------------------------------------
-- Quality names for status display
-------------------------------------------------------------------------------

local QUALITY_NAMES = {
    [0] = "|cff9d9d9d" .. L["Poor"] .. "|r",
    [1] = "|cffffffff" .. L["Common"] .. "|r",
    [2] = "|cff1eff00" .. L["Uncommon"] .. "|r",
    [3] = "|cff0070dd" .. L["Rare"] .. "|r",
    [4] = "|cffa335ee" .. L["Epic"] .. "|r",
    [5] = "|cffff8000" .. L["Legendary"] .. "|r",
}

-------------------------------------------------------------------------------
-- Status Display
-------------------------------------------------------------------------------

local function YesNo(cond)
    return cond and ns.COLOR_GREEN .. L["Yes"] or ns.COLOR_RED .. L["No"]
end

local function PrintStatus()
    local db = ns.Addon.db.profile

    print(ns.COLOR_GOLD .. L["--- DragonToast Status ---"] .. ns.COLOR_RESET)
    print("  " .. L["Enabled"] .. ": " .. YesNo(db.enabled) .. ns.COLOR_RESET)
    print("  " .. L["Min Quality"] .. ": " .. (QUALITY_NAMES[db.filters.minQuality] or L["Unknown"]))
    print("  " .. L["Self Loot"] .. ": " .. YesNo(db.filters.showSelfLoot))
    print("  " .. L["Group Loot"] .. ": " .. YesNo(db.filters.showGroupLoot))
    print("  " .. L["Currency"] .. ": " .. YesNo(db.filters.showCurrency))
    print("  " .. L["Gold"] .. ": " .. YesNo(db.filters.showGold))
    print("  " .. L["Quest Items"] .. ": " .. YesNo(db.filters.showQuestItems))
    print("  " .. L["XP Gains"] .. ": " .. YesNo(db.filters.showXP))
    print("  " .. L["Honor Gains"] .. ": " .. YesNo(db.filters.showHonor))
    print("  " .. L["Reputation Gains"] .. ": " .. YesNo(db.filters.showReputation))
    print("  " .. L["Mail"] .. ": " .. YesNo(db.filters.showMail))
    print("  " .. L["Max Toasts"] .. ": " .. db.display.maxToasts)
    print("  " .. L["Growth"] .. ": " .. db.display.growDirection)
    print("  " .. L["Animations"] .. ": " .. YesNo(db.animation.enableAnimations))
    print("  " .. L["Hold Duration"] .. ": " .. db.animation.holdDuration .. L["s"])
    print("  " .. L["Sound"] .. ": " .. YesNo(db.sound.enabled))
    print("  " .. L["Defer in Combat"] .. ": " .. YesNo(db.combat.deferInCombat))
    print("  " .. L["ElvUI Skin"] .. ": " .. YesNo(db.elvui.useSkin))
    print("  " .. L["Minimap Icon"] .. ": " .. YesNo(not db.minimap.hide))
    print("  " .. L["Anchor"] .. ": " .. db.display.anchorPoint
        .. " (" .. math.floor(db.display.anchorX) .. ", " .. math.floor(db.display.anchorY) .. ")")
    local tmStatus = (ns.TestToasts and ns.TestToasts.IsTestModeActive())
        and ns.COLOR_GREEN .. L["Active"] or L["Inactive"]
    print("  " .. L["Test Mode"] .. ": " .. tmStatus .. ns.COLOR_RESET)
end

-------------------------------------------------------------------------------
-- Help Display
-------------------------------------------------------------------------------

local HELP_ENTRIES = {
    { "",                 L["Show this help"] },
    { " toggle",          L["Toggle addon on/off"] },
    { " config",          L["Open settings panel"] },
    { " lock",            L["Toggle anchor lock (drag to move)"] },
    { " test",            L["Show a test toast"] },
    { " test stack",      L["Test item stacking (3 rapid items)"] },
    { " test xp",         L["Test XP accumulation"] },
    { " test gold",       L["Test gold accumulation"] },
    { " test honor",      L["Test honor accumulation"] },
    { " test reputation", L["Test reputation accumulation"] },
    { " test all",        L["Run all stacking tests"] },
    { " testmode",        L["Toggle continuous test toast generation"] },
    { " clear",           L["Dismiss all toasts"] },
    { " reset",           L["Reset anchor position to default"] },
    { " status",          L["Show current settings"] },
    { " help",            L["Show this help"] },
}

local function PrintHelp()
    print(ns.COLOR_GOLD .. L["--- DragonToast Commands ---"] .. ns.COLOR_RESET)
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
        ns.Print(L["Addon enabled"])
        return
    end

    ns.Addon:OnDisable()
    ns.Print(L["Addon disabled"])
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
        if not ns.TestToasts then
            ns.Print(L["TestToasts module is not loaded."])
            return
        end
        ns.TestToasts.ShowTestToast()

    elseif cmd:find("^test ") then
        if not ns.TestToasts then
            ns.Print(L["TestToasts module is not loaded."])
            return
        end
        local subCmd = cmd:match("^test (.+)$")
        ns.TestToasts.RunStackTest(subCmd)

    elseif cmd == "testmode" then
        if not ns.TestToasts then
            ns.Print(L["TestToasts module is not loaded."])
            return
        end
        ns.TestToasts.ToggleTestMode()

    elseif cmd == "clear" then
        ns.ToastManager.ClearAll()
        ns.Print(L["All toasts cleared."])

    elseif cmd == "reset" then
        ns.ToastManager.ResetAnchor()

    elseif cmd == "status" then
        PrintStatus()

    elseif cmd == "help" or cmd == "?" then
        PrintHelp()

    else
        ns.Print(L["Unknown command: "] .. ns.COLOR_WHITE .. cmd .. ns.COLOR_RESET)
        PrintHelp()
    end
end
