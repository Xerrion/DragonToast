-------------------------------------------------------------------------------
-- ListenerUtils_spec.lua
-- Unit tests for capture-order parsing helpers
-------------------------------------------------------------------------------

local function LoadListenerUtils()
    -- luacheck: push ignore 121
    GOLD_AMOUNT = "%dg"
    SILVER_AMOUNT = "%ds"
    COPPER_AMOUNT = "%dc"
    GOLD_AMOUNT_TEXTURE = "%d|Tgold|t"
    SILVER_AMOUNT_TEXTURE = "%d|Tsilver|t"
    COPPER_AMOUNT_TEXTURE = "%d|Tcopper|t"
    -- luacheck: pop

    local ns = {
        ListenerUtils = {},
    }

    local chunk, err = loadfile("Core/ListenerUtils.lua")
    if not chunk then
        error("Failed to load Core/ListenerUtils.lua: " .. (err or "unknown error"))
    end

    chunk("DragonToast", ns)
    return ns.ListenerUtils
end

local function RemapCaptures(captures, captureOrder)
    local capturedValues = {}

    for index, placeholderIndex in ipairs(captureOrder) do
        capturedValues[placeholderIndex] = captures[index]
    end

    return capturedValues
end

describe("ListenerUtils.BuildCapturePattern", function()
    local Utils

    setup(function()
        Utils = LoadListenerUtils()
    end)

    it("uses 1-based indexes for non-positional placeholders", function()
        local pattern, captureOrder = Utils.BuildCapturePattern("Reputation with %s increased by %d.", true)
        local captures = { string.match("Reputation with The Sha'tar increased by 250.", pattern) }
        local capturedValues = RemapCaptures(captures, captureOrder)

        assert.same({ 1, 2 }, captureOrder)
        assert.equal("The Sha'tar", capturedValues[1])
        assert.equal("250", capturedValues[2])
    end)

    it("preserves positional placeholder order for localized strings", function()
        local pattern, captureOrder = Utils.BuildCapturePattern("%2$d reputation with %1$s.", true)
        local captures = { string.match("250 reputation with The Sha'tar.", pattern) }
        local capturedValues = RemapCaptures(captures, captureOrder)

        assert.same({ 2, 1 }, captureOrder)
        assert.equal("The Sha'tar", capturedValues[1])
        assert.equal("250", capturedValues[2])
    end)
end)
