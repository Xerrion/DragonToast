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
local ipairs = ipairs

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
-- Static tables
-------------------------------------------------------------------------------

local FONT_OUTLINE_VALUES = {
    { value = "", text = L["None"] },
    { value = "OUTLINE", text = L["Outline"] },
    { value = "THICKOUTLINE", text = L["Thick Outline"] },
    { value = "MONOCHROME, OUTLINE", text = L["Monochrome Outline"] },
}

-- Builds a list of available appearance presets.
-- @return An array of tables where each entry has `value` (preset key) and `text` (preset display name).
local function GetPresetValues()
    local values = {}
    for _, key in ipairs(dtns.Presets.order) do
        values[#values + 1] = { value = key, text = dtns.Presets.names[key] }
    end
    return values
end

-------------------------------------------------------------------------------
-- Section builders
-- Creates the Preset section in the Appearance tab and anchors it at the specified vertical offset.
-- @param parent The UI container/frame to attach the section to.
-- @param yOffset The starting vertical offset (pixels) from the top; adjusted downward as widgets are placed.
-- @return The updated vertical offset (pixels) after the preset section has been added.

local function CreatePresetSection(parent, yOffset)
    local header = W.CreateHeader(parent, L["Preset"])
    LC.AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - LC.SPACING_AFTER_HEADER

    local presetDropdown = W.CreateDropdown(parent, {
        label = L["Skin Preset"],
        tooltip = L["Apply a preset appearance theme"],
        values = GetPresetValues,
        get = function() return dtns.Presets:DetectPreset() or "default" end,
        set = function(value)
            dtns.Presets:ApplyPreset(value)
            if ns.RefreshVisibleWidgets then ns.RefreshVisibleWidgets() end
        end,
    })
    LC.AnchorWidget(presetDropdown, parent, yOffset)
    yOffset = yOffset - presetDropdown:GetHeight()

    return yOffset
end

-- Builds the Font section UI inside the Appearance tab and returns the updated vertical offset.
-- @param parent The UI container to attach the section widgets to.
-- @param db Addon database table used for reading and writing appearance settings.
-- @param yOffset Current vertical offset from the top of `parent` where widgets should be anchored.
-- @return The updated vertical offset after placing the Font section.
local function CreateFontSection(parent, db, yOffset)
    yOffset = yOffset - LC.SPACING_BETWEEN_SECTIONS

    local header = W.CreateHeader(parent, L["Font"])
    LC.AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - LC.SPACING_AFTER_HEADER

    local fontFace = W.CreateDropdown(parent, {
        label = L["Font"],
        tooltip = L["Font face for toast text"],
        values = function() return LC.BuildLSMValues("font") end,
        mediaType = "font",
        get = function() return db.profile.appearance.fontFace end,
        set = function(value) db.profile.appearance.fontFace = value; LC.NotifyAppearanceChange() end,
    })
    LC.AnchorWidget(fontFace, parent, yOffset)
    yOffset = yOffset - fontFace:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

    local fontSize = W.CreateSlider(parent, {
        label = L["Primary Font Size"],
        tooltip = L["Size of the main text"],
        min = 8, max = 20, step = 1,
        get = function() return db.profile.appearance.fontSize end,
        set = function(value) db.profile.appearance.fontSize = value; LC.NotifyAppearanceChange() end,
    })
    LC.AnchorWidget(fontSize, parent, yOffset)
    yOffset = yOffset - fontSize:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

    local secondaryFontSize = W.CreateSlider(parent, {
        label = L["Secondary Font Size"],
        tooltip = L["Size of secondary text"],
        min = 6, max = 16, step = 1,
        get = function() return db.profile.appearance.secondaryFontSize end,
        set = function(value)
            db.profile.appearance.secondaryFontSize = value
            LC.NotifyAppearanceChange()
        end,
    })
    LC.AnchorWidget(secondaryFontSize, parent, yOffset)
    yOffset = yOffset - secondaryFontSize:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

    local fontOutline = W.CreateDropdown(parent, {
        label = L["Font Outline"],
        tooltip = L["Outline style for text"],
        values = FONT_OUTLINE_VALUES,
        get = function() return db.profile.appearance.fontOutline end,
        set = function(value) db.profile.appearance.fontOutline = value; LC.NotifyAppearanceChange() end,
    })
    LC.AnchorWidget(fontOutline, parent, yOffset)
    yOffset = yOffset - fontOutline:GetHeight()

    return yOffset
end

-- Creates the "Background" subsection of the Appearance tab, adding
-- color, alpha, and texture controls and returning the updated vertical
-- offset.
-- @param parent The parent UI frame to attach the section's widgets to.
-- @param db Addon database table (expects db.profile.appearance to exist and be writable).
-- @param yOffset The starting vertical offset (in pixels) where the
--   section will be anchored; widgets are laid out downward from this
--   value.
-- @return number The updated vertical offset after placing the section's widgets.
local function CreateBackgroundSection(parent, db, yOffset)
    yOffset = yOffset - LC.SPACING_BETWEEN_SECTIONS

    local header = W.CreateHeader(parent, L["Background"])
    LC.AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - LC.SPACING_AFTER_HEADER

    local bgColor = W.CreateColorPicker(parent, {
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
            LC.NotifyAppearanceChange()
        end,
    })
    LC.AnchorWidget(bgColor, parent, yOffset)
    yOffset = yOffset - bgColor:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

    local bgAlpha = W.CreateSlider(parent, {
        label = L["Background Alpha"],
        tooltip = L["Opacity of the toast background"],
        min = 0, max = 1, step = 0.05, isPercent = true,
        get = function() return db.profile.appearance.backgroundAlpha end,
        set = function(value)
            db.profile.appearance.backgroundAlpha = value
            LC.NotifyAppearanceChange()
        end,
    })
    LC.AnchorWidget(bgAlpha, parent, yOffset)
    yOffset = yOffset - bgAlpha:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

    local bgTexture = W.CreateDropdown(parent, {
        label = L["Background Texture"],
        tooltip = L["Texture for the toast background"],
        values = function() return LC.BuildLSMValues("background") end,
        mediaType = "background",
        get = function() return db.profile.appearance.backgroundTexture end,
        set = function(value)
            db.profile.appearance.backgroundTexture = value
            LC.NotifyAppearanceChange()
        end,
    })
    LC.AnchorWidget(bgTexture, parent, yOffset)
    yOffset = yOffset - bgTexture:GetHeight()

    return yOffset
end

-- Builds the "Border and Glow" section in the Appearance tab and lays out its controls.
-- @param parent UI container/frame to which the section widgets are attached.
-- @param db Addon database table (expects db.profile.appearance to exist and be writable).
-- @param yOffset Number vertical offset (in pixels) from the top where layout should start.
-- @return number The updated vertical offset after placing the section's widgets.
local function CreateBorderSection(parent, db, yOffset)
    yOffset = yOffset - LC.SPACING_BETWEEN_SECTIONS

    local header = W.CreateHeader(parent, L["Border and Glow"])
    LC.AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - LC.SPACING_AFTER_HEADER

    local qualityBorder = W.CreateToggle(parent, {
        label = L["Quality Border"],
        tooltip = L["Color the border based on item quality"],
        get = function() return db.profile.appearance.qualityBorder end,
        set = function(value) db.profile.appearance.qualityBorder = value; LC.NotifyAppearanceChange() end,
    })
    LC.AnchorWidget(qualityBorder, parent, yOffset)
    yOffset = yOffset - qualityBorder:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

    local borderSize = W.CreateSlider(parent, {
        label = L["Border Size"],
        tooltip = L["Thickness of the toast border"],
        min = 0, max = 20, step = 1,
        get = function() return db.profile.appearance.borderSize end,
        set = function(value) db.profile.appearance.borderSize = value; LC.NotifyAppearanceChange() end,
    })
    LC.AnchorWidget(borderSize, parent, yOffset)
    yOffset = yOffset - borderSize:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

    local borderInset = W.CreateSlider(parent, {
        label = L["Border Inset"],
        tooltip = L["Inset of the border from the toast edge"],
        min = 0, max = 20, step = 1,
        get = function() return db.profile.appearance.borderInset end,
        set = function(value) db.profile.appearance.borderInset = value; LC.NotifyAppearanceChange() end,
    })
    LC.AnchorWidget(borderInset, parent, yOffset)
    yOffset = yOffset - borderInset:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

    local borderTexture = W.CreateDropdown(parent, {
        label = L["Border Texture"],
        tooltip = L["Texture for the toast border"],
        values = function() return LC.BuildLSMValues("border") end,
        mediaType = "border",
        get = function() return db.profile.appearance.borderTexture end,
        set = function(value)
            db.profile.appearance.borderTexture = value
            LC.NotifyAppearanceChange()
        end,
    })
    LC.AnchorWidget(borderTexture, parent, yOffset)
    yOffset = yOffset - borderTexture:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

    local qualityGlow = W.CreateToggle(parent, {
        label = L["Quality Glow"],
        tooltip = L["Add a quality-colored glow effect"],
        get = function() return db.profile.appearance.qualityGlow end,
        set = function(value) db.profile.appearance.qualityGlow = value; LC.NotifyAppearanceChange() end,
    })
    LC.AnchorWidget(qualityGlow, parent, yOffset)
    yOffset = yOffset - qualityGlow:GetHeight()

    return yOffset
end

-- Creates the Glowing Border section in the Appearance tab and returns the updated vertical offset.
-- @param parent The parent UI frame to attach the section's widgets to.
-- @param db The addon's database table; the function reads and writes values under `db.profile.appearance`.
-- @param yOffset The starting vertical offset (number) where the section should be placed.
-- @return The updated vertical offset after placing the section's widgets.
local function CreateGlowingBorderSection(parent, db, yOffset)
    yOffset = yOffset - LC.SPACING_BETWEEN_SECTIONS

    local header = W.CreateHeader(parent, L["Glowing Border"])
    LC.AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - LC.SPACING_AFTER_HEADER

    local statusBarTexture = W.CreateDropdown(parent, {
        label = L["Glow Texture"],
        tooltip = L["Texture for the glowing border"],
        values = function() return LC.BuildLSMValues("statusbar") end,
        mediaType = "statusbar",
        get = function() return db.profile.appearance.statusBarTexture end,
        set = function(value)
            db.profile.appearance.statusBarTexture = value
            LC.NotifyAppearanceChange()
        end,
    })
    LC.AnchorWidget(statusBarTexture, parent, yOffset)
    yOffset = yOffset - statusBarTexture:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

    local glowWidth = W.CreateSlider(parent, {
        label = L["Glow Width"],
        tooltip = L["Width of the quality glow effect"],
        min = 0, max = 12, step = 1,
        get = function() return db.profile.appearance.glowWidth end,
        set = function(value) db.profile.appearance.glowWidth = value; LC.NotifyAppearanceChange() end,
    })
    LC.AnchorWidget(glowWidth, parent, yOffset)
    yOffset = yOffset - glowWidth:GetHeight()

    return yOffset
end

-- Creates the "Icon" appearance section on the given parent and places
-- an icon size slider bound to the appearance settings.
-- @param parent UI frame that will contain the section.
-- @param db Addon database; the slider reads and updates
--   db.profile.appearance.iconSize.
-- @param yOffset Starting vertical offset (pixels) from the parent's
--   top; the function positions widgets relative to this value.
-- @return The updated vertical offset after adding the section's widgets.
local function CreateIconSection(parent, db, yOffset)
    yOffset = yOffset - LC.SPACING_BETWEEN_SECTIONS

    local header = W.CreateHeader(parent, L["Icon"])
    LC.AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - LC.SPACING_AFTER_HEADER

    local iconSize = W.CreateSlider(parent, {
        label = L["Icon Size"],
        tooltip = L["Size of the item icon on toasts"],
        min = 16, max = 64, step = 2,
        get = function() return db.profile.appearance.iconSize end,
        set = function(value) db.profile.appearance.iconSize = value; LC.NotifyAppearanceChange() end,
    })
    LC.AnchorWidget(iconSize, parent, yOffset)
    yOffset = yOffset - iconSize:GetHeight()

    return yOffset
end

-------------------------------------------------------------------------------
-- Build the Appearance tab content
-------------------------------------------------------------------------------

local function CreateContent(parent)
    dtns = ns.dtns
    local db = dtns.Addon.db
    local yOffset = LC.PADDING_TOP

    yOffset = CreatePresetSection(parent, yOffset)
    yOffset = CreateFontSection(parent, db, yOffset)
    yOffset = CreateBackgroundSection(parent, db, yOffset)
    yOffset = CreateBorderSection(parent, db, yOffset)
    yOffset = CreateGlowingBorderSection(parent, db, yOffset)
    yOffset = CreateIconSection(parent, db, yOffset)

    parent:SetHeight(math_abs(yOffset) + LC.PADDING_BOTTOM)
end

-------------------------------------------------------------------------------
-- Register tab
-------------------------------------------------------------------------------

ns.Tabs[#ns.Tabs + 1] = {
    id = "appearance",
    label = L["Appearance"],
    order = 5,
    createFunc = CreateContent,
}
