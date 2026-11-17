-------------------------------------------------------------------------------
-- AnimationTab.lua
-- Animation settings tab: entrance, hold, exit, slide, attention animations
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

-------------------------------------------------------------------------------
-- Cached globals
-------------------------------------------------------------------------------

local math_abs = math.abs
local ipairs = ipairs
local pairs = pairs
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
local currentAttentionState

-------------------------------------------------------------------------------
-- Helpers
-- Create a list of dropdown option tables for animations returned by the specified LibAnimate method.
-- @param methodName The method name on LibAnimate to call (e.g., "GetEntranceAnimations").
-- @return A list of tables each containing `value` and `text` for a
--   dropdown; the first entry is
--   `{ value = "none", text = "None" }`.

local function BuildAnimationValues(methodName)
    local lib = LibStub("LibAnimate", true)
    if not lib then return {} end

    local names = lib[methodName](lib)
    local values = { { value = "none", text = L["None"] } }
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
    local db = dtns.Addon.db

    local section = W.CreateSection(parent, L["Animation"])
    local content = section.content
    local innerY = -LC.SECTION_PADDING_TOP

    local enableToggle = W.CreateToggle(content, {
        label = L["Enable Animations"],
        tooltip = L["Enable or disable all toast animations"],
        get = function() return db.profile.animation.enableAnimations end,
        set = function(value)
            db.profile.animation.enableAnimations = value
            if attentionState.dropdown then
                UpdateAttentionDisabledState(attentionState.enableToggle, attentionState.dropdown,
                    attentionState.widgets)
            end
        end,
    })
    innerY = LC.AnchorWidget(enableToggle, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    attentionState.enableToggle = enableToggle

    section:SetContentHeight(math_abs(innerY) + LC.SECTION_PADDING_BOTTOM)
    return LC.AnchorSection(section, parent, yOffset) - LC.SPACING_BETWEEN_SECTIONS
end

-- Creates the "Entrance" section in the animation options and adds its widgets to the given parent.
-- @param parent The UI container/frame to which the section's widgets will be anchored.
-- @param yOffset The current vertical offset (y) used to position
--   widgets; will be adjusted downward as widgets are added.
-- @return The updated vertical offset after placing the section's header and widgets.
local function CreateEntranceSection(parent, yOffset)
    local db = dtns.Addon.db

    local section = W.CreateSection(parent, L["Entrance"])
    local content = section.content
    local innerY = -LC.SECTION_PADDING_TOP

    local animation = W.CreateDropdown(content, {
        label = L["Entrance Animation"],
        tooltip = L["Animation style for toast entrance"],
        values = GetEntranceAnimationValues,
        get = function() return db.profile.animation.entranceAnimation end,
        set = function(value) db.profile.animation.entranceAnimation = value end,
    })
    innerY = LC.AnchorWidget(animation, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local duration = W.CreateSlider(content, {
        label = L["Entrance Duration"],
        tooltip = L["Duration of the entrance animation in seconds"],
        min = 0.1, max = 1.0, step = 0.05,
        get = function() return db.profile.animation.entranceDuration end,
        set = function(value) db.profile.animation.entranceDuration = value end,
    })
    innerY = LC.AnchorWidget(duration, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local distance = W.CreateSlider(content, {
        label = L["Entrance Distance"],
        tooltip = L["Distance in pixels the toast travels during entrance"],
        min = 50, max = 600, step = 10,
        get = function() return db.profile.animation.entranceDistance end,
        set = function(value) db.profile.animation.entranceDistance = value end,
    })
    innerY = LC.AnchorWidget(distance, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    section:SetContentHeight(math_abs(innerY) + LC.SECTION_PADDING_BOTTOM)
    return LC.AnchorSection(section, parent, yOffset) - LC.SPACING_BETWEEN_SECTIONS
end

-- Builds the Hold animation settings section and positions its widgets within the parent.
-- Creates a duration slider and a "pause on hover" toggle, anchored starting at the provided yOffset.
-- @param parent The parent UI frame to attach the section's widgets to.
-- @param yOffset The starting vertical offset (pixels) where the section will be placed.
-- @return The updated vertical offset after the section and its widgets have been laid out.
local function CreateHoldSection(parent, yOffset)
    local db = dtns.Addon.db

    local section = W.CreateSection(parent, L["Hold"])
    local content = section.content
    local innerY = -LC.SECTION_PADDING_TOP

    local duration = W.CreateSlider(content, {
        label = L["Hold Duration"],
        tooltip = L["How long the toast stays visible before exiting"],
        min = 1.0, max = 15.0, step = 0.5,
        get = function() return db.profile.animation.holdDuration end,
        set = function(value) db.profile.animation.holdDuration = value end,
    })
    innerY = LC.AnchorWidget(duration, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local pauseOnHover = W.CreateToggle(content, {
        label = L["Pause on Hover"],
        tooltip = L["Pause toast fade-out when hovering to read tooltips"],
        get = function() return db.profile.animation.pauseOnHover end,
        set = function(value) db.profile.animation.pauseOnHover = value end,
    })
    innerY = LC.AnchorWidget(pauseOnHover, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    section:SetContentHeight(math_abs(innerY) + LC.SECTION_PADDING_BOTTOM)
    return LC.AnchorSection(section, parent, yOffset) - LC.SPACING_BETWEEN_SECTIONS
end

-- Creates the "Exit" section and its controls for animation, duration, and distance.
-- @param parent The parent UI frame to attach the section to.
-- @param yOffset The starting vertical offset; widgets are anchored relative to this value.
-- @return The updated vertical offset after laying out the section.
local function CreateExitSection(parent, yOffset)
    local db = dtns.Addon.db

    local section = W.CreateSection(parent, L["Exit"])
    local content = section.content
    local innerY = -LC.SECTION_PADDING_TOP

    local animation = W.CreateDropdown(content, {
        label = L["Exit Animation"],
        tooltip = L["Animation style for toast exit"],
        values = GetExitAnimationValues,
        get = function() return db.profile.animation.exitAnimation end,
        set = function(value) db.profile.animation.exitAnimation = value end,
    })
    innerY = LC.AnchorWidget(animation, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local duration = W.CreateSlider(content, {
        label = L["Exit Duration"],
        tooltip = L["Duration of the exit animation in seconds"],
        min = 0.1, max = 2.0, step = 0.1,
        get = function() return db.profile.animation.exitDuration end,
        set = function(value) db.profile.animation.exitDuration = value end,
    })
    innerY = LC.AnchorWidget(duration, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local distance = W.CreateSlider(content, {
        label = L["Exit Distance"],
        tooltip = L["Distance in pixels the toast travels during exit"],
        min = 50, max = 600, step = 10,
        get = function() return db.profile.animation.exitDistance end,
        set = function(value) db.profile.animation.exitDistance = value end,
    })
    innerY = LC.AnchorWidget(distance, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    section:SetContentHeight(math_abs(innerY) + LC.SECTION_PADDING_BOTTOM)
    return LC.AnchorSection(section, parent, yOffset) - LC.SPACING_BETWEEN_SECTIONS
end

-- Creates the "Stack Timing" section and its sliders for queue stagger and slide speed.
-- @param parent The parent UI frame to anchor the section to.
-- @param yOffset The current vertical offset within the parent where the section should be placed.
-- @return The updated vertical offset after adding the section.
local function CreateSlideSection(parent, yOffset)
    local db = dtns.Addon.db

    local section = W.CreateSection(parent, L["Stack Timing"])
    local content = section.content
    local innerY = -LC.SECTION_PADDING_TOP

    local queueStagger = W.CreateSlider(content, {
        label = L["Queue Stagger"],
        tooltip = L["Delay between showing consecutive toasts from the queue (in seconds)"],
        min = 0, max = 1, step = 0.05,
        get = function() return db.profile.display.queueStagger end,
        set = function(value) db.profile.display.queueStagger = value end,
    })
    innerY = LC.AnchorWidget(queueStagger, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local speed = W.CreateSlider(content, {
        label = L["Slide Speed"],
        tooltip = L["Speed of the slide animation when toasts reposition"],
        min = 0.05, max = 0.5, step = 0.05,
        get = function() return db.profile.animation.slideSpeed end,
        set = function(value) db.profile.animation.slideSpeed = value end,
    })
    innerY = LC.AnchorWidget(speed, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    section:SetContentHeight(math_abs(innerY) + LC.SECTION_PADDING_BOTTOM)
    return LC.AnchorSection(section, parent, yOffset) - LC.SPACING_BETWEEN_SECTIONS
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
    local db = dtns.Addon.db

    local section = W.CreateSection(parent, L["Attention"])
    local content = section.content
    local innerY = -LC.SECTION_PADDING_TOP

    local attentionDropdown

    attentionDropdown = W.CreateDropdown(content, {
        label = L["Attention Animation"],
        tooltip = L["Animation to draw attention to high-quality items"],
        values = GetAttentionAnimationValues,
        get = function() return db.profile.animation.attentionAnimation end,
        set = function(value)
            db.profile.animation.attentionAnimation = value
            UpdateAttentionDisabledState(attentionState.enableToggle, attentionDropdown,
                attentionState.widgets)
        end,
    })
    innerY = LC.AnchorWidget(attentionDropdown, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    attentionState.dropdown = attentionDropdown

    local initialDisabled = not db.profile.animation.enableAnimations
        or db.profile.animation.attentionAnimation == "none"

    local minQuality = W.CreateDropdown(content, {
        label = L["Attention Min Quality"],
        tooltip = L["Minimum item quality required to trigger the attention animation"],
        values = ns.QualityValues,
        get = function() return db.profile.animation.attentionMinQuality end,
        set = function(value) db.profile.animation.attentionMinQuality = tonumber(value) or 0 end,
    })
    if initialDisabled then minQuality:SetDisabled(true) end
    innerY = LC.AnchorWidget(minQuality, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local repeatCount = W.CreateSlider(content, {
        label = L["Attention Repeat Count"],
        tooltip = L["Number of times the attention animation repeats"],
        min = 1, max = 5, step = 1,
        get = function() return db.profile.animation.attentionRepeatCount end,
        set = function(value) db.profile.animation.attentionRepeatCount = value end,
    })
    if initialDisabled then repeatCount:SetDisabled(true) end
    innerY = LC.AnchorWidget(repeatCount, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local delay = W.CreateSlider(content, {
        label = L["Attention Delay"],
        tooltip = L["Delay in seconds before the attention animation starts"],
        min = 0, max = 1.0, step = 0.05,
        get = function() return db.profile.animation.attentionDelay end,
        set = function(value) db.profile.animation.attentionDelay = value end,
    })
    if initialDisabled then delay:SetDisabled(true) end
    innerY = LC.AnchorWidget(delay, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    attentionState.widgets = { minQuality, repeatCount, delay }

    section:SetContentHeight(math_abs(innerY) + LC.SECTION_PADDING_BOTTOM)
    return LC.AnchorSection(section, parent, yOffset) - LC.SPACING_BETWEEN_SECTIONS
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
    yOffset = CreateAttentionSection(parent, yOffset, attentionState)
    yOffset = CreateHoldSection(parent, yOffset)
    yOffset = CreateExitSection(parent, yOffset)
    yOffset = CreateSlideSection(parent, yOffset)
    currentAttentionState = attentionState

    parent:SetHeight(math_abs(yOffset) + LC.PADDING_BOTTOM)
end

-------------------------------------------------------------------------------
-- Register tab
-------------------------------------------------------------------------------

ns.Tabs[#ns.Tabs + 1] = {
    id = "animation",
    label = L["Animation"],
    order = 5,
    createFunc = CreateContent,
    refreshFunc = function()
        local state = currentAttentionState
        if state then
            UpdateAttentionDisabledState(state.enableToggle, state.dropdown, state.widgets)
        end
    end,
}
