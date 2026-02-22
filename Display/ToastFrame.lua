-------------------------------------------------------------------------------
-- ToastFrame.lua
-- Individual toast frame creation and layout
--
-- Supported versions: TBC Anniversary, Retail
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

-------------------------------------------------------------------------------
-- Cached WoW API
-------------------------------------------------------------------------------

local CreateFrame = CreateFrame
local GameTooltip = GameTooltip
local IsShiftKeyDown = IsShiftKeyDown
local ChatFrame_OpenChat = ChatFrame_OpenChat
local UIParent = UIParent
local STANDARD_TEXT_FONT = STANDARD_TEXT_FONT

local LSM = LibStub("LibSharedMedia-3.0")

-------------------------------------------------------------------------------
-- Frame Pool
-------------------------------------------------------------------------------

local framePool = {}
local frameCount = 0

-------------------------------------------------------------------------------
-- Create a single toast frame
-------------------------------------------------------------------------------

local function CreateToastFrame()
    frameCount = frameCount + 1
    local frameName = "DragonToastFrame" .. frameCount

    local frame = CreateFrame("Button", frameName, UIParent)
    frame:SetSize(350, 48)
    frame:SetFrameStrata("MEDIUM")
    frame:SetFrameLevel(100 + frameCount)
    frame:Hide()

    -- Background
    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetAllPoints()
    frame.bg:SetColorTexture(0.05, 0.05, 0.05, 0.7)

    -- Border: top, bottom, left, right (1px lines)
    frame.borderTop = frame:CreateTexture(nil, "BORDER")
    frame.borderTop:SetHeight(1)
    frame.borderTop:SetPoint("TOPLEFT")
    frame.borderTop:SetPoint("TOPRIGHT")
    frame.borderTop:SetColorTexture(0.3, 0.3, 0.3, 0.8)

    frame.borderBottom = frame:CreateTexture(nil, "BORDER")
    frame.borderBottom:SetHeight(1)
    frame.borderBottom:SetPoint("BOTTOMLEFT")
    frame.borderBottom:SetPoint("BOTTOMRIGHT")
    frame.borderBottom:SetColorTexture(0.3, 0.3, 0.3, 0.8)

    frame.borderLeft = frame:CreateTexture(nil, "BORDER")
    frame.borderLeft:SetWidth(1)
    frame.borderLeft:SetPoint("TOPLEFT")
    frame.borderLeft:SetPoint("BOTTOMLEFT")
    frame.borderLeft:SetColorTexture(0.3, 0.3, 0.3, 0.8)

    frame.borderRight = frame:CreateTexture(nil, "BORDER")
    frame.borderRight:SetWidth(1)
    frame.borderRight:SetPoint("TOPRIGHT")
    frame.borderRight:SetPoint("BOTTOMRIGHT")
    frame.borderRight:SetColorTexture(0.3, 0.3, 0.3, 0.8)

    -- Quality glow strip (left edge, 4px wide)
    frame.qualityGlow = frame:CreateTexture(nil, "ARTWORK")
    frame.qualityGlow:SetWidth(4)
    frame.qualityGlow:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    frame.qualityGlow:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 1, 1)
    frame.qualityGlow:SetColorTexture(1, 1, 1, 0.8)

    -- Icon frame (container for icon + icon border)
    local iconSize = 36
    local iconPadding = 6

    frame.icon = frame:CreateTexture(nil, "ARTWORK")
    frame.icon:SetSize(iconSize, iconSize)
    frame.icon:SetPoint("LEFT", frame, "LEFT", iconPadding + 4, 0) -- +4 for glow strip
    frame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- trim default icon borders

    frame.iconBorder = frame:CreateTexture(nil, "OVERLAY")
    frame.iconBorder:SetPoint("TOPLEFT", frame.icon, "TOPLEFT", -1, 1)
    frame.iconBorder:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", 1, -1)
    frame.iconBorder:SetColorTexture(0.3, 0.3, 0.3, 0.8)
    -- Draw icon on top of border
    frame.icon:SetDrawLayer("OVERLAY", 1)

    -- Item name (row 1, left)
    frame.itemName = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.itemName:SetPoint("TOPLEFT", frame.icon, "TOPRIGHT", 8, -2)
    frame.itemName:SetPoint("RIGHT", frame, "RIGHT", -80, 0)
    frame.itemName:SetJustifyH("LEFT")
    frame.itemName:SetWordWrap(false)

    -- Quantity badge (bottom-right of icon, stack count style)
    frame.quantity = frame:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    frame.quantity:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", 2, -2)
    frame.quantity:SetJustifyH("RIGHT")
    frame.quantity:SetTextColor(1, 1, 1)

    -- Item level (row 1, right)
    frame.itemLevel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.itemLevel:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -6)
    frame.itemLevel:SetJustifyH("RIGHT")
    frame.itemLevel:SetTextColor(0.6, 0.6, 0.6)

    -- Type/Subtype (row 2, left)
    frame.itemType = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.itemType:SetPoint("BOTTOMLEFT", frame.icon, "BOTTOMRIGHT", 8, 2)
    frame.itemType:SetJustifyH("LEFT")
    frame.itemType:SetTextColor(0.5, 0.5, 0.5)

    -- Looter name (row 2, right)
    frame.looter = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.looter:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 6)
    frame.looter:SetJustifyH("RIGHT")
    frame.looter:SetTextColor(0.7, 0.7, 0.7)

    ---------------------------------------------------------------------------
    -- Interaction Scripts
    ---------------------------------------------------------------------------

    frame:EnableMouse(true)
    frame:RegisterForClicks("LeftButtonUp")

    frame:SetScript("OnClick", function(self)
        if IsShiftKeyDown() and self.lootData and self.lootData.itemLink and not self.lootData.isXP then
            -- Shift-click: link item in chat
            ChatFrame_OpenChat(self.lootData.itemLink)
        else
            -- Normal click: dismiss
            if ns.ToastManager.DismissToast then
                ns.ToastManager.DismissToast(self)
            end
        end
    end)

    frame:SetScript("OnEnter", function(self)
        -- Pause fade timer
        self.isHovered = true
        ns.Addon:CancelTimer(self.fadeTimer)
        self.fadeTimer = nil

        -- Show tooltip (not for XP toasts)
        if self.lootData and self.lootData.itemLink and not self.lootData.isXP then
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:SetHyperlink(self.lootData.itemLink)
            GameTooltip:Show()
        end
    end)

    frame:SetScript("OnLeave", function(self)
        self.isHovered = false
        GameTooltip:Hide()

        -- Resume fade timer
        if ns.ToastManager.ResumeFadeTimer then
            ns.ToastManager.ResumeFadeTimer(self)
        end
    end)

    -- Store reference for animations (created by ToastAnimations.lua)
    frame.animGroups = {}

    return frame
