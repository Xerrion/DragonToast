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

local function anchor(widget, parent, yOffset)
    parent.anchored = parent.anchored or {}
    parent.anchored[#parent.anchored + 1] = widget
    widget.anchorParent = parent
    return yOffset - widget:GetHeight()
end

describe("Options live preview", function()
    local saved, ns, dw, dt, callbacks, controls, refreshCount, previewCalls, appearanceChanges

    before_each(function()
        saved = {}
        for _, key in ipairs({
            "DragonWidgetsNS", "DragonToastNS", "DragonToast_Options", "LibStub", "CreateFrame", "StaticPopupDialogs",
        }) do
            saved[key] = rawget(_G, key)
        end
        callbacks, controls, previewCalls = {}, {}, {}
        refreshCount, appearanceChanges = 0, 0
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
                SECTION_PADDING_TOP = 8, SECTION_PADDING_BOTTOM = 12,
                SPACING_BETWEEN_WIDGETS = 6, SPACING_BETWEEN_SECTIONS = 16,
                AnchorWidget = anchor, AnchorSection = anchor,
                NotifyAppearanceChange = function() appearanceChanges = appearanceChanges + 1 end,
            },
        }
        dw.Widgets.CreateSection = function(_, title)
            local section = frame()
            section.title = title
            section.content = frame()
            function section:SetContentHeight(height)
                self:SetHeight(height)
            end
            return section
        end
        for _, kind in ipairs({
            "Button", "Header", "Dropdown", "Slider", "ColorPicker", "Toggle", "TextInput", "Description",
        }) do
            dw.Widgets["Create" .. kind] = function(parent, opts)
                local widget = frame()
                widget.parent = parent
                widget.options = opts
                function widget:GetValue()
                    return type(opts) == "table" and opts.get and opts.get() or self.value
                end
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

    local function findControl(label)
        for _, control in ipairs(controls) do
            local opts = control.options
            if type(opts) == "table" and (opts.label == label or opts.text == label) then return control end
        end
        error("Missing option: " .. label)
    end

    local function buildTab(name)
        ns.dtns = dt
        loadOptions("Tabs/" .. name .. "Tab.lua", ns)
        local tab = ns.Tabs[#ns.Tabs]
        tab.createFunc(frame())
        return tab
    end

    it("refreshes profile changes before the Profiles tab is ever created", function()
        _G.DragonToast_Options.Open()
        assert.is_nil(dw.config.width)
        assert.is_nil(dw.config.height)
        assert.is_nil(dw.config.navigation)
        assert.is_nil(dw.config.settingsLayout)
        assert.is_nil(dw.config.preview.height)
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
        ns.RefreshVisibleWidgets = function()
            refreshCount = refreshCount + 1
            if ns.Tabs[1] and ns.Tabs[1].refreshFunc then ns.Tabs[1].refreshFunc() end
        end
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
        dt.Addon.db.profile.appearance.borderAlpha = 0.25
        preset.set("minimal")
        assert.is_false(findControl("Border Color").disabled)
        assert.is_true(findControl("Glow Opacity").disabled)
        assert.are.equal(0.25, dt.Addon.db.profile.appearance.borderAlpha)
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

    it("keeps moved content, size, and queue settings bound to their original profile keys", function()
        dt.Addon.db.profile = {
            display = { showIcon = true, showItemLevel = true, showItemType = true, showQuantity = true,
                showItemCount = false, showLooter = true, goldFormat = "icons", queueStagger = 0.1 },
            appearance = { iconSize = 36 }, animation = { enableAnimations = true, attentionAnimation = "none" },
        }
        local contentTab = buildTab("Content")
        assert.are.equal(3, contentTab.order)
        for _, entry in ipairs({
            { "Show Icon", "showIcon" }, { "Show Item Level", "showItemLevel" },
            { "Show Item Type", "showItemType" }, { "Show Quantity", "showQuantity" },
            { "Show Item Count", "showItemCount" }, { "Show Looter", "showLooter" },
        }) do
            local opts = findControl(entry[1]).options
            local value = not opts.get()
            opts.set(value)
            assert.are.equal(value, dt.Addon.db.profile.display[entry[2]])
        end
        findControl("Gold Format").options.set("long")
        assert.are.equal("long", dt.Addon.db.profile.display.goldFormat)

        local layoutTab = buildTab("Display")
        assert.are.equal("display", layoutTab.id)
        assert.are.equal("Layout", layoutTab.label)
        assert.are.equal(2, layoutTab.order)
        findControl("Icon Size").options.set(42)
        assert.are.equal(42, dt.Addon.db.profile.appearance.iconSize)
        local animationTab = buildTab("Animation")
        assert.are.equal(5, animationTab.order)
        findControl("Queue Stagger").options.set(0.3)
        assert.are.equal(0.3, dt.Addon.db.profile.display.queueStagger)
        assert.is_nil(dt.Addon.db.profile.animation.queueStagger)
        assert.is_true(appearanceChanges > 0)
    end)

    it("updates exact anchor coordinates and resets with the manager's dot-call contract", function()
        dt.Addon.db.profile = {
            display = { anchorPoint = "RIGHT", anchorX = -20, anchorY = 0 }, appearance = {},
        }
        local calls = {}
        dt.ToastManager.SetAnchor = function(...) calls[#calls + 1] = { ... } end
        dt.Print = function() end
        ns.RefreshVisibleWidgets = function()
            for _, control in ipairs(controls) do control:Refresh() end
        end
        buildTab("Display")
        findControl("Anchor Point").options.set("CENTER")
        findControl("Horizontal Offset").options.set("-128.5")
        findControl("Vertical Offset").options.set("72")
        assert.are.same({ "CENTER", -128.5, 72 }, calls[#calls])
        assert.are.equal("-128.5", findControl("Horizontal Offset").value)
        for _, invalid in ipairs({ "bad", "", "1e999" }) do
            findControl("Horizontal Offset").options.set(invalid)
        end
        assert.are.equal(3, #calls)
        assert.are.equal(-128.5, dt.Addon.db.profile.display.anchorX)
        findControl("Reset Position").options.onClick()
        assert.are.same({ "RIGHT", -20, 0 }, calls[#calls])
        assert.are.equal("-20", findControl("Horizontal Offset").value)
        assert.are.equal("0", findControl("Vertical Offset").value)
        assert.are.equal(0, #previewCalls)
    end)

    it("refreshes applicable appearance controls after toggles and profile changes", function()
        dt.Addon.db.profile = {
            appearance = { qualityBorder = true, qualityGlow = false }, elvui = { useSkin = true },
        }
        dt.Presets = { order = {}, names = {} }
        local detected = false
        dt.ElvUISkin = { IsElvUI = function() return detected end }
        local tab = buildTab("Appearance")
        assert.are.equal(4, tab.order)
        assert.is_true(findControl("Border Color").disabled)
        assert.is_true(findControl("Border Opacity").disabled)
        assert.is_false(findControl("Quality Border Opacity").disabled)
        assert.is_true(findControl("Glow Opacity").disabled)
        assert.is_true(findControl("Match ElvUI Style").disabled)
        assert.is_false(findControl("Font").disabled)

        findControl("Quality Border").options.set(false)
        findControl("Quality Glow").options.set(true)
        assert.is_false(findControl("Border Color").disabled)
        assert.is_true(findControl("Quality Border Opacity").disabled)
        assert.is_false(findControl("Glow Opacity").disabled)
        findControl("Border Color").options.set(0.2, 0.3, 0.4)
        findControl("Border Opacity").options.set(0)
        findControl("Quality Border Opacity").options.set(0.4)
        findControl("Glow Opacity").options.set(0.2)
        findControl("Icon Crop").options.set(0.1)
        assert.are.same({ r = 0.2, g = 0.3, b = 0.4 }, dt.Addon.db.profile.appearance.borderColor)
        assert.are.equal(0, dt.Addon.db.profile.appearance.borderAlpha)
        assert.are.equal(0.4, dt.Addon.db.profile.appearance.qualityBorderAlpha)
        assert.are.equal(0.2, dt.Addon.db.profile.appearance.glowAlpha)
        assert.are.equal(0.1, dt.Addon.db.profile.appearance.iconCrop)

        -- AceDB replaces profile tables; existing controls must read the new one.
        dt.Addon.db.profile = {
            appearance = { qualityBorder = true, qualityGlow = false, borderAlpha = 0.65,
                backgroundColor = { r = 0, g = 0, b = 0 } },
            elvui = { useSkin = true },
        }
        detected = true
        for _, control in ipairs(controls) do
            if type(control.options) == "table" and control.options.label ~= "Skin Preset" then control:Refresh() end
        end
        tab.refreshFunc()
        assert.are.equal(0.65, findControl("Border Opacity").value)
        assert.is_true(findControl("Border Color").disabled)
        assert.is_false(findControl("Quality Border Opacity").disabled)
        assert.is_true(findControl("Glow Opacity").disabled)
        assert.is_false(findControl("Match ElvUI Style").disabled)
        assert.is_true(findControl("Font").disabled)
        findControl("Match ElvUI Style").options.set(false)
        assert.is_false(findControl("Font").disabled)
        assert.is_false(dt.Addon.db.profile.elvui.useSkin)
    end)


    it("declares a coherent page order while keeping existing navigation ids", function()
        for _, name in ipairs({ "Profiles", "Animation", "General", "Appearance", "Display", "Filters", "Content" }) do
            loadOptions("Tabs/" .. name .. "Tab.lua", ns)
        end
        table.sort(ns.Tabs, function(a, b) return a.order < b.order end)
        local ids = {}
        for _, tab in ipairs(ns.Tabs) do ids[#ids + 1] = tab.id end
        assert.are.same({ "general", "display", "content", "appearance", "animation", "filters", "profiles" }, ids)
    end)

    it("groups each page's controls inside its registered section cards", function()
        ns.dtns = dt
        dt.Addon.db.profile = { appearance = {}, animation = {}, sound = {} }
        local cases = {
            General = { "Core Settings", "Sound", "Testing" },
            Display = { "Toast Size", "Spacing", "Stack", "Position" },
            Content = { "Content" },
            Appearance = { "Preset", "Font", "Background", "Border", "Glow", "Icon", "Integration" },
            Animation = { "Animation", "Entrance", "Attention", "Hold", "Exit", "Stack Timing" },
            Filters = { "Loot Quality", "Loot Sources", "Currency and Rewards" },
            Profiles = { "Current Profile", "Profile Actions" },
        }
        for name, expected in pairs(cases) do
            local page = frame()
            local firstControl = #controls + 1
            loadOptions("Tabs/" .. name .. "Tab.lua", ns)
            ns.Tabs[#ns.Tabs].createFunc(page)

            local titles, containers = {}, {}
            for i, section in ipairs(page.anchored) do
                assert.is_table(section.content)
                assert.is_table(section.content.anchored)
                titles[i] = section.title
                containers[section.content] = true
            end
            assert.are.same(expected, titles)
            for i = firstControl, #controls do
                local widget = controls[i]
                assert.is_true(containers[widget.parent])
                assert.are.equal(widget.parent, widget.anchorParent)
            end
        end
    end)

end)
