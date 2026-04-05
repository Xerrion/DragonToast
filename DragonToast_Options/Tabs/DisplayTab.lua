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
-- Creates the "Layout" section in the Display tab and places its controls into the given parent.
-- The section exposes controls bound to `db.profile.display`: max toasts, grow direction, and spacing.
-- The grow direction control triggers toast repositioning when changed;
-- the spacing control triggers a layout update when changed.
-- @param parent UI frame that will contain the section's widgets.
-- @param yOffset Number vertical offset (in pixels) from the parent's top where the section should start.
-- @return Number the updated vertical offset after placing the section's widgets.

local function CreateLayoutSection(parent, yOffset)
    local db = dtns.Addon.db

    local header = W.CreateHeader(parent, L["Layout"])
    LC.AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - LC.SPACING_AFTER_HEADER

    local maxToasts = W.CreateSlider(parent, {
        label = L["Max Toasts"],
        tooltip = L["Maximum number of toasts visible at once"],
        min = 1, max = 15, step = 1,
        get = function() return db.profile.display.maxToasts end,
        set = function(value) db.profile.display.maxToasts = value end,
    })
    LC.AnchorWidget(maxToasts, parent, yOffset)
    yOffset = yOffset - maxToasts:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

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
    LC.AnchorWidget(growDirection, parent, yOffset)
    yOffset = yOffset - growDirection:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

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
    LC.AnchorWidget(spacing, parent, yOffset)
    yOffset = yOffset - spacing:GetHeight()

    return yOffset
end

-- Creates the "Toast Size" section inside the Display tab and positions its widgets.
-- @param parent The parent UI frame to anchor the section's widgets to.
-- @param yOffset The starting vertical offset (in pixels) for placing
--   the section; positive or negative values are allowed.
-- @return The updated vertical offset (in pixels) after placing the section's widgets.
local function CreateSizeSection(parent, yOffset)
    local db = dtns.Addon.db

    yOffset = yOffset - LC.SPACING_BETWEEN_SECTIONS

    local header = W.CreateHeader(parent, L["Toast Size"])
    LC.AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - LC.SPACING_AFTER_HEADER

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
    LC.AnchorWidget(toastWidth, parent, yOffset)
    yOffset = yOffset - toastWidth:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

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
    LC.AnchorWidget(toastHeight, parent, yOffset)
    yOffset = yOffset - toastHeight:GetHeight()

    return yOffset
end

-- Builds the "Content" section of the Display tab, creating and anchoring content-related controls.
-- The created controls read and write values in `db.profile.display`. Controls that affect layout will
-- trigger a layout update when changed.
-- @param parent UI frame that will contain the section's widgets.
-- @param yOffset Starting vertical offset (number) where the section
--   should be placed; positive or negative coordinate as used by the
--   caller.
-- @return number The updated vertical offset after placing the section's widgets.
local function CreateContentSection(parent, yOffset)
    local db = dtns.Addon.db

    yOffset = yOffset - LC.SPACING_BETWEEN_SECTIONS

    local header = W.CreateHeader(parent, L["Content"])
    LC.AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - LC.SPACING_AFTER_HEADER

    local showIcon = W.CreateToggle(parent, {
        label = L["Show Icon"],
        tooltip = L["Display the item icon on toasts"],
        get = function() return db.profile.display.showIcon end,
        set = function(value)
            db.profile.display.showIcon = value
            dtns.ToastManager:UpdateLayout()
        end,
    })
    LC.AnchorWidget(showIcon, parent, yOffset)
    yOffset = yOffset - showIcon:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

    local showItemLevel = W.CreateToggle(parent, {
        label = L["Show Item Level"],
        tooltip = L["Display the item level on toasts"],
        get = function() return db.profile.display.showItemLevel end,
        set = function(value) db.profile.display.showItemLevel = value end,
    })
    LC.AnchorWidget(showItemLevel, parent, yOffset)
    yOffset = yOffset - showItemLevel:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

    local showItemType = W.CreateToggle(parent, {
        label = L["Show Item Type"],
        tooltip = L["Display the item type on toasts"],
        get = function() return db.profile.display.showItemType end,
        set = function(value) db.profile.display.showItemType = value end,
    })
    LC.AnchorWidget(showItemType, parent, yOffset)
    yOffset = yOffset - showItemType:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

    local showQuantity = W.CreateToggle(parent, {
        label = L["Show Quantity"],
        tooltip = L["Display the item quantity on toasts"],
        get = function() return db.profile.display.showQuantity end,
        set = function(value) db.profile.display.showQuantity = value end,
    })
    LC.AnchorWidget(showQuantity, parent, yOffset)
    yOffset = yOffset - showQuantity:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

    local showLooter = W.CreateToggle(parent, {
        label = L["Show Looter"],
        tooltip = L["Display who looted the item"],
        get = function() return db.profile.display.showLooter end,
        set = function(value) db.profile.display.showLooter = value end,
    })
    LC.AnchorWidget(showLooter, parent, yOffset)
    yOffset = yOffset - showLooter:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

    local goldFormat = W.CreateDropdown(parent, {
        label = L["Gold Format"],
        tooltip = L["How to display gold amounts"],
        values = GOLD_FORMAT_VALUES,
        get = function() return db.profile.display.goldFormat end,
        set = function(value) db.profile.display.goldFormat = value end,
    })
    LC.AnchorWidget(goldFormat, parent, yOffset)
    yOffset = yOffset - goldFormat:GetHeight()

    return yOffset
