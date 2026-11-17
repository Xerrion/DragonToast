local function loadOptions(file, ns)
    assert(loadfile("DragonToast_Options/" .. file))("DragonToast_Options", ns)
end

local function frame()
    local result = { _scripts = {}, _height = 24 }
    function result:SetPoint() end
    function result:SetFont() end
    function result:SetTextColor() end
    function result:EnableMouse() end
    function result:SetText(value) self.text = value end
    function result:SetDisabled(value) self.disabled = value end
    function result:SetHeight(value) self._height = value end
    function result:GetHeight() return self._height end
    function result:SetScript(event, callback) self._scripts[event] = callback end
    function result:CreateFontString() return frame() end
    return result
end

describe("Options live preview", function()
    local saved, ns, dw, dt, callbacks, controls, refreshCount, previewCalls

    before_each(function()
        saved = {}
        for _, key in ipairs({
            "DragonWidgetsNS", "DragonToastNS", "DragonToast_Options", "LibStub", "CreateFrame", "StaticPopupDialogs",
        }) do
            saved[key] = rawget(_G, key)
        end
        callbacks, controls, previewCalls = {}, {}, {}
        refreshCount = 0
        local L = setmetatable({}, { __index = function(_, key) return key end })
        dt = {
            L = L,
            Addon = { db = {
                profile = { appearance = {} },
                RegisterCallback = function(_, event, callback) callbacks[event] = callback end,
            } },
            ToastManager = { UpdateLayout = function() end },
            ToastFrame = { CreatePreview = function()
                return {
                    Refresh = function(_, sample) previewCalls[#previewCalls + 1] = sample end,
                    OnHide = function() previewCalls.hidden = true end,
                }
            end },
        }
        dw = {
            On = function() end,
            Widgets = {},
            WidgetConstants = {
                FONT_PATH = "font", FONT_SIZE = 12, FONT_SIZE_SMALL = 11,
                TEXT_COLOR = { 1, 1, 1 }, GRAY_COLOR = { 0.6, 0.6, 0.6 },
            },
            LayoutConstants = {
                PADDING_TOP = -10, PADDING_BOTTOM = 20,
                SPACING_AFTER_HEADER = 8, SPACING_BETWEEN_WIDGETS = 6, SPACING_BETWEEN_SECTIONS = 16,
                AnchorWidget = function() end,
            },
        }
        for _, kind in ipairs({
            "Button", "Header", "Dropdown", "Slider", "ColorPicker", "Toggle", "TextInput", "Description",
        }) do
            dw.Widgets["Create" .. kind] = function(_, opts)
                local widget = frame()
                widget.options = opts
                function widget:Refresh()
                    if type(opts) == "table" and opts.get then self.value = opts.get() end
                end
                controls[#controls + 1] = widget
                return widget
            end
        end
        dw.CreateOptionsPanel = function(config)
            dw.config = config
            assert.is_function(callbacks.OnProfileChanged)
            assert.is_function(callbacks.OnProfileReset)
            return {
                Open = function() end, Close = function() end, Toggle = function() end,
                RefreshVisibleWidgets = function() refreshCount = refreshCount + 1 end,
                RefreshPreview = function() end,
            }
        end
        rawset(_G, "DragonWidgetsNS", dw)
        rawset(_G, "DragonToastNS", dt)
        rawset(_G, "CreateFrame", frame)
        rawset(_G, "StaticPopupDialogs", {})
        rawset(_G, "LibStub", function()
            return { GetLocale = function() return L end }
        end)
        ns = {}
        loadOptions("Core.lua", ns)
        loadOptions("Preview.lua", ns)
    end)

    after_each(function()
        for _, key in ipairs({
            "DragonWidgetsNS", "DragonToastNS", "DragonToast_Options", "LibStub", "CreateFrame", "StaticPopupDialogs",
        }) do
            rawset(_G, key, saved[key])
        end
    end)

    it("refreshes profile changes before the Profiles tab is ever created", function()
        _G.DragonToast_Options.Open()
        assert.are.equal(ns.CreatePreview, dw.config.preview.createFunc)
        assert.are.equal(0, #ns.Tabs)
        for _, event in ipairs({
            "OnProfileChanged", "OnProfileCopied", "OnProfileReset", "OnNewProfile", "OnProfileDeleted",
        }) do
            callbacks[event]()
        end
        assert.are.equal(5, refreshCount)
    end)

    it("changes preview samples locally and delegates hiding to the isolated renderer", function()
        ns.dtns = dt
        local preview = ns.CreatePreview(frame())
        preview:Refresh()
        assert.are.equal(4, previewCalls[1].itemQuality)
        assert.are.equal("Example item", previewCalls[1].itemName)
        local rarity, sample = controls[1], controls[2]
        rarity.options.onClick()
        assert.are.equal(1, #previewCalls)
        preview:Refresh() -- Shared widget event schedules the redraw.
        assert.are.equal(5, previewCalls[2].itemQuality)
        sample.options.onClick()
        assert.are.equal(2, #previewCalls)
        preview:Refresh()
        assert.is_true(previewCalls[3].isCurrency)
        assert.is_true(rarity.disabled)
        assert.are.same({ appearance = {} }, dt.Addon.db.profile)
        preview:OnHide()
        assert.is_true(previewCalls.hidden)
    end)

    it("passes the selected preset key to the real preset function and refreshes controls", function()
        ns.dtns = dt
        ns.RefreshVisibleWidgets = function() refreshCount = refreshCount + 1 end
        assert(loadfile("DragonToast/Core/Presets.lua"))("DragonToast", dt)
        loadOptions("Tabs/AppearanceTab.lua", ns)
        ns.Tabs[1].createFunc(frame())
        local preset
        for _, control in ipairs(controls) do
            if type(control.options) == "table" and control.options.label == "Skin Preset" then
                preset = control.options
                break
            end
        end
        assert.is_table(preset)
        preset.set("dark")
        assert.are.equal("dark", dt.Presets.DetectPreset())
        assert.are.equal(1, refreshCount)
    end)

    it("keeps the pending profile name visible through silent refreshes before creation", function()
        ns.dtns = dt
        local createdName
        dt.Addon.db.SetProfile = function(_, name) createdName = name end
        dt.Addon.db.GetCurrentProfile = function() return "Default" end
        ns.RefreshVisibleWidgets = function()
            for _, control in ipairs(controls) do control:Refresh() end
        end
        loadOptions("Tabs/ProfilesTab.lua", ns)
        ns.Tabs[1].createFunc(frame())
        local input, createButton, active
        for _, control in ipairs(controls) do
            local opts = control.options
            if type(opts) == "table" then
                if opts.label == "New Profile Name" then input = control end
                if opts.label == "Active Profile" then active = control end
                if opts.text == "Create Profile" then createButton = control end
            end
        end
        assert.is_true(active._layoutFullWidth)
        input.options.set("My new profile")
        ns.RefreshVisibleWidgets()
        assert.are.equal("My new profile", input.value)

        createButton.options.onClick()
        assert.are.equal("My new profile", createdName)
        assert.are.equal("", input.value)
    end)
end)
