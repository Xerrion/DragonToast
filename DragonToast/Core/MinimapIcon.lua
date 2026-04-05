-------------------------------------------------------------------------------
-- MinimapIcon.lua
-- Minimap button via LibDBIcon-1.0 and LibDataBroker-1.1
--
-- Supported versions: TBC Anniversary, Retail, MoP Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

-------------------------------------------------------------------------------
-- Cached references
-------------------------------------------------------------------------------

local LibStub = LibStub
local L = LibStub("AceLocale-3.0"):GetLocale("DragonToast")

-------------------------------------------------------------------------------
-- Minimap Icon Module
-------------------------------------------------------------------------------

ns.MinimapIcon = {}

function ns.MinimapIcon.Initialize()
    local LDB = LibStub("LibDataBroker-1.1", true)
    local LDBIcon = LibStub("LibDBIcon-1.0", true)

    if not LDB or not LDBIcon then
        ns.DebugPrint("LibDataBroker or LibDBIcon not found, minimap icon disabled")
        return
    end

    local dataObject = LDB:NewDataObject("DragonToast", {
        type = "launcher",
        icon = "Interface\\AddOns\\DragonToast\\DragonToast_Icon",
        label = "DragonToast",
        text = "DragonToast",

        OnClick = function(_, button)
            if button == "LeftButton" then
                if IsShiftKeyDown() then
                    -- Shift-left: test toast
                    if ns.TestToasts.ShowTestToast then
                        ns.TestToasts.ShowTestToast()
                    end
                else
                    -- Left-click: toggle config
                    if ns.ToggleOptions then
                        ns.ToggleOptions()
                    end
                end
            elseif button == "RightButton" then
                -- Right-click: toggle addon on/off
                local db = ns.Addon.db.profile
                db.enabled = not db.enabled
                if db.enabled then
                    ns.Addon:OnEnable()
                    ns.Print(L["Addon enabled"])
                else
                    ns.Addon:OnDisable()
                    ns.Print(L["Addon disabled"])
                end
            elseif button == "MiddleButton" then
                -- Middle-click: toggle anchor lock
                ns.ToastManager.ToggleLock()
            end
        end,

        OnTooltipShow = function(tooltip)
            tooltip:AddDoubleLine("DragonToast", ns.VERSION or "", 1, 0.82, 0, 0.6, 0.6, 0.6)
            tooltip:AddLine(" ")

            local db = ns.Addon.db.profile
            local status = db.enabled and (ns.COLOR_GREEN .. L["Enabled"] .. ns.COLOR_RESET)
                or (ns.COLOR_RED .. L["Disabled"] .. ns.COLOR_RESET)
            tooltip:AddLine(L["Status: "] .. status)
            tooltip:AddLine(" ")

            tooltip:AddLine(ns.COLOR_WHITE .. L["Left-Click"] .. ns.COLOR_RESET .. " - " .. L["Open settings"])
            tooltip:AddLine(ns.COLOR_WHITE .. L["Shift-Left-Click"] .. ns.COLOR_RESET .. " - " .. L["Test toast"])
            tooltip:AddLine(ns.COLOR_WHITE .. L["Right-Click"] .. ns.COLOR_RESET .. " - " .. L["Toggle on/off"])
            tooltip:AddLine(ns.COLOR_WHITE .. L["Middle-Click"] .. ns.COLOR_RESET .. " - " .. L["Toggle anchor lock"])
        end,
    })

    -- Register with LibDBIcon using the minimap table from AceDB
    LDBIcon:Register("DragonToast", dataObject, ns.Addon.db.profile.minimap)

    ns.DebugPrint("Minimap icon initialized")
end

function ns.MinimapIcon.SetShown(shown)
    local LDBIcon = LibStub("LibDBIcon-1.0", true)
    if not LDBIcon then return end

    local db = ns.Addon.db.profile.minimap
    db.hide = not shown
    if shown then
        LDBIcon:Show("DragonToast")
    else
        LDBIcon:Hide("DragonToast")
    end
end

function ns.MinimapIcon.Refresh()
    local LDBIcon = LibStub("LibDBIcon-1.0", true)
    if not LDBIcon then return end

    LDBIcon:Refresh("DragonToast", ns.Addon.db.profile.minimap)
end
