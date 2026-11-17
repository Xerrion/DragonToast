# Options layout and live preview

The options panel uses DragonWidgets' sidebar and paired settings rows. A pinned preview remains visible while the settings below it scroll. Its sample and rarity controls change only the preview; they do not write to the active profile.

The preview caption shows the configured toast width and height, followed by the scale used to fit it inside the panel.

`ToastFrame.CreatePreview(parent)` builds anonymous frames with the same textures, layout, font, backdrop, glow, and ElvUI skin functions used by normal notifications. It bypasses the live pool, manager, test-toast generation, mouse handlers, and animation lifecycle. The parent owns its position, and oversized toasts scale down to fit. This preview is static; the existing test-toast actions remain available for checking animations in the game world.

Profile callbacks are registered when the options panel is first created, before any lazy profile-tab construction. Profile changes and presets refresh the selected controls and preview. Visiting another section refreshes its controls; the General, Appearance, and Animation refresh callbacks also restore their dependent disabled states.

Automated checks cover pool/lifecycle isolation, redraw from current settings, scaling, untouched saved anchors, local sample selection, early profile callbacks, and passing the selected preset key to the real preset implementation.

In game, open `/dt config`, change fonts, dimensions, icon visibility, opacity, borders, and presets, then switch profiles and revisit General/Animation. Check the preview stays pinned, its content follows the active profile, and normal notifications continue independently. Inspect narrow windows and localized labels with the shared settings layout. In-game rendering has not yet been verified.

## Customization organization

The goal is to let players find a setting by the thing they want to change, see the result immediately, and preserve explicitly customized profile values. The old placement of content, icon size, and queue timing was inherited organization rather than a behavioral requirement. Saved setting names and notification semantics are compatibility contracts. The user requested an intentional change to missing/new appearance defaults so the actual notifications match the modern options panel.

The sidebar follows this order:

| Page | Settings |
| --- | --- |
| General | Enablement, minimap, combat deferral, sound, and live test actions |
| Layout | Toast and icon size; internal and stack spacing; stack capacity and direction; exact screen position |
| Content | Icon and text visibility, quantities, inventory counts, looter names, and money format |
| Appearance | Presets, typography, background, borders, glow, icon crop, and ElvUI matching |
| Animation | Entrance, quality-based attention, hold, exit, and stack timing |
| Filters | Minimum quality, loot sources, currency, rewards, and losses |
| Profiles | Active profile, creation, copy, reset, and deletion |

Content settings still use the `display` table. Icon size still uses `appearance.iconSize`; queue stagger still uses `display.queueStagger`. No existing profile value is renamed or overwritten by moving its control.

New appearance controls expose border color and opacity, quality-border opacity, glow opacity, and icon crop. Zero opacity and zero crop are valid. The native **Modern (Default)** appearance uses the same dark panel color (RGB `0.035, 0.047, 0.065`, `98%` opacity), a flat one-pixel border (RGB `0.22, 0.28, 0.35`, fully opaque), and the locale-aware `Dragon UI` font without an outline. Quality-colored borders and glow start disabled. If glow is enabled, its modern defaults are two pixels at `20%` opacity. Icon crop remains `8%` per edge.

These are AceDB defaults for new or missing values; there is no theme migration that overwrites explicit saved colors, fonts, opacity, or ElvUI preferences. Existing profiles can select **Modern (Default)** to apply the complete theme. This changes typography, palette, border treatment, glow, and crop while preserving primary and secondary font sizes, icon size, toast dimensions, padding, content, filters, animations, and anchors. Other presets retain their previous field scope. Unmatched configurations display **Custom** instead of being mislabeled as the default.

`Dragon UI` takes its font from `ChatFontSmall:GetFont()`, then `STANDARD_TEXT_FONT`, then the historical Friz fallback. Media registration includes a language mask so LibSharedMedia accepts the client-selected font on Korean, Russian, and Chinese clients. Flat background, border, and status-bar media use the built-in white texture. The renderer has no configurable primary/muted text palette; item rarity, reward, secondary-text, and quantity-font behavior stay under the other renderer's established policy.

The fallback border controls apply when quality coloring is disabled; quality opacity applies when it is enabled. Glow controls apply only while the glow is enabled. ElvUI matching is available only when ElvUI is detected and defaults to off for new/missing settings. An explicitly saved enabled preference remains enabled, including after applying Modern. With matching enabled, the font face comes from ElvUI and the font picker is disabled, while text sizes, outline, and background remain configurable. ElvUI's font and border precedence is preserved. Disable **Match ElvUI Style** to see the native Modern font and border; the fallback border controls are disabled while ElvUI supplies them. These applicability states refresh after profile and preset changes.

Position controls accept signed decimal offsets from any of the nine screen anchor points. Invalid or infinite offsets leave the saved position intact. Reset restores `RIGHT`, `-20`, `0` through the manager's existing dot-call API. Editing these settings moves the live anchor only: the sample remains positioned by its preview host.

The change does not alter animation admission, frame pooling, hover behavior, reward/listener logic, platform detection, manifest compatibility, or local Camelot aliases. Their established behavior is preserved instead of being inferred from a desktop test harness. Rendering on the supported game clients remains an in-game verification step.

Additional automated checks cover renderer visual fallbacks, modern defaults without destructive theme migration, preset color-table isolation, locale-aware media registration, custom and zero-opacity rendering, textured and fallback glow paths, exact position validation/reset, retained saved keys after moving controls, explicit page order, and dependency refresh after replacing the active profile. In game, also test dragging the unlocked anchor, revisiting Layout, toggling ElvUI matching where available, and changing border/glow modes before switching profiles.
