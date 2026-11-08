-------------------------------------------------------------------------------
-- CurrencyListener_Retail.lua
-- Retail and WoW: Forever wrapper for the shared currency listener implementation
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

if not ns.CurrencyListenerShared or not ns.CurrencyListenerShared.Create then return end

ns.CurrencyListener = ns.CurrencyListenerShared.Create()
