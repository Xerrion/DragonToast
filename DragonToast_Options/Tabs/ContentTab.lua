-------------------------------------------------------------------------------
-- ContentTab.lua
-- Content visibility and money formatting; saved keys remain under display.
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...
local W = ns.DW.Widgets
local LC = ns.DW.LayoutConstants
local L = ns.L
local dtns

local GOLD_FORMAT_VALUES = {
    { value = "icons", text = L["Icons"] },
    { value = "short", text = L["Short (1g 2s 3c)"] },
    { value = "long", text = L["Long (1 Gold 2 Silver 3 Copper)"] },
}

local function CreateContentSection(parent, yOffset)
    local db = dtns.Addon.db

    local section = W.CreateSection(parent, L["Content"])
    local content = section.content
    local innerY = -LC.SECTION_PADDING_TOP

    local showIcon = W.CreateToggle(content, {
        label = L["Show Icon"],
        tooltip = L["Display the item icon on toasts"],
        get = function() return db.profile.display.showIcon end,
        set = function(value)
            db.profile.display.showIcon = value
            dtns.ToastManager:UpdateLayout()
        end,
    })
    innerY = LC.AnchorWidget(showIcon, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local showItemLevel = W.CreateToggle(content, {
        label = L["Show Item Level"],
        tooltip = L["Display the item level on toasts"],
        get = function() return db.profile.display.showItemLevel end,
        set = function(value)
            db.profile.display.showItemLevel = value
            LC.NotifyAppearanceChange()
        end,
    })
    innerY = LC.AnchorWidget(showItemLevel, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local showItemType = W.CreateToggle(content, {
        label = L["Show Item Type"],
        tooltip = L["Display the item type on toasts"],
        get = function() return db.profile.display.showItemType end,
        set = function(value)
            db.profile.display.showItemType = value
            LC.NotifyAppearanceChange()
        end,
    })
    innerY = LC.AnchorWidget(showItemType, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local showQuantity = W.CreateToggle(content, {
        label = L["Show Quantity"],
        tooltip = L["Display the item quantity on toasts"],
        get = function() return db.profile.display.showQuantity end,
        set = function(value)
            db.profile.display.showQuantity = value
            LC.NotifyAppearanceChange()
        end,
    })
    innerY = LC.AnchorWidget(showQuantity, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local itemCountToggle = W.CreateToggle(content, {
        label = L["Show Item Count"],
        tooltip = L["Display total inventory count of the looted item on the toast"],
        get = function() return db.profile.display.showItemCount end,
        set = function(value)
            db.profile.display.showItemCount = value
            dtns.ToastManager:UpdateLayout()
        end,
    })
    innerY = LC.AnchorWidget(itemCountToggle, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local showLooter = W.CreateToggle(content, {
        label = L["Show Looter"],
        tooltip = L["Display who looted the item"],
        get = function() return db.profile.display.showLooter end,
        set = function(value)
            db.profile.display.showLooter = value
            LC.NotifyAppearanceChange()
        end,
    })
    innerY = LC.AnchorWidget(showLooter, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    local goldFormat = W.CreateDropdown(content, {
        label = L["Gold Format"],
        tooltip = L["How to display gold amounts"],
        values = GOLD_FORMAT_VALUES,
        get = function() return db.profile.display.goldFormat end,
        set = function(value)
            db.profile.display.goldFormat = value
            LC.NotifyAppearanceChange()
        end,
    })
    innerY = LC.AnchorWidget(goldFormat, content, innerY) - LC.SPACING_BETWEEN_WIDGETS

    section:SetContentHeight(math.abs(innerY) + LC.SECTION_PADDING_BOTTOM)
    return LC.AnchorSection(section, parent, yOffset) - LC.SPACING_BETWEEN_SECTIONS
end


local function CreateContent(parent)
    dtns = ns.dtns
    local yOffset = CreateContentSection(parent, LC.PADDING_TOP)
    parent:SetHeight(math.abs(yOffset) + LC.PADDING_BOTTOM)
end

ns.Tabs[#ns.Tabs + 1] = {
    id = "content",
    label = L["Content"],
    order = 3,
    createFunc = CreateContent,
}
