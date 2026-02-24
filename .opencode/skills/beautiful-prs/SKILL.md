---
name: beautiful-prs
description: Create clear and useful pull requests for DragonToast.
compatibility: opencode
metadata:
  project: DragonToast
  topic: pull-request
---

## What I do
- Build PRs with a clear summary and testing section.
- Ensure the branch is ready and pushed.
- Assign the PR to the requested owner.

## When to use me
- After commits are complete and tests pass.
- Before opening a PR with gh.

## PR checklist
1. Confirm you are not on master.
2. Ensure the branch name matches the change.
3. Verify git status is clean.
4. Run tests.
   - luacheck .
   - In game: /dt test, /dt testmode, /dt clear, hover pause, shift click, scriptErrors 1
5. Push with upstream tracking.

## PR template
Use this body template:

```
## Summary
- bullet 1
- bullet 2
- bullet 3

## Testing
- luacheck .
- In game: /dt test, /dt testmode, /dt clear

## Notes
- mention migrations or config changes if any
```

## Why this matters
- A clear PR speeds up review and reduces back and forth.
- A testing section increases confidence.
