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
-- Localization
-------------------------------------------------------------------------------

local L = ns.L

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
    local lib = LibStub("LibAnimate", true)
    if not lib then return {} end
    local names = lib:GetEntranceAnimations()
    local values = { { value = "none", text = L["None"] } }
    for _, name in ipairs(names) do
        values[#values + 1] = { value = name, text = name }
    end
    return values
end

local function GetExitAnimationValues()
    local lib = LibStub("LibAnimate", true)
    if not lib then return {} end
    local names = lib:GetExitAnimations()
    local values = { { value = "none", text = L["None"] } }
    for _, name in ipairs(names) do
        values[#values + 1] = { value = name, text = name }
    end
    return values
end

local function GetAttentionAnimationValues()
    local lib = LibStub("LibAnimate", true)
    if not lib then return { { value = "none", text = L["None"] } } end
    local names = lib:GetAttentionAnimations()
    local values = { { value = "none", text = L["None"] } }
    for _, name in ipairs(names) do
        values[#values + 1] = { value = name, text = name }
    end
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

    local header = W.CreateHeader(parent, L["Animation"])
    AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - SPACING_AFTER_HEADER

    local enableToggle = W.CreateToggle(parent, {
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
    AnchorWidget(enableToggle, parent, yOffset)
    yOffset = yOffset - enableToggle:GetHeight()

    attentionState.enableToggle = enableToggle

    return yOffset
end

local function CreateEntranceSection(parent, yOffset)
    local W = ns.Widgets
    local db = dtns.Addon.db

    yOffset = yOffset - SPACING_BETWEEN_SECTIONS

    local header = W.CreateHeader(parent, L["Entrance"])
    AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - SPACING_AFTER_HEADER

    local duration = W.CreateSlider(parent, {
        label = L["Entrance Duration"],
        tooltip = L["Duration of the entrance animation in seconds"],
        min = 0.1, max = 1.0, step = 0.05,
        get = function() return db.profile.animation.entranceDuration end,
        set = function(value) db.profile.animation.entranceDuration = value end,
    })
    AnchorWidget(duration, parent, yOffset)
    yOffset = yOffset - duration:GetHeight() - SPACING_BETWEEN_WIDGETS

    local animation = W.CreateDropdown(parent, {
        label = L["Entrance Animation"],
        tooltip = L["Animation style for toast entrance"],
        values = GetEntranceAnimationValues,
        get = function() return db.profile.animation.entranceAnimation end,
        set = function(value) db.profile.animation.entranceAnimation = value end,
    })
    AnchorWidget(animation, parent, yOffset)
    yOffset = yOffset - animation:GetHeight() - SPACING_BETWEEN_WIDGETS

    local distance = W.CreateSlider(parent, {
        label = L["Entrance Distance"],
        tooltip = L["Distance in pixels the toast travels during entrance"],
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

    local header = W.CreateHeader(parent, L["Hold"])
    AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - SPACING_AFTER_HEADER

    local duration = W.CreateSlider(parent, {
        label = L["Hold Duration"],
        tooltip = L["How long the toast stays visible before exiting"],
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

    local header = W.CreateHeader(parent, L["Exit"])
    AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - SPACING_AFTER_HEADER

    local duration = W.CreateSlider(parent, {
        label = L["Exit Duration"],
        tooltip = L["Duration of the exit animation in seconds"],
        min = 0.1, max = 2.0, step = 0.1,
        get = function() return db.profile.animation.exitDuration end,
        set = function(value) db.profile.animation.exitDuration = value end,
    })
    AnchorWidget(duration, parent, yOffset)
    yOffset = yOffset - duration:GetHeight() - SPACING_BETWEEN_WIDGETS

    local animation = W.CreateDropdown(parent, {
        label = L["Exit Animation"],
        tooltip = L["Animation style for toast exit"],
        values = GetExitAnimationValues,
        get = function() return db.profile.animation.exitAnimation end,
        set = function(value) db.profile.animation.exitAnimation = value end,
    })
    AnchorWidget(animation, parent, yOffset)
    yOffset = yOffset - animation:GetHeight() - SPACING_BETWEEN_WIDGETS

    local distance = W.CreateSlider(parent, {
        label = L["Exit Distance"],
        tooltip = L["Distance in pixels the toast travels during exit"],
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

    local header = W.CreateHeader(parent, L["Slide"])
    AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - SPACING_AFTER_HEADER

    local speed = W.CreateSlider(parent, {
        label = L["Slide Speed"],
        tooltip = L["Speed of the slide animation when toasts reposition"],
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

    local header = W.CreateHeader(parent, L["Attention"])
    AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - SPACING_AFTER_HEADER

    local attentionDropdown

    attentionDropdown = W.CreateDropdown(parent, {
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
    AnchorWidget(attentionDropdown, parent, yOffset)
    yOffset = yOffset - attentionDropdown:GetHeight() - SPACING_BETWEEN_WIDGETS

    attentionState.dropdown = attentionDropdown

    local initialDisabled = not db.profile.animation.enableAnimations
        or db.profile.animation.attentionAnimation == "none"

    local minQuality = W.CreateDropdown(parent, {
        label = L["Attention Min Quality"],
        tooltip = L["Minimum item quality required to trigger the attention animation"],
        values = QUALITY_VALUES,
        get = function() return db.profile.animation.attentionMinQuality end,
        set = function(value) db.profile.animation.attentionMinQuality = tonumber(value) end,
    })
    AnchorWidget(minQuality, parent, yOffset)
    if initialDisabled then minQuality:SetDisabled(true) end
    yOffset = yOffset - minQuality:GetHeight() - SPACING_BETWEEN_WIDGETS

    local repeatCount = W.CreateSlider(parent, {
        label = L["Attention Repeat Count"],
        tooltip = L["Number of times the attention animation repeats"],
        min = 1, max = 5, step = 1,
        get = function() return db.profile.animation.attentionRepeatCount end,
        set = function(value) db.profile.animation.attentionRepeatCount = value end,
    })
    AnchorWidget(repeatCount, parent, yOffset)
    if initialDisabled then repeatCount:SetDisabled(true) end
    yOffset = yOffset - repeatCount:GetHeight() - SPACING_BETWEEN_WIDGETS

    local delay = W.CreateSlider(parent, {
        label = L["Attention Delay"],
        tooltip = L["Delay in seconds before the attention animation starts"],
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
    dtns = ns.dtns
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
    label = L["Animation"],
    order = 4,
    createFunc = CreateContent,
}
