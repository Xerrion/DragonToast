# DragonToast - Agent Guidelines

Project-specific guidelines for DragonToast. See the parent `../AGENTS.md` for general WoW addon development rules.

---

## Overview

DragonToast is an animated loot feed addon for World of Warcraft.
*Every drop deserves a toast — a dragon-forged loot feed for your adventures.*

It shows a stacking feed of toast notifications when items are looted, with smooth animations and ElvUI skin matching.

**GitHub**: https://github.com/Xerrion/DragonToast

---

## Target Versions

| Version | Interface | TOC Directive | Listener File |
|---------|-----------|---------------|---------------|
| TBC Anniversary (Primary) | 20505 | `## Interface: 20505` | `LootListener_TBC.lua` |
| Retail (Secondary) | 110207 | `## Interface: 110207` | `LootListener_Retail.lua` |

Version-specific files are loaded via BigWigsMods packager comment directives (`#@retail@` / `#@non-retail@`) in the TOC, **not** via `## Interface-*` mid-file directives (those don't work).

**Local dev behavior**: `#@non-retail@` lines are comments, so the line AFTER them loads. Both listener files load locally, but TBC overrides Retail (loads second).

---

## Architecture

| Layer | Directory | Responsibility |
|-------|-----------|----------------|
| Core | `Core/` | Addon lifecycle, config, slash commands, minimap icon |
| Listeners | `Listeners/` | Version-specific loot/XP event parsing |
| Display | `Display/` | Toast frames, animations, feed management, ElvUI skin |
| Libs | `Libs/` | Embedded Ace3 + utility libraries |

### File Inventory

```
Core/
├── Init.lua              # AceAddon bootstrap with all mixins
├── Config.lua            # AceDB defaults + AceConfig options table
├── ConfigWindow.lua      # Standalone AceGUI config window
├── SlashCommands.lua     # /dt and /dragontoast commands
└── MinimapIcon.lua       # LibDBIcon + LibDataBroker minimap button

Listeners/
├── LootListener_TBC.lua      # CHAT_MSG_LOOT + CHAT_MSG_MONEY (TBC only)
├── LootListener_Retail.lua   # Same + CHAT_MSG_CURRENCY (Retail only)
└── XPListener.lua            # CHAT_MSG_COMBAT_XP_GAIN (both versions)

Display/
├── ToastFrame.lua        # Frame creation (BackdropTemplate), Populate, Acquire/Release pool
├── ToastAnimations.lua   # Entrance, Exit, Slide animations
├── ToastManager.lua      # Queue management, positioning, combat deferral
└── ElvUISkin.lua          # ElvUI detection and font/border matching
```

### Namespace Pattern

All files use the shared private namespace:
```lua
local ADDON_NAME, ns = ...
```

Sub-tables on `ns`:
- `ns.Addon` — AceAddon instance (set in Init.lua)
- `ns.ToastManager` — Queue, positioning, combat deferral
- `ns.ToastFrame` — Frame creation, pool, populate
- `ns.ToastAnimations` — Entrance/Exit/Slide animation control
- `ns.ElvUISkin` — ElvUI detection and skin application
- `ns.LootListener` — Loot event parsing (version-specific)
- `ns.XPListener` — XP event parsing
- `ns.MinimapIcon` — Minimap button management
- `ns.Print` — Prefixed chat output helper

---

## Ace3 Stack

DragonToast uses Ace3 extensively. **All** of these must be used — no raw alternatives:

| Library | Usage | Raw Alternative (DO NOT USE) |
|---------|-------|------------------------------|
| AceAddon | Addon lifecycle | — |
| AceEvent | Event registration | `frame:RegisterEvent()` |
| AceTimer | Timers | `C_Timer.After()` / `C_Timer.NewTimer()` |
| AceDB | SavedVariables + profiles | Raw `SavedVariables` |
| AceConfig | Options table registration | — |
| AceConfigDialog | Blizzard settings integration | — |
| AceGUI | Standalone config window | — |
| AceConsole | Slash command registration | `SLASH_*` globals |
| LibSharedMedia-3.0 | Font/texture/sound selection | Hardcoded paths |
| LibDataBroker-1.1 | Data source for minimap icon | — |
| LibDBIcon-1.0 | Minimap button | — |
| AceGUI-3.0-SharedMediaWidgets | LSM widget controls in config | — |

### Local Dev: Ace3 Submodule

`.pkgmeta` externals only work during CI packaging. For local dev, Ace3 is a git submodule at `Libs/Ace3/`. Other libs are regular directories.

---

## Toast Lifecycle

1. **Loot event** → `LootListener` / `XPListener` parses and calls `ToastManager.QueueToast(lootData)`
2. **QueueToast** → Checks combat deferral, duplicate stacking, then calls `ShowToast()`
3. **ShowToast** → `ToastFrame.Acquire()` gets frame from pool, `Populate()` fills it, `PlayLifecycle()` starts the animation queue
4. **PlayLifecycle** → Builds a `lib:Queue()` with chained entries: entrance → attention (optional, quality-gated) → exit (with hold delay)
5. **Queue completes** → `OnToastFinished()` → `StopAll()` → `Release()` returns frame to pool
6. **Hover** → `PauseQueue()` freezes animation + hold timer. Unhover → `ResumeQueue()` continues from exact pause point
7. **Click** → `Dismiss()` skips to exit animation via `SkipToEntry()`. **Shift-click** → Link item in chat.

### Frame Pool

Frames are recycled via `Acquire()` / `Release()`. Key safety measures:
- `Release()` calls `ClearQueue()` to stop animations and clear queue
- `Release()` clears `_exitEntryIndex` and `_noAnimTimer` fields
- `Release()` has a pool duplication guard
- `StopAll()` calls `lib:ClearQueue()` which stops animation + restores frame state
- `PlayLifecycle()` defensively calls `StopAll()` before starting new queue

### Animation System

Three animation phases managed by LibAnimate Queue:
- **Entrance**: Configurable entrance animation (slideInRight, fadeIn, etc.)
- **Attention** (optional): Quality-gated attention animation (pulse, bounce, heartBeat, etc.) — only plays for items meeting minimum quality threshold
- **Exit**: Configurable exit animation with hold delay (the delay IS the display duration)
- **Slide**: `SlideAnchor()` for smooth repositioning without interrupting the lifecycle queue

### Test Mode

`/dt testmode` or the General → Actions config toggle starts a repeating AceTimer (2.5s interval) that calls `ShowTestToast()` continuously. Useful for previewing settings changes in real-time. Runtime-only state — not persisted in SavedVariables. Auto-stops on `/dt clear`.

---

## ElvUI Integration

Detection: `ElvUI and ElvUI[1]` → store as `E`

When "Match ElvUI Style" is enabled:
- **Font face**: Uses `E.media.normFont` (ElvUI's typeface)
- **Font size/outline**: Respects user's Appearance settings (NOT overridden)
- **Background**: Never overridden — user's Appearance settings are final
- **Border color**: Uses `E.media.bordercolor` when quality border is off

---

## Config UI Structure

6 tabs + Profiles (AceDBOptions):

| Tab | Sections |
|-----|----------|
| General | Controls (enable, minimap, combat defer) → Actions (test, clear) |
| Filters | Item Quality → Loot Sources → Rewards |
| Display | Layout → Toast Size → Toast Content → Position |
| Animation | General → Timing → Entrance |
| Appearance | Font → Background (color, texture, opacity) → Border & Glow (quality, thickness, texture) → Icon → ElvUI |
| Sound | Notification Sound |

Config uses `type = "header"` separators and `type = "description"` intro text on every tab. LSM widget controls (`LSM30_Font`, `LSM30_Statusbar`, `LSM30_Sound`) for media selection.

---

## CI/CD

### Workflows

| File | Trigger | Purpose |
|------|---------|---------|
| `lint.yml` | `pull_request_target` to master | Luacheck (uses `pull_request_target` so it runs on release-please bot PRs) |
| `release.yml` | `push` to master | release-please creates/updates release PR; on tag push, BigWigsMods packager publishes |

### Branch Protection

- **Required check**: Luacheck (strict mode)
- **Merge method**: Squash only (merge commit and rebase disabled)
- **Auto-delete branches** on merge

### Secrets

| Secret | Purpose |
|--------|---------|
| `CF_API_KEY` | CurseForge upload |
| `WAGO_API_TOKEN` | Wago.io upload |

### Project IDs

| Platform | ID | TOC Field |
|----------|----|-----------|
| CurseForge | `1468628` | `X-Curse-Project-ID` |
| Wago | `E6gvQAN1` | `X-Wago-ID` |

---

## Local Development

### Install Location

Create a directory junction from the WoW addons folder to the repo:
```powershell
New-Item -ItemType Junction -Path "E:\World of Warcraft\_anniversary_\Interface\AddOns\DragonToast" -Target "F:\Repos\wow-addons\DragonToast"
```

### Testing

No automated tests. Test manually in-game:
1. `/dt test` — Show a test toast
2. `/dt` — Open config window
3. `/dt clear` — Dismiss all toasts
4. `/dt testmode` — Toggle continuous test toasts for live config preview
5. Rapid-fire `/dt test` (10+ times) to stress frame pool recycling
6. Hover/unhover during fade to test timer pause/resume
7. `/console scriptErrors 1` to catch Lua errors

---

## Known Gotchas

1. **GetItemInfo may return nil** on first call if item not cached — handled with AceTimer retry (up to 5 retries, 0.2s each)
2. **CHAT_MSG_LOOT patterns are localized** — parsing uses Lua pattern matching on the localized chat string
3. **AceTimer cancellation** — Always cancel timers before nullifying references, or the closure fires on a recycled frame
4. **ElvUI skin ordering** — `SkinToast()` runs after `PopulateToast()`. It must respect user's Appearance settings, not override them
5. **TOC conditional loading** — Mid-file `## Interface:` directives don't work. Use BigWigsMods packager comment directives (`#@retail@`, `#@non-retail@`)
6. **pull_request vs pull_request_target** — GitHub doesn't trigger `pull_request` workflows for PRs created by GITHUB_TOKEN (release-please). Use `pull_request_target` for lint workflows
