-------------------------------------------------------------------------------
-- ListenerUtils.lua
-- Shared utility functions and constants used across listener modules
--
-- Supported versions: TBC Anniversary, Retail, MoP Classic
-------------------------------------------------------------------------------

local _, ns = ...
local Utils = ns.ListenerUtils

-- Cache Lua globals
local tostring = tostring
local tonumber = tonumber
local type = type
local math_floor = math.floor
local string_format = string.format
local table_concat = table.concat
local table_insert = table.insert
local ipairs = ipairs
local next = next

-- Cache WoW API
local C_ChatInfo = C_ChatInfo

-- Pending item lookups: itemID (number) -> { buildFunc, filterFunc }
-- Multiple entries can share the same itemID (e.g. two loots of the same item in quick succession)
-- Use an array of entries per itemID to handle that correctly.
local pendingItems = {}
local itemEventRegistered = false
local registeredAddon = nil

local COPPER_PER_SILVER = 100
local COPPER_PER_GOLD = 10000
local GOLD_SUFFIX = "g"
local SILVER_SUFFIX = "s"
local COPPER_SUFFIX = "c"
local ZERO_COPPER_TEXT = "0c"

local function BuildLocalizedPattern(globalString, anchor)
    if not globalString then return nil, nil end

    local pattern = tostring(globalString)
    local captureOrder = {}
    local literalPercentToken = "\1LITERAL_PERCENT\2"
    local stringToken = "\1STRING_CAPTURE\2"
    local numberToken = "\1NUMBER_CAPTURE\2"

    pattern = pattern:gsub("%%%%", literalPercentToken)
    pattern = pattern:gsub("%%(%d+)%$([sd])", function(index, placeholderType)
        captureOrder[#captureOrder + 1] = tonumber(index)
        if placeholderType == "s" then
            return stringToken
        end
        return numberToken
    end)
    pattern = pattern:gsub("%%([sd])", function(placeholderType)
        captureOrder[#captureOrder + 1] = #captureOrder + 1
        if placeholderType == "s" then
            return stringToken
        end
        return numberToken
    end)

    pattern = pattern:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
    pattern = pattern:gsub(stringToken, "(.+)")
    pattern = pattern:gsub(numberToken, "(%%d+)")
    pattern = pattern:gsub(literalPercentToken, "%%%%")

    if anchor then
        pattern = "^" .. pattern .. "$"
    end

    return pattern, captureOrder
end

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

Utils.GOLD_ICON = 133784
Utils.QUESTION_MARK_ICON = 134400
Utils.MAX_RETRIES = 5
Utils.RETRY_INTERVAL = 0.2

-------------------------------------------------------------------------------
-- BuildPattern(globalString, anchor)
-- Converts a WoW GlobalString (with %s/%d placeholders) into a Lua pattern.
-- When anchor is true, wraps in ^ and $ and returns nil for nil input.
-------------------------------------------------------------------------------

function Utils.BuildPattern(globalString, anchor)
    local pattern = BuildLocalizedPattern(globalString, anchor)
    return pattern
end

-------------------------------------------------------------------------------
-- BuildCapturePattern(globalString, anchor)
-- Like BuildPattern, but also returns placeholder order for localized positional
-- format strings such as %2$s.
-------------------------------------------------------------------------------

function Utils.BuildCapturePattern(globalString, anchor)
    return BuildLocalizedPattern(globalString, anchor)
end

-------------------------------------------------------------------------------
-- ParseMoneyString(moneyString)
-- Parses a localized money string into total copper value.
-- Tries text-based patterns first, then texture-based fallbacks.
-------------------------------------------------------------------------------

local PATTERN_GOLD = Utils.BuildPattern(GOLD_AMOUNT)
local PATTERN_SILVER = Utils.BuildPattern(SILVER_AMOUNT)
local PATTERN_COPPER = Utils.BuildPattern(COPPER_AMOUNT)
local PATTERN_GOLD_TEXTURE = Utils.BuildPattern(GOLD_AMOUNT_TEXTURE)
local PATTERN_SILVER_TEXTURE = Utils.BuildPattern(SILVER_AMOUNT_TEXTURE)
local PATTERN_COPPER_TEXTURE = Utils.BuildPattern(COPPER_AMOUNT_TEXTURE)

function Utils.ParseMoneyString(moneyString)
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

    local total = gold * COPPER_PER_GOLD + silver * COPPER_PER_SILVER + copper
    return total > 0 and total or nil
end

-------------------------------------------------------------------------------
-- FormatGold(copper)
-- Formats a copper amount into a display string with gold/silver/copper parts.
-------------------------------------------------------------------------------

function Utils.FormatGold(copper)
    local gold = math_floor(copper / COPPER_PER_GOLD)
    local silver = math_floor((copper % COPPER_PER_GOLD) / COPPER_PER_SILVER)
    local copperRemainder = copper % COPPER_PER_SILVER
    local parts = {}
    if gold > 0 then parts[#parts + 1] = gold .. GOLD_SUFFIX end
    if silver > 0 then parts[#parts + 1] = silver .. SILVER_SUFFIX end
    if copperRemainder > 0 then parts[#parts + 1] = copperRemainder .. COPPER_SUFFIX end
    if #parts == 0 then parts[#parts + 1] = ZERO_COPPER_TEXT end
    return string_format("|T%d:0:0:0:0|t%s", Utils.GOLD_ICON, table_concat(parts, " "))
end

-------------------------------------------------------------------------------
-- IsIndexableChatMessage(msg, lineID)
--
-- Retail occasionally emits CHAT_MSG_* payloads as Blizzard "secret"
-- (censored) strings. Any index / match operation on them raises a
-- tainted-string error. Callers guard handlers with a string type check
-- and a C_ChatInfo.IsChatLineCensored probe before touching the message.
-- The C_ChatInfo namespace does not exist on TBC / MoP Classic, so it is
-- nil-checked here.
-------------------------------------------------------------------------------

function Utils.IsIndexableChatMessage(msg, lineID)
    if type(msg) ~= "string" then return false end
    if C_ChatInfo and C_ChatInfo.IsChatLineCensored and lineID
        and C_ChatInfo.IsChatLineCensored(lineID) then
        return false
    end
    return true
end

-------------------------------------------------------------------------------
-- RetryWithTimer(addon, buildFunc, filterFunc, retries)
-- Retries a build function up to MAX_RETRIES times at RETRY_INTERVAL seconds.
-- If buildFunc() returns data and filterFunc(data) passes, queues the toast.
-------------------------------------------------------------------------------

function Utils.RetryWithTimer(addon, buildFunc, filterFunc, retries)
    retries = retries or 0
    if retries >= Utils.MAX_RETRIES then
        ns.DebugPrint("Max retries reached, giving up")
        return
    end
    local data = buildFunc()
    if data then
        if filterFunc(data) then
            ns.ToastManager.QueueToast(data)
        end
    else
        addon:ScheduleTimer(function()
            Utils.RetryWithTimer(addon, buildFunc, filterFunc, retries + 1)
        end, Utils.RETRY_INTERVAL)
    end
end

-------------------------------------------------------------------------------
-- WaitForItem(addon, itemLink, buildFunc, filterFunc)
-- Waits for GetItemInfo to be available for itemLink, then builds and queues
-- a toast. Uses GET_ITEM_INFO_RECEIVED instead of polling to avoid up-to-1s
-- lag on uncached items.
-------------------------------------------------------------------------------

function Utils.WaitForItem(addon, itemLink, buildFunc, filterFunc)
    local data = buildFunc()
    if data then
        if filterFunc(data) then
            ns.ToastManager.QueueToast(data)
        end
        return
    end

    -- Item not cached yet - extract itemID and register for the event
    local itemID = tonumber(itemLink:match("item:(%d+)"))
    if not itemID then return end

    if not pendingItems[itemID] then
        pendingItems[itemID] = {}
    end
    table_insert(pendingItems[itemID], { buildFunc = buildFunc, filterFunc = filterFunc })

    if not itemEventRegistered then
        itemEventRegistered = true
        registeredAddon = addon
        addon:RegisterEvent("GET_ITEM_INFO_RECEIVED", function(_, id, success)
            local entries = pendingItems[id]
            if not entries then return end

            pendingItems[id] = nil

            if success ~= true then
                -- Item data unavailable - silently drop
                ns.DebugPrint("WaitForItem: item " .. tostring(id) .. " data unavailable (success=" ..
                    tostring(success) .. ")")
            else
                for _, entry in ipairs(entries) do
                    local builtData = entry.buildFunc()
                    if builtData and entry.filterFunc(builtData) then
                        ns.ToastManager.QueueToast(builtData)
                    end
                end
            end

            -- Unregister when no more pending items
            if not next(pendingItems) then
                itemEventRegistered = false
                registeredAddon:UnregisterEvent("GET_ITEM_INFO_RECEIVED")
                registeredAddon = nil
            end
        end)
    end
end
