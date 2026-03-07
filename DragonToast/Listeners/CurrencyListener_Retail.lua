-------------------------------------------------------------------------------
-- CurrencyListener_Retail.lua
-- Currency gain toast notifications with proper icon lookup
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

local C_CurrencyInfo_GetCurrencyInfo = C_CurrencyInfo.GetCurrencyInfo
local GetTime = GetTime
local UnitName = UnitName

-------------------------------------------------------------------------------
-- Namespace
-------------------------------------------------------------------------------

local CurrencyListener = ns.CurrencyListener

-------------------------------------------------------------------------------
-- Currency message pattern building
-------------------------------------------------------------------------------

local PATTERN_CURRENCY_SELF = Utils.BuildPattern(CURRENCY_GAINED or "You receive currency: %s.")
local PATTERN_CURRENCY_SELF_MULTI = Utils.BuildPattern(
    CURRENCY_GAINED_MULTIPLE or "You receive currency: %s x%d."
)

-------------------------------------------------------------------------------
-- Build currency data
-------------------------------------------------------------------------------

local function BuildCurrencyData(currencyName, currencyID, quantity, looter, isSelf)
    local icon = Utils.QUESTION_MARK_ICON

    if currencyID then
        local info = C_CurrencyInfo_GetCurrencyInfo(currencyID)
        if info and info.iconFileID then
            icon = info.iconFileID
        end
    end

    return {
        itemName = currencyName,
        itemIcon = icon,
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

-------------------------------------------------------------------------------
-- Filter Check
-------------------------------------------------------------------------------

local function PassesFilter(lootData)
    local db = ns.Addon.db.profile
    if not db.enabled then return false end
    if not db.filters.showCurrency then return false end

    if lootData.isSelf and not db.filters.showSelfLoot then return false end
    if not lootData.isSelf and not db.filters.showGroupLoot then return false end

    return true
end

-------------------------------------------------------------------------------
-- Event Handler
-------------------------------------------------------------------------------

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

    if not currencyLink then return end

    local currencyID = tonumber(currencyLink:match("currency:(%d+)"))
    local currencyName = currencyLink:match("%[(.+)%]") or currencyLink
    local lootData = BuildCurrencyData(currencyName, currencyID, quantity, UnitName("player"), true)

    if PassesFilter(lootData) then
        ns.ToastManager.QueueToast(lootData)
    end
end

-------------------------------------------------------------------------------
-- Public Interface
-------------------------------------------------------------------------------

function CurrencyListener.Initialize(addon)
    addon:RegisterEvent("CHAT_MSG_CURRENCY", OnChatMsgCurrency)
    ns.DebugPrint("CurrencyListener initialized")
end

function CurrencyListener.Shutdown()
    ns.Addon:UnregisterEvent("CHAT_MSG_CURRENCY")
    ns.DebugPrint("CurrencyListener shutdown")
end
