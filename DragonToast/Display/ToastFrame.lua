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
local GetTime = GetTime
local UIParent = UIParent
local STANDARD_TEXT_FONT = STANDARD_TEXT_FONT
local math_ceil = math.ceil
local string_format = string.format
local LSM = LibStub("LibSharedMedia-3.0")
local L = ns.L
local Utils = ns.ListenerUtils

local DEFAULT_TEXT_PADDING_V = 6
local DEFAULT_TEXT_PADDING_H = 8
local DEFAULT_BORDER_SIZE = 1
local DEFAULT_GLOW_WIDTH = 4
local DEFAULT_ICON_SIZE = 36
local DEFAULT_SECONDARY_FONT_SIZE = 10
local DEFAULT_FRAME_WIDTH = 350
local DEFAULT_FRAME_HEIGHT = 48
local BASE_FRAME_LEVEL = 100
local HOVERED_FRAME_STRATA = "HIGH"
local FRAME_BORDER_OFFSET = 1
local ICON_FRAME_BORDER_EXTRA = 2
local ICON_FRAME_INSET = 4
local TEXT_ONLY_LEFT_INSET = 6
local ICON_BORDER_EDGE_SIZE = 1
local QUALITY_BORDER_ALPHA = 0.6
local DEFAULT_BORDER_COLOR = { r = 0.3, g = 0.3, b = 0.3, a = 0.8 }
local DEFAULT_BACKGROUND_COLOR = { r = 0.05, g = 0.05, b = 0.05, a = 0.7 }
local GOLD_ACCENT_COLOR = { r = 1, g = 0.82, b = 0 }
local HONOR_TOAST_COLOR = { r = 1, g = 0.24, b = 0.17 }
local REPUTATION_TOAST_COLOR = { r = 0.35, g = 0.85, b = 0.55 }
local WHITE_TEXT_COLOR = { r = 1, g = 1, b = 1 }
local MUTED_TEXT_COLOR = { r = 0.7, g = 0.7, b = 0.7 }
local SECONDARY_TEXT_COLOR = { r = 0.5, g = 0.5, b = 0.5 }
local ITEM_LEVEL_TEXT_COLOR = { r = 0.6, g = 0.6, b = 0.6 }
local SELF_LOOTER_COLOR = { r = 0.3, g = 1.0, b = 0.3 }
local ICON_EDGE_FILE = "Interface\\Buttons\\WHITE8x8"
local ICON_BACKDROP_KEY = ICON_EDGE_FILE .. "|1|0"
local ICON_TEX_COORD_MIN = 0.08
local ICON_TEX_COORD_MAX = 0.92
local COPPER_PER_SILVER = 100
local COPPER_PER_GOLD = 10000
local QUANTITY_MIN_STACK = 1

-------------------------------------------------------------------------------
-- Frame Pool
-------------------------------------------------------------------------------

local framePool = {}
local frameCount = 0

local function IsLinkableToast(lootData)
    return lootData
        and lootData.itemLink
        and not lootData.isXP
        and not lootData.isHonor
        and not lootData.isReputation
end

--- Build a cache key for backdrop params to skip redundant SetBackdrop calls during stacking
local function GetBackdropKey(bgFile)
    return bgFile or ""
end

