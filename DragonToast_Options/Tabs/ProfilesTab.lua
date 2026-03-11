-------------------------------------------------------------------------------
-- ProfilesTab.lua
-- Profile management tab: switch, create, copy, reset, delete profiles
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...
local LDF = _G.LibDragonFramework

-------------------------------------------------------------------------------
-- Cached globals
-------------------------------------------------------------------------------

local pairs = pairs
local table_sort = table.sort
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
-------------------------------------------------------------------------------

local function CreateCurrentProfileSection(parent, refreshAll)
    local db = dtns.Addon.db
    local newProfileName = ""

    local section = LDF.CreateSection(parent, L["Current Profile"])
    local stack = LDF.CreateStackLayout(section.content, "vertical")

    stack:AddChild(LDF.CreateDescription(section.content,
        L["Profiles allow you to save different configurations for different characters."]))

    local activeDropdown = LDF.CreateDropdown(section.content, {
        label = L["Active Profile"],
        tooltip = L["Select the active profile"],
        values = GetProfileValues,
        get = function() return db:GetCurrentProfile() end,
        set = function(value)
            db:SetProfile(value)
            refreshAll()
        end,
    })
    stack:AddChild(activeDropdown)

    local newProfileInput = LDF.CreateTextInput(section.content, {
        label = L["New Profile Name"],
        tooltip = L["Enter a name for a new profile"],
        get = function() return "" end,
        set = function(value) newProfileName = value end,
    })
    stack:AddChild(newProfileInput)

    stack:AddChild(LDF.CreateButton(section.content, {
        text = L["Create Profile"],
        tooltip = L["Create a new profile with the entered name"],
        onClick = function()
            if newProfileName and newProfileName ~= "" then
                db:SetProfile(newProfileName)
                newProfileName = ""
                newProfileInput:SetValue("")
                refreshAll()
            end
        end,
    }))

    return section, activeDropdown
end

local function CreateActionsSection(parent, refreshAll)
    local db = dtns.Addon.db

    local section = LDF.CreateSection(parent, L["Profile Actions"])
    local stack = LDF.CreateStackLayout(section.content, "vertical")

    local copyDropdown = LDF.CreateDropdown(section.content, {
        label = L["Copy From"],
        tooltip = L["Copy settings from another profile"],
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
    stack:AddChild(copyDropdown)

    stack:AddChild(LDF.CreateButton(section.content, {
        text = L["Reset Profile"],
        tooltip = L["Reset the current profile to default settings"],
        onClick = function()
            StaticPopup_Show("DRAGONTOAST_OPTIONS_RESET_PROFILE")
        end,
    }))

    local deleteDropdown = LDF.CreateDropdown(section.content, {
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
    stack:AddChild(deleteDropdown)

    return section, copyDropdown, deleteDropdown
end

-------------------------------------------------------------------------------
-- Build the Profiles tab content
-------------------------------------------------------------------------------

local function CreateContent(parent)
    dtns = ns.dtns
    local db = dtns.Addon.db
    local mainStack = LDF.CreateStackLayout(parent, "vertical")

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
    local currentSection
    currentSection, activeDropdown = CreateCurrentProfileSection(parent, RefreshProfileWidgets)
    mainStack:AddChild(currentSection)

    -- Profile Actions section
    local actionsSection
    actionsSection, copyDropdown, deleteDropdown = CreateActionsSection(parent, RefreshProfileWidgets)
    mainStack:AddChild(actionsSection)

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
