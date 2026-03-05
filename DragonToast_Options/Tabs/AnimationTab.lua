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
local pairs = pairs
local table_sort = table.sort
local tonumber = tonumber

-------------------------------------------------------------------------------
-- Namespace references
-------------------------------------------------------------------------------

local dtns = ns.dtns
local LibAnimate = LibStub("LibAnimate-1.0", true)

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local PADDING_SIDE = 10
local PADDING_TOP = -10
local SPACING_AFTER_HEADER = 8
local SPACING_BETWEEN_WIDGETS = 6
local SPACING_BETWEEN_SECTIONS = 16
local PADDING_BOTTOM = 20

local QUALITY_VALUES = {
    { value = 0, text = "|cff9d9d9dPoor|r" },
    { value = 1, text = "|cffffffffCommon|r" },
    { value = 2, text = "|cff1eff00Uncommon|r" },
    { value = 3, text = "|cff0070ddRare|r" },
    { value = 4, text = "|cffa335eeEpic|r" },
    { value = 5, text = "|cffff8000Legendary|r" },
}

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------

local function AnchorWidget(widget, parent, yOffset)
    widget:SetPoint("TOPLEFT", parent, "TOPLEFT", PADDING_SIDE, yOffset)
    widget:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -PADDING_SIDE, yOffset)
end

