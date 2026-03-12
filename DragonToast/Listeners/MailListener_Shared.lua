-------------------------------------------------------------------------------
-- MailListener_Shared.lua
-- Shared mailbox listener implementation with version-specific configuration
--
-- Supported versions: TBC Anniversary, Retail, MoP Classic
-------------------------------------------------------------------------------

local _, ns = ...

local Utils = ns.ListenerUtils
local QueueUtils = ns.QueueUtils

-------------------------------------------------------------------------------
-- Cached WoW API
-------------------------------------------------------------------------------

local GetCoinTextureString = GetCoinTextureString
local GetInboxHeaderInfo = GetInboxHeaderInfo
local GetInboxItem = GetInboxItem
local GetInboxInvoiceInfo = GetInboxInvoiceInfo
local GetInboxText = GetInboxText
local GetItemInfo = GetItemInfo
local GetTime = GetTime
local UnitName = UnitName
local hooksecurefunc = hooksecurefunc
local string_format = string.format
local type = type
local L = ns.L

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local ATTACHMENTS_MAX = 12 -- ATTACHMENTS_MAX_RECEIVE in Blizzard code

-------------------------------------------------------------------------------
-- Shared helpers
-------------------------------------------------------------------------------

local function GetMailSourceLabel(index)
    local _, _, _, isInvoice = GetInboxText(index)
    if isInvoice then
        local invoiceType = GetInboxInvoiceInfo(index)
        if invoiceType == "buyer" then
            return L["Auction Won"]
        elseif invoiceType == "seller" or invoiceType == "seller_temp_invoice" then
            return L["Auction Sale"]
        end
    end

    local _, _, sender = GetInboxHeaderInfo(index)
    if sender and sender ~= "" then
        return string_format(L["Mail - %s"], sender)
    end

    return L["Mail"]
end

local function SnapshotItemAttachment(index, attachIndex, sourceLabel, supportsAttachmentCurrencyFlag)
    local _, itemID, _, count, _, _, isCurrency = GetInboxItem(index, attachIndex)
    if not itemID then return nil end

    return {
        type = "item",
        mailIndex = index,
        attachIndex = attachIndex,
        itemID = itemID,
        count = count or 1,
        isCurrency = supportsAttachmentCurrencyFlag and (isCurrency or false) or false,
        sourceLabel = sourceLabel,
    }
end

local function SnapshotMoney(index, money, sourceLabel)
    if not money or money <= 0 then return nil end

    return {
        type = "money",
        mailIndex = index,
        copperAmount = money,
        sourceLabel = sourceLabel,
    }
end

local function PassesFilter(lootData)
    local db = ns.Addon.db.profile
    if not db.enabled then return false end
    if not db.filters.showMail then return false end

    if lootData.isCurrency then
        if lootData.copperAmount and not db.filters.showGold then
            return false
        end
    elseif lootData.itemQuality and lootData.itemQuality < db.filters.minQuality then
        return false
    end

    return true
end

local function BuildMailItemData(snapshot)
    local itemName, _, itemQuality, itemLevel, _, _, itemSubType,
        _, _, itemTexture, _, _, _, _, _, _, _, itemLink = GetItemInfo(snapshot.itemID)

    if not itemName then return nil end

    return {
        itemLink = itemLink,
        itemID = snapshot.itemID,
        itemName = itemName,
        itemQuality = itemQuality or 1,
        itemLevel = itemLevel or 0,
        itemType = snapshot.sourceLabel,
        itemSubType = itemSubType or "",
        itemIcon = itemTexture or Utils.QUESTION_MARK_ICON,
        quantity = snapshot.count,
        looter = UnitName("player"),
        isSelf = true,
        isCurrency = snapshot.isCurrency or false,
        isMail = true,
        timestamp = GetTime(),
    }
end

local function BuildMailMoneyData(snapshot)
    return {
        itemLink = nil,
        itemID = nil,
        itemName = GetCoinTextureString(snapshot.copperAmount),
        itemQuality = 1,
        itemLevel = 0,
        itemType = snapshot.sourceLabel,
        itemSubType = "Gold",
        itemIcon = Utils.GOLD_ICON,
        quantity = 1,
        copperAmount = snapshot.copperAmount,
        looter = UnitName("player"),
        isSelf = true,
        isCurrency = true,
        isMail = true,
        timestamp = GetTime(),
    }
end