end

-------------------------------------------------------------------------------
-- Populate toast with loot data
-------------------------------------------------------------------------------

local function PopulateToast(frame, lootData)
    frame.lootData = lootData
    local db = ns.Addon.db.profile

    -- Fetch LSM font
    local fontPath = LSM:Fetch("font", db.appearance.fontFace) or STANDARD_TEXT_FONT
    local fontOutline = db.appearance.fontOutline or "OUTLINE"
    local fontSize = db.appearance.fontSize
    local secondaryFontSize = db.appearance.secondaryFontSize or 10

    -- XP toast special handling
    if lootData.isXP then
        -- Apply fonts
        frame.itemName:SetFont(fontPath, fontSize, fontOutline)
        frame.itemLevel:SetFont(fontPath, secondaryFontSize, fontOutline)
        frame.itemType:SetFont(fontPath, secondaryFontSize, fontOutline)
        frame.looter:SetFont(fontPath, secondaryFontSize, fontOutline)

        -- Icon display
        frame.itemName:ClearAllPoints()
        frame.itemType:ClearAllPoints()
        if db.display.showIcon ~= false then
            frame.icon:SetTexture(lootData.itemIcon)
            frame.icon:Show()
            frame.iconBorder:Show()
            frame.itemName:SetPoint("TOPLEFT", frame.icon, "TOPRIGHT", 8, -2)
            frame.itemType:SetPoint("BOTTOMLEFT", frame.icon, "BOTTOMRIGHT", 8, 2)
        else
            frame.icon:Hide()
            frame.iconBorder:Hide()
            frame.itemName:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -6)
            frame.itemType:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 6)
        end

        -- XP name in gold color
        frame.itemName:SetText(lootData.itemName)
        frame.itemName:SetTextColor(1, 0.82, 0) -- gold

        -- No quantity badge for XP
        frame.quantity:Hide()

        -- No item level for XP
        frame.itemLevel:Hide()

        -- Secondary text: mob name if available
        if lootData.mobName and lootData.mobName ~= "" then
            frame.itemType:SetText(lootData.mobName)
            frame.itemType:SetTextColor(0.7, 0.7, 0.7)
            frame.itemType:Show()
        else
            frame.itemType:Hide()
        end

        -- Looter
        if db.display.showLooter then
            frame.looter:SetText("You")
            frame.looter:SetTextColor(0.3, 1.0, 0.3)
            frame.looter:Show()
        else
            frame.looter:Hide()
        end

        -- XP glow color: gold/amber
        local xpR, xpG, xpB = 1, 0.82, 0
        if db.appearance.qualityGlow then
            local glowWidth = db.appearance.glowWidth or 4
            frame.qualityGlow:SetWidth(glowWidth)
            local statusBarPath = LSM:Fetch("statusbar", db.appearance.statusBarTexture)
            if statusBarPath then
                frame.qualityGlow:SetTexture(statusBarPath)
                frame.qualityGlow:SetVertexColor(xpR, xpG, xpB, 0.8)
            else
                frame.qualityGlow:SetColorTexture(xpR, xpG, xpB, 0.8)
            end
            frame.qualityGlow:Show()
        else
            frame.qualityGlow:Hide()
        end

        -- XP border color: gold
        if db.appearance.qualityBorder then
            frame.borderTop:SetColorTexture(xpR, xpG, xpB, 0.6)
            frame.borderBottom:SetColorTexture(xpR, xpG, xpB, 0.6)
            frame.borderLeft:SetColorTexture(xpR, xpG, xpB, 0.6)
            frame.borderRight:SetColorTexture(xpR, xpG, xpB, 0.6)
            frame.iconBorder:SetColorTexture(xpR, xpG, xpB, 0.6)
        else
            frame.borderTop:SetColorTexture(0.3, 0.3, 0.3, 0.8)
            frame.borderBottom:SetColorTexture(0.3, 0.3, 0.3, 0.8)
            frame.borderLeft:SetColorTexture(0.3, 0.3, 0.3, 0.8)
            frame.borderRight:SetColorTexture(0.3, 0.3, 0.3, 0.8)
            frame.iconBorder:SetColorTexture(0.3, 0.3, 0.3, 0.8)
        end

        -- Border size
        local borderSize = db.appearance.borderSize or 1
        frame.borderTop:SetHeight(borderSize)
        frame.borderBottom:SetHeight(borderSize)
        frame.borderLeft:SetWidth(borderSize)
        frame.borderRight:SetWidth(borderSize)

        -- Background
        local bgColor = db.appearance.backgroundColor or { r = 0.05, g = 0.05, b = 0.05 }
        frame.bg:SetColorTexture(bgColor.r, bgColor.g, bgColor.b, db.appearance.backgroundAlpha)

        -- Size
        frame:SetSize(db.display.toastWidth, db.display.toastHeight)
        frame.icon:SetSize(db.appearance.iconSize, db.appearance.iconSize)

        -- ElvUI skin
        if ns.ElvUISkin and ns.ElvUISkin.SkinToast then
            ns.ElvUISkin.SkinToast(frame)
        end

        return  -- Skip normal item population
    end

    -- Icon display
    frame.itemName:ClearAllPoints()
    frame.itemType:ClearAllPoints()
    if db.display.showIcon ~= false then
        frame.icon:SetTexture(lootData.itemIcon)
        frame.icon:Show()
        frame.iconBorder:Show()
        -- Position text relative to icon as before
        frame.itemName:SetPoint("TOPLEFT", frame.icon, "TOPRIGHT", 8, -2)
        frame.itemType:SetPoint("BOTTOMLEFT", frame.icon, "BOTTOMRIGHT", 8, 2)
    else
        frame.icon:Hide()
        frame.iconBorder:Hide()
        -- Position text at left edge when no icon
        frame.itemName:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -6)
        frame.itemType:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 6)
    end

    -- Quality color
    local r, g, b = 1, 1, 1
    if lootData.itemQuality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[lootData.itemQuality] then
        local qc = ITEM_QUALITY_COLORS[lootData.itemQuality]
        r, g, b = qc.r, qc.g, qc.b
    elseif lootData.itemQuality and ns.QUALITY_COLORS and ns.QUALITY_COLORS[lootData.itemQuality] then
        local qc = ns.QUALITY_COLORS[lootData.itemQuality]
        r, g, b = qc.r, qc.g, qc.b
    end

    -- Apply LSM font to all text elements
    frame.itemName:SetFont(fontPath, fontSize, fontOutline)
    frame.itemLevel:SetFont(fontPath, secondaryFontSize, fontOutline)
    frame.itemType:SetFont(fontPath, secondaryFontSize, fontOutline)
    frame.looter:SetFont(fontPath, secondaryFontSize, fontOutline)

    -- Item name (colored by quality)
    frame.itemName:SetText(lootData.itemName)
    if lootData.isCurrency then
        frame.itemName:SetTextColor(1, 0.82, 0) -- gold color for currency
    else
        frame.itemName:SetTextColor(r, g, b)
    end

    -- Quantity
    if db.display.showQuantity and lootData.quantity and lootData.quantity > 1 then
        frame.quantity:SetText(lootData.quantity)
        frame.quantity:Show()
    else
        frame.quantity:Hide()
    end

    -- Item level
    if db.display.showItemLevel and lootData.itemLevel and lootData.itemLevel > 0 and not lootData.isCurrency then
        frame.itemLevel:SetText("ilvl " .. lootData.itemLevel)
        frame.itemLevel:Show()
    else
        frame.itemLevel:Hide()
    end

    -- Type/Subtype
    if db.display.showItemType and lootData.itemType and not lootData.isCurrency then
        local typeText = lootData.itemType
        if lootData.itemSubType and lootData.itemSubType ~= "" and lootData.itemSubType ~= lootData.itemType then
            typeText = typeText .. " > " .. lootData.itemSubType
        end
        frame.itemType:SetText(typeText)
        frame.itemType:Show()
    else
        frame.itemType:Hide()
    end

    -- Looter
    if db.display.showLooter and lootData.looter then
        if lootData.isSelf then
            frame.looter:SetText("You")
            frame.looter:SetTextColor(0.3, 1.0, 0.3) -- green for self
        else
            frame.looter:SetText(lootData.looter)
            frame.looter:SetTextColor(0.7, 0.7, 0.7)
        end
        frame.looter:Show()
    else
        frame.looter:Hide()
    end

    -- Quality glow strip
    if db.appearance.qualityGlow then
        local glowWidth = db.appearance.glowWidth or 4
        frame.qualityGlow:SetWidth(glowWidth)
        -- Apply LSM statusbar texture if available
        local statusBarPath = LSM:Fetch("statusbar", db.appearance.statusBarTexture)
        if statusBarPath then
            frame.qualityGlow:SetTexture(statusBarPath)
            frame.qualityGlow:SetVertexColor(r, g, b, 0.8)
        else
            frame.qualityGlow:SetColorTexture(r, g, b, 0.8)
        end
        frame.qualityGlow:Show()
    else
        frame.qualityGlow:Hide()
    end

    -- Quality border
    if db.appearance.qualityBorder then
        frame.borderTop:SetColorTexture(r, g, b, 0.6)
        frame.borderBottom:SetColorTexture(r, g, b, 0.6)
        frame.borderLeft:SetColorTexture(r, g, b, 0.6)
        frame.borderRight:SetColorTexture(r, g, b, 0.6)
        frame.iconBorder:SetColorTexture(r, g, b, 0.6)
    else
        frame.borderTop:SetColorTexture(0.3, 0.3, 0.3, 0.8)
        frame.borderBottom:SetColorTexture(0.3, 0.3, 0.3, 0.8)
        frame.borderLeft:SetColorTexture(0.3, 0.3, 0.3, 0.8)
        frame.borderRight:SetColorTexture(0.3, 0.3, 0.3, 0.8)
        frame.iconBorder:SetColorTexture(0.3, 0.3, 0.3, 0.8)
    end

    -- Apply configurable border size
    local borderSize = db.appearance.borderSize or 1
    frame.borderTop:SetHeight(borderSize)
    frame.borderBottom:SetHeight(borderSize)
    frame.borderLeft:SetWidth(borderSize)
    frame.borderRight:SetWidth(borderSize)

    -- Background color and alpha
    local bgColor = db.appearance.backgroundColor or { r = 0.05, g = 0.05, b = 0.05 }
    frame.bg:SetColorTexture(bgColor.r, bgColor.g, bgColor.b, db.appearance.backgroundAlpha)

    -- Size from config
    frame:SetSize(db.display.toastWidth, db.display.toastHeight)
    frame.icon:SetSize(db.appearance.iconSize, db.appearance.iconSize)

    -- Apply ElvUI skin if available
    if ns.ElvUISkin and ns.ElvUISkin.SkinToast then
        ns.ElvUISkin.SkinToast(frame)
    end
