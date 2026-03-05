-------------------------------------------------------------------------------
-- GeneralTab.lua
-- General settings tab: enable, minimap icon, combat, sound, testing
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

-------------------------------------------------------------------------------
-- Cached globals
-------------------------------------------------------------------------------

local math_abs = math.abs
local table_sort = table.sort
local table_insert = table.insert
local pairs = pairs

-------------------------------------------------------------------------------
-- Namespace references
-------------------------------------------------------------------------------

local dtns = ns.dtns
local LSM = LibStub("LibSharedMedia-3.0")

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local PADDING_SIDE = 10
local PADDING_TOP = -10
local SPACING_AFTER_HEADER = 8
local SPACING_BETWEEN_WIDGETS = 6
local SPACING_BETWEEN_SECTIONS = 16
local PADDING_BOTTOM = 20

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------

local function AnchorWidget(widget, parent, yOffset)
    widget:SetPoint("TOPLEFT", parent, "TOPLEFT", PADDING_SIDE, yOffset)
    widget:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -PADDING_SIDE, yOffset)
end

local function BuildSoundValues()
    local sounds = LSM:HashTable("sound")
    local values = {}
    for name in pairs(sounds) do
        values[#values + 1] = { value = name, text = name }
    end
    table_sort(values, function(a, b) return a.text < b.text end)
    table_insert(values, 1, { value = "None", text = "None" })
    return values
end

-------------------------------------------------------------------------------
-- Section builders
-------------------------------------------------------------------------------

local function CreateCoreSection(parent, yOffset)
    local W = ns.Widgets
    local db = dtns.Addon.db

    local header = W.CreateHeader(parent, "Core Settings")
    AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - SPACING_AFTER_HEADER

    local enableToggle = W.CreateToggle(parent, {
        label = "Enable DragonToast",
        tooltip = "Enable or disable the addon",
        get = function() return db.profile.enabled end,
        set = function(value)
            db.profile.enabled = value
            if value then
                dtns.Addon:OnEnable()
            else
                dtns.Addon:OnDisable()
            end
        end,
    })
    AnchorWidget(enableToggle, parent, yOffset)
    yOffset = yOffset - enableToggle:GetHeight() - SPACING_BETWEEN_WIDGETS

    local minimapToggle = W.CreateToggle(parent, {
        label = "Show Minimap Icon",
        tooltip = "Toggle the minimap button",
        get = function() return not db.profile.minimap.hide end,
        set = function(value)
            db.profile.minimap.hide = not value
            dtns.MinimapIcon:SetShown(value)
        end,
    })
    AnchorWidget(minimapToggle, parent, yOffset)
    yOffset = yOffset - minimapToggle:GetHeight() - SPACING_BETWEEN_WIDGETS

    local deferToggle = W.CreateToggle(parent, {
        label = "Defer in Combat",
        tooltip = "Queue toasts during combat and show them when combat ends",
        get = function() return db.profile.combat.deferInCombat end,
        set = function(value) db.profile.combat.deferInCombat = value end,
    })
    AnchorWidget(deferToggle, parent, yOffset)
    yOffset = yOffset - deferToggle:GetHeight()

    return yOffset
end

local function CreateSoundSection(parent, yOffset)
    local W = ns.Widgets
    local db = dtns.Addon.db

    yOffset = yOffset - SPACING_BETWEEN_SECTIONS

    local header = W.CreateHeader(parent, "Sound")
    AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - SPACING_AFTER_HEADER

    local soundDropdown

    local soundToggle = W.CreateToggle(parent, {
        label = "Enable Sound",
        tooltip = "Play a sound when a toast appears",
        get = function() return db.profile.sound.enabled end,
        set = function(value)
            db.profile.sound.enabled = value
            if soundDropdown then soundDropdown:SetDisabled(not value) end
        end,
    })
    AnchorWidget(soundToggle, parent, yOffset)
    yOffset = yOffset - soundToggle:GetHeight() - SPACING_BETWEEN_WIDGETS

    soundDropdown = W.CreateDropdown(parent, {
        label = "Sound",
        tooltip = "Sound to play with each toast",
        values = BuildSoundValues,
        get = function() return db.profile.sound.soundFile end,
        set = function(value) db.profile.sound.soundFile = value end,
        disabled = not db.profile.sound.enabled,
    })
    AnchorWidget(soundDropdown, parent, yOffset)
    if not db.profile.sound.enabled then soundDropdown:SetDisabled(true) end
    yOffset = yOffset - soundDropdown:GetHeight()

    return yOffset
end

local function CreateTestingSection(parent, yOffset)
    local W = ns.Widgets

    yOffset = yOffset - SPACING_BETWEEN_SECTIONS

    local header = W.CreateHeader(parent, "Testing")
    AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - SPACING_AFTER_HEADER

    local testButton = W.CreateButton(parent, {
        text = "Show Test Toast",
        tooltip = "Display a test toast notification",
        onClick = function() dtns.ToastManager:ShowTestToast() end,
    })
    AnchorWidget(testButton, parent, yOffset)
    yOffset = yOffset - testButton:GetHeight() - SPACING_BETWEEN_WIDGETS

    local clearButton = W.CreateButton(parent, {
        text = "Clear Toasts",
        tooltip = "Remove all active toasts",
        onClick = function() dtns.ToastManager:ClearAll() end,
    })
    AnchorWidget(clearButton, parent, yOffset)
    yOffset = yOffset - clearButton:GetHeight() - SPACING_BETWEEN_WIDGETS

    local testModeToggle = W.CreateToggle(parent, {
        label = "Test Mode",
        tooltip = "Continuously show random test toasts",
        get = function() return dtns.ToastManager:IsTestModeActive() end,
        set = function(value)
            if value then
                dtns.ToastManager:StartTestMode()
            else
                dtns.ToastManager:StopTestMode()
            end
        end,
    })
    AnchorWidget(testModeToggle, parent, yOffset)
    yOffset = yOffset - testModeToggle:GetHeight()

    return yOffset
end

-------------------------------------------------------------------------------
-- Build the General tab content
-------------------------------------------------------------------------------

local function CreateContent(parent)
    local yOffset = PADDING_TOP

    yOffset = CreateCoreSection(parent, yOffset)
    yOffset = CreateSoundSection(parent, yOffset)
    yOffset = CreateTestingSection(parent, yOffset)

    parent:SetHeight(math_abs(yOffset) + PADDING_BOTTOM)
end

-------------------------------------------------------------------------------
-- Register tab
-------------------------------------------------------------------------------

ns.Tabs = ns.Tabs or {}
ns.Tabs[#ns.Tabs + 1] = {
    id = "general",
    label = "General",
    order = 1,
    createFunc = CreateContent,
}
