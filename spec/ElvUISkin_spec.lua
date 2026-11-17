describe("ElvUI toast appearance integration", function()
    local savedElvUI, ns

    before_each(function()
        savedElvUI = rawget(_G, "ElvUI")
        rawset(_G, "ElvUI", { { media = {
            normFont = "ElvUI font", bordercolor = { 0.15, 0.25, 0.35, 0.9 },
        } } })
        ns = {
            ElvUISkin = {}, DebugPrint = function() end,
            Addon = { db = { profile = {
                elvui = { useSkin = true },
                appearance = { qualityBorder = false, fontSize = 17, secondaryFontSize = 13, fontOutline = "" },
            } } },
        }
        assert(loadfile("DragonToast/Display/ElvUISkin.lua"))("DragonToast", ns)
        ns.ElvUISkin.Apply()
    end)

    after_each(function()
        rawset(_G, "ElvUI", savedElvUI)
    end)

    local function frame()
        local result = {
            SetBackdropBorderColor = function() error("Root frame has no visible border") end,
            SetBackdropColor = function() error("ElvUI must preserve the configured background") end,
        }
        for _, name in ipairs({ "borderFrame", "iconFrame" }) do
            result[name] = {
                color = { 0.8, 0.4, 0.1, 0.6 },
                SetBackdropBorderColor = function(self, ...) self.color = { ... } end,
            }
        end
        for _, name in ipairs({ "itemName", "quantity", "itemLevel", "itemType", "looter" }) do
            result[name] = { SetFont = function(self, ...) self.font = { ... } end }
        end
        return result
    end

    it("applies ElvUI color to the visible border while respecting typography sizes and background", function()
        local toast = frame()
        ns.ElvUISkin.SkinToast(toast)
        assert.are.same({ 0.15, 0.25, 0.35, 0.9 }, toast.borderFrame.color)
        assert.are.same(toast.borderFrame.color, toast.iconFrame.color)
        assert.are.same({ "ElvUI font", 17, "" }, toast.itemName.font)
        assert.are.same({ "ElvUI font", 13, "" }, toast.itemType.font)
    end)

    it("preserves quality borders and leaves native appearance untouched when matching is disabled", function()
        local toast = frame()
        ns.Addon.db.profile.appearance.qualityBorder = true
        ns.ElvUISkin.SkinToast(toast)
        assert.are.same({ 0.8, 0.4, 0.1, 0.6 }, toast.borderFrame.color)
        assert.are.same(toast.borderFrame.color, toast.iconFrame.color)

        toast = frame()
        ns.Addon.db.profile.appearance.qualityBorder = false
        ns.Addon.db.profile.elvui.useSkin = false
        ns.ElvUISkin.SkinToast(toast)
        assert.are.same({ 0.8, 0.4, 0.1, 0.6 }, toast.borderFrame.color)
        assert.is_nil(toast.itemName.font)
    end)
end)
