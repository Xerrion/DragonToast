-------------------------------------------------------------------------------
-- CurrencyListener_Shared.lua
-- Shared currency listener implementation with version wrapper factories
--
-- Supported versions: Retail, MoP Classic
-------------------------------------------------------------------------------

local _, ns = ...
local Utils = ns.ListenerUtils

-------------------------------------------------------------------------------
-- Cached WoW API
-------------------------------------------------------------------------------

local C_CurrencyInfo = C_CurrencyInfo
local GetTime = GetTime
local UnitName = UnitName
local tonumber = tonumber

local PLAYER_UNIT = "player"

-------------------------------------------------------------------------------
-- Pattern Building
-------------------------------------------------------------------------------

local function BuildPatterns()
    return {
        selfSingle = Utils.BuildPattern(CURRENCY_GAINED or "You receive currency: %s."),
        selfMultiple = Utils.BuildPattern(CURRENCY_GAINED_MULTIPLE or "You receive currency: %s x%d."),
    }
end

-------------------------------------------------------------------------------
-- Currency Helpers
-------------------------------------------------------------------------------

local function GetCurrencyIcon(currencyID)
    if not currencyID then
        return Utils.QUESTION_MARK_ICON
    end

    if not C_CurrencyInfo or not C_CurrencyInfo.GetCurrencyInfo then
        return Utils.QUESTION_MARK_ICON
    end

    local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
    if not info or not info.iconFileID then
        return Utils.QUESTION_MARK_ICON
    end

    return info.iconFileID
end

local function BuildCurrencyData(currencyName, currencyID, quantity, looter, isSelf)
    return {
        itemName = currencyName,
        itemIcon = GetCurrencyIcon(currencyID),
        itemQuality = 1,
        quantity = quantity or 1,
        isSelf = isSelf,
        looter = looter,
        isCurrency = true,
        currencyID = currencyID,
        itemType = "Currency",
        itemSubType = "Currency",
        timestamp = GetTime(),
    }
end

local function PassesFilter(lootData)
    local db = ns.Addon.db.profile
    if not db.enabled then return false end
    if not db.filters.showCurrency then return false end

    if lootData.isSelf and not db.filters.showSelfLoot then return false end
    if not lootData.isSelf and not db.filters.showGroupLoot then return false end

    return true
end

local function ParseCurrencyMessage(patterns, message)
    local currencyLink, quantity = message:match(patterns.selfMultiple)
    if currencyLink then
        return currencyLink, tonumber(quantity) or 1
    end

    currencyLink = message:match(patterns.selfSingle)
    if currencyLink then
        return currencyLink, 1
    end

    return nil, nil
end

-------------------------------------------------------------------------------
-- Factory
-------------------------------------------------------------------------------

function ns.CreateCurrencyListenerModule(_)
    local patterns = BuildPatterns()

    local function OnChatMsgCurrency(_, message)
        local db = ns.Addon.db.profile
        if not db.enabled or not db.filters.showCurrency then return end

        local currencyLink, quantity = ParseCurrencyMessage(patterns, message)
        if not currencyLink then return end

        local currencyID = tonumber(currencyLink:match("currency:(%d+)"))
        local currencyName = currencyLink:match("%[(.+)%]") or currencyLink
        local lootData = BuildCurrencyData(currencyName, currencyID, quantity, UnitName(PLAYER_UNIT), true)

        if PassesFilter(lootData) then
            ns.ToastManager.QueueToast(lootData)
        end
    end

    return {
        Initialize = function(addon)
            addon:RegisterEvent("CHAT_MSG_CURRENCY", OnChatMsgCurrency)
            ns.DebugPrint("CurrencyListener initialized")
        end,
        Shutdown = function()
            ns.Addon:UnregisterEvent("CHAT_MSG_CURRENCY")
            ns.DebugPrint("CurrencyListener shutdown")
        end,
    }
end
