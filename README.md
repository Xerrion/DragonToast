<div align="center">

![Dragon Toast Logo](https://raw.githubusercontent.com/Xerrion/DragonToast/refs/heads/master/assets/dragon-toast.png)

# Dragon Toast

*Every drop deserves a toast: a dragon-forged loot feed for your adventures.*

[![Latest Release](https://img.shields.io/github/v/release/Xerrion/DragonToast?style=for-the-badge)](https://github.com/Xerrion/DragonToast/releases/latest)
[![License](https://img.shields.io/github/license/Xerrion/DragonToast?style=for-the-badge)](https://github.com/Xerrion/DragonToast/blob/master/LICENSE)
[![WoW Versions](https://img.shields.io/badge/WoW-TBC%20Anniversary%20%C2%B7%20MoP%20Classic%20%C2%B7%20Retail-blue?style=for-the-badge&logo=battledotnet)](https://worldofwarcraft.blizzard.com/)
[![CurseForge](https://img.shields.io/badge/CurseForge-1468628-F16436?style=for-the-badge&logo=curseforge)](https://www.curseforge.com/wow/addons/dragon-toast)
[![Wago](https://img.shields.io/badge/Wago-E6gvQAN1-C1272D?style=for-the-badge)](https://addons.wago.io/addons/dragon-toast)
[![Lint](https://img.shields.io/github/actions/workflow/status/Xerrion/DragonToast/lint.yml?style=for-the-badge&label=lint)](https://github.com/Xerrion/DragonToast/actions)

</div>

DragonToast displays clean, configurable toast notifications for in-game events: loot, gold, currency, quest items, XP,
honor, reputation, mail, and roll wins.

## 🐉 Features

- Toasts for items, gold, currency, quest items, XP, honor, reputation, mail, and roll wins
- Event-driven item loading and staggered queue for smooth performance during heavy loot sessions
- Stacking toasts that respect their full visible lifetime for natural feed growth
- Inventory item count badge displayed on item toasts (configurable)
- Configurable slot-based layout with adjustable stack direction, spacing, and max toast count
- Hover-pause - holding your cursor over a toast extends its visible lifetime for reading tooltips
- Built-in skin presets for quick visual restyling (Minimal, Dark, Neon, Parchment, and more)
- LibSharedMedia integration: full control over fonts, background textures, and borders
- Sound picker with bundled default notification sounds
- Defer-in-combat option to delay toast display until after combat ends
- DragonLoot AceComm integration: suppresses duplicate loot toasts and queues celebration toasts for roll wins
- Companion `DragonToast_Options` LoadOnDemand addon (embeds DragonWidgets shared library)
- 11 locales: English, German, Spanish (EU/MX), French, Italian, Korean, Portuguese, Russian, and Chinese (CN/TW)

## 🎮 Supported Versions

| Version         | Interface | Status       |
|:----------------|:----------|:-------------|
| TBC Anniversary | 20505     | ✅ Primary   |
| Mists Classic   | 50503     | ✅ Supported |
| Retail          | 120005    | ✅ Secondary |

## 📦 Installation

### Download

The recommended way to install DragonToast is via a management client like CurseForge or Wago.

- **CurseForge**: [Download](https://www.curseforge.com/wow/addons/dragon-toast)
- **Wago**: [Download](https://addons.wago.io/addons/dragon-toast)
- **GitHub**: [Latest Release](https://github.com/Xerrion/DragonToast/releases/latest)

### Manual Install

1. Download the latest release.
2. Extract the `DragonToast` and `DragonToast_Options` folders into your AddOns directory.
3. Restart World of Warcraft or type `/reload`.

## 🔌 Sub-addons

DragonToast is split into two parts to keep memory usage low:
- **DragonToast**: The main engine and listeners. Always loaded.
- **DragonToast_Options**: The configuration panel. Loads on demand only when you open the settings.

## 🍞 Toast Types

| Type | Description |
|:-----|:------------|
| Loot | Items looted by yourself or group members with quality filtering |
| XP | Experience gains with consecutive aggregation |
| Honor | Honor gains with faction-specific icon support |
| Reputation | Reputation gains with standing information |
| Mail | Notifications for new mail, auction sales, and won auctions |
| Currency | Track gold, badges, and other currency gains |
| Roll-Win | Celebration toasts for items won via rolls (requires DragonLoot) |

## ⌨️ Slash Commands

Use `/dt` or the alias `/dragontoast`.

| Command | Description |
|:--------|:------------|
| `/dt help` | Show the command list |
| `/dt toggle` | Toggle the addon on or off |
| `/dt config` | Open the options panel (aliases: `options`, `settings`) |
| `/dt lock` | Toggle the anchor frame for repositioning (aliases: `unlock`, `move`) |
| `/dt test` | Show a sample toast |
| `/dt reset` | Reset the toast anchor position |
| `/dt clear` | Dismiss all active toasts |
| `/dt status` | Show current configuration status |

## ⚙️ Configuration

Settings are stored in the `DragonToastDB` global and managed via the options panel:

| Tab | Settings |
|:----|:---------|
| General | Addon toggle, anchor lock, minimap icon, combat deferral, sound toggle |
| Filters | Quality threshold, loot sources, and individual toggles for each toast type |
| Display | Toast dimensions, slot count, stack direction, spacing, and bag count badge |
| Animation | Entrance/exit styles and durations, attention animations, and hover-pause |
| Appearance | Skin presets, fonts, backgrounds, quality borders, and ElvUI style matching |
| Profiles | Standard AceDB profile management (create, copy, reset) |

## 🔌 Integration API

DragonToast listens for AceComm-3.0 messages. Other addons can trigger or suppress toasts without a hard dependency.

| Message | Payload | Description |
|:--------|:--------|:------------|
| `DRAGONTOAST_SUPPRESS` | `source` (string) | Suppress normal loot toasts (120s safety timer) |
| `DRAGONTOAST_UNSUPPRESS` | `source` (string) | Clear suppression for the given source |
| `DRAGONTOAST_QUEUE_TOAST` | `data` (table) | Queue a toast with a custom data payload |

### Example Usage

```lua
-- Queue a custom toast via AceEvent-3.0
local payload = {
    itemName = "Sulfuras, Hand of Ragnaros",
    itemIcon = 132711,
    itemQuality = 5,
    quantity = 1,
    isSelf = true
}
LibStub("AceEvent-3.0"):SendMessage("DRAGONTOAST_QUEUE_TOAST", payload)
```

## 🌍 Localization

DragonToast is fully localized for 11 regions: enUS, deDE, esES, esMX, frFR, itIT, koKR, ptBR, ruRU, zhCN, and zhTW.
Translation contributions are always welcome via GitHub pull requests.

## 🤝 Contributing

Contributions are welcome! If you are a developer, please refer to the `AGENTS.md` file in the repository root for
detailed coding standards and architecture documentation. The project uses `luacheck` for linting and `busted` for
unit testing.

## ❤️ Support

If you would like to support the development of DragonToast, you can sponsor the project on [GitHub Sponsors](https://github.com/sponsors/Xerrion) or buy me a coffee on [Ko-fi](https://ko-fi.com/Xerrion).

## 📄 License

This project is licensed under the **MIT License**. See the [LICENSE](https://github.com/Xerrion/DragonToast/blob/master/LICENSE) file for details.

Made with ❤️ by [Xerrion]
