-------------------------------------------------------------------------------
-- Media.lua
-- Registers bundled media assets with LibSharedMedia
--
-- Supported versions: TBC Anniversary, Retail, MoP Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

local LSM = LibStub("LibSharedMedia-3.0")

local SOUND_PATH = [[Interface\AddOns\DragonToast\Sounds\]]

LSM:Register("sound", "Dragon Toast", SOUND_PATH .. [[DragonToast.ogg]])
LSM:Register("sound", "Dragon Roar", SOUND_PATH .. [[DragonRoar.ogg]])
LSM:Register("sound", "Ember Chime", SOUND_PATH .. [[EmberChime.ogg]])
LSM:Register("sound", "Treasure Drop", SOUND_PATH .. [[TreasureDrop.ogg]])
