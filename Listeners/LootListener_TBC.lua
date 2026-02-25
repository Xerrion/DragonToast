-------------------------------------------------------------------------------
-- LootListener_TBC.lua
-- TBC Anniversary loot event parsing
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
-- Cached WoW API
-------------------------------------------------------------------------------

local GetItemInfo = GetItemInfo
local GetTime = GetTime
local UnitName = UnitName

-------------------------------------------------------------------------------
-- Loot message pattern building
-------------------------------------------------------------------------------

-- Build patterns from Blizzard's localized format strings
-- LOOT_ITEM_SELF = "You receive loot: %s."
-- LOOT_ITEM_SELF_MULTIPLE = "You receive loot: %s x%d."
-- LOOT_ITEM = "%s receives loot: %s."
-- LOOT_ITEM_MULTIPLE = "%s receives loot: %s x%d."

local function BuildPattern(globalString)
    -- First, escape all Lua pattern special characters
    local pattern = globalString:gsub("([%.%+%-%*%?%[%]%^%$%(%)%%])", "%%%1")
    -- Now our %s and %d have been escaped to %%s and %%d
    -- Replace them with capture groups
    pattern = pattern:gsub("%%%%s", "(.+)")
    pattern = pattern:gsub("%%%%d", "(%%d+)")
    return pattern
end

local PATTERN_LOOT_SELF = BuildPattern(LOOT_ITEM_SELF or "You receive loot: %s.")
local PATTERN_LOOT_SELF_MULTI = BuildPattern(LOOT_ITEM_SELF_MULTIPLE or "You receive loot: %s x%d.")
local PATTERN_LOOT_OTHER = BuildPattern(LOOT_ITEM or "%s receives loot: %s.")
local PATTERN_LOOT_OTHER_MULTI = BuildPattern(LOOT_ITEM_MULTIPLE or "%s receives loot: %s x%d.")

-- Money patterns
local PATTERN_MONEY_SELF = BuildPattern(YOU_LOOT_MONEY or "You loot %s")
local PATTERN_MONEY_OTHER = BuildPattern(LOOT_MONEY or "%s loots %s")

-- Money amount patterns (text and texture variants)
local PATTERN_GOLD = BuildPattern(GOLD_AMOUNT)
local PATTERN_SILVER = BuildPattern(SILVER_AMOUNT)
local PATTERN_COPPER = BuildPattern(COPPER_AMOUNT)
local PATTERN_GOLD_TEXTURE = BuildPattern(GOLD_AMOUNT_TEXTURE)
local PATTERN_SILVER_TEXTURE = BuildPattern(SILVER_AMOUNT_TEXTURE)
local PATTERN_COPPER_TEXTURE = BuildPattern(COPPER_AMOUNT_TEXTURE)

local function ParseMoneyString(moneyString)
    local gold, silver, copper = 0, 0, 0

    -- Try text-based patterns first
    local g = moneyString:match(PATTERN_GOLD)
    if g then gold = tonumber(g) or 0 end

    local s = moneyString:match(PATTERN_SILVER)
    if s then silver = tonumber(s) or 0 end

    local c = moneyString:match(PATTERN_COPPER)
    if c then copper = tonumber(c) or 0 end

    -- Fall back to texture-based patterns if text patterns found nothing
    if gold == 0 and silver == 0 and copper == 0 then
        g = moneyString:match(PATTERN_GOLD_TEXTURE)
        if g then gold = tonumber(g) or 0 end

        s = moneyString:match(PATTERN_SILVER_TEXTURE)
        if s then silver = tonumber(s) or 0 end

        c = moneyString:match(PATTERN_COPPER_TEXTURE)
        if c then copper = tonumber(c) or 0 end
    end

    local total = gold * 10000 + silver * 100 + copper
    return total > 0 and total or nil
end

local MAX_RETRIES = 5

-------------------------------------------------------------------------------
-- Parse and Build LootData
-------------------------------------------------------------------------------

