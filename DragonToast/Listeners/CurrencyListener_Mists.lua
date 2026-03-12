-------------------------------------------------------------------------------
-- CurrencyListener_Mists.lua
-- MoP wrapper for the shared currency listener implementation
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

local CreateCurrencyListenerModule = ns.CreateCurrencyListenerModule

if not CreateCurrencyListenerModule then
    error("CurrencyListener shared implementation must load before Mists wrapper")
end

local listener = CreateCurrencyListenerModule()

ns.CurrencyListener = ns.CurrencyListener or {}
ns.CurrencyListener.Initialize = listener.Initialize
ns.CurrencyListener.Shutdown = listener.Shutdown
