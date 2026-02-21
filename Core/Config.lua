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
            enablePopEffect = true,
            entranceDirection = "RIGHT",
            entranceDistance = 300,
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
            -- General section
            general = {
                name = "General",
                type = "group",
                order = 1,
                args = {
                    enabled = {
                        name = "Enable DragonToast",
                        desc = "Master toggle for the loot feed.",
                        type = "toggle",
                        order = 1,
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
                    test = {
                        name = "Show Test Toast",
                        desc = "Display a test toast to preview your settings.",
                        type = "execute",
                        order = 2,
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
                        order = 3,
                        func = function()
                            ns.ToastManager.ClearAll()
                        end,
                    },
                    minimapIcon = {
                        name = "Show Minimap Icon",
                        desc = "Show or hide the DragonToast minimap button.",
                        type = "toggle",
                        order = 4,
                        get = function() return not db.minimap.hide end,
                        set = function(_, val)
                            db.minimap.hide = not val
                            if ns.MinimapIcon.Toggle then
                                ns.MinimapIcon.Toggle()
                            end
                        end,
                    },
                },
            },

            -- Filters section
            filters = {
                name = "Filters",
                type = "group",
                order = 2,
                args = {
                    minQuality = {
                        name = "Minimum Quality",
                        desc = "Only show items of this quality or higher.",
                        type = "select",
                        order = 1,
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
                    showSelfLoot = {
                        name = "Show Your Loot",
                        desc = "Show toasts for items you loot.",
                        type = "toggle",
                        order = 2,
                        get = function() return db.filters.showSelfLoot end,
                        set = function(_, val) db.filters.showSelfLoot = val end,
                    },
                    showGroupLoot = {
                        name = "Show Group Loot",
                        desc = "Show toasts for items looted by party/raid members.",
                        type = "toggle",
                        order = 3,
                        get = function() return db.filters.showGroupLoot end,
                        set = function(_, val) db.filters.showGroupLoot = val end,
                    },
                    showCurrency = {
                        name = "Show Currency",
                        desc = "Show toasts for currency gains.",
                        type = "toggle",
                        order = 4,
                        get = function() return db.filters.showCurrency end,
                        set = function(_, val) db.filters.showCurrency = val end,
                    },
                    showGold = {
                        name = "Show Gold",
                        desc = "Show toasts for gold gains.",
                        type = "toggle",
                        order = 5,
                        get = function() return db.filters.showGold end,
                        set = function(_, val) db.filters.showGold = val end,
                    },
                    showQuestItems = {
                        name = "Show Quest Items",
                        desc = "Show toasts for quest item pickups.",
                        type = "toggle",
                        order = 6,
                        get = function() return db.filters.showQuestItems end,
                        set = function(_, val) db.filters.showQuestItems = val end,
                    },
                    showXP = {
                        name = "Show XP Gains",
                        desc = "Show toasts when you gain experience points.",
                        type = "toggle",
                        order = 7,
                        get = function() return db.filters.showXP end,
                        set = function(_, val) db.filters.showXP = val end,
                    },
                },
            },

            -- Display section
            display = {
                name = "Display",
                type = "group",
                order = 3,
                args = {
                    maxToasts = {
                        name = "Max Visible Toasts",
                        desc = "Maximum number of toasts visible at once. Overflow is queued.",
                        type = "range",
                        order = 1,
                        min = 1, max = 15, step = 1,
                        get = function() return db.display.maxToasts end,
                        set = function(_, val) db.display.maxToasts = val end,
                    },
                    toastWidth = {
                        name = "Toast Width",
                        desc = "Width of each toast in pixels.",
                        type = "range",
                        order = 2,
                        min = 200, max = 600, step = 10,
                        get = function() return db.display.toastWidth end,
                        set = function(_, val)
                            db.display.toastWidth = val
                            ns.ToastManager.UpdateLayout()
                        end,
                    },
                    toastHeight = {
                        name = "Toast Height",
                        desc = "Height of each toast in pixels.",
                        type = "range",
                        order = 3,
                        min = 32, max = 80, step = 2,
                        get = function() return db.display.toastHeight end,
                        set = function(_, val)
                            db.display.toastHeight = val
                            ns.ToastManager.UpdateLayout()
                        end,
                    },
                    growDirection = {
                        name = "Growth Direction",
                        desc = "Direction new toasts stack.",
                        type = "select",
                        order = 4,
                        values = { UP = "Upward", DOWN = "Downward" },
                        get = function() return db.display.growDirection end,
                        set = function(_, val)
                            db.display.growDirection = val
                            ns.ToastManager.UpdatePositions()
                        end,
                    },
                    spacer1 = { name = "", type = "description", order = 5 },
                    showItemLevel = {
                        name = "Show Item Level",
                        type = "toggle",
                        order = 6,
                        get = function() return db.display.showItemLevel end,
                        set = function(_, val) db.display.showItemLevel = val end,
                    },
                    showItemType = {
                        name = "Show Item Type",
                        type = "toggle",
                        order = 7,
                        get = function() return db.display.showItemType end,
                        set = function(_, val) db.display.showItemType = val end,
                    },
                    showLooter = {
                        name = "Show Looter Name",
                        type = "toggle",
                        order = 8,
                        get = function() return db.display.showLooter end,
                        set = function(_, val) db.display.showLooter = val end,
                    },
                    showQuantity = {
                        name = "Show Quantity",
                        type = "toggle",
                        order = 9,
                        get = function() return db.display.showQuantity end,
                        set = function(_, val) db.display.showQuantity = val end,
                    },
                    spacing = {
                        name = "Toast Spacing",
                        desc = "Space between toasts in pixels.",
                        type = "range",
                        order = 10,
                        min = 0, max = 20, step = 1,
                        get = function() return db.display.spacing end,
                        set = function(_, val)
                            db.display.spacing = val
                            ns.ToastManager.UpdateLayout()
                        end,
                    },
                    showIcon = {
                        name = "Show Item Icon",
                        desc = "Show item icon on toasts.",
                        type = "toggle",
                        order = 11,
                        get = function() return db.display.showIcon end,
                        set = function(_, val)
                            db.display.showIcon = val
                            ns.ToastManager.UpdateLayout()
                        end,
                    },
                    spacer2 = { name = "\nPosition", type = "header", order = 12 },
                    unlockAnchor = {
                        name = "Unlock Anchor",
                        desc = "Toggle the anchor frame to drag and reposition toasts.",
                        type = "toggle",
                        order = 13,
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
                        order = 14,
                        func = function()
                            ns.ToastManager.SetAnchor("RIGHT", -20, 0)
                            ns.Print("Anchor position reset to default.")
                        end,
                    },
                },
            },

            -- Animation section
            animation = {
                name = "Animation",
                type = "group",
                order = 4,
                args = {
                    enableAnimations = {
                        name = "Enable Animations",
                        desc = "Toggle slide-in and fade-out animations.",
                        type = "toggle",
                        order = 1,
                        width = "full",
                        get = function() return db.animation.enableAnimations end,
                        set = function(_, val) db.animation.enableAnimations = val end,
                    },
                    entranceDuration = {
                        name = "Entrance Duration",
                        desc = "How long the slide-in takes (seconds).",
                        type = "range",
                        order = 2,
                        min = 0.1, max = 1.0, step = 0.05,
                        get = function() return db.animation.entranceDuration end,
                        set = function(_, val) db.animation.entranceDuration = val end,
                    },
                    holdDuration = {
                        name = "Display Duration",
                        desc = "How long a toast stays visible before fading (seconds).",
                        type = "range",
                        order = 3,
                        min = 1.0, max = 15.0, step = 0.5,
                        get = function() return db.animation.holdDuration end,
                        set = function(_, val) db.animation.holdDuration = val end,
                    },
                    exitDuration = {
                        name = "Fade Out Duration",
                        desc = "How long the fade-out takes (seconds).",
                        type = "range",
                        order = 4,
                        min = 0.1, max = 2.0, step = 0.1,
                        get = function() return db.animation.exitDuration end,
                        set = function(_, val) db.animation.exitDuration = val end,
                    },
                    enablePopEffect = {
                        name = "Pop Effect",
                        desc = "Subtle scale bounce when a toast appears.",
                        type = "toggle",
                        order = 5,
                        get = function() return db.animation.enablePopEffect end,
                        set = function(_, val) db.animation.enablePopEffect = val end,
                    },
                    entranceDirection = {
                        name = "Entrance Direction",
                        desc = "Direction toasts slide in from.",
                        type = "select",
                        order = 6,
                        values = { LEFT = "Left", RIGHT = "Right", TOP = "Top", BOTTOM = "Bottom" },
                        get = function() return db.animation.entranceDirection end,
                        set = function(_, val) db.animation.entranceDirection = val end,
                    },
                    entranceDistance = {
                        name = "Entrance Distance",
                        desc = "How far toasts slide in (pixels).",
                        type = "range",
                        order = 7,
                        min = 50, max = 600, step = 10,
                        get = function() return db.animation.entranceDistance end,
                        set = function(_, val) db.animation.entranceDistance = val end,
                    },
                    slideSpeed = {
                        name = "Slide Speed",
                        desc = "Speed of toast repositioning (seconds).",
                        type = "range",
                        order = 8,
                        min = 0.05, max = 0.5, step = 0.05,
                        get = function() return db.animation.slideSpeed end,
                        set = function(_, val) db.animation.slideSpeed = val end,
                    },
                },
            },

            -- Appearance section
            appearance = {
                name = "Appearance",
                type = "group",
                order = 5,
                args = {
                    fontSize = {
                        name = "Font Size",
                        desc = "Size of the item name text.",
                        type = "range",
                        order = 1,
                        min = 8, max = 20, step = 1,
                        get = function() return db.appearance.fontSize end,
                        set = function(_, val)
                            db.appearance.fontSize = val
                            ns.ToastManager.UpdateLayout()
                        end,
                    },
                    backgroundAlpha = {
                        name = "Background Opacity",
                        desc = "Opacity of the toast background.",
                        type = "range",
                        order = 2,
                        min = 0.0, max = 1.0, step = 0.05, isPercent = true,
                        get = function() return db.appearance.backgroundAlpha end,
                        set = function(_, val)
                            db.appearance.backgroundAlpha = val
                            ns.ToastManager.UpdateLayout()
                        end,
                    },
                    iconSize = {
                        name = "Icon Size",
                        desc = "Size of the item icon.",
                        type = "range",
                        order = 3,
                        min = 16, max = 64, step = 2,
                        get = function() return db.appearance.iconSize end,
                        set = function(_, val)
                            db.appearance.iconSize = val
                            ns.ToastManager.UpdateLayout()
                        end,
                    },
                    qualityBorder = {
                        name = "Quality-Colored Border",
                        desc = "Color the toast border based on item quality.",
                        type = "toggle",
                        order = 4,
                        get = function() return db.appearance.qualityBorder end,
                        set = function(_, val) db.appearance.qualityBorder = val end,
                    },
                    qualityGlow = {
                        name = "Quality Glow",
                        desc = "Show a subtle glow strip colored by item quality.",
                        type = "toggle",
                        order = 5,
                        get = function() return db.appearance.qualityGlow end,
                        set = function(_, val) db.appearance.qualityGlow = val end,
                    },
                    fontFace = {
                        name = "Font",
                        desc = "Font for item names.",
                        type = "select",
                        order = 6,
                        dialogControl = "LSM30_Font",
                        values = function() return LSM:HashTable("font") end,
                        get = function() return db.appearance.fontFace end,
                        set = function(_, val)
                            db.appearance.fontFace = val
                            ns.ToastManager.UpdateLayout()
                        end,
                    },
                    fontOutline = {
                        name = "Font Outline",
                        desc = "Font outline style.",
                        type = "select",
                        order = 7,
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
                    secondaryFontSize = {
                        name = "Secondary Font Size",
                        desc = "Font size for item level, type, and looter.",
                        type = "range",
                        order = 8,
                        min = 6, max = 16, step = 1,
                        get = function() return db.appearance.secondaryFontSize end,
                        set = function(_, val)
                            db.appearance.secondaryFontSize = val
                            ns.ToastManager.UpdateLayout()
                        end,
                    },
                    backgroundColor = {
                        name = "Background Color",
                        desc = "Toast background color.",
                        type = "color",
                        order = 9,
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
                    borderSize = {
                        name = "Border Size",
                        desc = "Border thickness in pixels.",
                        type = "range",
                        order = 10,
                        min = 1, max = 4, step = 1,
                        get = function() return db.appearance.borderSize end,
                        set = function(_, val)
                            db.appearance.borderSize = val
                            ns.ToastManager.UpdateLayout()
                        end,
                    },
                    glowWidth = {
                        name = "Glow Width",
                        desc = "Quality glow strip width (0 to disable).",
                        type = "range",
                        order = 11,
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
                        order = 12,
                        dialogControl = "LSM30_Statusbar",
                        values = function() return LSM:HashTable("statusbar") end,
                        get = function() return db.appearance.statusBarTexture end,
                        set = function(_, val)
                            db.appearance.statusBarTexture = val
                            ns.ToastManager.UpdateLayout()
                        end,
                    },
                },
            },

            -- Sound section
            sound = {
                name = "Sound",
                type = "group",
                order = 6,
                args = {
                    enabled = {
                        name = "Enable Sound",
                        desc = "Play a sound when a toast appears.",
                        type = "toggle",
                        order = 1,
                        width = "full",
                        get = function() return db.sound.enabled end,
                        set = function(_, val) db.sound.enabled = val end,
                    },
                    soundFile = {
                        name = "Sound",
                        desc = "Sound to play when a toast appears.",
                        type = "select",
                        order = 2,
                        dialogControl = "LSM30_Sound",
                        values = function() return LSM:HashTable("sound") end,
                        get = function() return db.sound.soundFile end,
                        set = function(_, val) db.sound.soundFile = val end,
                    },
                },
            },

            -- Combat section
            combat = {
                name = "Combat",
                type = "group",
                order = 7,
                args = {
                    deferInCombat = {
                        name = "Defer During Combat",
                        desc = "Queue toasts during combat and show them when combat ends.",
                        type = "toggle",
                        order = 1,
                        width = "full",
                        get = function() return db.combat.deferInCombat end,
                        set = function(_, val) db.combat.deferInCombat = val end,
                    },
                },
            },

            -- ElvUI section
            elvui = {
                name = "ElvUI",
                type = "group",
                order = 8,
                args = {
                    useSkin = {
                        name = "Match ElvUI Style",
                        desc = "Automatically use ElvUI fonts and textures when ElvUI is detected.",
                        type = "toggle",
                        order = 1,
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

            -- Profiles section (AceDBOptions)
            profiles = AceDBOptions:GetOptionsTable(ns.Addon.db),
        },
    }

    -- Set profiles order
    options.args.profiles.order = 9

    return options
end

-------------------------------------------------------------------------------
-- Initialization (called from Init.lua OnInitialize)
-------------------------------------------------------------------------------

function ns.InitializeDB(addon)
    addon.db = LibStub("AceDB-3.0"):New("DragonToastDB", defaults, true)

    -- Register options
    AceConfig:RegisterOptionsTable(ADDON_NAME, GetOptions)
    AceConfigDialog:AddToBlizOptions(ADDON_NAME, "DragonToast")
end
