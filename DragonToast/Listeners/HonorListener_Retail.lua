-------------------------------------------------------------------------------
-- HonorListener_Retail.lua
-- Retail and WoW: Forever wrapper for the shared honor listener implementation
--
-- Supported versions: Retail, WoW: Forever
-------------------------------------------------------------------------------

local _, ns = ...

-------------------------------------------------------------------------------
-- Version guard: only run on Retail or WoW: Forever
-------------------------------------------------------------------------------

local WOW_PROJECT_ID = WOW_PROJECT_ID
local WOW_PROJECT_MAINLINE = WOW_PROJECT_MAINLINE
local WOW_PROJECT_CAMELOT = WOW_PROJECT_CAMELOT

if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE
    and (WOW_PROJECT_CAMELOT == nil or WOW_PROJECT_ID ~= WOW_PROJECT_CAMELOT) then
    return
end

if not ns.HonorListenerShared or not ns.HonorListenerShared.Create then return end

local RETAIL_ALLIANCE_HONOR_ICON = 463450
local RETAIL_HORDE_HONOR_ICON = 463451

ns.HonorListener = ns.HonorListenerShared.Create({
    iconByFaction = {
        Alliance = RETAIL_ALLIANCE_HONOR_ICON,
        Horde = RETAIL_HORDE_HONOR_ICON,
    },
    iconFallback = RETAIL_ALLIANCE_HONOR_ICON,
})
