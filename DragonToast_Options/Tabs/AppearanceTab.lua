-------------------------------------------------------------------------------
-- AppearanceTab.lua
-- Appearance settings: preset, typography, background, border, glow, icon, integration
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
local appearanceControls = {}

local function RefreshDependencies()
    local profile = dtns.Addon.db.profile
    local appearance = profile.appearance
    local hasElvUI = dtns.ElvUISkin and dtns.ElvUISkin.IsElvUI and dtns.ElvUISkin.IsElvUI() or false
    local useElvUI = hasElvUI and profile.elvui and profile.elvui.useSkin
    local states = {
        borderColor = appearance.qualityBorder or useElvUI,
        borderAlpha = appearance.qualityBorder or useElvUI,
        qualityBorderAlpha = not appearance.qualityBorder,
        statusBarTexture = not appearance.qualityGlow,
        glowWidth = not appearance.qualityGlow,
        glowAlpha = not appearance.qualityGlow,
        elvui = not hasElvUI,
        fontFace = useElvUI,
    }
    for key, control in pairs(appearanceControls) do
        control:SetDisabled(not not states[key])
    end
end

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
    local values = { { value = "custom", text = L["Custom"] } }
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
    local section = W.CreateSection(parent, L["Preset"])
    local content = section.content
    local innerY = -LC.SECTION_PADDING_TOP

    local presetDropdown = W.CreateDropdown(content, {
        label = L["Skin Preset"],
        tooltip = L["Apply a preset appearance theme"],
        values = GetPresetValues,
        get = function() return dtns.Presets.DetectPreset() or "custom" end,
        set = function(value)
            if value == "custom" then return end
            dtns.Presets.ApplyPreset(value)
            if ns.RefreshVisibleWidgets then ns.RefreshVisibleWidgets() end
        end,
    })
    innerY = LC.AnchorWidget(presetDropdown, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    section:SetContentHeight(math_abs(innerY) + LC.SECTION_PADDING_BOTTOM)
    return LC.AnchorSection(section, parent, yOffset) - LC.SPACING_BETWEEN_SECTIONS
end

-- Builds the Font section UI inside the Appearance tab and returns the updated vertical offset.
-- @param parent The UI container to attach the section widgets to.
-- @param db Addon database table used for reading and writing appearance settings.
-- @param yOffset Current vertical offset from the top of `parent` where widgets should be anchored.
-- @return The updated vertical offset after placing the Font section.
local function CreateFontSection(parent, db, yOffset)
    local section = W.CreateSection(parent, L["Font"])
    local content = section.content
    local innerY = -LC.SECTION_PADDING_TOP

    local fontFace = W.CreateDropdown(content, {
        label = L["Font"],
        tooltip = L["Font face for toast text"],
        values = function() return LC.BuildLSMValues("font") end,
        mediaType = "font",
        get = function() return db.profile.appearance.fontFace end,
        set = function(value) db.profile.appearance.fontFace = value; LC.NotifyAppearanceChange() end,
    })
    appearanceControls.fontFace = fontFace
    innerY = LC.AnchorWidget(fontFace, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local fontSize = W.CreateSlider(content, {
        label = L["Primary Font Size"],
        tooltip = L["Size of the main text"],
        min = 8, max = 20, step = 1,
        get = function() return db.profile.appearance.fontSize end,
        set = function(value) db.profile.appearance.fontSize = value; LC.NotifyAppearanceChange() end,
    })
    innerY = LC.AnchorWidget(fontSize, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local secondaryFontSize = W.CreateSlider(content, {
        label = L["Secondary Font Size"],
        tooltip = L["Size of secondary text"],
        min = 6, max = 16, step = 1,
        get = function() return db.profile.appearance.secondaryFontSize end,
        set = function(value)
            db.profile.appearance.secondaryFontSize = value
            LC.NotifyAppearanceChange()
        end,
    })
    innerY = LC.AnchorWidget(secondaryFontSize, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local fontOutline = W.CreateDropdown(content, {
        label = L["Font Outline"],
        tooltip = L["Outline style for text"],
        values = FONT_OUTLINE_VALUES,
        get = function() return db.profile.appearance.fontOutline end,
        set = function(value) db.profile.appearance.fontOutline = value; LC.NotifyAppearanceChange() end,
    })
    innerY = LC.AnchorWidget(fontOutline, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    section:SetContentHeight(math_abs(innerY) + LC.SECTION_PADDING_BOTTOM)
    return LC.AnchorSection(section, parent, yOffset) - LC.SPACING_BETWEEN_SECTIONS
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
    local section = W.CreateSection(parent, L["Background"])
    local content = section.content
    local innerY = -LC.SECTION_PADDING_TOP

    local bgColor = W.CreateColorPicker(content, {
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
    innerY = LC.AnchorWidget(bgColor, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local bgAlpha = W.CreateSlider(content, {
        label = L["Background Alpha"],
        tooltip = L["Opacity of the toast background"],
        min = 0, max = 1, step = 0.05, isPercent = true,
        get = function() return db.profile.appearance.backgroundAlpha end,
        set = function(value)
            db.profile.appearance.backgroundAlpha = value
            LC.NotifyAppearanceChange()
        end,
    })
    innerY = LC.AnchorWidget(bgAlpha, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local bgTexture = W.CreateDropdown(content, {
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
    innerY = LC.AnchorWidget(bgTexture, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    section:SetContentHeight(math_abs(innerY) + LC.SECTION_PADDING_BOTTOM)
    return LC.AnchorSection(section, parent, yOffset) - LC.SPACING_BETWEEN_SECTIONS
end

-- Builds the "Border" section in the Appearance tab and lays out its controls.
-- @param parent UI container/frame to which the section widgets are attached.
-- @param db Addon database table (expects db.profile.appearance to exist and be writable).
-- @param yOffset Number vertical offset (in pixels) from the top where layout should start.
-- @return number The updated vertical offset after placing the section's widgets.
local function CreateBorderSection(parent, db, yOffset)
    local section = W.CreateSection(parent, L["Border"])
    local content = section.content
    local innerY = -LC.SECTION_PADDING_TOP

    local qualityBorder = W.CreateToggle(content, {
        label = L["Quality Border"],
        tooltip = L["Color the border based on item quality"],
        get = function() return db.profile.appearance.qualityBorder end,
        set = function(value)
            db.profile.appearance.qualityBorder = value
            RefreshDependencies()
            LC.NotifyAppearanceChange()
        end,
    })
    innerY = LC.AnchorWidget(qualityBorder, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local borderSize = W.CreateSlider(content, {
        label = L["Border Size"],
        tooltip = L["Thickness of the toast border"],
        min = 0, max = 20, step = 1,
        get = function() return db.profile.appearance.borderSize end,
        set = function(value) db.profile.appearance.borderSize = value; LC.NotifyAppearanceChange() end,
    })
    innerY = LC.AnchorWidget(borderSize, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local borderInset = W.CreateSlider(content, {
        label = L["Border Inset"],
        tooltip = L["Inset of the border from the toast edge"],
        min = 0, max = 20, step = 1,
        get = function() return db.profile.appearance.borderInset end,
        set = function(value) db.profile.appearance.borderInset = value; LC.NotifyAppearanceChange() end,
    })
    innerY = LC.AnchorWidget(borderInset, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local borderTexture = W.CreateDropdown(content, {
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
    innerY = LC.AnchorWidget(borderTexture, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local borderColor = W.CreateColorPicker(content, {
        label = L["Border Color"],
        tooltip = L["Border color when quality coloring and ElvUI matching are off"],
        hasAlpha = false,
        get = function()
            local c = db.profile.appearance.borderColor or { r = 0.3, g = 0.3, b = 0.3 }
            return c.r, c.g, c.b
        end,
        set = function(r, g, b)
            db.profile.appearance.borderColor = { r = r, g = g, b = b }
            LC.NotifyAppearanceChange()
        end,
    })
    appearanceControls.borderColor = borderColor
    innerY = LC.AnchorWidget(borderColor, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local borderAlpha = W.CreateSlider(content, {
        label = L["Border Opacity"],
        tooltip = L["Opacity of the border when quality coloring is off"],
        min = 0, max = 1, step = 0.05, isPercent = true,
        get = function() return db.profile.appearance.borderAlpha or 0.8 end,
        set = function(value) db.profile.appearance.borderAlpha = value; LC.NotifyAppearanceChange() end,
    })
    appearanceControls.borderAlpha = borderAlpha
    innerY = LC.AnchorWidget(borderAlpha, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local qualityBorderAlpha = W.CreateSlider(content, {
        label = L["Quality Border Opacity"],
        tooltip = L["Opacity of borders colored by item quality or reward type"],
        min = 0, max = 1, step = 0.05, isPercent = true,
        get = function() return db.profile.appearance.qualityBorderAlpha or 0.6 end,
        set = function(value) db.profile.appearance.qualityBorderAlpha = value; LC.NotifyAppearanceChange() end,
    })
    appearanceControls.qualityBorderAlpha = qualityBorderAlpha
    innerY = LC.AnchorWidget(qualityBorderAlpha, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    section:SetContentHeight(math_abs(innerY) + LC.SECTION_PADDING_BOTTOM)
    return LC.AnchorSection(section, parent, yOffset) - LC.SPACING_BETWEEN_SECTIONS
end

-- Creates the Glow section in the Appearance tab and returns the updated vertical offset.
-- @param parent The parent UI frame to attach the section's widgets to.
-- @param db The addon's database table; the function reads and writes values under `db.profile.appearance`.
-- @param yOffset The starting vertical offset (number) where the section should be placed.
-- @return The updated vertical offset after placing the section's widgets.
local function CreateGlowingBorderSection(parent, db, yOffset)
    local section = W.CreateSection(parent, L["Glow"])
    local content = section.content
    local innerY = -LC.SECTION_PADDING_TOP

    local qualityGlow = W.CreateToggle(content, {
        label = L["Quality Glow"],
        tooltip = L["Add a quality-colored glow effect"],
        get = function() return db.profile.appearance.qualityGlow end,
        set = function(value)
            db.profile.appearance.qualityGlow = value
            RefreshDependencies()
            LC.NotifyAppearanceChange()
        end,
    })
    innerY = LC.AnchorWidget(qualityGlow, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local statusBarTexture = W.CreateDropdown(content, {
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
    appearanceControls.statusBarTexture = statusBarTexture
    innerY = LC.AnchorWidget(statusBarTexture, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local glowWidth = W.CreateSlider(content, {
        label = L["Glow Width"],
        tooltip = L["Width of the quality glow effect"],
        min = 0, max = 12, step = 1,
        get = function() return db.profile.appearance.glowWidth end,
        set = function(value) db.profile.appearance.glowWidth = value; LC.NotifyAppearanceChange() end,
    })
    appearanceControls.glowWidth = glowWidth
    innerY = LC.AnchorWidget(glowWidth, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local glowAlpha = W.CreateSlider(content, {
        label = L["Glow Opacity"],
        tooltip = L["Opacity of the quality-colored glow"],
        min = 0, max = 1, step = 0.05, isPercent = true,
        get = function() return db.profile.appearance.glowAlpha or 0.8 end,
        set = function(value) db.profile.appearance.glowAlpha = value; LC.NotifyAppearanceChange() end,
    })
    appearanceControls.glowAlpha = glowAlpha
    innerY = LC.AnchorWidget(glowAlpha, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    section:SetContentHeight(math_abs(innerY) + LC.SECTION_PADDING_BOTTOM)
    return LC.AnchorSection(section, parent, yOffset) - LC.SPACING_BETWEEN_SECTIONS
end

-- Texture crop is independent of the icon size on the Layout page.
local function CreateIconSection(parent, db, yOffset)
    local section = W.CreateSection(parent, L["Icon"])
    local content = section.content
    local innerY = -LC.SECTION_PADDING_TOP

    local iconCrop = W.CreateSlider(content, {
        label = L["Icon Crop"],
        tooltip = L["Amount trimmed from each edge of the icon"],
        min = 0, max = 0.25, step = 0.01, isPercent = true,
        get = function() return db.profile.appearance.iconCrop or 0.08 end,
        set = function(value) db.profile.appearance.iconCrop = value; LC.NotifyAppearanceChange() end,
    })
    innerY = LC.AnchorWidget(iconCrop, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    section:SetContentHeight(math_abs(innerY) + LC.SECTION_PADDING_BOTTOM)
    return LC.AnchorSection(section, parent, yOffset) - LC.SPACING_BETWEEN_SECTIONS
end

local function CreateIntegrationSection(parent, db, yOffset)
    local section = W.CreateSection(parent, L["Integration"])
    local content = section.content
    local innerY = -LC.SECTION_PADDING_TOP

    local elvui = W.CreateToggle(content, {
        label = L["Match ElvUI Style"],
        tooltip = L["Use ElvUI fonts and border colors when ElvUI is loaded"],
        get = function() return db.profile.elvui and db.profile.elvui.useSkin == true end,
        set = function(value)
            db.profile.elvui.useSkin = value
            RefreshDependencies()
            LC.NotifyAppearanceChange()
        end,
    })
    appearanceControls.elvui = elvui
    innerY = LC.AnchorWidget(elvui, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    section:SetContentHeight(math_abs(innerY) + LC.SECTION_PADDING_BOTTOM)
    return LC.AnchorSection(section, parent, yOffset) - LC.SPACING_BETWEEN_SECTIONS
end

-------------------------------------------------------------------------------
-- Build the Appearance tab content
-------------------------------------------------------------------------------

local function CreateContent(parent)
    dtns = ns.dtns
    local db = dtns.Addon.db
    appearanceControls = {}
    local yOffset = LC.PADDING_TOP

    yOffset = CreatePresetSection(parent, yOffset)
    yOffset = CreateFontSection(parent, db, yOffset)
    yOffset = CreateBackgroundSection(parent, db, yOffset)
    yOffset = CreateBorderSection(parent, db, yOffset)
    yOffset = CreateGlowingBorderSection(parent, db, yOffset)
    yOffset = CreateIconSection(parent, db, yOffset)
    yOffset = CreateIntegrationSection(parent, db, yOffset)
    RefreshDependencies()

    parent:SetHeight(math_abs(yOffset) + LC.PADDING_BOTTOM)
end

-------------------------------------------------------------------------------
-- Register tab
-------------------------------------------------------------------------------

ns.Tabs[#ns.Tabs + 1] = {
    id = "appearance",
    label = L["Appearance"],
    order = 4,
    createFunc = CreateContent,
    refreshFunc = RefreshDependencies,
}
