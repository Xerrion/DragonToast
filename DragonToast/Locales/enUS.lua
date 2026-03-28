-------------------------------------------------------------------------------
-- enUS.lua
-- English (US) locale - base/default
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------
local ADDON_NAME, ns = ... -- luacheck: ignore 211/ns
local L = LibStub("AceLocale-3.0"):NewLocale(ADDON_NAME, "enUS", true, true)
if not L then return end

-- DragonToast/Core/Init.lua
L["Loaded. Type /dt help for commands."] = true

-- DragonToast/Display/ToastFrame.lua
L["ilvl %s"] = true
L["You"] = true

-- DragonToast/Display/ToastManager.lua
L["+%s Honor"] = true
L["+%s Reputation"] = true
L["+%s XP"] = true
L["Drag to move"] = true

-- DragonToast/Listeners/MailListener_Shared.lua
L["Auction Sale"] = true
L["Auction Won"] = true
L["Mail"] = true
L["Mail - %s"] = true

-- DragonToast/Listeners/MessageBridge.lua
L["Disenchant"] = true
L["Greed"] = true
L["Need"] = true
L["Pass"] = true
L["Roll"] = true
L["Transmog"] = true
L["Unknown"] = true

-------------------------------------------------------------------------------
-- DragonToast_Options
-------------------------------------------------------------------------------

-- DragonToast_Options/Tabs/GeneralTab.lua
L["Clear Toasts"] = true
L["Continuously show random test toasts"] = true
L["Core Settings"] = true
L["Defer in Combat"] = true
L["Display a test toast notification"] = true
L["Enable DragonToast"] = true
L["Enable Sound"] = true
L["Enable or disable the addon"] = true
L["General"] = true
L["None"] = true
L["Play a sound when a toast appears"] = true
L["Queue toasts during combat and show them when combat ends"] = true
L["Remove all active toasts"] = true
L["Show Minimap Icon"] = true
L["Show Test Toast"] = true
L["Sound"] = true
L["Sound to play with each toast"] = true
L["Test Mode"] = true
L["Testing"] = true
L["Toggle the minimap button"] = true

-- DragonToast_Options/Tabs/FiltersTab.lua
L["Currency and Rewards"] = true
L["Filters"] = true
L["Loot Quality"] = true
L["Loot Sources"] = true
L["Minimum Quality"] = true
L["Only show toasts for items of this quality or higher"] = true
L["Show Currency"] = true
L["Show Gold"] = true
L["Show Group Loot"] = true
L["Show Honor"] = true
L["Show Mail"] = true
L["Show Quest Items"] = true
L["Show Reputation"] = true
L["Show Self Loot"] = true
L["Show XP"] = true
L["Show toasts for currency gains"] = true
L["Show toasts for experience gains"] = true
L["Show toasts for gold gains"] = true
L["Show toasts for honor gains"] = true
L["Show toasts for mail attachments"] = true
L["Show toasts for quest item pickups"] = true
L["Show toasts for reputation gains"] = true
L["Show toasts when group members receive loot"] = true
L["Show toasts when you loot items"] = true

-- DragonToast_Options/Tabs/DisplayTab.lua
L["Anchor"] = true
L["Anchor position reset to default."] = true
L["Content"] = true
L["Direction toasts stack from the anchor"] = true
L["Display"] = true
L["Display the item icon on toasts"] = true
L["Display the item level on toasts"] = true
L["Display the item quantity on toasts"] = true
L["Display the item type on toasts"] = true
L["Display who looted the item"] = true
L["Down"] = true
L["Gold Format"] = true
L["Grow Direction"] = true
L["Height of each toast in pixels"] = true
L["Horizontal Padding"] = true
L["Horizontal padding inside toasts in pixels"] = true
L["How to display gold amounts"] = true
L["Icons"] = true
L["Layout"] = true
L["Long (1 Gold 2 Silver 3 Copper)"] = true
L["Max Toasts"] = true
L["Maximum number of toasts visible at once"] = true
L["Padding"] = true
L["Reset Position"] = true
L["Reset the anchor to the default position"] = true
L["Short (1g 2s 3c)"] = true
L["Show Icon"] = true
L["Show Item Level"] = true
L["Show Item Type"] = true
L["Show Looter"] = true
L["Show Quantity"] = true
L["Show and unlock the toast anchor for repositioning"] = true
L["Space between toasts in pixels"] = true
L["Spacing"] = true
L["Toast Height"] = true
L["Toast Size"] = true
L["Toast Width"] = true
L["Unlock Anchor"] = true
L["Up"] = true
L["Vertical Padding"] = true
L["Vertical padding inside toasts in pixels"] = true
L["Width of each toast in pixels"] = true