local function ProcessSnapshot(snapshot)
    if not snapshot then return end

    if snapshot.type == "money" then
        local lootData = BuildMailMoneyData(snapshot)
        if PassesFilter(lootData) then
            ns.ToastManager.QueueToast(lootData)
        end
        return
    end

    Utils.RetryWithTimer(
        ns.Addon,
        function() return BuildMailItemData(snapshot) end,
        PassesFilter
    )
end

local function QueueSnapshot(queue, snapshot)
    if not snapshot then return end
    QueueUtils.Push(queue, snapshot)
end

local function SnapshotMailMoney(index, queue, sourceLabel)
    local _, _, _, _, money = GetInboxHeaderInfo(index)
    QueueSnapshot(queue, SnapshotMoney(index, money, sourceLabel))
end

local function SnapshotAllMailAttachments(index, queue, sourceLabel, supportsAttachmentCurrencyFlag)
    for attachIndex = 1, ATTACHMENTS_MAX do
        local snapshot = SnapshotItemAttachment(index, attachIndex, sourceLabel, supportsAttachmentCurrencyFlag)
        QueueSnapshot(queue, snapshot)
    end
end

-------------------------------------------------------------------------------
-- Factory
-------------------------------------------------------------------------------

function ns.MailListenerShared.Create(config)
    if type(config) ~= "table" then
        error("MailListener_Shared.Create - config must be a table", 2)
    end

    if type(config.versionName) ~= "string" or config.versionName == "" then
        error("MailListener_Shared.Create - config.versionName must be a non-empty string", 2)
    end

    local supportsAttachmentCurrencyFlag = config.supportsAttachmentCurrencyFlag == true
    local pendingTakes = QueueUtils.New()
    local isMailboxOpen = false
    local areHooksInstalled = false
    local listener = {}

    local function OnTakeInboxItem(index, attachIndex)
        if not isMailboxOpen then return end

        local sourceLabel = GetMailSourceLabel(index)
        local snapshot = SnapshotItemAttachment(index, attachIndex, sourceLabel, supportsAttachmentCurrencyFlag)
        QueueSnapshot(pendingTakes, snapshot)
    end

    local function OnTakeInboxMoney(index)
        if not isMailboxOpen then return end

        local sourceLabel = GetMailSourceLabel(index)
        SnapshotMailMoney(index, pendingTakes, sourceLabel)
    end

    local function OnAutoLootMailItem(index)
        if not isMailboxOpen then return end

        local sourceLabel = GetMailSourceLabel(index)
        SnapshotMailMoney(index, pendingTakes, sourceLabel)
        SnapshotAllMailAttachments(index, pendingTakes, sourceLabel, supportsAttachmentCurrencyFlag)
    end

    local function OnMailShow()
        isMailboxOpen = true
        ns.DebugPrint("MailListener: mailbox opened")
    end

    local function OnMailClosed()
        isMailboxOpen = false
        QueueUtils.Reset(pendingTakes)
        ns.DebugPrint("MailListener: mailbox closed, pending state cleared")
    end

    local function OnMailSuccess()
        local snapshot = QueueUtils.Pop(pendingTakes)
        ProcessSnapshot(snapshot)
    end

    local function OnMailFailed()
        QueueUtils.Pop(pendingTakes)
        ns.DebugPrint("MailListener: mail operation failed, discarded pending snapshot")
    end

    function listener.Initialize(addon)
        if not areHooksInstalled then
            hooksecurefunc("TakeInboxItem", OnTakeInboxItem)
            hooksecurefunc("TakeInboxMoney", OnTakeInboxMoney)
            hooksecurefunc("AutoLootMailItem", OnAutoLootMailItem)
            areHooksInstalled = true
        end

        addon:RegisterEvent("MAIL_SHOW", function() OnMailShow() end)
        addon:RegisterEvent("MAIL_CLOSED", function() OnMailClosed() end)
        addon:RegisterEvent("MAIL_SUCCESS", function() OnMailSuccess() end)
        addon:RegisterEvent("MAIL_FAILED", function() OnMailFailed() end)

        ns.DebugPrint(config.versionName .. " Mail Listener initialized")
    end

    function listener.Shutdown()
        ns.Addon:UnregisterEvent("MAIL_SHOW")
        ns.Addon:UnregisterEvent("MAIL_CLOSED")
        ns.Addon:UnregisterEvent("MAIL_SUCCESS")
        ns.Addon:UnregisterEvent("MAIL_FAILED")

        isMailboxOpen = false
        QueueUtils.Reset(pendingTakes)

        ns.DebugPrint(config.versionName .. " Mail Listener shut down")
    end

    return listener
end