--- Build a cache key for the border frame backdrop
local function GetBorderKey(edgeFile, edgeSize)
    return (edgeFile or "") .. "|" .. tostring(edgeSize)
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
    local padV = db.display.textPaddingV or DEFAULT_TEXT_PADDING_V
    local padH = db.display.textPaddingH or DEFAULT_TEXT_PADDING_H
    local borderSize = db.appearance.borderSize or DEFAULT_BORDER_SIZE
    local borderInset = db.appearance.borderInset or 0
    local glowWidth = db.appearance.glowWidth or DEFAULT_GLOW_WIDTH
    local iconSize = db.appearance.iconSize or DEFAULT_ICON_SIZE
    local contentInset = borderSize > 0 and borderInset or 0

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
        frame.iconFrame:SetSize(iconSize + ICON_FRAME_BORDER_EXTRA, iconSize + ICON_FRAME_BORDER_EXTRA)
        frame.iconFrame:ClearAllPoints()
        frame.iconFrame:SetPoint("LEFT", frame.content, "LEFT", iconGlowPad + ICON_FRAME_INSET, 0)
        frame.iconFrame:Show()
        frame.icon:SetSize(iconSize, iconSize)

        -- Text anchored relative to iconFrame
        frame.itemName:SetPoint("LEFT", frame.iconFrame, "RIGHT", padH, 0)
        frame.itemName:SetPoint("TOP", frame.content, "TOP", 0, -padV)
        frame.itemType:SetPoint("LEFT", frame.iconFrame, "RIGHT", padH, 0)
        frame.itemType:SetPoint("BOTTOM", frame.content, "BOTTOM", 0, padV)
    else
        frame.iconFrame:Hide()
        frame.itemName:SetPoint("TOPLEFT", frame.content, "TOPLEFT", iconGlowPad + TEXT_ONLY_LEFT_INSET, -padV)
        frame.itemType:SetPoint("BOTTOMLEFT", frame.content, "BOTTOMLEFT", iconGlowPad + TEXT_ONLY_LEFT_INSET, padV)
    end

    frame.itemName:SetPoint("RIGHT", frame.content, "RIGHT", -padH, 0)
    frame.itemLevel:SetPoint("TOPRIGHT", frame.content, "TOPRIGHT", -padH, -padV)
    frame.looter:SetPoint("BOTTOMRIGHT", frame.content, "BOTTOMRIGHT", -padH, padV)
end

--- Apply icon frame backdrop (always 1px solid border, no background)
local function ApplyIconBackdrop(frame)
    if frame._iconBackdropKey ~= ICON_BACKDROP_KEY then
        frame.iconFrame:SetBackdrop({
            bgFile = nil,
            edgeFile = ICON_EDGE_FILE,
            edgeSize = ICON_BORDER_EDGE_SIZE,
            insets = { left = 0, right = 0, top = 0, bottom = 0 },
        })
        frame._iconBackdropKey = ICON_BACKDROP_KEY
    end
end

--- Apply quality-based or default border colors to border and icon frames
local function ApplyBorderColors(frame, db, qualityR, qualityG, qualityB)
    if db.appearance.qualityBorder and qualityR then
        frame.borderFrame:SetBackdropBorderColor(qualityR, qualityG, qualityB, QUALITY_BORDER_ALPHA)
        frame.iconFrame:SetBackdropBorderColor(qualityR, qualityG, qualityB, QUALITY_BORDER_ALPHA)
    else
        frame.borderFrame:SetBackdropBorderColor(
            DEFAULT_BORDER_COLOR.r, DEFAULT_BORDER_COLOR.g, DEFAULT_BORDER_COLOR.b, DEFAULT_BORDER_COLOR.a
        )
        frame.iconFrame:SetBackdropBorderColor(
            DEFAULT_BORDER_COLOR.r, DEFAULT_BORDER_COLOR.g, DEFAULT_BORDER_COLOR.b, DEFAULT_BORDER_COLOR.a
        )
    end
end

