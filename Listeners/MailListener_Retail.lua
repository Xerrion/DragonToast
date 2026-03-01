-------------------------------------------------------------------------------
-- MailListener_Retail.lua
-- Mailbox item and gold collection toast notifications
--
-- Supported versions: Retail, MoP Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...
local Utils = ns.ListenerUtils

-------------------------------------------------------------------------------
-- Version guard: only run on Retail or MoP Classic
-------------------------------------------------------------------------------

local WOW_PROJECT_ID = WOW_PROJECT_ID
local WOW_PROJECT_MAINLINE = WOW_PROJECT_MAINLINE
local WOW_PROJECT_MISTS_CLASSIC = WOW_PROJECT_MISTS_CLASSIC

if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE
    and WOW_PROJECT_ID ~= WOW_PROJECT_MISTS_CLASSIC then
    return
end

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

-------------------------------------------------------------------------------
-- Module table
-------------------------------------------------------------------------------

ns.MailListener = ns.MailListener or {}

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local ATTACHMENTS_MAX = 12 -- ATTACHMENTS_MAX_RECEIVE in Blizzard code

-------------------------------------------------------------------------------
-- State
-------------------------------------------------------------------------------

local isMailboxOpen = false
local pendingTakes = { first = 1, last = 0 }

-------------------------------------------------------------------------------
-- FIFO queue helpers (matches ToastManager pattern)
-------------------------------------------------------------------------------

local function QueuePush(queue, item)
    queue.last = queue.last + 1
    queue[queue.last] = item
end

local function QueuePop(queue)
    if queue.first > queue.last then return nil end
    local item = queue[queue.first]
    queue[queue.first] = nil
    queue.first = queue.first + 1
    return item
end

local function QueueReset(queue)
    for i = queue.first, queue.last do
        queue[i] = nil
    end
    queue.first = 1
    queue.last = 0
end

-------------------------------------------------------------------------------
-- Mail source label
-------------------------------------------------------------------------------

local function GetMailSourceLabel(index)
    local _, _, _, isInvoice = GetInboxText(index)
    if isInvoice then
        local invoiceType = GetInboxInvoiceInfo(index)
        if invoiceType == "buyer" then
            return "Auction Won"
        elseif invoiceType == "seller" or invoiceType == "seller_temp_invoice" then
            return "Auction Sale"
        end
    end

    local _, _, sender = GetInboxHeaderInfo(index)
    if sender and sender ~= "" then
        return "Mail - " .. sender
    end
    return "Mail"
end

-------------------------------------------------------------------------------
-- Snapshot helpers
-------------------------------------------------------------------------------

