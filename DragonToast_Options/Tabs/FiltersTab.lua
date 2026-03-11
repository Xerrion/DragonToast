-------------------------------------------------------------------------------
-- FiltersTab.lua
-- Filters settings tab: loot quality, loot sources, currency and rewards
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...
local LDF = _G.LibDragonFramework

-------------------------------------------------------------------------------
-- Cached globals
-------------------------------------------------------------------------------

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

local QUALITY_VALUES = {
    { value = 0, text = "|cff9d9d9dPoor|r" },
    { value = 1, text = "|cffffffffCommon|r" },
    { value = 2, text = "|cff1eff00Uncommon|r" },
    { value = 3, text = "|cff0070ddRare|r" },
    { value = 4, text = "|cffa335eeEpic|r" },
    { value = 5, text = "|cffff8000Legendary|r" },
}

-------------------------------------------------------------------------------
-- Section builders
-------------------------------------------------------------------------------

local function CreateQualitySection(parent)
    local db = dtns.Addon.db
    local section = LDF.CreateSection(parent, L["Loot Quality"])
    local stack = LDF.CreateStackLayout(section.content, "vertical")

    stack:AddChild(LDF.CreateDropdown(section.content, {
        label = L["Minimum Quality"],
        tooltip = L["Only show toasts for items of this quality or higher"],
        values = QUALITY_VALUES,
        get = function() return db.profile.filters.minQuality end,
        set = function(value) db.profile.filters.minQuality = tonumber(value) end,
    }))

    return section
end

local function CreateSourcesSection(parent)
    local db = dtns.Addon.db
    local section = LDF.CreateSection(parent, L["Loot Sources"])
    local stack = LDF.CreateStackLayout(section.content, "vertical")

    stack:AddChild(LDF.CreateToggle(section.content, {
        label = L["Show Self Loot"],
        tooltip = L["Show toasts when you loot items"],
        get = function() return db.profile.filters.showSelfLoot end,
        set = function(value) db.profile.filters.showSelfLoot = value end,
    }))

    stack:AddChild(LDF.CreateToggle(section.content, {
        label = L["Show Group Loot"],
        tooltip = L["Show toasts when group members receive loot"],
        get = function() return db.profile.filters.showGroupLoot end,
        set = function(value) db.profile.filters.showGroupLoot = value end,
    }))

    stack:AddChild(LDF.CreateToggle(section.content, {
        label = L["Show Quest Items"],
        tooltip = L["Show toasts for quest item pickups"],
        get = function() return db.profile.filters.showQuestItems end,
        set = function(value) db.profile.filters.showQuestItems = value end,
    }))

    stack:AddChild(LDF.CreateToggle(section.content, {
        label = L["Show Mail"],
        tooltip = L["Show toasts for mail attachments"],
        get = function() return db.profile.filters.showMail end,
        set = function(value) db.profile.filters.showMail = value end,
    }))

    return section
end

local function CreateCurrencySection(parent)
    local db = dtns.Addon.db
    local section = LDF.CreateSection(parent, L["Currency and Rewards"])
    local stack = LDF.CreateStackLayout(section.content, "vertical")

    stack:AddChild(LDF.CreateToggle(section.content, {
        label = L["Show Gold"],
        tooltip = L["Show toasts for gold gains"],
        get = function() return db.profile.filters.showGold end,
        set = function(value) db.profile.filters.showGold = value end,
    }))

    stack:AddChild(LDF.CreateToggle(section.content, {
        label = L["Show Currency"],
        tooltip = L["Show toasts for currency gains"],
        get = function() return db.profile.filters.showCurrency end,
        set = function(value) db.profile.filters.showCurrency = value end,
    }))

    stack:AddChild(LDF.CreateToggle(section.content, {
        label = L["Show XP"],
        tooltip = L["Show toasts for experience gains"],
        get = function() return db.profile.filters.showXP end,
        set = function(value) db.profile.filters.showXP = value end,
    }))

    stack:AddChild(LDF.CreateToggle(section.content, {
        label = L["Show Honor"],
        tooltip = L["Show toasts for honor gains"],
        get = function() return db.profile.filters.showHonor end,
        set = function(value) db.profile.filters.showHonor = value end,
    }))

    stack:AddChild(LDF.CreateToggle(section.content, {
        label = L["Show Reputation"],
        tooltip = L["Show toasts for reputation gains"],
        get = function() return db.profile.filters.showReputation end,
        set = function(value) db.profile.filters.showReputation = value end,
    }))

    return section
end

-------------------------------------------------------------------------------
-- Build the Filters tab content
-------------------------------------------------------------------------------

local function CreateContent(parent)
    dtns = ns.dtns
    local stack = LDF.CreateStackLayout(parent, "vertical")

    stack:AddChild(CreateQualitySection(parent))
    stack:AddChild(CreateSourcesSection(parent))
    stack:AddChild(CreateCurrencySection(parent))
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
