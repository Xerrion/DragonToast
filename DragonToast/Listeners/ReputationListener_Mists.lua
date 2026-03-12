-------------------------------------------------------------------------------
-- ReputationListener_Mists.lua
-- MoP wrapper for the shared reputation listener implementation
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

local CreateReputationListenerModule = ns.CreateReputationListenerModule

if not CreateReputationListenerModule then
    error("ReputationListener shared implementation must load before Mists wrapper")
end

local listener = CreateReputationListenerModule()

ns.ReputationListener = ns.ReputationListener or {}
ns.ReputationListener.Initialize = listener.Initialize
ns.ReputationListener.Shutdown = listener.Shutdown
ns.ReputationListener.GetReputationIcon = listener.GetReputationIcon
