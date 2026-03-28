-------------------------------------------------------------------------------
-- MessageBridge.lua
-- Generic cross-addon messaging bridge for toast suppression and queuing
--
-- Supported versions: TBC Anniversary, Retail, MoP Classic
-------------------------------------------------------------------------------

local _, ns = ...

-------------------------------------------------------------------------------
-- Cached WoW API
-------------------------------------------------------------------------------

local GetTime = GetTime
local UnitName = UnitName
local tonumber = tonumber
local type = type
local next = next
local wipe = wipe
local L = ns.L

local PLAYER_UNIT = "player"

-------------------------------------------------------------------------------
-- Module
-------------------------------------------------------------------------------

ns.MessageBridge = ns.MessageBridge or {}

-------------------------------------------------------------------------------
-- Module-level state
-------------------------------------------------------------------------------

-- Keys are source strings, values are AceTimer handles
local suppressionSources = {}

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local SUPPRESS_TIMEOUT = 120

-------------------------------------------------------------------------------
-- Generic Messages
-------------------------------------------------------------------------------

local ALL_MESSAGES = {
    "DRAGONTOAST_SUPPRESS",
    "DRAGONTOAST_UNSUPPRESS",
    "DRAGONTOAST_QUEUE_TOAST",
    "DRAGONLOOT_LOOT_OPENED",
    "DRAGONLOOT_LOOT_CLOSED",
    "DRAGONLOOT_ROLL_WON",
}

-------------------------------------------------------------------------------
-- Suppression Helpers
-------------------------------------------------------------------------------

local function AddSuppression(source)
    -- Cancel existing timer for this source if any
    if suppressionSources[source] then
        ns.Addon:CancelTimer(suppressionSources[source])
    end

    -- Create per-source safety timer
    suppressionSources[source] = ns.Addon:ScheduleTimer(function()
        suppressionSources[source] = nil
        ns.DebugPrint("MessageBridge: safety timeout cleared suppression for '" .. source .. "'")
    end, SUPPRESS_TIMEOUT)

    ns.DebugPrint("MessageBridge: suppression added for '" .. source .. "'")
end

local function RemoveSuppression(source)
    if suppressionSources[source] then
        ns.Addon:CancelTimer(suppressionSources[source])
        suppressionSources[source] = nil
    end
    ns.DebugPrint("MessageBridge: suppression removed for '" .. source .. "'")
end

-------------------------------------------------------------------------------
-- Generic Message Handlers
-------------------------------------------------------------------------------

local function OnSuppress(_, source)
    if type(source) ~= "string" or source == "" then return end
    AddSuppression(source)
end

local function OnUnsuppress(_, source)
    if type(source) ~= "string" or source == "" then return end
    RemoveSuppression(source)
end

local function OnQueueToast(_, toastData)
    if type(toastData) ~= "table" then return end
    if not toastData.itemName or not toastData.itemIcon or not toastData.itemQuality then return end

    local db = ns.Addon.db.profile
    if not db.enabled then return end

    -- Shallow copy to avoid mutating caller's table
    local data = {}
    for k, v in pairs(toastData) do data[k] = v end

    -- Coerce and validate quality
    data.itemQuality = tonumber(data.itemQuality)
    if not data.itemQuality then return end

    if not data.timestamp then
        data.timestamp = GetTime()
    end

    ns.ToastManager.QueueToast(data)
end

-------------------------------------------------------------------------------
-- Roll-Won Toast Builder
--
-- Transforms DragonLoot rollData into a lootData table compatible with
-- ToastManager.QueueToast. Flagged with isRollWin so DragonToast can
-- optionally render it differently.
-------------------------------------------------------------------------------

-- Map numeric roll types to display names
local rollTypeNames = {
    [0] = L["Pass"],
    [1] = L["Need"],
    [2] = L["Greed"],
    [3] = L["Disenchant"],
    [4] = L["Transmog"],
}

