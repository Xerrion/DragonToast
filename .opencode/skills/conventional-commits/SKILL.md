---
name: conventional-commits
description: Create atomic conventional commits on feature branches for DragonToast.
compatibility: opencode
metadata:
  project: DragonToast
  topic: git
---

## What I do
- Enforce atomic commits and conventional commit messages.
- Ensure work happens on a non master branch that matches the change scope.
- Keep commit history clean and review friendly.

## When to use me
- Before staging files.
- When writing a commit message.
- When splitting a change into multiple commits.

## Workflow
1. Create a branch from master with a name that matches the change.
   - Examples: feat/honor-gains, fix/toast-stacking, chore/luacheck-globals
2. Make one logical change at a time.
3. Stage only the files for that change.
4. Run tests before and after the commit.
   - luacheck .
   - In game: /dt test, /dt testmode, /dt clear, hover pause, shift click, scriptErrors 1
5. Commit with conventional commit format.
   - type: short description
   - Optional scope in parentheses if helpful.

## Conventional types
- feat: new feature
- fix: bug fix
- refactor: code change with no behavior change
- docs: documentation only
- test: tests or test helpers
- chore: tooling or maintenance
- perf: performance improvements

## Rules for this repo
- Do not commit on master.
- Keep commits atomic and focused.
- Do not commit secrets.
- Do not amend after push unless explicitly requested.

## Why this matters
- Atomic commits make review and rollback easier.
- Conventional messages help release automation and changelogs.
