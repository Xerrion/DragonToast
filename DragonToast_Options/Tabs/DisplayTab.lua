-------------------------------------------------------------------------------
-- DisplayTab.lua
-- Display settings tab: layout, toast size, content, padding, anchor
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

-------------------------------------------------------------------------------
-- Cached globals
-------------------------------------------------------------------------------

local math_abs = math.abs

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
-- Helpers
-------------------------------------------------------------------------------

local function AnchorWidget(widget, parent, yOffset)
    widget:SetPoint("TOPLEFT", parent, "TOPLEFT", PADDING_SIDE, yOffset)
    widget:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -PADDING_SIDE, yOffset)
end

-------------------------------------------------------------------------------
-- Section builders
-------------------------------------------------------------------------------

local function CreateLayoutSection(parent, yOffset)
    local W = ns.Widgets
    local db = dtns.Addon.db

    local header = W.CreateHeader(parent, L["Layout"])
    AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - SPACING_AFTER_HEADER

    local maxToasts = W.CreateSlider(parent, {
        label = L["Max Toasts"],
        tooltip = L["Maximum number of toasts visible at once"],
        min = 1, max = 15, step = 1,
        get = function() return db.profile.display.maxToasts end,
        set = function(value) db.profile.display.maxToasts = value end,
    })
    AnchorWidget(maxToasts, parent, yOffset)
    yOffset = yOffset - maxToasts:GetHeight() - SPACING_BETWEEN_WIDGETS

    local growDirection = W.CreateDropdown(parent, {
        label = L["Grow Direction"],
        tooltip = L["Direction toasts stack from the anchor"],
        values = GROW_DIRECTION_VALUES,
        get = function() return db.profile.display.growDirection end,
        set = function(value)
            db.profile.display.growDirection = value
            dtns.ToastManager:UpdatePositions()
        end,
    })
    AnchorWidget(growDirection, parent, yOffset)
    yOffset = yOffset - growDirection:GetHeight() - SPACING_BETWEEN_WIDGETS

    local spacing = W.CreateSlider(parent, {
        label = L["Spacing"],
        tooltip = L["Space between toasts in pixels"],
        min = 0, max = 20, step = 1,
        get = function() return db.profile.display.spacing end,
        set = function(value)
            db.profile.display.spacing = value
            dtns.ToastManager:UpdateLayout()
        end,
    })
    AnchorWidget(spacing, parent, yOffset)
    yOffset = yOffset - spacing:GetHeight()

    return yOffset
end

local function CreateSizeSection(parent, yOffset)
    local W = ns.Widgets
    local db = dtns.Addon.db

    yOffset = yOffset - SPACING_BETWEEN_SECTIONS

    local header = W.CreateHeader(parent, L["Toast Size"])
    AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - SPACING_AFTER_HEADER

    local toastWidth = W.CreateSlider(parent, {
        label = L["Toast Width"],
        tooltip = L["Width of each toast in pixels"],
        min = 200, max = 600, step = 10,
        get = function() return db.profile.display.toastWidth end,
        set = function(value)
            db.profile.display.toastWidth = value
            dtns.ToastManager:UpdateLayout()
        end,
    })
    AnchorWidget(toastWidth, parent, yOffset)
    yOffset = yOffset - toastWidth:GetHeight() - SPACING_BETWEEN_WIDGETS

    local toastHeight = W.CreateSlider(parent, {
        label = L["Toast Height"],
        tooltip = L["Height of each toast in pixels"],
        min = 32, max = 80, step = 2,
        get = function() return db.profile.display.toastHeight end,
        set = function(value)
            db.profile.display.toastHeight = value
            dtns.ToastManager:UpdateLayout()
        end,
    })
    AnchorWidget(toastHeight, parent, yOffset)
    yOffset = yOffset - toastHeight:GetHeight()

    return yOffset
end

