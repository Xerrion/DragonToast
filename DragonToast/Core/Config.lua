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
            soundFile = "Dragon Toast",
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

    -- Simple single-field migrations (v3+)
    local SIMPLE_MIGRATIONS = {
        { version = 3, section = "display", key = "goldFormat", default = defaults.profile.display.goldFormat },
        { version = 4, section = "filters", key = "showHonor", default = true },
        { version = 5, section = "filters", key = "showMail", default = true },
        { version = 6, section = "filters", key = "showReputation", default = true },
    }

    for _, migration in ipairs(SIMPLE_MIGRATIONS) do
        if profile.schemaVersion < migration.version then
            if not profile[migration.section] then
                profile[migration.section] = {}
            end
            if profile[migration.section][migration.key] == nil then
                profile[migration.section][migration.key] = migration.default
            end
            profile.schemaVersion = migration.version
        end
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
