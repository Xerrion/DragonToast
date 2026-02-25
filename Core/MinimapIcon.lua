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
                    if ns.ToastManager.ShowTestToast then
                        ns.ToastManager.ShowTestToast()
                    end
                else
                    -- Left-click: toggle config
                    if ns.ToggleConfigWindow then
                        ns.ToggleConfigWindow()
                    end
                end
            elseif button == "RightButton" then
                -- Right-click: toggle addon on/off
                local db = ns.Addon.db.profile
                db.enabled = not db.enabled
                if db.enabled then
                    ns.Addon:OnEnable()
                    ns.Print("Addon " .. ns.COLOR_GREEN .. "enabled" .. ns.COLOR_RESET)
                else
                    ns.Addon:OnDisable()
                    ns.Print("Addon " .. ns.COLOR_RED .. "disabled" .. ns.COLOR_RESET)
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
            local status = db.enabled and (ns.COLOR_GREEN .. "Enabled" .. ns.COLOR_RESET)
                or (ns.COLOR_RED .. "Disabled" .. ns.COLOR_RESET)
            tooltip:AddLine("Status: " .. status)
            tooltip:AddLine(" ")

            tooltip:AddLine(ns.COLOR_WHITE .. "Left-Click" .. ns.COLOR_RESET .. " — Open settings")
            tooltip:AddLine(ns.COLOR_WHITE .. "Shift-Left-Click" .. ns.COLOR_RESET .. " — Test toast")
            tooltip:AddLine(ns.COLOR_WHITE .. "Right-Click" .. ns.COLOR_RESET .. " — Toggle on/off")
            tooltip:AddLine(ns.COLOR_WHITE .. "Middle-Click" .. ns.COLOR_RESET .. " — Toggle anchor lock")
        end,
    })

    -- Register with LibDBIcon using the minimap table from AceDB
    LDBIcon:Register("DragonToast", dataObject, ns.Addon.db.profile.minimap)

    ns.DebugPrint("Minimap icon initialized")
end

function ns.MinimapIcon.Toggle()
    local LDBIcon = LibStub("LibDBIcon-1.0", true)
    if not LDBIcon then return end

    local db = ns.Addon.db.profile.minimap
    if db.hide then
        LDBIcon:Show("DragonToast")
        db.hide = false
    else
        LDBIcon:Hide("DragonToast")
        db.hide = true
    end
end

function ns.MinimapIcon.Refresh()
    local LDBIcon = LibStub("LibDBIcon-1.0", true)
    if not LDBIcon then return end

    LDBIcon:Refresh("DragonToast", ns.Addon.db.profile.minimap)
end