--- Apply backdrop, background color, and border color to root frame and iconFrame
local function ApplyBackdrop(frame, db, qualityR, qualityG, qualityB)
    local borderSize = db.appearance.borderSize or DEFAULT_BORDER_SIZE

    -- Root frame backdrop: background only, no edge
    local bgFile = LSM:Fetch("background", db.appearance.backgroundTexture or "Solid")
    local backdropKey = GetBackdropKey(bgFile)
    if frame._backdropKey ~= backdropKey then
        frame:SetBackdrop({
            bgFile = bgFile,
            edgeFile = nil,
            edgeSize = 0,
            insets = { left = 0, right = 0, top = 0, bottom = 0 },
        })
        frame._backdropKey = backdropKey
    end

    local bgColor = db.appearance.backgroundColor or DEFAULT_BACKGROUND_COLOR
    frame:SetBackdropColor(bgColor.r, bgColor.g, bgColor.b, db.appearance.backgroundAlpha)

    -- Border frame: edge only, no background. Positioned outside the main frame.
    local edgeFile = borderSize > 0
        and LSM:Fetch("border", db.appearance.borderTexture or "None") or nil
    local borderKey = GetBorderKey(edgeFile, borderSize)
    if frame._borderKey ~= borderKey then
        if borderSize > 0 and edgeFile then
            frame.borderFrame:SetBackdrop({
                bgFile = nil,
                edgeFile = edgeFile,
                edgeSize = borderSize,
                insets = { left = 0, right = 0, top = 0, bottom = 0 },
            })
            frame.borderFrame:Show()
        else
            frame.borderFrame:SetBackdrop(nil)
            frame.borderFrame:Hide()
        end
        frame._borderKey = borderKey
    end

    -- Reposition border frame so the edge texture overlaps the toast background
    local offset = math_ceil(borderSize / 2)
    frame.borderFrame:ClearAllPoints()
    frame.borderFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", -offset, offset)
    frame.borderFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", offset, -offset)

    ApplyIconBackdrop(frame)
    ApplyBorderColors(frame, db, qualityR, qualityG, qualityB)
end

--- Apply quality glow strip to the content frame
local function ApplyGlow(frame, db, r, g, b)
    frame.qualityGlow:ClearAllPoints()
    frame.qualityGlow:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 0, 0)
    frame.qualityGlow:SetPoint("BOTTOMLEFT", frame.content, "BOTTOMLEFT", 0, 0)

    if db.appearance.qualityGlow then
        local glowWidth = db.appearance.glowWidth or DEFAULT_GLOW_WIDTH
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

local function GetToastColor(lootData)
    if lootData.isXP then
        return GOLD_ACCENT_COLOR.r, GOLD_ACCENT_COLOR.g, GOLD_ACCENT_COLOR.b
    end

    if lootData.isHonor then
        return HONOR_TOAST_COLOR.r, HONOR_TOAST_COLOR.g, HONOR_TOAST_COLOR.b
    end

    if lootData.isReputation then
        return REPUTATION_TOAST_COLOR.r, REPUTATION_TOAST_COLOR.g, REPUTATION_TOAST_COLOR.b
    end

    if lootData.itemQuality then
        if ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[lootData.itemQuality] then
            local qualityColor = ITEM_QUALITY_COLORS[lootData.itemQuality]
            return qualityColor.r, qualityColor.g, qualityColor.b
        end

        if ns.QUALITY_COLORS and ns.QUALITY_COLORS[lootData.itemQuality] then
            local qualityColor = ns.QUALITY_COLORS[lootData.itemQuality]
            return qualityColor.r, qualityColor.g, qualityColor.b
        end
    end

    return 1, 1, 1
end

local function ApplyRewardDetail(frame, detailText)
    if not detailText or detailText == "" then
        frame.itemType:Hide()
        return
    end

    frame.itemType:SetText(detailText)
    frame.itemType:SetTextColor(MUTED_TEXT_COLOR.r, MUTED_TEXT_COLOR.g, MUTED_TEXT_COLOR.b)
    frame.itemType:Show()
end

-- Shows or hides the looter label on a reward toast according to configuration.
-- If `db.display.showLooter` is false the looter label is hidden; otherwise the label
-- is set to the localized "YOU" text, colored with `SELF_LOOTER_COLOR`, and shown.
-- @param frame The toast frame containing the `looter` FontString.
-- @param db Configuration table; expects `db.display.showLooter` (boolean) to control visibility.
local function ApplyRewardLooter(frame, db)
    if not db.display.showLooter then
        frame.looter:Hide()
        return
    end

    frame.looter:SetText(L["You"])
    frame.looter:SetTextColor(SELF_LOOTER_COLOR.r, SELF_LOOTER_COLOR.g, SELF_LOOTER_COLOR.b)
    frame.looter:Show()
end

