# Flutter Auto Translate

![Flutter Auto Translate banner](https://raw.githubusercontent.com/devjaimul/flutter_auto_translate/main/assets/flutter_auto_translate_banner.png)

**Wrap any Text or TextField to add automatic localization to your Flutter app — zero effort, smart caching, 85+ languages.**

[![pub package](https://img.shields.io/pub/v/flutter_auto_translate.svg)](https://pub.dev/packages/flutter_auto_translate)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Features

- **Wrapper widget** – wrap any existing `Text` widget
- **TextField hint translation** – `hintText`, `labelText`, `helperText`, `errorText`, `prefixText`, `suffixText` and `counterText` are translated automatically
- **Smart caching** – instant translation loading from an in-memory + disk cache
- **Reactive state** – `TranslationService` is a `ChangeNotifier`; widgets update without manual `setState` calls (no more screen flicker)
- **Single full-screen loader** – `AutoTranslateScope` shows one loader for the whole screen instead of per-widget spinners
- **85+ languages** – all major languages supported
- **Beautiful language selector** – pre-built UI with flags
- **Easy setup** – 2 minute integration

## Installation
```yaml
dependencies:
  flutter_auto_translate: ^1.1.0
```

## Quick start

### 1. Initialize
```dart
import 'package:flutter_auto_translate/flutter_auto_translate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TranslationService().init();
  runApp(MyApp());
}
```

### 2. Wrap your Text
```dart
// Before
Text('Hello, World!')

// After
AutoTranslate(
  child: Text('Hello, World!'),
)
```

### 3. Translate input field hints
You can either wrap a `TextField` with `AutoTranslate`:
```dart
AutoTranslate(
  child: TextField(
    decoration: InputDecoration(
      hintText: 'Search products',
      labelText: 'Search',
    ),
  ),
)
```

…or use the dedicated `AutoTranslateField` / `AutoTranslateFormField`:
```dart
AutoTranslateField(
  controller: controller,
  decoration: const InputDecoration(
    hintText: 'you@example.com',
    labelText: 'Email address',
  ),
)
```

### 4. Show a single loader for the whole screen
Wrap your screen body with `AutoTranslateScope` so users see a single full-screen
loader while translations are being fetched, instead of every text widget showing
its own spinner:

```dart
Scaffold(
  body: AutoTranslateScope(
    child: MyScreenContents(),
  ),
)
```

You can customize the loader and timing:
```dart
AutoTranslateScope(
  loaderBuilder: (context) => Center(child: CircularProgressIndicator()),
  minLoaderDuration: Duration(milliseconds: 250),
  maxLoaderDuration: Duration(seconds: 8),
  showOnFirstBuild: true,
  child: MyScreenContents(),
)
```

### 5. Add a language selector
No more manual `setState` after the user picks a language – `AutoTranslate`
listens to `TranslationService` and rebuilds automatically.

```dart
IconButton(
  icon: Icon(Icons.language),
  onPressed: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => LanguageSelectionScreen(),
    ),
  ),
)
```

## What changed in `1.1.0`

| Concern                                  | Before                                                 | Now                                                                 |
| ---------------------------------------- | ------------------------------------------------------ | ------------------------------------------------------------------- |
| Hint text in `TextField`                 | Not translated                                         | Translated when wrapped with `AutoTranslate` or via `AutoTranslateField` |
| Loading effect on each widget            | Every `AutoTranslate` showed a spinner during fetch    | Off by default; opt-in via `showInlineLoader: true`                 |
| Full-screen loading during language swap | Not provided                                           | New `AutoTranslateScope` shows one loader per screen                |
| Screen shaking / flicker                 | Each `AutoTranslate` triggered its own `setState` chain | Reactive `ChangeNotifier` model with in-memory cache & deduped requests |

## API reference

### `AutoTranslate`
| Property            | Type      | Default | Description                                          |
| ------------------- | --------- | ------- | ---------------------------------------------------- |
| `child`             | `Widget`  | required | The `Text` or `TextField` widget to translate.       |
| `languageCode`      | `String?` | `null`  | Override the global language for this widget.        |
| `enable`            | `bool`    | `true`  | Disable translation for this widget.                 |
| `showInlineLoader`  | `bool`    | `false` | Show a small spinner while waiting for translation.  |
| `loadingWidget`     | `Widget?` | `null`  | Custom loader when `showInlineLoader` is `true`.     |

### `AutoTranslateField` / `AutoTranslateFormField`
Drop-in replacements for `TextField` / `TextFormField` that translate every
string in their `InputDecoration` and listen to language changes.

### `AutoTranslateScope`
| Property              | Type             | Default         | Description                                                                   |
| --------------------- | ---------------- | --------------- | ----------------------------------------------------------------------------- |
| `child`               | `Widget`         | required        | Subtree whose translations drive the loader.                                  |
| `loaderBuilder`       | `WidgetBuilder?` | `null`          | Custom full-screen loader (defaults to a centered `CircularProgressIndicator`). |
| `minLoaderDuration`   | `Duration`       | `250 ms`        | Minimum visible duration to prevent flashes.                                  |
| `maxLoaderDuration`   | `Duration`       | `8 s`           | Hard cap; loader auto-dismisses to avoid getting stuck.                       |
| `showOnFirstBuild`    | `bool`           | `true`          | Show loader the first time the scope is built.                                |
| `enabled`             | `bool`           | `true`          | Disable the scope entirely.                                                   |

### `TranslationService`
```dart
await TranslationService().init();                  // initialize once
TranslationService().currentLanguage;               // current language code
await TranslationService().setLanguage('es');       // change language (notifies listeners)
TranslationService().getCached('Hello');            // sync cache lookup, may return null
TranslationService().isCached('Hello');             // true if cached for current language
await TranslationService().translate('Hello');      // async translate + cache
await TranslationService().preload(['Hi', 'Bye']);  // warm up cache for a screen
await TranslationService().clearCache();            // clear everything
await TranslationService().clearCacheForLanguage('es');
TranslationService().isTranslating;                 // bool: any pending request?
TranslationService().pendingCount;                  // ValueListenable<int>
```

The service is a `ChangeNotifier`, so you can also `addListener` from your own
state-management layer (Provider, Riverpod, BLoC, …).

## How it works

1. Wrap any `Text` / `TextField` with `AutoTranslate`, or use
   `AutoTranslateField` for input hints.
2. On build, the widget looks up the translation **synchronously** from the
   in-memory cache.
3. If missing, an async request is fired; identical concurrent requests are
   deduplicated.
4. When a translation lands, `TranslationService` notifies its listeners and the
   affected widgets rebuild in place (no full screen rebuilds, no flicker).
5. `AutoTranslateScope` watches the pending request counter to show a single
   full-screen loader while a screen is "warming up".

## Supported languages

85+ languages including: English, Spanish, French, German, Chinese, Japanese,
Korean, Arabic, Hindi, Bengali, Portuguese, Russian, Turkish, Italian, and many
more.

## Example app

Check out the [example](example/) directory for a complete working app
demonstrating all features.

## Complete documentation

Medium article: https://medium.com/@jaimulislam7/flutter-auto-translate-making-your-app-multilingual-in-minutes-eb1193d8b2c6

## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Support

If you find this package helpful, please give it a star on [GitHub](https://github.com/devjaimul/flutter_auto_translate).
