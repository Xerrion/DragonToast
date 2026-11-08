-------------------------------------------------------------------------------
-- LootListener_Retail.lua
-- Retail and WoW: Forever loot event parsing
--
-- Supported versions: Retail, WoW: Forever
-------------------------------------------------------------------------------

local _, ns = ...

-------------------------------------------------------------------------------
-- Version guard: only run on Retail or WoW: Forever
-------------------------------------------------------------------------------

local WOW_PROJECT_ID = WOW_PROJECT_ID
local WOW_PROJECT_MAINLINE = WOW_PROJECT_MAINLINE
local WOW_PROJECT_CAMELOT = WOW_PROJECT_CAMELOT

if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE
    and (WOW_PROJECT_CAMELOT == nil or WOW_PROJECT_ID ~= WOW_PROJECT_CAMELOT) then
    return
end

-------------------------------------------------------------------------------
-- Shared implementation
-------------------------------------------------------------------------------

if not ns.LootListenerShared or not ns.LootListenerShared.Create then return end

-- Retail-style _SELF fallback strings omit trailing periods.
ns.LootListener = ns.LootListenerShared.Create({
    versionName = "Retail",
    lootCategories = {
        {
            name = "loot",
            self = {
                single = { globalString = LOOT_ITEM_SELF, fallbackString = "You receive loot: %s" },
                multi = { globalString = LOOT_ITEM_SELF_MULTIPLE, fallbackString = "You receive loot: %sx%d" },
            },
            other = {
                single = { globalString = LOOT_ITEM, fallbackString = "%s receives loot: %s." },
                multi = { globalString = LOOT_ITEM_MULTIPLE, fallbackString = "%s receives loot: %s x%d." },
            },
        },
        {
            name = "pushed",
            self = {
                single = { globalString = LOOT_ITEM_PUSHED_SELF, fallbackString = "You receive item: %s" },
                multi = {
                    globalString = LOOT_ITEM_PUSHED_SELF_MULTIPLE,
                    fallbackString = "You receive item: %sx%d",
                },
            },
            other = {
                single = { globalString = LOOT_ITEM_PUSHED, fallbackString = "%s receives item: %s." },
                multi = {
                    globalString = LOOT_ITEM_PUSHED_MULTIPLE,
                    fallbackString = "%s receives item: %sx%d.",
                },
            },
        },
        {
            name = "bonusRoll",
            self = {
                single = {
                    globalString = LOOT_ITEM_BONUS_ROLL_SELF,
                    fallbackString = "You receive bonus loot: %s",
                },
                multi = {
                    globalString = LOOT_ITEM_BONUS_ROLL_SELF_MULTIPLE,
                    fallbackString = "You receive bonus loot: %sx%d",
                },
            },
            other = {
                single = {
                    globalString = LOOT_ITEM_BONUS_ROLL,
                    fallbackString = "%s receives bonus loot: %s.",
                },
                multi = {
                    globalString = LOOT_ITEM_BONUS_ROLL_MULTIPLE,
                    fallbackString = "%s receives bonus loot: %sx%d.",
                },
            },
        },
        {
            name = "created",
            self = {
                single = { globalString = LOOT_ITEM_CREATED_SELF, fallbackString = "You create: %s." },
                multi = { globalString = LOOT_ITEM_CREATED_SELF_MULTIPLE, fallbackString = "You create: %sx%d." },
            },
        },
        {
            name = "refund",
            self = {
                single = { globalString = LOOT_ITEM_REFUND, fallbackString = "You are refunded: %s." },
                multi = { globalString = LOOT_ITEM_REFUND_MULTIPLE, fallbackString = "You are refunded: %sx%d." },
            },
        },
    },
})
