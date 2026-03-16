-------------------------------------------------------------------------------
-- TestToasts.lua
-- Test toast generation for /dt test, /dt testmode, and /dt stacktest
--
-- Supported versions: TBC Anniversary, Retail, MoP Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

-------------------------------------------------------------------------------
-- Cached WoW API
-------------------------------------------------------------------------------

local GetTime = GetTime
local UnitName = UnitName
local string_format = string.format
local math_random = math.random

local L = ns.L

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local TEST_MODE_INTERVAL = 1.5
local STACK_TEST_SECOND_DELAY = 0.3
local STACK_TEST_THIRD_DELAY = 0.6
local STACK_TEST_XP_DELAY = 2.0
local STACK_TEST_GOLD_DELAY = 4.0
local STACK_TEST_HONOR_DELAY = 6.0
local STACK_TEST_REPUTATION_DELAY = 8.0
local PLAYER_LINK_LEVEL = 70

-------------------------------------------------------------------------------
-- State
-------------------------------------------------------------------------------

local testCounter = 0
local testModeTimer = nil

-------------------------------------------------------------------------------
-- Module table
-------------------------------------------------------------------------------

ns.TestToasts = ns.TestToasts or {}

-------------------------------------------------------------------------------
-- Test Data Builders
-------------------------------------------------------------------------------

local function GetTestPlayerName()
    return UnitName("player") or "TestPlayer"
end

local function CreateTestLootData(fields)
    local lootData = {
        quantity = 1,
        looter = GetTestPlayerName(),
        isSelf = true,
        isCurrency = false,
        timestamp = GetTime(),
    }

    for key, value in pairs(fields) do
        lootData[key] = value
    end

    return lootData
end

local function CreateProgressionTestLootData(flagField, amountField, amount, label, icon, detailField, detailValue)
    local lootData = CreateTestLootData({
        itemIcon = icon,
        itemName = string_format(label, ns.FormatNumber(amount)),
        itemQuality = 1,
        itemLevel = 0,
    })

    lootData[flagField] = true
    lootData[amountField] = amount

    if detailField then
        lootData[detailField] = detailValue
    end

    return lootData
end

local function CreateMoneyTestLootData(copperAmount, quality, itemLevel, itemType, itemSubType, itemIcon)
    return CreateTestLootData({
        itemLink = nil,
        itemID = nil,
        copperAmount = copperAmount,
        itemName = GetCoinTextureString(copperAmount),
        itemQuality = quality,
        itemLevel = itemLevel,
        itemType = itemType,
        itemSubType = itemSubType,
        itemIcon = itemIcon,
        isCurrency = true,
    })
end

local function CreateItemTestLootData(test, quantity)
    return CreateTestLootData({
        itemLink = "|cff" .. (test.quality == 5 and "ff8000" or "a335ee") .. "|Hitem:" .. test.id
            .. "::::::::" .. PLAYER_LINK_LEVEL .. "::::::|h[" .. test.name .. "]|h|r" .. testCounter,
        itemID = test.id,
        itemName = test.name,
        itemQuality = test.quality,
        itemLevel = test.level,
        itemType = test.type,
        itemSubType = test.subType,
        itemIcon = test.icon,
        quantity = quantity,
    })
end

-------------------------------------------------------------------------------
-- Show Test Toast
-------------------------------------------------------------------------------

local HONOR_ICON_FALLBACK = 136986
local REPUTATION_ICON_FALLBACK = 136814

local testItems

local function GetHonorIcon()
    if ns.HonorListener and ns.HonorListener.GetHonorIcon then
        return ns.HonorListener.GetHonorIcon()
    end
    return HONOR_ICON_FALLBACK
end

local function GetReputationIcon()
    if ns.ReputationListener and ns.ReputationListener.GetReputationIcon then
        return ns.ReputationListener.GetReputationIcon()
    end
    return REPUTATION_ICON_FALLBACK
end

local function GetTestItems()
    if testItems then return testItems end

    testItems = {
        { name = "Warglaive of Azzinoth", quality = 5, level = 156, type = "Weapon", subType = "Sword",
          icon = 135562, id = 32837 },
        { name = "Bulwark of Azzinoth", quality = 4, level = 154, type = "Armor", subType = "Shield",
          icon = 132351, id = 32375 },
        { name = "Tier 6 Helm Token", quality = 4, level = 154, type = "Miscellaneous", subType = "Junk",
          icon = 134240, id = 31097 },
        { name = "Nethervoid Cloak", quality = 4, level = 141, type = "Armor", subType = "Cloth",
          icon = 133772, id = 32331 },
        { name = "Pattern: Sunfire Robe", quality = 4, level = 75, type = "Recipe", subType = "Tailoring",
          icon = 132744, id = 32754 },
        { name = "Gold Loot", quality = 1, level = 0, type = "Currency", subType = "Gold",
          icon = 133784, id = 99998, isMoney = true, copperAmount = 12345 },
        { name = "+1,234 XP", quality = 1, level = 0, type = nil, subType = nil,
          icon = 894556, id = 99999, isXP = true, xpAmount = 1234 },
        { name = "+150 Honor", quality = 1, level = 0, type = nil, subType = nil,
          icon = GetHonorIcon(), id = 99997, isHonor = true, honorAmount = 150,
          victimName = "Enemy Player" },
        { name = "+250 Reputation", quality = 1, level = 0, type = nil, subType = nil,
          icon = GetReputationIcon(), id = 99996, isReputation = true,
          reputationAmount = 250, factionName = "The Sha'tar" },
    }
    return testItems
