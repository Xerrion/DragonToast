-------------------------------------------------------------------------------
-- animation_harness.lua
-- Real toast lifecycle and LibAnimate, driven by a deterministic test clock.
-- Run tests from the repository root after initializing the LibAnimate submodule.
-- Supported versions: TBC Anniversary, Retail, MoP Classic
-------------------------------------------------------------------------------

local M = {}
local DEFAULT_STEP = 1 / 120
local EPSILON = 1e-9
local noop = function() end

local function Copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, child in pairs(value) do result[key] = Copy(child) end
    return result
end

local function Merge(target, values)
    for key, value in pairs(values or {}) do
        if type(value) == "table" and type(target[key]) == "table" then
            Merge(target[key], value)
        else
            target[key] = Copy(value)
        end
    end
end

local Widget = {}
Widget.__index = Widget

function Widget:SetPoint(point, relativeTo, relativePoint, x, y)
    if type(relativeTo) == "number" then
        x, y, relativeTo, relativePoint = relativeTo, relativePoint, self._parent, point
    elseif type(relativeTo) == "string" then
        relativeTo = self._harness.namedFrames[relativeTo]
    end
    relativeTo = relativeTo or self._parent
    relativePoint = relativePoint or point
    local entry = { point, relativeTo, relativePoint, x or 0, y or 0 }
    self._allPoints = nil
    for i, previous in ipairs(self._points) do
        if previous[1] == point then self._points[i] = entry; return end
    end
    self._points[#self._points + 1] = entry
end

function Widget:GetPoint(index) return unpack(self._points[index or 1] or {}) end
function Widget:GetNumPoints() return #self._points end
function Widget:ClearAllPoints() self._points = {}; self._allPoints = nil end
function Widget:SetAllPoints(parent) self:ClearAllPoints(); self._allPoints = parent or self._parent end
function Widget:SetParent(parent) self._parent = parent end
function Widget:GetParent() return self._parent end
function Widget:SetSize(width, height) self._width = width; self._height = height end
function Widget:SetWidth(width) self._width = width end
function Widget:SetHeight(height) self._height = height end
function Widget:GetWidth() return self._width or (self._allPoints and self._allPoints:GetWidth()) or 0 end
function Widget:GetHeight() return self._height or (self._allPoints and self._allPoints:GetHeight()) or 0 end
function Widget:SetAlpha(alpha) self._alpha = alpha end
function Widget:GetAlpha() return self._alpha end
function Widget:SetScale(scale) self._scale = scale end
function Widget:GetScale() return self._scale end
function Widget:GetEffectiveScale()
    return self._scale * (self._parent and self._parent:GetEffectiveScale() or 1)
end
function Widget:GetEffectiveAlpha()
    return self._alpha * (self._parent and self._parent:GetEffectiveAlpha() or 1)
end
function Widget:Show() self._shown = true end
function Widget:Hide() self._shown = false end
function Widget:IsShown() return self._shown end
function Widget:IsVisible() return self._shown and (not self._parent or self._parent:IsVisible()) end
function Widget:SetScript(event, callback) self._scripts[event] = callback end
function Widget:GetScript(event) return self._scripts[event] end
function Widget:HookScript(event, callback)
    local previous = self._scripts[event]
    self._scripts[event] = function(...)
        if previous then previous(...) end
        callback(...)
    end
end
function Widget:SetFrameLevel(level) self._frameLevel = level end
function Widget:GetFrameLevel() return self._frameLevel end
function Widget:SetFrameStrata(strata) self._strata = strata end
function Widget:GetFrameStrata() return self._strata end
function Widget:SetText(text) self._text = text end
function Widget:GetText() return self._text end
function Widget:SetBackdrop(backdrop) self._backdrop = backdrop end
function Widget:SetTexture(texture) self._texture = texture end
function Widget:CreateTexture() return self._harness:CreateWidget(self, false) end
function Widget:CreateFontString() return self._harness:CreateWidget(self, false) end

for _, name in ipairs({
    "SetBackdropColor", "SetBackdropBorderColor", "SetColorTexture", "SetVertexColor", "SetTexCoord",
    "SetFont", "SetTextColor", "SetWordWrap", "SetJustifyH", "SetMovable", "SetClampedToScreen",
    "EnableMouse", "RegisterForClicks", "StartMoving", "StopMovingOrSizing",
}) do
    Widget[name] = noop
end

local function AnchorFactors(point)
    local x = point:find("LEFT") and -0.5 or (point:find("RIGHT") and 0.5 or 0)
    local y = point:find("BOTTOM") and -0.5 or (point:find("TOP") and 0.5 or 0)
    return x, y
end

-- Geometry follows the first anchor and accounts for relative frames and scale.
-- Two-point stretching of decorative regions is outside these lifecycle tests.
function Widget:GetCenter()
    if self._allPoints then return self._allPoints:GetCenter() end
    local point, relativeTo, relativePoint, x, y = self:GetPoint()
    if not point then return 0, 0 end
    local relativeX, relativeY = 0, 0
    if relativeTo then
        relativeX, relativeY = relativeTo:GetCenter()
        local fx, fy = AnchorFactors(relativePoint)
        local scale = relativeTo:GetEffectiveScale()
        relativeX = relativeX + fx * relativeTo:GetWidth() * scale
        relativeY = relativeY + fy * relativeTo:GetHeight() * scale
    end
    local fx, fy = AnchorFactors(point)
    local scale = self:GetEffectiveScale()
    return relativeX + x * scale - fx * self:GetWidth() * scale,
        relativeY + y * scale - fy * self:GetHeight() * scale
end

local Harness = {}
Harness.__index = Harness

function Harness:CreateWidget(parent, isFrame, name)
    local widget = setmetatable({
        _harness = self, _parent = parent, _points = {}, _scripts = {},
        _shown = true, _alpha = 1, _scale = 1, _frameLevel = 1, _strata = "MEDIUM",
    }, Widget)
    if isFrame then self.frames[#self.frames + 1] = widget end
    if name then self.namedFrames[name] = widget end
    return widget
end

function Harness:PendingTimerCount()
    local count = 0
    for _, timer in ipairs(self.timers) do if not timer.cancelled then count = count + 1 end end
    return count
end

-- A single rendering frame. Due timers run in deadline/creation order, then
-- frame OnUpdate handlers run in creation order, including the real LibAnimate driver.
function Harness:Step(seconds)
    assert(seconds >= 0, "Cannot move the test clock backwards")
    self.now = self.now + seconds
    local due = {}
    for _, timer in ipairs(self.timers) do
        if not timer.cancelled and timer.due <= self.now + EPSILON then due[#due + 1] = timer end
    end
    table.sort(due, function(a, b)
        if a.due == b.due then return a.id < b.id end
        return a.due < b.due
    end)
    for _, timer in ipairs(due) do
        if not timer.cancelled then
            timer.cancelled = true
            timer.callback()
        end
    end
    local frameCount = #self.frames
    for i = 1, frameCount do
        local frame = self.frames[i]
        local callback = frame:GetScript("OnUpdate")
        if callback and frame:IsVisible() then callback(frame, seconds) end
    end
end

function Harness:Advance(seconds, step)
    assert(seconds >= 0, "Cannot move the test clock backwards")
    step = step or DEFAULT_STEP
    assert(step > 0, "Frame interval must be positive")
    local target = self.now + seconds
    while self.now < target - EPSILON do
        local elapsed = math.min(step, target - self.now)
        for _, timer in ipairs(self.timers) do
            local remaining = timer.due - self.now
            if not timer.cancelled and remaining > EPSILON then elapsed = math.min(elapsed, remaining) end
        end
        self:Step(elapsed)
    end
end

function Harness:Find(itemID)
    for _, frame in ipairs(self.ns.ToastManager._test.activeToasts) do
        if frame.lootData and frame.lootData.itemID == itemID then return frame end
    end
end

function Harness:Queue(itemID, values)
    if type(itemID) == "table" then values, itemID = itemID, nil end
    self.nextItemID = self.nextItemID + 1
    itemID = itemID or self.nextItemID
    local data = {
        itemID = itemID, itemName = "Item " .. itemID, itemIcon = 134400, itemQuality = 4,
        itemLink = "|Hitem:" .. itemID .. "|h[Item " .. itemID .. "]|h",
        quantity = 1, isSelf = true, looter = "TestPlayer", timestamp = self.now,
    }
    Merge(data, values)
    self.ns.ToastManager.QueueToast(data)
    return self:Find(data.itemID), data
end

function Harness:Visible()
    local visible = {}
    for _, frame in ipairs(self.ns.ToastManager._test.activeToasts) do
        if frame:IsVisible() then visible[#visible + 1] = frame end
    end
    return visible
end

function Harness:Enter(frame)
    local callback = frame:GetScript("OnEnter")
    if callback then callback(frame) end
end

function Harness:Leave(frame)
    local callback = frame:GetScript("OnLeave")
    if callback then callback(frame) end
end

function Harness:FireEvent(event, ...)
    local callback = self.events[event]
    if callback then callback(event, ...) end
end

-- Absolute center in UIParent coordinates, including movement of any ancestor.
function Harness:Position(frame) return frame:GetCenter() end

function Harness:Restore()
    if self.restored then return end
    self.restored = true
    local ok, err = pcall(function() self.ns.ToastManager.ClearAll() end)
    for name, entry in pairs(self.savedGlobals) do rawset(_G, name, entry.value) end
    if not ok then error(err) end
end

local LIBRARY_PATH = "DragonToast/Libs/LibAnimate/"

--- Whether the pinned LibAnimate submodule can be loaded. Specs that need it
--- skip themselves when it is absent so a plain checkout still runs the rest
--- of the suite. CI sets DRAGONTOAST_REQUIRE_LIBANIMATE so a missing submodule
--- there is a hard failure from New() instead of a silent skip.
function M.IsAvailable()
    if os.getenv("DRAGONTOAST_REQUIRE_LIBANIMATE") then return true end
    local file = io.open(LIBRARY_PATH .. "LibAnimate.lua", "r")
    if file then file:close() end
    return file ~= nil
end

function M.New(overrides)
    local libraryPath = LIBRARY_PATH
    local libraryChunk, libraryError = loadfile(libraryPath .. "LibAnimate.lua")
    assert(libraryChunk, "Initialize the pinned animation dependency with "
        .. "`git submodule update --init DragonToast/Libs/LibAnimate`: " .. tostring(libraryError))
    local animationsChunk = assert(loadfile(libraryPath .. "Animations.lua"))
    local self = setmetatable({
        now = 0, frames = {}, namedFrames = {}, timers = {}, events = {}, nextItemID = 10000, savedGlobals = {},
    }, Harness)
    local function SetGlobal(name, value)
        self.savedGlobals[name] = { value = rawget(_G, name) }
        rawset(_G, name, value)
    end
    local ns = {
        ToastFrame = {}, ToastAnimations = {}, ToastManager = {}, QueueUtils = {},
        ListenerUtils = { QUESTION_MARK_ICON = 134400 },
        TestToasts = { StopTestMode = noop }, MessageBridge = { IsSuppressed = function() return false end },
        DebugPrint = noop, Print = noop, FormatNumber = tostring,
        L = setmetatable({}, { __index = function(_, key) return key end }),
        Addon = { RegisterEvent = noop },
    }
    self.ns = ns
    local libraries = {
        ["LibSharedMedia-3.0"] = { Fetch = function() return nil end },
        ["AceDB-3.0"] = { New = function(_, _, defaults)
            local db = Copy(defaults)
            db.RegisterCallback = noop
            return db
        end },
    }
    SetGlobal("LibStub", setmetatable({ NewLibrary = function(_, name)
        libraries[name] = {}
        return libraries[name]
    end }, { __call = function(_, name) return assert(libraries[name], "Unexpected library: " .. name) end }))
    SetGlobal("GetTime", function() return self.now end)
    SetGlobal("UnitName", function() return "TestPlayer" end)
    SetGlobal("CreateFrame", function(_, name, parent) return self:CreateWidget(parent, true, name) end)
    SetGlobal("UIParent", self:CreateWidget(nil, true, "UIParent"))
    SetGlobal("InCombatLockdown", function() return self.inCombat or false end)
    SetGlobal("PlaySoundFile", noop)
    SetGlobal("geterrorhandler", function() return function(err) error(err) end end)
    SetGlobal("wipe", function(t) for key in pairs(t) do t[key] = nil end; return t end)
    SetGlobal("C_CurrencyInfo", { GetCoinTextureString = tostring })
    SetGlobal("C_Item", { GetItemCount = function() return 3 end })
    SetGlobal("STANDARD_TEXT_FONT", "Fonts\\FRIZQT__.TTF")
    SetGlobal("IsShiftKeyDown", function() return false end)
    SetGlobal("ChatFrame_OpenChat", noop)
    SetGlobal("GameTooltip", { SetOwner = noop, SetHyperlink = noop, Show = noop, Hide = noop })
    SetGlobal("ITEM_QUALITY_COLORS", { [4] = { r = 0.64, g = 0.21, b = 0.93 } })

    function ns.Addon.ScheduleTimer(_, callback, delay)
        local timer = { id = #self.timers + 1, callback = callback, due = self.now + delay }
        self.timers[#self.timers + 1] = timer
        return timer
    end
    function ns.Addon.CancelTimer(_, timer) if timer then timer.cancelled = true end end
    function ns.Addon.RegisterEvent(_, event, callback) self.events[event] = callback end
    function ns.Addon.UnregisterEvent(_, event) self.events[event] = nil end

    local ok, err = pcall(function()
        libraryChunk()
        animationsChunk()
        self.lib = libraries.LibAnimate
        assert(loadfile("DragonToast/Core/Config.lua"))("DragonToast", ns)
        ns.InitializeDB(ns.Addon)
        Merge(ns.Addon.db.profile, overrides)
        for _, path in ipairs({ "Core/QueueUtils", "Display/ToastFrame", "Display/ToastAnimations",
            "Display/ToastManager" }) do
            assert(loadfile("DragonToast/" .. path .. ".lua"))("DragonToast", ns)
        end
        ns.ToastManager.Initialize()
    end)
    if not ok then
        for name, entry in pairs(self.savedGlobals) do rawset(_G, name, entry.value) end
        error(err)
    end
    return self
end

return M
