# DragonToast - Agent Guidelines

Project-specific guidelines for DragonToast. See the parent `../AGENTS.md` for general WoW addon rules.

DragonToast is an animated loot feed addon for World of Warcraft. It shows a stacking feed of toast notifications when items are looted, with smooth animations and ElvUI skin matching.

**GitHub**: <https://github.com/Xerrion/DragonToast>

---

## Build, Lint & Test

### Linting

Luacheck is the only static analysis tool. Config lives in `.luacheckrc` (Lua 5.1, 120 char lines, `Libs/` excluded).

```bash
# Lint entire addon
luacheck .

# Lint a single file (preferred during development)
luacheck Core/Init.lua

# CI-style (matches GitHub Actions workflow)
luacheck . --no-color
```

CI runs Luacheck via `nebularg/actions-luacheck@v1` on `pull_request_target` to `master`. All warnings must pass before merge.

### Testing

**No automated test framework.** Test manually in-game:

1. `/dt test` - Show a single test toast
2. `/dt testmode` - Toggle continuous test toasts (2.5s interval) for live config preview
3. `/dt clear` - Dismiss all active toasts
4. `/dt config` - Open config window
5. Rapid-fire `/dt test` (10+ times) to stress the frame pool
6. Hover/unhover during animations to verify pause/resume
7. `/console scriptErrors 1` to surface Lua errors

### Packaging

No local build step. BigWigsMods packager runs automatically on tag push via `release.yml`. Release flow: merge to `master` -> release-please PR -> merge that PR -> tag -> packager publishes to CurseForge, Wago, GitHub Releases.

---

## Code Style

### Formatting

- **4 spaces** for indentation (no tabs)
- **120 character** max line length (enforced by Luacheck)
- Spaces around operators: `local x = 1 + 2`
- No trailing whitespace
- Dashes, not em-dashes or en-dashes, in comments and docs

### File Header

Every `.lua` file starts with this block:

```lua
-------------------------------------------------------------------------------
-- FileName.lua
-- Brief description of the file
--
-- Supported versions: TBC Anniversary, Retail, MoP Classic
-------------------------------------------------------------------------------
```

### Namespace and Imports

All files use the shared private namespace. Frequently-used WoW API globals are cached as locals at the top of each file, after the header.

```lua
local ADDON_NAME, ns = ...

-- Cached WoW API
local CreateFrame = CreateFrame
local GetItemInfo = GetItemInfo

-- Ace3 libraries via LibStub
local LSM = LibStub("LibSharedMedia-3.0")
```

### Naming Conventions

| Type               | Convention        | Example                             |
|--------------------|-------------------|-------------------------------------|
| Files              | PascalCase        | `ToastFrame.lua`                    |
| Global variables   | PascalCase        | `DragonToastDB`                     |
| Local variables    | camelCase         | `local frameCount`                  |
| Functions (public) | PascalCase        | `ns.ToastFrame.Acquire()`           |
| Functions (local)  | PascalCase        | `local function CreateToastFrame()` |
| Constants          | UPPER_SNAKE       | `local MAX_RETRIES = 5`             |
| Color codes        | COLOR_UPPER       | `ns.COLOR_GOLD`                     |
| Unused args        | Underscore prefix | `local _unused`                     |

### Error Handling

- **GetItemInfo may return nil** on first call. Always use the AceTimer retry pattern (up to 5 retries, 0.2s each).
- Defensive nil checks before calling optional module functions: `if ns.Module.Func then ns.Module.Func() end`
- Use `pcall` for operations that may not exist on all WoW versions.
- Cancel AceTimers before nullifying references, or closures fire on recycled frames.

---

## Architecture

| Layer     | Directory    | Responsibility                                         |
|-----------|--------------|--------------------------------------------------------|
| Core      | `Core/`      | Addon lifecycle, config, slash commands, minimap icon  |
| Listeners | `Listeners/` | Version-specific loot/XP/honor event parsing           |
| Display   | `Display/`   | Toast frames, animations, feed management, ElvUI skin  |
| Libs      | `Libs/`      | Embedded Ace3 + utility libraries (never lint or edit) |

