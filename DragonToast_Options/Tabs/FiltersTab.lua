-------------------------------------------------------------------------------
-- FiltersTab.lua
-- Filters settings tab: loot quality, loot sources, currency and rewards
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

-------------------------------------------------------------------------------
-- Cached globals
-------------------------------------------------------------------------------

local math_abs = math.abs
local tonumber = tonumber

-------------------------------------------------------------------------------
-- Localization
-------------------------------------------------------------------------------

local L = ns.L

-------------------------------------------------------------------------------
-- Namespace references
-------------------------------------------------------------------------------

local dtns

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local PADDING_SIDE = 10
local PADDING_TOP = -10
local SPACING_AFTER_HEADER = 8
local SPACING_BETWEEN_WIDGETS = 6
local SPACING_BETWEEN_SECTIONS = 16
local PADDING_BOTTOM = 20

local QUALITY_VALUES = {
    { value = 0, text = "|cff9d9d9dPoor|r" },
    { value = 1, text = "|cffffffffCommon|r" },
    { value = 2, text = "|cff1eff00Uncommon|r" },
    { value = 3, text = "|cff0070ddRare|r" },
    { value = 4, text = "|cffa335eeEpic|r" },
    { value = 5, text = "|cffff8000Legendary|r" },
}

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------

local function AnchorWidget(widget, parent, yOffset)
    widget:SetPoint("TOPLEFT", parent, "TOPLEFT", PADDING_SIDE, yOffset)
    widget:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -PADDING_SIDE, yOffset)
end

-------------------------------------------------------------------------------
-- Section builders
-------------------------------------------------------------------------------

local function CreateQualitySection(parent, yOffset)
    local W = ns.Widgets
    local db = dtns.Addon.db

    local header = W.CreateHeader(parent, L["Loot Quality"])
    AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - SPACING_AFTER_HEADER

    local minQuality = W.CreateDropdown(parent, {
        label = L["Minimum Quality"],
        tooltip = L["Only show toasts for items of this quality or higher"],
        values = QUALITY_VALUES,
        get = function() return db.profile.filters.minQuality end,
        set = function(value) db.profile.filters.minQuality = tonumber(value) end,
    })
    AnchorWidget(minQuality, parent, yOffset)
    yOffset = yOffset - minQuality:GetHeight()

    return yOffset
end

local function CreateSourcesSection(parent, yOffset)
    local W = ns.Widgets
    local db = dtns.Addon.db

    yOffset = yOffset - SPACING_BETWEEN_SECTIONS

    local header = W.CreateHeader(parent, L["Loot Sources"])
    AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - SPACING_AFTER_HEADER

    local selfLoot = W.CreateToggle(parent, {
        label = L["Show Self Loot"],
        tooltip = L["Show toasts when you loot items"],
        get = function() return db.profile.filters.showSelfLoot end,
        set = function(value) db.profile.filters.showSelfLoot = value end,
    })
    AnchorWidget(selfLoot, parent, yOffset)
    yOffset = yOffset - selfLoot:GetHeight() - SPACING_BETWEEN_WIDGETS

    local groupLoot = W.CreateToggle(parent, {
        label = L["Show Group Loot"],
        tooltip = L["Show toasts when group members receive loot"],
        get = function() return db.profile.filters.showGroupLoot end,
        set = function(value) db.profile.filters.showGroupLoot = value end,
    })
    AnchorWidget(groupLoot, parent, yOffset)
    yOffset = yOffset - groupLoot:GetHeight() - SPACING_BETWEEN_WIDGETS

    local questItems = W.CreateToggle(parent, {
        label = L["Show Quest Items"],
        tooltip = L["Show toasts for quest item pickups"],
        get = function() return db.profile.filters.showQuestItems end,
        set = function(value) db.profile.filters.showQuestItems = value end,
    })
    AnchorWidget(questItems, parent, yOffset)
    yOffset = yOffset - questItems:GetHeight() - SPACING_BETWEEN_WIDGETS

    local mail = W.CreateToggle(parent, {
        label = L["Show Mail"],
        tooltip = L["Show toasts for mail attachments"],
        get = function() return db.profile.filters.showMail end,
        set = function(value) db.profile.filters.showMail = value end,
    })
    AnchorWidget(mail, parent, yOffset)
    yOffset = yOffset - mail:GetHeight()

    return yOffset
end

local function CreateCurrencySection(parent, yOffset)
    local W = ns.Widgets
    local db = dtns.Addon.db

    yOffset = yOffset - SPACING_BETWEEN_SECTIONS

    local header = W.CreateHeader(parent, L["Currency and Rewards"])
    AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - SPACING_AFTER_HEADER

    local gold = W.CreateToggle(parent, {
        label = L["Show Gold"],
        tooltip = L["Show toasts for gold gains"],
        get = function() return db.profile.filters.showGold end,
        set = function(value) db.profile.filters.showGold = value end,
    })
    AnchorWidget(gold, parent, yOffset)
    yOffset = yOffset - gold:GetHeight() - SPACING_BETWEEN_WIDGETS

    local currency = W.CreateToggle(parent, {
        label = L["Show Currency"],
        tooltip = L["Show toasts for currency gains"],
        get = function() return db.profile.filters.showCurrency end,
        set = function(value) db.profile.filters.showCurrency = value end,
    })
    AnchorWidget(currency, parent, yOffset)
    yOffset = yOffset - currency:GetHeight() - SPACING_BETWEEN_WIDGETS

    local xp = W.CreateToggle(parent, {
        label = L["Show XP"],
        tooltip = L["Show toasts for experience gains"],
        get = function() return db.profile.filters.showXP end,
        set = function(value) db.profile.filters.showXP = value end,
    })
    AnchorWidget(xp, parent, yOffset)
    yOffset = yOffset - xp:GetHeight() - SPACING_BETWEEN_WIDGETS

    local honor = W.CreateToggle(parent, {
        label = L["Show Honor"],
        tooltip = L["Show toasts for honor gains"],
        get = function() return db.profile.filters.showHonor end,
        set = function(value) db.profile.filters.showHonor = value end,
    })
    AnchorWidget(honor, parent, yOffset)
    yOffset = yOffset - honor:GetHeight() - SPACING_BETWEEN_WIDGETS

    local reputation = W.CreateToggle(parent, {
        label = L["Show Reputation"],
        tooltip = L["Show toasts for reputation gains"],
        get = function() return db.profile.filters.showReputation end,
        set = function(value) db.profile.filters.showReputation = value end,
    })
    AnchorWidget(reputation, parent, yOffset)
    yOffset = yOffset - reputation:GetHeight()

    return yOffset
end

-------------------------------------------------------------------------------
-- Build the Filters tab content
-------------------------------------------------------------------------------

local function CreateContent(parent)
    dtns = ns.dtns
    local yOffset = PADDING_TOP

    yOffset = CreateQualitySection(parent, yOffset)
    yOffset = CreateSourcesSection(parent, yOffset)
    yOffset = CreateCurrencySection(parent, yOffset)

    parent:SetHeight(math_abs(yOffset) + PADDING_BOTTOM)
end

-------------------------------------------------------------------------------
-- Register tab
-------------------------------------------------------------------------------

ns.Tabs = ns.Tabs or {}
ns.Tabs[#ns.Tabs + 1] = {
    id = "filters",
    label = L["Filters"],
    order = 2,
    createFunc = CreateContent,
}
