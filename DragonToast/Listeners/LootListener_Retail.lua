-------------------------------------------------------------------------------
-- LootListener_Retail.lua
-- Retail loot event parsing
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

local Utils = ns.ListenerUtils

-------------------------------------------------------------------------------
-- Cached WoW API
-------------------------------------------------------------------------------

local GetItemInfo = GetItemInfo
local GetTime = GetTime
local UnitName = UnitName

-------------------------------------------------------------------------------
-- Loot message pattern building
-- NOTE: Retail _SELF variants have NO trailing period. Other variants DO.
-------------------------------------------------------------------------------

-- Standard loot patterns
local PATTERN_LOOT_SELF = Utils.BuildPattern(LOOT_ITEM_SELF or "You receive loot: %s")
local PATTERN_LOOT_SELF_MULTI = Utils.BuildPattern(LOOT_ITEM_SELF_MULTIPLE or "You receive loot: %sx%d")
local PATTERN_LOOT_OTHER = Utils.BuildPattern(LOOT_ITEM or "%s receives loot: %s.")
local PATTERN_LOOT_OTHER_MULTI = Utils.BuildPattern(LOOT_ITEM_MULTIPLE or "%s receives loot: %s x%d.")

-- Pushed item patterns (quest rewards, auto-loot BoP, items sent to bags)
local PATTERN_PUSHED_SELF = Utils.BuildPattern(LOOT_ITEM_PUSHED_SELF or "You receive item: %s")
local PATTERN_PUSHED_SELF_MULTI = Utils.BuildPattern(
    LOOT_ITEM_PUSHED_SELF_MULTIPLE or "You receive item: %sx%d"
)
local PATTERN_PUSHED_OTHER = Utils.BuildPattern(LOOT_ITEM_PUSHED or "%s receives item: %s.")
local PATTERN_PUSHED_OTHER_MULTI = Utils.BuildPattern(
    LOOT_ITEM_PUSHED_MULTIPLE or "%s receives item: %sx%d."
)

-- Bonus roll patterns
local PATTERN_BONUS_SELF = Utils.BuildPattern(LOOT_ITEM_BONUS_ROLL_SELF or "You receive bonus loot: %s")
local PATTERN_BONUS_SELF_MULTI = Utils.BuildPattern(
    LOOT_ITEM_BONUS_ROLL_SELF_MULTIPLE or "You receive bonus loot: %sx%d"
)
local PATTERN_BONUS_OTHER = Utils.BuildPattern(LOOT_ITEM_BONUS_ROLL or "%s receives bonus loot: %s.")
local PATTERN_BONUS_OTHER_MULTI = Utils.BuildPattern(
    LOOT_ITEM_BONUS_ROLL_MULTIPLE or "%s receives bonus loot: %sx%d."
)

-- Created item patterns (crafting, conjuring)
local PATTERN_CREATED_SELF = Utils.BuildPattern(LOOT_ITEM_CREATED_SELF or "You create: %s.")
local PATTERN_CREATED_SELF_MULTI = Utils.BuildPattern(
    LOOT_ITEM_CREATED_SELF_MULTIPLE or "You create: %sx%d."
)

-- Item refund patterns
local PATTERN_ITEM_REFUND_SELF = Utils.BuildPattern(LOOT_ITEM_REFUND or "You are refunded: %s.")
local PATTERN_ITEM_REFUND_SELF_MULTI = Utils.BuildPattern(
    LOOT_ITEM_REFUND_MULTIPLE or "You are refunded: %sx%d."
)

-- Money patterns
local PATTERN_MONEY_SELF = Utils.BuildPattern(YOU_LOOT_MONEY or "You loot %s")
local PATTERN_MONEY_OTHER = Utils.BuildPattern(LOOT_MONEY or "%s loots %s.")
local PATTERN_MONEY_SPLIT = Utils.BuildPattern(LOOT_MONEY_SPLIT or "Your share of the loot is %s.")
local PATTERN_MONEY_SPLIT_GUILD = Utils.BuildPattern(
    LOOT_MONEY_SPLIT_GUILD or "Your share of the loot is %s. (%s deposited to guild bank)"
)
local PATTERN_MONEY_SELF_GUILD = Utils.BuildPattern(
    YOU_LOOT_MONEY_GUILD or "You loot %s (%s deposited to guild bank)"
)
local PATTERN_MONEY_SELF_MOD = Utils.BuildPattern(YOU_LOOT_MONEY_MOD or "You loot %s (+%s)")
local PATTERN_MONEY_SPLIT_MOD = Utils.BuildPattern(
    LOOT_MONEY_SPLIT_MOD or "Your share of the loot is %s (+%s)"
)
local PATTERN_MONEY_REFUND = Utils.BuildPattern(LOOT_MONEY_REFUND or "You are refunded %s.")

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

    return true
end

-------------------------------------------------------------------------------
-- Event Handlers
-------------------------------------------------------------------------------

