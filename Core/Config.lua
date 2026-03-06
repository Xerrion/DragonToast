-------------------------------------------------------------------------------
-- Config.lua
-- DragonToast configuration: AceDB defaults and profile migration
--
-- Supported versions: TBC Anniversary, Retail, MoP Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

-------------------------------------------------------------------------------
-- Database Defaults
-------------------------------------------------------------------------------

local defaults = {
    profile = {
        enabled = true,
        debug = false,

        filters = {
            minQuality = 0,
            showSelfLoot = true,
            showGroupLoot = true,
            showCurrency = true,
            showGold = true,
            showQuestItems = true,
            showXP = true,
            showHonor = true,
            showReputation = true,
            showMail = true,
        },

        display = {
            maxToasts = 7,
            toastWidth = 350,
            toastHeight = 48,
            growDirection = "UP",
            anchorPoint = "RIGHT",
            anchorX = -20,
            anchorY = 0,
            spacing = 4,
            showItemLevel = true,
            showItemType = true,
            showLooter = true,
            showQuantity = true,
            goldFormat = "icons",
            showIcon = true,
            textPaddingV = 6,
            textPaddingH = 8,
        },

        animation = {
            enableAnimations = true,
            entranceDuration = 0.3,
            exitDuration = 0.5,
            holdDuration = 4.0,

            entranceAnimation = "slideInRight",
            entranceDistance = 300,
            exitAnimation = "fadeOut",
            exitDistance = 300,
            slideSpeed = 0.2,

            attentionAnimation = "none",
            attentionMinQuality = 4,
            attentionRepeatCount = 2,
            attentionDelay = 0.1,
        },

        appearance = {
            fontSize = 12,
            secondaryFontSize = 10,
            fontFace = "Friz Quadrata TT",
            fontOutline = "OUTLINE",
            backgroundAlpha = 0.7,
            backgroundColor = { r = 0.05, g = 0.05, b = 0.05 },
            backgroundTexture = "Solid",
            qualityBorder = true,
            qualityGlow = true,
            iconSize = 36,
            borderSize = 1,
            borderInset = 0,
            borderTexture = "None",
            glowWidth = 4,
            statusBarTexture = "Blizzard",
        },

        sound = {
            enabled = false,
            soundFile = "None",
        },

        combat = {
            deferInCombat = false,
        },

        elvui = {
            useSkin = true,
        },

        minimap = {
            hide = false,
        },
    },
}

-------------------------------------------------------------------------------
-- Profile Migration
-------------------------------------------------------------------------------

local CURRENT_SCHEMA = 6

local DIRECTION_TO_ANIMATION = {
    RIGHT  = "slideInRight",
    LEFT   = "slideInLeft",
    TOP    = "slideInDown",
    BOTTOM = "slideInUp",
}

local function MigrateProfile(db)
    local profile = db.profile
    local animDefaults = defaults.profile.animation

    local version = profile.schemaVersion or 0

    if version < 1 then
        -- v0 -> v1: entranceDirection -> entranceAnimation (LibAnimate)
        if profile.animation.entranceDirection then
            profile.animation.entranceAnimation =
                DIRECTION_TO_ANIMATION[profile.animation.entranceDirection]
                or "slideInRight"
            profile.animation.entranceDirection = nil
        end

        -- Set defaults for new keys
        if not profile.animation.exitAnimation then
            profile.animation.exitAnimation = "fadeOut"
        end
        if not profile.animation.exitDistance then
            profile.animation.exitDistance = 300
        end

        profile.schemaVersion = 1
    end

    if (profile.schemaVersion or 0) < 2 then
        -- v1 -> v2: attention animation defaults
        profile.animation = profile.animation or {}
        if profile.animation.attentionAnimation == nil then
            profile.animation.attentionAnimation =
                animDefaults.attentionAnimation
        end
        if profile.animation.attentionMinQuality == nil then
            profile.animation.attentionMinQuality =
                animDefaults.attentionMinQuality
        end
        if profile.animation.attentionRepeatCount == nil then
            profile.animation.attentionRepeatCount =
                animDefaults.attentionRepeatCount
        end
        if profile.animation.attentionDelay == nil then
            profile.animation.attentionDelay =
                animDefaults.attentionDelay
        end

        profile.schemaVersion = 2
    end

    if (profile.schemaVersion or 0) < 3 then
        -- v2 -> v3: gold display format default
        profile.display = profile.display or {}
        if profile.display.goldFormat == nil then
            profile.display.goldFormat = defaults.profile.display.goldFormat
        end

        profile.schemaVersion = 3
    end

    if (profile.schemaVersion or 0) < 4 then
        -- v3 -> v4: honor filter default
        if profile.filters and profile.filters.showHonor == nil then
            profile.filters.showHonor = true
        end

        profile.schemaVersion = 4
    end

    if (profile.schemaVersion or 0) < 5 then
        -- v4 -> v5: mail filter default
        if profile.filters and profile.filters.showMail == nil then
            profile.filters.showMail = true
        end

        profile.schemaVersion = 5
    end

    if (profile.schemaVersion or 0) < 6 then
        -- v5 -> v6: reputation filter default
        if profile.filters and profile.filters.showReputation == nil then
            profile.filters.showReputation = true
        end

        profile.schemaVersion = CURRENT_SCHEMA
    end
end

-------------------------------------------------------------------------------
-- Initialization (called from Init.lua OnInitialize)
-------------------------------------------------------------------------------

function ns.InitializeDB(addon)
    addon.db = LibStub("AceDB-3.0"):New("DragonToastDB", defaults, true)

    -- Migrate active profile
    MigrateProfile(addon.db)

    -- Re-migrate on profile changes
    addon.db.RegisterCallback(addon, "OnProfileChanged", function() MigrateProfile(addon.db) end)
    addon.db.RegisterCallback(addon, "OnProfileCopied", function() MigrateProfile(addon.db) end)
    addon.db.RegisterCallback(addon, "OnProfileReset", function() MigrateProfile(addon.db) end)
end
