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

function ns.TestToasts.ShowTestToast()
    testCounter = testCounter + 1

    local items = GetTestItems()
    local test = items[math_random(#items)]

    local lootData
    if test.isXP then
        local amount = test.xpAmount + math_random(0, 500)
        lootData = CreateProgressionTestLootData(
            "isXP",
            "xpAmount",
            amount,
            L["+%s XP"],
            test.icon,
            "mobName",
            (math_random(2) == 1) and "Test Creature" or nil
        )
        lootData.itemQuality = test.quality
    elseif test.isHonor then
        local amount = test.honorAmount + math_random(0, 100)
        lootData = CreateProgressionTestLootData(
            "isHonor",
            "honorAmount",
            amount,
            L["+%s Honor"],
            test.icon,
            "victimName",
            test.victimName
        )
        lootData.itemQuality = test.quality
    elseif test.isReputation then
        local amount = test.reputationAmount + math_random(0, 200)
        lootData = CreateProgressionTestLootData(
            "isReputation",
            "reputationAmount",
            amount,
            L["+%s Reputation"],
            test.icon,
            "factionName",
            test.factionName
        )
        lootData.itemQuality = test.quality
    elseif test.isMoney then
        lootData = CreateMoneyTestLootData(
            test.copperAmount,
            test.quality,
            test.level,
            test.type,
            test.subType,
            test.icon
        )
    else
        lootData = CreateItemTestLootData(test, math_random(1, 3))
    end

    ns.ToastManager.ShowToast(lootData)
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

    ns.Print("Test mode " .. ns.COLOR_GREEN .. "started" .. ns.COLOR_RESET .. " — toasts will keep appearing.")
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
-------------------------------------------------------------------------------

function ns.TestToasts.RunStackTest(testType)
    local addon = ns.Addon
    local ShowToast = ns.ToastManager.ShowToast

    local function FireToast(lootData, delay)
        if delay and delay > 0 then
            addon:ScheduleTimer(function() ShowToast(lootData) end, delay)
        else
            ShowToast(lootData)
        end
    end

    local function MakeItemData()
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

    local function MakeXPData()
        return CreateProgressionTestLootData("isXP", "xpAmount", 500, L["+%s XP"], 894556)
    end

    local function MakeGoldData()
        return CreateMoneyTestLootData(50000, 1, 0, "Currency", "Gold", 133784)
    end

    local function MakeHonorData()
        return CreateProgressionTestLootData(
            "isHonor",
            "honorAmount",
            100,
            L["+%s Honor"],
            GetHonorIcon(),
            "victimName",
            "Enemy Player"
        )
    end

    local function MakeReputationData()
        return CreateProgressionTestLootData(
            "isReputation",
            "reputationAmount",
            250,
            L["+%s Reputation"],
            GetReputationIcon(),
            "factionName",
            "The Sha'tar"
        )
    end

    local function RunGroup(label, makeFunc)
        ns.Print("[Stack Test] Testing " .. ns.COLOR_WHITE .. label .. ns.COLOR_RESET .. " stacking...")
        FireToast(makeFunc(), 0)
        FireToast(makeFunc(), STACK_TEST_SECOND_DELAY)
        FireToast(makeFunc(), STACK_TEST_THIRD_DELAY)
    end

    if testType == "item" or testType == "stack" then
        RunGroup("item", MakeItemData)
    elseif testType == "xp" then
        RunGroup("XP", MakeXPData)
    elseif testType == "gold" then
        RunGroup("gold", MakeGoldData)
    elseif testType == "honor" then
        RunGroup("honor", MakeHonorData)
    elseif testType == "reputation" or testType == "rep" then
        RunGroup("reputation", MakeReputationData)
    elseif testType == "all" then
        RunGroup("item", MakeItemData)
        addon:ScheduleTimer(function() RunGroup("XP", MakeXPData) end, STACK_TEST_XP_DELAY)
        addon:ScheduleTimer(function() RunGroup("gold", MakeGoldData) end, STACK_TEST_GOLD_DELAY)
        addon:ScheduleTimer(function() RunGroup("honor", MakeHonorData) end, STACK_TEST_HONOR_DELAY)
        addon:ScheduleTimer(function() RunGroup("reputation", MakeReputationData) end, STACK_TEST_REPUTATION_DELAY)
    else
        ns.Print("Unknown test type: " .. ns.COLOR_WHITE .. (testType or "nil") .. ns.COLOR_RESET)
        ns.Print("Usage: /dt test [stack|xp|gold|honor|reputation|all]")
        return
    end
end
