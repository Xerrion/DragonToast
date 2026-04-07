# DragonToast - Agent Guidelines

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

No local build step. BigWigsMods packager runs automatically via `packager.yml` (dispatched by `release.yml`). Release flow: merge to `master` -> release-please PR -> merge that PR -> tag + GitHub Release -> release.yml dispatches packager.yml -> packager publishes to CurseForge, Wago, GitHub Releases.

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

### Types
- Default to plain Lua 5.1 with no annotations
- Only add LuaLS annotations when the file already uses them or for public library APIs
- Keep annotations minimal and accurate; do not introduce new tooling

### Functions and Structure
- Keep functions under 50 lines; extract helpers when longer
- Prefer early returns over deep nesting
- Prefer composition over inheritance
- Keep logic separated by layer when possible: Core (WoW API), Engine (pure Lua),
  Data (tables), Presentation (UI)

---

## Architecture

| Layer     | Directory    | Responsibility                                         |
|-----------|--------------|--------------------------------------------------------|
| Core      | `Core/`      | Addon lifecycle, config, slash commands, minimap icon  |
| Listeners | `Listeners/` | Version-specific loot/XP/honor event parsing           |
| Display   | `Display/`   | Toast frames, animations, feed management, ElvUI skin  |
| Libs      | `Libs/`      | Embedded Ace3 + utility libraries (never lint or edit) |

### Namespace Sub-tables

All modules attach to `ns`: `ns.Addon`, `ns.ToastManager`, `ns.ToastFrame`, `ns.ToastAnimations`, `ns.ElvUISkin`, `ns.LootListener`, `ns.XPListener`, `ns.HonorListener`, `ns.MailListener`, `ns.MessageBridge`, `ns.ListenerUtils`, `ns.MinimapIcon`, `ns.Print`.

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

---

## CI/CD

| Workflow         | Trigger                         | Purpose                                                          |
|------------------|---------------------------------|------------------------------------------------------------------|
| `lint.yml`       | `pull_request_target` to master | Luacheck + busted tests via `Xerrion/wow-workflows` reusable workflow |
| `release.yml`    | `push` to master                | release-please PR via `Xerrion/wow-workflows`; dispatches `packager.yml` on release |
| `packager.yml`   | `workflow_dispatch` (from release.yml) | BigWigsMods packager via `Xerrion/wow-workflows` reusable workflow |
| `toc-update.yml` | Weekly schedule / manual        | Auto-bump TOC Interface versions via `Xerrion/wow-workflows` reusable workflow |

Branch protection on `master`: PRs required, Luacheck status check required, branches must be up to date, no force pushes. Squash merge only; auto-delete head branches.

---

## Known Gotchas

1. **GetItemInfo caching** - Returns nil on first call for uncached items. Use retry pattern.
2. **Localized loot patterns** - `CHAT_MSG_LOOT` strings are locale-dependent. Build patterns from Blizzard globals.
3. **AceTimer cleanup** - Cancel timers before nullifying references.
4. **ElvUI skin ordering** - `SkinToast()` must respect user Appearance settings, not override them.
5. **TOC conditional loading** - Use packager comment directives, not `## Interface:` mid-file.
6. **pull_request_target** - GitHub does not trigger `pull_request` for PRs from GITHUB_TOKEN. Use `pull_request_target`.

---

## GitHub Workflow

### Issues
- Title format: `[Bug]: description` / `[Feature]: description`
- Always apply: one `C-*` (category), one `A-*` (area), one `D-*` (difficulty), one `P-*` (platform) label
- Use the repo's GitHub issue templates (bug-report or feature-request)
- Add new issues to the appropriate project and set status to **"To triage"**

### GitHub Projects
- **DragonToast - Bugs**: project #6 (`C-Bug` issues)
- **DragonToast - Feature Requests**: project #7 (`C-Feature` issues)
- Status columns: **To triage → Backlog → Ready → In progress → In review → Done**
- Move status as work progresses: filed (To triage) → scoped (Backlog) → branch created (In progress) → PR open (In review) → merged (Done)

### Branching and PRs
- Branch from `master`: `feat/<number>-short-desc`, `fix/<number>-short-desc`, `refactor/<number>-short-desc`
- One PR per issue; reference `Closes #N` in the PR body
- Fill the PR template fully (type of change, testing, checklist)
- CI must pass (`gh pr checks <N> --repo Xerrion/DragonToast`) before merging
- Wait for CodeRabbit AI review to complete and address any findings before merging
- When replying to CodeRabbit review comments, always use `@coderabbitai` and always reply to the **specific comment thread** (not as a top-level PR comment)
- Squash merge only: `gh pr merge <N> --squash --delete-branch`
- **Never merge release-please PRs** (`chore(master): release X.Y.Z`) - the repo owner merges these manually

### Commits
- Conventional Commits: `feat:`, `fix:`, `refactor:`, `docs:`, `chore:`
- Reference issue numbers: `feat: show inventory item count on loot toasts (#151)`

---

## Working Agreement for Agents
- Addon-level AGENTS.md overrides root rules when present
- Do not add new dependencies without discussing trade-offs
- Run luacheck before and after changes
- If only manual tests exist, document what you verified in-game
- Verify changes in the game client when possible
- Keep changes small and focused; prefer composition over inheritance
- Use the `wow-addon` agent to verify WoW API signatures before implementation - never guess
- See the root `AGENTS.md` Skill Routing table for the full skill-loading matrix for `coder` delegations

---

## Communication Style

When responding to or commenting on issues, always write in **first-person singular** ("I")
as the repo owner -- never use "we" or "our team". Speak as if you are the developer personally.

**Writing style:**
- Direct, structured, solution-driven. Get to the point fast. Text is a tool, not decoration.
- Think in systems. Break things into flows, roles, rules, and frameworks.
- Bias toward precision. Concrete output, copy-paste-ready solutions, clear constraints. Low
  tolerance for fluff.
- Tone is calm and rational with small flashes of humor and self-awareness.
- When confident in a topic, become more informal and creative.
- When something matters, become sharp and focused.
