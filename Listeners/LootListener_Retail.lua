-------------------------------------------------------------------------------
-- LootListener_Retail.lua
-- Retail loot event parsing (also used by MoP Classic)
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

local GetItemInfo = GetItemInfo
local GetTime = GetTime
local UnitName = UnitName

-------------------------------------------------------------------------------
-- Loot message pattern building
-------------------------------------------------------------------------------

local PATTERN_LOOT_SELF = Utils.BuildPattern(LOOT_ITEM_SELF or "You receive loot: %s.")
local PATTERN_LOOT_SELF_MULTI = Utils.BuildPattern(LOOT_ITEM_SELF_MULTIPLE or "You receive loot: %s x%d.")
local PATTERN_LOOT_OTHER = Utils.BuildPattern(LOOT_ITEM or "%s receives loot: %s.")
local PATTERN_LOOT_OTHER_MULTI = Utils.BuildPattern(LOOT_ITEM_MULTIPLE or "%s receives loot: %s x%d.")
local PATTERN_MONEY_SELF = Utils.BuildPattern(YOU_LOOT_MONEY or "You loot %s")
local PATTERN_MONEY_OTHER = Utils.BuildPattern(LOOT_MONEY or "%s loots %s")
local PATTERN_CURRENCY_SELF = Utils.BuildPattern(CURRENCY_GAINED or "You receive currency: %s.")
local PATTERN_CURRENCY_SELF_MULTI = Utils.BuildPattern(CURRENCY_GAINED_MULTIPLE or "You receive currency: %s x%d.")

-------------------------------------------------------------------------------
-- Build loot data (Retail: 18-return GetItemInfo)
-------------------------------------------------------------------------------

local function BuildLootData(itemLink, quantity, looter, isSelf)
    local itemName, _, itemQuality, itemLevel, _, itemType, itemSubType,
        _, _, itemTexture = GetItemInfo(itemLink) -- remaining returns ignored

    if not itemName then
        return nil
    end

    local itemID = tonumber(itemLink:match("item:(%d+)"))

    return {
        itemLink = itemLink,
        itemID = itemID,
        itemName = itemName,
        itemQuality = itemQuality or 1,
        itemLevel = itemLevel or 0,
        itemType = itemType or UNKNOWN,
        itemSubType = itemSubType or "",
        itemIcon = itemTexture or Utils.QUESTION_MARK_ICON,
        quantity = quantity,
        looter = looter,
        isSelf = isSelf,
        isCurrency = false,
        timestamp = GetTime(),
    }
end

local function BuildMoneyData(amount, copperAmount, looter, isSelf)
    return {
        itemLink = nil,
        itemID = nil,
        itemName = amount,
        itemQuality = 1,
        itemLevel = 0,
        itemType = "Currency",
        itemSubType = "Gold",
        itemIcon = Utils.GOLD_ICON,
        quantity = 1,
        copperAmount = copperAmount,
        looter = looter,
        isSelf = isSelf,
        isCurrency = true,
        timestamp = GetTime(),
    }
end

local function BuildCurrencyData(currencyName, quantity, looter, isSelf)
    return {
        itemLink = nil,
        itemID = nil,
        itemName = currencyName,
        itemQuality = 1,
        itemLevel = 0,
        itemType = "Currency",
        itemSubType = "Currency",
        itemIcon = Utils.QUESTION_MARK_ICON,
        quantity = quantity or 1,
        looter = looter,
        isSelf = isSelf,
        isCurrency = true,
        timestamp = GetTime(),
    }
end

-------------------------------------------------------------------------------
-- Filter Check
-------------------------------------------------------------------------------

local function PassesFilter(lootData)
    local db = ns.Addon.db.profile
    if not db.enabled then return false end

    -- Quest item filter
    if lootData.itemType == "Quest" and not db.filters.showQuestItems then
        return false
    end

    if not lootData.isCurrency and lootData.itemQuality < db.filters.minQuality then
        return false
    end

    if lootData.isSelf and not db.filters.showSelfLoot then return false end
    if not lootData.isSelf and not db.filters.showGroupLoot then return false end

    if lootData.isCurrency and not db.filters.showCurrency then return false end

    return true
