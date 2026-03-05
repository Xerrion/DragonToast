-------------------------------------------------------------------------------
-- Core.lua
-- Entry point for DragonToast_Options companion addon
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

-------------------------------------------------------------------------------
-- Cached WoW API
-------------------------------------------------------------------------------

local tinsert = table.insert

-------------------------------------------------------------------------------
-- Bridge to DragonToast namespace
-------------------------------------------------------------------------------

local dtns = _G.DragonToastNS

-------------------------------------------------------------------------------
-- Widget and tab registries (populated by subsequent files)
-------------------------------------------------------------------------------

ns.Widgets = {}
ns.Tabs = {}

-------------------------------------------------------------------------------
-- Panel state
-------------------------------------------------------------------------------

local optionsPanel
local tabGroup

-------------------------------------------------------------------------------
-- Refresh all visible widget values from db
-------------------------------------------------------------------------------

local function RefreshVisibleWidgets()
    if not tabGroup then return end
    local selectedId = tabGroup:GetSelectedTab()
    if not selectedId then return end
    for _, tab in ipairs(ns.Tabs) do
        if tab.id == selectedId and tab.refreshFunc then
            tab.refreshFunc()
            break
        end
    end
end

-------------------------------------------------------------------------------
-- Create the options panel (called lazily on first Open)
-------------------------------------------------------------------------------

local function CreateOptionsPanel()
    local panel = ns.Widgets.CreatePanel("DragonToastOptionsFrame", 800, 600)

    -- Tab group below title bar
    tabGroup = ns.Widgets.CreateTabGroup(panel, ns.Tabs)
    tabGroup:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -32)
    tabGroup:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -8, 8)

    -- ESC-closable
    tinsert(UISpecialFrames, "DragonToastOptionsFrame")

    optionsPanel = panel
end

-------------------------------------------------------------------------------
-- Global API
-------------------------------------------------------------------------------

DragonToast_Options = {}

function DragonToast_Options.Open()
    if not optionsPanel then
        CreateOptionsPanel()
    end
    optionsPanel:Show()
    RefreshVisibleWidgets()
end

function DragonToast_Options.Close()
    if not optionsPanel then return end
    optionsPanel:Hide()
end

function DragonToast_Options.Toggle()
    if optionsPanel and optionsPanel:IsShown() then
        DragonToast_Options.Close()
    else
        DragonToast_Options.Open()
    end
end

-------------------------------------------------------------------------------
-- Expose namespace bridge for widgets/tabs
-------------------------------------------------------------------------------

ns.dtns = dtns
ns.RefreshVisibleWidgets = RefreshVisibleWidgets
