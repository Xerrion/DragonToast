-------------------------------------------------------------------------------
-- ToastFrame.lua
-- Individual toast frame creation and layout
--
-- Supported versions: TBC Anniversary, Retail, MoP Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

-------------------------------------------------------------------------------
-- Cached WoW API
-------------------------------------------------------------------------------

local CreateFrame = CreateFrame
local GameTooltip = GameTooltip
local IsShiftKeyDown = IsShiftKeyDown
local ChatFrame_OpenChat = ChatFrame_OpenChat
local GetCoinTextureString = GetCoinTextureString
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

    local frame = CreateFrame("Button", frameName, UIParent, "BackdropTemplate")
    frame:SetSize(350, 48)
    frame:SetFrameStrata("MEDIUM")
    frame:SetFrameLevel(100 + frameCount)
    frame:Hide()

    -- Background + border via BackdropTemplate
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 },
    })
    frame:SetBackdropColor(0.05, 0.05, 0.05, 0.7)
    frame:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)

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
    frame.itemName:SetPoint("LEFT", frame.icon, "RIGHT", 8, 0)
    frame.itemName:SetPoint("TOP", frame, "TOP", 0, -6)
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
    frame.itemType:SetPoint("LEFT", frame.icon, "RIGHT", 8, 0)
    frame.itemType:SetPoint("BOTTOM", frame, "BOTTOM", 0, 6)
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
        if IsShiftKeyDown() and self.lootData and self.lootData.itemLink
            and not self.lootData.isXP and not self.lootData.isHonor then
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
        -- Show tooltip (not for XP or honor toasts)
        if self.lootData and self.lootData.itemLink and not self.lootData.isXP and not self.lootData.isHonor then
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:SetHyperlink(self.lootData.itemLink)
            GameTooltip:Show()
        end
    end)

    frame:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    return frame
end

-------------------------------------------------------------------------------
-- Format a copper amount into a human-readable money string
-------------------------------------------------------------------------------