-- Update the toast's looter label according to configuration and loot data.
-- Shows or hides the looter text; when the looter is the player displays
-- `L["YOU"]` with the self looter color, otherwise displays the looter's
-- name with a muted color.
-- @param frame Table representing the toast frame; must contain a `looter` FontString.
-- @param db Table of toast configuration; expects `db.display.showLooter` (boolean).
-- @param lootData Table with looter information. Expected fields:
--   `looter` (string) - name of the looter,
--   `isSelf` (boolean) - true if the looter is the current player.
local function ApplyItemLooter(frame, db, lootData)
    if not db.display.showLooter or not lootData.looter then
        frame.looter:Hide()
        return
    end

    if lootData.isSelf then
        frame.looter:SetText(L["You"])
        frame.looter:SetTextColor(SELF_LOOTER_COLOR.r, SELF_LOOTER_COLOR.g, SELF_LOOTER_COLOR.b)
    else
        frame.looter:SetText(lootData.looter)
        frame.looter:SetTextColor(MUTED_TEXT_COLOR.r, MUTED_TEXT_COLOR.g, MUTED_TEXT_COLOR.b)
    end

    frame.looter:Show()
end

local function BuildItemTypeText(lootData)
    local typeText = lootData.itemType
    if lootData.itemSubType and lootData.itemSubType ~= "" and lootData.itemSubType ~= lootData.itemType then
        typeText = typeText .. " > " .. lootData.itemSubType
    end

    return typeText
end

local function PopulateRewardToast(frame, lootData, db, r, g, b, detailText)
    frame.itemName:SetText(lootData.itemName)
    frame.itemName:SetTextColor(r, g, b)
    frame.quantity:Hide()
    frame.itemLevel:Hide()

    ApplyRewardDetail(frame, detailText)
    ApplyRewardLooter(frame, db)
end

-------------------------------------------------------------------------------
-- Create a single toast frame (split into helpers for readability)
-------------------------------------------------------------------------------

--- Create glow, icon container, icon texture, and quantity badge on the frame
local function CreateToastTextures(frame)
    -- Quality glow strip on content (BACKGROUND layer = behind text but above root border)
    frame.qualityGlow = frame.content:CreateTexture(nil, "BACKGROUND")
    frame.qualityGlow:SetWidth(DEFAULT_GLOW_WIDTH)
    frame.qualityGlow:SetPoint("TOPLEFT", frame.content, "TOPLEFT", FRAME_BORDER_OFFSET, -FRAME_BORDER_OFFSET)
    frame.qualityGlow:SetPoint("BOTTOMLEFT", frame.content, "BOTTOMLEFT", FRAME_BORDER_OFFSET, FRAME_BORDER_OFFSET)
    frame.qualityGlow:SetColorTexture(WHITE_TEXT_COLOR.r, WHITE_TEXT_COLOR.g, WHITE_TEXT_COLOR.b, 0.8)

    -- Icon container frame with its own border (above content)
    frame.iconFrame = CreateFrame("Frame", nil, frame.content, "BackdropTemplate")
    frame.iconFrame:SetFrameLevel(frame.content:GetFrameLevel() + 2)
    frame.iconFrame:SetSize(DEFAULT_ICON_SIZE + ICON_FRAME_BORDER_EXTRA, DEFAULT_ICON_SIZE + ICON_FRAME_BORDER_EXTRA)
    frame.iconFrame:SetBackdrop({
        bgFile = nil,
        edgeFile = ICON_EDGE_FILE,
        edgeSize = ICON_BORDER_EDGE_SIZE,
        insets = { left = 0, right = 0, top = 0, bottom = 0 },
    })
    frame.iconFrame:SetBackdropBorderColor(
        DEFAULT_BORDER_COLOR.r, DEFAULT_BORDER_COLOR.g, DEFAULT_BORDER_COLOR.b, DEFAULT_BORDER_COLOR.a
    )

    -- Icon texture on iconFrame (ARTWORK = natural layer)
    frame.icon = frame.iconFrame:CreateTexture(nil, "ARTWORK")
    frame.icon:SetSize(DEFAULT_ICON_SIZE, DEFAULT_ICON_SIZE)
    frame.icon:SetPoint("CENTER", frame.iconFrame, "CENTER", 0, 0)
    frame.icon:SetTexCoord(ICON_TEX_COORD_MIN, ICON_TEX_COORD_MAX, ICON_TEX_COORD_MIN, ICON_TEX_COORD_MAX)

    -- Quantity badge on iconFrame (OVERLAY = on top of icon)
    frame.quantity = frame.iconFrame:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    frame.quantity:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", 2, -2)
    frame.quantity:SetJustifyH("RIGHT")
    frame.quantity:SetTextColor(WHITE_TEXT_COLOR.r, WHITE_TEXT_COLOR.g, WHITE_TEXT_COLOR.b)