end

-- Builds a concrete loot data table from a test descriptor for use in test toasts.
-- @param test Table describing the test scenario. Expected fields include
--   boolean flags `isXP`, `isHonor`, `isReputation`, `isMoney` to indicate
--   the kind of loot, plus corresponding fields:
--   - `xpAmount`, `honorAmount`, `reputationAmount` (numeric amounts for progression types)
--   - `copperAmount` (numeric copper for money)
--   - `icon`, `quality`, `level`, `type`, `subType` (item/currency metadata)
--   - `victimName`, `factionName` (optional detail strings for honor/reputation)
--   - other item fields used when producing an item entry
-- @return A loot data table representing an item, currency, XP, honor,
--   or reputation gain suitable for displaying as a test toast.
local function BuildTestLootData(test)
    if test.isXP then
        local amount = test.xpAmount + math_random(0, 500)
        local lootData = CreateProgressionTestLootData(
            "isXP", "xpAmount", amount, L["FORMAT_PLUS_XP"],
            test.icon, "mobName",
            (math_random(2) == 1) and "Test Creature" or nil
        )
        lootData.itemQuality = test.quality
        return lootData
    elseif test.isHonor then
        local amount = test.honorAmount + math_random(0, 100)
        local lootData = CreateProgressionTestLootData(
            "isHonor", "honorAmount", amount, L["FORMAT_PLUS_HONOR"],
            test.icon, "victimName", test.victimName
        )
        lootData.itemQuality = test.quality
        return lootData
    elseif test.isReputation then
        local amount = test.reputationAmount + math_random(0, 200)
        local lootData = CreateProgressionTestLootData(
            "isReputation", "reputationAmount", amount, L["FORMAT_PLUS_REPUTATION"],
            test.icon, "factionName", test.factionName
        )
        lootData.itemQuality = test.quality
        return lootData
    elseif test.isMoney then
        return CreateMoneyTestLootData(
            test.copperAmount, test.quality, test.level,
            test.type, test.subType, test.icon
        )
    else
        return CreateItemTestLootData(test, math_random(1, 3))
    end
end