end

-------------------------------------------------------------------------------
-- Public Interface
-------------------------------------------------------------------------------

function ns.ToastFrame.Acquire()
    local frame = table.remove(framePool)
    if not frame then
        frame = CreateToastFrame()
        -- Create animation groups
        if ns.ToastAnimations and ns.ToastAnimations.SetupAnimations then
            ns.ToastAnimations.SetupAnimations(frame)
        end
    end
    return frame
end

function ns.ToastFrame.Release(frame)
    -- Cancel any pending fade timer before releasing
    if frame.fadeTimer then
        ns.Addon:CancelTimer(frame.fadeTimer)
    end

    frame:Hide()
    frame:ClearAllPoints()
    frame.lootData = nil
    frame.isHovered = false
    frame.fadeTimer = nil
    frame.fadeTimerStart = nil
    frame.fadeTimerRemaining = nil
    frame._isEntering = false
    frame._entranceStartTime = nil
    frame._entranceDuration = nil
    frame._entranceSlideX = nil
    frame._entranceSlideY = nil
    frame._entranceFinalX = nil
    frame._entranceFinalY = nil
    frame._isSliding = false
    frame._slideStartTime = nil
    frame._slideDuration = nil
    frame._slideFromY = nil
    frame._slideToY = nil
    frame._slidePoint = nil
    frame._slideRelativeTo = nil
    frame._slideRelativePoint = nil
    frame._slideX = nil
    frame:SetScript("OnUpdate", nil)
    frame:SetAlpha(1)
    frame:SetScale(1)
    -- Pool duplication guard
    for _, pooled in ipairs(framePool) do
        if pooled == frame then return end
    end
    table.insert(framePool, frame)
end

function ns.ToastFrame.Populate(frame, lootData)
    PopulateToast(frame, lootData)
end

function ns.ToastFrame.UpdateLayout(frame)
    if frame and frame.lootData then
        PopulateToast(frame, frame.lootData)
    end
end