end

--- Create all text FontStrings (itemName, itemLevel, itemType, looter) on the content frame
local function CreateToastTexts(frame)
    frame.itemName = frame.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.itemName:SetJustifyH("LEFT")
    frame.itemName:SetWordWrap(false)

    frame.itemLevel = frame.content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.itemLevel:SetJustifyH("RIGHT")
    frame.itemLevel:SetTextColor(ITEM_LEVEL_TEXT_COLOR.r, ITEM_LEVEL_TEXT_COLOR.g, ITEM_LEVEL_TEXT_COLOR.b)

    frame.itemType = frame.content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.itemType:SetJustifyH("LEFT")
    frame.itemType:SetTextColor(SECONDARY_TEXT_COLOR.r, SECONDARY_TEXT_COLOR.g, SECONDARY_TEXT_COLOR.b)

    frame.looter = frame.content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.looter:SetJustifyH("RIGHT")
    frame.looter:SetTextColor(MUTED_TEXT_COLOR.r, MUTED_TEXT_COLOR.g, MUTED_TEXT_COLOR.b)
end

local function PauseNoAnimTimer(frame)
    if not frame._noAnimTimer then return end
    if not frame._holdEndTime then return end

    frame._holdRemaining = frame._holdEndTime - GetTime()
    if frame._holdRemaining < 0 then
        frame._holdRemaining = 0
    end
    frame._holdEndTime = nil

    ns.Addon:CancelTimer(frame._noAnimTimer)
    frame._noAnimTimer = nil
end

local function ResumeNoAnimTimer(frame)
    if frame._holdRemaining == nil then return end
    if frame._noAnimTimer then return end

    local remaining = frame._holdRemaining
    frame._holdRemaining = nil
    frame._holdEndTime = GetTime() + remaining

    frame._noAnimTimer = ns.Addon:ScheduleTimer(function()
        frame._noAnimTimer = nil
        frame._holdEndTime = nil
        frame._phase = nil
        ns.ToastManager.OnToastFinished(frame)
    end, remaining)
end

--- Wire up click, enter, and leave scripts on the root Button frame
local function SetupToastScripts(frame)
    frame:EnableMouse(true)
    frame:RegisterForClicks("LeftButtonUp")

    frame:SetScript("OnClick", function(self)
        if IsShiftKeyDown() and IsLinkableToast(self.lootData) then
            ChatFrame_OpenChat(self.lootData.itemLink)
        else
            if ns.ToastManager.DismissToast then
                ns.ToastManager.DismissToast(self)
            end
        end
    end)

    frame:SetScript("OnEnter", function(self)
        if IsLinkableToast(self.lootData) then
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:SetHyperlink(self.lootData.itemLink)
            GameTooltip:Show()
        end

        local db = ns.Addon.db
        if not db or not db.profile.animation.pauseOnHover then return end
        if self._phase == nil or self._phase == "entrance" then return end

        self._isHovered = true
        self._savedStrata = self:GetFrameStrata()
        self:SetFrameStrata(HOVERED_FRAME_STRATA)

        if not db.profile.animation.enableAnimations then
            PauseNoAnimTimer(self)
        else
            local libAnim = ns.LibAnimate
            if libAnim then
                if self._isExiting then
                    libAnim:PauseQueue(self)
                elseif libAnim.activeAnimations then
                    -- Freeze in-progress slide at its current interpolated position.
                    -- Accesses LibAnimate internals (tested against LibAnimate r20250315).
                    -- Guard all required fields so we degrade gracefully if internals change.
                    local state = libAnim.activeAnimations[self]
                    if state and state.slideStartTime and state.slideDuration
                        and state.slideFromX and state.slideFromY
                        and state.slideToX and state.slideToY then
                        local slideElapsed = GetTime() - state.slideStartTime
                        local slideProgress = math.min(slideElapsed / state.slideDuration, 1.0)
                        state.anchorX = state.slideFromX
                            + (state.slideToX - state.slideFromX) * slideProgress
                        state.anchorY = state.slideFromY
                            + (state.slideToY - state.slideFromY) * slideProgress
                        state.slideStartTime = nil
                        state.slideDuration = nil
                        state.slideFromX = nil
                        state.slideFromY = nil
                        state.slideToX = nil
                        state.slideToY = nil
                        state.slideElapsedAtPause = nil
                    end
                end
            end
        end
    end)

    frame:SetScript("OnLeave", function(self)
        GameTooltip:Hide()

        if not self._isHovered then return end
        self._isHovered = false

        if self._savedStrata then
            self:SetFrameStrata(self._savedStrata)
            self._savedStrata = nil
        end

        local resumed = false
        if ns.Addon.db and ns.Addon.db.profile.animation.enableAnimations then
            local libAnim = ns.LibAnimate
            if libAnim then
                if self._isExiting then
                    libAnim:ResumeQueue(self)
                    resumed = true
                elseif ns.ToastAnimations.ResumeFromHoverHold then
                    resumed = ns.ToastAnimations.ResumeFromHoverHold(self)
                end
            end
        else
            if self._holdRemaining ~= nil then
                ResumeNoAnimTimer(self)
                resumed = true
            end
        end

        if not resumed then
            ns.ToastManager.OnToastFinished(self)
        end
    end)