local function SnapshotItemAttachment(index, attachIndex, sourceLabel)
    local _name, itemID, _texture, count, _quality, _canUse, isCurrency =
        GetInboxItem(index, attachIndex)
    if not itemID then return nil end

    return {
        type = "item",
        mailIndex = index,
        attachIndex = attachIndex,
        itemID = itemID,
        count = count or 1,
        isCurrency = isCurrency or false,
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

-------------------------------------------------------------------------------
-- Filter check
-------------------------------------------------------------------------------

local function PassesFilter(lootData)
    local db = ns.Addon.db.profile
    if not db.enabled then return false end
    if not db.filters.showMail then return false end

    if lootData.isCurrency then
        if lootData.copperAmount and not db.filters.showGold then
            return false
        end
    else
        if lootData.itemQuality and lootData.itemQuality < db.filters.minQuality then
            return false
        end
    end

    return true
end

-------------------------------------------------------------------------------
-- Build toast data (items)
-------------------------------------------------------------------------------

local function BuildMailItemData(snapshot)
    local itemName, _, itemQuality, itemLevel, _, _itemType, itemSubType,
        _, _, itemTexture, _, _, _, _, _, _, _, itemLink =
        GetItemInfo(snapshot.itemID)

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

-------------------------------------------------------------------------------
-- Build toast data (gold)
-------------------------------------------------------------------------------

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

-------------------------------------------------------------------------------
-- Process a completed take
-------------------------------------------------------------------------------

local function ProcessSnapshot(snapshot)
    if not snapshot then return end

    if snapshot.type == "money" then
        local lootData = BuildMailMoneyData(snapshot)
        if PassesFilter(lootData) then
            ns.ToastManager.QueueToast(lootData)
        end
    elseif snapshot.type == "item" then
        Utils.RetryWithTimer(
            ns.Addon,
            function() return BuildMailItemData(snapshot) end,
            PassesFilter
        )
    end
end

-------------------------------------------------------------------------------
-- Hook: TakeInboxItem(index, attachIndex)
-------------------------------------------------------------------------------

local function OnTakeInboxItem(index, attachIndex)
    if not isMailboxOpen then return end
    local sourceLabel = GetMailSourceLabel(index)
    local snapshot = SnapshotItemAttachment(index, attachIndex, sourceLabel)
    if snapshot then
        QueuePush(pendingTakes, snapshot)
    end
end

-------------------------------------------------------------------------------
-- Hook: TakeInboxMoney(index)
-------------------------------------------------------------------------------

local function OnTakeInboxMoney(index)
    if not isMailboxOpen then return end

    local _, _, _, _, money = GetInboxHeaderInfo(index)
    local sourceLabel = GetMailSourceLabel(index)
    local snapshot = SnapshotMoney(index, money, sourceLabel)
    if snapshot then
        QueuePush(pendingTakes, snapshot)
    end
end

-------------------------------------------------------------------------------
-- Hook: AutoLootMailItem(index)
-- Takes ALL attachments and money from a single mail
-------------------------------------------------------------------------------

local function OnAutoLootMailItem(index)
    if not isMailboxOpen then return end

    local sourceLabel = GetMailSourceLabel(index)

    -- Snapshot money
    local _, _, _, _, money = GetInboxHeaderInfo(index)
    local moneySnap = SnapshotMoney(index, money, sourceLabel)
    if moneySnap then
        QueuePush(pendingTakes, moneySnap)
    end

    -- Snapshot all item attachments
    for attachIndex = 1, ATTACHMENTS_MAX do
        local snap = SnapshotItemAttachment(index, attachIndex, sourceLabel)
        if snap then
            QueuePush(pendingTakes, snap)
        end
    end
end

-------------------------------------------------------------------------------
-- Event handlers
-------------------------------------------------------------------------------

local function OnMailShow()
    isMailboxOpen = true
    ns.DebugPrint("MailListener: mailbox opened")
end

local function OnMailClosed()
    isMailboxOpen = false
    QueueReset(pendingTakes)
    ns.DebugPrint("MailListener: mailbox closed, pending state cleared")
end

local function OnMailSuccess()
    local snapshot = QueuePop(pendingTakes)
    ProcessSnapshot(snapshot)
end

local function OnMailFailed()
    -- Discard the oldest pending snapshot
    QueuePop(pendingTakes)
    ns.DebugPrint("MailListener: mail operation failed, discarded pending snapshot")
end

-------------------------------------------------------------------------------
-- Public Interface
-------------------------------------------------------------------------------

function ns.MailListener.Initialize(addon)
    -- Install hooks (once, cannot be undone)
    hooksecurefunc("TakeInboxItem", OnTakeInboxItem)
    hooksecurefunc("TakeInboxMoney", OnTakeInboxMoney)
    hooksecurefunc("AutoLootMailItem", OnAutoLootMailItem)

    -- Register events
    addon:RegisterEvent("MAIL_SHOW", function() OnMailShow() end)
    addon:RegisterEvent("MAIL_CLOSED", function() OnMailClosed() end)
    addon:RegisterEvent("MAIL_SUCCESS", function() OnMailSuccess() end)
    addon:RegisterEvent("MAIL_FAILED", function() OnMailFailed() end)

    ns.DebugPrint("Retail Mail Listener initialized")
end

function ns.MailListener.Shutdown()
    ns.Addon:UnregisterEvent("MAIL_SHOW")
    ns.Addon:UnregisterEvent("MAIL_CLOSED")
    ns.Addon:UnregisterEvent("MAIL_SUCCESS")
    ns.Addon:UnregisterEvent("MAIL_FAILED")

    isMailboxOpen = false
    QueueReset(pendingTakes)

    ns.DebugPrint("Retail Mail Listener shut down")
end
