-------------------------------------------------------------------------------
-- LootListener_Shared.lua
-- Shared loot listener implementation with version wrapper factories
--
-- Supported versions: TBC Anniversary, Retail, MoP Classic
-------------------------------------------------------------------------------

local _, ns = ...

local Utils = ns.ListenerUtils

-------------------------------------------------------------------------------
-- Cached WoW API
-------------------------------------------------------------------------------

local GetItemInfo = GetItemInfo
local GetTime = GetTime
local UnitName = UnitName
local C_ChatInfo = C_ChatInfo
local error = error
local geterrorhandler = geterrorhandler
local ipairs = ipairs
local pcall = pcall
local select = select
local tonumber = tonumber
local tostring = tostring
local type = type

-------------------------------------------------------------------------------
-- Chat message sanity guard
--
-- Retail occasionally emits CHAT_MSG_LOOT / CHAT_MSG_MONEY payloads as
-- Blizzard "secret" (censored) strings. Any index / match operation on them
-- raises a tainted-string error. Guard handlers with a string type check and
-- a C_ChatInfo.IsChatLineCensored probe before touching the message. The
-- C_ChatInfo namespace does not exist on TBC / MoP Classic, so nil-check it.
-------------------------------------------------------------------------------

local function IsIndexableChatMessage(msg, lineID)
    if type(msg) ~= "string" then return false end
    if C_ChatInfo and C_ChatInfo.IsChatLineCensored and lineID
        and C_ChatInfo.IsChatLineCensored(lineID) then
        return false
    end
    return true
end

local PLAYER_UNIT = "player"

local owner

-------------------------------------------------------------------------------
-- Default money patterns (shared across all version wrappers)
-------------------------------------------------------------------------------

local DEFAULT_MONEY_PATTERNS = {
    {
        name = "splitGuild",
        pattern = {
            globalString = LOOT_MONEY_SPLIT_GUILD,
            fallbackString = "Your share of the loot is %s. (%s deposited to guild bank)",
        },
        amountIndex = 1,
        isSelf = true,
    },
    {
        name = "selfGuild",
        pattern = {
            globalString = YOU_LOOT_MONEY_GUILD,
            fallbackString = "You loot %s (%s deposited to guild bank)",
        },
        amountIndex = 1,
        isSelf = true,
    },
    {
        name = "splitModifier",
        pattern = {
            globalString = LOOT_MONEY_SPLIT_MOD,
            fallbackString = "Your share of the loot is %s (+%s)",
        },
        amountIndex = 1,
        isSelf = true,
    },
    {
        name = "selfModifier",
        pattern = {
            globalString = YOU_LOOT_MONEY_MOD,
            fallbackString = "You loot %s (+%s)",
        },
        amountIndex = 1,
        isSelf = true,
    },
    {
        name = "self",
        pattern = { globalString = YOU_LOOT_MONEY, fallbackString = "You loot %s" },
        amountIndex = 1,
        isSelf = true,
    },
    {
        name = "split",
        pattern = { globalString = LOOT_MONEY_SPLIT, fallbackString = "Your share of the loot is %s." },
        amountIndex = 1,
        isSelf = true,
    },
    {
        name = "refund",
        pattern = { globalString = LOOT_MONEY_REFUND, fallbackString = "You are refunded %s." },
        amountIndex = 1,
        isSelf = true,
    },
    {
        name = "other",
        pattern = { globalString = LOOT_MONEY, fallbackString = "%s loots %s." },
        amountIndex = 2,
        looterIndex = 1,
        isSelf = false,
    },
}

-------------------------------------------------------------------------------
-- Pattern builders
-------------------------------------------------------------------------------

local function BuildConfiguredPattern(patternConfig, context)
    if type(patternConfig) ~= "table" then
        error("LootListener_Shared.Create - " .. context .. " must be a table", 3)
    end

    if type(patternConfig.fallbackString) ~= "string" or patternConfig.fallbackString == "" then
        error("LootListener_Shared.Create - " .. context .. ".fallbackString must be a non-empty string", 3)
    end

    return Utils.BuildPattern(patternConfig.globalString or patternConfig.fallbackString)