end

local function CreateToastFrame()
    frameCount = frameCount + 1
    local frameName = "DragonToastFrame" .. frameCount

    -- Root frame: outer border + background only
    local frame = CreateFrame("Button", frameName, UIParent, "BackdropTemplate")
    frame:SetSize(DEFAULT_FRAME_WIDTH, DEFAULT_FRAME_HEIGHT)
    frame:SetFrameStrata("MEDIUM")
    frame:SetFrameLevel(BASE_FRAME_LEVEL + frameCount)
    frame:Hide()

    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = nil,
        edgeSize = 0,
        insets = { left = 0, right = 0, top = 0, bottom = 0 },
    })
    frame:SetBackdropColor(
        DEFAULT_BACKGROUND_COLOR.r, DEFAULT_BACKGROUND_COLOR.g,
        DEFAULT_BACKGROUND_COLOR.b, DEFAULT_BACKGROUND_COLOR.a
    )

    -- Border frame: wraps outside the main frame, edge only
    frame.borderFrame = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.borderFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", -FRAME_BORDER_OFFSET, FRAME_BORDER_OFFSET)
    frame.borderFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", FRAME_BORDER_OFFSET, -FRAME_BORDER_OFFSET)
    frame.borderFrame:SetFrameLevel(frame:GetFrameLevel() + 1)
    frame.borderFrame:SetBackdrop({
        bgFile = nil,
        edgeFile = ICON_EDGE_FILE,
        edgeSize = ICON_BORDER_EDGE_SIZE,
        insets = { left = 0, right = 0, top = 0, bottom = 0 },
    })
    frame.borderFrame:SetBackdropBorderColor(
        DEFAULT_BORDER_COLOR.r, DEFAULT_BORDER_COLOR.g, DEFAULT_BORDER_COLOR.b, DEFAULT_BORDER_COLOR.a
    )

    -- Content frame: child for all visible content (above root border)
    frame.content = CreateFrame("Frame", nil, frame)
    frame.content:SetAllPoints(frame)
    frame.content:SetFrameLevel(frame:GetFrameLevel() + 2)

    CreateToastTextures(frame)
    CreateToastTexts(frame)
    SetupToastScripts(frame)

    return frame
end

-------------------------------------------------------------------------------
-- Format a copper amount into a human-readable money string
-------------------------------------------------------------------------------

local function FormatMoney(copperAmount, format)
    local gold = math.floor(copperAmount / COPPER_PER_GOLD)
    local silver = math.floor((copperAmount % COPPER_PER_GOLD) / COPPER_PER_SILVER)
    local copper = copperAmount % COPPER_PER_SILVER

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

