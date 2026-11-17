-------------------------------------------------------------------------------
-- SlashCommands_spec.lua
-- Unit tests for slash command normalization
-------------------------------------------------------------------------------

local function LoadSlashCommands(namespace)
    local chunk, err = loadfile("DragonToast/Core/SlashCommands.lua")
    if not chunk then
        error("Failed to load DragonToast/Core/SlashCommands.lua: " .. (err or "unknown error"))
    end

    chunk("DragonToast", namespace)
end

describe("HandleSlashCommand", function()
    local ns
    local clearCalled
    local printedMessage
    local originalPrint

    before_each(function()
        originalPrint = _G.print
        _G.print = function() end

        local localeStub = setmetatable({}, {
            __index = function(_, key) return key end,
        })
        local aceLocaleStub = {
            GetLocale = function(_self, _addonName) return localeStub end,
        }
        _G.LibStub = setmetatable({}, {
            __call = function(_self, _libName) return aceLocaleStub end,
        })

        clearCalled = false
        printedMessage = nil

        ns = {
            COLOR_GOLD = "",
            COLOR_GREEN = "",
            COLOR_RED = "",
            COLOR_WHITE = "",
            COLOR_RESET = "",
            Addon = {
                db = {
                    profile = {
                        enabled = true,
                        filters = {},
                        display = {},
                        animation = {},
                        sound = {},
                        combat = {},
                        elvui = {},
                        minimap = {},
                    },
                },
            },
            ToastManager = {
                ClearAll = function()
                    clearCalled = true
                end,
            },
            TestToasts = {
                IsTestModeActive = function()
                    return false
                end,
            },
            Print = function(message)
                printedMessage = message
            end,
        }

        LoadSlashCommands(ns)
    end)

    after_each(function()
        _G.print = originalPrint
        _G.LibStub = nil
    end)

    it("trims and lowercases commands with surrounding whitespace", function()
        ns.HandleSlashCommand("   CLEAR   ")

        assert.is_true(clearCalled)
        assert.equal("All toasts cleared.", printedMessage)
    end)

    it("routes the default mass loot command", function()
        local called = false
        ns.TestToasts.RunMassLootTest = function(count)
            called = true
            assert.is_nil(count)
        end
        ns.HandleSlashCommand(" MASSLOOT ")
        assert.is_true(called)
    end)

    it("passes the optional mass loot count through for validation", function()
        local count
        ns.TestToasts.RunMassLootTest = function(value) count = value end
        ns.HandleSlashCommand("  MASSLOOT   50  ")
        assert.equal("50", count)
    end)

    it("reports an unavailable mass loot test module", function()
        ns.TestToasts = nil
        ns.HandleSlashCommand("massloot 50")
        assert.equal("TestToasts module is not loaded.", printedMessage)
    end)
end)
