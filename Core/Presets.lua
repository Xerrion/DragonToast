-------------------------------------------------------------------------------
-- Presets.lua
-- Built-in skin presets for quick appearance customization
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------
local _, ns = ...

-------------------------------------------------------------------------------
-- Preset definitions
-- Each preset contains curated values for appearance fields. Fields not
-- specified in a preset will remain at their current value when applied.
-------------------------------------------------------------------------------
ns.Presets = {}

--- Ordered list of preset keys (controls dropdown display order)
ns.Presets.order = { "default", "minimal", "classic", "dark" }

--- Human-readable names for each preset
ns.Presets.names = {
    default = "Default",
    minimal = "Minimal",
    classic = "Classic",
    dark    = "Dark",
}

--- Preset appearance values. Each key maps to a table of appearance fields
--- that will be copied into db.profile.appearance when the preset is applied.
ns.Presets.data = {
    default = {
        fontSize          = 12,
        secondaryFontSize = 10,
        fontFace          = "Friz Quadrata TT",
        fontOutline       = "OUTLINE",
        backgroundAlpha   = 0.7,
        backgroundColor   = { r = 0.05, g = 0.05, b = 0.05 },
        backgroundTexture = "Solid",
        qualityBorder     = true,
        qualityGlow       = true,
        iconSize          = 36,
        borderSize        = 1,
        borderInset       = 0,
        borderTexture     = "None",
        glowWidth         = 4,
        statusBarTexture  = "Blizzard",
    },
    minimal = {
        fontSize          = 11,
        secondaryFontSize = 9,
        fontFace          = "Friz Quadrata TT",
        fontOutline       = "OUTLINE",
        backgroundAlpha   = 0.5,
        backgroundColor   = { r = 0, g = 0, b = 0 },
        backgroundTexture = "Solid",
        qualityBorder     = false,
        qualityGlow       = false,
        iconSize          = 32,
        borderSize        = 0,
        borderInset       = 0,
        borderTexture     = "None",
        glowWidth         = 0,
        statusBarTexture  = "Blizzard",
    },
    classic = {
        fontSize          = 13,
        secondaryFontSize = 11,
        fontFace          = "Friz Quadrata TT",
        fontOutline       = "OUTLINE",
        backgroundAlpha   = 0.85,
        backgroundColor   = { r = 0.1, g = 0.08, b = 0.05 },
        backgroundTexture = "Solid",
        qualityBorder     = true,
        qualityGlow       = true,
        iconSize          = 40,
        borderSize        = 2,
        borderInset       = 1,
        borderTexture     = "Blizzard Dialog",
        glowWidth         = 5,
        statusBarTexture  = "Blizzard",
    },
    dark = {
        fontSize          = 12,
        secondaryFontSize = 10,
        fontFace          = "Friz Quadrata TT",
        fontOutline       = "OUTLINE",
        backgroundAlpha   = 0.92,
        backgroundColor   = { r = 0, g = 0, b = 0 },
        backgroundTexture = "Solid",
        qualityBorder     = true,
        qualityGlow       = true,
        iconSize          = 36,
        borderSize        = 1,
        borderInset       = 0,
        borderTexture     = "None",
        glowWidth         = 6,
        statusBarTexture  = "Blizzard",
    },
}

-------------------------------------------------------------------------------
-- ApplyPreset
-- Copies all appearance values from the named preset into the active profile.
-- @param presetKey string - key from ns.Presets.data
-- @return boolean - true if the preset was applied successfully
-------------------------------------------------------------------------------
function ns.Presets.ApplyPreset(presetKey)
    local preset = ns.Presets.data[presetKey]
    if not preset then return false end

    local appearance = ns.Addon.db.profile.appearance
    for key, value in pairs(preset) do
        if key == "backgroundColor" then
            appearance.backgroundColor.r = value.r
            appearance.backgroundColor.g = value.g
            appearance.backgroundColor.b = value.b
        else
            appearance[key] = value
        end
    end

    if ns.ToastManager and ns.ToastManager.UpdateLayout then
        ns.ToastManager.UpdateLayout()
    end

    return true
end

-------------------------------------------------------------------------------
-- DetectPreset
-- Checks if the current appearance settings match a known preset.
-- @return string - preset key if matched, or nil if custom
-------------------------------------------------------------------------------
function ns.Presets.DetectPreset()
    local appearance = ns.Addon.db.profile.appearance

    for _, presetKey in ipairs(ns.Presets.order) do
        local preset = ns.Presets.data[presetKey]
        local matches = true
        for key, value in pairs(preset) do
            if key == "backgroundColor" then
                local cur = appearance.backgroundColor
                if math.abs(cur.r - value.r) > 0.01
                    or math.abs(cur.g - value.g) > 0.01
                    or math.abs(cur.b - value.b) > 0.01 then
                    matches = false
                    break
                end
            elseif appearance[key] ~= value then
                matches = false
                break
            end
        end
        if matches then return presetKey end
    end

    return nil
end