-- Populates the toast's item-related display fields (name, quantity,
-- item level, type, and looter) according to the provided loot data and
-- display configuration.
-- @param frame The toast frame whose UI elements will be updated
--   (expects fields: itemName, quantity, itemLevel, itemType, etc.).
-- @param lootData Table describing the loot (e.g., itemName,
--   copperAmount, itemSubType, isCurrency, quantity, itemLevel,
--   itemType); used to decide text, colors, and visibility.
-- @param db Configuration table controlling presentation (notably
--   db.display.showQuantity, db.display.showItemLevel,
--   db.display.showItemType, and db.display.goldFormat).
-- @param r Number red component for item name color when the item is not a currency.
-- @param g Number green component for item name color when the item is not a currency.
-- @param b Number blue component for item name color when the item is not a currency.
-- (No return value.)
local function PopulateItemContent(frame, lootData, db, r, g, b)
    -- Money or item name
    if lootData.copperAmount and lootData.itemSubType == "Gold" then
        frame.itemName:SetText(FormatMoney(lootData.copperAmount, db.display.goldFormat))
    else
        frame.itemName:SetText(lootData.itemName)
    end

    -- Currency color
    if lootData.isCurrency then
        frame.itemName:SetTextColor(GOLD_ACCENT_COLOR.r, GOLD_ACCENT_COLOR.g, GOLD_ACCENT_COLOR.b)
    else
        frame.itemName:SetTextColor(r, g, b)
    end

    -- Quantity
    if db.display.showQuantity and lootData.quantity and lootData.quantity > QUANTITY_MIN_STACK then
        frame.quantity:SetText(lootData.quantity)
        frame.quantity:Show()
    else
        frame.quantity:Hide()
    end

    -- Item level
    if db.display.showItemLevel and lootData.itemLevel and lootData.itemLevel > 0
        and not lootData.isCurrency then
        frame.itemLevel:SetText(string_format(L["ilvl %s"], lootData.itemLevel))
        frame.itemLevel:Show()
    else
        frame.itemLevel:Hide()
    end

    -- Type/Subtype
    if db.display.showItemType and lootData.itemType and not lootData.isCurrency then
        frame.itemType:SetText(BuildItemTypeText(lootData))
        frame.itemType:Show()
    else
        frame.itemType:Hide()
    end

    -- Looter
    ApplyItemLooter(frame, db, lootData)
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
    local secondaryFontSize = db.appearance.secondaryFontSize or DEFAULT_SECONDARY_FONT_SIZE

    -- Apply fonts (shared across all paths)
    ApplyFonts(frame, fontPath, fontSize, secondaryFontSize, fontOutline)

    -- Size from config (shared)
    frame:SetSize(db.display.toastWidth, db.display.toastHeight)

    -- Determine quality color
    local r, g, b = GetToastColor(lootData)

    -- Layout, backdrop, glow (shared)
    local showIcon = db.display.showIcon ~= false
    ApplyLayout(frame, db, showIcon)
    ApplyBackdrop(frame, db, r, g, b)
    ApplyGlow(frame, db, r, g, b)

    -- Icon
    if showIcon then
        frame.icon:SetTexture(lootData.itemIcon or Utils.QUESTION_MARK_ICON)
        frame.icon:Show()
    end

    ---------------------------------------------------------------------------
    -- Path-specific content
    ---------------------------------------------------------------------------

    if lootData.isXP then
        PopulateRewardToast(frame, lootData, db, r, g, b, lootData.mobName)
    elseif lootData.isHonor then
        PopulateRewardToast(frame, lootData, db, r, g, b, lootData.victimName)
    elseif lootData.isReputation then
        PopulateRewardToast(frame, lootData, db, r, g, b, lootData.factionName)
    else
        PopulateItemContent(frame, lootData, db, r, g, b)
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
    frame._holdEndTime = nil
    frame._holdRemaining = nil
    frame._isHovered = false
    frame._savedStrata = nil
    frame._hoverHoldCallback = nil
    frame._backdropKey = nil
    frame._borderKey = nil
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
