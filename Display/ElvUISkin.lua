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

function ns.ElvUISkin.GetFontSize()
    local db = ns.Addon.db.profile
    if db.appearance.fontSize then
        return db.appearance.fontSize
    end
    return 12
end

function ns.ElvUISkin.GetBackdropTexture()
    if elvuiDetected and E and E.media and E.media.blankTex then
        return E.media.blankTex
    end
    return nil -- use default ColorTexture
end

function ns.ElvUISkin.GetBorderColor()
    if elvuiDetected and E and E.media and E.media.bordercolor then
        return E.media.bordercolor[1], E.media.bordercolor[2], E.media.bordercolor[3], E.media.bordercolor[4] or 1
    end
    return 0.3, 0.3, 0.3, 0.8 -- default
end

function ns.ElvUISkin.GetBackdropColor()
    if elvuiDetected and E and E.media and E.media.backdropcolor then
        return E.media.backdropcolor[1], E.media.backdropcolor[2], E.media.backdropcolor[3], 0.8
    end
    return 0.05, 0.05, 0.05, 0.7 -- default
end

-------------------------------------------------------------------------------
-- Apply Skin to a Single Toast Frame
-------------------------------------------------------------------------------

function ns.ElvUISkin.SkinToast(frame)
    if not elvuiDetected or not ns.Addon.db.profile.elvui.useSkin then
        return -- nothing to do
    end

    local font = ns.ElvUISkin.GetFont()
    local fontSize = ns.ElvUISkin.GetFontSize()
    local br, bg, bb, ba = ns.ElvUISkin.GetBorderColor()
    local bgr, bgg, bgb, bga = ns.ElvUISkin.GetBackdropColor()

    -- Apply font
    if font then
        frame.itemName:SetFont(font, fontSize, "OUTLINE")
        frame.quantity:SetFont(font, fontSize - 2, "OUTLINE")
        frame.itemLevel:SetFont(font, fontSize - 2, "OUTLINE")
        frame.itemType:SetFont(font, fontSize - 3, "OUTLINE")
        frame.looter:SetFont(font, fontSize - 3, "OUTLINE")
    end

    -- Apply backdrop color
    frame.bg:SetColorTexture(bgr, bgg, bgb, bga)

    -- Apply border color (unless quality border is active — quality takes priority)
    if not ns.Addon.db.profile.appearance.qualityBorder then
        frame.borderTop:SetColorTexture(br, bg, bb, ba)
        frame.borderBottom:SetColorTexture(br, bg, bb, ba)
        frame.borderLeft:SetColorTexture(br, bg, bb, ba)
        frame.borderRight:SetColorTexture(br, bg, bb, ba)
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
