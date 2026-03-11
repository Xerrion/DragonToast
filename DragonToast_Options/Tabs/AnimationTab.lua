-------------------------------------------------------------------------------
-- AnimationTab.lua
-- Animation settings tab: entrance, hold, exit, slide, attention animations
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...
local LDF = _G.LibDragonFramework

-------------------------------------------------------------------------------
-- Cached globals
-------------------------------------------------------------------------------

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
-- Static dropdown values
-------------------------------------------------------------------------------

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

local function CreateAnimationSection(parent, attentionState)
    local db = dtns.Addon.db
    local section = LDF.CreateSection(parent, L["Animation"])
    local stack = LDF.CreateStackLayout(section.content, "vertical")

    local enableToggle = LDF.CreateToggle(section.content, {
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
    stack:AddChild(enableToggle)

    attentionState.enableToggle = enableToggle

    return section
end

local function CreateEntranceSection(parent)
    local db = dtns.Addon.db
    local section = LDF.CreateSection(parent, L["Entrance"], { collapsible = true })
    local stack = LDF.CreateStackLayout(section.content, "vertical")

    stack:AddChild(LDF.CreateSlider(section.content, {
        label = L["Entrance Duration"],
        tooltip = L["Duration of the entrance animation in seconds"],
        min = 0.1, max = 1.0, step = 0.05,
        get = function() return db.profile.animation.entranceDuration end,
        set = function(value) db.profile.animation.entranceDuration = value end,
    }))

    stack:AddChild(LDF.CreateDropdown(section.content, {
        label = L["Entrance Animation"],
        tooltip = L["Animation style for toast entrance"],
        values = GetEntranceAnimationValues,
        get = function() return db.profile.animation.entranceAnimation end,
        set = function(value) db.profile.animation.entranceAnimation = value end,
    }))

    stack:AddChild(LDF.CreateSlider(section.content, {
        label = L["Entrance Distance"],
        tooltip = L["Distance in pixels the toast travels during entrance"],
        min = 50, max = 600, step = 10,
        get = function() return db.profile.animation.entranceDistance end,
        set = function(value) db.profile.animation.entranceDistance = value end,
    }))

    return section
end

local function CreateHoldSection(parent)
    local db = dtns.Addon.db
    local section = LDF.CreateSection(parent, L["Hold"], { collapsible = true })
    local stack = LDF.CreateStackLayout(section.content, "vertical")

    stack:AddChild(LDF.CreateSlider(section.content, {
        label = L["Hold Duration"],
        tooltip = L["How long the toast stays visible before exiting"],
        min = 1.0, max = 15.0, step = 0.5,
        get = function() return db.profile.animation.holdDuration end,
        set = function(value) db.profile.animation.holdDuration = value end,
    }))

    return section
end

local function CreateExitSection(parent)
    local db = dtns.Addon.db
    local section = LDF.CreateSection(parent, L["Exit"], { collapsible = true })
    local stack = LDF.CreateStackLayout(section.content, "vertical")

    stack:AddChild(LDF.CreateSlider(section.content, {
        label = L["Exit Duration"],
        tooltip = L["Duration of the exit animation in seconds"],
        min = 0.1, max = 2.0, step = 0.1,
        get = function() return db.profile.animation.exitDuration end,
        set = function(value) db.profile.animation.exitDuration = value end,
    }))

    stack:AddChild(LDF.CreateDropdown(section.content, {
        label = L["Exit Animation"],
        tooltip = L["Animation style for toast exit"],
        values = GetExitAnimationValues,
        get = function() return db.profile.animation.exitAnimation end,
        set = function(value) db.profile.animation.exitAnimation = value end,
    }))

    stack:AddChild(LDF.CreateSlider(section.content, {
        label = L["Exit Distance"],
        tooltip = L["Distance in pixels the toast travels during exit"],
        min = 50, max = 600, step = 10,
        get = function() return db.profile.animation.exitDistance end,
        set = function(value) db.profile.animation.exitDistance = value end,
    }))

    return section
end

local function CreateSlideSection(parent)
    local db = dtns.Addon.db
    local section = LDF.CreateSection(parent, L["Slide"], { collapsible = true })
    local stack = LDF.CreateStackLayout(section.content, "vertical")

    stack:AddChild(LDF.CreateSlider(section.content, {
        label = L["Slide Speed"],
        tooltip = L["Speed of the slide animation when toasts reposition"],
        min = 0.05, max = 0.5, step = 0.05,
        get = function() return db.profile.animation.slideSpeed end,
        set = function(value) db.profile.animation.slideSpeed = value end,
    }))

    return section
end

local function CreateAttentionSection(parent, attentionState)
    local db = dtns.Addon.db
    local section = LDF.CreateSection(parent, L["Attention"], { collapsible = true })
    local stack = LDF.CreateStackLayout(section.content, "vertical")

    local attentionDropdown
    attentionDropdown = LDF.CreateDropdown(section.content, {
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
    stack:AddChild(attentionDropdown)

    attentionState.dropdown = attentionDropdown

    local initialDisabled = not db.profile.animation.enableAnimations
        or db.profile.animation.attentionAnimation == "none"

    local minQuality = LDF.CreateDropdown(section.content, {
        label = L["Attention Min Quality"],
        tooltip = L["Minimum item quality required to trigger the attention animation"],
        values = QUALITY_VALUES,
        get = function() return db.profile.animation.attentionMinQuality end,
        set = function(value) db.profile.animation.attentionMinQuality = tonumber(value) end,
        disabled = initialDisabled,
    })
    stack:AddChild(minQuality)

    local repeatCount = LDF.CreateSlider(section.content, {
        label = L["Attention Repeat Count"],
        tooltip = L["Number of times the attention animation repeats"],
        min = 1, max = 5, step = 1,
        get = function() return db.profile.animation.attentionRepeatCount end,
        set = function(value) db.profile.animation.attentionRepeatCount = value end,
        disabled = initialDisabled,
    })
    stack:AddChild(repeatCount)

    local delay = LDF.CreateSlider(section.content, {
        label = L["Attention Delay"],
        tooltip = L["Delay in seconds before the attention animation starts"],
        min = 0, max = 1.0, step = 0.05,
        get = function() return db.profile.animation.attentionDelay end,
        set = function(value) db.profile.animation.attentionDelay = value end,
        disabled = initialDisabled,
    })
    stack:AddChild(delay)

    attentionState.widgets = { minQuality, repeatCount, delay }

    return section
end

-------------------------------------------------------------------------------
-- Build the Animation tab content
-------------------------------------------------------------------------------

local function CreateContent(parent)
    dtns = ns.dtns
    local attentionState = {}
    local stack = LDF.CreateStackLayout(parent, "vertical")

    stack:AddChild(CreateAnimationSection(parent, attentionState))
    stack:AddChild(CreateEntranceSection(parent))
    stack:AddChild(CreateHoldSection(parent))
    stack:AddChild(CreateExitSection(parent))
    stack:AddChild(CreateSlideSection(parent))
    stack:AddChild(CreateAttentionSection(parent, attentionState))
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
