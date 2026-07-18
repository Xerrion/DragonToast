# DragonToast AGENTS.md

## In-Game Test Commands

1. `/dt test` - show a single test toast
2. `/dt testmode` - toggle continuous test toasts (2.5s interval) for live config preview
3. `/dt clear` - dismiss all active toasts
4. `/dt config` - open config window
5. Rapid-fire `/dt test` (10+ times) to stress the frame pool
6. Hover/unhover during animations to verify pause/resume
7. `/console scriptErrors 1` to surface Lua errors

## Ace3 Stack

Mandatory; no raw alternatives.

| Library | Replaces |
|--------------------|------------------------------------------|
| AceEvent | `frame:RegisterEvent()` |
| AceTimer | `C_Timer.After()` / `C_Timer.NewTimer()` |
| AceDB | Raw `SavedVariables` |
| AceConsole | `SLASH_*` globals |
| LibSharedMedia-3.0 | Hardcoded font/texture paths |

For local dev, Ace3 is a git submodule at `Libs/Ace3/`. The `.pkgmeta` externals only resolve during CI packaging.

## Toast Lifecycle

1. Loot event -> `LootListener` / `XPListener` parses and calls `ToastManager.QueueToast(lootData)`
2. QueueToast -> Checks combat deferral and duplicate stacking, then calls `ShowToast()`
3. ShowToast -> `ToastFrame.Acquire()` gets frame from pool, `Populate()` fills it, `PlayLifecycle()` starts animation
4. PlayLifecycle -> Builds a `lib:Queue()`: entrance -> attention (optional, quality-gated) -> exit (with hold delay)
5. Queue completes -> `OnToastFinished()` -> `StopAll()` -> `Release()` returns frame to pool

Frames are recycled via `Acquire()` / `Release()`. `Release()` calls `ClearQueue()`, clears state fields, and has a pool duplication guard. Always call `StopAll()` before starting a new queue on an acquired frame.

## ElvUI Integration

When "Match ElvUI Style" is enabled: font face uses `E.media.normFont`, font size/outline respects user settings (not overridden), background is never overridden, border color uses `E.media.bordercolor` when quality border is off. `SkinToast()` runs after `PopulateToast()`.

## Cross-Addon Messaging API

DragonToast exposes a generic messaging API via `ns.MessageBridge` so external addons can suppress toasts and queue custom toast notifications without depending on internal implementation details.

### Generic Messages

| Message | Payload | Description |
|---------|---------|-------------|
| `DRAGONTOAST_SUPPRESS` | `source` (string) | Suppresses normal item toasts. Adds source to suppression set with a per-source 120s safety timer. |
| `DRAGONTOAST_UNSUPPRESS` | `source` (string) | Removes source from suppression set and cancels its safety timer. |
| `DRAGONTOAST_QUEUE_TOAST` | `toastData` (table) | Validates required fields and forwards to `ToastManager.QueueToast()`. |

### Toast Data Contract

Required fields:
- `itemName` (string) - display name
- `itemIcon` (number) - texture ID
- `itemQuality` (number) - Blizzard quality enum (0-7)

Optional fields (auto-filled if missing):
- `timestamp` (number) - defaults to `GetTime()` if omitted
- `itemLink` (string) - clickable item link
- `itemID` (number) - item ID for duplicate detection
- `itemLevel` (number) - item level
- `itemType` (string) - item type / subheading text
- `itemSubType` (string) - item sub-type
- `quantity` (number) - stack count
- `looter` (string) - name of the looter
- `isSelf` (boolean) - whether the looter is the local player
- `isCurrency` (boolean) - currency flag (bypasses suppression)
- `isRollWin` (boolean) - roll-win flag (bypasses suppression)
- `isXP` (boolean) - XP flag (bypasses suppression, enables XP stacking)
- `isHonor` (boolean) - honor flag (bypasses suppression, enables honor stacking)
- `copperAmount` (number) - non-negative money magnitude in copper
- `moneyDirection` (`"gain"` or `"loss"`) - money movement direction; omitted values remain gains for compatibility

