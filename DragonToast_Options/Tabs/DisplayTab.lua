-------------------------------------------------------------------------------
-- DisplayTab.lua
-- Display settings tab: layout, toast size, content, padding, anchor
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...
local LDF = _G.LibDragonFramework

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

local GROW_DIRECTION_VALUES = {
    { value = "UP", text = L["Up"] },
    { value = "DOWN", text = L["Down"] },
}

local GOLD_FORMAT_VALUES = {
    { value = "icons", text = L["Icons"] },
    { value = "short", text = L["Short (1g 2s 3c)"] },
    { value = "long", text = L["Long (1 Gold 2 Silver 3 Copper)"] },
}

-------------------------------------------------------------------------------
-- Section builders
-------------------------------------------------------------------------------

local function CreateLayoutSection(parent)
    local db = dtns.Addon.db
    local section = LDF.CreateSection(parent, L["Layout"])
    local stack = LDF.CreateStackLayout(section.content, "vertical")

    stack:AddChild(LDF.CreateSlider(section.content, {
        label = L["Max Toasts"],
        tooltip = L["Maximum number of toasts visible at once"],
        min = 1, max = 15, step = 1,
        get = function() return db.profile.display.maxToasts end,
        set = function(value) db.profile.display.maxToasts = value end,
    }))

    stack:AddChild(LDF.CreateDropdown(section.content, {
        label = L["Grow Direction"],
        tooltip = L["Direction toasts stack from the anchor"],
        values = GROW_DIRECTION_VALUES,
        get = function() return db.profile.display.growDirection end,
        set = function(value)
            db.profile.display.growDirection = value
            dtns.ToastManager:UpdatePositions()
        end,
    }))

    stack:AddChild(LDF.CreateSlider(section.content, {
        label = L["Spacing"],
        tooltip = L["Space between toasts in pixels"],
        min = 0, max = 20, step = 1,
        get = function() return db.profile.display.spacing end,
        set = function(value)
            db.profile.display.spacing = value
            dtns.ToastManager:UpdateLayout()
        end,
    }))

    return section
end

local function CreateSizeSection(parent)
    local db = dtns.Addon.db
    local section = LDF.CreateSection(parent, L["Toast Size"])
    local stack = LDF.CreateStackLayout(section.content, "vertical")

    stack:AddChild(LDF.CreateSlider(section.content, {
        label = L["Toast Width"],
        tooltip = L["Width of each toast in pixels"],
        min = 200, max = 600, step = 10,
        get = function() return db.profile.display.toastWidth end,
        set = function(value)
            db.profile.display.toastWidth = value
            dtns.ToastManager:UpdateLayout()
        end,
    }))

    stack:AddChild(LDF.CreateSlider(section.content, {
        label = L["Toast Height"],
        tooltip = L["Height of each toast in pixels"],
        min = 32, max = 80, step = 2,
        get = function() return db.profile.display.toastHeight end,
        set = function(value)
            db.profile.display.toastHeight = value
            dtns.ToastManager:UpdateLayout()
        end,
    }))

    return section
end