local function BuildLootData(itemLink, quantity, looter, isSelf)
    local itemName, _, itemQuality, itemLevel, _, itemType, itemSubType,
        _, _, itemTexture = GetItemInfo(itemLink)

    if not itemName then
        return nil -- item not cached yet
    end

    -- Extract itemID from link
    local itemID = tonumber(itemLink:match("item:(%d+)"))

    return {
        itemLink = itemLink,
        itemID = itemID,
        itemName = itemName,
        itemQuality = itemQuality or 1,
        itemLevel = itemLevel or 0,
        itemType = itemType or UNKNOWN,
        itemSubType = itemSubType or "",
        itemIcon = itemTexture or 134400, -- question mark icon fallback
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
        itemQuality = 1, -- Common (gold color)
        itemLevel = 0,
        itemType = "Currency",
        itemSubType = "Gold",
        itemIcon = 133784, -- gold coin icon
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

    -- Quality filter
    if not lootData.isCurrency and lootData.itemQuality < db.filters.minQuality then
        return false
    end

    -- Self/group filter
    if lootData.isSelf and not db.filters.showSelfLoot then return false end
    if not lootData.isSelf and not db.filters.showGroupLoot then return false end

    -- Currency filter
    if lootData.isCurrency and not db.filters.showCurrency then return false end

    return true
end

-------------------------------------------------------------------------------
-- Item Info Retry
-------------------------------------------------------------------------------

local function RetryBuildLootData(itemLink, quantity, looter, isSelf, retries)
    retries = retries or 0
    if retries >= MAX_RETRIES then
        ns.DebugPrint("Failed to get item info for: " .. itemLink .. " after " .. MAX_RETRIES .. " retries")
        return
    end

    local lootData = BuildLootData(itemLink, quantity, looter, isSelf)
    if lootData then
        if PassesFilter(lootData) then
            ns.ToastManager.QueueToast(lootData)
        end
    else
        -- Item not cached, retry after a short delay
        ns.Addon:ScheduleTimer(function()
            RetryBuildLootData(itemLink, quantity, looter, isSelf, retries + 1)
        end, 0.2)
    end
end

-------------------------------------------------------------------------------
-- Event Handlers
-------------------------------------------------------------------------------

local function OnChatMsgLoot(_, msg)
    local itemLink, quantity, looter, isSelf

    -- Try self-loot with quantity first (more specific)
    itemLink, quantity = msg:match(PATTERN_LOOT_SELF_MULTI)
    if itemLink then
        quantity = tonumber(quantity) or 1
        isSelf = true
        looter = UnitName("player")
    -- Try self-loot without quantity
    elseif msg:match(PATTERN_LOOT_SELF) then
        itemLink = msg:match(PATTERN_LOOT_SELF)
        quantity = 1
        isSelf = true
        looter = UnitName("player")
    else
        -- Try other-loot with quantity
        looter, itemLink, quantity = msg:match(PATTERN_LOOT_OTHER_MULTI)
        if itemLink then
            quantity = tonumber(quantity) or 1
            isSelf = false
        else
            -- Try other-loot without quantity
            looter, itemLink = msg:match(PATTERN_LOOT_OTHER)
            if itemLink then
                quantity = 1
                isSelf = false
            end
        end
    end

    -- If we found an item link, process it
    if itemLink then
        RetryBuildLootData(itemLink, quantity, looter or UNKNOWN, isSelf)
    end
end

local function OnChatMsgMoney(_, msg)
    local db = ns.Addon.db.profile
    if not db.enabled or not db.filters.showGold then return end

    local playerName = UnitName("player")
    local amount

    -- Self money loot
    amount = msg:match(PATTERN_MONEY_SELF)
    if amount then
        local copperAmount = ParseMoneyString(amount)
        local lootData = BuildMoneyData(amount, copperAmount, playerName, true)
        if PassesFilter(lootData) then
            ns.ToastManager.QueueToast(lootData)
        end
        return
    end

    -- Other money loot
    local looter
    looter, amount = msg:match(PATTERN_MONEY_OTHER)
    if amount and looter then
        local copperAmount = ParseMoneyString(amount)
        local lootData = BuildMoneyData(amount, copperAmount, looter, false)
        if PassesFilter(lootData) then
            ns.ToastManager.QueueToast(lootData)
        end
    end
end

-------------------------------------------------------------------------------
-- Public Interface (populated on ns.LootListener)
-------------------------------------------------------------------------------

function ns.LootListener.Initialize(addon)
    addon:RegisterEvent("CHAT_MSG_LOOT", OnChatMsgLoot)
    addon:RegisterEvent("CHAT_MSG_MONEY", OnChatMsgMoney)
    ns.DebugPrint("TBC Loot Listener initialized")
end

function ns.LootListener.Shutdown()
    ns.Addon:UnregisterEvent("CHAT_MSG_LOOT")
    ns.Addon:UnregisterEvent("CHAT_MSG_MONEY")
    ns.DebugPrint("TBC Loot Listener shut down")
end
