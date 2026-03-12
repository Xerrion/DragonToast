-------------------------------------------------------------------------------
-- MailListener_Retail.lua
-- Retail mailbox wrapper around shared mail listener implementation
--
-- Supported versions: Retail
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

-------------------------------------------------------------------------------
-- Version guard: only run on Retail
-------------------------------------------------------------------------------

local WOW_PROJECT_ID = WOW_PROJECT_ID
local WOW_PROJECT_MAINLINE = WOW_PROJECT_MAINLINE

if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then return end

-------------------------------------------------------------------------------
-- Shared implementation
-------------------------------------------------------------------------------

ns.MailListener = ns.MailListenerShared.Create({
    versionName = "Retail",
    supportsAttachmentCurrencyFlag = true,
})
