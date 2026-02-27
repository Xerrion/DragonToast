<div align="center">

![Dragon Toast Logo](https://raw.githubusercontent.com/DragonAddons/DragonLoot/refs/heads/master/assets/dragon-toast.png)

# Dragon Toast

*Every drop deserves a toast: a dragon-forged loot feed for your adventures.*  

[![Latest Release](https://img.shields.io/github/v/release/DragonAddons/DragonLoot?style=for-the-badge)](https://github.com/DragonAddons/DragonLoot/releases/latest)
[![License](https://img.shields.io/github/license/DragonAddons/DragonLoot?style=for-the-badge)](LICENSE)
[![WoW Versions](https://img.shields.io/badge/WoW-TBC%20Anniversary%20%C2%B7%20MoP%20Classic%20%C2%B7%20Retail-blue?style=for-the-badge&logo=battledotnet)](https://worldofwarcraft.blizzard.com/)
[![Lint](https://img.shields.io/github/actions/workflow/status/DragonAddons/DragonLoot/lint.yml?style=for-the-badge&label=lint)](https://github.com/DragonAddons/DragonLoot/actions)

</div>

## 🐉 Features

- Animated toast notifications for all loot types: items, gold, currency, quest items, XP, and honor gains
- Quality-colored item names with configurable minimum quality filter
- Stacking feed with configurable max toasts and growth direction (up/down)
- Smooth entrance, attention, and exit animations
- Duplicate stacking (x2, x3...) and consecutive XP gain aggregation
- ElvUI skin matching: automatically uses ElvUI fonts, textures, and borders when detected
- Toggleable toast info: icon, item level, type/subtype, looter name, quantity
- Shift-click to link items in chat, hover for tooltip
- Combat deferral: queue toasts during combat, flush when combat ends
- Optional loot sounds via LibSharedMedia
- Minimap icon with quick-access controls (left-click config, right-click toggle, shift-click test)
- Full LibSharedMedia-3.0 support for fonts, textures, and sounds

## 🎮 Supported Versions

| Version         | Interface              | Status       |
|:----------------|:-----------------------|:-------------|
| TBC Anniversary | 20505                  | ✅ Primary   |
| Mists Classic   | 50502, 50503           | ✅ Supported |
| Retail          | 110207, 120001, 120000 | ✅ Secondary |

## 📦 Installation

### Download

[![CurseForge](https://img.shields.io/badge/CurseForge-Download-F16436?style=for-the-badge&logo=curseforge)](https://www.curseforge.com/wow/addons/dragon-toast)
[![Wago](https://img.shields.io/badge/Wago-Download-C1272D?style=for-the-badge)](https://addons.wago.io/addons/dragon-toast)
[![GitHub](https://img.shields.io/badge/GitHub-Releases-181717?style=for-the-badge&logo=github)](https://github.com/DragonAddons/DragonLoot/releases/latest)

### Manual Install

1. Download the latest release from one of the sources above
2. Extract the `DragonToast` folder into your AddOns directory:

   ```text
   World of Warcraft/_retail_/Interface/AddOns/DragonToast/
   ```

3. Restart WoW or type `/reload`

## ⌨️ Commands

All commands use the `/dt` prefix (or the full `/dragontoast`):

| Command         | Description                             |
|:----------------|:----------------------------------------|
| `/dt`           | Toggle addon on/off                     |
| `/dt config`    | Open settings panel                     |
| `/dt lock`      | Toggle anchor lock (drag to reposition) |
| `/dt test`      | Show a test toast                       |
| `/dt testmode`  | Toggle continuous test toasts           |
| `/dt clear`     | Dismiss all active toasts               |
| `/dt reset`     | Reset anchor position to default        |
| `/dt status`    | Show current settings                   |
| `/dt help`      | Show available commands                 |

## ⚙️ Configuration

- **General**: Enable/disable addon, show minimap icon, defer toasts during combat, test mode toggle, show test toast, clear all toasts
- **Filters**: Minimum item quality (Poor through Legendary), loot sources (self, group), reward types (gold, currency, quest items, XP, honor)
- **Display**: Layout (max toasts, growth direction, spacing), toast size (width, height), toast content (icon, item level, type/subtype, quantity, looter name, gold format, text padding), position (unlock anchor, reset position)
- **Animation**: Enable/disable animations, timing (entrance duration, display duration, fade-out duration), entrance (animation style, distance), attention (animation style, minimum quality, repeat count, delay), exit (animation style, distance), repositioning speed
- **Appearance**: Font (face, primary/secondary size, outline), background (color, opacity, texture), border and glow (quality-colored border, thickness, texture, quality glow strip, glow width, glow texture), icon size, ElvUI style matching
- **Sound**: Enable/disable notification sound, sound effect picker via LibSharedMedia
- **Profiles**: AceDB profile management (create, copy, delete, reset)

Access settings with `/dt config` or click the minimap icon.

## 🔌 Integration API

DragonToast provides a generic AceEvent messaging API for other addons to control toast behavior:

| Message | Payload | Purpose |
|:--------|:--------|:--------|
| `DRAGONTOAST_SUPPRESS` | `source` (string) | Suppress item toasts while your addon handles loot |
| `DRAGONTOAST_UNSUPPRESS` | `source` (string) | Resume normal toast display |
| `DRAGONTOAST_QUEUE_TOAST` | `toastData` (table) | Queue a custom toast notification |

Messages are fire-and-forget via `AceEvent:SendMessage()` - no dependency on DragonToast required. See [AGENTS.md](AGENTS.md) for the full toast data contract and integration guide.

## 🤝 Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for setup, coding standards, and the PR process. All contributors are expected to follow the [Code of Conduct](CODE_OF_CONDUCT.md).

## ❤️ Support

If you would like to support Dragon Toast, you can sponsor the project on [GitHub Sponsors](https://github.com/sponsors/Xerrion) or buy me a coffee on [Ko-fi](https://ko-fi.com/Xerrion).

## 📄 License

This project is licensed under the **MIT License**. See the [LICENSE](https://github.com/DragonAddons/DragonLoot/blob/master/LICENSE) file for details.

Made with ❤️ by [Xerrion](https://github.com/Xerrion)
