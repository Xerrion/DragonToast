-------------------------------------------------------------------------------
-- MailListener_TBC.lua
-- TBC mailbox wrapper around shared mail listener implementation
--
-- Supported versions: TBC Anniversary
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

-------------------------------------------------------------------------------
-- Version guard: only run on TBC Anniversary
-------------------------------------------------------------------------------

local WOW_PROJECT_ID = WOW_PROJECT_ID
local WOW_PROJECT_BURNING_CRUSADE_CLASSIC = WOW_PROJECT_BURNING_CRUSADE_CLASSIC

if WOW_PROJECT_ID ~= WOW_PROJECT_BURNING_CRUSADE_CLASSIC then return end

-------------------------------------------------------------------------------
-- Shared implementation
-------------------------------------------------------------------------------

ns.MailListener = ns.MailListenerShared.Create({
    versionName = "TBC",
    supportsAttachmentCurrencyFlag = false,
})
