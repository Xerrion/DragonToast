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
    end)

    it("trims and lowercases commands with surrounding whitespace", function()
        ns.HandleSlashCommand("   CLEAR   ")

        assert.is_true(clearCalled)
        assert.equal("All toasts cleared.", printedMessage)
    end)
end)