end

local function BuildPatternPair(pairConfig, context)
    if type(pairConfig) ~= "table" then
        error("LootListener_Shared.Create - " .. context .. " must be a table", 3)
    end

    return {
        single = BuildConfiguredPattern(pairConfig.single, context .. ".single"),
        multi = BuildConfiguredPattern(pairConfig.multi, context .. ".multi"),
    }
end

local function BuildLootCategories(lootCategories)
    if type(lootCategories) ~= "table" then
        error("LootListener_Shared.Create - config.lootCategories must be a table", 2)
    end

    local builtCategories = {}

    for index, categoryConfig in ipairs(lootCategories) do
        local context = "config.lootCategories[" .. index .. "]"
        if type(categoryConfig) ~= "table" then
            error("LootListener_Shared.Create - " .. context .. " must be a table", 2)
        end

        builtCategories[index] = {
            name = categoryConfig.name,
            self = BuildPatternPair(categoryConfig.self, context .. ".self"),
            other = categoryConfig.other and BuildPatternPair(categoryConfig.other, context .. ".other") or nil,
        }
    end

    return builtCategories
end

local function BuildMoneyPatterns(moneyPatterns)
    if type(moneyPatterns) ~= "table" then
        error("LootListener_Shared.Create - config.moneyPatterns must be a table", 2)
    end

    local builtPatterns = {}

    for index, moneyPatternConfig in ipairs(moneyPatterns) do
        local context = "config.moneyPatterns[" .. index .. "]"
        if type(moneyPatternConfig) ~= "table" then
            error("LootListener_Shared.Create - " .. context .. " must be a table", 2)
        end

        if type(moneyPatternConfig.amountIndex) ~= "number" then
            error("LootListener_Shared.Create - " .. context .. ".amountIndex must be a number", 2)
        end

        builtPatterns[index] = {
            name = moneyPatternConfig.name,
            pattern = BuildConfiguredPattern(moneyPatternConfig.pattern, context .. ".pattern"),
            amountIndex = moneyPatternConfig.amountIndex,
            looterIndex = moneyPatternConfig.looterIndex,
            isSelf = moneyPatternConfig.isSelf == true,
        }
    end

    return builtPatterns
end

-------------------------------------------------------------------------------
-- Toast data builders
-------------------------------------------------------------------------------

local function BuildLootData(itemLink, quantity, looter, isSelf)
    local itemName, _, itemQuality, itemLevel, _, itemType, itemSubType,
        _, _, itemTexture = GetItemInfo(itemLink)

    if not itemName then return nil end

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
-- Filtering
-------------------------------------------------------------------------------

local function PassesFilter(lootData)
    local db = owner.db.profile
    if not db.enabled then return false end

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
-- Message parsing helpers
-------------------------------------------------------------------------------

local function TrySelfPair(msg, patternPair)
    local itemLink, quantity = msg:match(patternPair.multi)
    if itemLink then
        return itemLink, tonumber(quantity) or 1
    end

    itemLink = msg:match(patternPair.single)
    if itemLink then
        return itemLink, 1
    end

    return nil, nil
end

local function TryOtherPair(msg, patternPair)
    local looter, itemLink, quantity = msg:match(patternPair.multi)
    if itemLink then
        return looter, itemLink, tonumber(quantity) or 1
    end

    looter, itemLink = msg:match(patternPair.single)
    if itemLink then
        return looter, itemLink, 1
    end

    return nil, nil, nil
end

local function ParseLootMessage(msg, lootCategories, playerName)
    for _, category in ipairs(lootCategories) do
        local itemLink, quantity = TrySelfPair(msg, category.self)
        if itemLink then
            return itemLink, quantity, playerName, true
        end
    end

    for _, category in ipairs(lootCategories) do
        if category.other then
            local looter, itemLink, quantity = TryOtherPair(msg, category.other)
            if itemLink then
                return itemLink, quantity, looter, false
            end
        end
    end

    return nil, nil, nil, nil
end

