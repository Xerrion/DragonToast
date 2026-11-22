-------------------------------------------------------------------------------
-- MailListener_TBC.lua
-- TBC mailbox wrapper around shared mail listener implementation
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

-------------------------------------------------------------------------------
-- Shared implementation
-------------------------------------------------------------------------------

if not ns.MailListenerShared or not ns.MailListenerShared.Create then return end

ns.MailListener = ns.MailListenerShared.Create({
    versionName = "TBC",
    supportsAttachmentCurrencyFlag = false,
})