-- DragonToast_Options/Tabs/AnimationTab.lua
L["Animation"] = true
L["Animation style for toast entrance"] = true
L["Animation style for toast exit"] = true
L["Animation to draw attention to high-quality items"] = true
L["Attention"] = true
L["Attention Animation"] = true
L["Attention Delay"] = true
L["Attention Min Quality"] = true
L["Attention Repeat Count"] = true
L["Delay in seconds before the attention animation starts"] = true
L["Distance in pixels the toast travels during entrance"] = true
L["Distance in pixels the toast travels during exit"] = true
L["Duration of the entrance animation in seconds"] = true
L["Duration of the exit animation in seconds"] = true
L["Enable Animations"] = true
L["Enable or disable all toast animations"] = true
L["Entrance"] = true
L["Entrance Animation"] = true
L["Entrance Distance"] = true
L["Entrance Duration"] = true
L["Exit"] = true
L["Exit Animation"] = true
L["Exit Distance"] = true
L["Exit Duration"] = true
L["Hold"] = true
L["Hold Duration"] = true
L["How long the toast stays visible before exiting"] = true
L["Minimum item quality required to trigger the attention animation"] = true
L["Number of times the attention animation repeats"] = true
L["Pause on Hover"] = true
L["Pause toast fade-out when hovering to read tooltips"] = true
L["Slide"] = true
L["Slide Speed"] = true
L["Speed of the slide animation when toasts reposition"] = true

-- DragonToast_Options/Tabs/AppearanceTab.lua
L["Add a quality-colored glow effect"] = true
L["Appearance"] = true
L["Apply a preset appearance theme"] = true
L["Background"] = true
L["Background Alpha"] = true
L["Background Color"] = true
L["Background Texture"] = true
L["Border Inset"] = true
L["Border Size"] = true
L["Border Texture"] = true
L["Border and Glow"] = true
L["Color the border based on item quality"] = true
L["Font"] = true
L["Font Outline"] = true
L["Font face for toast text"] = true
L["Glow Texture"] = true
L["Glow Width"] = true
L["Glowing Border"] = true
L["Icon"] = true
L["Icon Size"] = true
L["Inset of the border from the toast edge"] = true
L["Monochrome"] = true
L["Monochrome Outline"] = true
L["Opacity of the toast background"] = true
L["Outline"] = true
L["Outline style for text"] = true
L["Preset"] = true
L["Primary Font Size"] = true
L["Quality Border"] = true
L["Quality Glow"] = true
L["Secondary Font Size"] = true
L["Size of secondary text"] = true
L["Size of the item icon on toasts"] = true
L["Size of the main text"] = true
L["Skin Preset"] = true
L["Texture for the glowing border"] = true
L["Texture for the toast background"] = true
L["Texture for the toast border"] = true
L["Thick Outline"] = true
L["Thickness of the toast border"] = true
L["Toast background color"] = true
L["Width of the quality glow effect"] = true

-- DragonToast_Options/Tabs/ProfilesTab.lua
L["Active Profile"] = true
L["Are you sure you want to delete the profile \"%s\"?"] = true
L["Are you sure you want to reset the current profile?"] = true
L["Cancel"] = true
L["Copy From"] = true
L["Copy settings from another profile"] = true
L["Create Profile"] = true
L["Create a new profile with the entered name"] = true
L["Current Profile"] = true
L["Delete"] = true
L["Delete Profile"] = true
L["Delete a profile"] = true
L["Enter a name for a new profile"] = true
L["New Profile Name"] = true
L["Profile Actions"] = true
L["Profiles"] = true
L["Profiles allow you to save different configurations for different characters."] = true
L["Reset"] = true
L["Reset Profile"] = true
L["Reset the current profile to default settings"] = true
L["Select the active profile"] = true
