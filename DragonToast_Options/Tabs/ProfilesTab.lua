-------------------------------------------------------------------------------
-- ProfilesTab.lua
-- Profile management tab: switch, create, copy, reset, delete profiles
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

-------------------------------------------------------------------------------
-- Cached globals
-------------------------------------------------------------------------------

local pairs = pairs
local table_sort = table.sort
local math_abs = math.abs
local StaticPopup_Show = StaticPopup_Show
local StaticPopupDialogs = StaticPopupDialogs

-------------------------------------------------------------------------------
-- Namespace references
-------------------------------------------------------------------------------

local dtns = ns.dtns

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local PADDING_SIDE = 10
local PADDING_TOP = -10
local SPACING_AFTER_HEADER = 8
local SPACING_BETWEEN_WIDGETS = 6
local SPACING_BETWEEN_SECTIONS = 16
local PADDING_BOTTOM = 20

-------------------------------------------------------------------------------
-- Static popup dialogs (defined at file scope)
-------------------------------------------------------------------------------

StaticPopupDialogs["DRAGONTOAST_OPTIONS_RESET_PROFILE"] = {
    text = "Are you sure you want to reset the current profile?",
    button1 = "Reset",
    button2 = "Cancel",
    OnAccept = function()
        dtns.Addon.db:ResetProfile()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["DRAGONTOAST_OPTIONS_DELETE_PROFILE"] = {
    text = "Are you sure you want to delete the profile \"%s\"?",
    button1 = "Delete",
    button2 = "Cancel",
    OnAccept = function(self)
        local profileName = self.data
        if profileName then
            dtns.Addon.db:DeleteProfile(profileName)
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------

local function AnchorWidget(widget, parent, yOffset)
    widget:SetPoint("TOPLEFT", parent, "TOPLEFT", PADDING_SIDE, yOffset)
    widget:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -PADDING_SIDE, yOffset)
end

local function GetProfileValues()
    local db = dtns.Addon.db
    local profiles = db:GetProfiles()
    local values = {}
    for _, name in pairs(profiles) do
        values[#values + 1] = { value = name, text = name }
    end
    table_sort(values, function(a, b) return a.text < b.text end)
    return values
end

local function GetOtherProfileValues()
    local db = dtns.Addon.db
    local profiles = db:GetProfiles()
    local current = db:GetCurrentProfile()
    local values = {}
    for _, name in pairs(profiles) do
        if name ~= current then
            values[#values + 1] = { value = name, text = name }
        end
    end
    table_sort(values, function(a, b) return a.text < b.text end)
    return values
end

-------------------------------------------------------------------------------
-- Section builders
-------------------------------------------------------------------------------

local function CreateCurrentProfileSection(parent, yOffset, refreshAll)
    local W = ns.Widgets
    local db = dtns.Addon.db
    local newProfileName = ""

    local header = W.CreateHeader(parent, "Current Profile")
    AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - SPACING_AFTER_HEADER

    local desc = W.CreateDescription(parent,
        "Profiles allow you to save different configurations for different characters.")
    AnchorWidget(desc, parent, yOffset)
    yOffset = yOffset - desc:GetHeight() - SPACING_BETWEEN_WIDGETS

    local activeDropdown = W.CreateDropdown(parent, {
        label = "Active Profile",
        tooltip = "Select the active profile",
        values = GetProfileValues,
        get = function() return db:GetCurrentProfile() end,
        set = function(value)
            db:SetProfile(value)
            refreshAll()
        end,
    })
    AnchorWidget(activeDropdown, parent, yOffset)
    yOffset = yOffset - activeDropdown:GetHeight() - SPACING_BETWEEN_WIDGETS

    local newProfileInput = W.CreateTextInput(parent, {
        label = "New Profile Name",
        tooltip = "Enter a name for a new profile",
        get = function() return "" end,
        set = function(value) newProfileName = value end,
    })
    AnchorWidget(newProfileInput, parent, yOffset)
    yOffset = yOffset - newProfileInput:GetHeight() - SPACING_BETWEEN_WIDGETS

    local createButton = W.CreateButton(parent, {
        text = "Create Profile",
        tooltip = "Create a new profile with the entered name",
        onClick = function()
            if newProfileName and newProfileName ~= "" then
                db:SetProfile(newProfileName)
                newProfileName = ""
                if newProfileInput.Refresh then
                    newProfileInput:Refresh()
                end
                refreshAll()
            end
        end,
    })
    AnchorWidget(createButton, parent, yOffset)
    yOffset = yOffset - createButton:GetHeight()

    return yOffset, activeDropdown
end

local function CreateActionsSection(parent, yOffset, refreshAll)
    local W = ns.Widgets
    local db = dtns.Addon.db

    yOffset = yOffset - SPACING_BETWEEN_SECTIONS

    local header = W.CreateHeader(parent, "Profile Actions")
    AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - SPACING_AFTER_HEADER

    local copyDropdown = W.CreateDropdown(parent, {
        label = "Copy From",
        tooltip = "Copy settings from another profile",
        values = GetOtherProfileValues,
        get = function() return "" end,
        set = function(value)
            db:CopyProfile(value)
            if ns.RefreshVisibleWidgets then
                ns.RefreshVisibleWidgets()
            end
            refreshAll()
        end,
    })
    AnchorWidget(copyDropdown, parent, yOffset)
    yOffset = yOffset - copyDropdown:GetHeight() - SPACING_BETWEEN_WIDGETS

    local resetButton = W.CreateButton(parent, {
        text = "Reset Profile",
        tooltip = "Reset the current profile to default settings",
        onClick = function()
            StaticPopup_Show("DRAGONTOAST_OPTIONS_RESET_PROFILE")
        end,
    })
    AnchorWidget(resetButton, parent, yOffset)
    yOffset = yOffset - resetButton:GetHeight() - SPACING_BETWEEN_WIDGETS

    local deleteDropdown = W.CreateDropdown(parent, {
        label = "Delete Profile",
        tooltip = "Delete a profile",
        values = GetOtherProfileValues,
        get = function() return "" end,
        set = function(value)
            local dialog = StaticPopup_Show("DRAGONTOAST_OPTIONS_DELETE_PROFILE", value)
            if dialog then
                dialog.data = value
            end
        end,
    })
    AnchorWidget(deleteDropdown, parent, yOffset)
    yOffset = yOffset - deleteDropdown:GetHeight()

    return yOffset, copyDropdown, deleteDropdown
end

-------------------------------------------------------------------------------
-- Build the Profiles tab content
-------------------------------------------------------------------------------

local function CreateContent(parent)
    local db = dtns.Addon.db
    local yOffset = PADDING_TOP

    -- Forward-declare widget refs for refresh closure
    local activeDropdown, copyDropdown, deleteDropdown

    local function RefreshProfileWidgets()
        local widgets = { activeDropdown, copyDropdown, deleteDropdown }
        for _, widget in pairs(widgets) do
            if widget and widget.Refresh then
                widget:Refresh()
            end
        end
        if ns.RefreshVisibleWidgets then
            ns.RefreshVisibleWidgets()
        end
    end

    -- Current Profile section
    yOffset, activeDropdown = CreateCurrentProfileSection(parent, yOffset, RefreshProfileWidgets)

    -- Profile Actions section
    yOffset, copyDropdown, deleteDropdown = CreateActionsSection(parent, yOffset, RefreshProfileWidgets)

    parent:SetHeight(math_abs(yOffset) + PADDING_BOTTOM)

    -- Register AceDB profile callbacks (only once, CreateContent is called via lazy init)
    db.RegisterCallback(db, "OnProfileChanged", RefreshProfileWidgets)
    db.RegisterCallback(db, "OnProfileCopied", RefreshProfileWidgets)
    db.RegisterCallback(db, "OnProfileReset", RefreshProfileWidgets)
    db.RegisterCallback(db, "OnNewProfile", RefreshProfileWidgets)
    db.RegisterCallback(db, "OnProfileDeleted", RefreshProfileWidgets)
end

-------------------------------------------------------------------------------
-- Register tab
-------------------------------------------------------------------------------

ns.Tabs = ns.Tabs or {}
ns.Tabs[#ns.Tabs + 1] = {
    id = "profiles",
    label = "Profiles",
    order = 6,
    createFunc = CreateContent,
}
