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

local ONE_THOUSAND = 1000
local ONE_MILLION = 1000000

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
-- Localization
-------------------------------------------------------------------------------

ns.L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)
local L = ns.L

-------------------------------------------------------------------------------
-- Namespace sub-tables (populated by other files)
-------------------------------------------------------------------------------

ns.ListenerUtils = {}
ns.QueueUtils = {}
ns.ToastManager = {}
ns.ToastFrame = {}
ns.ToastAnimations = {}
ns.ElvUISkin = {}
ns.LootListener = {}
ns.LootListenerShared = {}
ns.XPListener = {}
ns.HonorListener = {}
ns.HonorListenerShared = {}
ns.ReputationListener = {}
ns.ReputationListenerShared = {}
ns.CurrencyListener = {}
ns.CurrencyListenerShared = {}
ns.MessageBridge = {}
ns.TestToasts = {}
ns.MailListener = {}
ns.MailListenerShared = {}
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
    if num >= ONE_MILLION then
        local divided = num / ONE_MILLION
        if math.floor(divided) == divided then
            return string.format("%dM", divided)
        end
        return string.format("%.1fM", divided)
    elseif num >= ONE_THOUSAND then
        local divided = num / ONE_THOUSAND
        if math.floor(divided) == divided then
            return string.format("%dK", divided)
        end
        return string.format("%.1fK", divided)
    end
    return tostring(num)
end

-------------------------------------------------------------------------------
-- Expose namespace for companion addons (e.g. DragonToast_Options)
-------------------------------------------------------------------------------

DragonToastNS = ns

-------------------------------------------------------------------------------
-- Listener module registry (initialized/shutdown via loop in OnEnable/OnDisable)
-------------------------------------------------------------------------------

local LISTENER_MODULES = {
    "LootListener",
    "XPListener",
    "HonorListener",
    "ReputationListener",
    "CurrencyListener",
    "MailListener",
    "MessageBridge",
}

-------------------------------------------------------------------------------
-- AceAddon Lifecycle
-- Initialize addon runtime state, configuration, and UI integrations.
-- Performs database setup, registers the "dragontoast" and "dt" slash commands,
-- initializes the minimap icon if available, and prints the localized loaded message.

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

    ns.Print(L["LOADED_MESSAGE"])
end

-- Performs addon enable-time setup: initializes the toast display system, starts listener modules, and applies an ElvUI skin if present.
-- Initializes the core ToastManager, calls `Initialize` on each module listed in `LISTENER_MODULES` if available, and invokes `ns.ElvUISkin.Apply()` when provided.
function Addon:OnEnable()
    -- Initialize display system (always present)
    ns.ToastManager.Initialize()

    -- Initialize all listener modules
    for _, name in ipairs(LISTENER_MODULES) do
        local mod = ns[name]
        if mod and mod.Initialize then
            mod.Initialize(self)
        end
    end

    -- Apply ElvUI skin if available
    if ns.ElvUISkin.Apply then
        ns.ElvUISkin.Apply()
    end
end

function Addon:OnDisable()
    -- Shutdown all listener modules
    for _, name in ipairs(LISTENER_MODULES) do
        local mod = ns[name]
        if mod and mod.Shutdown then
            mod.Shutdown()
        end
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
