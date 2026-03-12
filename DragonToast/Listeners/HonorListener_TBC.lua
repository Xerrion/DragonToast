-------------------------------------------------------------------------------
-- HonorListener_TBC.lua
-- TBC wrapper for the shared honor listener implementation
--
-- Supported versions: TBC Anniversary
-------------------------------------------------------------------------------

local _, ns = ...

-------------------------------------------------------------------------------
-- Version guard: only run on TBC Anniversary
-------------------------------------------------------------------------------

local WOW_PROJECT_ID = WOW_PROJECT_ID
local WOW_PROJECT_BURNING_CRUSADE_CLASSIC = WOW_PROJECT_BURNING_CRUSADE_CLASSIC

if WOW_PROJECT_ID ~= WOW_PROJECT_BURNING_CRUSADE_CLASSIC then return end

local CreateHonorListenerModule = ns.CreateHonorListenerModule

local TBC_ALLIANCE_HONOR_ICON = 132486
local TBC_HORDE_HONOR_ICON = 132485

if not CreateHonorListenerModule then
    error("HonorListener shared implementation must load before TBC wrapper")
end

local listener = CreateHonorListenerModule({
    iconByFaction = {
        Alliance = TBC_ALLIANCE_HONOR_ICON,
        Horde = TBC_HORDE_HONOR_ICON,
    },
    iconFallback = TBC_ALLIANCE_HONOR_ICON,
})

ns.HonorListener = ns.HonorListener or {}
ns.HonorListener.Initialize = listener.Initialize
ns.HonorListener.Shutdown = listener.Shutdown
ns.HonorListener.GetHonorIcon = listener.GetHonorIcon
