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
-- Builds the Loot Quality section containing a header and a minimum-quality dropdown, anchoring them at the given vertical offset.
-- @param parent The parent frame or widget to which the section widgets are anchored.
-- @param yOffset The starting vertical offset (in pixels) for anchoring the section.
-- @return The updated vertical offset after placing the section's widgets.

local function CreateQualitySection(parent, yOffset)
    local W = ns.Widgets
    local db = dtns.Addon.db

    local header = W.CreateHeader(parent, L["HEADER_LOOT_QUALITY"])
    LC.AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - LC.SPACING_AFTER_HEADER

    local minQuality = W.CreateDropdown(parent, {
        label = L["MINIMUM_QUALITY"],
        tooltip = L["TOOLTIP_MINIMUM_QUALITY"],
        values = LC.QUALITY_VALUES,
        get = function() return db.profile.filters.minQuality end,
        set = function(value) db.profile.filters.minQuality = tonumber(value) end,
    })
    LC.AnchorWidget(minQuality, parent, yOffset)
    yOffset = yOffset - minQuality:GetHeight()

    return yOffset
end

local SOURCE_TOGGLES = {
    { key = "showSelfLoot",   label = "SHOW_SELF_LOOT",    tooltip = "TOOLTIP_SHOW_SELF_LOOT" },
    { key = "showGroupLoot",  label = "SHOW_GROUP_LOOT",   tooltip = "TOOLTIP_SHOW_GROUP_LOOT" },
    { key = "showQuestItems", label = "SHOW_QUEST_ITEMS",  tooltip = "TOOLTIP_SHOW_QUEST_ITEMS" },
    { key = "showMail",       label = "SHOW_MAIL",          tooltip = "TOOLTIP_SHOW_MAIL" },
}

-- Creates the "Loot Sources" section: places a header and the source filter toggles anchored from the given vertical offset.
-- @param parent The container frame to attach the section widgets to.
-- @param yOffset The starting vertical offset (number) from which widgets are anchored.
-- @return The updated vertical offset (number) after the section has been laid out.
local function CreateSourcesSection(parent, yOffset)
    local db = dtns.Addon.db

    yOffset = yOffset - LC.SPACING_BETWEEN_SECTIONS

    local header = ns.Widgets.CreateHeader(parent, L["HEADER_LOOT_SOURCES"])
    LC.AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - LC.SPACING_AFTER_HEADER

    yOffset = CreateFilterToggles(parent, yOffset, db, SOURCE_TOGGLES)

    return yOffset
end

local CURRENCY_TOGGLES = {
    { key = "showGold",       label = "SHOW_GOLD",         tooltip = "TOOLTIP_SHOW_GOLD" },
    { key = "showCurrency",   label = "SHOW_CURRENCY",     tooltip = "TOOLTIP_SHOW_CURRENCY" },
    { key = "showXP",         label = "SHOW_XP",           tooltip = "TOOLTIP_SHOW_XP" },
    { key = "showHonor",      label = "SHOW_HONOR",        tooltip = "TOOLTIP_SHOW_HONOR" },
    { key = "showReputation", label = "SHOW_REPUTATION",   tooltip = "TOOLTIP_SHOW_REPUTATION" },
}

-- Creates the "Currency and Rewards" section and its filter toggles, anchored at the given vertical offset.
-- @param parent UI frame to attach the section to.
-- @param yOffset Number representing the current vertical offset (pixels); will be decreased as widgets are added.
-- @return The updated vertical offset after placing the section and its toggles.
local function CreateCurrencySection(parent, yOffset)
    local db = dtns.Addon.db

    yOffset = yOffset - LC.SPACING_BETWEEN_SECTIONS

    local header = ns.Widgets.CreateHeader(parent, L["HEADER_CURRENCY_AND_REWARDS"])
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
    label = L["TAB_FILTERS"],
    order = 2,
    createFunc = CreateContent,
}
