<div align="center">
<img src="icon.png" width="400" />
</div>

# DragonToast

*Every drop deserves a toast — a dragon-forged loot feed for your adventures*

[![Latest Release](https://img.shields.io/github/v/release/Xerrion/DragonToast?style=for-the-badge)](https://github.com/Xerrion/DragonToast/releases/latest)
[![License](https://img.shields.io/github/license/Xerrion/DragonToast?style=for-the-badge)](LICENSE)
[![WoW Versions](https://img.shields.io/badge/WoW-TBC%20Anniversary%20%C2%B7%20Retail-blue?style=for-the-badge&logo=battledotnet)](https://worldofwarcraft.blizzard.com/)
[![Lint](https://img.shields.io/github/actions/workflow/status/Xerrion/DragonToast/lint.yml?style=for-the-badge&label=lint)](https://github.com/Xerrion/DragonToast/actions)
[![CurseForge](https://img.shields.io/badge/CurseForge-coming%20soon-F16436?style=for-the-badge&logo=curseforge)](https://www.curseforge.com/wow/addons/dragontoast)

</div>

---

## 🐉 Features

- Animated toast notifications for all loot types — items, gold, currency, quest items, and XP gains
- Quality-colored item names with configurable minimum quality filter
- Stacking feed with configurable max toasts and growth direction (up/down)
- Smooth entrance, pop, and exit animations
- Duplicate stacking (x2, x3…) and consecutive XP gain aggregation
- ElvUI skin matching — automatically uses ElvUI fonts, textures, and borders when detected
- Toggleable toast info: icon, item level, type/subtype, looter name, quantity
- Shift-click to link items in chat, hover for tooltip
- Combat deferral — queue toasts during combat, flush when combat ends
- Optional loot sounds via LibSharedMedia
- Minimap icon with quick-access controls (left-click config, right-click toggle, shift-click test)
- Full LibSharedMedia-3.0 support for fonts, textures, and sounds

---

## 🎮 Supported Versions

| Version | Interface | Status |
|:--------|:----------|:-------|
| TBC Anniversary | 20505 | ✅ Primary |
| Retail | 110207 | ✅ Secondary |

---

## 📦 Installation

### Download

<div align="center">

[![CurseForge](https://img.shields.io/badge/CurseForge-Download-F16436?style=for-the-badge&logo=curseforge)](https://www.curseforge.com/wow/addons/dragontoast)
[![Wago](https://img.shields.io/badge/Wago-Download-C1272D?style=for-the-badge&logo=wago)](https://addons.wago.io/addons/dragontoast)
[![GitHub](https://img.shields.io/badge/GitHub-Releases-181717?style=for-the-badge&logo=github)](https://github.com/Xerrion/DragonToast/releases/latest)

</div>

### Manual Install

1. Download the latest release from one of the sources above
2. Extract the `DragonToast` folder into your AddOns directory:
   ```
   World of Warcraft/_retail_/Interface/AddOns/DragonToast/
   ```
3. Restart WoW or type `/reload`

---

## ⌨️ Commands

All commands use the `/dt` prefix (or the full `/dragontoast`):

| Command | Description |
|:--------|:------------|
| `/dt` | Toggle addon on/off |
| `/dt config` | Open settings panel |
| `/dt lock` | Toggle anchor lock (drag to reposition) |
| `/dt test` | Show a test toast |
| `/dt clear` | Dismiss all active toasts |
| `/dt status` | Show current settings |
| `/dt help` | Show available commands |

---

<details>
<summary><h2>⚙️ Configuration</h2></summary>

- **General**: Enable/disable, minimum quality filter (Poor through Legendary), growth direction (up/down), max visible toasts (1-10), hold duration
- **Filters**: Self loot, party/raid loot, gold, currency, quest items, XP gains — each independently toggleable
- **Display**: Toast info toggles — item level, type/subtype, looter name, quantity badge
- **Appearance**: Fonts, textures, and colors customizable via LibSharedMedia-3.0 pickers
- **Sound**: Optional loot sound with LSM sound picker (off by default)
- **Behavior**: Combat deferral (queue during combat), anchor position (drag to move), minimap icon visibility
- **ElvUI**: Automatic skin matching when ElvUI is detected — uses ElvUI fonts, statusbar textures, and border colors

Access settings with `/dt config` or click the minimap icon.

</details>

---

## 🤝 Contributing

Contributions are welcome! Feel free to open an [issue](https://github.com/Xerrion/DragonToast/issues) or submit a [pull request](https://github.com/Xerrion/DragonToast/pulls).

1. Fork the repository
2. Create your feature branch (`git checkout -b feat/my-feature`)
3. Commit your changes (`git commit -m 'feat: add my feature'`)
4. Push to the branch (`git push origin feat/my-feature`)
5. Open a Pull Request

---

<div align="center">

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

Made with ❤️ by [Xerrion](https://github.com/Xerrion)

</div>
