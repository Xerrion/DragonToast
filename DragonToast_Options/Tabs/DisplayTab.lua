-------------------------------------------------------------------------------
-- DisplayTab.lua
-- Layout settings: size, spacing, stack, and exact screen position
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

local ANCHOR_VALUES = {
    { value = "TOPLEFT", text = L["Top Left"] },
    { value = "TOP", text = L["Top"] },
    { value = "TOPRIGHT", text = L["Top Right"] },
    { value = "LEFT", text = L["Left"] },
    { value = "CENTER", text = L["Center"] },
    { value = "RIGHT", text = L["Right"] },
    { value = "BOTTOMLEFT", text = L["Bottom Left"] },
    { value = "BOTTOM", text = L["Bottom"] },
    { value = "BOTTOMRIGHT", text = L["Bottom Right"] },
}

local function UpdateAnchor(key, value)
    local display = dtns.Addon.db.profile.display
    display[key] = value
    dtns.ToastManager.SetAnchor(display.anchorPoint, display.anchorX, display.anchorY)
    if ns.RefreshVisibleWidgets then ns.RefreshVisibleWidgets() end
end

local function SetAnchorOffset(key, value)
    local number = tonumber(value)
    if number and number == number and math.abs(number) < math.huge then
        UpdateAnchor(key, number)
    elseif ns.RefreshVisibleWidgets then
        ns.RefreshVisibleWidgets()
    end
end

-------------------------------------------------------------------------------
-- Section builders
-- Stack capacity and growth direction retain their existing display settings.
-- Changing growth direction repositions the live stack.
-- @param parent UI frame that will contain the section's widgets.
-- @param yOffset Number vertical offset (in pixels) from the parent's top where the section should start.
-- @return Number the updated vertical offset after placing the section's widgets.

