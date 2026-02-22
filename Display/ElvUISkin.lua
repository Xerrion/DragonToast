-------------------------------------------------------------------------------
-- ElvUISkin.lua
-- ElvUI detection and skin matching for DragonToast
--
-- Supported versions: TBC Anniversary, Retail
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

-------------------------------------------------------------------------------
-- State
-------------------------------------------------------------------------------

local elvuiDetected = false
local E = nil -- ElvUI engine reference

-------------------------------------------------------------------------------
-- Detection
-------------------------------------------------------------------------------

function ns.ElvUISkin.IsElvUI()
    return elvuiDetected
end

local function DetectElvUI()
    if ElvUI and ElvUI[1] then
        E = ElvUI[1]
        elvuiDetected = true
        ns.DebugPrint("ElvUI detected — skin matching available")
        return true
    end
    elvuiDetected = false
    return false
end

-------------------------------------------------------------------------------
-- Media Accessors
-------------------------------------------------------------------------------

function ns.ElvUISkin.GetFont()
    if elvuiDetected and E and E.media and E.media.normFont then
        return E.media.normFont
    end
    return nil -- use default
end

function ns.ElvUISkin.GetBorderColor()
    if elvuiDetected and E and E.media and E.media.bordercolor then
        return E.media.bordercolor[1], E.media.bordercolor[2], E.media.bordercolor[3], E.media.bordercolor[4] or 1
    end
    return 0.3, 0.3, 0.3, 0.8 -- default
end

-------------------------------------------------------------------------------
-- Apply Skin to a Single Toast Frame
-------------------------------------------------------------------------------

function ns.ElvUISkin.SkinToast(frame)
    if not elvuiDetected or not ns.Addon.db.profile.elvui.useSkin then
        return -- nothing to do
    end

    local db = ns.Addon.db.profile

    -- Apply ElvUI font FACE only — respect user's sizes and outline from Appearance
    local font = ns.ElvUISkin.GetFont()
    if font then
        local fontSize = db.appearance.fontSize
        local secondaryFontSize = db.appearance.secondaryFontSize
        local fontOutline = db.appearance.fontOutline
        frame.itemName:SetFont(font, fontSize, fontOutline)
        frame.quantity:SetFont(font, secondaryFontSize, fontOutline)
        frame.itemLevel:SetFont(font, secondaryFontSize, fontOutline)
        frame.itemType:SetFont(font, secondaryFontSize, fontOutline)
        frame.looter:SetFont(font, secondaryFontSize, fontOutline)
    end

    -- Background: respect user's Appearance settings (already applied by PopulateToast)
    -- Do NOT override with ElvUI backdrop color

    -- Apply ElvUI border color (unless quality border is active — quality takes priority)
    if not db.appearance.qualityBorder then
        local br, bg, bb, ba = ns.ElvUISkin.GetBorderColor()
        frame:SetBackdropBorderColor(br, bg, bb, ba)
        frame.iconBorder:SetColorTexture(br, bg, bb, ba)
    end
end

-------------------------------------------------------------------------------
-- Apply (called from Init.lua OnEnable)
-------------------------------------------------------------------------------

function ns.ElvUISkin.Apply()
    DetectElvUI()

    if not elvuiDetected then
        ns.DebugPrint("ElvUI not detected — using default skin")
    end
end
