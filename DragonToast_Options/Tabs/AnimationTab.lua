-------------------------------------------------------------------------------
-- AnimationTab.lua
-- Animation settings tab: entrance, hold, exit, slide, attention animations
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...
local LC = ns.LayoutConstants

-------------------------------------------------------------------------------
-- Cached globals
-------------------------------------------------------------------------------

local math_abs = math.abs
local ipairs = ipairs
local pairs = pairs
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
-- Create a list of dropdown option tables for animations returned by the specified LibAnimate method.
-- @param methodName The method name on LibAnimate to call (e.g., "GetEntranceAnimations").
-- @return A list of tables each containing `value` and `text` for a
--   dropdown; the first entry is
--   `{ value = "none", text = L["NONE"] }`.

local function BuildAnimationValues(methodName)
    local lib = LibStub("LibAnimate", true)
    if not lib then return {} end

    local names = lib[methodName](lib)
    local values = { { value = "none", text = L["NONE"] } }
    for _, name in ipairs(names) do
        values[#values + 1] = { value = name, text = name }
    end
    return values
end

local function GetEntranceAnimationValues()
    return BuildAnimationValues("GetEntranceAnimations")
end

local function GetExitAnimationValues()
    return BuildAnimationValues("GetExitAnimations")
end

local function GetAttentionAnimationValues()
    return BuildAnimationValues("GetAttentionAnimations")
end

local function UpdateAttentionDisabledState(enableToggle, attentionDropdown, widgets)
    local disabled = not enableToggle:GetValue() or attentionDropdown:GetValue() == "none"
    for _, w in pairs(widgets) do
        w:SetDisabled(disabled)
    end
end

-------------------------------------------------------------------------------
-- Section builders
-- Create the "Animation" section UI and its enable toggle.
-- Updates `attentionState.enableToggle` and wires the toggle to enable/disable attention widgets.
-- @param parent UI container to which widgets will be added.
-- @param yOffset Number vertical offset (pixels) where the section should start; adjusted as widgets are anchored.
-- @param attentionState Table with optional fields `dropdown` and `widgets` used to manage the Attention subsection.
-- @return number The updated vertical offset after placing the section's widgets.

local function CreateAnimationSection(parent, yOffset, attentionState)
    local W = ns.Widgets
    local db = dtns.Addon.db

    local header = W.CreateHeader(parent, L["TAB_ANIMATION"])
    LC.AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - LC.SPACING_AFTER_HEADER

    local enableToggle = W.CreateToggle(parent, {
        label = L["ENABLE_ANIMATIONS"],
        tooltip = L["TOOLTIP_ENABLE_ANIMATIONS"],
        get = function() return db.profile.animation.enableAnimations end,
        set = function(value)
            db.profile.animation.enableAnimations = value
            if attentionState.dropdown then
                UpdateAttentionDisabledState(attentionState.enableToggle, attentionState.dropdown,
                    attentionState.widgets)
            end
        end,
    })
    LC.AnchorWidget(enableToggle, parent, yOffset)
    yOffset = yOffset - enableToggle:GetHeight()

    attentionState.enableToggle = enableToggle

    return yOffset
end

-- Creates the "Entrance" section in the animation options and adds its widgets to the given parent.
-- @param parent The UI container/frame to which the section's widgets will be anchored.
-- @param yOffset The current vertical offset (y) used to position
--   widgets; will be adjusted downward as widgets are added.
-- @return The updated vertical offset after placing the section's header and widgets.
local function CreateEntranceSection(parent, yOffset)
    local W = ns.Widgets
    local db = dtns.Addon.db

    yOffset = yOffset - LC.SPACING_BETWEEN_SECTIONS

    local header = W.CreateHeader(parent, L["HEADER_ENTRANCE"])
    LC.AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - LC.SPACING_AFTER_HEADER

    local duration = W.CreateSlider(parent, {
        label = L["ENTRANCE_DURATION"],
        tooltip = L["TOOLTIP_ENTRANCE_DURATION"],
        min = 0.1, max = 1.0, step = 0.05,
        get = function() return db.profile.animation.entranceDuration end,
        set = function(value) db.profile.animation.entranceDuration = value end,
    })
    LC.AnchorWidget(duration, parent, yOffset)
    yOffset = yOffset - duration:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

    local animation = W.CreateDropdown(parent, {
        label = L["ENTRANCE_ANIMATION"],
        tooltip = L["TOOLTIP_ENTRANCE_ANIMATION"],
        values = GetEntranceAnimationValues,
        get = function() return db.profile.animation.entranceAnimation end,
        set = function(value) db.profile.animation.entranceAnimation = value end,
    })
    LC.AnchorWidget(animation, parent, yOffset)
    yOffset = yOffset - animation:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

    local distance = W.CreateSlider(parent, {
        label = L["ENTRANCE_DISTANCE"],
        tooltip = L["TOOLTIP_ENTRANCE_DISTANCE"],
        min = 50, max = 600, step = 10,
        get = function() return db.profile.animation.entranceDistance end,
        set = function(value) db.profile.animation.entranceDistance = value end,
    })
    LC.AnchorWidget(distance, parent, yOffset)
    yOffset = yOffset - distance:GetHeight()

    return yOffset
end

-- Builds the Hold animation settings section and positions its widgets within the parent.
-- Creates a duration slider and a "pause on hover" toggle, anchored starting at the provided yOffset.
-- @param parent The parent UI frame to attach the section's widgets to.
-- @param yOffset The starting vertical offset (pixels) where the section will be placed.
-- @return The updated vertical offset after the section and its widgets have been laid out.
local function CreateHoldSection(parent, yOffset)
    local W = ns.Widgets
    local db = dtns.Addon.db

    yOffset = yOffset - LC.SPACING_BETWEEN_SECTIONS

    local header = W.CreateHeader(parent, L["HEADER_HOLD"])
    LC.AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - LC.SPACING_AFTER_HEADER

    local duration = W.CreateSlider(parent, {
        label = L["HOLD_DURATION"],
        tooltip = L["TOOLTIP_HOLD_DURATION"],
        min = 1.0, max = 15.0, step = 0.5,
        get = function() return db.profile.animation.holdDuration end,
        set = function(value) db.profile.animation.holdDuration = value end,
    })
    LC.AnchorWidget(duration, parent, yOffset)
    yOffset = yOffset - duration:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

    local pauseOnHover = W.CreateToggle(parent, {
        label = L["PAUSE_ON_HOVER"],
        tooltip = L["TOOLTIP_PAUSE_ON_HOVER"],
        get = function() return db.profile.animation.pauseOnHover end,
        set = function(value) db.profile.animation.pauseOnHover = value end,
    })
    LC.AnchorWidget(pauseOnHover, parent, yOffset)
    yOffset = yOffset - pauseOnHover:GetHeight()

    return yOffset
end

-- Creates the "Exit" section of the Animation tab, placing a header and
-- widgets for exit duration, exit animation, and exit distance.
-- @param parent The parent UI frame to attach the section to.
-- @param yOffset The starting vertical offset; widgets are anchored relative to this value.
-- @return The updated vertical offset after laying out the section.
local function CreateExitSection(parent, yOffset)
    local W = ns.Widgets
    local db = dtns.Addon.db

    yOffset = yOffset - LC.SPACING_BETWEEN_SECTIONS

    local header = W.CreateHeader(parent, L["HEADER_EXIT"])
    LC.AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - LC.SPACING_AFTER_HEADER

    local duration = W.CreateSlider(parent, {
        label = L["EXIT_DURATION"],
        tooltip = L["TOOLTIP_EXIT_DURATION"],
        min = 0.1, max = 2.0, step = 0.1,
        get = function() return db.profile.animation.exitDuration end,
        set = function(value) db.profile.animation.exitDuration = value end,
    })
    LC.AnchorWidget(duration, parent, yOffset)
    yOffset = yOffset - duration:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

    local animation = W.CreateDropdown(parent, {
        label = L["EXIT_ANIMATION"],
        tooltip = L["TOOLTIP_EXIT_ANIMATION"],
        values = GetExitAnimationValues,
        get = function() return db.profile.animation.exitAnimation end,
        set = function(value) db.profile.animation.exitAnimation = value end,
    })
    LC.AnchorWidget(animation, parent, yOffset)
    yOffset = yOffset - animation:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

    local distance = W.CreateSlider(parent, {
        label = L["EXIT_DISTANCE"],
        tooltip = L["TOOLTIP_EXIT_DISTANCE"],
        min = 50, max = 600, step = 10,
        get = function() return db.profile.animation.exitDistance end,
        set = function(value) db.profile.animation.exitDistance = value end,
    })
    LC.AnchorWidget(distance, parent, yOffset)
    yOffset = yOffset - distance:GetHeight()

    return yOffset
end

-- Creates and places the Slide section UI (header and slide speed slider) into the parent layout.
-- @param parent The parent UI frame to anchor the section to.
-- @param yOffset The current vertical offset within the parent where the section should be placed.
-- @return The updated vertical offset after adding the section.
local function CreateSlideSection(parent, yOffset)
    local W = ns.Widgets
    local db = dtns.Addon.db

    yOffset = yOffset - LC.SPACING_BETWEEN_SECTIONS

    local header = W.CreateHeader(parent, L["HEADER_SLIDE"])
    LC.AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - LC.SPACING_AFTER_HEADER

    local speed = W.CreateSlider(parent, {
        label = L["SLIDE_SPEED"],
        tooltip = L["TOOLTIP_SLIDE_SPEED"],
        min = 0.05, max = 0.5, step = 0.05,
        get = function() return db.profile.animation.slideSpeed end,
        set = function(value) db.profile.animation.slideSpeed = value end,
    })
    LC.AnchorWidget(speed, parent, yOffset)
    yOffset = yOffset - speed:GetHeight()

    return yOffset
end

-- Creates the "Attention" subsection of the Animation tab, adds its
-- controls to the given parent, and registers those widgets in
-- attentionState.
-- @param parent UI frame to attach the section widgets to.
-- @param yOffset Number representing the starting vertical offset; widgets are anchored relative to this value.
-- @param attentionState Table used to read the enable toggle and to
--   store created controls; this function sets attentionState.dropdown
--   and attentionState.widgets.
-- @return The updated vertical offset after placing the section's widgets.
local function CreateAttentionSection(parent, yOffset, attentionState)
    local W = ns.Widgets
    local db = dtns.Addon.db

    yOffset = yOffset - LC.SPACING_BETWEEN_SECTIONS

    local header = W.CreateHeader(parent, L["HEADER_ATTENTION"])
    LC.AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - LC.SPACING_AFTER_HEADER

    local attentionDropdown

    attentionDropdown = W.CreateDropdown(parent, {
        label = L["ATTENTION_ANIMATION"],
        tooltip = L["TOOLTIP_ATTENTION_ANIMATION"],
        values = GetAttentionAnimationValues,
        get = function() return db.profile.animation.attentionAnimation end,
        set = function(value)
            db.profile.animation.attentionAnimation = value
            UpdateAttentionDisabledState(attentionState.enableToggle, attentionDropdown,
                attentionState.widgets)
        end,
    })
    LC.AnchorWidget(attentionDropdown, parent, yOffset)
    yOffset = yOffset - attentionDropdown:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

    attentionState.dropdown = attentionDropdown

    local initialDisabled = not db.profile.animation.enableAnimations
        or db.profile.animation.attentionAnimation == "none"

    local minQuality = W.CreateDropdown(parent, {
        label = L["ATTENTION_MIN_QUALITY"],
        tooltip = L["TOOLTIP_ATTENTION_MIN_QUALITY"],
        values = LC.QUALITY_VALUES,
        get = function() return db.profile.animation.attentionMinQuality end,
        set = function(value) db.profile.animation.attentionMinQuality = tonumber(value) end,
    })
    LC.AnchorWidget(minQuality, parent, yOffset)
    if initialDisabled then minQuality:SetDisabled(true) end
    yOffset = yOffset - minQuality:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

    local repeatCount = W.CreateSlider(parent, {
        label = L["ATTENTION_REPEAT_COUNT"],
        tooltip = L["TOOLTIP_ATTENTION_REPEAT_COUNT"],
        min = 1, max = 5, step = 1,
        get = function() return db.profile.animation.attentionRepeatCount end,
        set = function(value) db.profile.animation.attentionRepeatCount = value end,
    })
    LC.AnchorWidget(repeatCount, parent, yOffset)
    if initialDisabled then repeatCount:SetDisabled(true) end
    yOffset = yOffset - repeatCount:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

    local delay = W.CreateSlider(parent, {
        label = L["ATTENTION_DELAY"],
        tooltip = L["TOOLTIP_ATTENTION_DELAY"],
        min = 0, max = 1.0, step = 0.05,
        get = function() return db.profile.animation.attentionDelay end,
        set = function(value) db.profile.animation.attentionDelay = value end,
    })
    LC.AnchorWidget(delay, parent, yOffset)
    if initialDisabled then delay:SetDisabled(true) end
    yOffset = yOffset - delay:GetHeight()

    attentionState.widgets = { minQuality, repeatCount, delay }

    return yOffset
end

-------------------------------------------------------------------------------
-- Build the Animation tab content
-------------------------------------------------------------------------------

local function CreateContent(parent)
    dtns = ns.dtns
    local yOffset = LC.PADDING_TOP
    local attentionState = {}

    yOffset = CreateAnimationSection(parent, yOffset, attentionState)
    yOffset = CreateEntranceSection(parent, yOffset)
    yOffset = CreateHoldSection(parent, yOffset)
    yOffset = CreateExitSection(parent, yOffset)
    yOffset = CreateSlideSection(parent, yOffset)
    yOffset = CreateAttentionSection(parent, yOffset, attentionState)

    parent:SetHeight(math_abs(yOffset) + LC.PADDING_BOTTOM)
end

-------------------------------------------------------------------------------
-- Register tab
-------------------------------------------------------------------------------

ns.Tabs = ns.Tabs or {}
ns.Tabs[#ns.Tabs + 1] = {
    id = "animation",
    label = L["TAB_ANIMATION"],
    order = 4,
    createFunc = CreateContent,
}
