-------------------------------------------------------------------------------
-- HonorListener_Mists.lua
-- MoP wrapper for the shared honor listener implementation
--
-- Supported versions: MoP Classic
-------------------------------------------------------------------------------

local _, ns = ...

-------------------------------------------------------------------------------
-- Version guard: only run on MoP Classic
-------------------------------------------------------------------------------

local WOW_PROJECT_ID = WOW_PROJECT_ID
local WOW_PROJECT_MISTS_CLASSIC = WOW_PROJECT_MISTS_CLASSIC

if WOW_PROJECT_ID ~= WOW_PROJECT_MISTS_CLASSIC then return end

local CreateHonorListenerModule = ns.CreateHonorListenerModule

local MISTS_ALLIANCE_HONOR_ICON = 463450
local MISTS_HORDE_HONOR_ICON = 463451

if not CreateHonorListenerModule then
    error("HonorListener shared implementation must load before Mists wrapper")
end

local listener = CreateHonorListenerModule({
    iconByFaction = {
        Alliance = MISTS_ALLIANCE_HONOR_ICON,
        Horde = MISTS_HORDE_HONOR_ICON,
    },
    iconFallback = MISTS_ALLIANCE_HONOR_ICON,
})

ns.HonorListener = ns.HonorListener or {}
ns.HonorListener.Initialize = listener.Initialize
ns.HonorListener.Shutdown = listener.Shutdown
ns.HonorListener.GetHonorIcon = listener.GetHonorIcon
