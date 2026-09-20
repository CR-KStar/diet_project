# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A Flutter port of a completed single-file HTML prototype ("다이어트 관리 앱 v3.0" — a
diet-tracking app with a photo-first meal log and a plant-growth reward loop; see
`README.md` for the product spec and the list of 27 screens). All data is mock; there is
no backend, no persistence, and no network layer. The HTML prototype is treated as the
source of truth — comments refer to it as "프로토타입", and `AppState` deliberately mirrors
its `Component.state`.

The port is **mid-migration**: `lib/app_state.dart` and the shared layers are fully built,
and ~29 screen files exist under `lib/ui/`, but only Login and Onboarding are currently
reachable. Wiring the remaining screens into the shell is the main outstanding work.

## Commands

```bash
flutter pub get                       # install deps after touching pubspec.yaml
flutter run -d chrome                 # run (web); or -d macos / a device id
flutter analyze                       # static analysis + lints (flutter_lints)
dart format lib test                  # formatter
flutter test                          # all tests
flutter test test/widget_test.dart --plain-name "smoke"   # single test by name
```

Note: `test/widget_test.dart` is still the default Flutter counter template and **fails**
(it looks for a counter UI that does not exist). Replace or delete it when adding real tests.

Environment: Flutter 3.44 (stable), Dart SDK `^3.12.2`.

## Architecture

### State and navigation — one global `ChangeNotifier`

`main.dart` wraps the app in a single `ChangeNotifierProvider<AppState>`. `lib/app_state.dart`
is a deliberately large god-object that holds **all** state for every screen, every domain
model (`Bowl`, `Routine`, `Challenge`, `MealLog`, `PlantSpecies`, `Mission`, …), and all mock
data.

Navigation is **string-based, not `Navigator`**:

- `String screen` names the active screen; sub-modes of merged screens are booleans/strings
  (`missionOpen`, `extraOpen`, `editing`, `plantTab`, `friendTab`, `setTab`, …).
- `go(id)` switches screens: it resets every sub-mode, then either expands a legacy id via
  the `_alias` map (e.g. `'dex'` → `screen: 'plant', plantTab: '도감'`) or sets `screen = id`.
- `setSub(() => ...)` runs an arbitrary mutation and calls `notifyListeners()` — used for
  one-off field edits from widgets.
- `showShell`, `tabGroups` support a bottom-tab shell that is **not built yet**. Until it is,
  `LoginPage` → `OnboardingPage` transitions use a real `Navigator.push`; everything past
  onboarding is expected to route through `go()` inside the future shell.

Screens read state with `context.watch<AppState>()` and mutate through the named methods on
`AppState` (`toggleTerm`, `addWater`, `care`, `createChallenge`, …). Computed values
(`dailyTarget`, `adjustedKcal`, `plantStage`, `recommendations`, …) are getters on `AppState`
— do not recompute them in widgets.

### Three shared layers — always build on these

- **`lib/theme_tokens.dart`** — design tokens as `abstract final class` holders of static
  consts: `AppColor`, `AppSpace`, `AppRadius`, `AppShadow`, `AppText`, `AppDeco`, `AppSize`,
  plus `buildAppTheme()`. Never hardcode a color, radius, padding, or shadow that already has
  a token.
- **`DietRules`** (also in `theme_tokens.dart`) — the spec's fixed domain constants:
  calorie-correction factors (`cookFactor`, `sauceFactor`, `proteinFactor`, `portionRatio`,
  `fillRatio`), exercise/activity factors, and plant-growth rules (`careExp`, `plantStages`,
  `balanceSpreadThreshold`, `wiltAfterDays`, `graceDays`, `maxBowls`, …). `AppState`'s
  calculation getters read from here; change the rule in one place.
- **`lib/common.dart`** — the reusable widget kit (`AppCard`, `SunkenBox`, `IconTile`,
  `TabHeader`/`SubHeader`/`CardHeader`, chip/segment/tab selectors, `AppToggle`, `CheckDot`,
  `PrimaryButton`/`TextLink`/`SmallButton`/`Pill`, `ProgressBar`/`Ring`/`BarChart`/
  `WeightLineChart`, `NumberField`/`AppTextField`/`DragSlider`, `PhotoPlaceholder`,
  `RowBetween`). Also the text helper `t(size, {w, c, sp, h})` (wraps `GoogleFonts.notoSansKr`)
  and `toast(context, msg)`. Compose screens from these rather than raw Material widgets.

### Screen files

`lib/ui/<feature>/widgets/<screen>_page.dart`, grouped by feature: `onboarding`, `home`,
`growth`, `record`, `report_settings`, `social`. Each `*_page.dart` is a `StatelessWidget`
that reads `AppState` and composes `common.dart` widgets. (One filename is misspelled:
`nutrient_detail_pgae.dart`.)

### Korean string literals are significant

Comments, UI copy, and many state values / map keys / enum-like checks are Korean string
literals — e.g. `goal == '체중 감량'`, `portion == '전체'`, `careExp['물 주기']`,
`chKindMeta['운동 시간']`. These exact strings are the contract between `AppState`, `DietRules`,
and the widgets; match them precisely.
