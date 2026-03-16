-------------------------------------------------------------------------------
-- wow_mock.lua
-- Lightweight WoW API mock for busted unit tests
-------------------------------------------------------------------------------

local M = {}

-------------------------------------------------------------------------------
-- Mock time (controllable clock)
-------------------------------------------------------------------------------

local mockTime = 0

function M.SetTime(t)
    mockTime = t
end

function M.AdvanceTime(dt)
    mockTime = mockTime + dt
end

-- luacheck: push ignore 121 122

-------------------------------------------------------------------------------
-- Core WoW API mocks
-------------------------------------------------------------------------------

function GetTime()
    return mockTime
end

function InCombatLockdown()
    return M._inCombat or false
end

function PlaySoundFile() end

function UnitName()
    return "TestPlayer"
end

function GetCoinTextureString(copper)
    return tostring(copper) .. "c"
end

-------------------------------------------------------------------------------
-- Frame mock
-------------------------------------------------------------------------------

local function CreateMockFrame()
    local frame = {
        _points = {},
        _shown = false,
        _size = { w = 0, h = 0 },
        _scripts = {},
        lootData = nil,
    }

    function frame:SetPoint(point, relativeTo, relativePoint, x, y)
        self._points = { point = point, relativeTo = relativeTo, relativePoint = relativePoint, x = x, y = y }
    end

    function frame:ClearAllPoints()
        self._points = {}
    end

    function frame:GetPoint()
        local p = self._points
        return p.point, p.relativeTo, p.relativePoint, p.x or 0, p.y or 0
    end

    function frame:Show()
        self._shown = true
    end

    function frame:Hide()
        self._shown = false
    end

    function frame:IsShown()
        return self._shown
    end

    function frame:SetSize(w, h)
        self._size = { w = w, h = h }
    end

    function frame:GetWidth()
        return self._size.w
    end

    function frame:GetHeight()
        return self._size.h
    end

    function frame.SetMovable(_) end
    function frame.SetClampedToScreen(_) end
    function frame.EnableMouse(_) end
    function frame.StartMoving(_) end
    function frame.StopMovingOrSizing(_) end
    function frame.SetFrameStrata(_) end

    function frame.CreateTexture(_)
        return {
            SetAllPoints = function() end,
            SetColorTexture = function() end,
        }
    end

    function frame.CreateFontString(_)
        return {
            SetPoint = function() end,
            SetText = function() end,
        }
    end

    function frame:SetScript(event, handler)
        self._scripts[event] = handler
    end

    return frame
end

function CreateFrame()
    return CreateMockFrame()
end

UIParent = CreateMockFrame()

-------------------------------------------------------------------------------
-- LibStub mock
-------------------------------------------------------------------------------

function LibStub()
    return {
        Fetch = function() return nil end,
    }
end

-------------------------------------------------------------------------------
-- Lua globals WoW adds
-------------------------------------------------------------------------------

function wipe(t)
    for k in pairs(t) do
        t[k] = nil
    end
    return t
end

-- luacheck: pop

-------------------------------------------------------------------------------
-- Namespace builder
-------------------------------------------------------------------------------