### Namespace Sub-tables

All modules attach to `ns`: `ns.Addon`, `ns.ToastManager`, `ns.ToastFrame`, `ns.ToastAnimations`, `ns.ElvUISkin`, `ns.LootListener`, `ns.XPListener`, `ns.HonorListener`, `ns.MinimapIcon`, `ns.Print`.

### Ace3 Stack (mandatory, no raw alternatives)

| Library            | Replaces                                 |
|--------------------|------------------------------------------|
| AceEvent           | `frame:RegisterEvent()`                  |
| AceTimer           | `C_Timer.After()` / `C_Timer.NewTimer()` |
| AceDB              | Raw `SavedVariables`                     |
| AceConsole         | `SLASH_*` globals                        |
| LibSharedMedia-3.0 | Hardcoded font/texture paths             |

For local dev, Ace3 is a git submodule at `Libs/Ace3/`. The `.pkgmeta` externals only resolve during CI packaging.

### Version-Specific Loading

Three target versions: TBC Anniversary (20505, primary), MoP Classic (50502/50503), and Retail (110207, secondary).

Version-specific files load via BigWigsMods packager comment directives in the TOC (`#@retail@` / `#@tbc-anniversary@` / `#@version-mists@`). Do NOT use `## Interface-*` mid-file directives. Locally, all listener files load; runtime guards in each version-specific listener ensure only the correct one initializes.

---

## Toast Lifecycle

1. Loot event -> `LootListener` / `XPListener` parses and calls `ToastManager.QueueToast(lootData)`
2. QueueToast -> Checks combat deferral and duplicate stacking, then calls `ShowToast()`
3. ShowToast -> `ToastFrame.Acquire()` gets frame from pool, `Populate()` fills it, `PlayLifecycle()` starts animation
4. PlayLifecycle -> Builds a `lib:Queue()`: entrance -> attention (optional, quality-gated) -> exit (with hold delay)
5. Queue completes -> `OnToastFinished()` -> `StopAll()` -> `Release()` returns frame to pool

Frames are recycled via `Acquire()` / `Release()`. `Release()` calls `ClearQueue()`, clears state fields, and has a pool duplication guard. Always call `StopAll()` before starting a new queue on an acquired frame.

---

## ElvUI Integration

When "Match ElvUI Style" is enabled: font face uses `E.media.normFont`, font size/outline respects user settings (not overridden), background is never overridden, border color uses `E.media.bordercolor` when quality border is off. `SkinToast()` runs after `PopulateToast()`.

---

## CI/CD

| Workflow         | Trigger                         | Purpose                                                          |
|------------------|---------------------------------|------------------------------------------------------------------|
| `lint.yml`       | `pull_request_target` to master | Luacheck (uses `pull_request_target` for release-please bot PRs) |
| `release-pr.yml` | `push` to master                | release-please creates/updates a Release PR                      |
| `release.yml`    | tag push or `workflow_dispatch` | BigWigsMods packager -> CurseForge, Wago, GitHub Releases        |

Branch protection on `master`: PRs required, Luacheck status check required, branches must be up to date, no force pushes. Squash merge only; auto-delete head branches.

---

## Known Gotchas

1. **GetItemInfo caching** - Returns nil on first call for uncached items. Use retry pattern.
2. **Localized loot patterns** - `CHAT_MSG_LOOT` strings are locale-dependent. Build patterns from Blizzard globals.
3. **AceTimer cleanup** - Cancel timers before nullifying references.
4. **ElvUI skin ordering** - `SkinToast()` must respect user Appearance settings, not override them.
5. **TOC conditional loading** - Use packager comment directives, not `## Interface:` mid-file.
6. **pull_request_target** - GitHub does not trigger `pull_request` for PRs from GITHUB_TOKEN. Use `pull_request_target`.
