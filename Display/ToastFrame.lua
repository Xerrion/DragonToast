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

--- Build a cache key for backdrop params to skip redundant SetBackdrop calls during stacking
local function GetBackdropKey(bgFile, edgeFile, edgeSize, inset)
    return (bgFile or "") .. "|" .. (edgeFile or "") .. "|" .. tostring(edgeSize) .. "|" .. tostring(inset)
end

-------------------------------------------------------------------------------
-- Shared layout helpers
-------------------------------------------------------------------------------

--- Apply LSM font to all text elements
local function ApplyFonts(frame, fontPath, fontSize, secondaryFontSize, fontOutline)
    frame.itemName:SetFont(fontPath, fontSize, fontOutline)
    frame.itemLevel:SetFont(fontPath, secondaryFontSize, fontOutline)
    frame.itemType:SetFont(fontPath, secondaryFontSize, fontOutline)
    frame.looter:SetFont(fontPath, secondaryFontSize, fontOutline)
end

--- Position all content elements based on icon visibility and config
local function ApplyLayout(frame, db, showIcon)
    local padV = db.display.textPaddingV or 6
    local padH = db.display.textPaddingH or 8
    local borderSize = db.appearance.borderSize or 1
    local borderInset = db.appearance.borderInset or 0
    local glowWidth = db.appearance.glowWidth or 4
    local iconSize = db.appearance.iconSize or 36
    local contentInset = borderSize > 0 and math.max(borderInset, math.ceil(borderSize / 2)) or 0

    -- Update content frame inset to sit inside the border
    frame.content:ClearAllPoints()
    frame.content:SetPoint("TOPLEFT", frame, "TOPLEFT", contentInset, -contentInset)
    frame.content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -contentInset, contentInset)

    -- Clear all text anchors
    frame.itemName:ClearAllPoints()
    frame.itemType:ClearAllPoints()
    frame.itemLevel:ClearAllPoints()
    frame.looter:ClearAllPoints()

    local iconGlowPad = db.appearance.qualityGlow and glowWidth or 0

    if showIcon then
        -- iconFrame: size includes 1px border on each side
        frame.iconFrame:SetSize(iconSize + 2, iconSize + 2)
        frame.iconFrame:ClearAllPoints()
        frame.iconFrame:SetPoint("LEFT", frame.content, "LEFT", iconGlowPad + 4, 0)
        frame.iconFrame:Show()
        frame.icon:SetSize(iconSize, iconSize)

        -- Text anchored relative to iconFrame
        frame.itemName:SetPoint("LEFT", frame.iconFrame, "RIGHT", padH, 0)
        frame.itemName:SetPoint("TOP", frame.content, "TOP", 0, -padV)
        frame.itemType:SetPoint("LEFT", frame.iconFrame, "RIGHT", padH, 0)
        frame.itemType:SetPoint("BOTTOM", frame.content, "BOTTOM", 0, padV)
    else
        frame.iconFrame:Hide()
        frame.itemName:SetPoint("TOPLEFT", frame.content, "TOPLEFT", iconGlowPad + 6, -padV)
        frame.itemType:SetPoint("BOTTOMLEFT", frame.content, "BOTTOMLEFT", iconGlowPad + 6, padV)
    end

    frame.itemName:SetPoint("RIGHT", frame.content, "RIGHT", -padH, 0)
    frame.itemLevel:SetPoint("TOPRIGHT", frame.content, "TOPRIGHT", -padH, -padV)
    frame.looter:SetPoint("BOTTOMRIGHT", frame.content, "BOTTOMRIGHT", -padH, padV)
end

--- Apply backdrop, background color, and border color to root frame and iconFrame
local function ApplyBackdrop(frame, db, qualityR, qualityG, qualityB)
    local borderSize = db.appearance.borderSize or 1
    local borderInset = db.appearance.borderInset or 0

    -- Root frame backdrop
    local bgFile = LSM:Fetch("background", db.appearance.backgroundTexture or "Solid")
    local edgeFile = borderSize > 0
        and LSM:Fetch("border", db.appearance.borderTexture or "None") or nil
    local inset = borderSize > 0 and borderInset or 0
    local backdropKey = GetBackdropKey(bgFile, edgeFile, borderSize, inset)
    if frame._backdropKey ~= backdropKey then
        frame:SetBackdrop({
            bgFile = bgFile,
            edgeFile = edgeFile,
            edgeSize = borderSize,
            insets = { left = inset, right = inset, top = inset, bottom = inset },
        })
        frame._backdropKey = backdropKey
    end

    local bgColor = db.appearance.backgroundColor or { r = 0.05, g = 0.05, b = 0.05 }
    frame:SetBackdropColor(bgColor.r, bgColor.g, bgColor.b, db.appearance.backgroundAlpha)

    -- iconFrame backdrop (always 1px solid border, no background)
    local iconEdge = "Interface\\Buttons\\WHITE8x8"
    local iconBackdropKey = iconEdge .. "|1|0"
    if frame._iconBackdropKey ~= iconBackdropKey then
        frame.iconFrame:SetBackdrop({
            bgFile = nil,
            edgeFile = iconEdge,
            edgeSize = 1,
            insets = { left = 0, right = 0, top = 0, bottom = 0 },
        })
        frame._iconBackdropKey = iconBackdropKey
    end

    -- Border colors
    if db.appearance.qualityBorder and qualityR then
        frame:SetBackdropBorderColor(qualityR, qualityG, qualityB, 0.6)
        frame.iconFrame:SetBackdropBorderColor(qualityR, qualityG, qualityB, 0.6)
    else
        frame:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
        frame.iconFrame:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
    end
