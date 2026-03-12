-------------------------------------------------------------------------------
-- LayoutConstants.lua
-- Shared layout constants and helpers for Options UI tabs
--
-- Supported versions: TBC Anniversary, Retail, MoP Classic
-------------------------------------------------------------------------------

local _, ns = ...

ns.LayoutConstants = {
    PADDING_SIDE = 10,
    PADDING_TOP = -10,
    SPACING_AFTER_HEADER = 8,
    SPACING_BETWEEN_WIDGETS = 6,
    SPACING_BETWEEN_SECTIONS = 16,
    PADDING_BOTTOM = 20,
}

--- Anchor a widget to fill the width of its parent with standard side padding.
function ns.LayoutConstants.AnchorWidget(widget, parent, yOffset)
    widget:SetPoint("TOPLEFT", parent, "TOPLEFT", ns.LayoutConstants.PADDING_SIDE, yOffset)
    widget:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -ns.LayoutConstants.PADDING_SIDE, yOffset)
end

--- Quality dropdown values shared across multiple tabs.
ns.LayoutConstants.QUALITY_VALUES = {
    { value = 0, text = "|cff9d9d9dPoor|r" },
    { value = 1, text = "|cffffffffCommon|r" },
    { value = 2, text = "|cff1eff00Uncommon|r" },
    { value = 3, text = "|cff0070ddRare|r" },
    { value = 4, text = "|cffa335eeEpic|r" },
    { value = 5, text = "|cffff8000Legendary|r" },
}