local function FormatMoney(copperAmount, format)
    local gold = math.floor(copperAmount / 10000)
    local silver = math.floor((copperAmount % 10000) / 100)
    local copper = copperAmount % 100

    if format == "short" then
        local parts = {}
        if gold > 0 then parts[#parts + 1] = gold .. "g" end
        if silver > 0 then parts[#parts + 1] = silver .. "s" end
        if copper > 0 then parts[#parts + 1] = copper .. "c" end
        return table.concat(parts, " ")
    elseif format == "long" then
        local parts = {}
        if gold > 0 then parts[#parts + 1] = GOLD_AMOUNT:format(gold) end
        if silver > 0 then parts[#parts + 1] = SILVER_AMOUNT:format(silver) end
        if copper > 0 then parts[#parts + 1] = COPPER_AMOUNT:format(copper) end
        return table.concat(parts, " ")
    else
        -- "icons" format (default) - use Blizzard's coin texture string
        return GetCoinTextureString(copperAmount)
    end
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
        frame.itemLevel:ClearAllPoints()
        frame.looter:ClearAllPoints()
        local padV = db.display.textPaddingV or 6
        local padH = db.display.textPaddingH or 8
        if db.display.showIcon ~= false then
            frame.icon:SetTexture(lootData.itemIcon)
            frame.icon:Show()
            frame.iconBorder:Show()
            frame.itemName:SetPoint("LEFT", frame.icon, "RIGHT", padH, 0)
            frame.itemName:SetPoint("TOP", frame, "TOP", 0, -padV)
            frame.itemType:SetPoint("LEFT", frame.icon, "RIGHT", padH, 0)
            frame.itemType:SetPoint("BOTTOM", frame, "BOTTOM", 0, padV)
        else
            frame.icon:Hide()
            frame.iconBorder:Hide()
            frame.itemName:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -padV)
            frame.itemType:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, padV)
        end
        frame.itemLevel:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -padH, -padV)
        frame.looter:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -padH, padV)

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
        local borderSize = db.appearance.borderSize or 1
        local borderInset = db.appearance.borderInset or 0
        local glowOffset = borderSize
        frame.qualityGlow:ClearAllPoints()
        frame.qualityGlow:SetPoint("TOPLEFT", frame, "TOPLEFT", glowOffset, -glowOffset)
        frame.qualityGlow:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", glowOffset, glowOffset)
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

        -- Border size, background, and border color
        frame:SetBackdrop({
            bgFile = LSM:Fetch("background", db.appearance.backgroundTexture or "Solid"),
            edgeFile = LSM:Fetch("border", db.appearance.borderTexture or "None"),
            edgeSize = borderSize,
            insets = { left = borderInset, right = borderInset, top = borderInset, bottom = borderInset },
        })

        local bgColor = db.appearance.backgroundColor or { r = 0.05, g = 0.05, b = 0.05 }
        frame:SetBackdropColor(bgColor.r, bgColor.g, bgColor.b, db.appearance.backgroundAlpha)

        if db.appearance.qualityBorder then
            frame:SetBackdropBorderColor(xpR, xpG, xpB, 0.6)
            frame.iconBorder:SetColorTexture(xpR, xpG, xpB, 0.6)
        else
            frame:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
            frame.iconBorder:SetColorTexture(0.3, 0.3, 0.3, 0.8)
        end

        -- Size
        frame:SetSize(db.display.toastWidth, db.display.toastHeight)
        frame.icon:SetSize(db.appearance.iconSize, db.appearance.iconSize)

        -- ElvUI skin
        if ns.ElvUISkin and ns.ElvUISkin.SkinToast then
            ns.ElvUISkin.SkinToast(frame)
        end

        return  -- Skip normal item population
    end

    -- Honor toast special handling
    if lootData.isHonor then
        -- Apply fonts
        frame.itemName:SetFont(fontPath, fontSize, fontOutline)
        frame.itemLevel:SetFont(fontPath, secondaryFontSize, fontOutline)
        frame.itemType:SetFont(fontPath, secondaryFontSize, fontOutline)
        frame.looter:SetFont(fontPath, secondaryFontSize, fontOutline)

        -- Icon display
        frame.itemName:ClearAllPoints()
        frame.itemType:ClearAllPoints()
        frame.itemLevel:ClearAllPoints()
        frame.looter:ClearAllPoints()
        local padV = db.display.textPaddingV or 6
        local padH = db.display.textPaddingH or 8
        if db.display.showIcon ~= false then
            frame.icon:SetTexture(lootData.itemIcon)
            frame.icon:Show()
            frame.iconBorder:Show()
            frame.itemName:SetPoint("LEFT", frame.icon, "RIGHT", padH, 0)
            frame.itemName:SetPoint("TOP", frame, "TOP", 0, -padV)
            frame.itemType:SetPoint("LEFT", frame.icon, "RIGHT", padH, 0)
            frame.itemType:SetPoint("BOTTOM", frame, "BOTTOM", 0, padV)
        else
            frame.icon:Hide()
            frame.iconBorder:Hide()
            frame.itemName:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -padV)
            frame.itemType:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, padV)
        end
        frame.itemLevel:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -padH, -padV)
        frame.looter:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -padH, padV)

        -- Honor name in red color
        local honorR, honorG, honorB = 1, 0.24, 0.17
        frame.itemName:SetText(lootData.itemName)
        frame.itemName:SetTextColor(honorR, honorG, honorB)

        -- No quantity badge for honor
        frame.quantity:Hide()

        -- No item level for honor
        frame.itemLevel:Hide()

        -- Secondary text: victim name if available
        if lootData.victimName and lootData.victimName ~= "" then
            frame.itemType:SetText(lootData.victimName)
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

        -- Honor glow color: red
        local borderSize = db.appearance.borderSize or 1
        local borderInset = db.appearance.borderInset or 0
        local glowOffset = borderSize
        frame.qualityGlow:ClearAllPoints()
        frame.qualityGlow:SetPoint("TOPLEFT", frame, "TOPLEFT", glowOffset, -glowOffset)
        frame.qualityGlow:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", glowOffset, glowOffset)
        if db.appearance.qualityGlow then
            local glowWidth = db.appearance.glowWidth or 4
            frame.qualityGlow:SetWidth(glowWidth)
            local statusBarPath = LSM:Fetch("statusbar", db.appearance.statusBarTexture)
            if statusBarPath then
                frame.qualityGlow:SetTexture(statusBarPath)
                frame.qualityGlow:SetVertexColor(honorR, honorG, honorB, 0.8)
            else
                frame.qualityGlow:SetColorTexture(honorR, honorG, honorB, 0.8)
            end
            frame.qualityGlow:Show()
        else
            frame.qualityGlow:Hide()
        end

        -- Border size, background, and border color
        frame:SetBackdrop({
            bgFile = LSM:Fetch("background", db.appearance.backgroundTexture or "Solid"),
            edgeFile = LSM:Fetch("border", db.appearance.borderTexture or "None"),
            edgeSize = borderSize,
            insets = { left = borderInset, right = borderInset, top = borderInset, bottom = borderInset },
        })

        local bgColor = db.appearance.backgroundColor or { r = 0.05, g = 0.05, b = 0.05 }
        frame:SetBackdropColor(bgColor.r, bgColor.g, bgColor.b, db.appearance.backgroundAlpha)

        if db.appearance.qualityBorder then
            frame:SetBackdropBorderColor(honorR, honorG, honorB, 0.6)
            frame.iconBorder:SetColorTexture(honorR, honorG, honorB, 0.6)
        else
            frame:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
            frame.iconBorder:SetColorTexture(0.3, 0.3, 0.3, 0.8)
        end

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
    frame.itemLevel:ClearAllPoints()
    frame.looter:ClearAllPoints()
    local padV = db.display.textPaddingV or 6
    local padH = db.display.textPaddingH or 8
    if db.display.showIcon ~= false then
        frame.icon:SetTexture(lootData.itemIcon)
        frame.icon:Show()
        frame.iconBorder:Show()
        -- Position text relative to icon as before
        frame.itemName:SetPoint("LEFT", frame.icon, "RIGHT", padH, 0)
        frame.itemName:SetPoint("TOP", frame, "TOP", 0, -padV)
        frame.itemType:SetPoint("LEFT", frame.icon, "RIGHT", padH, 0)
        frame.itemType:SetPoint("BOTTOM", frame, "BOTTOM", 0, padV)
    else
        frame.icon:Hide()
        frame.iconBorder:Hide()
        -- Position text at left edge when no icon
        frame.itemName:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -padV)
        frame.itemType:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, padV)
    end
    frame.itemLevel:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -padH, -padV)
    frame.looter:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -padH, padV)

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
    if lootData.copperAmount and lootData.itemSubType == "Gold" then
        frame.itemName:SetText(FormatMoney(lootData.copperAmount, db.display.goldFormat))
    else
        frame.itemName:SetText(lootData.itemName)
    end
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
    local borderSize = db.appearance.borderSize or 1
    local borderInset = db.appearance.borderInset or 0
    local glowOffset = borderSize
    frame.qualityGlow:ClearAllPoints()
    frame.qualityGlow:SetPoint("TOPLEFT", frame, "TOPLEFT", glowOffset, -glowOffset)
    frame.qualityGlow:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", glowOffset, glowOffset)
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

    -- Border size, background, and border color
    frame:SetBackdrop({
        bgFile = LSM:Fetch("background", db.appearance.backgroundTexture or "Solid"),
        edgeFile = LSM:Fetch("border", db.appearance.borderTexture or "None"),
        edgeSize = borderSize,
        insets = { left = borderInset, right = borderInset, top = borderInset, bottom = borderInset },
    })

    local bgColor = db.appearance.backgroundColor or { r = 0.05, g = 0.05, b = 0.05 }
    frame:SetBackdropColor(bgColor.r, bgColor.g, bgColor.b, db.appearance.backgroundAlpha)

    if db.appearance.qualityBorder then
        frame:SetBackdropBorderColor(r, g, b, 0.6)
        frame.iconBorder:SetColorTexture(r, g, b, 0.6)
    else
        frame:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
        frame.iconBorder:SetColorTexture(0.3, 0.3, 0.3, 0.8)
    end

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
    end
    frame._isPooled = false
    return frame
end

function ns.ToastFrame.Release(frame)
    -- O(1) duplication guard
    if frame._isPooled then return end
    frame._isPooled = true

    -- Cancel any pending no-anim timer before releasing
    if frame._noAnimTimer then
        ns.Addon:CancelTimer(frame._noAnimTimer)
    end

    frame:Hide()
    frame:ClearAllPoints()
    frame.lootData = nil
    frame._noAnimTimer = nil
    frame._isExiting = false
    frame._queueRoles = nil
    frame._targetY = nil

    -- Clean up LibAnimate animation state
    if ns.LibAnimate then
        ns.LibAnimate:ClearQueue(frame)
    end

    frame:SetAlpha(1)
    frame:SetScale(1)

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