local function OnChatMsgLoot(_, msg)
    local itemLink, quantity, looter, isSelf

    -- Helper: try a self-loot pattern pair (multi first, then single)
    local function TrySelfPair(patMulti, patSingle)
        local link, qty = msg:match(patMulti)
        if link then
            return link, tonumber(qty) or 1
        end
        link = msg:match(patSingle)
        if link then
            return link, 1
        end
        return nil, nil
    end

    -- Helper: try an other-loot pattern pair (multi first, then single)
    local function TryOtherPair(patMulti, patSingle)
        local who, link, qty = msg:match(patMulti)
        if link then
            return who, link, tonumber(qty) or 1
        end
        who, link = msg:match(patSingle)
        if link then
            return who, link, 1
        end
        return nil, nil, nil
    end

    -- Self-loot patterns (most specific first)
    itemLink, quantity = TrySelfPair(PATTERN_LOOT_SELF_MULTI, PATTERN_LOOT_SELF)
    if not itemLink then
        itemLink, quantity = TrySelfPair(PATTERN_PUSHED_SELF_MULTI, PATTERN_PUSHED_SELF)
    end
    if not itemLink then
        itemLink, quantity = TrySelfPair(PATTERN_BONUS_SELF_MULTI, PATTERN_BONUS_SELF)
    end
    if not itemLink then
        itemLink, quantity = TrySelfPair(PATTERN_CREATED_SELF_MULTI, PATTERN_CREATED_SELF)
    end
    if not itemLink then
        itemLink, quantity = TrySelfPair(PATTERN_ITEM_REFUND_SELF_MULTI, PATTERN_ITEM_REFUND_SELF)
    end

    if itemLink then
        isSelf = true
        looter = UnitName("player")
    else
        -- Other-loot patterns
        looter, itemLink, quantity = TryOtherPair(PATTERN_LOOT_OTHER_MULTI, PATTERN_LOOT_OTHER)
        if not itemLink then
            looter, itemLink, quantity = TryOtherPair(
                PATTERN_PUSHED_OTHER_MULTI, PATTERN_PUSHED_OTHER
            )
        end
        if not itemLink then
            looter, itemLink, quantity = TryOtherPair(
                PATTERN_BONUS_OTHER_MULTI, PATTERN_BONUS_OTHER
            )
        end
        if itemLink then
            isSelf = false
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

    -- Guild split: "Your share of the loot is %s. (%s deposited to guild bank)"
    local splitAmount, _guildAmount = msg:match(PATTERN_MONEY_SPLIT_GUILD)
    if splitAmount then
        local copperAmount = Utils.ParseMoneyString(splitAmount) or 0
        local lootData = BuildMoneyData(splitAmount, copperAmount, playerName, true)
        if PassesFilter(lootData) then
            ns.ToastManager.QueueToast(lootData)
        end
        return
    end

    -- Solo guild: "You loot %s (%s deposited to guild bank)"
    local selfAmount, _selfGuildAmount = msg:match(PATTERN_MONEY_SELF_GUILD)
    if selfAmount then
        local copperAmount = Utils.ParseMoneyString(selfAmount) or 0
        local lootData = BuildMoneyData(selfAmount, copperAmount, playerName, true)
        if PassesFilter(lootData) then
            ns.ToastManager.QueueToast(lootData)
        end
        return
    end

    -- Split with modifier: "Your share of the loot is %s (+%s)"
    local splitModAmount, _splitBonus = msg:match(PATTERN_MONEY_SPLIT_MOD)
    if splitModAmount then
        local copperAmount = Utils.ParseMoneyString(splitModAmount) or 0
        local lootData = BuildMoneyData(splitModAmount, copperAmount, playerName, true)
        if PassesFilter(lootData) then
            ns.ToastManager.QueueToast(lootData)
        end
        return
    end

    -- Self with modifier: "You loot %s (+%s)"
    local selfModAmount, _selfBonus = msg:match(PATTERN_MONEY_SELF_MOD)
    if selfModAmount then
        local copperAmount = Utils.ParseMoneyString(selfModAmount) or 0
        local lootData = BuildMoneyData(selfModAmount, copperAmount, playerName, true)
        if PassesFilter(lootData) then
            ns.ToastManager.QueueToast(lootData)
        end
        return
    end

    -- Self money loot: "You loot %s"
    amount = msg:match(PATTERN_MONEY_SELF)
    if amount then
        local copperAmount = Utils.ParseMoneyString(amount) or 0
        local lootData = BuildMoneyData(amount, copperAmount, playerName, true)
        if PassesFilter(lootData) then
            ns.ToastManager.QueueToast(lootData)
        end
        return
    end

    -- Group split: "Your share of the loot is %s."
    amount = msg:match(PATTERN_MONEY_SPLIT)
    if amount then
        local copperAmount = Utils.ParseMoneyString(amount) or 0
        local lootData = BuildMoneyData(amount, copperAmount, playerName, true)
        if PassesFilter(lootData) then
            ns.ToastManager.QueueToast(lootData)
        end
        return
    end

    -- Money refund: "You are refunded %s."
    amount = msg:match(PATTERN_MONEY_REFUND)
    if amount then
        local copperAmount = Utils.ParseMoneyString(amount) or 0
        local lootData = BuildMoneyData(amount, copperAmount, playerName, true)
        if PassesFilter(lootData) then
            ns.ToastManager.QueueToast(lootData)
        end
        return
    end

    -- Other money loot: "%s loots %s."
    local looter
    looter, amount = msg:match(PATTERN_MONEY_OTHER)
    if amount and looter then
        local copperAmount = Utils.ParseMoneyString(amount) or 0
        local lootData = BuildMoneyData(amount, copperAmount, looter, false)
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
    ns.DebugPrint("Retail Loot Listener initialized")
end

function ns.LootListener.Shutdown()
    ns.Addon:UnregisterEvent("CHAT_MSG_LOOT")
    ns.Addon:UnregisterEvent("CHAT_MSG_MONEY")
    ns.DebugPrint("Retail Loot Listener shut down")
end
