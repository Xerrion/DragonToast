-------------------------------------------------------------------------------
-- ProfilesTab.lua
-- Profile management tab: switch, create, copy, reset, delete profiles
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...
local LC = ns.LayoutConstants

-------------------------------------------------------------------------------
-- Cached globals
-------------------------------------------------------------------------------

local pairs = pairs
local table_sort = table.sort
local math_abs = math.abs
local StaticPopup_Show = StaticPopup_Show
local StaticPopupDialogs = StaticPopupDialogs

-------------------------------------------------------------------------------
-- Localization
-------------------------------------------------------------------------------

local L = ns.L

-------------------------------------------------------------------------------
-- Namespace references
-------------------------------------------------------------------------------

local dtns

-------------------------------------------------------------------------------
-- Static popup dialogs (defined at file scope)
-------------------------------------------------------------------------------

StaticPopupDialogs["DRAGONTOAST_OPTIONS_RESET_PROFILE"] = {
    text = L["Are you sure you want to reset the current profile?"],
    button1 = L["Reset"],
    button2 = L["Cancel"],
    OnAccept = function()
        dtns.Addon.db:ResetProfile()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["DRAGONTOAST_OPTIONS_DELETE_PROFILE"] = {
    text = L["Are you sure you want to delete the profile \"%s\"?"],
    button1 = L["Delete"],
    button2 = L["Cancel"],
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
-- Builds the "Current Profile" UI section inside the given parent container.
-- The section includes a header, description, an active-profile
-- dropdown, an input for a new profile name, and a create button.
-- @param parent The parent UI frame to which the section widgets are attached.
-- @param yOffset The starting vertical offset (top-down) where the
--   section should be anchored; returned updated for subsequent layout.
-- @param refreshAll Function called after profile changes to refresh relevant widgets and UI state.
-- @return number The updated vertical offset after placing the section's widgets.
-- @return table The active profile dropdown widget.

local function CreateCurrentProfileSection(parent, yOffset, refreshAll)
    local W = ns.Widgets
    local db = dtns.Addon.db
    local newProfileName = ""

    local header = W.CreateHeader(parent, L["Current Profile"])
    LC.AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - LC.SPACING_AFTER_HEADER

    local descText = L["Profiles allow you to save different configurations for different characters."]
    local desc = W.CreateDescription(parent, descText)
    LC.AnchorWidget(desc, parent, yOffset)
    yOffset = yOffset - desc:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

    local activeDropdown = W.CreateDropdown(parent, {
        label = L["Active Profile"],
        tooltip = L["Select the active profile"],
        values = GetProfileValues,
        get = function() return db:GetCurrentProfile() end,
        set = function(value)
            db:SetProfile(value)
            refreshAll()
        end,
    })
    LC.AnchorWidget(activeDropdown, parent, yOffset)
    yOffset = yOffset - activeDropdown:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

    local newProfileInput = W.CreateTextInput(parent, {
        label = L["New Profile Name"],
        tooltip = L["Enter a name for a new profile"],
        get = function() return "" end,
        set = function(value) newProfileName = value end,
    })
    LC.AnchorWidget(newProfileInput, parent, yOffset)
    yOffset = yOffset - newProfileInput:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

    local createButton = W.CreateButton(parent, {
        text = L["Create Profile"],
        tooltip = L["Create a new profile with the entered name"],
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
    LC.AnchorWidget(createButton, parent, yOffset)
    yOffset = yOffset - createButton:GetHeight()

    return yOffset, activeDropdown
end

-- Builds the "Profile Actions" UI section with controls to copy from
-- another profile, reset the current profile, and delete another
-- profile.
-- @param refreshAll Function called to refresh profile-related widgets after changes.
-- @return number The updated vertical offset after laying out the section.
-- @return table The dropdown widget used to select a profile to copy from.
-- @return table The dropdown widget used to select a profile to delete.
local function CreateActionsSection(parent, yOffset, refreshAll)
    local W = ns.Widgets
    local db = dtns.Addon.db

    yOffset = yOffset - LC.SPACING_BETWEEN_SECTIONS

    local header = W.CreateHeader(parent, L["Profile Actions"])
    LC.AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - LC.SPACING_AFTER_HEADER

    local copyDropdown = W.CreateDropdown(parent, {
        label = L["Copy From"],
        tooltip = L["Copy settings from another profile"],
        values = GetOtherProfileValues,
        get = function() return "" end,
        set = function(value)
            db:CopyProfile(value)
            refreshAll()
        end,
    })
    LC.AnchorWidget(copyDropdown, parent, yOffset)
    yOffset = yOffset - copyDropdown:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

    local resetButton = W.CreateButton(parent, {
        text = L["Reset Profile"],
        tooltip = L["Reset the current profile to default settings"],
        onClick = function()
            StaticPopup_Show("DRAGONTOAST_OPTIONS_RESET_PROFILE")
        end,
    })
    LC.AnchorWidget(resetButton, parent, yOffset)
    yOffset = yOffset - resetButton:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

    local deleteDropdown = W.CreateDropdown(parent, {
        label = L["Delete Profile"],
        tooltip = L["Delete a profile"],
        values = GetOtherProfileValues,
        get = function() return "" end,
        set = function(value)
            local dialog = StaticPopup_Show("DRAGONTOAST_OPTIONS_DELETE_PROFILE", value)
            if dialog then
                dialog.data = value
            end
        end,
    })
    LC.AnchorWidget(deleteDropdown, parent, yOffset)
    yOffset = yOffset - deleteDropdown:GetHeight()

    return yOffset, copyDropdown, deleteDropdown
end

-------------------------------------------------------------------------------
-- Build the Profiles tab content
-------------------------------------------------------------------------------

local function CreateContent(parent)
    dtns = ns.dtns
    local db = dtns.Addon.db
    local yOffset = LC.PADDING_TOP

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

    parent:SetHeight(math_abs(yOffset) + LC.PADDING_BOTTOM)

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
    label = L["Profiles"],
    order = 6,
    createFunc = CreateContent,
}
