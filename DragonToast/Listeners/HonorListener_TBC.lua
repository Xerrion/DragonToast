-------------------------------------------------------------------------------
-- HonorListener_TBC.lua
-- TBC wrapper for the shared honor listener implementation
--
-- Supported versions: TBC Anniversary, Classic Era
-------------------------------------------------------------------------------

local _, ns = ...

-------------------------------------------------------------------------------
-- Version guard: only run on TBC Anniversary and Classic Era
-------------------------------------------------------------------------------

local WOW_PROJECT_ID = WOW_PROJECT_ID
local WOW_PROJECT_BURNING_CRUSADE_CLASSIC = WOW_PROJECT_BURNING_CRUSADE_CLASSIC
local WOW_PROJECT_CLASSIC = WOW_PROJECT_CLASSIC

if WOW_PROJECT_ID ~= WOW_PROJECT_BURNING_CRUSADE_CLASSIC and WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC then return end

if not ns.HonorListenerShared or not ns.HonorListenerShared.Create then return end

local TBC_ALLIANCE_HONOR_ICON = 132486
local TBC_HORDE_HONOR_ICON = 132485

ns.HonorListener = ns.HonorListenerShared.Create({
    iconByFaction = {
        Alliance = TBC_ALLIANCE_HONOR_ICON,
        Horde = TBC_HORDE_HONOR_ICON,
    },
    iconFallback = TBC_ALLIANCE_HONOR_ICON,
})
