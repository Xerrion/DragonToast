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
-- DragonWidgets references
-------------------------------------------------------------------------------

local W = ns.DW.Widgets
local LC = ns.DW.LayoutConstants
local L = ns.L

-------------------------------------------------------------------------------
-- Namespace references
-------------------------------------------------------------------------------

local dtns

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------

local function CreateFilterToggles(parent, yOffset, db, entries)
    for _, entry in ipairs(entries) do
        local toggle = W.CreateToggle(parent, {
            label = entry.label,
            tooltip = entry.tooltip,
            get = function() return db.profile.filters[entry.key] end,
            set = function(value) db.profile.filters[entry.key] = value end,
        })
        yOffset = LC.AnchorWidget(toggle, parent, yOffset) - LC.SPACING_BETWEEN_WIDGETS
    end
    return yOffset
end

-------------------------------------------------------------------------------
-- Section builders
-- Builds the Loot Quality section containing a header and a
-- minimum-quality dropdown, anchoring them at the given vertical offset.
-- @param parent The parent frame or widget to which the section widgets are anchored.
-- @param yOffset The starting vertical offset (in pixels) for anchoring the section.
-- @return The updated vertical offset after placing the section's widgets.

local function CreateQualitySection(parent, yOffset)
    local db = dtns.Addon.db

    local section = W.CreateSection(parent, L["Loot Quality"])
    local content = section.content
    local innerY = -LC.SECTION_PADDING_TOP

    local minQuality = W.CreateDropdown(content, {
        label = L["Minimum Quality"],
        tooltip = L["Only show toasts for items of this quality or higher"],
        values = ns.QualityValues,
        get = function() return db.profile.filters.minQuality end,
        set = function(value) db.profile.filters.minQuality = tonumber(value) or 0 end,
    })
    innerY = LC.AnchorWidget(minQuality, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    section:SetContentHeight(math_abs(innerY) + LC.SECTION_PADDING_BOTTOM)
    return LC.AnchorSection(section, parent, yOffset) - LC.SPACING_BETWEEN_SECTIONS
end

local SOURCE_TOGGLES = {
    { key = "showSelfLoot",   label = L["Show Self Loot"],    tooltip = L["Show toasts when you loot items"] },
    { key = "showGroupLoot",  label = L["Show Group Loot"],
        tooltip = L["Show toasts when group members receive loot"] },
    { key = "showQuestItems", label = L["Show Quest Items"],  tooltip = L["Show toasts for quest item pickups"] },
    { key = "showMail",       label = L["Show Mail"],         tooltip = L["Show toasts for mail attachments"] },
}

-- Creates the "Loot Sources" section: places a header and the source
-- filter toggles anchored from the given vertical offset.
-- @param parent The container frame to attach the section widgets to.
-- @param yOffset The starting vertical offset (number) from which widgets are anchored.
-- @return The updated vertical offset (number) after the section has been laid out.
local function CreateSourcesSection(parent, yOffset)
    local db = dtns.Addon.db

    local section = W.CreateSection(parent, L["Loot Sources"])
    local content = section.content
    local innerY = -LC.SECTION_PADDING_TOP

    innerY = CreateFilterToggles(content, innerY, db, SOURCE_TOGGLES)

    section:SetContentHeight(math_abs(innerY) + LC.SECTION_PADDING_BOTTOM)
    return LC.AnchorSection(section, parent, yOffset) - LC.SPACING_BETWEEN_SECTIONS
end

local CURRENCY_TOGGLES = {
    { key = "showGold",       label = L["Show Gold Gains"],   tooltip = L["Show toasts for gold gains"] },
    { key = "showMoneyLoss",  label = L["Show Money Losses"], tooltip = L["Show toasts for money losses"] },
    { key = "showCurrency",   label = L["Show Currency"],     tooltip = L["Show toasts for currency gains"] },
    { key = "showXP",         label = L["Show XP"],           tooltip = L["Show toasts for experience gains"] },
    { key = "showHonor",      label = L["Show Honor"],        tooltip = L["Show toasts for honor gains"] },
    { key = "showReputation", label = L["Show Reputation Gains"],
        tooltip = L["Show toasts for reputation gains"] },
    { key = "showReputationLoss", label = L["Show Reputation Losses"],
        tooltip = L["Show toasts for reputation losses"] },
}

-- Creates the "Currency and Rewards" section and its filter toggles, anchored at the given vertical offset.
-- @param parent UI frame to attach the section to.
-- @param yOffset Number representing the current vertical offset (pixels); will be decreased as widgets are added.
-- @return The updated vertical offset after placing the section and its toggles.
local function CreateCurrencySection(parent, yOffset)
    local db = dtns.Addon.db

    local section = W.CreateSection(parent, L["Currency and Rewards"])
    local content = section.content
    local innerY = -LC.SECTION_PADDING_TOP

    innerY = CreateFilterToggles(content, innerY, db, CURRENCY_TOGGLES)

    section:SetContentHeight(math_abs(innerY) + LC.SECTION_PADDING_BOTTOM)
    return LC.AnchorSection(section, parent, yOffset) - LC.SPACING_BETWEEN_SECTIONS
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

ns.Tabs[#ns.Tabs + 1] = {
    id = "filters",
    label = L["Filters"],
    order = 6,
    createFunc = CreateContent,
}
