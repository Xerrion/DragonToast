-------------------------------------------------------------------------------
-- MailListener_Retail.lua
-- Retail and WoW: Forever mailbox wrapper around the shared mail listener
--
-- Supported versions: Retail, WoW: Forever
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

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

-------------------------------------------------------------------------------
-- Shared implementation
-------------------------------------------------------------------------------

if not ns.MailListenerShared or not ns.MailListenerShared.Create then return end

ns.MailListener = ns.MailListenerShared.Create({
    versionName = "Retail",
    supportsAttachmentCurrencyFlag = true,
})
