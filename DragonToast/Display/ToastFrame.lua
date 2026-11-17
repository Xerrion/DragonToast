-------------------------------------------------------------------------------
-- ToastFrame.lua
-- One toast card: construction, styling, content, interaction, and pooling
--
-- Supported versions: TBC Anniversary, Retail, MoP Classic
--
-- Structure of a card (the parent chain is a contract with ToastAnimations):
--
--   layoutFrame            Frame   owns the stack position (ToastAnimations)
--   `- frame               Button  visual root: background, mouse, effects
--      |- borderFrame      Frame   edge only, drawn just outside `frame`
--      `- content         Frame   everything visible, above the border
--         |- qualityGlow           accent strip on the left edge
--         |- iconFrame     Frame   icon + 1px border + quantity badge
--         `- itemName / itemLevel / itemCount / itemType / looter
--
-- Text slots:  topLeft = itemName      topRight    = itemLevel, itemCount
--              bottomLeft = itemType   bottomRight = looter
--
-- A card is re-rendered from scratch by Populate(); no state survives a
-- render except the backdrop cache keys, so stacking and live settings
-- changes cannot leave stale visuals behind.
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

-------------------------------------------------------------------------------
-- Cached WoW API
-------------------------------------------------------------------------------

local CreateFrame = CreateFrame
local GameTooltip = GameTooltip
local IsShiftKeyDown = IsShiftKeyDown
local ChatFrame_OpenChat = ChatFrame_OpenChat
local GetCoinTextureString = C_CurrencyInfo.GetCoinTextureString
local UIParent = UIParent
local STANDARD_TEXT_FONT = STANDARD_TEXT_FONT
local math_abs = math.abs
local math_ceil = math.ceil
local math_floor = math.floor
local math_min = math.min
local string_format = string.format
local table_concat = table.concat
local GetItemCount = C_Item and C_Item.GetItemCount or GetItemCount
local LSM = LibStub("LibSharedMedia-3.0")
local L = ns.L
local Utils = ns.ListenerUtils

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

-- Fallbacks for settings that may be absent from an older profile
local DEFAULT_TEXT_PADDING_V = 6
local DEFAULT_TEXT_PADDING_H = 8
local DEFAULT_BORDER_SIZE = 1
local DEFAULT_GLOW_WIDTH = 4
local DEFAULT_ICON_SIZE = 36
local DEFAULT_SECONDARY_FONT_SIZE = 10
local DEFAULT_ICON_CROP = 0.08

-- Frame stacking
local BASE_FRAME_LEVEL = 100
local LIVE_STRATA = "MEDIUM"
local HOVERED_STRATA = "HIGH"

-- Geometry
local ICON_INSET = 4          -- gap between the glow strip and the icon frame
local ICON_BORDER_SIZE = 1
local ICON_FRAME_EXTRA = 2 * ICON_BORDER_SIZE
local COUNT_LINE_GAP = 2      -- itemCount sits one secondary line below itemLevel
local SOLID_TEXTURE = "Interface\\Buttons\\WHITE8x8"

-- Colors
local GLOW_ALPHA = 0.8
local QUALITY_BORDER_ALPHA = 0.6
local DEFAULT_BORDER_COLOR = { r = 0.3, g = 0.3, b = 0.3, a = 0.8 }
local DEFAULT_BACKGROUND_COLOR = { r = 0.05, g = 0.05, b = 0.05 }
local WHITE = { r = 1, g = 1, b = 1 }
local GOLD = { r = 1, g = 0.82, b = 0 }
local MONEY_LOSS = { r = 1, g = 0.2, b = 0.2 }
local HONOR = { r = 1, g = 0.24, b = 0.17 }
local REPUTATION_GAIN = { r = 0.35, g = 0.85, b = 0.55 }
local REPUTATION_LOSS = { r = 0.95, g = 0.3, b = 0.3 }
local MUTED = { r = 0.7, g = 0.7, b = 0.7 }
local DIM = { r = 0.5, g = 0.5, b = 0.5 }
local ITEM_LEVEL = { r = 0.6, g = 0.6, b = 0.6 }
local SELF_LOOTER = { r = 0.3, g = 1.0, b = 0.3 }

local COPPER_PER_SILVER = 100
local COPPER_PER_GOLD = 10000
local MIN_STACK_FOR_BADGE = 1

-- Text slots that share the secondary font size
local SECONDARY_TEXT_FIELDS = { "itemLevel", "itemCount", "itemType", "looter" }

-- Fields Release() clears. Lifecycle ids and generations are deliberately
-- absent: ToastAnimations.StopAll() advances them so late callbacks of a
-- previous life can never act on a recycled frame.
local RELEASE_CLEARED_FIELDS = {
    "lootData", "_noAnimTimer", "_holdEndTime", "_holdRemaining", "_savedStrata",
    "_hoverHoldCallback", "_backdropKey", "_borderKey", "_phase",
    "_targetY", "_anchorY", "_layoutSlide", "_layoutPoint", "_layoutRelativeTo",
    "_layoutRelativePoint", "_layoutX", "_animationsEnabled", "_lifecycleConfig",
}

-------------------------------------------------------------------------------
-- Pool state
-------------------------------------------------------------------------------

local framePool = {}
local frameCount = 0

-------------------------------------------------------------------------------
-- What kind of reward is this?
-------------------------------------------------------------------------------

local KIND_ITEM = "item"
local KIND_XP = "xp"
local KIND_HONOR = "honor"
local KIND_REPUTATION = "reputation"

-- Non-item rewards show their source in the detail slot.
local DETAIL_FIELD = {
    [KIND_XP] = "mobName",
    [KIND_HONOR] = "victimName",
    [KIND_REPUTATION] = "factionName",
}

local function KindOf(lootData)
    if lootData.isXP then return KIND_XP end
    if lootData.isHonor then return KIND_HONOR end
    if lootData.isReputation then return KIND_REPUTATION end
    return KIND_ITEM
end

--- Only real items have a hyperlink worth showing or sharing.
local function IsLinkable(lootData)
    return lootData ~= nil and lootData.itemLink ~= nil and KindOf(lootData) == KIND_ITEM
end

--- The accent color: glow strip, quality border, and (for items) the name.
local function AccentColor(lootData, kind)
    if kind == KIND_XP then return GOLD end
    if kind == KIND_HONOR then return HONOR end
    if kind == KIND_REPUTATION then
        return lootData.reputationDirection == "loss" and REPUTATION_LOSS or REPUTATION_GAIN
    end

    local quality = lootData.itemQuality
    if quality then
        local color = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
        if not color and ns.QUALITY_COLORS then color = ns.QUALITY_COLORS[quality] end
        if color then return color end
    end
    return WHITE
end

-------------------------------------------------------------------------------
-- Small helpers
-------------------------------------------------------------------------------

local function SetTextRGB(fontString, color)
    fontString:SetTextColor(color.r, color.g, color.b)
end

local function ShowText(fontString, text, color)
    fontString:SetText(text)
    SetTextRGB(fontString, color)
    fontString:Show()
end

local function FormatMoney(copperAmount, format)
    if format ~= "short" and format ~= "long" then
        -- "icons" (default): Blizzard's inline coin textures
        return GetCoinTextureString(copperAmount)
    end

    local gold = math_floor(copperAmount / COPPER_PER_GOLD)
    local silver = math_floor((copperAmount % COPPER_PER_GOLD) / COPPER_PER_SILVER)
    local copper = copperAmount % COPPER_PER_SILVER
    local parts = {}

    if format == "short" then
        if gold > 0 then parts[#parts + 1] = gold .. "g" end
        if silver > 0 then parts[#parts + 1] = silver .. "s" end
        if copper > 0 then parts[#parts + 1] = copper .. "c" end
    else
        if gold > 0 then parts[#parts + 1] = GOLD_AMOUNT:format(gold) end
        if silver > 0 then parts[#parts + 1] = SILVER_AMOUNT:format(silver) end
        if copper > 0 then parts[#parts + 1] = COPPER_AMOUNT:format(copper) end
    end
    return table_concat(parts, " ")
end

local function FormatMoneyDisplay(lootData, format)
    local text = FormatMoney(math_abs(lootData.copperAmount), format)
    if lootData.moneyDirection == "loss" then return "-" .. text end
    return text
end

local function BuildItemTypeText(lootData)
    local text = lootData.itemType
    local subType = lootData.itemSubType
    if subType and subType ~= "" and subType ~= text then
        text = text .. " > " .. subType
    end
    return text
end

-------------------------------------------------------------------------------
-- Style: fonts, geometry, background, border, glow, icon
-------------------------------------------------------------------------------

local function ApplyFonts(frame, appearance)
    local path = LSM:Fetch("font", appearance.fontFace) or STANDARD_TEXT_FONT
    local outline = appearance.fontOutline or "OUTLINE"
    local secondarySize = appearance.secondaryFontSize or DEFAULT_SECONDARY_FONT_SIZE

    frame.itemName:SetFont(path, appearance.fontSize, outline)
    for _, field in ipairs(SECONDARY_TEXT_FIELDS) do
        frame[field]:SetFont(path, secondarySize, outline)
    end
end

--- Place the content frame, icon, and all five text slots.
local function ApplyLayout(frame, db, showIcon)
    local display, appearance = db.display, db.appearance
    local padV = display.textPaddingV or DEFAULT_TEXT_PADDING_V
    local padH = display.textPaddingH or DEFAULT_TEXT_PADDING_H
    local borderSize = appearance.borderSize or DEFAULT_BORDER_SIZE
    local contentInset = borderSize > 0 and (appearance.borderInset or 0) or 0
    local glowPad = appearance.qualityGlow and (appearance.glowWidth or DEFAULT_GLOW_WIDTH) or 0
    local iconSize = appearance.iconSize or DEFAULT_ICON_SIZE
    local secondarySize = appearance.secondaryFontSize or DEFAULT_SECONDARY_FONT_SIZE
    local content = frame.content

    content:ClearAllPoints()
    content:SetPoint("TOPLEFT", frame, "TOPLEFT", contentInset, -contentInset)
    content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -contentInset, contentInset)

    local name, typeLine = frame.itemName, frame.itemType
    name:ClearAllPoints()
    typeLine:ClearAllPoints()
    frame.itemLevel:ClearAllPoints()
    frame.itemCount:ClearAllPoints()
    frame.looter:ClearAllPoints()

    if showIcon then
        local iconFrame = frame.iconFrame
        iconFrame:SetSize(iconSize + ICON_FRAME_EXTRA, iconSize + ICON_FRAME_EXTRA)
        iconFrame:ClearAllPoints()
        iconFrame:SetPoint("LEFT", content, "LEFT", glowPad + ICON_INSET, 0)
        iconFrame:Show()
        frame.icon:SetSize(iconSize, iconSize)

        name:SetPoint("LEFT", iconFrame, "RIGHT", padH, 0)
        name:SetPoint("TOP", content, "TOP", 0, -padV)
        name:SetPoint("RIGHT", content, "RIGHT", -padH, 0)

        typeLine:SetPoint("LEFT", iconFrame, "RIGHT", padH, 0)
        typeLine:SetPoint("BOTTOM", content, "BOTTOM", 0, padV)
    else
        frame.iconFrame:Hide()

        name:SetPoint("TOPLEFT", content, "TOPLEFT", glowPad + padH, -padV)
        name:SetPoint("RIGHT", content, "RIGHT", -padH, 0)

        typeLine:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", glowPad + padH, padV)
    end

    -- Both right-hand slots anchor to content, so itemCount does not depend
    -- on whether itemLevel is shown.
    frame.itemLevel:SetPoint("TOPRIGHT", content, "TOPRIGHT", -padH, -padV)
    frame.itemCount:SetPoint("TOPRIGHT", content, "TOPRIGHT", -padH, -padV - secondarySize - COUNT_LINE_GAP)
    frame.looter:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -padH, padV)
end

--- Background on the root frame; the edge lives on borderFrame.
local function ApplyBackground(frame, appearance)
    local bgFile = LSM:Fetch("background", appearance.backgroundTexture or "Solid")
    local key = bgFile or ""
    if frame._backdropKey ~= key then
        frame:SetBackdrop({
            bgFile = bgFile,
            edgeFile = nil,
            edgeSize = 0,
            insets = { left = 0, right = 0, top = 0, bottom = 0 },
        })
        frame._backdropKey = key
    end

    local color = appearance.backgroundColor or DEFAULT_BACKGROUND_COLOR
    frame:SetBackdropColor(color.r, color.g, color.b, appearance.backgroundAlpha)
end

--- Edge texture just outside the card, tinted by quality or a chosen color.
local function ApplyBorder(frame, appearance, accent)
    local borderFrame = frame.borderFrame
    local size = appearance.borderSize or DEFAULT_BORDER_SIZE
    local edgeFile = size > 0 and LSM:Fetch("border", appearance.borderTexture or "None") or nil
    local key = (edgeFile or "") .. "|" .. tostring(size)

    if frame._borderKey ~= key then
        if edgeFile then
            borderFrame:SetBackdrop({
                bgFile = nil,
                edgeFile = edgeFile,
                edgeSize = size,
                insets = { left = 0, right = 0, top = 0, bottom = 0 },
            })
            borderFrame:Show()
        else
            borderFrame:SetBackdrop(nil)
            borderFrame:Hide()
        end
        frame._borderKey = key
    end

    -- Straddle the card edge so the texture overlaps the background.
    local offset = math_ceil(size / 2)
    borderFrame:ClearAllPoints()
    borderFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", -offset, offset)
    borderFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", offset, -offset)

    local color, alpha
    if appearance.qualityBorder then
        color = accent
        alpha = appearance.qualityBorderAlpha or QUALITY_BORDER_ALPHA
    else
        color = appearance.borderColor or DEFAULT_BORDER_COLOR
        alpha = appearance.borderAlpha or DEFAULT_BORDER_COLOR.a
    end
    borderFrame:SetBackdropBorderColor(color.r, color.g, color.b, alpha)
    frame.iconFrame:SetBackdropBorderColor(color.r, color.g, color.b, alpha)
end

local function ApplyGlow(frame, appearance, accent)
    local glow = frame.qualityGlow
    glow:ClearAllPoints()
    glow:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 0, 0)
    glow:SetPoint("BOTTOMLEFT", frame.content, "BOTTOMLEFT", 0, 0)

    if not appearance.qualityGlow then
        glow:Hide()
        return
    end

    local alpha = appearance.glowAlpha or GLOW_ALPHA
    glow:SetWidth(appearance.glowWidth or DEFAULT_GLOW_WIDTH)
    local statusBar = LSM:Fetch("statusbar", appearance.statusBarTexture)
    if statusBar then
        glow:SetTexture(statusBar)
        glow:SetVertexColor(accent.r, accent.g, accent.b, alpha)
    else
        glow:SetColorTexture(accent.r, accent.g, accent.b, alpha)
    end
    glow:Show()
end

local function ApplyIcon(frame, appearance, lootData)
    local crop = appearance.iconCrop or DEFAULT_ICON_CROP
    frame.icon:SetTexture(lootData.itemIcon or Utils.QUESTION_MARK_ICON)
    frame.icon:SetTexCoord(crop, 1 - crop, crop, 1 - crop)
    frame.icon:Show()
end

-------------------------------------------------------------------------------
-- Content: what each kind of reward says
-------------------------------------------------------------------------------

--- XP, honor, and reputation: a headline, the source, and always "You".
local function PresentReward(frame, lootData, db, kind, accent)
    ShowText(frame.itemName, lootData.itemName, accent)
    frame.quantity:Hide()
    frame.itemLevel:Hide()
    frame.itemCount:Hide()

    local detail = lootData[DETAIL_FIELD[kind]]
    if detail and detail ~= "" then
        ShowText(frame.itemType, detail, MUTED)
    else
        frame.itemType:Hide()
    end

    if db.display.showLooter then
        ShowText(frame.looter, L["You"], SELF_LOOTER)
    else
        frame.looter:Hide()
    end
end

--- Items, currencies, and money.
local function PresentItem(frame, lootData, db, accent)
    local display = db.display
    local isMoney = lootData.copperAmount and lootData.itemSubType == "Gold"

    -- Headline: money amount or item name, colored by what it is
    if isMoney then
        frame.itemName:SetText(FormatMoneyDisplay(lootData, display.goldFormat))
    else
        frame.itemName:SetText(lootData.itemName)
    end
    if lootData.moneyDirection == "loss" then
        SetTextRGB(frame.itemName, MONEY_LOSS)
    elseif lootData.isCurrency then
        SetTextRGB(frame.itemName, GOLD)
    else
        SetTextRGB(frame.itemName, accent)
    end

    -- Stack badge on the icon
    if display.showQuantity and lootData.quantity and lootData.quantity > MIN_STACK_FOR_BADGE then
        frame.quantity:SetText(lootData.quantity)
        frame.quantity:Show()
    else
        frame.quantity:Hide()
    end

    -- Item level (not meaningful for currencies)
    if display.showItemLevel and lootData.itemLevel and lootData.itemLevel > 0
        and not lootData.isCurrency then
        ShowText(frame.itemLevel, string_format(L["ilvl %s"], lootData.itemLevel), ITEM_LEVEL)
    else
        frame.itemLevel:Hide()
    end

    -- Bag count: GetItemCount reads the local inventory, so only our own loot
    if display.showItemCount and lootData.isSelf and lootData.itemID and not lootData.isCurrency then
        local count = GetItemCount(lootData.itemID) or 0
        ShowText(frame.itemCount, string_format(L["x%d in bags"], count), DIM)
    else
        frame.itemCount:Hide()
    end

    -- Type > Subtype
    if display.showItemType and lootData.itemType and not lootData.isCurrency then
        ShowText(frame.itemType, BuildItemTypeText(lootData), DIM)
    else
        frame.itemType:Hide()
    end

    -- Looter: ourselves as "You", anyone else by name
    if display.showLooter and lootData.looter then
        if lootData.isSelf then
            ShowText(frame.looter, L["You"], SELF_LOOTER)
        else
            ShowText(frame.looter, lootData.looter, MUTED)
        end
    else
        frame.looter:Hide()
    end
end

-------------------------------------------------------------------------------
-- Render a card from loot data and the current profile
-------------------------------------------------------------------------------

local function Render(frame, lootData)
    frame.lootData = lootData
    local db = ns.Addon.db.profile
    local appearance, display = db.appearance, db.display
    local kind = KindOf(lootData)
    local accent = AccentColor(lootData, kind)
    local showIcon = display.showIcon ~= false

    frame:SetSize(display.toastWidth, display.toastHeight)
    frame.layoutFrame:SetSize(display.toastWidth, display.toastHeight)

    ApplyFonts(frame, appearance)
    ApplyLayout(frame, db, showIcon)
    ApplyBackground(frame, appearance)
    ApplyBorder(frame, appearance, accent)
    ApplyGlow(frame, appearance, accent)
    if showIcon then ApplyIcon(frame, appearance, lootData) end

    if kind == KIND_ITEM then
        PresentItem(frame, lootData, db, accent)
    else
        PresentReward(frame, lootData, db, kind, accent)
    end

    -- The ElvUI skin runs last so it can respect, never override, user style.
    if ns.ElvUISkin and ns.ElvUISkin.SkinToast then
        ns.ElvUISkin.SkinToast(frame)
    end
end

-------------------------------------------------------------------------------
-- Interaction (live cards only)
-------------------------------------------------------------------------------

-- Explicit geometry edits end hover just as a physical mouse leave does.
-- Callers notify the manager after changing the hover state.
function ns.ToastFrame.ClearHover(frame)
    if frame._isPooled or not frame._isHovered then return false end
    frame._isHovered = false
    if frame._savedStrata then
        frame:SetFrameStrata(frame._savedStrata)
        frame._savedStrata = nil
    end
    GameTooltip:Hide()
    ns.ToastAnimations.ResumeFromHover(frame)
    return true
end

local function OnClick(self)
    if self._isPooled then return end
    if IsShiftKeyDown() and IsLinkable(self.lootData) then
        ChatFrame_OpenChat(self.lootData.itemLink)
    elseif ns.ToastManager.DismissToast then
        ns.ToastManager.DismissToast(self)
    end
end

local function OnEnter(self)
    if self._isPooled then return end
    if IsLinkable(self.lootData) then
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetHyperlink(self.lootData.itemLink)
        GameTooltip:Show()
    end

    local db = ns.Addon.db
    if not db or not db.profile.animation.pauseOnHover then return end
    -- Entrances are never interrupted; an already-hovered card needs nothing.
    if self._isHovered or self._phase == nil or self._phase == "entrance" then return end

    self._isHovered = true
    self._savedStrata = self:GetFrameStrata()
    self:SetFrameStrata(HOVERED_STRATA)
    ns.ToastAnimations.PauseForHover(self)
    if ns.ToastManager.OnHoverChanged then ns.ToastManager.OnHoverChanged(self) end
end

local function OnLeave(self)
    GameTooltip:Hide()
    -- Hiding a released frame can generate OnLeave. It must not resume a timer
    -- or reflow the stack once the frame is back in the pool, and it resumes
    -- the mode this lifecycle started with even if settings changed meanwhile.
    if not ns.ToastFrame.ClearHover(self) then return end
    if not self._isPooled and ns.ToastManager.OnHoverChanged then
        ns.ToastManager.OnHoverChanged(self)
    end
end

local function MakeInteractive(frame)
    frame:EnableMouse(true)
    frame:RegisterForClicks("LeftButtonUp")
    frame:SetScript("OnClick", OnClick)
    frame:SetScript("OnEnter", OnEnter)
    frame:SetScript("OnLeave", OnLeave)
end

-------------------------------------------------------------------------------
-- Construction
-------------------------------------------------------------------------------

local function CreateText(parent, template, justify)
    local fontString = parent:CreateFontString(nil, "OVERLAY", template)
    fontString:SetJustifyH(justify)
    return fontString
end

--- Build one card. A preview card (previewParent given) is anonymous, inert,
--- and parented to the options panel instead of UIParent.
local function CreateToast(previewParent)
    local isPreview = previewParent ~= nil
    local frameName
    if not isPreview then
        frameCount = frameCount + 1
        frameName = "DragonToastFrame" .. frameCount
    end

    -- Stack movement belongs to the parent; effects animate the complete
    -- visual Button without changing the stack's coordinate system.
    local layoutFrame = CreateFrame("Frame", nil, previewParent or UIParent)
    layoutFrame:Hide()
    local frame = CreateFrame("Button", frameName, layoutFrame, "BackdropTemplate")
    frame.layoutFrame = layoutFrame
    frame:SetPoint("CENTER", layoutFrame, "CENTER", 0, 0)
    if isPreview then
        frame:SetFrameLevel(layoutFrame:GetFrameLevel() + 1)
        frame:EnableMouse(false)
        layoutFrame:EnableMouse(false)
    else
        frame:SetFrameStrata(LIVE_STRATA)
        frame:SetFrameLevel(BASE_FRAME_LEVEL + frameCount)
    end
    frame:Hide()

    -- Edge only, just outside the card. Styled on first render.
    frame.borderFrame = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.borderFrame:SetFrameLevel(frame:GetFrameLevel() + 1)

    -- Everything visible lives here, above the border (see 9e3daf8: z-fighting).
    local content = CreateFrame("Frame", nil, frame)
    content:SetAllPoints(frame)
    content:SetFrameLevel(frame:GetFrameLevel() + 2)
    frame.content = content

    -- Accent strip: BACKGROUND, behind the text
    frame.qualityGlow = content:CreateTexture(nil, "BACKGROUND")
    frame.qualityGlow:SetWidth(DEFAULT_GLOW_WIDTH)

    -- Icon with its own constant 1px border (only the color ever changes)
    local iconFrame = CreateFrame("Frame", nil, content, "BackdropTemplate")
    iconFrame:SetFrameLevel(content:GetFrameLevel() + 2)
    iconFrame:SetBackdrop({
        bgFile = nil,
        edgeFile = SOLID_TEXTURE,
        edgeSize = ICON_BORDER_SIZE,
        insets = { left = 0, right = 0, top = 0, bottom = 0 },
    })
    frame.iconFrame = iconFrame

    frame.icon = iconFrame:CreateTexture(nil, "ARTWORK")
    frame.icon:SetPoint("CENTER", iconFrame, "CENTER", 0, 0)

    frame.quantity = CreateText(iconFrame, "NumberFontNormal", "RIGHT")
    frame.quantity:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", 2, -2)
    SetTextRGB(frame.quantity, WHITE)

    frame.itemName = CreateText(content, "GameFontNormal", "LEFT")
    frame.itemName:SetWordWrap(false)
    frame.itemLevel = CreateText(content, "GameFontNormalSmall", "RIGHT")
    frame.itemCount = CreateText(content, "GameFontNormalSmall", "RIGHT")
    frame.itemType = CreateText(content, "GameFontNormalSmall", "LEFT")
    frame.looter = CreateText(content, "GameFontNormalSmall", "RIGHT")

    if isPreview then
        frame.borderFrame:EnableMouse(false)
        content:EnableMouse(false)
        iconFrame:EnableMouse(false)
    else
        MakeInteractive(frame)
    end

    return frame
end

-------------------------------------------------------------------------------
-- Public interface
-------------------------------------------------------------------------------

-- An options-only renderer. It has no pool membership, click scripts, lifecycle,
-- manager callbacks, or saved anchor state; its parent owns its position.
function ns.ToastFrame.CreatePreview(parent)
    local frame = CreateToast(parent)
    frame.layoutFrame:SetPoint("CENTER", parent, "CENTER", 0, 0)
    local controller = { frame = frame }

    --- Redraw from `lootData` (or the last one) with the current settings,
    --- scaled down, never up, to fit the parent. Returns width, height, scale.
    function controller:Refresh(lootData)
        lootData = lootData or frame.lootData
        if not lootData then return end
        Render(frame, lootData)

        local width, height = frame:GetWidth(), frame:GetHeight()
        local availableWidth, availableHeight = parent:GetWidth(), parent:GetHeight()
        -- Width can be unresolved until the first panel layout pass.
        if availableWidth <= 0 or availableHeight <= 0 then return end

        local border = ns.Addon.db.profile.appearance.borderSize or DEFAULT_BORDER_SIZE
        local scale = math_min(1, availableWidth / (width + border * 2),
            availableHeight / (height + border * 2))
        frame.layoutFrame:SetScale(scale)
        frame:SetAlpha(1)
        frame:SetScale(1)
        frame.layoutFrame:Show()
        frame:Show()
        return width, height, scale
    end

    function controller:OnHide()
        frame:Hide()
        frame.layoutFrame:Hide()
    end

    return controller
end

function ns.ToastFrame.Acquire()
    local frame = table.remove(framePool) or CreateToast()
    frame._isPooled = false
    return frame
end

function ns.ToastFrame.Release(frame)
    if frame._isPooled then return end
    -- Mark it first: Hide can synchronously invoke mouse-leave scripts.
    frame._isPooled = true
    ns.ToastAnimations.StopAll(frame)
    if frame._savedStrata then frame:SetFrameStrata(frame._savedStrata) end

    frame:Hide()
    frame.layoutFrame:Hide()
    frame.layoutFrame:SetScript("OnUpdate", nil)
    frame.layoutFrame:ClearAllPoints()
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", frame.layoutFrame, "CENTER", 0, 0)

    for _, field in ipairs(RELEASE_CLEARED_FIELDS) do
        frame[field] = nil
    end
    frame._isHovered = false
    frame._isExiting = false
    frame._isEntering = false

    frame:SetAlpha(1)
    frame:SetScale(1)
    table.insert(framePool, frame)
end

function ns.ToastFrame.Populate(frame, lootData)
    Render(frame, lootData)
end

function ns.ToastFrame.UpdateLayout(frame)
    if frame and frame.lootData then
        Render(frame, frame.lootData)
    end
end
