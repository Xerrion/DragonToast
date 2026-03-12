-------------------------------------------------------------------------------
-- FiltersTab.lua
-- Filters settings tab: loot quality, loot sources, currency and rewards
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...
local LC = ns.LayoutConstants

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
-- Helpers
-------------------------------------------------------------------------------

local function CreateFilterToggles(parent, yOffset, db, entries)
    local W = ns.Widgets
    for i, entry in ipairs(entries) do
        local toggle = W.CreateToggle(parent, {
            label = L[entry.label],
            tooltip = L[entry.tooltip],
            get = function() return db.profile.filters[entry.key] end,
            set = function(value) db.profile.filters[entry.key] = value end,
        })
        LC.AnchorWidget(toggle, parent, yOffset)
        -- No trailing spacing after the last toggle in a section
        if i < #entries then
            yOffset = yOffset - toggle:GetHeight() - LC.SPACING_BETWEEN_WIDGETS
        else
            yOffset = yOffset - toggle:GetHeight()
        end
    end
    return yOffset
end

-------------------------------------------------------------------------------
-- Section builders
-------------------------------------------------------------------------------

local function CreateQualitySection(parent, yOffset)
    local W = ns.Widgets
    local db = dtns.Addon.db

    local header = W.CreateHeader(parent, L["Loot Quality"])
    LC.AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - LC.SPACING_AFTER_HEADER

    local minQuality = W.CreateDropdown(parent, {
        label = L["Minimum Quality"],
        tooltip = L["Only show toasts for items of this quality or higher"],
        values = LC.QUALITY_VALUES,
        get = function() return db.profile.filters.minQuality end,
        set = function(value) db.profile.filters.minQuality = tonumber(value) end,
    })
    LC.AnchorWidget(minQuality, parent, yOffset)
    yOffset = yOffset - minQuality:GetHeight()

    return yOffset
end

local SOURCE_TOGGLES = {
    { key = "showSelfLoot",   label = "Show Self Loot",   tooltip = "Show toasts when you loot items" },
    { key = "showGroupLoot",  label = "Show Group Loot",  tooltip = "Show toasts when group members receive loot" },
    { key = "showQuestItems", label = "Show Quest Items",  tooltip = "Show toasts for quest item pickups" },
    { key = "showMail",       label = "Show Mail",         tooltip = "Show toasts for mail attachments" },
}

local function CreateSourcesSection(parent, yOffset)
    local db = dtns.Addon.db

    yOffset = yOffset - LC.SPACING_BETWEEN_SECTIONS

    local header = ns.Widgets.CreateHeader(parent, L["Loot Sources"])
    LC.AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - LC.SPACING_AFTER_HEADER

    yOffset = CreateFilterToggles(parent, yOffset, db, SOURCE_TOGGLES)

    return yOffset
end

local CURRENCY_TOGGLES = {
    { key = "showGold",       label = "Show Gold",       tooltip = "Show toasts for gold gains" },
    { key = "showCurrency",   label = "Show Currency",   tooltip = "Show toasts for currency gains" },
    { key = "showXP",         label = "Show XP",         tooltip = "Show toasts for experience gains" },
    { key = "showHonor",      label = "Show Honor",      tooltip = "Show toasts for honor gains" },
    { key = "showReputation", label = "Show Reputation", tooltip = "Show toasts for reputation gains" },
}

local function CreateCurrencySection(parent, yOffset)
    local db = dtns.Addon.db

    yOffset = yOffset - LC.SPACING_BETWEEN_SECTIONS

    local header = ns.Widgets.CreateHeader(parent, L["Currency and Rewards"])
    LC.AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - LC.SPACING_AFTER_HEADER

    yOffset = CreateFilterToggles(parent, yOffset, db, CURRENCY_TOGGLES)

    return yOffset
end

-------------------------------------------------------------------------------
-- Build the Filters tab content
-------------------------------------------------------------------------------

local function CreateContent(parent)
    dtns = ns.dtns
    local yOffset = LC.PADDING_TOP

    yOffset = CreateQualitySection(parent, yOffset)
    yOffset = CreateSourcesSection(parent, yOffset)
    yOffset = CreateCurrencySection(parent, yOffset)

    parent:SetHeight(math_abs(yOffset) + LC.PADDING_BOTTOM)
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
