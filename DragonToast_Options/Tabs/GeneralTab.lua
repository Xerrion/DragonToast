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
local LSM = LibStub("LibSharedMedia-3.0")

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------

local function BuildSoundValues()
    local sounds = LSM:HashTable("sound")
    local values = {}
    for name in pairs(sounds) do
        values[#values + 1] = { value = name, text = name }
    end
    table_sort(values, function(a, b) return a.text < b.text end)
    table_insert(values, 1, { value = "None", text = L["None"] })
    return values
end

-------------------------------------------------------------------------------
-- Section builders
-------------------------------------------------------------------------------

local function CreateCoreSection(parent, yOffset)
    local W = ns.Widgets
    local db = dtns.Addon.db

    local header = W.CreateHeader(parent, L["Core Settings"])
    LC.AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - LC.SPACING_AFTER_HEADER

    local enableToggle = W.CreateToggle(parent, {
        label = L["Enable DragonToast"],
        tooltip = L["Enable or disable the addon"],
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
    LC.AnchorWidget(enableToggle, parent, yOffset)
    yOffset = yOffset - enableToggle:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

    local minimapToggle = W.CreateToggle(parent, {
        label = L["Show Minimap Icon"],
        tooltip = L["Toggle the minimap button"],
        get = function() return not db.profile.minimap.hide end,
        set = function(value)
            db.profile.minimap.hide = not value
            dtns.MinimapIcon:SetShown(value)
        end,
    })
    LC.AnchorWidget(minimapToggle, parent, yOffset)
    yOffset = yOffset - minimapToggle:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

    local deferToggle = W.CreateToggle(parent, {
        label = L["Defer in Combat"],
        tooltip = L["Queue toasts during combat and show them when combat ends"],
        get = function() return db.profile.combat.deferInCombat end,
        set = function(value) db.profile.combat.deferInCombat = value end,
    })
    LC.AnchorWidget(deferToggle, parent, yOffset)
    yOffset = yOffset - deferToggle:GetHeight()

    return yOffset
end

local function CreateSoundSection(parent, yOffset)
    local W = ns.Widgets
    local db = dtns.Addon.db

    yOffset = yOffset - LC.SPACING_BETWEEN_SECTIONS

    local header = W.CreateHeader(parent, L["Sound"])
    LC.AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - LC.SPACING_AFTER_HEADER

    local soundDropdown

    local soundToggle = W.CreateToggle(parent, {
        label = L["Enable Sound"],
        tooltip = L["Play a sound when a toast appears"],
        get = function() return db.profile.sound.enabled end,
        set = function(value)
            db.profile.sound.enabled = value
            if soundDropdown then soundDropdown:SetDisabled(not value) end
        end,
    })
    LC.AnchorWidget(soundToggle, parent, yOffset)
    yOffset = yOffset - soundToggle:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

    soundDropdown = W.CreateDropdown(parent, {
        label = L["Sound"],
        tooltip = L["Sound to play with each toast"],
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

local function CreateTestingSection(parent, yOffset)
    local W = ns.Widgets

    yOffset = yOffset - LC.SPACING_BETWEEN_SECTIONS

    local header = W.CreateHeader(parent, L["Testing"])
    LC.AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - LC.SPACING_AFTER_HEADER

    local testButton = W.CreateButton(parent, {
        text = L["Show Test Toast"],
        tooltip = L["Display a test toast notification"],
        onClick = function() dtns.TestToasts.ShowTestToast() end,
    })
    LC.AnchorWidget(testButton, parent, yOffset)
    yOffset = yOffset - testButton:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

    local clearButton = W.CreateButton(parent, {
        text = L["Clear Toasts"],
        tooltip = L["Remove all active toasts"],
        onClick = function() dtns.ToastManager:ClearAll() end,
    })
    LC.AnchorWidget(clearButton, parent, yOffset)
    yOffset = yOffset - clearButton:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

    local testModeToggle = W.CreateToggle(parent, {
        label = L["Test Mode"],
        tooltip = L["Continuously show random test toasts"],
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
    label = L["General"],
    order = 1,
    createFunc = CreateContent,
}
