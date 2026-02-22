-------------------------------------------------------------------------------
-- Config.lua
-- DragonToast configuration: AceDB defaults, AceConfig options, GUI panel
--
-- Supported versions: TBC Anniversary, Retail
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")
local LSM = LibStub("LibSharedMedia-3.0")

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
            showIcon = true,
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
        },

        appearance = {
            fontSize = 12,
            secondaryFontSize = 10,
            fontFace = "Friz Quadrata TT",
            fontOutline = "OUTLINE",
            backgroundAlpha = 0.7,
            backgroundColor = { r = 0.05, g = 0.05, b = 0.05 },
            qualityBorder = true,
            qualityGlow = true,
            iconSize = 36,
            borderSize = 1,
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
-- Options Table
-------------------------------------------------------------------------------

local function GetOptions()
    local db = ns.Addon.db.profile

    local options = {
        name = "DragonToast",
        handler = ns.Addon,
        type = "group",
        args = {
            ----------------------------------------------------------------
            -- General
            ----------------------------------------------------------------
            general = {
                name = "General",
                type = "group",
                order = 1,
                args = {
                    desc = {
                        name = "General settings for DragonToast loot notifications.",
                        type = "description",
                        order = 0,
                        fontSize = "medium",
                    },

                    -- Master Controls
                    headerControls = {
                        name = "Controls",
                        type = "header",
                        order = 1,
                    },
                    enabled = {
                        name = "Enable DragonToast",
                        desc = "Master toggle for the loot feed.",
                        type = "toggle",
                        order = 2,
                        width = "full",
                        get = function() return db.enabled end,
                        set = function(_, val)
                            db.enabled = val
                            if val then
                                ns.Addon:OnEnable()
                            else
                                ns.Addon:OnDisable()
                            end
                        end,
                    },
                    minimapIcon = {
                        name = "Show Minimap Icon",
                        desc = "Show or hide the DragonToast minimap button.",
                        type = "toggle",
                        order = 3,
                        get = function() return not db.minimap.hide end,
                        set = function(_, val)
                            db.minimap.hide = not val
                            if ns.MinimapIcon.Toggle then
                                ns.MinimapIcon.Toggle()
                            end
                        end,
                    },
                    deferInCombat = {
                        name = "Defer During Combat",
                        desc = "Queue toasts during combat and show them when combat ends.",
                        type = "toggle",
                        order = 4,
                        get = function() return db.combat.deferInCombat end,
                        set = function(_, val) db.combat.deferInCombat = val end,
                    },

                    -- Actions
                    headerActions = {
                        name = "Actions",
                        type = "header",
                        order = 10,
                    },
                    test = {
                        name = "Show Test Toast",
                        desc = "Display a test toast to preview your settings.",
                        type = "execute",
                        order = 11,
                        func = function()
                            if ns.ToastManager.ShowTestToast then
                                ns.ToastManager.ShowTestToast()
                            end
                        end,
                    },
                    clear = {
                        name = "Clear All Toasts",
                        desc = "Dismiss all visible toasts.",
                        type = "execute",
                        order = 12,
                        func = function()
                            ns.ToastManager.ClearAll()
                        end,
                    },
                    testMode = {
                        name = "Test Mode",
                        desc = "Continuously generate test toasts for previewing your settings. Toggles on/off.",
                        type = "toggle",
                        order = 13,
                        width = "full",
                        get = function() return ns.ToastManager.IsTestModeActive() end,
                        set = function(_, val)
                            if val then
                                ns.ToastManager.StartTestMode()
                            else
                                ns.ToastManager.StopTestMode()
                            end
                        end,
                    },
                },
            },

            ----------------------------------------------------------------
            -- Filters
            ----------------------------------------------------------------
            filters = {
                name = "Filters",
                type = "group",
                order = 2,
                args = {
                    desc = {
                        name = "Control which loot events generate toast notifications.",
                        type = "description",
                        order = 0,
                        fontSize = "medium",
                    },

                    -- Item Quality
                    headerQuality = {
                        name = "Item Quality",
                        type = "header",
                        order = 1,
                    },
                    minQuality = {
                        name = "Minimum Quality",
                        desc = "Only show items of this quality or higher.",
                        type = "select",
                        order = 2,
                        values = {
                            [0] = "|cff9d9d9dPoor|r",
                            [1] = "|cffffffffCommon|r",
                            [2] = "|cff1eff00Uncommon|r",
                            [3] = "|cff0070ddRare|r",
                            [4] = "|cffa335eeEpic|r",
                            [5] = "|cffff8000Legendary|r",
                        },
                        get = function() return db.filters.minQuality end,
                        set = function(_, val) db.filters.minQuality = val end,
                    },

                    -- Loot Sources
                    headerSources = {
                        name = "Loot Sources",
                        type = "header",
                        order = 10,
                    },
                    showSelfLoot = {
                        name = "Show Your Loot",
                        desc = "Show toasts for items you loot.",
                        type = "toggle",
                        order = 11,
                        get = function() return db.filters.showSelfLoot end,
                        set = function(_, val) db.filters.showSelfLoot = val end,
                    },
                    showGroupLoot = {
                        name = "Show Group Loot",
                        desc = "Show toasts for items looted by party/raid members.",
                        type = "toggle",
                        order = 12,
                        get = function() return db.filters.showGroupLoot end,
                        set = function(_, val) db.filters.showGroupLoot = val end,
                    },

                    -- Rewards
                    headerRewards = {
                        name = "Rewards",
                        type = "header",
                        order = 20,
                    },
                    showQuestItems = {
                        name = "Show Quest Items",
                        desc = "Show toasts for quest item pickups.",
                        type = "toggle",
                        order = 21,
                        get = function() return db.filters.showQuestItems end,
                        set = function(_, val) db.filters.showQuestItems = val end,
                    },
                    showGold = {
                        name = "Show Gold",
                        desc = "Show toasts for gold gains.",
                        type = "toggle",
                        order = 22,
                        get = function() return db.filters.showGold end,
                        set = function(_, val) db.filters.showGold = val end,
                    },
                    showCurrency = {
                        name = "Show Currency",
                        desc = "Show toasts for currency gains.",
                        type = "toggle",
                        order = 23,
                        get = function() return db.filters.showCurrency end,
                        set = function(_, val) db.filters.showCurrency = val end,
                    },
                    showXP = {
                        name = "Show XP Gains",
                        desc = "Show toasts when you gain experience points.",
                        type = "toggle",
                        order = 24,
                        get = function() return db.filters.showXP end,
                        set = function(_, val) db.filters.showXP = val end,
                    },
                },
            },

            ----------------------------------------------------------------
            -- Display
            ----------------------------------------------------------------
            display = {
                name = "Display",
                type = "group",
                order = 3,
                args = {
                    desc = {
                        name = "Configure toast layout, sizing, and visible information.",
                        type = "description",
                        order = 0,
                        fontSize = "medium",
                    },

                    -- Layout
                    headerLayout = {
                        name = "Layout",
                        type = "header",
                        order = 1,
                    },
                    maxToasts = {
                        name = "Max Visible Toasts",
                        desc = "Maximum number of toasts visible at once. Overflow is queued.",
                        type = "range",
                        order = 2,
                        min = 1, max = 15, step = 1,
                        get = function() return db.display.maxToasts end,
                        set = function(_, val) db.display.maxToasts = val end,
                    },
                    growDirection = {
                        name = "Growth Direction",
                        desc = "Direction new toasts stack.",
                        type = "select",
                        order = 3,
                        values = { UP = "Upward", DOWN = "Downward" },
                        get = function() return db.display.growDirection end,
                        set = function(_, val)
                            db.display.growDirection = val
                            ns.ToastManager.UpdatePositions()
                        end,
                    },
                    spacing = {
                        name = "Toast Spacing",
                        desc = "Space between toasts in pixels.",
                        type = "range",
                        order = 4,
                        min = 0, max = 20, step = 1,
                        get = function() return db.display.spacing end,
                        set = function(_, val)
                            db.display.spacing = val
                            ns.ToastManager.UpdateLayout()
                        end,
                    },

                    -- Size
                    headerSize = {
                        name = "Toast Size",
                        type = "header",
                        order = 10,
                    },
                    toastWidth = {
                        name = "Width",
                        desc = "Width of each toast in pixels.",
                        type = "range",
                        order = 11,
                        min = 200, max = 600, step = 10,
                        get = function() return db.display.toastWidth end,
                        set = function(_, val)
                            db.display.toastWidth = val
                            ns.ToastManager.UpdateLayout()
                        end,
                    },
                    toastHeight = {
                        name = "Height",
                        desc = "Height of each toast in pixels.",
                        type = "range",
                        order = 12,
                        min = 32, max = 80, step = 2,
                        get = function() return db.display.toastHeight end,
                        set = function(_, val)
                            db.display.toastHeight = val
                            ns.ToastManager.UpdateLayout()
                        end,
                    },

                    -- Content
                    headerContent = {
                        name = "Toast Content",
                        type = "header",
                        order = 20,
                    },
                    showIcon = {
                        name = "Show Icon",
                        desc = "Show item icon on toasts.",
                        type = "toggle",
                        order = 21,
                        get = function() return db.display.showIcon end,
                        set = function(_, val)
                            db.display.showIcon = val
                            ns.ToastManager.UpdateLayout()
                        end,
                    },
                    showItemLevel = {
                        name = "Show Item Level",
                        type = "toggle",
                        order = 22,
                        get = function() return db.display.showItemLevel end,
                        set = function(_, val) db.display.showItemLevel = val end,
                    },
                    showItemType = {
                        name = "Show Item Type",
                        type = "toggle",
                        order = 23,
                        get = function() return db.display.showItemType end,
                        set = function(_, val) db.display.showItemType = val end,
                    },
                    showQuantity = {
                        name = "Show Quantity",
                        type = "toggle",
                        order = 24,
                        get = function() return db.display.showQuantity end,
                        set = function(_, val) db.display.showQuantity = val end,
                    },
                    showLooter = {
                        name = "Show Looter Name",
                        type = "toggle",
                        order = 25,
                        get = function() return db.display.showLooter end,
                        set = function(_, val) db.display.showLooter = val end,
                    },

                    -- Position
                    headerPosition = {
                        name = "Position",
                        type = "header",
                        order = 30,
                    },
                    unlockAnchor = {
                        name = "Unlock Anchor",
                        desc = "Toggle the anchor frame to drag and reposition toasts.",
                        type = "toggle",
                        order = 31,
                        get = function()
                            local anchor = _G["DragonToastAnchor"]
                            return anchor and anchor:IsShown() or false
                        end,
                        set = function(_, _val)
                            ns.ToastManager.ToggleLock()
                        end,
                    },
                    resetPosition = {
                        name = "Reset Position",
                        desc = "Reset toast anchor to the default position (right side of screen).",
                        type = "execute",
                        order = 32,
                        func = function()
                            ns.ToastManager.SetAnchor("RIGHT", -20, 0)
                            ns.Print("Anchor position reset to default.")
                        end,
                    },
                },
            },

            ----------------------------------------------------------------
            -- Animation
            ----------------------------------------------------------------
            animation = {
                name = "Animation",
                type = "group",
                order = 4,
                args = {
                    desc = {
                        name = "Configure toast entrance, exit, and movement animations.",
                        type = "description",
                        order = 0,
                        fontSize = "medium",
                    },

                    -- Master toggle
                    headerGeneral = {
                        name = "General",
                        type = "header",
                        order = 1,
                    },
                    enableAnimations = {
                        name = "Enable Animations",
                        desc = "Toggle slide-in and fade-out animations.",
                        type = "toggle",
                        order = 2,
                        width = "full",
                        get = function() return db.animation.enableAnimations end,
                        set = function(_, val) db.animation.enableAnimations = val end,
                    },

                    -- Timing
                    headerTiming = {
                        name = "Timing",
                        type = "header",
                        order = 10,
                    },
                    entranceDuration = {
                        name = "Entrance Duration",
                        desc = "How long the slide-in takes (seconds).",
                        type = "range",
                        order = 11,
                        min = 0.1, max = 1.0, step = 0.05,
                        get = function() return db.animation.entranceDuration end,
                        set = function(_, val) db.animation.entranceDuration = val end,
                    },
                    holdDuration = {
                        name = "Display Duration",
                        desc = "How long a toast stays visible before fading (seconds).",
                        type = "range",
                        order = 12,
                        min = 1.0, max = 15.0, step = 0.5,
                        get = function() return db.animation.holdDuration end,
                        set = function(_, val) db.animation.holdDuration = val end,
                    },
                    exitDuration = {
                        name = "Fade Out Duration",
                        desc = "How long the fade-out takes (seconds).",
                        type = "range",
                        order = 13,
                        min = 0.1, max = 2.0, step = 0.1,
                        get = function() return db.animation.exitDuration end,
                        set = function(_, val) db.animation.exitDuration = val end,
                    },

                    -- Entrance
                    headerEntrance = {
                        name = "Entrance",
                        type = "header",
                        order = 20,
                    },
                    entranceAnimation = {
                        name = "Entrance Animation",
                        desc = "Animation to play when a toast appears.",
                        type = "select",
                        order = 21,
                        values = function()
                            local lib = ns.LibAnimate
                            if not lib then return {} end
                            local vals = {}
                            for _, name in ipairs(lib:GetEntranceAnimations()) do
                                vals[name] = name:gsub("(%u)", " %1"):gsub("^%l", string.upper)
                            end
                            return vals
                        end,
                        get = function() return db.animation.entranceAnimation end,
                        set = function(_, val) db.animation.entranceAnimation = val end,
                    },
                    entranceDistance = {
                        name = "Entrance Distance",
                        desc = "How far toasts travel during entrance (pixels). Only affects directional animations.",
                        type = "range",
                        order = 22,
                        min = 50, max = 600, step = 10,
                        get = function() return db.animation.entranceDistance end,
                        set = function(_, val) db.animation.entranceDistance = val end,
                    },

                    -- Exit
                    headerExit = {
                        name = "Exit",
                        type = "header",
                        order = 24,
                    },
                    exitAnimation = {
                        name = "Exit Animation",
                        desc = "Animation to play when a toast is dismissed.",
                        type = "select",
                        order = 25,
                        values = function()
                            local lib = ns.LibAnimate
                            if not lib then return {} end
                            local vals = {}
                            for _, name in ipairs(lib:GetExitAnimations()) do
                                vals[name] = name:gsub("(%u)", " %1"):gsub("^%l", string.upper)
                            end
                            return vals
                        end,
                        get = function() return db.animation.exitAnimation end,
                        set = function(_, val) db.animation.exitAnimation = val end,
                    },
                    exitDistance = {
                        name = "Exit Distance",
                        desc = "How far toasts travel during exit (pixels). Only affects directional animations.",
                        type = "range",
                        order = 26,
                        min = 50, max = 600, step = 10,
                        get = function() return db.animation.exitDistance end,
                        set = function(_, val) db.animation.exitDistance = val end,
                    },

                    -- Repositioning
                    headerReposition = {
                        name = "Repositioning",
                        type = "header",
                        order = 30,
                    },
                    slideSpeed = {
                        name = "Reposition Speed",
                        desc = "Speed of toast repositioning when a toast above is dismissed (seconds).",
                        type = "range",
                        order = 31,
                        min = 0.05, max = 0.5, step = 0.05,
                        get = function() return db.animation.slideSpeed end,
                        set = function(_, val) db.animation.slideSpeed = val end,
                    },
                },
            },

            ----------------------------------------------------------------
            -- Appearance
            ----------------------------------------------------------------
            appearance = {
                name = "Appearance",
                type = "group",
                order = 5,
                args = {
                    desc = {
                        name = "Customize toast fonts, colors, borders, and visual style.",
                        type = "description",
                        order = 0,
                        fontSize = "medium",
                    },

                    -- Font
                    headerFont = {
                        name = "Font",
                        type = "header",
                        order = 1,
                    },
                    fontFace = {
                        name = "Font Face",
                        desc = "Font for all toast text.",
                        type = "select",
                        order = 2,
                        dialogControl = "LSM30_Font",
                        values = function() return LSM:HashTable("font") end,
                        get = function() return db.appearance.fontFace end,
                        set = function(_, val)
                            db.appearance.fontFace = val
                            ns.ToastManager.UpdateLayout()
                        end,
                    },
                    fontSize = {
                        name = "Primary Font Size",
                        desc = "Size of the item name text.",
                        type = "range",
                        order = 3,
                        min = 8, max = 20, step = 1,
                        get = function() return db.appearance.fontSize end,
                        set = function(_, val)
                            db.appearance.fontSize = val
                            ns.ToastManager.UpdateLayout()
                        end,
                    },
                    secondaryFontSize = {
                        name = "Secondary Font Size",
                        desc = "Font size for item level, type, and looter.",
                        type = "range",
                        order = 4,
                        min = 6, max = 16, step = 1,
                        get = function() return db.appearance.secondaryFontSize end,
                        set = function(_, val)
                            db.appearance.secondaryFontSize = val
                            ns.ToastManager.UpdateLayout()
                        end,
                    },
                    fontOutline = {
                        name = "Font Outline",
                        desc = "Font outline style.",
                        type = "select",
                        order = 5,
                        values = {
                            [""] = "None",
                            OUTLINE = "Outline",
                            THICKOUTLINE = "Thick Outline",
                            ["MONOCHROME, OUTLINE"] = "Monochrome",
                        },
                        get = function() return db.appearance.fontOutline end,
                        set = function(_, val)
                            db.appearance.fontOutline = val
                            ns.ToastManager.UpdateLayout()
                        end,
                    },

                    -- Background
                    headerBackground = {
                        name = "Background",
                        type = "header",
                        order = 10,
                    },
                    backgroundColor = {
                        name = "Background Color",
                        desc = "Toast background color.",
                        type = "color",
                        order = 11,
                        hasAlpha = false,
                        get = function()
                            local c = db.appearance.backgroundColor
                            return c.r, c.g, c.b
                        end,
                        set = function(_, r, g, b)
                            db.appearance.backgroundColor.r = r
                            db.appearance.backgroundColor.g = g
                            db.appearance.backgroundColor.b = b
                            ns.ToastManager.UpdateLayout()
                        end,
                    },
                    backgroundAlpha = {
                        name = "Background Opacity",
                        desc = "Opacity of the toast background.",
                        type = "range",
                        order = 12,
                        min = 0.0, max = 1.0, step = 0.05, isPercent = true,
                        get = function() return db.appearance.backgroundAlpha end,
                        set = function(_, val)
                            db.appearance.backgroundAlpha = val
                            ns.ToastManager.UpdateLayout()
                        end,
                    },

                    -- Border & Glow
                    headerBorder = {
                        name = "Border & Glow",
                        type = "header",
                        order = 20,
                    },
                    qualityBorder = {
                        name = "Quality-Colored Border",
                        desc = "Color the toast border based on item quality.",
                        type = "toggle",
                        order = 21,
                        get = function() return db.appearance.qualityBorder end,
                        set = function(_, val) db.appearance.qualityBorder = val end,
                    },
                    borderSize = {
                        name = "Border Thickness",
                        desc = "Border thickness in pixels.",
                        type = "range",
                        order = 22,
                        min = 1, max = 4, step = 1,
                        get = function() return db.appearance.borderSize end,
                        set = function(_, val)
                            db.appearance.borderSize = val
                            ns.ToastManager.UpdateLayout()
                        end,
                    },
                    borderTexture = {
                        name = "Border Texture",
                        desc = "Border texture style for toasts.",
                        type = "select",
                        order = 23,
                        dialogControl = "LSM30_Border",
                        values = function() return LSM:HashTable("border") end,
                        get = function() return db.appearance.borderTexture end,
                        set = function(_, val)
                            db.appearance.borderTexture = val
                            ns.ToastManager.UpdateLayout()
                        end,
                    },
                    qualityGlow = {
                        name = "Quality Glow Strip",
                        desc = "Show a subtle glow strip colored by item quality.",
                        type = "toggle",
                        order = 24,
                        get = function() return db.appearance.qualityGlow end,
                        set = function(_, val) db.appearance.qualityGlow = val end,
                    },
                    glowWidth = {
                        name = "Glow Width",
                        desc = "Quality glow strip width in pixels.",
                        type = "range",
                        order = 25,
                        min = 0, max = 12, step = 1,
                        get = function() return db.appearance.glowWidth end,
                        set = function(_, val)
                            db.appearance.glowWidth = val
                            ns.ToastManager.UpdateLayout()
                        end,
                    },
                    statusBarTexture = {
                        name = "Glow Texture",
                        desc = "Texture for quality glow strip.",
                        type = "select",
                        order = 26,
                        dialogControl = "LSM30_Statusbar",
                        values = function() return LSM:HashTable("statusbar") end,
                        get = function() return db.appearance.statusBarTexture end,
                        set = function(_, val)
                            db.appearance.statusBarTexture = val
                            ns.ToastManager.UpdateLayout()
                        end,
                    },

                    -- Icon
                    headerIcon = {
                        name = "Icon",
                        type = "header",
                        order = 30,
                    },
                    iconSize = {
                        name = "Icon Size",
                        desc = "Size of the item icon in pixels.",
                        type = "range",
                        order = 31,
                        min = 16, max = 64, step = 2,
                        get = function() return db.appearance.iconSize end,
                        set = function(_, val)
                            db.appearance.iconSize = val
                            ns.ToastManager.UpdateLayout()
                        end,
                    },

                    -- ElvUI
                    headerElvUI = {
                        name = "ElvUI",
                        type = "header",
                        order = 40,
                    },
                    useSkin = {
                        name = "Match ElvUI Style",
                        desc = "Automatically use ElvUI fonts and textures when ElvUI is detected.",
                        type = "toggle",
                        order = 41,
                        width = "full",
                        get = function() return db.elvui.useSkin end,
                        set = function(_, val)
                            db.elvui.useSkin = val
                            if ns.ElvUISkin.Apply then
                                ns.ElvUISkin.Apply()
                            end
                        end,
                    },
                },
            },

            ----------------------------------------------------------------
            -- Sound
            ----------------------------------------------------------------
            sound = {
                name = "Sound",
                type = "group",
                order = 6,
                args = {
                    desc = {
                        name = "Configure audio feedback for toast notifications.",
                        type = "description",
                        order = 0,
                        fontSize = "medium",
                    },
                    headerSound = {
                        name = "Notification Sound",
                        type = "header",
                        order = 1,
                    },
                    enabled = {
                        name = "Enable Sound",
                        desc = "Play a sound when a toast appears.",
                        type = "toggle",
                        order = 2,
                        width = "full",
                        get = function() return db.sound.enabled end,
                        set = function(_, val) db.sound.enabled = val end,
                    },
                    soundFile = {
                        name = "Sound Effect",
                        desc = "Sound to play when a toast appears.",
                        type = "select",
                        order = 3,
                        dialogControl = "LSM30_Sound",
                        values = function() return LSM:HashTable("sound") end,
                        get = function() return db.sound.soundFile end,
                        set = function(_, val) db.sound.soundFile = val end,
                    },
                },
            },

            ----------------------------------------------------------------
            -- Profiles (AceDBOptions)
            ----------------------------------------------------------------
            profiles = AceDBOptions:GetOptionsTable(ns.Addon.db),
        },
    }

    -- Set profiles order
    options.args.profiles.order = 7

    return options
end

-------------------------------------------------------------------------------
-- Profile Migration
-------------------------------------------------------------------------------

local CURRENT_SCHEMA = 1

local DIRECTION_TO_ANIMATION = {
    RIGHT  = "slideInRight",
    LEFT   = "slideInLeft",
    TOP    = "slideInDown",
    BOTTOM = "slideInUp",
}

local function MigrateProfile(db)
    local profile = db.profile

    local version = profile.schemaVersion or 0

    if version < 1 then
        -- v0 → v1: entranceDirection → entranceAnimation (LibAnimate integration)
        if profile.animation.entranceDirection then
            profile.animation.entranceAnimation = DIRECTION_TO_ANIMATION[profile.animation.entranceDirection]
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

    -- Register options
    AceConfig:RegisterOptionsTable(ADDON_NAME, GetOptions)
    AceConfigDialog:AddToBlizOptions(ADDON_NAME, "DragonToast")
end
