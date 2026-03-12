-------------------------------------------------------------------------------
-- ReputationListener_Retail.lua
-- Retail wrapper for the shared reputation listener implementation
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

local CreateReputationListenerModule = ns.CreateReputationListenerModule

if not CreateReputationListenerModule then
    error("ReputationListener shared implementation must load before Retail wrapper")
end

local listener = CreateReputationListenerModule()

ns.ReputationListener = ns.ReputationListener or {}
ns.ReputationListener.Initialize = listener.Initialize
ns.ReputationListener.Shutdown = listener.Shutdown
ns.ReputationListener.GetReputationIcon = listener.GetReputationIcon
