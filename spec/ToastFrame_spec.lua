-------------------------------------------------------------------------------
-- ToastFrame_spec.lua
-- Unit tests for ToastFrame display logic
--
-- Supported versions: TBC Anniversary, Retail, MoP Classic
-------------------------------------------------------------------------------

local mock = require("spec.wow_mock")

-------------------------------------------------------------------------------
-- Extended frame mock
-------------------------------------------------------------------------------

-- ToastFrame.lua calls many more widget methods than the basic mock provides.
-- Build a richer mock frame that tracks SetText/Show/Hide on FontStrings and
-- Textures so we can assert against them after Populate runs.

local function CreateFontStringSpy()
    local fs = {
        _text = nil,
        _shown = false,
        _justifyH = nil,
        _textColor = nil,
        _font = nil,
        _points = {},
    }
    function fs:SetText(text) self._text = text end
    function fs:Show() self._shown = true end
    function fs:Hide() self._shown = false end
    function fs:SetJustifyH(h) self._justifyH = h end
    function fs:SetWordWrap() end
    function fs:SetTextColor(r, g, b, a)
        self._textColor = { r = r, g = g, b = b, a = a }
    end
    function fs:SetPoint(point, relativeTo, relativePoint, x, y)
        self._points[#self._points + 1] = {
            point = point, relativeTo = relativeTo,
            relativePoint = relativePoint, x = x, y = y,
        }
    end
    function fs:ClearAllPoints() self._points = {} end
    function fs:SetFont(path, size, outline) self._font = { path, size, outline } end
    return fs
end

local function CreateTextureSpy()
    local texture = {
        SetAllPoints = function() end,
        SetColorTexture = function(self, ...) self._color = { ... } end,
        SetTexture = function(self, value) self._texture = value end,
        SetVertexColor = function(self, ...) self._vertexColor = { ... } end,
        SetTexCoord = function(self, ...) self._texCoord = { ... } end,
        SetSize = function() end,
        SetPoint = function() end,
        ClearAllPoints = function() end,
        SetWidth = function() end,
        Show = function() end,
        Hide = function() end,
    }
    return texture
end

local function CreateRichMockFrame(_, name, parent)
    local frame = {
        _name = name,
        _parent = parent,
        _points = {},
        _shown = false,
        _size = { w = 0, h = 0 },
        _scripts = {},
        _frameLevel = 1,
        _strata = "MEDIUM",
        _alpha = 1,
        _scale = 1,
        _backdrop = nil,
        lootData = nil,
    }

    function frame:SetPoint() end
    function frame:ClearAllPoints() self._points = {} end
    function frame:GetPoint()
        local p = self._points
        return p.point, p.relativeTo, p.relativePoint, p.x or 0, p.y or 0
    end
    function frame:Show() self._shown = true end
    function frame:Hide() self._shown = false end
    function frame:IsShown() return self._shown end
    function frame:SetSize(w, h) self._size = { w = w, h = h } end
    function frame:GetWidth() return self._size.w end
    function frame:GetHeight() return self._size.h end
    function frame:SetFrameStrata(s) self._strata = s end
    function frame:GetFrameStrata() return self._strata end
    function frame:SetFrameLevel(l) self._frameLevel = l end
    function frame:GetFrameLevel() return self._frameLevel end
    function frame:SetBackdrop(bd) self._backdrop = bd end
    function frame:SetBackdropColor(...) self._backdropColor = { ... } end
    function frame:SetBackdropBorderColor(...) self._borderColor = { ... } end
    function frame:SetAlpha(a) self._alpha = a end
    function frame:SetScale(s) self._scale = s end
    function frame:EnableMouse(enabled) self._mouseEnabled = enabled end
    function frame:RegisterForClicks() end
    function frame:SetAllPoints() end
    function frame:SetMovable() end
    function frame:SetClampedToScreen() end
    function frame:StartMoving() end
    function frame:StopMovingOrSizing() end
    function frame:SetScript(event, handler)
        self._scripts[event] = handler
    end

    function frame:CreateTexture()
        return CreateTextureSpy()
    end

    function frame:CreateFontString()
        return CreateFontStringSpy()
    end

    return frame
