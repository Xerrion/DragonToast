local function loadModule(path, ns)
    assert(loadfile(path))("DragonToast", ns)
end

local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, item in pairs(value) do result[key] = copy(item) end
    return result
end

describe("Modern toast theme", function()
    local saved, L
    before_each(function()
        saved = {}
        for _, key in ipairs({ "LibStub", "ChatFontSmall", "STANDARD_TEXT_FONT" }) do
            saved[key] = rawget(_G, key)
        end
        L = setmetatable({}, { __index = function(_, key) return key end })
    end)
    after_each(function()
        for _, key in ipairs({ "LibStub", "ChatFontSmall", "STANDARD_TEXT_FONT" }) do
            rawset(_G, key, saved[key])
        end
    end)

    local function registerMedia()
        local registered = {}
        rawset(_G, "LibStub", function()
            return { Register = function(_, kind, name, path, mask)
                registered[kind] = registered[kind] or {}
                registered[kind][name] = { path = path, mask = mask }
            end }
        end)
        loadModule("DragonToast/Core/Media.lua", {})
        return registered
    end

    it("registers the locale's UI font with a language mask accepted on non-Western clients", function()
        for _, path in ipairs({
            [[Fonts\2002.TTF]], [[Fonts\FRIZQT___CYR.TTF]], [[Fonts\ARKai_T.ttf]], [[Fonts\bLEI00D.ttf]],
        }) do
            rawset(_G, "ChatFontSmall", { GetFont = function() return path, 12, "" end })
            local media = registerMedia()
            assert.are.equal(path, media.font["Dragon UI"].path)
            -- LSM's registration requires koKR/ruRU/zhCN/zhTW bits 1/2/4/8;
            -- 255 also includes its Western bit 128. Omitting it rejects the font.
            assert.are.equal(255, media.font["Dragon UI"].mask)
            for _, kind in ipairs({ "background", "border", "statusbar" }) do
                assert.are.equal([[Interface\Buttons\WHITE8x8]], media[kind]["Dragon UI Flat"].path)
            end
            assert.are.equal([[Interface\AddOns\DragonToast\Sounds\DragonToast.ogg]],
                media.sound["Dragon Toast"].path)
        end
    end)

    it("falls back to the standard client font before the historical font path", function()
        rawset(_G, "ChatFontSmall", nil)
        rawset(_G, "STANDARD_TEXT_FONT", [[Fonts\LocaleFallback.ttf]])
        assert.are.equal([[Fonts\LocaleFallback.ttf]], registerMedia().font["Dragon UI"].path)
        rawset(_G, "STANDARD_TEXT_FONT", nil)
        assert.are.equal([[Fonts\FRIZQT__.TTF]], registerMedia().font["Dragon UI"].path)
    end)

    local function loadPresets(profile)
        local refreshes = 0
        local ns = {
            L = L, Addon = { db = { profile = profile } },
            ToastManager = { UpdateLayout = function() refreshes = refreshes + 1 end },
        }
        rawset(_G, "LibStub", function() return { GetLocale = function() return L end } end)
        loadModule("DragonToast/Core/Presets.lua", ns)
        return ns, function() return refreshes end
    end

    it("provides modern defaults without migrating explicitly customized saved values", function()
        local profile = {
            schemaVersion = 11,
            appearance = { fontFace = "Custom font", fontOutline = "OUTLINE", backgroundAlpha = 0.4,
                backgroundColor = { r = 0.1, g = 0.2, b = 0.3 }, qualityBorder = true,
                qualityGlow = true, borderColor = { r = 0.8, g = 0.2, b = 0.1 }, borderAlpha = 0 },
            display = { toastWidth = 475, anchorPoint = "CENTER", anchorX = 45, anchorY = -70 },
            filters = { minQuality = 3 }, animation = { holdDuration = 9 }, elvui = { useSkin = true },
        }
        local original, defaults = copy(profile)
        local db = { profile = profile, RegisterCallback = function() end }
        rawset(_G, "LibStub", function()
            return { New = function(_, _, values) defaults = values; return db end }
        end)
        local ns = {}
        loadModule("DragonToast/Core/Config.lua", ns)
        ns.InitializeDB({})
        assert.are.same(original, profile)
        assert.are.equal("Dragon UI", defaults.profile.appearance.fontFace)
        assert.are.equal("", defaults.profile.appearance.fontOutline)
        assert.are.same({ r = 0.035, g = 0.047, b = 0.065 }, defaults.profile.appearance.backgroundColor)
        assert.are.same({ r = 0.22, g = 0.28, b = 0.35 }, defaults.profile.appearance.borderColor)
        assert.are.equal(0.98, defaults.profile.appearance.backgroundAlpha)
        assert.are.equal(1, defaults.profile.appearance.borderAlpha)
        assert.is_false(defaults.profile.appearance.qualityGlow)
        assert.is_false(defaults.profile.appearance.qualityBorder)
        assert.is_false(defaults.profile.elvui.useSkin)
        local presetNS = loadPresets(copy(defaults.profile))
        assert.are.equal("default", presetNS.Presets.DetectPreset())
    end)

    it("applies Modern explicitly without changing layout, behavior, or ElvUI preference", function()
        local profile = {
            appearance = { iconSize = 52, fontSize = 19, secondaryFontSize = 13,
                borderSize = 9, backgroundColor = {}, borderColor = {} },
            display = { toastWidth = 490, toastHeight = 70, textPaddingV = 12,
                anchorPoint = "TOP", anchorX = -22, anchorY = -55 },
            filters = { showGold = false }, animation = { holdDuration = 12 }, elvui = { useSkin = true },
        }
        local oldDisplay, oldFilters = copy(profile.display), copy(profile.filters)
        local oldAnimation = copy(profile.animation)
        local ns, refreshes = loadPresets(profile)
        assert.are.equal("Modern (Default)", ns.Presets.names.default)
        assert.is_true(ns.Presets.ApplyPreset("default"))
        assert.are.equal("default", ns.Presets.DetectPreset())
        assert.are.equal(1, refreshes())
        assert.are.equal(52, profile.appearance.iconSize)
        assert.are.equal(19, profile.appearance.fontSize)
        assert.are.equal(13, profile.appearance.secondaryFontSize)
        assert.are.same(oldDisplay, profile.display)
        assert.are.same(oldFilters, profile.filters)
        assert.are.same(oldAnimation, profile.animation)
        assert.is_true(profile.elvui.useSkin)
        assert.are.equal(1, profile.appearance.borderSize)
        assert.are.equal(0.2, profile.appearance.glowAlpha)
        assert.are.equal("Dragon UI Flat", profile.appearance.borderTexture)
        assert.is_false(rawequal(profile.appearance.borderColor, ns.Presets.data.default.borderColor))
        assert.is_false(rawequal(profile.appearance.backgroundColor, ns.Presets.data.default.backgroundColor))
        profile.appearance.borderColor.r = 0.9
        assert.are.equal(0.22, ns.Presets.data.default.borderColor.r)
        assert.is_nil(ns.Presets.DetectPreset())
        ns.Presets.ApplyPreset("default")
        assert.are.equal(0.22, profile.appearance.borderColor.r)
    end)

    it("labels unmatched settings Custom instead of presenting them as Modern", function()
        local dt = loadPresets({ appearance = { fontFace = "My font" }, elvui = { useSkin = false } })
        local controls = {}
        local W = setmetatable({}, { __index = function()
            return function(_, options)
                local control = { options = options, GetHeight = function() return 24 end,
                    SetDisabled = function() end }
                controls[#controls + 1] = control
                return control
            end
        end })
        local ns = {
            dtns = dt, Tabs = {}, L = L,
            DW = { Widgets = W, LayoutConstants = {
                AnchorWidget = function() end, PADDING_TOP = 0, PADDING_BOTTOM = 0,
                SPACING_AFTER_HEADER = 0, SPACING_BETWEEN_WIDGETS = 0, SPACING_BETWEEN_SECTIONS = 0,
            } },
        }
        loadModule("DragonToast_Options/Tabs/AppearanceTab.lua", ns)
        ns.Tabs[1].createFunc({ SetHeight = function() end })
        for _, control in ipairs(controls) do
            local opts = control.options
            if type(opts) == "table" and opts.label == "Skin Preset" then
                assert.are.equal("custom", opts.get())
                assert.are.same({ value = "custom", text = "Custom" }, opts.values()[1])
                opts.set("custom")
                assert.are.equal("My font", dt.Addon.db.profile.appearance.fontFace)
                return
            end
        end
        error("Missing preset selector")
    end)
end)
