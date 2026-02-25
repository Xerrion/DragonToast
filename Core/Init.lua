-------------------------------------------------------------------------------
-- Init.lua
-- DragonToast addon bootstrap and namespace setup
--
-- Supported versions: TBC Anniversary, Retail, MoP Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

ns.ADDON_NAME = ADDON_NAME
ns.ADDON_TITLE = "DragonToast"
ns.VERSION = "@project-version@"

-- Color constants
ns.COLOR_GOLD = "|cffffd700"
ns.COLOR_GREEN = "|cff00ff00"
ns.COLOR_RED = "|cffff0000"
ns.COLOR_GRAY = "|cff888888"
ns.COLOR_WHITE = "|cffffffff"
ns.COLOR_RESET = "|r"

-- Quality colors (fallback, also available via ITEM_QUALITY_COLORS)
ns.QUALITY_COLORS = {
    [0] = { r = 0.62, g = 0.62, b = 0.62 }, -- Poor
    [1] = { r = 1.00, g = 1.00, b = 1.00 }, -- Common
    [2] = { r = 0.12, g = 1.00, b = 0.00 }, -- Uncommon
    [3] = { r = 0.00, g = 0.44, b = 0.87 }, -- Rare
    [4] = { r = 0.64, g = 0.21, b = 0.93 }, -- Epic
    [5] = { r = 1.00, g = 0.50, b = 0.00 }, -- Legendary
    [6] = { r = 0.90, g = 0.80, b = 0.50 }, -- Artifact
    [7] = { r = 0.00, g = 0.80, b = 1.00 }, -- Heirloom
}

-------------------------------------------------------------------------------
-- Namespace sub-tables (populated by other files)
-------------------------------------------------------------------------------

ns.ToastManager = {}
ns.ToastFrame = {}
ns.ToastAnimations = {}
ns.ElvUISkin = {}
ns.LootListener = {}
ns.XPListener = {}
ns.HonorListener = {}
ns.MinimapIcon = {}

-------------------------------------------------------------------------------
-- AceAddon Setup
-------------------------------------------------------------------------------

local Addon = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME, "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
ns.Addon = Addon

-------------------------------------------------------------------------------
-- Utility: Print with addon prefix
-------------------------------------------------------------------------------

function ns.Print(msg)
    print(ns.COLOR_GOLD .. "[DragonToast]|r " .. msg)
end

function ns.DebugPrint(msg)
    local db = ns.Addon.db
    if db and db.profile and db.profile.debug then
        print(ns.COLOR_GRAY .. "[DragonToast Debug]|r " .. msg)
    end
end

-------------------------------------------------------------------------------
-- Utility: Number formatting (shared across modules)
-------------------------------------------------------------------------------

function ns.FormatNumber(num)
    if num >= 1000000 then
        local divided = num / 1000000
        if math.floor(divided) == divided then
            return string.format("%dM", divided)
        end
        return string.format("%.1fM", divided)
    elseif num >= 1000 then
        local divided = num / 1000
        if math.floor(divided) == divided then
            return string.format("%dK", divided)
        end
        return string.format("%.1fK", divided)
    end
    return tostring(num)
end

-------------------------------------------------------------------------------
-- AceAddon Lifecycle
-------------------------------------------------------------------------------

function Addon:OnInitialize()
    -- AceDB setup (Config.lua defines the defaults and registers the DB)
    -- This is called by Config.lua's InitializeDB function
    ns.InitializeDB(self)

    -- Register slash commands
    self:RegisterChatCommand("dragontoast", "OnSlashCommand")
    self:RegisterChatCommand("dt", "OnSlashCommand")

    -- Initialize minimap icon (after DB is ready)
    if ns.MinimapIcon.Initialize then
        ns.MinimapIcon.Initialize()
    end

    ns.Print("Loaded. Type " .. ns.COLOR_WHITE .. "/dt help" .. ns.COLOR_RESET .. " for commands.")
end

function Addon:OnEnable()
    -- Initialize display system
    ns.ToastManager.Initialize()

    -- Initialize loot listener (version-specific file populates ns.LootListener)
    if ns.LootListener.Initialize then
        ns.LootListener.Initialize(self)
    end

    -- Apply ElvUI skin if available
    if ns.ElvUISkin.Apply then
        ns.ElvUISkin.Apply()
    end

    -- Initialize XP listener
    if ns.XPListener.Initialize then
        ns.XPListener.Initialize(self)
    end

    -- Initialize Honor listener
    if ns.HonorListener.Initialize then
        ns.HonorListener.Initialize(self)
    end

    -- Initialize DragonLoot bridge (optional cross-addon integration)
    if ns.DragonLootBridge and ns.DragonLootBridge.Initialize then
        ns.DragonLootBridge.Initialize(self)
    end
end

function Addon:OnDisable()
    -- Shutdown loot listener
    if ns.LootListener.Shutdown then
        ns.LootListener.Shutdown()
    end

    -- Shutdown XP listener
    if ns.XPListener.Shutdown then
        ns.XPListener.Shutdown()
    end

    -- Shutdown Honor listener
    if ns.HonorListener.Shutdown then
        ns.HonorListener.Shutdown()
    end

    -- Shutdown DragonLoot bridge
    if ns.DragonLootBridge and ns.DragonLootBridge.Shutdown then
        ns.DragonLootBridge.Shutdown()
    end

    -- Clear all toasts
    ns.ToastManager.ClearAll()
end

function Addon:OnSlashCommand(input)
    -- Routed to SlashCommands.lua
    if ns.HandleSlashCommand then
        ns.HandleSlashCommand(input)
    end
end
