## [1.1.1] - 2026-05-13

### Fixed
- README banner image now uses a path relative to the package root
  (`assets/flutter_auto_translate_banner.png`) so it renders correctly on
  **pub.dev** and **GitHub** (the previous `raw.githubusercontent.com/.../main/...`
  URL returned 404 when the default branch is `master`).

## [1.1.0] - 2026-05-13

### Added
- Hint text translation in `TextField`: wrap any `TextField` with
  `AutoTranslate`, or use the new `AutoTranslateField` /
  `AutoTranslateFormField` widgets. `hintText`, `labelText`, `helperText`,
  `errorText`, `prefixText`, `suffixText` and `counterText` are translated.
- New `AutoTranslateScope` widget that renders a single, configurable
  full-screen loader while translations for a screen are being fetched or
  while the language is changing — replaces per-widget spinners with a
  clean screen-level UX.
- `TranslationService` is now a `ChangeNotifier` and exposes a
  `pendingCount` (`ValueListenable<int>`) plus an `isTranslating` flag for
  custom loading states.
- Synchronous, in-memory translation cache that mirrors `SharedPreferences`,
  so widgets can resolve translations during build with no flicker.
- Request deduplication: simultaneous translation requests for the same
  text + language are merged into a single network call.
- `TranslationService.preload(...)` batch-translates a list of strings to
  pre-warm a screen.

### Changed
- `AutoTranslate` no longer shows a per-widget loading indicator by default.
  Opt back into the legacy behavior with `showInlineLoader: true`.
- Language changes no longer require manual `setState` from consuming
  screens. `AutoTranslate`, `AutoTranslateField` and `AutoTranslateFormField`
  all listen reactively to `TranslationService` and update in place,
  eliminating screen-level rebuild flicker / shaking.

## [1.0.0] - 2024-11-19

* Initial release
* AutoTranslate wrapper widget for any Text widget
* Support for 85+ languages with automatic translation
* Smart caching system for instant loading
* Language selection screen with country flags
* Search functionality for languages
* Zero refactoring needed - just wrap existing Text widgets