end

-------------------------------------------------------------------------------
-- Test helpers
-------------------------------------------------------------------------------

local function makeItemData(overrides)
    local data = {
        itemName    = "Thunderfury",
        itemIcon    = 123456,
        itemQuality = 4,
        itemID      = 19019,
        itemLink    = "|cffa335ee|Hitem:19019:::::::60:::::|h[Thunderfury]|h|r",
        itemLevel   = 80,
        itemType    = "Weapon",
        itemSubType = "Sword",
        quantity    = 1,
        isSelf      = true,
        looter      = "TestPlayer",
        isCurrency  = false,
        timestamp   = GetTime(),
    }
    if overrides then
        for k, v in pairs(overrides) do data[k] = v end
    end
    return data
end

--- Find the first anchor in a FontStringSpy's _points list matching the given point name.
--- Returns the anchor table or nil.
local function findAnchor(fontStringSpy, pointName)
    for _, anchor in ipairs(fontStringSpy._points) do
        if anchor.point == pointName then
            return anchor
        end
    end
    return nil
end

-- Controllable GetItemCount: delegates to _mock so tests can swap behavior
-- after the module has already cached the local reference.
local _mockGetItemCount = { fn = function() return 3 end }
local function GetItemCountProxy(itemID)
    return _mockGetItemCount.fn(itemID)
end

-------------------------------------------------------------------------------
-- Tests
-------------------------------------------------------------------------------

