# Options layout and live preview

The options panel uses DragonWidgets' sidebar and paired settings rows. A pinned preview remains visible while the settings below it scroll. Its sample and rarity controls change only the preview; they do not write to the active profile.

The preview caption shows the configured toast width and height, followed by the scale used to fit it inside the panel.

`ToastFrame.CreatePreview(parent)` builds anonymous frames with the same textures, layout, font, backdrop, glow, and ElvUI skin functions used by normal notifications. It bypasses the live pool, manager, test-toast generation, mouse handlers, and animation lifecycle. The parent owns its position, and oversized toasts scale down to fit. This preview is static; the existing test-toast actions remain available for checking animations in the game world.

Profile callbacks are registered when the options panel is first created, before any lazy profile-tab construction. Profile changes and presets refresh the selected controls and preview. Visiting another section refreshes its controls; the General and Animation refresh callbacks also restore their dependent disabled states.

Automated checks cover pool/lifecycle isolation, redraw from current settings, scaling, untouched saved anchors, local sample selection, early profile callbacks, and passing the selected preset key to the real preset implementation.

In game, open `/dt config`, change fonts, dimensions, icon visibility, opacity, borders, and presets, then switch profiles and revisit General/Animation. Check the preview stays pinned, its content follows the active profile, and normal notifications continue independently. Inspect narrow windows and localized labels with the shared settings layout. In-game rendering has not yet been verified.
