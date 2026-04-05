-------------------------------------------------------------------------------
-- ToastFrame_spec.lua
-- Unit tests for ToastFrame item count display logic
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
    return {
        SetAllPoints = function() end,
        SetColorTexture = function() end,
        SetTexture = function() end,
        SetVertexColor = function() end,
        SetTexCoord = function() end,
        SetSize = function() end,
        SetPoint = function() end,
        ClearAllPoints = function() end,
        SetWidth = function() end,
        Show = function() end,
        Hide = function() end,
    }
end

local function CreateRichMockFrame()
    local frame = {
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
    function frame:SetBackdropColor() end
    function frame:SetBackdropBorderColor() end
    function frame:SetAlpha(a) self._alpha = a end
    function frame:SetScale(s) self._scale = s end
    function frame:EnableMouse() end
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

describe("ToastFrame item count display", function()
    local ns
    local frame

    setup(function()
        -- Override CreateFrame and UIParent with richer mocks before loading
        -- luacheck: ignore 122
        rawset(_G, "CreateFrame", function()
            return CreateRichMockFrame()
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
        local chunk = assert(loadfile("DragonToast/Display/ToastFrame.lua"))
        chunk("DragonToast", ns)
    end)

    before_each(function()
        -- Reset display config to known defaults
        ns.Addon.db.profile.display.showItemCount = true
        ns.Addon.db.profile.display.showItemLevel = true
        ns.Addon.db.profile.display.showItemType = true
        ns.Addon.db.profile.display.showIcon = true
        ns.Addon.db.profile.display.showLooter = true

        -- Reset appearance config to known defaults
        ns.Addon.db.profile.appearance.secondaryFontSize = 10

        -- Reset display padding to known defaults
        ns.Addon.db.profile.display.textPaddingH = 8
        ns.Addon.db.profile.display.textPaddingV = 6

        -- Acquire a fresh frame from the real pool
        frame = ns.ToastFrame.Acquire()

        -- Reset GetItemCount mock to default (returns 3)
        _mockGetItemCount.fn = function() return 3 end
    end)

    after_each(function()
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
end)
