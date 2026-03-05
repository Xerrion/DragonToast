-------------------------------------------------------------------------------
-- AppearanceTab.lua
-- Appearance settings tab: preset, font, background, border, glow, icon
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

-------------------------------------------------------------------------------
-- Cached globals
-------------------------------------------------------------------------------

local math_abs = math.abs
local pairs = pairs
local ipairs = ipairs
local table_sort = table.sort

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

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------

local function AnchorWidget(widget, parent, yOffset)
    widget:SetPoint("TOPLEFT", parent, "TOPLEFT", PADDING_SIDE, yOffset)
    widget:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -PADDING_SIDE, yOffset)
end

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
    { value = "", text = "None" },
    { value = "OUTLINE", text = "Outline" },
    { value = "THICKOUTLINE", text = "Thick Outline" },
    { value = "MONOCHROME, OUTLINE", text = "Monochrome" },
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

local function CreatePresetSection(parent, _db, yOffset)
    local W = ns.Widgets
    local header = W.CreateHeader(parent, "Preset")
    AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - SPACING_AFTER_HEADER

    local presetDropdown = W.CreateDropdown(parent, {
        label = "Skin Preset",
        tooltip = "Apply a preset appearance theme",
        values = GetPresetValues,
        get = function() return dtns.Presets:DetectPreset() or "default" end,
        set = function(value)
            dtns.Presets:ApplyPreset(value)
            ns.RefreshVisibleWidgets()
        end,
    })
    AnchorWidget(presetDropdown, parent, yOffset)
    yOffset = yOffset - presetDropdown:GetHeight()

    return yOffset
end

local function CreateFontSection(parent, db, yOffset)
    local W = ns.Widgets
    yOffset = yOffset - SPACING_BETWEEN_SECTIONS

    local header = W.CreateHeader(parent, "Font")
    AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - SPACING_AFTER_HEADER

    local fontFace = W.CreateDropdown(parent, {
        label = "Font",
        tooltip = "Font face for toast text",
        values = function() return BuildLSMValues("font") end,
        mediaType = "font",
        get = function() return db.profile.appearance.fontFace end,
        set = function(value) db.profile.appearance.fontFace = value; NotifyAppearanceChange() end,
    })
    AnchorWidget(fontFace, parent, yOffset)
    yOffset = yOffset - fontFace:GetHeight() - SPACING_BETWEEN_WIDGETS

    local fontSize = W.CreateSlider(parent, {
        label = "Primary Font Size",
        tooltip = "Size of the main text",
        min = 8, max = 20, step = 1,
        get = function() return db.profile.appearance.fontSize end,
        set = function(value) db.profile.appearance.fontSize = value; NotifyAppearanceChange() end,
    })
    AnchorWidget(fontSize, parent, yOffset)
    yOffset = yOffset - fontSize:GetHeight() - SPACING_BETWEEN_WIDGETS

    local secondaryFontSize = W.CreateSlider(parent, {
        label = "Secondary Font Size",
        tooltip = "Size of secondary text",
        min = 6, max = 16, step = 1,
        get = function() return db.profile.appearance.secondaryFontSize end,
        set = function(value)
            db.profile.appearance.secondaryFontSize = value
            NotifyAppearanceChange()
        end,
    })
    AnchorWidget(secondaryFontSize, parent, yOffset)
    yOffset = yOffset - secondaryFontSize:GetHeight() - SPACING_BETWEEN_WIDGETS

    local fontOutline = W.CreateDropdown(parent, {
        label = "Font Outline",
        tooltip = "Outline style for text",
        values = FONT_OUTLINE_VALUES,
        get = function() return db.profile.appearance.fontOutline end,
        set = function(value) db.profile.appearance.fontOutline = value; NotifyAppearanceChange() end,
    })
    AnchorWidget(fontOutline, parent, yOffset)
    yOffset = yOffset - fontOutline:GetHeight()

    return yOffset
end

local function CreateBackgroundSection(parent, db, yOffset)
    local W = ns.Widgets
    yOffset = yOffset - SPACING_BETWEEN_SECTIONS

    local header = W.CreateHeader(parent, "Background")
    AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - SPACING_AFTER_HEADER

    local bgColor = W.CreateColorPicker(parent, {
        label = "Background Color",
        tooltip = "Toast background color",
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
    })
    AnchorWidget(bgColor, parent, yOffset)
    yOffset = yOffset - bgColor:GetHeight() - SPACING_BETWEEN_WIDGETS

    local bgAlpha = W.CreateSlider(parent, {
        label = "Background Alpha",
        tooltip = "Opacity of the toast background",
        min = 0, max = 1, step = 0.05, isPercent = true,
        get = function() return db.profile.appearance.backgroundAlpha end,
        set = function(value)
            db.profile.appearance.backgroundAlpha = value
            NotifyAppearanceChange()
        end,
    })
    AnchorWidget(bgAlpha, parent, yOffset)
    yOffset = yOffset - bgAlpha:GetHeight() - SPACING_BETWEEN_WIDGETS

    local bgTexture = W.CreateDropdown(parent, {
        label = "Background Texture",
        tooltip = "Texture for the toast background",
        values = function() return BuildLSMValues("background") end,
        mediaType = "background",
        get = function() return db.profile.appearance.backgroundTexture end,
        set = function(value)
            db.profile.appearance.backgroundTexture = value
            NotifyAppearanceChange()
        end,
    })
    AnchorWidget(bgTexture, parent, yOffset)
    yOffset = yOffset - bgTexture:GetHeight()

    return yOffset
end

