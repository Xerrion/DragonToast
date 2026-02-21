# DragonToast - Agent Guidelines

## Overview
DragonToast is an animated loot feed addon for World of Warcraft.
It shows a stacking feed of toast notifications when items are looted, with smooth animations and ElvUI skin matching.

## Target Versions
- **Primary**: TBC Anniversary (2.5.5 / Interface 20505)
- **Secondary**: Retail (Interface 110207)

## Architecture
| Layer | Directory | Responsibility |
|-------|-----------|----------------|
| Core | `Core/` | Addon lifecycle, config, slash commands |
| Listeners | `Listeners/` | Version-specific loot event parsing |
| Display | `Display/` | Toast frames, animations, feed management, ElvUI skin |
| Libs | `Libs/` | Embedded Ace3 libraries |

## Version-Specific Files
- `Listeners/LootListener_TBC.lua` — TBC-only loot parsing
- `Listeners/LootListener_Retail.lua` — Retail-only loot parsing
- **DO NOT** use runtime version checks. Use separate files loaded via `.toc` conditionals.

## Namespace Pattern
All files use `local ADDON_NAME, ns = ...` to share a private namespace.
Sub-tables: `ns.ToastManager`, `ns.ToastFrame`, `ns.ToastAnimations`, `ns.ElvUISkin`, `ns.LootListener`

## Key Conventions
- 4 spaces indentation, 120 char max line length
- Cache WoW API globals as locals at file top
- All addon functions should be local (except AceAddon methods)
- Use AceEvent for event registration, AceDB for saved variables
