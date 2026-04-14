## [1.8.2](https://github.com/Xerrion/DragonToast/compare/1.8.1...1.8.2) (2026-02-25)

### ⚙️ Miscellaneous Tasks

* fix changelog list items ([#65](https://github.com/Xerrion/DragonToast/issues/65)) ([1c399f4](https://github.com/Xerrion/DragonToast/commit/1c399f41beacb7b0b8b07ddd63df7422190ece88))

## [3.3.0](https://github.com/Xerrion/DragonToast/compare/3.2.1...3.3.0) (2026-04-14)


### 🚀 Features

* stack toasts for their full visible lifetime, not a fixed window ([#163](https://github.com/Xerrion/DragonToast/issues/163)) ([#164](https://github.com/Xerrion/DragonToast/issues/164)) ([0fcc912](https://github.com/Xerrion/DragonToast/commit/0fcc912e3f2a0c55e2c8cae0e6d7ed06606b2a75))


### ⚙️ Miscellaneous Tasks

* increase default toast spacing from 4 to 8 pixels ([#161](https://github.com/Xerrion/DragonToast/issues/161)) ([#162](https://github.com/Xerrion/DragonToast/issues/162)) ([a5528ba](https://github.com/Xerrion/DragonToast/commit/a5528ba564522ab23fb4f61bda6cf34b6627d518))

## [3.2.1](https://github.com/Xerrion/DragonToast/compare/3.2.0...3.2.1) (2026-04-06)


### 🐛 Bug Fixes

* hide item bag count on other players' loot toasts ([#157](https://github.com/Xerrion/DragonToast/issues/157)) ([#158](https://github.com/Xerrion/DragonToast/issues/158)) ([2074d29](https://github.com/Xerrion/DragonToast/commit/2074d293e81a94687f7522bb6eb409c6b228b080))

## [3.2.0](https://github.com/Xerrion/DragonToast/compare/3.1.0...3.2.0) (2026-04-05)


### 🚀 Features

* embed DragonWidgets as shared widget library in DragonToast_Options ([#147](https://github.com/Xerrion/DragonToast/issues/147)) ([d306403](https://github.com/Xerrion/DragonToast/commit/d306403deed1c68dc682755827a6182471438df7))
* show inventory item count on loot toasts ([#151](https://github.com/Xerrion/DragonToast/issues/151)) ([#152](https://github.com/Xerrion/DragonToast/issues/152)) ([d35db07](https://github.com/Xerrion/DragonToast/commit/d35db07b82e1e1b0ad52b039d1d637681c185e87))


### 🐛 Bug Fixes

* correct DragonWidgets embedded library paths in DragonToast_Options.toc ([12bd6a6](https://github.com/Xerrion/DragonToast/commit/12bd6a671d3b9cd1afab83ab16efc566329840ab))
* localize all user-facing strings in main addon ([#150](https://github.com/Xerrion/DragonToast/issues/150)) ([bb37aac](https://github.com/Xerrion/DragonToast/commit/bb37aacca25574ba2edc53dc8a0451d59c8a30d7))


### 🚜 Refactor

* slot-based layout engine in ToastFrame ([#153](https://github.com/Xerrion/DragonToast/issues/153)) ([#154](https://github.com/Xerrion/DragonToast/issues/154)) ([f8f9800](https://github.com/Xerrion/DragonToast/commit/f8f9800c131a703579848b74193729bd75e5db18))


### ⚙️ Miscellaneous Tasks

* migrate to structured label taxonomy ([#145](https://github.com/Xerrion/DragonToast/issues/145)) ([d3c013d](https://github.com/Xerrion/DragonToast/commit/d3c013d5b5edd1faf61405a3f3062c0c0faa6b46))

## [3.1.0](https://github.com/Xerrion/DragonToast/compare/3.0.0...3.1.0) (2026-03-28)


### 🚀 Features

* **localization:** add Simplified Chinese (zhCN) translations, Notes, Category ([#143](https://github.com/Xerrion/DragonToast/issues/143)) ([572cebe](https://github.com/Xerrion/DragonToast/commit/572cebe5c01d088915e4bf96c0847c5da24b6fa6))


### 🐛 Bug Fixes

* **deDE:** restore English keys matching enUS.lua ([#140](https://github.com/Xerrion/DragonToast/issues/140)) ([#141](https://github.com/Xerrion/DragonToast/issues/141)) ([bdc09db](https://github.com/Xerrion/DragonToast/commit/bdc09db3be04f60ddb8035b09af7db25a6e6ee71))


### 🚜 Refactor

* convert locale keys to standard AceLocale format ([#144](https://github.com/Xerrion/DragonToast/issues/144)) ([38270ed](https://github.com/Xerrion/DragonToast/commit/38270ed91ab232f0b098e4be34b7decb1a8e31d7))

## [3.0.0](https://github.com/Xerrion/DragonToast/compare/2.1.3...3.0.0) (2026-03-15)


### ⚠ BREAKING CHANGES

* ns.ToastManager test functions moved to ns.TestToasts

### 🚀 Features

* add /dt reset command to restore default anchor position ([#17](https://github.com/Xerrion/DragonToast/issues/17)) ([03ae8fb](https://github.com/Xerrion/DragonToast/commit/03ae8fbe8efc8f7b44cf9c15aa12bc63ae213bed))
* add AceLocale-3.0 localization support ([#95](https://github.com/Xerrion/DragonToast/issues/95)) ([#117](https://github.com/Xerrion/DragonToast/issues/117)) ([0780b45](https://github.com/Xerrion/DragonToast/commit/0780b45a9e9570803331f86f43c101fdeb603fba))
* add built-in skin presets ([#88](https://github.com/Xerrion/DragonToast/issues/88)) ([#92](https://github.com/Xerrion/DragonToast/issues/92)) ([8c2a7c4](https://github.com/Xerrion/DragonToast/commit/8c2a7c4a87e5f07c39525b6a6b73f8557c7565de))
* add bundled default notification sounds ([#122](https://github.com/Xerrion/DragonToast/issues/122)) ([4930a55](https://github.com/Xerrion/DragonToast/commit/4930a5557efdcbf885a2df76185a860ed99a9aae))
* add configurable gold display format ([#49](https://github.com/Xerrion/DragonToast/issues/49)) ([485cffc](https://github.com/Xerrion/DragonToast/commit/485cffcdc759c613ba7f15d876a4dc8eecc56ea6))
* add honor gain toasts ([#55](https://github.com/Xerrion/DragonToast/issues/55)) ([cdf6ead](https://github.com/Xerrion/DragonToast/commit/cdf6eadc3d7a245260b22f3dfa99f42f36e3ee3a))
* add mail toast support ([#87](https://github.com/Xerrion/DragonToast/issues/87)) ([#89](https://github.com/Xerrion/DragonToast/issues/89)) ([05914a9](https://github.com/Xerrion/DragonToast/commit/05914a94929690a35a24fa4e47bd898da7b89808))
* add reputation gain toasts ([#93](https://github.com/Xerrion/DragonToast/issues/93)) ([#110](https://github.com/Xerrion/DragonToast/issues/110)) ([d39ae79](https://github.com/Xerrion/DragonToast/commit/d39ae79848584d3f0667d80f533f13c819484d7e))
* backdrop template, border/background textures, and test mode ([#35](https://github.com/Xerrion/DragonToast/issues/35)) ([bb02338](https://github.com/Xerrion/DragonToast/commit/bb02338aefccd914b899e17b4c81d02224da8762))
* codebase-wide refactoring for consistency and maintainability ([#127](https://github.com/Xerrion/DragonToast/issues/127)) ([7dfee81](https://github.com/Xerrion/DragonToast/commit/7dfee818a84fa305716928ba1c7478c657888b87))
* custom options panel replacing AceConfig ([#107](https://github.com/Xerrion/DragonToast/issues/107)) ([5d09ee8](https://github.com/Xerrion/DragonToast/commit/5d09ee8ae2b5cbd3c6fea82c97830faf78ec781d))
* DragonLoot cross-addon bridge via AceEvent messaging ([#70](https://github.com/Xerrion/DragonToast/issues/70)) ([7b4ed89](https://github.com/Xerrion/DragonToast/commit/7b4ed8945ec4a8aad0495ecef0df435a8d4c0089))
* drop support for tww ([8edabfa](https://github.com/Xerrion/DragonToast/commit/8edabfacdf50d873db1af36651b54813649a1564))
* enhanced border customization ([#75](https://github.com/Xerrion/DragonToast/issues/75)) ([37f1918](https://github.com/Xerrion/DragonToast/commit/37f19184bf70afec5195f4eb8371fb67afde1ca8))
* enhanced roll-won toast with winner name and roll details ([#71](https://github.com/Xerrion/DragonToast/issues/71)) ([e1c7b62](https://github.com/Xerrion/DragonToast/commit/e1c7b622be7e55e8f78bfc08df48eb5474341fc1))
* initial DragonToast implementation ([8bdbb76](https://github.com/Xerrion/DragonToast/commit/8bdbb76fcc6366e7aab37a42a6ad63009608169b))
* leverage LibAnimate queue APIs for optimized toast management ([#47](https://github.com/Xerrion/DragonToast/issues/47)) ([11d1f9f](https://github.com/Xerrion/DragonToast/commit/11d1f9f93d2c352480bf61af4ee256a4c2d41820))
* pause toast fade-out on mouseover ([#120](https://github.com/Xerrion/DragonToast/issues/120)) ([#138](https://github.com/Xerrion/DragonToast/issues/138)) ([ce1d0a6](https://github.com/Xerrion/DragonToast/commit/ce1d0a677a471d9ca8a8c80d12fed7a67d231eb5))
* replace AceConfig with custom LoadOnDemand options panel ([#109](https://github.com/Xerrion/DragonToast/issues/109)) ([2c98454](https://github.com/Xerrion/DragonToast/commit/2c98454334d5b1ef621a4440ece4acd979d108c9))
* rewrite animation system to use LibAnimate-1.0 ([#26](https://github.com/Xerrion/DragonToast/issues/26)) ([fa75719](https://github.com/Xerrion/DragonToast/commit/fa7571974862d6fb7f46b931f6f09f6a26f5c9bb))
* support mop classic ([#62](https://github.com/Xerrion/DragonToast/issues/62)) ([94433ca](https://github.com/Xerrion/DragonToast/commit/94433ca8d22014e625ad82350d1e42ebc4616186))


### 🐛 Bug Fixes

* add contents:write permission to release workflow ([7dd5274](https://github.com/Xerrion/DragonToast/commit/7dd5274e472c4f9a1bc744bc397c3172375c5e85))
* add missing currency loot messages ([#126](https://github.com/Xerrion/DragonToast/issues/126)) ([b4b9853](https://github.com/Xerrion/DragonToast/commit/b4b9853ffbefc4f75eb825a4abaf60f4fe71ecd8))
* add permissions to caller workflow ([#68](https://github.com/Xerrion/DragonToast/issues/68)) ([1ae82cb](https://github.com/Xerrion/DragonToast/commit/1ae82cbb556adb2491d760974ecbd246df86ddcd))
* address code review issues in MessageBridge ([#81](https://github.com/Xerrion/DragonToast/issues/81)) ([5843b81](https://github.com/Xerrion/DragonToast/commit/5843b8109bfcab9d0b126a64bc8327f8d696c56b))
* again ([#42](https://github.com/Xerrion/DragonToast/issues/42)) ([fe0f1bd](https://github.com/Xerrion/DragonToast/commit/fe0f1bdef1f53351839e09d516e6d69251147b32))
* animation glitches and deferred slide jumps ([#104](https://github.com/Xerrion/DragonToast/issues/104)) ([#105](https://github.com/Xerrion/DragonToast/issues/105)) ([b1ff4f1](https://github.com/Xerrion/DragonToast/commit/b1ff4f1c1b9081db87b5021f229d87859e82e533))
* clarify slash command help and toggle behavior ([#114](https://github.com/Xerrion/DragonToast/issues/114)) ([016ce4c](https://github.com/Xerrion/DragonToast/commit/016ce4caf96242986424da3678539c4f2e6468eb))
* consolidate duplicates, optimize pooling, and improve code quality ([#51](https://github.com/Xerrion/DragonToast/issues/51)) ([cb4cd1d](https://github.com/Xerrion/DragonToast/commit/cb4cd1db4f7513a75b18411c870a106749f1477f))
* correct branch name in CI workflows from main to master ([#6](https://github.com/Xerrion/DragonToast/issues/6)) ([c120433](https://github.com/Xerrion/DragonToast/commit/c1204335e3df86929bac243f2e0af1952f476e6b))
* correct hover-pause bugs and hoist hovered toast strata ([#120](https://github.com/Xerrion/DragonToast/issues/120)) ([#139](https://github.com/Xerrion/DragonToast/issues/139)) ([fb75b9e](https://github.com/Xerrion/DragonToast/commit/fb75b9efbd5e70082e20e88fd74585f014b00bc6))
* correct LibAnimate submodule path from DragonToasts to DragonToast ([#135](https://github.com/Xerrion/DragonToast/issues/135)) ([c431923](https://github.com/Xerrion/DragonToast/commit/c43192392ec35114360f17e191c73d7e7fa8e897))
* correct TOC packager directives ([#112](https://github.com/Xerrion/DragonToast/issues/112)) ([7ce6c6f](https://github.com/Xerrion/DragonToast/commit/7ce6c6ff80054de5f90647c410da50c02681f3e0))
* ElvUI skin now respects user Appearance settings ([#12](https://github.com/Xerrion/DragonToast/issues/12)) ([b7fd920](https://github.com/Xerrion/DragonToast/commit/b7fd920e211033e41c696a285211860eb3b330ab))
* exclude generate_sound.py from bundling ([3e96233](https://github.com/Xerrion/DragonToast/commit/3e96233e4520694cda9a3ae710e0e42bb7d67830))
* extract CurrencyListener and resolve currency icons ([#102](https://github.com/Xerrion/DragonToast/issues/102)) ([#103](https://github.com/Xerrion/DragonToast/issues/103)) ([3976b34](https://github.com/Xerrion/DragonToast/commit/3976b34bb8f17ca4f5b595f6c53ea099905b23ac))
* include Libs/embeds.xml in git tracking ([#39](https://github.com/Xerrion/DragonToast/issues/39)) ([e812fb2](https://github.com/Xerrion/DragonToast/commit/e812fb2f3ec3e15cfed08dfba38ad6dff2085fdf))
* lint workflow now triggers on release-please PRs ([#13](https://github.com/Xerrion/DragonToast/issues/13)) ([51aae3e](https://github.com/Xerrion/DragonToast/commit/51aae3eb716bdfbd1179478fc9800f54b3640679))
* load correct xml for LibDBIcon-1.0 ([#41](https://github.com/Xerrion/DragonToast/issues/41)) ([f346148](https://github.com/Xerrion/DragonToast/commit/f346148bc7ac82d681f1daae171d9293ee2a5f42))
* pop animation no longer overflows toast border ([#7](https://github.com/Xerrion/DragonToast/issues/7)) ([a89bb51](https://github.com/Xerrion/DragonToast/commit/a89bb51553d116cb6492573e29781befe02662b4))
* prevent invisible toasts from stale animation state and leaked timers ([#5](https://github.com/Xerrion/DragonToast/issues/5)) ([247236c](https://github.com/Xerrion/DragonToast/commit/247236cfa080d201284edecc3a59d5e8232ad118))
* remove unused string_format variable in XPListener ([#53](https://github.com/Xerrion/DragonToast/issues/53)) ([e7deb2f](https://github.com/Xerrion/DragonToast/commit/e7deb2fe39578ad8f59f932abbb60c72791ddd5d))
* resolve anchor z-order and position shift on lock ([#100](https://github.com/Xerrion/DragonToast/issues/100)) ([4d8f217](https://github.com/Xerrion/DragonToast/commit/4d8f2175ef5d7eb3ce14bcc01b037cce2f16d1fb))
* resolve invisible toast and slide animation snap bugs ([#24](https://github.com/Xerrion/DragonToast/issues/24)) ([b8f5f5d](https://github.com/Xerrion/DragonToast/commit/b8f5f5daa6440259db188b83f76244741436c2e8))
* resolve minimap icon toggle inverted logic ([#74](https://github.com/Xerrion/DragonToast/issues/74)) ([7389939](https://github.com/Xerrion/DragonToast/commit/738993949c3e2c4f4d631d7e00ad182c30972e1e))
* rework toast frame layout with child-frame hierarchy ([#83](https://github.com/Xerrion/DragonToast/issues/83)) ([9e3daf8](https://github.com/Xerrion/DragonToast/commit/9e3daf81ca37070b7e9220c40f2fc2887739c71b))
* show honor and mail filter status in /dt status output ([260c8ca](https://github.com/Xerrion/DragonToast/commit/260c8caf0a7141f6082046789fb82f4fb4ab672a))
* stacking accumulation bugs and add busted unit tests ([#85](https://github.com/Xerrion/DragonToast/issues/85)) ([f45f211](https://github.com/Xerrion/DragonToast/commit/f45f211f4870f02430271cf0c7fbc8b899bed961))
* **toast:** sync slide start anchor ([#59](https://github.com/Xerrion/DragonToast/issues/59)) ([fb174a9](https://github.com/Xerrion/DragonToast/commit/fb174a93161e3af30ecc617ffc38cb42514910eb))
* update AGENTS.md CI/CD docs to reflect consolidated workflow structure ([654eaa6](https://github.com/Xerrion/DragonToast/commit/654eaa6ade737adecaa0b4072a125e9357f581a1))
* use correct verion tags ([#124](https://github.com/Xerrion/DragonToast/issues/124)) ([ab0463c](https://github.com/Xerrion/DragonToast/commit/ab0463c650fc6d57fed428c261ca12c8ce594d16))
* use faction-specific honor icon constants (closes [#76](https://github.com/Xerrion/DragonToast/issues/76)) ([#84](https://github.com/Xerrion/DragonToast/issues/84)) ([38499c9](https://github.com/Xerrion/DragonToast/commit/38499c938a5de14b9853c8409dfe024ccfd73fae))
* use hardcoded honor icon FileDataIDs ([#91](https://github.com/Xerrion/DragonToast/issues/91)) ([d074976](https://github.com/Xerrion/DragonToast/commit/d074976bc3fb75c6359e6a8c84ceb67b4e928685))
* use latest libanimate ([#36](https://github.com/Xerrion/DragonToast/issues/36)) ([74597da](https://github.com/Xerrion/DragonToast/commit/74597da8127067d04c0fa2f7014569871ca7e2eb))
* use proper token? ([0671e7c](https://github.com/Xerrion/DragonToast/commit/0671e7cd1d2de26e9eda61913d1f4442564c34b8))
* workflow should now work? ([#21](https://github.com/Xerrion/DragonToast/issues/21)) ([eaa999f](https://github.com/Xerrion/DragonToast/commit/eaa999f6e3c424a48433d42270da8abcd48ae146))


### 🚜 Refactor

* convert to monorepo structure ([#116](https://github.com/Xerrion/DragonToast/issues/116)) ([689fc89](https://github.com/Xerrion/DragonToast/commit/689fc89f3b97760d29bbb66794838f2b515fea51))
* extract shared listener helpers into ListenerUtils ([#96](https://github.com/Xerrion/DragonToast/issues/96)) ([#98](https://github.com/Xerrion/DragonToast/issues/98)) ([0702a5b](https://github.com/Xerrion/DragonToast/commit/0702a5b24f154ec5ec6e1af471cded9caee6a501))
* rebranding ([#31](https://github.com/Xerrion/DragonToast/issues/31)) ([43f50c2](https://github.com/Xerrion/DragonToast/commit/43f50c26b3cf80228f0ed864b9e58edda55ad3ee))
* remove pop animation system ([#9](https://github.com/Xerrion/DragonToast/issues/9)) ([8d5bb93](https://github.com/Xerrion/DragonToast/commit/8d5bb938bdc2d1b61bbc60936974204029b34b84))
* reorganize config UI with headers and logical grouping ([#10](https://github.com/Xerrion/DragonToast/issues/10)) ([53079dd](https://github.com/Xerrion/DragonToast/commit/53079ddb3b30bd3c73e1833b96ac2a872ea78deb))


### ⚙️ Miscellaneous Tasks

* add scaled image ([#45](https://github.com/Xerrion/DragonToast/issues/45)) ([aa8a2cd](https://github.com/Xerrion/DragonToast/commit/aa8a2cdffaab290d7a6f3edfdf139e37b06daa9b))
* centered header content of the README ([#46](https://github.com/Xerrion/DragonToast/issues/46)) ([d567ea8](https://github.com/Xerrion/DragonToast/commit/d567ea8802c7311dcc19500e419ef7ed02c15685))
* codebase maintenance ([#73](https://github.com/Xerrion/DragonToast/issues/73)) ([58c4fc0](https://github.com/Xerrion/DragonToast/commit/58c4fc062992e342365761a4550954b25f18d1a9))
* customize release changelog ([#63](https://github.com/Xerrion/DragonToast/issues/63)) ([7f07d71](https://github.com/Xerrion/DragonToast/commit/7f07d7107c9bf28cd2f5676bd5a00fb1cc039492))
* fix changelog list items ([#65](https://github.com/Xerrion/DragonToast/issues/65)) ([1c399f4](https://github.com/Xerrion/DragonToast/commit/1c399f41beacb7b0b8b07ddd63df7422190ece88))
* fix wrong toc version ([5d9c56a](https://github.com/Xerrion/DragonToast/commit/5d9c56a51b5167f01d9533597ab86559a1dd24ea))
* i made a booboo ([4847783](https://github.com/Xerrion/DragonToast/commit/4847783ea7d4d3d33304296a61c6cab94e481280))
* initialize repository ([721993e](https://github.com/Xerrion/DragonToast/commit/721993e02b9fec77e891f96235988dbad99750d8))
* inline shared release workflows ([#130](https://github.com/Xerrion/DragonToast/issues/130)) ([c061080](https://github.com/Xerrion/DragonToast/commit/c061080c921b08aa19ce281c73587e3e325a2ecb))
* interface cleanup and pkgmeta maintenance ([#125](https://github.com/Xerrion/DragonToast/issues/125)) ([8c09d35](https://github.com/Xerrion/DragonToast/commit/8c09d35768e0180e0a22859c7e48504b5d1e74e7))
* **master:** release 1.1.0 ([#11](https://github.com/Xerrion/DragonToast/issues/11)) ([bb1c3aa](https://github.com/Xerrion/DragonToast/commit/bb1c3aa6f69a58447b0295691397437a5912160b))
* **master:** release 1.10.0 ([#90](https://github.com/Xerrion/DragonToast/issues/90)) ([6831f3d](https://github.com/Xerrion/DragonToast/commit/6831f3d97261a11127177d7b6e5f7fc9f32a32e6))
* **master:** release 1.10.1 ([#101](https://github.com/Xerrion/DragonToast/issues/101)) ([189e882](https://github.com/Xerrion/DragonToast/commit/189e8829cf2a118c490feb563ae438e4771b9ead))
* **master:** release 1.10.2 ([#106](https://github.com/Xerrion/DragonToast/issues/106)) ([b858cd1](https://github.com/Xerrion/DragonToast/commit/b858cd17128aff3f47907999e0adf6f65963ae0c))
* **master:** release 1.11.0 ([#108](https://github.com/Xerrion/DragonToast/issues/108)) ([562953f](https://github.com/Xerrion/DragonToast/commit/562953ffa924cfe65b44299a0437a8017fcf71d8))
* **master:** release 1.12.0 ([#111](https://github.com/Xerrion/DragonToast/issues/111)) ([19afb02](https://github.com/Xerrion/DragonToast/commit/19afb02e9bcb2af80a49ad4f4bd498fd8541e26b))
* **master:** release 1.12.1 ([#113](https://github.com/Xerrion/DragonToast/issues/113)) ([a1b0cda](https://github.com/Xerrion/DragonToast/commit/a1b0cda81ed927633514e187762d68f5a9f52ff4))
* **master:** release 1.13.0 ([#115](https://github.com/Xerrion/DragonToast/issues/115)) ([6d14d42](https://github.com/Xerrion/DragonToast/commit/6d14d42413a5c0ef58306abe27d17522287d7289))
* **master:** release 1.2.0 ([#18](https://github.com/Xerrion/DragonToast/issues/18)) ([b3b18b2](https://github.com/Xerrion/DragonToast/commit/b3b18b2195f853e7f37c70614986e1609a6e15c2))
* **master:** release 1.2.1 ([#23](https://github.com/Xerrion/DragonToast/issues/23)) ([96912d3](https://github.com/Xerrion/DragonToast/commit/96912d3f3e48c3e01095424c158008b8d35c2c79))
* **master:** release 1.5.0 ([#48](https://github.com/Xerrion/DragonToast/issues/48)) ([a3c278f](https://github.com/Xerrion/DragonToast/commit/a3c278f665f368d4b7fe95ca78751ab755b202f5))
* **master:** release 1.6.0 ([#50](https://github.com/Xerrion/DragonToast/issues/50)) ([ae42d81](https://github.com/Xerrion/DragonToast/commit/ae42d818e22f9f2ab82d0d57d3be36c3b07154d7))
* **master:** release 1.6.1 ([#52](https://github.com/Xerrion/DragonToast/issues/52)) ([ddf9fad](https://github.com/Xerrion/DragonToast/commit/ddf9fad2426ad340cbde37bc06214ef4219028c3))
* **master:** release 1.7.0 ([#57](https://github.com/Xerrion/DragonToast/issues/57)) ([05f14b2](https://github.com/Xerrion/DragonToast/commit/05f14b25f4b2737b1ca1f01ad070b786d0b2c006))
* **master:** release 1.8.0 ([#60](https://github.com/Xerrion/DragonToast/issues/60)) ([b4446ed](https://github.com/Xerrion/DragonToast/commit/b4446ed6cc8f6a75b2ff59cb303e5b93b4021889))
* **master:** release 1.8.1 ([#64](https://github.com/Xerrion/DragonToast/issues/64)) ([1410340](https://github.com/Xerrion/DragonToast/commit/1410340d70d429dce89a4d5aae3be6dda2eb20ab))
* **master:** release 1.8.2 ([#66](https://github.com/Xerrion/DragonToast/issues/66)) ([1684d90](https://github.com/Xerrion/DragonToast/commit/1684d90653048077e75e4803a5f2ec9e0aa51c9c))
* **master:** release 1.9.0 ([#69](https://github.com/Xerrion/DragonToast/issues/69)) ([81c9322](https://github.com/Xerrion/DragonToast/commit/81c9322bf5f1da064029bdd199bc6832e83850cb))
* **master:** release 2.0.0 ([#123](https://github.com/Xerrion/DragonToast/issues/123)) ([43c65fa](https://github.com/Xerrion/DragonToast/commit/43c65fa005f6c4e6ae67691f5fe16d734319d740))
* **master:** release 2.0.1 ([#128](https://github.com/Xerrion/DragonToast/issues/128)) ([633e50c](https://github.com/Xerrion/DragonToast/commit/633e50c4e27be204a5043f95a704f702f0308af0))
* **master:** release 2.0.2 ([#129](https://github.com/Xerrion/DragonToast/issues/129)) ([192ba36](https://github.com/Xerrion/DragonToast/commit/192ba36c378cb64872dae4e21378d2ee495acdc7))
* **master:** release 2.1.0 ([#131](https://github.com/Xerrion/DragonToast/issues/131)) ([ce6079a](https://github.com/Xerrion/DragonToast/commit/ce6079a2f007d8489b6f6669068d9793cac60c03))
* **master:** release 2.1.1 ([#132](https://github.com/Xerrion/DragonToast/issues/132)) ([e2831c2](https://github.com/Xerrion/DragonToast/commit/e2831c2ae11764720aea97c38e3cf76813342aba))
* **master:** release 2.1.2 ([#134](https://github.com/Xerrion/DragonToast/issues/134)) ([0ad5e3a](https://github.com/Xerrion/DragonToast/commit/0ad5e3a5ec11df7ab03c3aae8c4e3409f0277640))
* **master:** release 2.1.3 ([#136](https://github.com/Xerrion/DragonToast/issues/136)) ([ae89bf0](https://github.com/Xerrion/DragonToast/commit/ae89bf02cefa9992ad44e2315ff1edbc52de9fbf))
* migrate to shared release workflows ([#67](https://github.com/Xerrion/DragonToast/issues/67)) ([b171f72](https://github.com/Xerrion/DragonToast/commit/b171f7202fbdf76a5fe547566c551ed221599afb))
* release 1.3.0 ([#30](https://github.com/Xerrion/DragonToast/issues/30)) ([43f1ba5](https://github.com/Xerrion/DragonToast/commit/43f1ba54007bfe5998bd998dd942938d6f204d70))
* release 1.4.0 ([#33](https://github.com/Xerrion/DragonToast/issues/33)) ([9d646c3](https://github.com/Xerrion/DragonToast/commit/9d646c3569e042da97855dff474baae7dd17690e))
* release 1.4.1 ([#37](https://github.com/Xerrion/DragonToast/issues/37)) ([1aa052c](https://github.com/Xerrion/DragonToast/commit/1aa052c59f20fc31a40bb74546a8818c1eb5acbc))
* release 1.4.2 ([#40](https://github.com/Xerrion/DragonToast/issues/40)) ([6cf8e8f](https://github.com/Xerrion/DragonToast/commit/6cf8e8fc3714da020d094e736ad3a53c1137c6f2))
* release 1.4.3 ([#43](https://github.com/Xerrion/DragonToast/issues/43)) ([3247fce](https://github.com/Xerrion/DragonToast/commit/3247fce805b66aaf7c2fecf5c17e21e7179f8603))
* set CurseForge project ID ([#14](https://github.com/Xerrion/DragonToast/issues/14)) ([900ea85](https://github.com/Xerrion/DragonToast/commit/900ea85ce733a2ac660bc94387d28d59a90e576b))
* set Wago project ID and fix gitignore ([05450ab](https://github.com/Xerrion/DragonToast/commit/05450ab86603aab699a1a46c6d9b38734daaeebf))
* simplify .pkgmeta ignore list with *.png and *.md globs ([f7b3ba8](https://github.com/Xerrion/DragonToast/commit/f7b3ba8df74b57c1173d6a44ab16cb7cf9e6aa37))
* toc bump ([ea5e57d](https://github.com/Xerrion/DragonToast/commit/ea5e57d1db6ce10333f25d2354766c86eaf80787))
* update addon tagline ([#8](https://github.com/Xerrion/DragonToast/issues/8)) ([d71413c](https://github.com/Xerrion/DragonToast/commit/d71413c268a7f8b349d20d8ed38c3029442cdcaa))
* update LibAnimate submodule ([15ae034](https://github.com/Xerrion/DragonToast/commit/15ae0349c3bcf878e78d774cd21ee96d411bed47))
* update naming ([49d6b8c](https://github.com/Xerrion/DragonToast/commit/49d6b8c0b9a9eab709e21736ac861e0afb6c6fef))
* update repo location ([be303d0](https://github.com/Xerrion/DragonToast/commit/be303d049f33d1c9193442144db4063c082bb98a))
* update submodule ([f37655b](https://github.com/Xerrion/DragonToast/commit/f37655b3d9f093aa47a6137138d1494d775b9380))

## [2.1.3](https://github.com/Xerrion/DragonToast/compare/2.1.2...2.1.3) (2026-03-15)


### 🐛 Bug Fixes

* correct LibAnimate submodule path from DragonToasts to DragonToast ([#135](https://github.com/Xerrion/DragonToast/issues/135)) ([c431923](https://github.com/Xerrion/DragonToast/commit/c43192392ec35114360f17e191c73d7e7fa8e897))

## [2.1.2](https://github.com/Xerrion/DragonToast/compare/2.1.1...2.1.2) (2026-03-15)


### 🐛 Bug Fixes

* show honor and mail filter status in /dt status output ([260c8ca](https://github.com/Xerrion/DragonToast/commit/260c8caf0a7141f6082046789fb82f4fb4ab672a))

## [2.1.1](https://github.com/Xerrion/DragonToast/compare/2.1.0...2.1.1) (2026-03-15)


### 🐛 Bug Fixes

* update AGENTS.md CI/CD docs to reflect consolidated workflow structure ([654eaa6](https://github.com/Xerrion/DragonToast/commit/654eaa6ade737adecaa0b4072a125e9357f581a1))

## [2.1.0](https://github.com/Xerrion/DragonToast/compare/2.0.2...2.1.0) (2026-03-15)


### 🚀 Features

* drop support for tww ([8edabfa](https://github.com/Xerrion/DragonToast/commit/8edabfacdf50d873db1af36651b54813649a1564))


### 🐛 Bug Fixes

* use proper token? ([0671e7c](https://github.com/Xerrion/DragonToast/commit/0671e7cd1d2de26e9eda61913d1f4442564c34b8))


### ⚙️ Miscellaneous Tasks

* inline shared release workflows ([#130](https://github.com/Xerrion/DragonToast/issues/130)) ([c061080](https://github.com/Xerrion/DragonToast/commit/c061080c921b08aa19ce281c73587e3e325a2ecb))
* update naming ([49d6b8c](https://github.com/Xerrion/DragonToast/commit/49d6b8c0b9a9eab709e21736ac861e0afb6c6fef))
* update submodule ([f37655b](https://github.com/Xerrion/DragonToast/commit/f37655b3d9f093aa47a6137138d1494d775b9380))

## [2.0.2](https://github.com/Xerrion/DragonToast/compare/2.0.1...2.0.2) (2026-03-13)


### ⚙️ Miscellaneous Tasks

* fix wrong toc version ([5d9c56a](https://github.com/Xerrion/DragonToast/commit/5d9c56a51b5167f01d9533597ab86559a1dd24ea))

## [2.0.1](https://github.com/Xerrion/DragonToast/compare/2.0.0...2.0.1) (2026-03-13)


### ⚙️ Miscellaneous Tasks

* toc bump ([ea5e57d](https://github.com/Xerrion/DragonToast/commit/ea5e57d1db6ce10333f25d2354766c86eaf80787))

## [2.0.0](https://github.com/Xerrion/DragonToast/compare/1.13.0...2.0.0) (2026-03-13)


### ⚠ BREAKING CHANGES

* ns.ToastManager test functions moved to ns.TestToasts

### 🚀 Features

* add bundled default notification sounds ([#122](https://github.com/Xerrion/DragonToast/issues/122)) ([4930a55](https://github.com/Xerrion/DragonToast/commit/4930a5557efdcbf885a2df76185a860ed99a9aae))
* codebase-wide refactoring for consistency and maintainability ([#127](https://github.com/Xerrion/DragonToast/issues/127)) ([7dfee81](https://github.com/Xerrion/DragonToast/commit/7dfee818a84fa305716928ba1c7478c657888b87))


### 🐛 Bug Fixes

* add missing currency loot messages ([#126](https://github.com/Xerrion/DragonToast/issues/126)) ([b4b9853](https://github.com/Xerrion/DragonToast/commit/b4b9853ffbefc4f75eb825a4abaf60f4fe71ecd8))
* exclude generate_sound.py from bundling ([3e96233](https://github.com/Xerrion/DragonToast/commit/3e96233e4520694cda9a3ae710e0e42bb7d67830))
* use correct verion tags ([#124](https://github.com/Xerrion/DragonToast/issues/124)) ([ab0463c](https://github.com/Xerrion/DragonToast/commit/ab0463c650fc6d57fed428c261ca12c8ce594d16))

## [1.13.0](https://github.com/Xerrion/DragonToast/compare/1.12.1...1.13.0) (2026-03-07)


### 🚀 Features

* add AceLocale-3.0 localization support ([#95](https://github.com/Xerrion/DragonToast/issues/95)) ([#117](https://github.com/Xerrion/DragonToast/issues/117)) ([0780b45](https://github.com/Xerrion/DragonToast/commit/0780b45a9e9570803331f86f43c101fdeb603fba))


### 🐛 Bug Fixes

* clarify slash command help and toggle behavior ([#114](https://github.com/Xerrion/DragonToast/issues/114)) ([016ce4c](https://github.com/Xerrion/DragonToast/commit/016ce4caf96242986424da3678539c4f2e6468eb))


### 🚜 Refactor

* convert to monorepo structure ([#116](https://github.com/Xerrion/DragonToast/issues/116)) ([689fc89](https://github.com/Xerrion/DragonToast/commit/689fc89f3b97760d29bbb66794838f2b515fea51))

## [1.12.1](https://github.com/Xerrion/DragonToast/compare/1.12.0...1.12.1) (2026-03-06)


### 🐛 Bug Fixes

* correct TOC packager directives ([#112](https://github.com/Xerrion/DragonToast/issues/112)) ([7ce6c6f](https://github.com/Xerrion/DragonToast/commit/7ce6c6ff80054de5f90647c410da50c02681f3e0))

## [1.12.0](https://github.com/Xerrion/DragonToast/compare/1.11.0...1.12.0) (2026-03-06)


### 🚀 Features

* add reputation gain toasts ([#93](https://github.com/Xerrion/DragonToast/issues/93)) ([#110](https://github.com/Xerrion/DragonToast/issues/110)) ([d39ae79](https://github.com/Xerrion/DragonToast/commit/d39ae79848584d3f0667d80f533f13c819484d7e))

## [1.11.0](https://github.com/Xerrion/DragonToast/compare/1.10.2...1.11.0) (2026-03-05)


### 🚀 Features

* custom options panel replacing AceConfig ([#107](https://github.com/Xerrion/DragonToast/issues/107)) ([5d09ee8](https://github.com/Xerrion/DragonToast/commit/5d09ee8ae2b5cbd3c6fea82c97830faf78ec781d))

## [1.10.2](https://github.com/Xerrion/DragonToast/compare/1.10.1...1.10.2) (2026-03-02)


### 🐛 Bug Fixes

* animation glitches and deferred slide jumps ([#104](https://github.com/Xerrion/DragonToast/issues/104)) ([#105](https://github.com/Xerrion/DragonToast/issues/105)) ([b1ff4f1](https://github.com/Xerrion/DragonToast/commit/b1ff4f1c1b9081db87b5021f229d87859e82e533))
* extract CurrencyListener and resolve currency icons ([#102](https://github.com/Xerrion/DragonToast/issues/102)) ([#103](https://github.com/Xerrion/DragonToast/issues/103)) ([3976b34](https://github.com/Xerrion/DragonToast/commit/3976b34bb8f17ca4f5b595f6c53ea099905b23ac))

## [1.10.1](https://github.com/Xerrion/DragonToast/compare/1.10.0...1.10.1) (2026-03-01)


### 🐛 Bug Fixes

* resolve anchor z-order and position shift on lock ([#100](https://github.com/Xerrion/DragonToast/issues/100)) ([4d8f217](https://github.com/Xerrion/DragonToast/commit/4d8f2175ef5d7eb3ce14bcc01b037cce2f16d1fb))

## [1.10.0](https://github.com/Xerrion/DragonToast/compare/1.9.0...1.10.0) (2026-03-01)


### 🚀 Features

* add built-in skin presets ([#88](https://github.com/Xerrion/DragonToast/issues/88)) ([#92](https://github.com/Xerrion/DragonToast/issues/92)) ([8c2a7c4](https://github.com/Xerrion/DragonToast/commit/8c2a7c4a87e5f07c39525b6a6b73f8557c7565de))
* add mail toast support ([#87](https://github.com/Xerrion/DragonToast/issues/87)) ([#89](https://github.com/Xerrion/DragonToast/issues/89)) ([05914a9](https://github.com/Xerrion/DragonToast/commit/05914a94929690a35a24fa4e47bd898da7b89808))


### 🐛 Bug Fixes

* use hardcoded honor icon FileDataIDs ([#91](https://github.com/Xerrion/DragonToast/issues/91)) ([d074976](https://github.com/Xerrion/DragonToast/commit/d074976bc3fb75c6359e6a8c84ceb67b4e928685))


### 🚜 Refactor

* extract shared listener helpers into ListenerUtils ([#96](https://github.com/Xerrion/DragonToast/issues/96)) ([#98](https://github.com/Xerrion/DragonToast/issues/98)) ([0702a5b](https://github.com/Xerrion/DragonToast/commit/0702a5b24f154ec5ec6e1af471cded9caee6a501))

## [1.9.0](https://github.com/Xerrion/DragonToast/compare/1.8.2...1.9.0) (2026-02-27)


### 🚀 Features

* DragonLoot cross-addon bridge via AceEvent messaging ([#70](https://github.com/Xerrion/DragonToast/issues/70)) ([7b4ed89](https://github.com/Xerrion/DragonToast/commit/7b4ed8945ec4a8aad0495ecef0df435a8d4c0089))
* enhanced border customization ([#75](https://github.com/Xerrion/DragonToast/issues/75)) ([37f1918](https://github.com/Xerrion/DragonToast/commit/37f19184bf70afec5195f4eb8371fb67afde1ca8))
* enhanced roll-won toast with winner name and roll details ([#71](https://github.com/Xerrion/DragonToast/issues/71)) ([e1c7b62](https://github.com/Xerrion/DragonToast/commit/e1c7b622be7e55e8f78bfc08df48eb5474341fc1))


### 🐛 Bug Fixes

* add contents:write permission to release workflow ([7dd5274](https://github.com/Xerrion/DragonToast/commit/7dd5274e472c4f9a1bc744bc397c3172375c5e85))
* add permissions to caller workflow ([#68](https://github.com/Xerrion/DragonToast/issues/68)) ([1ae82cb](https://github.com/Xerrion/DragonToast/commit/1ae82cbb556adb2491d760974ecbd246df86ddcd))
* address code review issues in MessageBridge ([#81](https://github.com/Xerrion/DragonToast/issues/81)) ([5843b81](https://github.com/Xerrion/DragonToast/commit/5843b8109bfcab9d0b126a64bc8327f8d696c56b))
* resolve minimap icon toggle inverted logic ([#74](https://github.com/Xerrion/DragonToast/issues/74)) ([7389939](https://github.com/Xerrion/DragonToast/commit/738993949c3e2c4f4d631d7e00ad182c30972e1e))
* rework toast frame layout with child-frame hierarchy ([#83](https://github.com/Xerrion/DragonToast/issues/83)) ([9e3daf8](https://github.com/Xerrion/DragonToast/commit/9e3daf81ca37070b7e9220c40f2fc2887739c71b))
* stacking accumulation bugs and add busted unit tests ([#85](https://github.com/Xerrion/DragonToast/issues/85)) ([f45f211](https://github.com/Xerrion/DragonToast/commit/f45f211f4870f02430271cf0c7fbc8b899bed961))
* use faction-specific honor icon constants (closes [#76](https://github.com/Xerrion/DragonToast/issues/76)) ([#84](https://github.com/Xerrion/DragonToast/issues/84)) ([38499c9](https://github.com/Xerrion/DragonToast/commit/38499c938a5de14b9853c8409dfe024ccfd73fae))

## [1.8.1](https://github.com/Xerrion/DragonToast/compare/1.8.0...1.8.1) (2026-02-25)

### ⚙️ Miscellaneous Tasks

* customize release changelog ([#63](https://github.com/Xerrion/DragonToast/issues/63)) ([7f07d71](https://github.com/Xerrion/DragonToast/commit/7f07d7107c9bf28cd2f5676bd5a00fb1cc039492))

## [1.8.0](https://github.com/Xerrion/DragonToast/compare/1.7.0...1.8.0) (2026-02-25)

### 🚀 Features

* support mop classic ([#62](https://github.com/Xerrion/DragonToast/issues/62)) ([94433ca](https://github.com/Xerrion/DragonToast/commit/94433ca8d22014e625ad82350d1e42ebc4616186))

### 🐛 Bug Fixes

* **toast:** sync slide start anchor ([#59](https://github.com/Xerrion/DragonToast/issues/59)) ([fb174a9](https://github.com/Xerrion/DragonToast/commit/fb174a93161e3af30ecc617ffc38cb42514910eb))

### 📚 Documentation

* update README ([#61](https://github.com/Xerrion/DragonToast/issues/61)) ([900f725](https://github.com/Xerrion/DragonToast/commit/900f725310c765dd5af2e63f5587726c04bf70ad))
* updated AGENTS.md with current information ([#58](https://github.com/Xerrion/DragonToast/issues/58)) ([7114e7e](https://github.com/Xerrion/DragonToast/commit/7114e7e351388e749fe71e540513ed5955a85503))

## [1.7.0](https://github.com/Xerrion/DragonToast/compare/1.6.1...1.7.0) (2026-02-24)

### 🚀 Features

* add honor gain toasts ([#55](https://github.com/Xerrion/DragonToast/issues/55)) ([cdf6ead](https://github.com/Xerrion/DragonToast/commit/cdf6eadc3d7a245260b22f3dfa99f42f36e3ee3a))

## [1.6.1](https://github.com/Xerrion/DragonToast/compare/1.6.0...1.6.1) (2026-02-24)

### 🐛 Bug Fixes

* consolidate duplicates, optimize pooling, and improve code quality ([#51](https://github.com/Xerrion/DragonToast/issues/51)) ([cb4cd1d](https://github.com/Xerrion/DragonToast/commit/cb4cd1db4f7513a75b18411c870a106749f1477f))
* remove unused string_format variable in XPListener ([#53](https://github.com/Xerrion/DragonToast/issues/53)) ([e7deb2f](https://github.com/Xerrion/DragonToast/commit/e7deb2fe39578ad8f59f932abbb60c72791ddd5d))

## [1.6.0](https://github.com/Xerrion/DragonToast/compare/1.5.0...1.6.0) (2026-02-23)

### 🚀 Features

* add configurable gold display format ([#49](https://github.com/Xerrion/DragonToast/issues/49)) ([485cffc](https://github.com/Xerrion/DragonToast/commit/485cffcdc759c613ba7f15d876a4dc8eecc56ea6))

### ⚙️ Miscellaneous Tasks

* simplify .pkgmeta ignore list with *.png and*.md globs ([f7b3ba8](https://github.com/Xerrion/DragonToast/commit/f7b3ba8df74b57c1173d6a44ab16cb7cf9e6aa37))

## [1.5.0](https://github.com/Xerrion/DragonToast/compare/1.4.3...1.5.0) (2026-02-23)

### 🚀 Features

* leverage LibAnimate queue APIs for optimized toast management ([#47](https://github.com/Xerrion/DragonToast/issues/47)) ([11d1f9f](https://github.com/Xerrion/DragonToast/commit/11d1f9f93d2c352480bf61af4ee256a4c2d41820))

### ⚙️ Miscellaneous Tasks

* add scaled image ([#45](https://github.com/Xerrion/DragonToast/issues/45)) ([aa8a2cd](https://github.com/Xerrion/DragonToast/commit/aa8a2cdffaab290d7a6f3edfdf139e37b06daa9b))
* centered header content of the README ([#46](https://github.com/Xerrion/DragonToast/issues/46)) ([d567ea8](https://github.com/Xerrion/DragonToast/commit/d567ea8802c7311dcc19500e419ef7ed02c15685))
* update LibAnimate submodule ([15ae034](https://github.com/Xerrion/DragonToast/commit/15ae0349c3bcf878e78d774cd21ee96d411bed47))

## [1.4.2] - 2026-02-22

### 🐛 Bug Fixes

* Include Libs/embeds.xml in git tracking (#39)
* Load correct xml for LibDBIcon-1.0 (#41)

### ⚙️ Miscellaneous Tasks

* Release 1.4.2 (#40)

## [1.4.1] - 2026-02-22

### 🐛 Bug Fixes

* Use latest libanimate (#36)

### ⚙️ Miscellaneous Tasks

* Release 1.4.1 (#37)

## [1.4.0] - 2026-02-22

### 🚀 Features

* Backdrop template, border/background textures, and test mode (#35)

### ⚙️ Miscellaneous Tasks

* Fix release workflow (#32)
* Release 1.4.0 (#33)

## [1.3.0] - 2026-02-22

### 🚀 Features

* Rewrite animation system to use LibAnimate-1.0 (#26)

### 🐛 Bug Fixes

* Resolve invisible toast and slide animation snap bugs (#24)

### 🚜 Refactor

* Rebranding (#31)

### ⚙️ Miscellaneous Tasks

* Update release workflow (#28)
* Add release-please-style auto-release workflow (#29)
* Release 1.3.0 (#30)

## [1.2.1] - 2026-02-22

### 🐛 Bug Fixes

* Workflow should now work? (#21)

### ⚙️ Miscellaneous Tasks

* *(master)* Release 1.2.1 (#23)

## [1.2.0] - 2026-02-22

### 🚀 Features

* Add /dt reset command to restore default anchor position (#17)

### ⚙️ Miscellaneous Tasks

* Fix BigWigsMods packager future tag error (#16)
* *(master)* Release 1.2.0 (#18)

## [1.1.0] - 2026-02-22

### 🐛 Bug Fixes

* ElvUI skin now respects user Appearance settings (#12)
* Lint workflow now triggers on release-please PRs (#13)

### 🚜 Refactor

* Remove pop animation system (#9)
* Reorganize config UI with headers and logical grouping (#10)

### 📚 Documentation

* Comprehensive DragonToast AGENTS.md (#15)

### ⚙️ Miscellaneous Tasks

* Update addon tagline (#8)
* Set CurseForge project ID (#14)
* *(master)* Release 1.1.0 (#11)

## [1.0.0] - 2026-02-22

### 🚀 Features

* Initial DragonToast implementation

### 🐛 Bug Fixes

* Prevent invisible toasts from stale animation state and leaked timers (#5)
* Correct branch name in CI workflows from main to master (#6)
* Pop animation no longer overflows toast border (#7)

### ⚙️ Miscellaneous Tasks

* Initialize repository
* Set Wago project ID and fix gitignore