end

-------------------------------------------------------------------------------
-- Event Handlers
-------------------------------------------------------------------------------

local function OnChatMsgLoot(_, msg)
    local itemLink, quantity, looter, isSelf

    -- Self-loot with quantity
    itemLink, quantity = msg:match(PATTERN_LOOT_SELF_MULTI)
    if itemLink then
        quantity = tonumber(quantity) or 1
        isSelf = true
        looter = UnitName("player")
    -- Self-loot
    elseif msg:match(PATTERN_LOOT_SELF) then
        itemLink = msg:match(PATTERN_LOOT_SELF)
        quantity = 1
        isSelf = true
        looter = UnitName("player")
    else
        -- Other-loot with quantity
        looter, itemLink, quantity = msg:match(PATTERN_LOOT_OTHER_MULTI)
        if itemLink then
            quantity = tonumber(quantity) or 1
            isSelf = false
        else
            -- Other-loot
            looter, itemLink = msg:match(PATTERN_LOOT_OTHER)
            if itemLink then
                quantity = 1
                isSelf = false
            end
        end
    end

    if itemLink then
        Utils.RetryWithTimer(
            ns.Addon,
            function() return BuildLootData(itemLink, quantity, looter or UNKNOWN, isSelf) end,
            PassesFilter
        )
    end
end

local function OnChatMsgMoney(_, msg)
    local db = ns.Addon.db.profile
    if not db.enabled or not db.filters.showGold then return end

    local playerName = UnitName("player")
    local amount

    amount = msg:match(PATTERN_MONEY_SELF)
    if amount then
        local copperAmount = Utils.ParseMoneyString(amount)
        local lootData = BuildMoneyData(amount, copperAmount, playerName, true)
        if PassesFilter(lootData) then
            ns.ToastManager.QueueToast(lootData)
        end
        return
    end

    local looter
    looter, amount = msg:match(PATTERN_MONEY_OTHER)
    if amount and looter then
        local copperAmount = Utils.ParseMoneyString(amount)
        local lootData = BuildMoneyData(amount, copperAmount, looter, false)
        if PassesFilter(lootData) then
            ns.ToastManager.QueueToast(lootData)
        end
    end
end

local function OnChatMsgCurrency(_, msg)
    local db = ns.Addon.db.profile
    if not db.enabled or not db.filters.showCurrency then return end

    local currencyLink, quantity

    -- Try multi first (more specific)
    currencyLink, quantity = msg:match(PATTERN_CURRENCY_SELF_MULTI)
    if currencyLink then
        quantity = tonumber(quantity) or 1
    end

    -- Try single
    if not currencyLink then
        currencyLink = msg:match(PATTERN_CURRENCY_SELF)
        if currencyLink then
            quantity = 1
        end
    end

    if currencyLink then
        local currencyName = currencyLink:match("%[(.+)%]") or currencyLink
        local lootData = BuildCurrencyData(currencyName, quantity, UnitName("player"), true)
        if PassesFilter(lootData) then
            ns.ToastManager.QueueToast(lootData)
        end
    end
end

-------------------------------------------------------------------------------
-- Public Interface
-------------------------------------------------------------------------------

function ns.LootListener.Initialize(addon)
    addon:RegisterEvent("CHAT_MSG_LOOT", OnChatMsgLoot)
    addon:RegisterEvent("CHAT_MSG_MONEY", OnChatMsgMoney)
    addon:RegisterEvent("CHAT_MSG_CURRENCY", OnChatMsgCurrency)
    ns.DebugPrint("Retail Loot Listener initialized")
end

function ns.LootListener.Shutdown()
    ns.Addon:UnregisterEvent("CHAT_MSG_LOOT")
    ns.Addon:UnregisterEvent("CHAT_MSG_MONEY")
    ns.Addon:UnregisterEvent("CHAT_MSG_CURRENCY")
    ns.DebugPrint("Retail Loot Listener shut down")
end
