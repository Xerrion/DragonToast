-------------------------------------------------------------------------------
-- ReputationListener_TBC.lua
-- TBC wrapper for the shared reputation listener implementation
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

local CreateReputationListenerModule = ns.CreateReputationListenerModule

if not CreateReputationListenerModule then
    error("ReputationListener shared implementation must load before TBC wrapper")
end

local listener = CreateReputationListenerModule()

ns.ReputationListener = ns.ReputationListener or {}
ns.ReputationListener.Initialize = listener.Initialize
ns.ReputationListener.Shutdown = listener.Shutdown
ns.ReputationListener.GetReputationIcon = listener.GetReputationIcon