local function CreateBorderSection(parent, db, yOffset)
    local W = ns.Widgets
    yOffset = yOffset - SPACING_BETWEEN_SECTIONS

    local header = W.CreateHeader(parent, "Border and Glow")
    AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - SPACING_AFTER_HEADER

    local qualityBorder = W.CreateToggle(parent, {
        label = "Quality Border",
        tooltip = "Color the border based on item quality",
        get = function() return db.profile.appearance.qualityBorder end,
        set = function(value) db.profile.appearance.qualityBorder = value; NotifyAppearanceChange() end,
    })
    AnchorWidget(qualityBorder, parent, yOffset)
    yOffset = yOffset - qualityBorder:GetHeight() - SPACING_BETWEEN_WIDGETS

    local borderSize = W.CreateSlider(parent, {
        label = "Border Size",
        tooltip = "Thickness of the toast border",
        min = 0, max = 20, step = 1,
        get = function() return db.profile.appearance.borderSize end,
        set = function(value) db.profile.appearance.borderSize = value; NotifyAppearanceChange() end,
    })
    AnchorWidget(borderSize, parent, yOffset)
    yOffset = yOffset - borderSize:GetHeight() - SPACING_BETWEEN_WIDGETS

    local borderInset = W.CreateSlider(parent, {
        label = "Border Inset",
        tooltip = "Inset of the border from the toast edge",
        min = 0, max = 20, step = 1,
        get = function() return db.profile.appearance.borderInset end,
        set = function(value) db.profile.appearance.borderInset = value; NotifyAppearanceChange() end,
    })
    AnchorWidget(borderInset, parent, yOffset)
    yOffset = yOffset - borderInset:GetHeight() - SPACING_BETWEEN_WIDGETS

    local borderTexture = W.CreateDropdown(parent, {
        label = "Border Texture",
        tooltip = "Texture for the toast border",
        values = function() return BuildLSMValues("border") end,
        mediaType = "border",
        get = function() return db.profile.appearance.borderTexture end,
        set = function(value)
            db.profile.appearance.borderTexture = value
            NotifyAppearanceChange()
        end,
    })
    AnchorWidget(borderTexture, parent, yOffset)
    yOffset = yOffset - borderTexture:GetHeight() - SPACING_BETWEEN_WIDGETS

    local qualityGlow = W.CreateToggle(parent, {
        label = "Quality Glow",
        tooltip = "Add a quality-colored glow effect",
        get = function() return db.profile.appearance.qualityGlow end,
        set = function(value) db.profile.appearance.qualityGlow = value; NotifyAppearanceChange() end,
    })
    AnchorWidget(qualityGlow, parent, yOffset)
    yOffset = yOffset - qualityGlow:GetHeight()

    return yOffset
end

local function CreateGlowingBorderSection(parent, db, yOffset)
    local W = ns.Widgets
    yOffset = yOffset - SPACING_BETWEEN_SECTIONS

    local header = W.CreateHeader(parent, "Glowing Border")
    AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - SPACING_AFTER_HEADER

    local statusBarTexture = W.CreateDropdown(parent, {
        label = "Glow Texture",
        tooltip = "Texture for the glowing border",
        values = function() return BuildLSMValues("statusbar") end,
        mediaType = "statusbar",
        get = function() return db.profile.appearance.statusBarTexture end,
        set = function(value)
            db.profile.appearance.statusBarTexture = value
            NotifyAppearanceChange()
        end,
    })
    AnchorWidget(statusBarTexture, parent, yOffset)
    yOffset = yOffset - statusBarTexture:GetHeight() - SPACING_BETWEEN_WIDGETS

    local glowWidth = W.CreateSlider(parent, {
        label = "Glow Width",
        tooltip = "Width of the quality glow effect",
        min = 0, max = 12, step = 1,
        get = function() return db.profile.appearance.glowWidth end,
        set = function(value) db.profile.appearance.glowWidth = value; NotifyAppearanceChange() end,
    })
    AnchorWidget(glowWidth, parent, yOffset)
    yOffset = yOffset - glowWidth:GetHeight()

    return yOffset
end

local function CreateIconSection(parent, db, yOffset)
    local W = ns.Widgets
    yOffset = yOffset - SPACING_BETWEEN_SECTIONS

    local header = W.CreateHeader(parent, "Icon")
    AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - SPACING_AFTER_HEADER

    local iconSize = W.CreateSlider(parent, {
        label = "Icon Size",
        tooltip = "Size of the item icon on toasts",
        min = 16, max = 64, step = 2,
        get = function() return db.profile.appearance.iconSize end,
        set = function(value) db.profile.appearance.iconSize = value; NotifyAppearanceChange() end,
    })
    AnchorWidget(iconSize, parent, yOffset)
    yOffset = yOffset - iconSize:GetHeight()

    return yOffset
end

-------------------------------------------------------------------------------
-- Build the Appearance tab content
-------------------------------------------------------------------------------

local function CreateContent(parent)
    dtns = ns.dtns
    local db = dtns.Addon.db
    local yOffset = PADDING_TOP

    yOffset = CreatePresetSection(parent, db, yOffset)
    yOffset = CreateFontSection(parent, db, yOffset)
    yOffset = CreateBackgroundSection(parent, db, yOffset)
    yOffset = CreateBorderSection(parent, db, yOffset)
    yOffset = CreateGlowingBorderSection(parent, db, yOffset)
    yOffset = CreateIconSection(parent, db, yOffset)

    parent:SetHeight(math_abs(yOffset) + PADDING_BOTTOM)
end

-------------------------------------------------------------------------------
-- Register tab
-------------------------------------------------------------------------------

ns.Tabs = ns.Tabs or {}
ns.Tabs[#ns.Tabs + 1] = {
    id = "appearance",
    label = "Appearance",
    order = 5,
    createFunc = CreateContent,
}