local function CreateContentSection(parent, yOffset)
    local W = ns.Widgets
    local db = dtns.Addon.db

    yOffset = yOffset - SPACING_BETWEEN_SECTIONS

    local header = W.CreateHeader(parent, L["Content"])
    AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - SPACING_AFTER_HEADER

    local showIcon = W.CreateToggle(parent, {
        label = L["Show Icon"],
        tooltip = L["Display the item icon on toasts"],
        get = function() return db.profile.display.showIcon end,
        set = function(value)
            db.profile.display.showIcon = value
            dtns.ToastManager:UpdateLayout()
        end,
    })
    AnchorWidget(showIcon, parent, yOffset)
    yOffset = yOffset - showIcon:GetHeight() - SPACING_BETWEEN_WIDGETS

    local showItemLevel = W.CreateToggle(parent, {
        label = L["Show Item Level"],
        tooltip = L["Display the item level on toasts"],
        get = function() return db.profile.display.showItemLevel end,
        set = function(value) db.profile.display.showItemLevel = value end,
    })
    AnchorWidget(showItemLevel, parent, yOffset)
    yOffset = yOffset - showItemLevel:GetHeight() - SPACING_BETWEEN_WIDGETS

    local showItemType = W.CreateToggle(parent, {
        label = L["Show Item Type"],
        tooltip = L["Display the item type on toasts"],
        get = function() return db.profile.display.showItemType end,
        set = function(value) db.profile.display.showItemType = value end,
    })
    AnchorWidget(showItemType, parent, yOffset)
    yOffset = yOffset - showItemType:GetHeight() - SPACING_BETWEEN_WIDGETS

    local showQuantity = W.CreateToggle(parent, {
        label = L["Show Quantity"],
        tooltip = L["Display the item quantity on toasts"],
        get = function() return db.profile.display.showQuantity end,
        set = function(value) db.profile.display.showQuantity = value end,
    })
    AnchorWidget(showQuantity, parent, yOffset)
    yOffset = yOffset - showQuantity:GetHeight() - SPACING_BETWEEN_WIDGETS

    local showLooter = W.CreateToggle(parent, {
        label = L["Show Looter"],
        tooltip = L["Display who looted the item"],
        get = function() return db.profile.display.showLooter end,
        set = function(value) db.profile.display.showLooter = value end,
    })
    AnchorWidget(showLooter, parent, yOffset)
    yOffset = yOffset - showLooter:GetHeight() - SPACING_BETWEEN_WIDGETS

    local goldFormat = W.CreateDropdown(parent, {
        label = L["Gold Format"],
        tooltip = L["How to display gold amounts"],
        values = GOLD_FORMAT_VALUES,
        get = function() return db.profile.display.goldFormat end,
        set = function(value) db.profile.display.goldFormat = value end,
    })
    AnchorWidget(goldFormat, parent, yOffset)
    yOffset = yOffset - goldFormat:GetHeight()

    return yOffset
end

local function CreatePaddingSection(parent, yOffset)
    local W = ns.Widgets
    local db = dtns.Addon.db

    yOffset = yOffset - SPACING_BETWEEN_SECTIONS

    local header = W.CreateHeader(parent, L["Padding"])
    AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - SPACING_AFTER_HEADER

    local vertPadding = W.CreateSlider(parent, {
        label = L["Vertical Padding"],
        tooltip = L["Vertical padding inside toasts in pixels"],
        min = 0, max = 20, step = 1,
        get = function() return db.profile.display.textPaddingV end,
        set = function(value)
            db.profile.display.textPaddingV = value
            dtns.ToastManager:UpdateLayout()
        end,
    })
    AnchorWidget(vertPadding, parent, yOffset)
    yOffset = yOffset - vertPadding:GetHeight() - SPACING_BETWEEN_WIDGETS

    local horzPadding = W.CreateSlider(parent, {
        label = L["Horizontal Padding"],
        tooltip = L["Horizontal padding inside toasts in pixels"],
        min = 0, max = 20, step = 1,
        get = function() return db.profile.display.textPaddingH end,
        set = function(value)
            db.profile.display.textPaddingH = value
            dtns.ToastManager:UpdateLayout()
        end,
    })
    AnchorWidget(horzPadding, parent, yOffset)
    yOffset = yOffset - horzPadding:GetHeight()

    return yOffset
end

local function CreateAnchorSection(parent, yOffset)
    local W = ns.Widgets

    yOffset = yOffset - SPACING_BETWEEN_SECTIONS

    local header = W.CreateHeader(parent, L["Anchor"])
    AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - SPACING_AFTER_HEADER

    local unlockAnchor = W.CreateToggle(parent, {
        label = L["Unlock Anchor"],
        tooltip = L["Show and unlock the toast anchor for repositioning"],
        get = function()
            local anchor = _G["DragonToastAnchor"]
            return anchor and anchor.overlay and anchor.overlay:IsShown() or false
        end,
        set = function() dtns.ToastManager:ToggleLock() end,
    })
    AnchorWidget(unlockAnchor, parent, yOffset)
    yOffset = yOffset - unlockAnchor:GetHeight() - SPACING_BETWEEN_WIDGETS

    local resetButton = W.CreateButton(parent, {
        text = L["Reset Position"],
        tooltip = L["Reset the anchor to the default position"],
        onClick = function()
            dtns.ToastManager:SetAnchor("RIGHT", -20, 0)
            dtns.Print(L["Anchor position reset to default."])
        end,
    })
    AnchorWidget(resetButton, parent, yOffset)
    yOffset = yOffset - resetButton:GetHeight()

    return yOffset
end

-------------------------------------------------------------------------------
-- Build the Display tab content
-------------------------------------------------------------------------------

local function CreateContent(parent)
    dtns = ns.dtns
    local yOffset = PADDING_TOP

    yOffset = CreateLayoutSection(parent, yOffset)
    yOffset = CreateSizeSection(parent, yOffset)
    yOffset = CreateContentSection(parent, yOffset)
    yOffset = CreatePaddingSection(parent, yOffset)
    yOffset = CreateAnchorSection(parent, yOffset)

    parent:SetHeight(math_abs(yOffset) + PADDING_BOTTOM)
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
