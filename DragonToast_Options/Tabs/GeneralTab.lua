-------------------------------------------------------------------------------
-- GeneralTab.lua
-- General settings tab: enable, minimap icon, combat, sound, testing
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...
local LC = ns.LayoutConstants

-------------------------------------------------------------------------------
-- Cached globals
-------------------------------------------------------------------------------

local math_abs = math.abs
local table_sort = table.sort
local table_insert = table.insert
local pairs = pairs

-------------------------------------------------------------------------------
-- Localization
-------------------------------------------------------------------------------

local L = ns.L

-------------------------------------------------------------------------------
-- Namespace references
-------------------------------------------------------------------------------

local dtns
local LSM = LibStub("LibSharedMedia-3.0", true)

-------------------------------------------------------------------------------
-- Helpers
-- Builds a sorted list of available sound options for use in a dropdown.
-- Includes a leading `{ value = "None", text = L["NONE"] }` entry.
-- If LibSharedMedia-3.0 is unavailable, returns an empty table.
-- @return A table of `{ value = <soundName>, text = <displayName> }`
--   entries, sorted alphabetically by `text`, with the "None" entry
--   first (or `{}` if no sound provider).

local function BuildSoundValues()
    if not LSM then return {} end
    local sounds = LSM:HashTable("sound")
    local values = {}
    for name in pairs(sounds) do
        values[#values + 1] = { value = name, text = name }
    end
    table_sort(values, function(a, b) return a.text < b.text end)
    table_insert(values, 1, { value = "None", text = L["NONE"] })
    return values
end

-------------------------------------------------------------------------------
-- Section builders
-- Builds the "Core Settings" subsection of the General tab and places its widgets into the given parent container.
-- @param parent UI frame that will contain the section's widgets.
-- @param yOffset Number representing the starting vertical offset within `parent`.
-- @return number The updated vertical offset after the section's widgets have been placed.

local function CreateCoreSection(parent, yOffset)
    local W = ns.Widgets
    local db = dtns.Addon.db

    local header = W.CreateHeader(parent, L["HEADER_CORE_SETTINGS"])
    LC.AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - LC.SPACING_AFTER_HEADER

    local enableToggle = W.CreateToggle(parent, {
        label = L["ENABLE_DRAGONTOAST"],
        tooltip = L["TOOLTIP_ENABLE_DRAGONTOAST"],
        get = function() return db.profile.enabled end,
        set = function(value)
            if value then
                dtns.Addon:OnEnable()
            else
                dtns.Addon:OnDisable()
            end
        end,
    })
    LC.AnchorWidget(enableToggle, parent, yOffset)
    yOffset = yOffset - enableToggle:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

    local minimapToggle = W.CreateToggle(parent, {
        label = L["SHOW_MINIMAP_ICON"],
        tooltip = L["TOOLTIP_SHOW_MINIMAP_ICON"],
        get = function() return not db.profile.minimap.hide end,
        set = function(value)
            db.profile.minimap.hide = not value
            dtns.MinimapIcon:SetShown(value)
        end,
    })
    LC.AnchorWidget(minimapToggle, parent, yOffset)
    yOffset = yOffset - minimapToggle:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

    local deferToggle = W.CreateToggle(parent, {
        label = L["DEFER_IN_COMBAT"],
        tooltip = L["TOOLTIP_DEFER_IN_COMBAT"],
        get = function() return db.profile.combat.deferInCombat end,
        set = function(value) db.profile.combat.deferInCombat = value end,
    })
    LC.AnchorWidget(deferToggle, parent, yOffset)
    yOffset = yOffset - deferToggle:GetHeight()

    return yOffset
end

-- Builds the "Sound" subsection of the General tab UI.
-- Creates a header, an enable-sound toggle, and a sound selection
-- dropdown; the dropdown is disabled when sound is disabled.
-- @param parent The parent UI frame to anchor the section's widgets to.
-- @param yOffset The starting vertical offset for placing widgets; layout proceeds downward.
-- @return The updated vertical offset after placing the section's widgets.
local function CreateSoundSection(parent, yOffset)
    local W = ns.Widgets
    local db = dtns.Addon.db

    yOffset = yOffset - LC.SPACING_BETWEEN_SECTIONS

    local header = W.CreateHeader(parent, L["SOUND"])
    LC.AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - LC.SPACING_AFTER_HEADER

    local soundDropdown

    local soundToggle = W.CreateToggle(parent, {
        label = L["ENABLE_SOUND"],
        tooltip = L["TOOLTIP_ENABLE_SOUND"],
        get = function() return db.profile.sound.enabled end,
        set = function(value)
            db.profile.sound.enabled = value
            if soundDropdown then soundDropdown:SetDisabled(not value) end
        end,
    })
    LC.AnchorWidget(soundToggle, parent, yOffset)
    yOffset = yOffset - soundToggle:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

    soundDropdown = W.CreateDropdown(parent, {
        label = L["SOUND"],
        tooltip = L["TOOLTIP_SOUND"],
        values = BuildSoundValues,
        get = function() return db.profile.sound.soundFile end,
        set = function(value) db.profile.sound.soundFile = value end,
        disabled = not db.profile.sound.enabled,
    })
    LC.AnchorWidget(soundDropdown, parent, yOffset)
    if not db.profile.sound.enabled then soundDropdown:SetDisabled(true) end
    yOffset = yOffset - soundDropdown:GetHeight()

    return yOffset
end

-- Builds the "Testing" subsection in the provided parent frame and anchors its widgets vertically.
-- Creates a header, "Show Test Toast" and "Clear Toasts" buttons, and a "Test Mode" toggle.
-- @param parent The parent frame to contain the testing widgets.
-- @param yOffset The starting vertical offset (in pixels) from the top of the parent where the section is placed.
-- @return The updated vertical offset after placing the section.
local function CreateTestingSection(parent, yOffset)
    local W = ns.Widgets

    yOffset = yOffset - LC.SPACING_BETWEEN_SECTIONS

    local header = W.CreateHeader(parent, L["HEADER_TESTING"])
    LC.AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - LC.SPACING_AFTER_HEADER

    local testButton = W.CreateButton(parent, {
        text = L["SHOW_TEST_TOAST"],
        tooltip = L["TOOLTIP_SHOW_TEST_TOAST"],
        onClick = function() dtns.TestToasts.ShowTestToast() end,
    })
    LC.AnchorWidget(testButton, parent, yOffset)
    yOffset = yOffset - testButton:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

    local clearButton = W.CreateButton(parent, {
        text = L["CLEAR_TOASTS"],
        tooltip = L["TOOLTIP_CLEAR_TOASTS"],
        onClick = function() dtns.ToastManager:ClearAll() end,
    })
    LC.AnchorWidget(clearButton, parent, yOffset)
    yOffset = yOffset - clearButton:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

    local testModeToggle = W.CreateToggle(parent, {
        label = L["TEST_MODE"],
        tooltip = L["TOOLTIP_TEST_MODE"],
        get = function() return dtns.TestToasts.IsTestModeActive() end,
        set = function(value)
            if value then
                dtns.TestToasts.StartTestMode()
            else
                dtns.TestToasts.StopTestMode()
            end
        end,
    })
    LC.AnchorWidget(testModeToggle, parent, yOffset)
    yOffset = yOffset - testModeToggle:GetHeight()

    return yOffset
end

-------------------------------------------------------------------------------
-- Build the General tab content
-------------------------------------------------------------------------------

local function CreateContent(parent)
    dtns = ns.dtns
    local yOffset = LC.PADDING_TOP

    yOffset = CreateCoreSection(parent, yOffset)
    yOffset = CreateSoundSection(parent, yOffset)
    yOffset = CreateTestingSection(parent, yOffset)

    parent:SetHeight(math_abs(yOffset) + LC.PADDING_BOTTOM)
end

-------------------------------------------------------------------------------
-- Register tab
-------------------------------------------------------------------------------

ns.Tabs = ns.Tabs or {}
ns.Tabs[#ns.Tabs + 1] = {
    id = "general",
    label = L["TAB_GENERAL"],
    order = 1,
    createFunc = CreateContent,
}
