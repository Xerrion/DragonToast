-------------------------------------------------------------------------------
-- MailListener_Mists.lua
-- MoP mailbox wrapper around shared mail listener implementation
--
-- Supported versions: MoP Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

-------------------------------------------------------------------------------
-- Version guard: only run on MoP Classic
-------------------------------------------------------------------------------

local WOW_PROJECT_ID = WOW_PROJECT_ID
local WOW_PROJECT_MISTS_CLASSIC = WOW_PROJECT_MISTS_CLASSIC

if WOW_PROJECT_ID ~= WOW_PROJECT_MISTS_CLASSIC then return end

-------------------------------------------------------------------------------
-- Shared implementation
-------------------------------------------------------------------------------

ns.MailListener = ns.MailListenerShared.Create({
    versionName = "Mists",
    supportsAttachmentCurrencyFlag = true,
})
