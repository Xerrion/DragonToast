-------------------------------------------------------------------------------
-- CurrencyListener_Retail.lua
-- Retail wrapper for the shared currency listener implementation
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

local CreateCurrencyListenerModule = ns.CreateCurrencyListenerModule

if not CreateCurrencyListenerModule then
    error("CurrencyListener shared implementation must load before Retail wrapper")
end

local listener = CreateCurrencyListenerModule()

ns.CurrencyListener = ns.CurrencyListener or {}
ns.CurrencyListener.Initialize = listener.Initialize
ns.CurrencyListener.Shutdown = listener.Shutdown
