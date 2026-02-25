-------------------------------------------------------------------------------
-- DragonLootBridge.lua
-- Cross-addon messaging bridge for DragonLoot integration
--
-- Supported versions: TBC Anniversary, Retail, MoP Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

-------------------------------------------------------------------------------
-- Cached WoW API
-------------------------------------------------------------------------------

local GetTime = GetTime
local UnitName = UnitName
local tonumber = tonumber

-------------------------------------------------------------------------------
-- Module
-------------------------------------------------------------------------------

ns.DragonLootBridge = ns.DragonLootBridge or {}

-------------------------------------------------------------------------------
-- Module-level state
-------------------------------------------------------------------------------

local suppressTimer

-------------------------------------------------------------------------------
-- Loot Suppression
--
-- When DragonLoot's loot window is open we suppress normal item toasts so the
-- player does not see duplicate notifications. XP, honor, currency, and
-- roll-win celebration toasts are still allowed through.
-------------------------------------------------------------------------------

local SUPPRESS_TIMEOUT = 120

local function OnDragonLootOpened()
    ns.dragonLootSuppressLoot = true
    -- Safety timeout - clear if CLOSED never arrives (crash / reload)
    if suppressTimer then ns.Addon:CancelTimer(suppressTimer) end
    suppressTimer = ns.Addon:ScheduleTimer(function()
        if ns.dragonLootSuppressLoot then
            ns.dragonLootSuppressLoot = false
            ns.DebugPrint("DragonLootBridge: safety timeout cleared suppress flag")
        end
        suppressTimer = nil
    end, SUPPRESS_TIMEOUT)
    ns.DebugPrint("DragonLoot loot window opened - suppressing item toasts")
end

local function OnDragonLootClosed()
    ns.dragonLootSuppressLoot = false
    if suppressTimer then
        ns.Addon:CancelTimer(suppressTimer)
        suppressTimer = nil
    end
    ns.DebugPrint("DragonLoot loot window closed - resuming item toasts")
end

-------------------------------------------------------------------------------
-- Roll-Won Celebration Toast
--
-- Fired when the player wins a roll in DragonLoot. We build a lootData table
-- compatible with ToastManager.QueueToast and flag it with isRollWin so
-- DragonToast can optionally render it differently.
-------------------------------------------------------------------------------

local function OnDragonLootRollWon(_event, rollData)
    if not rollData then return end

    local db = ns.Addon.db.profile
    if not db.enabled then return end

    local lootData = {
        isRollWin = true,
        itemLink = rollData.itemLink,
        itemID = rollData.itemID or (rollData.itemLink and tonumber(rollData.itemLink:match("item:(%d+)"))),
        itemName = rollData.itemName or UNKNOWN,
        itemQuality = rollData.itemQuality or 1,
        itemIcon = rollData.itemIcon,
        itemLevel = 0,
        itemType = rollData.rollType or "Roll",
        itemSubType = nil,
        quantity = rollData.quantity or 1,
        looter = UnitName("player") or "You",
        isSelf = true,
        isCurrency = false,
        timestamp = GetTime(),
    }

    ns.ToastManager.QueueToast(lootData)
end

-------------------------------------------------------------------------------
-- Public Interface
-------------------------------------------------------------------------------

function ns.DragonLootBridge.Initialize(addon)
    addon:RegisterMessage("DRAGONLOOT_LOOT_OPENED", OnDragonLootOpened)
    addon:RegisterMessage("DRAGONLOOT_LOOT_CLOSED", OnDragonLootClosed)
    addon:RegisterMessage("DRAGONLOOT_ROLL_WON", OnDragonLootRollWon)
    ns.DebugPrint("DragonLootBridge initialized")
end

function ns.DragonLootBridge.Shutdown()
    ns.dragonLootSuppressLoot = false
    if suppressTimer then
        ns.Addon:CancelTimer(suppressTimer)
        suppressTimer = nil
    end
    ns.Addon:UnregisterMessage("DRAGONLOOT_LOOT_OPENED")
    ns.Addon:UnregisterMessage("DRAGONLOOT_LOOT_CLOSED")
    ns.Addon:UnregisterMessage("DRAGONLOOT_ROLL_WON")
    ns.DebugPrint("DragonLootBridge shutdown")
end