local function ParseMoneyMessage(msg, moneyPatterns, playerName)
    for _, moneyPattern in ipairs(moneyPatterns) do
        local captures = { msg:match(moneyPattern.pattern) }
        local amount = captures[moneyPattern.amountIndex]

        if amount then
            if moneyPattern.isSelf then
                return amount, playerName, true
            end

            local looter = captures[moneyPattern.looterIndex]
            if looter then
                return amount, looter, false
            end
        end
    end

    return nil, nil, nil
end

local function QueueMoneyToast(amount, looter, isSelf)
    local copperAmount = Utils.ParseMoneyString(amount) or 0
    local lootData = BuildMoneyData(amount, copperAmount, looter, isSelf)

    if PassesFilter(lootData) then
        ns.ToastManager.QueueToast(lootData)
    end
end

-------------------------------------------------------------------------------
-- Factory
-------------------------------------------------------------------------------

function ns.LootListenerShared.Create(config)
    if type(config) ~= "table" then
        error("LootListener_Shared.Create - config must be a table", 2)
    end

    if type(config.versionName) ~= "string" or config.versionName == "" then
        error("LootListener_Shared.Create - config.versionName must be a non-empty string", 2)
    end

    local lootCategories = BuildLootCategories(config.lootCategories)
    local moneyPatterns = BuildMoneyPatterns(config.moneyPatterns or DEFAULT_MONEY_PATTERNS)
    local listener = {}

    local function OnChatMsgLoot(_, msg, ...)
        -- CHAT_MSG_* payload position 11 is lineID; with (_, msg) consuming
        -- event+text, lineID is the 10th element of the remaining varargs.
        local lineID = select(10, ...)
        -- Skip non-string or censored (tainted) payloads to avoid retail secret-string errors.
        if not IsIndexableChatMessage(msg, lineID) then return end

        local playerName = UnitName(PLAYER_UNIT) or UNKNOWN
        -- Parse under pcall; a tainted string can still slip through if Blizzard changes the
        -- censoring contract, and a parser error must not break the event dispatcher.
        local ok, itemLink, quantity, looter, isSelf = pcall(ParseLootMessage, msg, lootCategories, playerName)
        if not ok then
            geterrorhandler()("DragonToast: ParseLootMessage failed: " .. tostring(itemLink))
            return
        end
        if not itemLink then return end

        Utils.WaitForItem(
            owner,
            itemLink,
            function() return BuildLootData(itemLink, quantity, looter or UNKNOWN, isSelf) end,
            PassesFilter
        )
    end

    local function OnChatMsgMoney(_, msg, ...)
        -- CHAT_MSG_* payload position 11 is lineID; with (_, msg) consuming
        -- event+text, lineID is the 10th element of the remaining varargs.
        local lineID = select(10, ...)
        -- Skip non-string or censored (tainted) payloads to avoid retail secret-string errors.
        if not IsIndexableChatMessage(msg, lineID) then return end

        local db = owner.db.profile
        if not db.enabled or not db.filters.showGold then return end

        local playerName = UnitName(PLAYER_UNIT) or UNKNOWN
        -- Defensive pcall: same tainted-string safety net as the loot handler.
        local ok, amount, looter, isSelf = pcall(ParseMoneyMessage, msg, moneyPatterns, playerName)
        if not ok then
            geterrorhandler()("DragonToast: ParseMoneyMessage failed: " .. tostring(amount))
            return
        end
        if not amount then return end

        QueueMoneyToast(amount, looter, isSelf)
    end

    function listener.Initialize(addon)
        owner = addon
        addon:RegisterEvent("CHAT_MSG_LOOT", OnChatMsgLoot)
        addon:RegisterEvent("CHAT_MSG_MONEY", OnChatMsgMoney)
        ns.DebugPrint(config.versionName .. " Loot Listener initialized")
    end

    function listener.Shutdown()
        owner:UnregisterEvent("CHAT_MSG_LOOT")
        owner:UnregisterEvent("CHAT_MSG_MONEY")
        ns.DebugPrint(config.versionName .. " Loot Listener shut down")
    end

    return listener
end
