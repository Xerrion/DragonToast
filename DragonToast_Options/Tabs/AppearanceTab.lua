-------------------------------------------------------------------------------
-- AppearanceTab.lua
-- Appearance settings tab: preset, font, background, border, glow, icon
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...
local LDF = _G.LibDragonFramework

-------------------------------------------------------------------------------
-- Cached globals
-------------------------------------------------------------------------------

local pairs = pairs
local ipairs = ipairs
local table_sort = table.sort

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

local function BuildLSMValues(mediaType)
    local lsm = LibStub("LibSharedMedia-3.0", true)
    if not lsm then return {} end
    local hash = lsm:HashTable(mediaType)
    local values = {}
    for name in pairs(hash) do
        values[#values + 1] = { value = name, text = name }
    end
    table_sort(values, function(a, b) return a.text < b.text end)
    return values
end

local function NotifyAppearanceChange()
    dtns.ToastManager:UpdateLayout()
end

-------------------------------------------------------------------------------
-- Static tables
-------------------------------------------------------------------------------

local FONT_OUTLINE_VALUES = {
    { value = "", text = L["None"] },
    { value = "OUTLINE", text = L["Outline"] },
    { value = "THICKOUTLINE", text = L["Thick Outline"] },
    { value = "MONOCHROME, OUTLINE", text = L["Monochrome"] },
}

local function GetPresetValues()
    local values = {}
    for _, key in ipairs(dtns.Presets.order) do
        values[#values + 1] = { value = key, text = dtns.Presets.names[key] }
    end
    return values
end

-------------------------------------------------------------------------------
-- Section builders
-------------------------------------------------------------------------------

local function CreatePresetSection(parent)
    local section = LDF.CreateSection(parent, L["Preset"])
    local stack = LDF.CreateStackLayout(section.content, "vertical")

    stack:AddChild(LDF.CreateDropdown(section.content, {
        label = L["Skin Preset"],
        tooltip = L["Apply a preset appearance theme"],
        values = GetPresetValues,
        get = function() return dtns.Presets:DetectPreset() or "default" end,
        set = function(value)
            dtns.Presets:ApplyPreset(value)
            ns.RefreshVisibleWidgets()
        end,
    }))

    return section
end

local function CreateFontSection(parent)
    local db = dtns.Addon.db
    local section = LDF.CreateSection(parent, L["Font"], { collapsible = true })
    local stack = LDF.CreateStackLayout(section.content, "vertical")

    stack:AddChild(LDF.CreateDropdown(section.content, {
        label = L["Font"],
        tooltip = L["Font face for toast text"],
        values = function() return BuildLSMValues("font") end,
        mediaType = "font",
        get = function() return db.profile.appearance.fontFace end,
        set = function(value) db.profile.appearance.fontFace = value; NotifyAppearanceChange() end,
    }))

    stack:AddChild(LDF.CreateSlider(section.content, {
        label = L["Primary Font Size"],
        tooltip = L["Size of the main text"],
        min = 8, max = 20, step = 1,
        get = function() return db.profile.appearance.fontSize end,
        set = function(value) db.profile.appearance.fontSize = value; NotifyAppearanceChange() end,
    }))

    stack:AddChild(LDF.CreateSlider(section.content, {
        label = L["Secondary Font Size"],
        tooltip = L["Size of secondary text"],
        min = 6, max = 16, step = 1,
        get = function() return db.profile.appearance.secondaryFontSize end,
        set = function(value)
            db.profile.appearance.secondaryFontSize = value
            NotifyAppearanceChange()
        end,
    }))

    stack:AddChild(LDF.CreateDropdown(section.content, {
        label = L["Font Outline"],
        tooltip = L["Outline style for text"],
        values = FONT_OUTLINE_VALUES,
        get = function() return db.profile.appearance.fontOutline end,
        set = function(value) db.profile.appearance.fontOutline = value; NotifyAppearanceChange() end,
    }))

    return section
end

local function CreateBackgroundSection(parent)
    local db = dtns.Addon.db
    local section = LDF.CreateSection(parent, L["Background"], { collapsible = true })
    local stack = LDF.CreateStackLayout(section.content, "vertical")

    stack:AddChild(LDF.CreateColorPicker(section.content, {
        label = L["Background Color"],
        tooltip = L["Toast background color"],
        hasAlpha = false,
        get = function()
            local c = db.profile.appearance.backgroundColor
            return c.r, c.g, c.b
        end,
        set = function(r, g, b)
            db.profile.appearance.backgroundColor.r = r
            db.profile.appearance.backgroundColor.g = g
            db.profile.appearance.backgroundColor.b = b
            NotifyAppearanceChange()
        end,
    }))

    stack:AddChild(LDF.CreateSlider(section.content, {
        label = L["Background Alpha"],
        tooltip = L["Opacity of the toast background"],
        min = 0, max = 1, step = 0.05, isPercent = true,
        get = function() return db.profile.appearance.backgroundAlpha end,
        set = function(value)
            db.profile.appearance.backgroundAlpha = value
            NotifyAppearanceChange()
        end,
    }))

    stack:AddChild(LDF.CreateDropdown(section.content, {
        label = L["Background Texture"],
        tooltip = L["Texture for the toast background"],
        values = function() return BuildLSMValues("background") end,
        mediaType = "background",
        get = function() return db.profile.appearance.backgroundTexture end,
        set = function(value)
            db.profile.appearance.backgroundTexture = value
            NotifyAppearanceChange()
        end,
    }))

    return section
end

local function CreateBorderSection(parent)
    local db = dtns.Addon.db
    local section = LDF.CreateSection(parent, L["Border and Glow"], { collapsible = true })
    local stack = LDF.CreateStackLayout(section.content, "vertical")

    stack:AddChild(LDF.CreateToggle(section.content, {
        label = L["Quality Border"],
        tooltip = L["Color the border based on item quality"],
        get = function() return db.profile.appearance.qualityBorder end,
        set = function(value) db.profile.appearance.qualityBorder = value; NotifyAppearanceChange() end,
    }))

    stack:AddChild(LDF.CreateSlider(section.content, {
        label = L["Border Size"],
        tooltip = L["Thickness of the toast border"],
        min = 0, max = 20, step = 1,
        get = function() return db.profile.appearance.borderSize end,
        set = function(value) db.profile.appearance.borderSize = value; NotifyAppearanceChange() end,
    }))

    stack:AddChild(LDF.CreateSlider(section.content, {
        label = L["Border Inset"],
        tooltip = L["Inset of the border from the toast edge"],
        min = 0, max = 20, step = 1,
        get = function() return db.profile.appearance.borderInset end,
        set = function(value) db.profile.appearance.borderInset = value; NotifyAppearanceChange() end,
    }))

    stack:AddChild(LDF.CreateDropdown(section.content, {
        label = L["Border Texture"],
        tooltip = L["Texture for the toast border"],
        values = function() return BuildLSMValues("border") end,
        mediaType = "border",
        get = function() return db.profile.appearance.borderTexture end,
        set = function(value)
            db.profile.appearance.borderTexture = value
            NotifyAppearanceChange()
        end,
    }))

    stack:AddChild(LDF.CreateToggle(section.content, {
        label = L["Quality Glow"],
        tooltip = L["Add a quality-colored glow effect"],
        get = function() return db.profile.appearance.qualityGlow end,
        set = function(value) db.profile.appearance.qualityGlow = value; NotifyAppearanceChange() end,
    }))

    return section
end

local function CreateGlowingBorderSection(parent)
    local db = dtns.Addon.db
    local section = LDF.CreateSection(parent, L["Glowing Border"], { collapsible = true })
    local stack = LDF.CreateStackLayout(section.content, "vertical")

    stack:AddChild(LDF.CreateDropdown(section.content, {
        label = L["Glow Texture"],
        tooltip = L["Texture for the glowing border"],
        values = function() return BuildLSMValues("statusbar") end,
        mediaType = "statusbar",
        get = function() return db.profile.appearance.statusBarTexture end,
        set = function(value)
            db.profile.appearance.statusBarTexture = value
            NotifyAppearanceChange()
        end,
    }))

    stack:AddChild(LDF.CreateSlider(section.content, {
        label = L["Glow Width"],
        tooltip = L["Width of the quality glow effect"],
        min = 0, max = 12, step = 1,
        get = function() return db.profile.appearance.glowWidth end,
        set = function(value) db.profile.appearance.glowWidth = value; NotifyAppearanceChange() end,
    }))

    return section
end

local function CreateIconSection(parent)
    local db = dtns.Addon.db
    local section = LDF.CreateSection(parent, L["Icon"])
    local stack = LDF.CreateStackLayout(section.content, "vertical")

    stack:AddChild(LDF.CreateSlider(section.content, {
        label = L["Icon Size"],
        tooltip = L["Size of the item icon on toasts"],
        min = 16, max = 64, step = 2,
        get = function() return db.profile.appearance.iconSize end,
        set = function(value) db.profile.appearance.iconSize = value; NotifyAppearanceChange() end,
    }))

    return section
end

-------------------------------------------------------------------------------
-- Build the Appearance tab content
-------------------------------------------------------------------------------

local function CreateContent(parent)
    dtns = ns.dtns
    local stack = LDF.CreateStackLayout(parent, "vertical")
    stack:AddChild(CreatePresetSection(parent))
    stack:AddChild(CreateFontSection(parent))
    stack:AddChild(CreateBackgroundSection(parent))
    stack:AddChild(CreateBorderSection(parent))
    stack:AddChild(CreateGlowingBorderSection(parent))
    stack:AddChild(CreateIconSection(parent))
end

-------------------------------------------------------------------------------
-- Register tab
-------------------------------------------------------------------------------

ns.Tabs = ns.Tabs or {}
ns.Tabs[#ns.Tabs + 1] = {
    id = "appearance",
    label = L["Appearance"],
    order = 5,
    createFunc = CreateContent,
}