local function CreateLayoutSection(parent, yOffset)
    local db = dtns.Addon.db

    local section = W.CreateSection(parent, L["Stack"])
    local content = section.content
    local innerY = -LC.SECTION_PADDING_TOP

    local maxToasts = W.CreateSlider(content, {
        label = L["Max Toasts"],
        tooltip = L["Maximum number of toasts visible at once"],
        min = 1, max = 15, step = 1,
        get = function() return db.profile.display.maxToasts end,
        set = function(value) db.profile.display.maxToasts = value end,
    })
    innerY = LC.AnchorWidget(maxToasts, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local growDirection = W.CreateDropdown(content, {
        label = L["Grow Direction"],
        tooltip = L["Direction toasts stack from the anchor"],
        values = GROW_DIRECTION_VALUES,
        get = function() return db.profile.display.growDirection end,
        set = function(value)
            db.profile.display.growDirection = value
            dtns.ToastManager:UpdatePositions()
        end,
    })
    innerY = LC.AnchorWidget(growDirection, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    section:SetContentHeight(math_abs(innerY) + LC.SECTION_PADDING_BOTTOM)
    return LC.AnchorSection(section, parent, yOffset) - LC.SPACING_BETWEEN_SECTIONS
end

-- Creates the "Toast Size" section inside the Display tab and positions its widgets.
-- @param parent The parent UI frame to anchor the section's widgets to.
-- @param yOffset The starting vertical offset (in pixels) for placing
--   the section; positive or negative values are allowed.
-- @return The updated vertical offset (in pixels) after placing the section's widgets.
local function CreateSizeSection(parent, yOffset)
    local db = dtns.Addon.db

    local section = W.CreateSection(parent, L["Toast Size"])
    local content = section.content
    local innerY = -LC.SECTION_PADDING_TOP

    local toastWidth = W.CreateSlider(content, {
        label = L["Toast Width"],
        tooltip = L["Width of each toast in pixels"],
        min = 200, max = 600, step = 10,
        get = function() return db.profile.display.toastWidth end,
        set = function(value)
            db.profile.display.toastWidth = value
            dtns.ToastManager:UpdateLayout()
        end,
    })
    innerY = LC.AnchorWidget(toastWidth, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local toastHeight = W.CreateSlider(content, {
        label = L["Toast Height"],
        tooltip = L["Height of each toast in pixels"],
        min = 32, max = 80, step = 2,
        get = function() return db.profile.display.toastHeight end,
        set = function(value)
            db.profile.display.toastHeight = value
            dtns.ToastManager:UpdateLayout()
        end,
    })
    innerY = LC.AnchorWidget(toastHeight, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local iconSize = W.CreateSlider(content, {
        label = L["Icon Size"],
        tooltip = L["Size of the item icon on toasts"],
        min = 16, max = 64, step = 2,
        get = function() return db.profile.appearance.iconSize end,
        set = function(value) db.profile.appearance.iconSize = value; LC.NotifyAppearanceChange() end,
    })
    innerY = LC.AnchorWidget(iconSize, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    section:SetContentHeight(math_abs(innerY) + LC.SECTION_PADDING_BOTTOM)
    return LC.AnchorSection(section, parent, yOffset) - LC.SPACING_BETWEEN_SECTIONS
end

-- Group the horizontal and vertical text padding with spacing between toasts.
-- @param parent The parent UI frame to attach the section to.
-- @param yOffset The current vertical offset (in pixels) where the section should start; used for positioning.
-- @return The updated vertical offset after placing the section's widgets.
local function CreatePaddingSection(parent, yOffset)
    local db = dtns.Addon.db

    local section = W.CreateSection(parent, L["Spacing"])
    local content = section.content
    local innerY = -LC.SECTION_PADDING_TOP

    local horzPadding = W.CreateSlider(content, {
        label = L["Horizontal Padding"],
        tooltip = L["Horizontal padding inside toasts in pixels"],
        min = 0, max = 20, step = 1,
        get = function() return db.profile.display.textPaddingH end,
        set = function(value)
            db.profile.display.textPaddingH = value
            dtns.ToastManager:UpdateLayout()
        end,
    })
    innerY = LC.AnchorWidget(horzPadding, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local vertPadding = W.CreateSlider(content, {
        label = L["Vertical Padding"],
        tooltip = L["Vertical padding inside toasts in pixels"],
        min = 0, max = 20, step = 1,
        get = function() return db.profile.display.textPaddingV end,
        set = function(value)
            db.profile.display.textPaddingV = value
            dtns.ToastManager:UpdateLayout()
        end,
    })
    innerY = LC.AnchorWidget(vertPadding, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local spacing = W.CreateSlider(content, {
        label = L["Spacing"],
        tooltip = L["Space between toasts in pixels"],
        min = 0, max = 20, step = 1,
        get = function() return db.profile.display.spacing end,
        set = function(value)
            db.profile.display.spacing = value
            dtns.ToastManager:UpdateLayout()
        end,
    })
    innerY = LC.AnchorWidget(spacing, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    section:SetContentHeight(math_abs(innerY) + LC.SECTION_PADDING_BOTTOM)
    return LC.AnchorSection(section, parent, yOffset) - LC.SPACING_BETWEEN_SECTIONS
end

-- Position controls update the live anchor; the pinned preview owns its own position.
-- @param parent The parent UI frame to which the section's widgets will be attached.
-- @param yOffset The starting vertical offset (number); widgets are placed relative to this value.
-- @return The updated vertical offset after placing the section's header and widgets.
local function CreateAnchorSection(parent, yOffset)
    local section = W.CreateSection(parent, L["Position"])
    local content = section.content
    local innerY = -LC.SECTION_PADDING_TOP

    local point = W.CreateDropdown(content, {
        label = L["Anchor Point"],
        tooltip = L["Screen point used as the origin for the toast position"],
        values = ANCHOR_VALUES,
        get = function() return dtns.Addon.db.profile.display.anchorPoint end,
        set = function(value) UpdateAnchor("anchorPoint", value) end,
    })
    innerY = LC.AnchorWidget(point, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local offsetX = W.CreateTextInput(content, {
        label = L["Horizontal Offset"],
        tooltip = L["Horizontal distance from the anchor point; positive moves right"],
        get = function() return tostring(dtns.Addon.db.profile.display.anchorX) end,
        set = function(value) SetAnchorOffset("anchorX", value) end,
    })
    innerY = LC.AnchorWidget(offsetX, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local offsetY = W.CreateTextInput(content, {
        label = L["Vertical Offset"],
        tooltip = L["Vertical distance from the anchor point; positive moves up"],
        get = function() return tostring(dtns.Addon.db.profile.display.anchorY) end,
        set = function(value) SetAnchorOffset("anchorY", value) end,
    })
    innerY = LC.AnchorWidget(offsetY, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local unlockAnchor = W.CreateToggle(content, {
        label = L["Unlock Anchor"],
        tooltip = L["Show and unlock the toast anchor for repositioning"],
        get = function()
            local anchor = _G["DragonToastAnchor"]
            return anchor and anchor.overlay and anchor.overlay:IsShown() or false
        end,
        set = function() dtns.ToastManager:ToggleLock() end,
    })
    innerY = LC.AnchorWidget(unlockAnchor, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local resetButton = W.CreateButton(content, {
        text = L["Reset Position"],
        tooltip = L["Reset the anchor to the default position"],
        onClick = function()
            local display = dtns.Addon.db.profile.display
            display.anchorPoint, display.anchorX, display.anchorY = "RIGHT", -20, 0
            dtns.ToastManager.SetAnchor("RIGHT", -20, 0)
            if ns.RefreshVisibleWidgets then ns.RefreshVisibleWidgets() end
            dtns.Print(L["Anchor position reset to default."])
        end,
    })
    innerY = LC.AnchorWidget(resetButton, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    section:SetContentHeight(math_abs(innerY) + LC.SECTION_PADDING_BOTTOM)
    return LC.AnchorSection(section, parent, yOffset) - LC.SPACING_BETWEEN_SECTIONS
end

-------------------------------------------------------------------------------
-- Build the Display tab content
-------------------------------------------------------------------------------

local function CreateContent(parent)
    dtns = ns.dtns
    local yOffset = LC.PADDING_TOP

    yOffset = CreateSizeSection(parent, yOffset)
    yOffset = CreatePaddingSection(parent, yOffset)
    yOffset = CreateLayoutSection(parent, yOffset)
    yOffset = CreateAnchorSection(parent, yOffset)

    parent:SetHeight(math_abs(yOffset) + LC.PADDING_BOTTOM)
end

-------------------------------------------------------------------------------
-- Register tab
-------------------------------------------------------------------------------

ns.Tabs[#ns.Tabs + 1] = {
    id = "display",
    label = L["Layout"],
    order = 2,
    createFunc = CreateContent,
}
