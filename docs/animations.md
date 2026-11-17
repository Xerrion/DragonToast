# Toast animation design

## Goal

Every accepted loot entry must either update an eligible duplicate, wait in FIFO order, or receive a visible toast. Bursts must preserve readable rows and continuous movement. Hover, visual effects, and frame reuse must not corrupt the layout or another toast's lifetime.

This design follows the burst investigation and the history of the entrance, hover, and duplicate fixes. It keeps the existing public message and toast data contracts.

## Assumptions and evidence

| Assumption | Classification | Decision and evidence |
| --- | --- | --- |
| Visible count is bounded and overflow is FIFO. | Fundamental | Preserve `maxToasts` and the index queue introduced in `11d1f9f`. |
| Newest visible entries belong nearest the anchor; growth direction is configurable. | Contract | Preserve active order and UP/DOWN layout. Make space before revealing the next entry. |
| Duplicate updates must not replay animations or extend lifetime. | Contract | Preserve the explicit decisions in `689fc89` and `0fcc912`, including the separate queued duplicate time window. |
| Hover keeps a toast accessible and does not pause other lifecycles. | Contract | Preserve the hover fixes in `ce1d0a6`, `fb75b9e`, and `61feaf3`. Reserve the exact physical position. |
| Stack movement and effects must share a frame anchor. | Inherited | Reject. Reproductions showed jumps, discarded movement, and scale-only effects ignoring layout updates. Parent and child frames have independent anchors. |
| An entrance must finish before its toast can move in the stack. | Inherited | Remove the workaround from `9e3daf8`/`b1ff4f1`; independent parent movement cannot overwrite the child's entrance offsets. |
| Exiting toasts must remain stationary. | Inherited | Remove. Their layout parents can move while the children fade, so occupied rows remain accounted for. |
| A hovered toast can be represented by a rounded row number. | Inherited | Reject. A toast can be hovered halfway between rows. |
| Every completion should immediately restart queue flushing. | Inherited | Reject. Concurrent completions bypassed the configured stagger. Use one pending admission timer. |
| The existing content, border, and icon hierarchy matters. | Fundamental | Preserve the layer relationships introduced in `9e3daf8` to fix z-fighting, and preserve ElvUI skin ordering. |
| Direct phase callbacks are required rather than a library queue. | Unknown historical rationale | Keep the existing phase structure. Its choice no longer affects layout correctness. |
| Every configured effect has identical transformed mouse behavior in every client. | Unverified | Keep mouse scripts on the same complete visual Button. Verify actual rendering and hit testing in-game. |

## Coordinate ownership

Each pooled toast consists of a private layout Frame under `UIParent` and the existing named visual Button beneath it. The Button contains the original background, border, icon, text, tooltip, and mouse handlers.

The layout Frame owns the stack anchor. LibAnimate only owns the Button's local offset, alpha, and scale. A pulse, fade, entrance, phase transition, or cancelled effect therefore cannot restore an old stack anchor or lose the remaining stack movement.

`_anchorY` always represents the sampled physical layout position. `_targetY` is the intended position. Movement retargets from its current interpolation rather than finishing the old movement instantly. A changed layout retargets all moving rows with a common start time and duration: interpolating two ordered layouts with sufficient spacing preserves their gaps.

Changing growth direction or row spacing is a geometry edit and applies the new layout directly. Such an explicit edit ends an active hover hold: a pin in the old geometry cannot safely constrain resized or reversed rows. Normal loot arrivals and removals animate within the existing coordinate system.

## Admission and hover

Unique new entries enter the same FIFO path whether they came from a listener, a combat flush, or a test command. The first entry can appear immediately. Before admitting another entry, the manager reserves the entry row and moves existing rows out of it. The new Button becomes visible only after that movement completes. Actual admissions also respect `queueStagger`.

Multiple completions share the existing admission timer. They do not cancel the delay and each reveal a replacement immediately. Queued duplicates are merged before admission; an eligible active duplicate is checked again when a queued entry is drained.

A hovered toast pins its exact physical coordinate. Layout planning proceeds outward from the anchor and leaves enough space around that coordinate. If reserving the entry row would require crossing the hovered toast, the new entry stays queued until hover ends or another removal creates room. Other lifecycles continue, and the manager can use space that is actually available below the pinned toast.

Hover during entrance remains ignored. Attention can finish while hovered; hold waits for the pointer to leave before exit. Hover can pause an already-running exit. Non-animated toasts preserve the remaining timer duration. Unhover resumes the lifecycle mode the toast actually started with, even if animation or hover options changed meanwhile.

## Completion and reuse

Lifecycle, effect, and hold-timer generations identify the callback owner. A cancelled timer or already-collected effect callback cannot finish a replacement phase or recycled frame. Manager completion also requires current active-list membership.

Release marks the toast pooled before hiding it, stops both motion systems, cancels timers, restores hover strata, hides the parent and child, and resets layout/effect state. Hide-triggered mouse leave cannot restart old work.

## Intentional visible changes

- Bursts enter sequentially after space is available, instead of several cards entering through the same row. A batch may take longer to finish appearing.
- New entries may wait while a hovered toast blocks the entry path; existing unrelated lifecycles continue.
- Fading cards can move with the stack until their exit completes.
- Changing row size, spacing, or growth direction ends hover and applies the new geometry immediately.
- Duplicate updates retain the original lifetime, as before.

The spacing guarantee concerns resting layout boxes and stack movement. Configured bounce, scale, and vertical entrance effects can deliberately extend visual content outside those boxes; the chosen effect is preserved.

## Verification

`spec/ToastAnimations_spec.lua` drives real ToastFrame, ToastAnimations, ToastManager, and the pinned LibAnimate engine through `spec/animation_harness.lua`. The harness supplies frame geometry, timers, mouse events, and deterministic time.

Regressions assert intermediate spacing, continuity, FIFO admission, stagger timing, phase-independent motion, hover behavior, timer cleanup, and pool reuse. The initial regression set failed against the previous production code in 13 cases, with no harness errors. Existing content and duplicate tests remain in place.

Run `git submodule update --init DragonToast/Libs/LibAnimate`, then `busted --verbose` and `luacheck .`. CI initializes the same pinned dependency. Final in-game validation should exercise rapid `/dt test` calls, hover/unhover during movement and exit, both growth directions, custom attention effects, live settings, and `/dt clear`.

Verification on 17 November 2026: 134 tests passed, including 30 animation integration cases. The full suite passed both with the original LibAnimate pin `274e2bc` and the concurrently updated checkout `8d47897`; their animation engine and definitions differ only in supported-client header comments. All 64 first-party Lua files passed lint. Recursive lint also includes externally populated DragonWidgets files with unrelated warnings; those dependencies were not modified by this fix. Workflow YAML and the scoped whitespace check passed. Actual WoW rendering was not run.
