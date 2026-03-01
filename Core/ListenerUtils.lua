-------------------------------------------------------------------------------
-- ListenerUtils.lua
-- Shared utility functions and constants used across listener modules
--
-- Supported versions: TBC Anniversary, Retail, MoP Classic
-------------------------------------------------------------------------------

local _, ns = ...
local Utils = ns.ListenerUtils

-- Cache Lua globals
local tonumber = tonumber
local math_floor = math.floor
local string_format = string.format
local table_concat = table.concat

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
    if anchor and not globalString then return nil end
    local pattern = globalString:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
    pattern = pattern:gsub("%%%%s", "(.+)")
    pattern = pattern:gsub("%%%%d", "(%%d+)")
    if anchor then
        return "^" .. pattern .. "$"
    end
    return pattern
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

    local total = gold * 10000 + silver * 100 + copper
    return total > 0 and total or nil
end

-------------------------------------------------------------------------------
-- FormatGold(copper)
-- Formats a copper amount into a display string with gold/silver/copper parts.
-------------------------------------------------------------------------------

function Utils.FormatGold(copper)
    local gold = math_floor(copper / 10000)
    local silver = math_floor((copper % 10000) / 100)
    local copperRemainder = copper % 100
    local parts = {}
    if gold > 0 then parts[#parts + 1] = gold .. "g" end
    if silver > 0 then parts[#parts + 1] = silver .. "s" end
    if copperRemainder > 0 then parts[#parts + 1] = copperRemainder .. "c" end
    if #parts == 0 then parts[#parts + 1] = "0c" end
    return string_format("|T%d:0:0:0:0|t%s", Utils.GOLD_ICON, table_concat(parts, " "))
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