local function CreateContentSection(parent)
    local db = dtns.Addon.db
    local section = LDF.CreateSection(parent, L["Content"], { collapsible = true })
    local stack = LDF.CreateStackLayout(section.content, "vertical")

    stack:AddChild(LDF.CreateToggle(section.content, {
        label = L["Show Icon"],
        tooltip = L["Display the item icon on toasts"],
        get = function() return db.profile.display.showIcon end,
        set = function(value)
            db.profile.display.showIcon = value
            dtns.ToastManager:UpdateLayout()
        end,
    }))

    stack:AddChild(LDF.CreateToggle(section.content, {
        label = L["Show Item Level"],
        tooltip = L["Display the item level on toasts"],
        get = function() return db.profile.display.showItemLevel end,
        set = function(value) db.profile.display.showItemLevel = value end,
    }))

    stack:AddChild(LDF.CreateToggle(section.content, {
        label = L["Show Item Type"],
        tooltip = L["Display the item type on toasts"],
        get = function() return db.profile.display.showItemType end,
        set = function(value) db.profile.display.showItemType = value end,
    }))

    stack:AddChild(LDF.CreateToggle(section.content, {
        label = L["Show Quantity"],
        tooltip = L["Display the item quantity on toasts"],
        get = function() return db.profile.display.showQuantity end,
        set = function(value) db.profile.display.showQuantity = value end,
    }))

    stack:AddChild(LDF.CreateToggle(section.content, {
        label = L["Show Looter"],
        tooltip = L["Display who looted the item"],
        get = function() return db.profile.display.showLooter end,
        set = function(value) db.profile.display.showLooter = value end,
    }))

    stack:AddChild(LDF.CreateDropdown(section.content, {
        label = L["Gold Format"],
        tooltip = L["How to display gold amounts"],
        values = GOLD_FORMAT_VALUES,
        get = function() return db.profile.display.goldFormat end,
        set = function(value) db.profile.display.goldFormat = value end,
    }))

    return section
end

local function CreatePaddingSection(parent)
    local db = dtns.Addon.db
    local section = LDF.CreateSection(parent, L["Padding"], { collapsible = true })
    local stack = LDF.CreateStackLayout(section.content, "vertical")

    stack:AddChild(LDF.CreateSlider(section.content, {
        label = L["Vertical Padding"],
        tooltip = L["Vertical padding inside toasts in pixels"],
        min = 0, max = 20, step = 1,
        get = function() return db.profile.display.textPaddingV end,
        set = function(value)
            db.profile.display.textPaddingV = value
            dtns.ToastManager:UpdateLayout()
        end,
    }))

    stack:AddChild(LDF.CreateSlider(section.content, {
        label = L["Horizontal Padding"],
        tooltip = L["Horizontal padding inside toasts in pixels"],
        min = 0, max = 20, step = 1,
        get = function() return db.profile.display.textPaddingH end,
        set = function(value)
            db.profile.display.textPaddingH = value
            dtns.ToastManager:UpdateLayout()
        end,
    }))

    return section
end

local function CreateAnchorSection(parent)
    local section = LDF.CreateSection(parent, L["Anchor"])
    local stack = LDF.CreateStackLayout(section.content, "vertical")

    stack:AddChild(LDF.CreateToggle(section.content, {
        label = L["Unlock Anchor"],
        tooltip = L["Show and unlock the toast anchor for repositioning"],
        get = function()
            local anchor = _G["DragonToastAnchor"]
            return anchor and anchor.overlay and anchor.overlay:IsShown() or false
        end,
        set = function() dtns.ToastManager:ToggleLock() end,
    }))

    stack:AddChild(LDF.CreateButton(section.content, {
        text = L["Reset Position"],
        tooltip = L["Reset the anchor to the default position"],
        onClick = function()
            dtns.ToastManager:SetAnchor("RIGHT", -20, 0)
            dtns.Print(L["Anchor position reset to default."])
        end,
    }))

    return section
end

-------------------------------------------------------------------------------
-- Build the Display tab content
-------------------------------------------------------------------------------

local function CreateContent(parent)
    dtns = ns.dtns
    local stack = LDF.CreateStackLayout(parent, "vertical")
    stack:AddChild(CreateLayoutSection(parent))
    stack:AddChild(CreateSizeSection(parent))
    stack:AddChild(CreateContentSection(parent))
    stack:AddChild(CreatePaddingSection(parent))
    stack:AddChild(CreateAnchorSection(parent))
end

-------------------------------------------------------------------------------
-- Register tab
-------------------------------------------------------------------------------

ns.Tabs = ns.Tabs or {}
ns.Tabs[#ns.Tabs + 1] = {
    id = "display",
    label = L["Display"],
    order = 3,
    createFunc = CreateContent,
}
