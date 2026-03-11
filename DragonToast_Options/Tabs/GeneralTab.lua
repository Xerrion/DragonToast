-------------------------------------------------------------------------------
-- GeneralTab.lua
-- General settings tab: enable, minimap icon, combat, sound, testing
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...
local LDF = _G.LibDragonFramework

-------------------------------------------------------------------------------
-- Cached globals
-------------------------------------------------------------------------------

local pairs = pairs
local table_sort = table.sort
local table_insert = table.insert

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

local function CreateCoreSection(parent)
    local db = dtns.Addon.db
    local section = LDF.CreateSection(parent, L["Core Settings"])
    local stack = LDF.CreateStackLayout(section.content, "vertical")

    stack:AddChild(LDF.CreateToggle(section.content, {
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
    }))

    stack:AddChild(LDF.CreateToggle(section.content, {
        label = L["Show Minimap Icon"],
        tooltip = L["Toggle the minimap button"],
        get = function() return not db.profile.minimap.hide end,
        set = function(value)
            db.profile.minimap.hide = not value
            dtns.MinimapIcon:SetShown(value)
        end,
    }))

    stack:AddChild(LDF.CreateToggle(section.content, {
        label = L["Defer in Combat"],
        tooltip = L["Queue toasts during combat and show them when combat ends"],
        get = function() return db.profile.combat.deferInCombat end,
        set = function(value) db.profile.combat.deferInCombat = value end,
    }))

    return section
end

local function CreateSoundSection(parent)
    local db = dtns.Addon.db
    local section = LDF.CreateSection(parent, L["Sound"])
    local stack = LDF.CreateStackLayout(section.content, "vertical")

    local soundDropdown

    local soundToggle = LDF.CreateToggle(section.content, {
        label = L["Enable Sound"],
        tooltip = L["Play a sound when a toast appears"],
        get = function() return db.profile.sound.enabled end,
        set = function(value)
            db.profile.sound.enabled = value
            if soundDropdown then soundDropdown:SetDisabled(not value) end
        end,
    })
    stack:AddChild(soundToggle)

    soundDropdown = LDF.CreateDropdown(section.content, {
        label = L["Sound"],
        tooltip = L["Sound to play with each toast"],
        values = BuildSoundValues,
        get = function() return db.profile.sound.soundFile end,
        set = function(value) db.profile.sound.soundFile = value end,
        disabled = not db.profile.sound.enabled,
    })
    stack:AddChild(soundDropdown)

    return section
end

local function CreateTestingSection(parent)
    local section = LDF.CreateSection(parent, L["Testing"])
    local stack = LDF.CreateStackLayout(section.content, "vertical")

    stack:AddChild(LDF.CreateButton(section.content, {
        text = L["Show Test Toast"],
        tooltip = L["Display a test toast notification"],
        onClick = function() dtns.ToastManager:ShowTestToast() end,
    }))

    stack:AddChild(LDF.CreateButton(section.content, {
        text = L["Clear Toasts"],
        tooltip = L["Remove all active toasts"],
        onClick = function() dtns.ToastManager:ClearAll() end,
    }))

    stack:AddChild(LDF.CreateToggle(section.content, {
        label = L["Test Mode"],
        tooltip = L["Continuously show random test toasts"],
        get = function() return dtns.ToastManager:IsTestModeActive() end,
        set = function(value)
            if value then
                dtns.ToastManager:StartTestMode()
            else
                dtns.ToastManager:StopTestMode()
            end
        end,
    }))

    return section
end

-------------------------------------------------------------------------------
-- Build the General tab content
-------------------------------------------------------------------------------

local function CreateContent(parent)
    dtns = ns.dtns
    local stack = LDF.CreateStackLayout(parent, "vertical")
    stack:AddChild(CreateCoreSection(parent))
    stack:AddChild(CreateSoundSection(parent))
    stack:AddChild(CreateTestingSection(parent))
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
