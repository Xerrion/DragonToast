-------------------------------------------------------------------------------
-- ConfigWindow.lua
-- LoadOnDemand bridge for DragonToast_Options
--
-- Supported versions: TBC Anniversary, Retail, MoP Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

local C_AddOns = C_AddOns
local L = LibStub("AceLocale-3.0"):GetLocale("DragonToast")

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------

local function IsOptionsLoaded()
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        return C_AddOns.IsAddOnLoaded("DragonToast_Options")
    elseif _G.IsAddOnLoaded then
        return _G.IsAddOnLoaded("DragonToast_Options")
    end
    return false
end

local function LoadOptions()
    if IsOptionsLoaded() then return true end

    if C_AddOns and C_AddOns.LoadAddOn then
        C_AddOns.LoadAddOn("DragonToast_Options")
    elseif _G.LoadAddOn then
        _G.LoadAddOn("DragonToast_Options")
    end

    return IsOptionsLoaded()
end

-------------------------------------------------------------------------------
-- Config Window Management
-------------------------------------------------------------------------------

function ns.OpenOptions()
    if not LoadOptions() then
        ns.Print(L["DragonToast_Options addon not found. Please ensure it is installed."])
        return
    end

    if DragonToast_Options and DragonToast_Options.Open then
        DragonToast_Options.Open()
    end
end

function ns.CloseOptions()
    if not IsOptionsLoaded() then return end

    if DragonToast_Options and DragonToast_Options.Close then
        DragonToast_Options.Close()
    end
end

function ns.ToggleOptions()
    if not LoadOptions() then
        ns.Print(L["DragonToast_Options addon not found. Please ensure it is installed."])
        return
    end

    if DragonToast_Options and DragonToast_Options.Toggle then
        DragonToast_Options.Toggle()
    else
        ns.OpenOptions()
    end
end
