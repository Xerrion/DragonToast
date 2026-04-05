-------------------------------------------------------------------------------
-- Core.lua
-- DragonToast_Options bootstrap - bridges DragonWidgets for DragonToast config
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

-------------------------------------------------------------------------------
-- Cached WoW API
-------------------------------------------------------------------------------

local tinsert = table.insert

-------------------------------------------------------------------------------
-- DragonWidgets bridge
-------------------------------------------------------------------------------

local DW = DragonWidgetsNS
if not DW then
    error("[DragonToast_Options] DragonWidgets is not loaded. Ensure DragonWidgets is installed and enabled.", 2)
end

ns.DW = DW

-------------------------------------------------------------------------------
-- Localization
-------------------------------------------------------------------------------

ns.L = LibStub("AceLocale-3.0"):GetLocale("DragonToast")

-------------------------------------------------------------------------------
-- Tab registry (populated by subsequent tab files)
-------------------------------------------------------------------------------

ns.Tabs = {}

-------------------------------------------------------------------------------
-- Shared dropdown values (used by multiple tab files)
-------------------------------------------------------------------------------

ns.QualityValues = {
    { value = 0, text = "|cff9d9d9dPoor|r" },
    { value = 1, text = "|cffffffffCommon|r" },
    { value = 2, text = "|cff1eff00Uncommon|r" },
    { value = 3, text = "|cff0070ddRare|r" },
    { value = 4, text = "|cffa335eeEpic|r" },
    { value = 5, text = "|cffff8000Legendary|r" },
}

-------------------------------------------------------------------------------
-- Appearance-change listener
--
-- When DragonWidgets fires OnAppearanceChanged, propagate to DragonToast
-- display modules that are currently loaded.
-------------------------------------------------------------------------------

DW.On("OnAppearanceChanged", function()
    local dt = ns.dtns
    if not dt then return end
    dt.ToastManager:UpdateLayout()
end)

-------------------------------------------------------------------------------
-- Panel state
-------------------------------------------------------------------------------

local panelResult

-------------------------------------------------------------------------------
-- Create the options panel (called lazily on first Open)
-------------------------------------------------------------------------------

local function CreateOptionsPanel()
    ns.dtns = _G.DragonToastNS
    if not ns.dtns then
        print("|cffff6600[DragonToast_Options]|r DragonToast namespace not found.")
        return
    end

    local tabDefs = {}
    for i = 1, #ns.Tabs do
        tinsert(tabDefs, ns.Tabs[i])
    end

    panelResult = DW.CreateOptionsPanel({
        name = "DragonToastOptionsFrame",
        title = "DragonToast Options",
        width = 800,
        height = 600,
        tabs = tabDefs,
    })

    ns.RefreshVisibleWidgets = panelResult.RefreshVisibleWidgets
end

-------------------------------------------------------------------------------
-- Global API
-------------------------------------------------------------------------------

DragonToast_Options = {}

function DragonToast_Options.Open()
    if not panelResult then
        CreateOptionsPanel()
    end
    if not panelResult then return end
    panelResult.Open()
end

function DragonToast_Options.Close()
    if not panelResult then return end
    panelResult.Close()
end

function DragonToast_Options.Toggle()
    if not panelResult then
        CreateOptionsPanel()
    end
    if not panelResult then return end
    panelResult.Toggle()
end