local function GetEntranceAnimationValues()
    if not LibAnimate then return {} end
    local anims = LibAnimate:GetEntranceAnimations()
    local values = {}
    for key, name in pairs(anims) do
        values[#values + 1] = { value = key, text = name }
    end
    table_sort(values, function(a, b) return a.text < b.text end)
    return values
end

local function GetExitAnimationValues()
    if not LibAnimate then return {} end
    local anims = LibAnimate:GetExitAnimations()
    local values = {}
    for key, name in pairs(anims) do
        values[#values + 1] = { value = key, text = name }
    end
    table_sort(values, function(a, b) return a.text < b.text end)
    return values
end

local function GetAttentionAnimationValues()
    if not LibAnimate then return { { value = "none", text = "None" } } end
    local anims = LibAnimate:GetAttentionAnimations()
    local values = { { value = "none", text = "None" } }
    for key, name in pairs(anims) do
        values[#values + 1] = { value = key, text = name }
    end
    table_sort(values, function(a, b)
        if a.value == "none" then return true end
        if b.value == "none" then return false end
        return a.text < b.text
    end)
    return values
end

local function UpdateAttentionDisabledState(enableToggle, attentionDropdown, widgets)
    local disabled = not enableToggle:GetValue() or attentionDropdown:GetValue() == "none"
    for _, w in pairs(widgets) do
        w:SetDisabled(disabled)
    end
end

-------------------------------------------------------------------------------
-- Section builders
-------------------------------------------------------------------------------

local function CreateAnimationSection(parent, yOffset, attentionState)
    local W = ns.Widgets
    local db = dtns.Addon.db

    local header = W.CreateHeader(parent, "Animation")
    AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - SPACING_AFTER_HEADER

    local enableToggle = W.CreateToggle(parent, {
        label = "Enable Animations",
        tooltip = "Enable or disable all toast animations",
        get = function() return db.profile.animation.enableAnimations end,
        set = function(value)
            db.profile.animation.enableAnimations = value
            if attentionState.dropdown then
                UpdateAttentionDisabledState(attentionState.enableToggle, attentionState.dropdown,
                    attentionState.widgets)
            end
        end,
    })
    AnchorWidget(enableToggle, parent, yOffset)
    yOffset = yOffset - enableToggle:GetHeight()

    attentionState.enableToggle = enableToggle

    return yOffset
end

local function CreateEntranceSection(parent, yOffset)
    local W = ns.Widgets
    local db = dtns.Addon.db

    yOffset = yOffset - SPACING_BETWEEN_SECTIONS

    local header = W.CreateHeader(parent, "Entrance")
    AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - SPACING_AFTER_HEADER

    local duration = W.CreateSlider(parent, {
        label = "Entrance Duration",
        tooltip = "Duration of the entrance animation in seconds",
        min = 0.1, max = 1.0, step = 0.05,
        get = function() return db.profile.animation.entranceDuration end,
        set = function(value) db.profile.animation.entranceDuration = value end,
    })
    AnchorWidget(duration, parent, yOffset)
    yOffset = yOffset - duration:GetHeight() - SPACING_BETWEEN_WIDGETS

    local animation = W.CreateDropdown(parent, {
        label = "Entrance Animation",
        tooltip = "Animation style for toast entrance",
        values = GetEntranceAnimationValues,
        get = function() return db.profile.animation.entranceAnimation end,
        set = function(value) db.profile.animation.entranceAnimation = value end,
    })
    AnchorWidget(animation, parent, yOffset)
    yOffset = yOffset - animation:GetHeight() - SPACING_BETWEEN_WIDGETS

    local distance = W.CreateSlider(parent, {
        label = "Entrance Distance",
        tooltip = "Distance in pixels the toast travels during entrance",
        min = 50, max = 600, step = 10,
        get = function() return db.profile.animation.entranceDistance end,
        set = function(value) db.profile.animation.entranceDistance = value end,
    })
    AnchorWidget(distance, parent, yOffset)
    yOffset = yOffset - distance:GetHeight()

    return yOffset
end

local function CreateHoldSection(parent, yOffset)
    local W = ns.Widgets
    local db = dtns.Addon.db

    yOffset = yOffset - SPACING_BETWEEN_SECTIONS

    local header = W.CreateHeader(parent, "Hold")
    AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - SPACING_AFTER_HEADER

    local duration = W.CreateSlider(parent, {
        label = "Hold Duration",
        tooltip = "How long the toast stays visible before exiting",
        min = 1.0, max = 15.0, step = 0.5,
        get = function() return db.profile.animation.holdDuration end,
        set = function(value) db.profile.animation.holdDuration = value end,
    })
    AnchorWidget(duration, parent, yOffset)
    yOffset = yOffset - duration:GetHeight()

    return yOffset
end

local function CreateExitSection(parent, yOffset)
    local W = ns.Widgets
    local db = dtns.Addon.db

    yOffset = yOffset - SPACING_BETWEEN_SECTIONS

    local header = W.CreateHeader(parent, "Exit")
    AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - SPACING_AFTER_HEADER

    local duration = W.CreateSlider(parent, {
        label = "Exit Duration",
        tooltip = "Duration of the exit animation in seconds",
        min = 0.1, max = 2.0, step = 0.1,
        get = function() return db.profile.animation.exitDuration end,
        set = function(value) db.profile.animation.exitDuration = value end,
    })
    AnchorWidget(duration, parent, yOffset)
    yOffset = yOffset - duration:GetHeight() - SPACING_BETWEEN_WIDGETS

    local animation = W.CreateDropdown(parent, {
        label = "Exit Animation",
        tooltip = "Animation style for toast exit",
        values = GetExitAnimationValues,
        get = function() return db.profile.animation.exitAnimation end,
        set = function(value) db.profile.animation.exitAnimation = value end,
    })
    AnchorWidget(animation, parent, yOffset)
    yOffset = yOffset - animation:GetHeight() - SPACING_BETWEEN_WIDGETS

    local distance = W.CreateSlider(parent, {
        label = "Exit Distance",
        tooltip = "Distance in pixels the toast travels during exit",
        min = 50, max = 600, step = 10,
        get = function() return db.profile.animation.exitDistance end,
        set = function(value) db.profile.animation.exitDistance = value end,
    })
    AnchorWidget(distance, parent, yOffset)
    yOffset = yOffset - distance:GetHeight()

    return yOffset
end

local function CreateSlideSection(parent, yOffset)
    local W = ns.Widgets
    local db = dtns.Addon.db

    yOffset = yOffset - SPACING_BETWEEN_SECTIONS

    local header = W.CreateHeader(parent, "Slide")
    AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - SPACING_AFTER_HEADER

    local speed = W.CreateSlider(parent, {
        label = "Slide Speed",
        tooltip = "Speed of the slide animation when toasts reposition",
        min = 0.05, max = 0.5, step = 0.05,
        get = function() return db.profile.animation.slideSpeed end,
        set = function(value) db.profile.animation.slideSpeed = value end,
    })
    AnchorWidget(speed, parent, yOffset)
    yOffset = yOffset - speed:GetHeight()

    return yOffset
end

local function CreateAttentionSection(parent, yOffset, attentionState)
    local W = ns.Widgets
    local db = dtns.Addon.db

    yOffset = yOffset - SPACING_BETWEEN_SECTIONS

    local header = W.CreateHeader(parent, "Attention")
    AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - SPACING_AFTER_HEADER

    local attentionDropdown

    attentionDropdown = W.CreateDropdown(parent, {
        label = "Attention Animation",
        tooltip = "Animation to draw attention to high-quality items",
        values = GetAttentionAnimationValues,
        get = function() return db.profile.animation.attentionAnimation end,
        set = function(value)
            db.profile.animation.attentionAnimation = value
            UpdateAttentionDisabledState(attentionState.enableToggle, attentionDropdown,
                attentionState.widgets)
        end,
    })
    AnchorWidget(attentionDropdown, parent, yOffset)
    yOffset = yOffset - attentionDropdown:GetHeight() - SPACING_BETWEEN_WIDGETS

    attentionState.dropdown = attentionDropdown

    local initialDisabled = not db.profile.animation.enableAnimations
        or db.profile.animation.attentionAnimation == "none"

    local minQuality = W.CreateDropdown(parent, {
        label = "Attention Min Quality",
        tooltip = "Minimum item quality required to trigger the attention animation",
        values = QUALITY_VALUES,
        get = function() return db.profile.animation.attentionMinQuality end,
        set = function(value) db.profile.animation.attentionMinQuality = tonumber(value) end,
    })
    AnchorWidget(minQuality, parent, yOffset)
    if initialDisabled then minQuality:SetDisabled(true) end
    yOffset = yOffset - minQuality:GetHeight() - SPACING_BETWEEN_WIDGETS

    local repeatCount = W.CreateSlider(parent, {
        label = "Attention Repeat Count",
        tooltip = "Number of times the attention animation repeats",
        min = 1, max = 5, step = 1,
        get = function() return db.profile.animation.attentionRepeatCount end,
        set = function(value) db.profile.animation.attentionRepeatCount = value end,
    })
    AnchorWidget(repeatCount, parent, yOffset)
    if initialDisabled then repeatCount:SetDisabled(true) end
    yOffset = yOffset - repeatCount:GetHeight() - SPACING_BETWEEN_WIDGETS

    local delay = W.CreateSlider(parent, {
        label = "Attention Delay",
        tooltip = "Delay in seconds before the attention animation starts",
        min = 0, max = 1.0, step = 0.05,
        get = function() return db.profile.animation.attentionDelay end,
        set = function(value) db.profile.animation.attentionDelay = value end,
    })
    AnchorWidget(delay, parent, yOffset)
    if initialDisabled then delay:SetDisabled(true) end
    yOffset = yOffset - delay:GetHeight()

    attentionState.widgets = { minQuality, repeatCount, delay }

    return yOffset
end

-------------------------------------------------------------------------------
-- Build the Animation tab content
-------------------------------------------------------------------------------

local function CreateContent(parent)
    local yOffset = PADDING_TOP
    local attentionState = {}

    yOffset = CreateAnimationSection(parent, yOffset, attentionState)
    yOffset = CreateEntranceSection(parent, yOffset)
    yOffset = CreateHoldSection(parent, yOffset)
    yOffset = CreateExitSection(parent, yOffset)
    yOffset = CreateSlideSection(parent, yOffset)
    yOffset = CreateAttentionSection(parent, yOffset, attentionState)

    parent:SetHeight(math_abs(yOffset) + PADDING_BOTTOM)
end

-------------------------------------------------------------------------------
-- Register tab
-------------------------------------------------------------------------------

ns.Tabs = ns.Tabs or {}
ns.Tabs[#ns.Tabs + 1] = {
    id = "animation",
    label = "Animation",
    order = 4,
    createFunc = CreateContent,
}