end

-- Creates the "Padding" section inside the given parent, adding vertical
-- and horizontal padding sliders that update the saved display padding
-- and refresh toast layout.
-- @param parent The parent UI frame to attach the section to.
-- @param yOffset The current vertical offset (in pixels) where the section should start; used for positioning.
-- @return The updated vertical offset after placing the section's widgets.
local function CreatePaddingSection(parent, yOffset)
    local db = dtns.Addon.db

    yOffset = yOffset - LC.SPACING_BETWEEN_SECTIONS

    local header = W.CreateHeader(parent, L["Padding"])
    LC.AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - LC.SPACING_AFTER_HEADER

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
    LC.AnchorWidget(vertPadding, parent, yOffset)
    yOffset = yOffset - vertPadding:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

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
    LC.AnchorWidget(horzPadding, parent, yOffset)
    yOffset = yOffset - horzPadding:GetHeight()

    return yOffset
end

-- Creates the "Anchor" section in the Display tab, adding an unlock toggle and a reset-position button.
-- @param parent The parent UI frame to which the section's widgets will be attached.
-- @param yOffset The starting vertical offset (number); widgets are placed relative to this value.
-- @return The updated vertical offset after placing the section's header and widgets.
local function CreateAnchorSection(parent, yOffset)
    yOffset = yOffset - LC.SPACING_BETWEEN_SECTIONS

    local header = W.CreateHeader(parent, L["Anchor"])
    LC.AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - LC.SPACING_AFTER_HEADER

    local unlockAnchor = W.CreateToggle(parent, {
        label = L["Unlock Anchor"],
        tooltip = L["Show and unlock the toast anchor for repositioning"],
        get = function()
            local anchor = _G["DragonToastAnchor"]
            return anchor and anchor.overlay and anchor.overlay:IsShown() or false
        end,
        set = function() dtns.ToastManager:ToggleLock() end,
    })
    LC.AnchorWidget(unlockAnchor, parent, yOffset)
    yOffset = yOffset - unlockAnchor:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

    local resetButton = W.CreateButton(parent, {
        text = L["Reset Position"],
        tooltip = L["Reset the anchor to the default position"],
        onClick = function()
            dtns.ToastManager:SetAnchor("RIGHT", -20, 0)
            dtns.Print(L["Anchor position reset to default."])
        end,
    })
    LC.AnchorWidget(resetButton, parent, yOffset)
    yOffset = yOffset - resetButton:GetHeight()

    return yOffset
end

-------------------------------------------------------------------------------
-- Build the Display tab content
-------------------------------------------------------------------------------

local function CreateContent(parent)
    dtns = ns.dtns
    local yOffset = LC.PADDING_TOP

    yOffset = CreateLayoutSection(parent, yOffset)
    yOffset = CreateSizeSection(parent, yOffset)
    yOffset = CreateContentSection(parent, yOffset)
    yOffset = CreatePaddingSection(parent, yOffset)
    yOffset = CreateAnchorSection(parent, yOffset)

    parent:SetHeight(math_abs(yOffset) + LC.PADDING_BOTTOM)
end

-------------------------------------------------------------------------------
-- Register tab
-------------------------------------------------------------------------------

ns.Tabs[#ns.Tabs + 1] = {
    id = "display",
    label = L["Display"],
    order = 3,
    createFunc = CreateContent,
}