function M.CreateNamespace()
    local ns = {}

    -- Color constants
    ns.COLOR_GOLD = "|cffffd700"
    ns.COLOR_GREEN = "|cff00ff00"
    ns.COLOR_RED = "|cffff0000"
    ns.COLOR_GRAY = "|cff888888"
    ns.COLOR_WHITE = "|cffffffff"
    ns.COLOR_RESET = "|r"

    -- Utility functions
    function ns.Print() end
    function ns.DebugPrint() end
    function ns.FormatNumber(num)
        if num >= 1000000 then
            return string.format("%.1fM", num / 1000000)
        elseif num >= 1000 then
            return string.format("%.1fK", num / 1000)
        end
        return tostring(num)
    end

    -- Initialize sub-tables
    ns.QueueUtils = {}
    ns.ToastManager = {}
    ns.TestToasts = {}

    -- Mock ToastFrame
    ns.ToastFrame = {
        Acquire = function()
            return CreateMockFrame()
        end,
        Populate = function(frame, lootData)
            frame.lootData = lootData
        end,
        Release = function(frame)
            frame.lootData = nil
        end,
    }

    -- Mock ToastAnimations
    ns.ToastAnimations = {
        PlayLifecycle = function() end,
        UpdateLifecycle = function() end,
        PlaySlide = function() end,
        StopAll = function() end,
        Dismiss = function() end,
    }

    -- Mock MessageBridge
    ns.MessageBridge = {
        IsSuppressed = function() return M._suppressed or false end,
    }

    -- Mock HonorListener
    ns.HonorListener = {
        GetHonorIcon = function() return 463450 end,
    }

    ns.ReputationListener = {
        GetReputationIcon = function() return 134400 end,
    }

    -- Mock Addon (Ace3 mixin)
    ns.Addon = {
        db = {
            profile = {
                enabled = true,
                display = {
                    maxToasts = 5,
                    toastWidth = 300,
                    toastHeight = 40,
                    growDirection = "UP",
                    anchorPoint = "RIGHT",
                    anchorX = -20,
                    anchorY = 0,
                    spacing = 4,
                    showQuantity = true,
                },
                filters = {
                    minQuality = 0,
                    showSelfLoot = true,
                    showGroupLoot = true,
                    showCurrency = true,
                    showGold = true,
                    showQuestItems = true,
                    showXP = true,
                    showHonor = true,
                    showMail = true,
                    showReputation = true,
                },
                combat = {
                    deferInCombat = false,
                },
                sound = {
                    enabled = false,
                    soundFile = "None",
                },
                animation = {
                    enableAnimations = true,
                    holdDuration = 4,
                },
                appearance = {
                    iconSize = 32,
                },
                elvui = {
                    useSkin = false,
                },
                minimap = {
                    hide = false,
                },
            },
        },
        ScheduleRepeatingTimer = function() return {} end,
        ScheduleTimer = function(_, func, _)
            -- In tests, execute immediately (no real timer)
            if func then func() end
            return {}
        end,
        CancelTimer = function() end,
        RegisterEvent = function() end,
    }

    -- Mock AceLocale (identity passthrough: L["key"] returns "key")
    -- Format-string keys need explicit values so string.format() works in tests.
    ns.L = setmetatable({
        FORMAT_PLUS_XP = "+%s XP",
        FORMAT_PLUS_HONOR = "+%s Honor",
        FORMAT_PLUS_REPUTATION = "+%s Reputation",
        FORMAT_ILVL = "ilvl %s",
        FORMAT_MAIL_FROM = "Mail - %s",
        CONFIRM_DELETE_PROFILE = "Are you sure you want to delete the profile \"%s\"?",
    }, {
        __index = function(_, key)
            return key
        end,
    })

    return ns
end

-------------------------------------------------------------------------------
-- Module loader
-------------------------------------------------------------------------------

function M.LoadToastManager(ns)
    -- Load QueueUtils dependency first
    local queuePath = "DragonToast/Core/QueueUtils.lua"
    local queueChunk, queueErr = loadfile(queuePath)
    if not queueChunk then
        error("Failed to load " .. queuePath .. ": " .. (queueErr or "unknown error"))
    end
    queueChunk("DragonToast", ns)

    local path = "DragonToast/Display/ToastManager.lua"
    local chunk, err = loadfile(path)
    if not chunk then
        error("Failed to load " .. path .. ": " .. (err or "unknown error"))
    end
    -- Call with the addon name and namespace as varargs
    chunk("DragonToast", ns)
    return ns.ToastManager
end

-------------------------------------------------------------------------------
-- Reset helpers
-------------------------------------------------------------------------------

function M.Reset(ns)
    mockTime = 0
    M._inCombat = false
    M._suppressed = false

    -- Clear active toasts
    local t = ns.ToastManager._test
    if t then
        wipe(t.activeToasts)
        t.QueueReset(t.toastQueue)
        t.QueueReset(t.combatQueue)
    end
end

return M
