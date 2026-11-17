-------------------------------------------------------------------------------
-- Media.lua
-- Registers bundled media assets with LibSharedMedia
--
-- Supported versions: TBC Anniversary, Retail, MoP Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

local LSM = LibStub("LibSharedMedia-3.0")

-- Use the client's locale-appropriate UI font rather than assuming Latin glyphs.
local chatFont = _G.ChatFontSmall
local uiFont = chatFont and chatFont.GetFont and chatFont:GetFont()
    or STANDARD_TEXT_FONT or [[Fonts\FRIZQT__.TTF]]
-- LSM requires an explicit language mask for fonts on non-Western clients.
LSM:Register("font", "Dragon UI", uiFont, 255)

local FLAT_TEXTURE = [[Interface\Buttons\WHITE8x8]]
LSM:Register("background", "Dragon UI Flat", FLAT_TEXTURE)
LSM:Register("border", "Dragon UI Flat", FLAT_TEXTURE)
LSM:Register("statusbar", "Dragon UI Flat", FLAT_TEXTURE)

local SOUND_PATH = [[Interface\AddOns\DragonToast\Sounds\]]

LSM:Register("sound", "Dragon Toast", SOUND_PATH .. [[DragonToast.ogg]])
LSM:Register("sound", "Dragon Roar", SOUND_PATH .. [[DragonRoar.ogg]])
LSM:Register("sound", "Ember Chime", SOUND_PATH .. [[EmberChime.ogg]])
LSM:Register("sound", "Treasure Drop", SOUND_PATH .. [[TreasureDrop.ogg]])
