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
    local tmStatus = ns.ToastManager.IsTestModeActive()
        and ns.COLOR_GREEN .. "Active" or "Inactive"
    print("  Test Mode: " .. tmStatus .. ns.COLOR_RESET)
end

-------------------------------------------------------------------------------
-- Help Display
-------------------------------------------------------------------------------

local function PrintHelp()
    print(ns.COLOR_GOLD .. "--- DragonToast Commands ---" .. ns.COLOR_RESET)
    print("  " .. ns.COLOR_WHITE .. "/dt" .. ns.COLOR_RESET .. " — Toggle addon on/off")
    print("  " .. ns.COLOR_WHITE .. "/dt config" .. ns.COLOR_RESET .. " — Open settings panel")
    print("  " .. ns.COLOR_WHITE .. "/dt lock" .. ns.COLOR_RESET .. " — Toggle anchor lock (drag to move)")
    print("  " .. ns.COLOR_WHITE .. "/dt test" .. ns.COLOR_RESET .. " — Show a test toast")
    print("  " .. ns.COLOR_WHITE .. "/dt testmode" .. ns.COLOR_RESET .. " — Toggle continuous test toast generation")
    print("  " .. ns.COLOR_WHITE .. "/dt clear" .. ns.COLOR_RESET .. " — Dismiss all toasts")
    print("  " .. ns.COLOR_WHITE .. "/dt reset" .. ns.COLOR_RESET .. " — Reset anchor position to default")
    print("  " .. ns.COLOR_WHITE .. "/dt status" .. ns.COLOR_RESET .. " — Show current settings")
    print("  " .. ns.COLOR_WHITE .. "/dt help" .. ns.COLOR_RESET .. " — Show this help")
end

-------------------------------------------------------------------------------
-- Command Router
-------------------------------------------------------------------------------

function ns.HandleSlashCommand(input)
    local cmd = (input or ""):lower():trim()

    if cmd == "" then
        -- Toggle addon
        local db = ns.Addon.db.profile
        db.enabled = not db.enabled
        if db.enabled then
            ns.Addon:OnEnable()
            ns.Print("Addon " .. ns.COLOR_GREEN .. "enabled" .. ns.COLOR_RESET)
        else
            ns.Addon:OnDisable()
            ns.Print("Addon " .. ns.COLOR_RED .. "disabled" .. ns.COLOR_RESET)
        end

    elseif cmd == "config" or cmd == "options" or cmd == "settings" then
        -- Open standalone AceGUI config window
        if ns.ToggleConfigWindow then
            ns.ToggleConfigWindow()
        end

    elseif cmd == "lock" or cmd == "unlock" or cmd == "move" then
        ns.ToastManager.ToggleLock()

    elseif cmd == "test" then
        if ns.ToastManager.ShowTestToast then
            ns.ToastManager.ShowTestToast()
        end

    elseif cmd == "testmode" then
        ns.ToastManager.ToggleTestMode()

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