function ns.TestToasts.ShowTestToast()
    testCounter = testCounter + 1
    local items = GetTestItems()
    local test = items[math_random(#items)]
    ns.ToastManager.ShowToast(BuildTestLootData(test))
end

-------------------------------------------------------------------------------
-- Test Mode (continuous toast generation)
-------------------------------------------------------------------------------

function ns.TestToasts.IsTestModeActive()
    return testModeTimer ~= nil
end

function ns.TestToasts.StartTestMode()
    if testModeTimer then return end -- already running

    -- Fire one immediately
    ns.TestToasts.ShowTestToast()

    -- Schedule repeating timer
    testModeTimer = ns.Addon:ScheduleRepeatingTimer(function()
        ns.TestToasts.ShowTestToast()
    end, TEST_MODE_INTERVAL)

    ns.Print("Test mode " .. ns.COLOR_GREEN .. "started" .. ns.COLOR_RESET .. " - toasts will keep appearing.")
end

function ns.TestToasts.StopTestMode()
    if not testModeTimer then return end

    ns.Addon:CancelTimer(testModeTimer)
    testModeTimer = nil

    ns.Print("Test mode " .. ns.COLOR_RED .. "stopped" .. ns.COLOR_RESET)
end

function ns.TestToasts.ToggleTestMode()
    if testModeTimer then
        ns.TestToasts.StopTestMode()
    else
        ns.TestToasts.StartTestMode()
    end
end

-------------------------------------------------------------------------------
-- Stack Test Commands (in-game verification)
-- Create a prepared item loot data table for stack tests using the
-- Warglaive of Azzinoth.
-- @return A loot data table containing populated item fields (itemLink,
--   itemID, itemName, itemQuality, itemLevel, itemType, itemSubType,
--   itemIcon) suitable for dispatching a stack test toast.

local function MakeStackTestItemData()
    return CreateTestLootData({
        itemLink = "|cffa335ee|Hitem:32837::::::::70::::::|h[Warglaive of Azzinoth]|h|r",
        itemID = 32837,
        itemName = "Warglaive of Azzinoth",
        itemQuality = 5,
        itemLevel = 156,
        itemType = "Weapon",
        itemSubType = "Sword",
        itemIcon = 135562,
    })
end

-- Create a progression loot data object representing an XP gain for stack testing.
-- The returned table has `isXP = true`, `xpAmount = 500`, uses the `L["FORMAT_PLUS_XP"]` label, and icon `894556`.
-- @return Loot data table for a 500 XP progression toast.
local function MakeStackTestXPData()
    return CreateProgressionTestLootData("isXP", "xpAmount", 500, L["FORMAT_PLUS_XP"], 894556)
end

-- Creates a money loot data object representing a gold payout used for stacking tests.
-- @return A loot data table for a gold currency event with 50,000 copper,
--   quality 1, item type "Currency", item subType "Gold", and icon 133784.
local function MakeStackTestGoldData()
    return CreateMoneyTestLootData(50000, 1, 0, "Currency", "Gold", 133784)
end

-- Creates a test loot data object representing an honor gain from an enemy player.
-- @return A loot data table with `isHonor = true`, `honorAmount = 100`,
--   `victimName = "Enemy Player"`, a localized label
--   (L["FORMAT_PLUS_HONOR"]), the honor icon, and standard base loot
--   fields (quantity, looter, isSelf, isCurrency, timestamp).
local function MakeStackTestHonorData()
    return CreateProgressionTestLootData(
        "isHonor", "honorAmount", 100, L["FORMAT_PLUS_HONOR"],
        GetHonorIcon(), "victimName", "Enemy Player"
    )
end

-- Creates a reputation progression loot data object used by stack-test commands.
-- The returned table is configured for a reputation gain: `isReputation = true`, `reputationAmount = 250`,
-- `label` set from `L["FORMAT_PLUS_REPUTATION"]`, `icon` from `GetReputationIcon()`, and `factionName = "The Sha'tar"`.
-- @return A loot data table representing a 250-point reputation gain for "The Sha'tar".
local function MakeStackTestReputationData()
    return CreateProgressionTestLootData(
        "isReputation", "reputationAmount", 250, L["FORMAT_PLUS_REPUTATION"],
        GetReputationIcon(), "factionName", "The Sha'tar"
    )
end

local function FireStackToast(lootData, delay)
    local ShowToast = ns.ToastManager.ShowToast
    if delay and delay > 0 then
        ns.Addon:ScheduleTimer(function() ShowToast(lootData) end, delay)
    else
        ShowToast(lootData)
    end
end

local function RunStackGroup(label, makeFunc)
    ns.Print("[Stack Test] Testing " .. ns.COLOR_WHITE .. label .. ns.COLOR_RESET .. " stacking...")
    FireStackToast(makeFunc(), 0)
    FireStackToast(makeFunc(), STACK_TEST_SECOND_DELAY)
    FireStackToast(makeFunc(), STACK_TEST_THIRD_DELAY)
end

local STACK_TEST_DISPATCH = {
    item  = { label = "item",       make = MakeStackTestItemData },
    stack = { label = "item",       make = MakeStackTestItemData },
    xp    = { label = "XP",         make = MakeStackTestXPData },
    gold  = { label = "gold",       make = MakeStackTestGoldData },
    honor = { label = "honor",      make = MakeStackTestHonorData },
    rep   = { label = "reputation", make = MakeStackTestReputationData },
    reputation = { label = "reputation", make = MakeStackTestReputationData },
}

local STACK_TEST_ALL_GROUPS = {
    { label = "item",       make = MakeStackTestItemData,       delay = 0 },
    { label = "XP",         make = MakeStackTestXPData,         delay = STACK_TEST_XP_DELAY },
    { label = "gold",       make = MakeStackTestGoldData,       delay = STACK_TEST_GOLD_DELAY },
    { label = "honor",      make = MakeStackTestHonorData,      delay = STACK_TEST_HONOR_DELAY },
    { label = "reputation", make = MakeStackTestReputationData, delay = STACK_TEST_REPUTATION_DELAY },
}

function ns.TestToasts.RunStackTest(testType)
    if testType == "all" then
        for _, group in ipairs(STACK_TEST_ALL_GROUPS) do
            if group.delay > 0 then
                ns.Addon:ScheduleTimer(function() RunStackGroup(group.label, group.make) end, group.delay)
            else
                RunStackGroup(group.label, group.make)
            end
        end
        return
    end

    local entry = STACK_TEST_DISPATCH[testType]
    if not entry then
        ns.Print("Unknown test type: " .. ns.COLOR_WHITE .. (testType or "nil") .. ns.COLOR_RESET)
        ns.Print("Usage: /dt test [stack|xp|gold|honor|reputation|all]")
        return
    end

    RunStackGroup(entry.label, entry.make)
end