-- Builds a toast payload representing a won roll for a loot item.
-- @param rollData Table with roll and item details. Expected keys:
--   `rollType` (number) - numeric roll type.
--   `rollValue` (number, optional) - numeric roll value to display.
--   `itemLink` (string, optional) - item link string.
--   `itemID` (number, optional) - numeric item ID.
--   `itemName` (string, optional) - display name for the item.
--   `itemQuality` (number, optional) - item quality index.
--   `itemIcon` (string, optional) - icon texture path.
--   `quantity` (number, optional) - item quantity.
--   `winnerName` (string, optional) - name of the roll winner.
--   `isSelf` (boolean, optional) - whether the winner is the player.
-- @return A table containing the toast payload with keys:
--   `isRollWin` (true), `itemLink`, `itemID`, `itemName`, `itemQuality`,
--   `itemIcon`, `itemLevel` (number), `itemType` (display string for roll),
--   `itemSubType` (nil), `quantity`, `looter` (string), `isSelf` (boolean),
--   `isCurrency` (false), and `timestamp` (number).
local function BuildRollWonToast(rollData)
    -- Build human-readable roll display (e.g. "Need (87)")
    local rollTypeName = rollTypeNames[rollData.rollType] or L["Roll"]
    local rollDisplay = rollTypeName
    if rollData.rollValue then
        rollDisplay = rollTypeName .. " (" .. rollData.rollValue .. ")"
    end

    return {
        isRollWin = true,
        itemLink = rollData.itemLink,
        itemID = rollData.itemID or (rollData.itemLink and tonumber(rollData.itemLink:match("item:(%d+)"))),
        itemName = rollData.itemName or UNKNOWN or L["Unknown"],
        itemQuality = rollData.itemQuality or 1,
        itemIcon = rollData.itemIcon,
        itemLevel = 0,
        itemType = rollDisplay,
        itemSubType = nil,
        quantity = rollData.quantity or 1,
        looter = rollData.winnerName or UnitName(PLAYER_UNIT) or L["You"],
        isSelf = (type(rollData.isSelf) == "boolean" and rollData.isSelf)
            or (rollData.winnerName == UnitName(PLAYER_UNIT) or rollData.winnerName == L["You"]),
        isCurrency = false,
        timestamp = GetTime(),
    }
end

-------------------------------------------------------------------------------
-- Legacy Message Handlers
-------------------------------------------------------------------------------

-- Legacy: remove when all senders use generic API
local function OnDragonLootOpened()
    AddSuppression("DragonLoot")
end

-- Legacy: remove when all senders use generic API
local function OnDragonLootClosed()
    RemoveSuppression("DragonLoot")
end

-- Legacy: remove when all senders use generic API
local function OnDragonLootRollWon(_, rollData)
    if not rollData then return end

    local db = ns.Addon.db.profile
    if not db.enabled then return end

    local lootData = BuildRollWonToast(rollData)
    ns.ToastManager.QueueToast(lootData)
end

-------------------------------------------------------------------------------
-- Public Interface
-------------------------------------------------------------------------------

function ns.MessageBridge.Initialize(addon)
    -- Generic messages
    addon:RegisterMessage("DRAGONTOAST_SUPPRESS", OnSuppress)
    addon:RegisterMessage("DRAGONTOAST_UNSUPPRESS", OnUnsuppress)
    addon:RegisterMessage("DRAGONTOAST_QUEUE_TOAST", OnQueueToast)

    -- Legacy messages (backward compat)
    addon:RegisterMessage("DRAGONLOOT_LOOT_OPENED", OnDragonLootOpened)
    addon:RegisterMessage("DRAGONLOOT_LOOT_CLOSED", OnDragonLootClosed)
    addon:RegisterMessage("DRAGONLOOT_ROLL_WON", OnDragonLootRollWon)

    ns.DebugPrint("MessageBridge initialized")
end

function ns.MessageBridge.Shutdown()
    -- Cancel all suppress timers and wipe state
    for _source, timerHandle in pairs(suppressionSources) do
        ns.Addon:CancelTimer(timerHandle)
    end
    wipe(suppressionSources)

    -- Unregister all messages
    for _, msg in ipairs(ALL_MESSAGES) do
        ns.Addon:UnregisterMessage(msg)
    end

    ns.DebugPrint("MessageBridge shutdown")
end

function ns.MessageBridge.IsSuppressed()
    return next(suppressionSources) ~= nil
end
