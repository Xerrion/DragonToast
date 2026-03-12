-------------------------------------------------------------------------------
-- HonorListener_Retail.lua
-- Retail wrapper for the shared honor listener implementation
--
-- Supported versions: Retail
-------------------------------------------------------------------------------

local _, ns = ...

-------------------------------------------------------------------------------
-- Version guard: only run on Retail
-------------------------------------------------------------------------------

local WOW_PROJECT_ID = WOW_PROJECT_ID
local WOW_PROJECT_MAINLINE = WOW_PROJECT_MAINLINE

if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then return end

local CreateHonorListenerModule = ns.CreateHonorListenerModule

local RETAIL_ALLIANCE_HONOR_ICON = 463450
local RETAIL_HORDE_HONOR_ICON = 463451

if not CreateHonorListenerModule then
    error("HonorListener shared implementation must load before Retail wrapper")
end

local listener = CreateHonorListenerModule({
    iconByFaction = {
        Alliance = RETAIL_ALLIANCE_HONOR_ICON,
        Horde = RETAIL_HORDE_HONOR_ICON,
    },
    iconFallback = RETAIL_ALLIANCE_HONOR_ICON,
})

ns.HonorListener = ns.HonorListener or {}
ns.HonorListener.Initialize = listener.Initialize
ns.HonorListener.Shutdown = listener.Shutdown
ns.HonorListener.GetHonorIcon = listener.GetHonorIcon