describe("ToastFrame display", function()
    local ns
    local frame
    local originalGetCoinTextureString
    local originalGoldAmount, originalSilverAmount, originalCopperAmount

    setup(function()
        originalGetCoinTextureString = _G.GetCoinTextureString
        originalGoldAmount, originalSilverAmount, originalCopperAmount =
            _G.GOLD_AMOUNT, _G.SILVER_AMOUNT, _G.COPPER_AMOUNT
        _G.GetCoinTextureString = nil
        _G.GOLD_AMOUNT, _G.SILVER_AMOUNT, _G.COPPER_AMOUNT = "%d Gold", "%d Silver", "%d Copper"

        -- Override CreateFrame and UIParent with richer mocks before loading
        -- luacheck: ignore 122
        rawset(_G, "CreateFrame", function(...)
            return CreateRichMockFrame(...)
        end)
        -- luacheck: ignore 122
        rawset(_G, "UIParent", CreateRichMockFrame())

        ns = mock.CreateNamespace()

        -- Provide the display config fields that ToastFrame reads
        local display = ns.Addon.db.profile.display
        display.showItemCount = true
        display.showItemLevel = true
        display.showItemType = true
        display.showIcon = true
        display.showLooter = true
        display.goldFormat = "short"
        display.textPaddingV = 6
        display.textPaddingH = 8

        -- Provide appearance config fields that ToastFrame reads
        local appearance = ns.Addon.db.profile.appearance
        appearance.borderSize = 1
        appearance.borderInset = 0
        appearance.glowWidth = 4
        appearance.qualityGlow = false
        appearance.qualityBorder = false
        appearance.backgroundAlpha = 0.7
        appearance.fontOutline = "OUTLINE"
        appearance.fontSize = 12
        appearance.secondaryFontSize = 10

        -- Stub globals needed at load time
        _G.STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
        _G.ITEM_QUALITY_COLORS = {
            [0] = { r = 0.6, g = 0.6, b = 0.6 },
            [1] = { r = 1, g = 1, b = 1 },
            [2] = { r = 0.12, g = 1, b = 0 },
            [3] = { r = 0, g = 0.44, b = 0.87 },
            [4] = { r = 0.64, g = 0.21, b = 0.93 },
            [5] = { r = 1, g = 0.5, b = 0 },
        }
        _G.IsShiftKeyDown = function() return false end
        _G.ChatFrame_OpenChat = function() end
        _G.GameTooltip = {
            SetOwner = function() end,
            SetHyperlink = function() end,
            Show = function() end,
            Hide = function() end,
        }
        _G.GetItemCount = GetItemCountProxy
        _G.C_Item = nil

        -- ListenerUtils needs QUESTION_MARK_ICON
        ns.ListenerUtils = ns.ListenerUtils or {}
        ns.ListenerUtils.QUESTION_MARK_ICON = 134400

        -- LibAnimate stub
        ns.LibAnimate = nil

        -- ElvUISkin stub
        ns.ElvUISkin = nil

        -- Load ToastFrame.lua - it overwrites ns.ToastFrame
        local originalLibStub = _G.LibStub
        rawset(_G, "LibStub", function(name, ...)
            if name == "LibSharedMedia-3.0" then
                return { Fetch = function(_, mediaType, key)
                    if mediaType == "statusbar" and key == "Example texture" then return "example.blp" end
                end }
            end
            return originalLibStub(name, ...)
        end)
        local chunk = assert(loadfile("DragonToast/Display/ToastFrame.lua"))
        chunk("DragonToast", ns)
        rawset(_G, "LibStub", originalLibStub)
    end)

    teardown(function()
        _G.GetCoinTextureString = originalGetCoinTextureString
        _G.GOLD_AMOUNT, _G.SILVER_AMOUNT, _G.COPPER_AMOUNT =
            originalGoldAmount, originalSilverAmount, originalCopperAmount
    end)

    before_each(function()
        -- Reset display config to known defaults
        ns.Addon.db.profile.display.showItemCount = true
        ns.Addon.db.profile.display.showItemLevel = true
        ns.Addon.db.profile.display.showItemType = true
        ns.Addon.db.profile.display.showIcon = true
        ns.Addon.db.profile.display.showLooter = true
        ns.Addon.db.profile.display.goldFormat = "short"

        -- Reset appearance config to known defaults
        ns.Addon.db.profile.appearance.secondaryFontSize = 10
        local appearance = ns.Addon.db.profile.appearance
        appearance.borderColor, appearance.borderAlpha = nil, nil
        appearance.qualityBorderAlpha, appearance.glowAlpha, appearance.iconCrop = nil, nil, nil
        appearance.qualityBorder, appearance.qualityGlow = false, false
        appearance.statusBarTexture = nil

        -- Reset display padding to known defaults
        ns.Addon.db.profile.display.textPaddingH = 8
        ns.Addon.db.profile.display.textPaddingV = 6

        -- Acquire a fresh frame from the real pool
        frame = ns.ToastFrame.Acquire()

        -- Reset GetItemCount mock to default (returns 3)
        _mockGetItemCount.fn = function() return 3 end
    end)

    after_each(function()
        if ns.ToastManager.ClearAll then
            ns.ToastManager.ClearAll()
        end
        if frame then
            ns.ToastFrame.Release(frame)
            frame = nil
        end
    end)

    it("shows count text when showItemCount=true and itemID present", function()
        _mockGetItemCount.fn = function() return 3 end
        local data = makeItemData()

        ns.ToastFrame.Populate(frame, data)

        assert.is_true(frame.itemCount._shown)
        assert.equal("x3 in bags", frame.itemCount._text)
    end)

    it("hides count when showItemCount=false", function()
        ns.Addon.db.profile.display.showItemCount = false
        local data = makeItemData()

        ns.ToastFrame.Populate(frame, data)

        assert.is_false(frame.itemCount._shown)
    end)

    it("hides count when itemID is nil", function()
        local data = makeItemData()
        data.itemID = nil

        ns.ToastFrame.Populate(frame, data)

        assert.is_false(frame.itemCount._shown)
    end)

    it("hides count for currency toasts", function()
        local data = makeItemData({ isCurrency = true })

        ns.ToastFrame.Populate(frame, data)

        assert.is_false(frame.itemCount._shown)
    end)

    it("displays count=0 when GetItemCount returns nil", function()
        _mockGetItemCount.fn = function() return nil end
        local data = makeItemData()

        ns.ToastFrame.Populate(frame, data)

        assert.is_true(frame.itemCount._shown)
        assert.equal("x0 in bags", frame.itemCount._text)
    end)

    it("hides item count for other player's loot (isSelf = false)", function()
        _mockGetItemCount.fn = function() return 3 end
        ns.Addon.db.profile.display.showItemCount = true
        local data = makeItemData({ isSelf = false, itemID = 19019 })

        ns.ToastFrame.Populate(frame, data)

        assert.is_false(frame.itemCount._shown)
    end)

    for _, moneyFormat in ipairs({
        { name = "icons", value = "icons", expected = "12345c" },
        { name = "short", value = "short", expected = "1g 23s 45c" },
        { name = "long", value = "long", expected = "1 Gold 23 Silver 45 Copper" },
    }) do
        for _, direction in ipairs({ "gain", "loss" }) do
            it("renders money " .. direction .. "s using " .. moneyFormat.name, function()
                ns.Addon.db.profile.display.goldFormat = moneyFormat.value
                local data = makeItemData({
                    copperAmount = 12345,
                    itemSubType = "Gold",
                    isCurrency = true,
                    moneyDirection = direction,
                })

                ns.ToastFrame.Populate(frame, data)

                local expectedText = (direction == "loss" and "-" or "") .. moneyFormat.expected
                local expectedColor = direction == "loss"
                    and { r = 1, g = 0.2, b = 0.2, a = nil }
                    or { r = 1, g = 0.82, b = 0, a = nil }
                assert.equal(expectedText, frame.itemName._text)
                assert.same(expectedColor, frame.itemName._textColor)
            end)
        end
    end

    it("renders and stacks generated gold test toasts without the legacy coin API", function()
        ns.Addon.db.profile.display.goldFormat = "icons"
        mock.LoadToastManager(ns)
        ns.ToastManager.Initialize()
        local chunk = assert(loadfile("DragonToast/Display/TestToasts.lua"))
        chunk("DragonToast", ns)

        ns.TestToasts.RunStackTest("gold")

        local activeToasts = ns.ToastManager._test.activeToasts
        assert.equal(1, #activeToasts)
        assert.equal("150000c", activeToasts[1].itemName._text)
        assert.equal(133784, activeToasts[1].icon._texture)
        assert.is_false(activeToasts[1].itemLevel._shown)
    end)

    it("anchors itemCount to content TOPRIGHT regardless of itemLevel visibility", function()
        ns.Addon.db.profile.display.showItemLevel = false
        local data = makeItemData()

        ns.ToastFrame.Populate(frame, data)

        -- itemLevel must be hidden
        assert.is_false(frame.itemLevel._shown)

        -- itemCount must be visible and anchored to content, not itemLevel
        assert.is_true(frame.itemCount._shown)
        local anchor = findAnchor(frame.itemCount, "TOPRIGHT")
        assert.is_not_nil(anchor)
        assert.is_true(anchor.relativeTo == frame.content, "expected relativeTo to be the content frame")
        assert.equal("TOPRIGHT", anchor.relativePoint)

        local padH = ns.Addon.db.profile.display.textPaddingH
        local padV = ns.Addon.db.profile.display.textPaddingV
        local secondaryFontSize = ns.Addon.db.profile.appearance.secondaryFontSize
        assert.equal(-padH, anchor.x)
        assert.equal(-padV - secondaryFontSize - 2, anchor.y)
    end)

    it("uses live secondaryFontSize for itemCount Y offset", function()
        ns.Addon.db.profile.appearance.secondaryFontSize = 14
        local data = makeItemData()

        ns.ToastFrame.Populate(frame, data)

        assert.is_true(frame.itemCount._shown)
        local anchor = findAnchor(frame.itemCount, "TOPRIGHT")
        assert.is_not_nil(anchor)

        local padV = ns.Addon.db.profile.display.textPaddingV
        -- Y offset must use the live font size (14), not the default (10)
        assert.equal(-padV - 14 - 2, anchor.y)
    end)

    it("uses the loss icon, label, and red color for reputation losses", function()
        local data = makeItemData({
            isReputation = true,
            reputationAmount = 250,
            reputationDirection = "loss",
            factionName = "The Sha'tar",
            itemName = "-250 Reputation",
            itemIcon = "ReputationLoss",
        })
        ns.ToastFrame.Populate(frame, data)
        assert.equal("ReputationLoss", frame.icon._texture)
        assert.equal("-250 Reputation", frame.itemName._text)
        assert.equal(0.95, frame.itemName._textColor.r)
        assert.equal(0.3, frame.itemName._textColor.g)
        assert.equal(0.3, frame.itemName._textColor.b)
    end)

    it("keeps the preview anonymous and independent of the live pool and lifecycle", function()
        local live = frame
        ns.ToastFrame.Release(live)
        frame = nil
        local parent = CreateRichMockFrame()
        parent:SetSize(500, 130)
        local oldManager, oldAnimations, oldTestToasts = ns.ToastManager, ns.ToastAnimations, ns.TestToasts
        local forbidden = setmetatable({}, { __index = function() error("Preview touched live toast state") end })
        ns.ToastManager, ns.ToastAnimations, ns.TestToasts = forbidden, forbidden, forbidden

        local preview = ns.ToastFrame.CreatePreview(parent)
        preview:Refresh(makeItemData())
        assert.is_nil(preview.frame._name)
        assert.are.equal(parent, preview.frame.layoutFrame._parent)
        assert.is_false(preview.frame._mouseEnabled)
        assert.is_false(preview.frame.iconFrame._mouseEnabled)
        assert.is_nil(preview.frame._scripts.OnClick)
        assert.is_nil(preview.frame._scripts.OnEnter)
        assert.is_nil(preview.frame._scripts.OnLeave)
        preview:OnHide()
        assert.is_false(preview.frame:IsShown())
        assert.is_false(preview.frame.layoutFrame:IsShown())

        ns.ToastManager, ns.ToastAnimations, ns.TestToasts = oldManager, oldAnimations, oldTestToasts
        frame = ns.ToastFrame.Acquire()
        assert.are.equal(live, frame)
    end)

    it("redraws the preview from current settings and only scales down to fit", function()
        local parent = CreateRichMockFrame()
        parent:SetSize(200, 100)
        local preview = ns.ToastFrame.CreatePreview(parent)
        local profile = ns.Addon.db.profile
        local display, appearance = profile.display, profile.appearance
        local oldWidth, oldFont = display.toastWidth, appearance.fontSize
        local oldColor, oldAlpha = appearance.backgroundColor, appearance.backgroundAlpha
        local anchorPoint, anchorX, anchorY = display.anchorPoint, display.anchorX, display.anchorY

        preview:Refresh(makeItemData())
        assert.is_true(preview.frame.layoutFrame._scale < 1)
        display.toastWidth = 160
        appearance.fontSize = 16
        appearance.backgroundColor = { r = 0.1, g = 0.2, b = 0.3 }
        appearance.backgroundAlpha = 0.5
        local width, height, scale = preview:Refresh(makeItemData({ itemQuality = 5, itemIcon = 654321 }))

        assert.are.equal(160, preview.frame:GetWidth())
        assert.are.equal(160, width)
        assert.are.equal(preview.frame:GetHeight(), height)
        assert.are.equal(1, scale)
        assert.are.equal(16, preview.frame.itemName._font[2])
        assert.are.same({ 0.1, 0.2, 0.3, 0.5 }, preview.frame._backdropColor)
        assert.are.equal(654321, preview.frame.icon._texture)
        assert.are.equal(1, preview.frame.itemName._textColor.r)
        assert.are.equal(0.5, preview.frame.itemName._textColor.g)
        assert.are.equal(1, preview.frame.layoutFrame._scale)
        assert.are.same({ anchorPoint, anchorX, anchorY },
            { display.anchorPoint, display.anchorX, display.anchorY })

        display.toastWidth, appearance.fontSize = oldWidth, oldFont
        appearance.backgroundColor, appearance.backgroundAlpha = oldColor, oldAlpha
    end)

    it("retains the historical border, glow, and crop when new profile fields are absent", function()
        local appearance = ns.Addon.db.profile.appearance
        local data = makeItemData({ itemQuality = 4 })
        appearance.qualityBorder, appearance.qualityGlow = true, true
        ns.ToastFrame.Populate(frame, data)
        assert.are.same({ 0.64, 0.21, 0.93, 0.6 }, frame.borderFrame._borderColor)
        assert.are.same(frame.borderFrame._borderColor, frame.iconFrame._borderColor)
        assert.are.same({ 0.64, 0.21, 0.93, 0.8 }, frame.qualityGlow._color)
        assert.are.same({ 0.08, 0.92, 0.08, 0.92 }, frame.icon._texCoord)

        appearance.qualityBorder = false
        ns.ToastFrame.Populate(frame, data)
        assert.are.same({ 0.3, 0.3, 0.3, 0.8 }, frame.borderFrame._borderColor)
    end)

    it("redraws custom border, glow, and icon crop on live and isolated frames including zero opacity", function()
        local appearance = ns.Addon.db.profile.appearance
        appearance.borderColor = { r = 0.1, g = 0.2, b = 0.4 }
        appearance.borderAlpha = 0.25
        appearance.qualityGlow = true
        appearance.glowAlpha = 0.35
        appearance.statusBarTexture = "Example texture"
        appearance.iconCrop = 0.15
        local data = makeItemData({ itemQuality = 4 })
        local parent = CreateRichMockFrame()
        parent:SetSize(500, 100)
        local preview = ns.ToastFrame.CreatePreview(parent)
        local display = ns.Addon.db.profile.display
        local position = { display.anchorPoint, display.anchorX, display.anchorY }

        ns.ToastFrame.Populate(frame, data)
        preview:Refresh(data)
        for _, rendered in ipairs({ frame, preview.frame }) do
            assert.are.same({ 0.1, 0.2, 0.4, 0.25 }, rendered.borderFrame._borderColor)
            assert.are.same({ 0.64, 0.21, 0.93, 0.35 }, rendered.qualityGlow._vertexColor)
            assert.are.same({ 0.15, 0.85, 0.15, 0.85 }, rendered.icon._texCoord)
        end

        appearance.qualityBorder = true
        appearance.qualityBorderAlpha, appearance.glowAlpha, appearance.iconCrop = 0, 0, 0
        preview:Refresh(data)
        assert.are.same({ 0.64, 0.21, 0.93, 0 }, preview.frame.borderFrame._borderColor)
        assert.are.same({ 0.64, 0.21, 0.93, 0 }, preview.frame.qualityGlow._vertexColor)
        assert.are.same({ 0, 1, 0, 1 }, preview.frame.icon._texCoord)
        appearance.qualityBorder, appearance.borderAlpha = false, 0
        preview:Refresh(data)
        assert.are.same({ 0.1, 0.2, 0.4, 0 }, preview.frame.borderFrame._borderColor)
        assert.are.same(position, { display.anchorPoint, display.anchorX, display.anchorY })
    end)

end)
