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
        set = function(value)
            db.profile.display.showItemLevel = value
            LC.NotifyAppearanceChange()
        end,
    })
    LC.AnchorWidget(showItemLevel, parent, yOffset)
    yOffset = yOffset - showItemLevel:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

    local showItemType = W.CreateToggle(parent, {
        label = L["Show Item Type"],
        tooltip = L["Display the item type on toasts"],
        get = function() return db.profile.display.showItemType end,
        set = function(value)
            db.profile.display.showItemType = value
            LC.NotifyAppearanceChange()
        end,
    })
    LC.AnchorWidget(showItemType, parent, yOffset)
    yOffset = yOffset - showItemType:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

    local showQuantity = W.CreateToggle(parent, {
        label = L["Show Quantity"],
        tooltip = L["Display the item quantity on toasts"],
        get = function() return db.profile.display.showQuantity end,
        set = function(value)
            db.profile.display.showQuantity = value
            LC.NotifyAppearanceChange()
        end,
    })
    LC.AnchorWidget(showQuantity, parent, yOffset)
    yOffset = yOffset - showQuantity:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

    local itemCountToggle = W.CreateToggle(parent, {
        label = L["Show Item Count"],
        tooltip = L["Display total inventory count of the looted item on the toast"],
        get = function() return db.profile.display.showItemCount end,
        set = function(value)
            db.profile.display.showItemCount = value
            dtns.ToastManager:UpdateLayout()
        end,
    })
    LC.AnchorWidget(itemCountToggle, parent, yOffset)
    yOffset = yOffset - itemCountToggle:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

    local showLooter = W.CreateToggle(parent, {
        label = L["Show Looter"],
        tooltip = L["Display who looted the item"],
        get = function() return db.profile.display.showLooter end,
        set = function(value)
            db.profile.display.showLooter = value
            LC.NotifyAppearanceChange()
        end,
    })
    LC.AnchorWidget(showLooter, parent, yOffset)
    yOffset = yOffset - showLooter:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

    local goldFormat = W.CreateDropdown(parent, {
        label = L["Gold Format"],
        tooltip = L["How to display gold amounts"],
        values = GOLD_FORMAT_VALUES,
        get = function() return db.profile.display.goldFormat end,
        set = function(value)
            db.profile.display.goldFormat = value
            LC.NotifyAppearanceChange()
        end,
    })
    LC.AnchorWidget(goldFormat, parent, yOffset)
    yOffset = yOffset - goldFormat:GetHeight()

    return yOffset
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