### Suppression Mechanism

Suppression uses a multi-source set. Each source string maps to its own 120-second safety timer. Toasts are suppressed when any source is active (`next(suppressionSources) ~= nil`). Normal item toasts are blocked; XP, honor, currency, and roll-win toasts always pass through.

The safety timer auto-clears a source if the matching UNSUPPRESS message never arrives (e.g. crash or reload).

### Legacy Messages (backward compat)

| Legacy Message | Translates To |
|----------------|---------------|
| `DRAGONLOOT_LOOT_OPENED` | `DRAGONTOAST_SUPPRESS` with source `"DragonLoot"` |
| `DRAGONLOOT_LOOT_CLOSED` | `DRAGONTOAST_UNSUPPRESS` with source `"DragonLoot"` |
| `DRAGONLOOT_ROLL_WON` | `DRAGONTOAST_QUEUE_TOAST` (transforms rollData to lootData) |

These will be removed when all senders migrate to the generic API.

### Example: External Addon Integration

```lua
-- Suppress toasts while your custom loot frame is open
local AceEvent = LibStub("AceEvent-3.0")

-- When your loot frame opens
AceEvent:SendMessage("DRAGONTOAST_SUPPRESS", "MyLootAddon")

-- Queue a custom toast
AceEvent:SendMessage("DRAGONTOAST_QUEUE_TOAST", {
    itemName = "Thunderfury, Blessed Blade of the Windseeker",
    itemIcon = 134585,
    itemQuality = 5,
    itemLink = itemLink,
    quantity = 1,
    looter = UnitName("player"),
    isSelf = true,
})

-- When your loot frame closes
AceEvent:SendMessage("DRAGONTOAST_UNSUPPRESS", "MyLootAddon")
```

## Known Gotchas

1. **Localized loot patterns** - `CHAT_MSG_LOOT` strings are locale-dependent. Build patterns from Blizzard globals.
2. **AceTimer cleanup** - cancel timers before nullifying references, or closures fire on recycled frames.
3. **ElvUI skin ordering** - `SkinToast()` must respect user Appearance settings, not override them.

## Labels

| Label | Description |
| --- | --- |
| **Category** | |
| `C-Bug` | Something is broken |
| `C-Feature` | New feature or enhancement |
| `C-Performance` | Speed, memory, or frame rate |
| `C-Usability` | UX, accessibility, discoverability |
| `C-Code-Quality` | Refactor, cleanup, tech debt |
| `C-Documentation` | Docs, README, guides |
| `C-Localization` | Translation, locale strings |
| **Area** | |
| `A-Core` | Addon lifecycle, slash commands, minimap icon |
| `A-Toast` | Toast frames, animations, manager, display |
| `A-Listeners` | Event listeners (loot, XP, honor, mail, currency, rep) |
| `A-Options` | DragonToast_Options companion addon |
| `A-Config` | Config schema, defaults, presets |
| `A-Appearance` | Visual styling, fonts, textures, colors |
| `A-Integration` | Cross-addon messaging, ElvUI skin |
| `A-Localization` | Locale files, translations |
| `A-CI` | GitHub workflows, packaging, CI/CD |
| **Difficulty** | |
| `D-Good-First-Issue` | Good for newcomers |
| `D-Straightforward` | Clear path, minimal risk |
| `D-Complex` | Multiple files, needs design |
| `D-Expert` | Deep system knowledge required |
| **Platform** | |
| `P-Retail` | Retail (Dragonflight/TWW) |
| `P-TBC-Anniversary` | TBC Anniversary Classic |
| `P-MoP-Classic` | Mists of Pandaria Classic |
| `P-All-Versions` | Affects all supported versions |
| **Status** | |
| `S-Needs-Investigation` | Requires debugging or research |

## GitHub Projects

- **DragonToast - Bugs**: project #6 (`C-Bug` issues)
- **DragonToast - Feature Requests**: project #7 (`C-Feature` issues)