end

--- Apply quality glow strip to the content frame
local function ApplyGlow(frame, db, r, g, b)
    frame.qualityGlow:ClearAllPoints()
    frame.qualityGlow:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 0, 0)
    frame.qualityGlow:SetPoint("BOTTOMLEFT", frame.content, "BOTTOMLEFT", 0, 0)

    if db.appearance.qualityGlow then
        local glowWidth = db.appearance.glowWidth or 4
        frame.qualityGlow:SetWidth(glowWidth)
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
end

-------------------------------------------------------------------------------
-- Create a single toast frame
-------------------------------------------------------------------------------

local function CreateToastFrame()
    frameCount = frameCount + 1
    local frameName = "DragonToastFrame" .. frameCount

    -- Root frame: outer border + background only
    local frame = CreateFrame("Button", frameName, UIParent, "BackdropTemplate")
    frame:SetSize(350, 48)
    frame:SetFrameStrata("MEDIUM")
    frame:SetFrameLevel(100 + frameCount)
    frame:Hide()

    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 },
    })
    frame:SetBackdropColor(0.05, 0.05, 0.05, 0.7)
    frame:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)

    -- Content frame: child for all visible content (above root border)
    frame.content = CreateFrame("Frame", nil, frame)
    frame.content:SetAllPoints(frame)
    frame.content:SetFrameLevel(frame:GetFrameLevel() + 2)

    -- Quality glow strip on content (BACKGROUND layer = behind text but above root border)
    frame.qualityGlow = frame.content:CreateTexture(nil, "BACKGROUND")
    frame.qualityGlow:SetWidth(4)
    frame.qualityGlow:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 1, -1)
    frame.qualityGlow:SetPoint("BOTTOMLEFT", frame.content, "BOTTOMLEFT", 1, 1)
    frame.qualityGlow:SetColorTexture(1, 1, 1, 0.8)

    -- Icon container frame with its own border (above content)
    frame.iconFrame = CreateFrame("Frame", nil, frame.content, "BackdropTemplate")
    frame.iconFrame:SetFrameLevel(frame.content:GetFrameLevel() + 2)
    frame.iconFrame:SetSize(38, 38)
    frame.iconFrame:SetBackdrop({
        bgFile = nil,
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 },
    })
    frame.iconFrame:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)

    -- Icon texture on iconFrame (ARTWORK = natural layer, no hack needed)
    frame.icon = frame.iconFrame:CreateTexture(nil, "ARTWORK")
    frame.icon:SetSize(36, 36)
    frame.icon:SetPoint("CENTER", frame.iconFrame, "CENTER", 0, 0)
    frame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- Quantity badge on iconFrame (OVERLAY = on top of icon)
    frame.quantity = frame.iconFrame:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    frame.quantity:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", 2, -2)
    frame.quantity:SetJustifyH("RIGHT")
    frame.quantity:SetTextColor(1, 1, 1)

    -- Text elements on content frame (OVERLAY layer)
    frame.itemName = frame.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.itemName:SetJustifyH("LEFT")
    frame.itemName:SetWordWrap(false)

    frame.itemLevel = frame.content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.itemLevel:SetJustifyH("RIGHT")
    frame.itemLevel:SetTextColor(0.6, 0.6, 0.6)

    frame.itemType = frame.content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.itemType:SetJustifyH("LEFT")
    frame.itemType:SetTextColor(0.5, 0.5, 0.5)

    frame.looter = frame.content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.looter:SetJustifyH("RIGHT")
    frame.looter:SetTextColor(0.7, 0.7, 0.7)

    ---------------------------------------------------------------------------
    -- Interaction Scripts (on root Button -- children don't enable mouse)
    ---------------------------------------------------------------------------

    frame:EnableMouse(true)
    frame:RegisterForClicks("LeftButtonUp")

    frame:SetScript("OnClick", function(self)
        if IsShiftKeyDown() and self.lootData and self.lootData.itemLink
            and not self.lootData.isXP and not self.lootData.isHonor then
            ChatFrame_OpenChat(self.lootData.itemLink)
        else
            if ns.ToastManager.DismissToast then
                ns.ToastManager.DismissToast(self)
            end
        end
    end)

    frame:SetScript("OnEnter", function(self)
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

    -- Apply fonts (shared across all paths)
    ApplyFonts(frame, fontPath, fontSize, secondaryFontSize, fontOutline)

    -- Size from config (shared)
    frame:SetSize(db.display.toastWidth, db.display.toastHeight)

    -- Determine quality color
    local r, g, b = 1, 1, 1
    if lootData.isXP then
        r, g, b = 1, 0.82, 0
    elseif lootData.isHonor then
        r, g, b = 1, 0.24, 0.17
    elseif lootData.itemQuality then
        if ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[lootData.itemQuality] then
            local qc = ITEM_QUALITY_COLORS[lootData.itemQuality]
            r, g, b = qc.r, qc.g, qc.b
        elseif ns.QUALITY_COLORS and ns.QUALITY_COLORS[lootData.itemQuality] then
            local qc = ns.QUALITY_COLORS[lootData.itemQuality]
            r, g, b = qc.r, qc.g, qc.b
        end
    end

    -- Layout, backdrop, glow (shared)
    local showIcon = db.display.showIcon ~= false
    ApplyLayout(frame, db, showIcon)
    ApplyBackdrop(frame, db, r, g, b)
    ApplyGlow(frame, db, r, g, b)

    -- Icon
    if showIcon then
        frame.icon:SetTexture(lootData.itemIcon)
        frame.icon:Show()
    end

    ---------------------------------------------------------------------------
    -- Path-specific content
    ---------------------------------------------------------------------------

    if lootData.isXP then
        -- XP toast
        frame.itemName:SetText(lootData.itemName)
        frame.itemName:SetTextColor(1, 0.82, 0)
        frame.quantity:Hide()
        frame.itemLevel:Hide()

        if lootData.mobName and lootData.mobName ~= "" then
            frame.itemType:SetText(lootData.mobName)
            frame.itemType:SetTextColor(0.7, 0.7, 0.7)
            frame.itemType:Show()
        else
            frame.itemType:Hide()
        end

        if db.display.showLooter then
            frame.looter:SetText("You")
            frame.looter:SetTextColor(0.3, 1.0, 0.3)
            frame.looter:Show()
        else
            frame.looter:Hide()
        end

    elseif lootData.isHonor then
        -- Honor toast
        frame.itemName:SetText(lootData.itemName)
        frame.itemName:SetTextColor(1, 0.24, 0.17)
        frame.quantity:Hide()
        frame.itemLevel:Hide()

        if lootData.victimName and lootData.victimName ~= "" then
            frame.itemType:SetText(lootData.victimName)
            frame.itemType:SetTextColor(0.7, 0.7, 0.7)
            frame.itemType:Show()
        else
            frame.itemType:Hide()
        end

        if db.display.showLooter then
            frame.looter:SetText("You")
            frame.looter:SetTextColor(0.3, 1.0, 0.3)
            frame.looter:Show()
        else
            frame.looter:Hide()
        end

    else
        -- Normal item toast
        if lootData.copperAmount and lootData.itemSubType == "Gold" then
            frame.itemName:SetText(FormatMoney(lootData.copperAmount, db.display.goldFormat))
        else
            frame.itemName:SetText(lootData.itemName)
        end
        if lootData.isCurrency then
            frame.itemName:SetTextColor(1, 0.82, 0)
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
        if db.display.showItemLevel and lootData.itemLevel and lootData.itemLevel > 0
            and not lootData.isCurrency then
            frame.itemLevel:SetText("ilvl " .. lootData.itemLevel)
            frame.itemLevel:Show()
        else
            frame.itemLevel:Hide()
        end

        -- Type/Subtype
        if db.display.showItemType and lootData.itemType and not lootData.isCurrency then
            local typeText = lootData.itemType
            if lootData.itemSubType and lootData.itemSubType ~= ""
                and lootData.itemSubType ~= lootData.itemType then
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
                frame.looter:SetTextColor(0.3, 1.0, 0.3)
            else
                frame.looter:SetText(lootData.looter)
                frame.looter:SetTextColor(0.7, 0.7, 0.7)
            end
            frame.looter:Show()
        else
            frame.looter:Hide()
        end
    end

    -- Apply ElvUI skin if available (always last)
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
    frame._backdropKey = nil
    frame._iconBackdropKey = nil
    frame._isExiting = false
    frame._isEntering = false
    frame._phase = nil
    frame._targetY = nil
    frame._anchorY = nil
    frame._deferredSlideArgs = nil

    -- Clean up LibAnimate animation state
    if ns.LibAnimate then
        ns.LibAnimate:Stop(frame)
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
