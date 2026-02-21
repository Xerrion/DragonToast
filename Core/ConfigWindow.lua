-------------------------------------------------------------------------------
-- ConfigWindow.lua
-- Standalone AceGUI configuration window for DragonToast
--
-- Supported versions: TBC Anniversary, Retail
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

local AceConfigDialog = LibStub("AceConfigDialog-3.0")

-------------------------------------------------------------------------------
-- Config Window Management
-------------------------------------------------------------------------------

function ns.OpenConfigWindow()
    -- AceConfigDialog:Open() creates a standalone AceGUI Frame window
    -- This is the standard Ace3 pattern for standalone config UIs
    AceConfigDialog:Open(ADDON_NAME)
end

function ns.CloseConfigWindow()
    AceConfigDialog:Close(ADDON_NAME)
end

function ns.ToggleConfigWindow()
    if AceConfigDialog.OpenFrames and AceConfigDialog.OpenFrames[ADDON_NAME] then
        ns.CloseConfigWindow()
    else
        ns.OpenConfigWindow()
    end
end
