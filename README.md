# Flutter Auto Translate

🎯 **Wrap any Text widget to add automatic translation with smart caching!**

[![pub package](https://img.shields.io/pub/v/flutter_auto_translate.svg)](https://pub.dev/packages/flutter_auto_translate)

## Features

✨ **Wrapper Widget** - Wrap ANY existing Text widget  
💾 **Smart Caching** - Instant translation loading  
🌍 **85+ Languages** - All major languages supported  
🎨 **Beautiful Language Selector** - Pre-built UI with flags  
⚡ **Zero Refactoring** - Works with your existing code  
🔧 **Easy Setup** - 2 minutes integration  

## Installation
```yaml
dependencies:
  flutter_auto_translate: ^1.0.0
```

## Usage

### 1. Initialize (in main.dart)
```dart
import 'package:flutter_auto_translate/flutter_auto_translate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TranslationService().init();
  runApp(MyApp());
}
```

### 2. Wrap Your Text Widgets

#### Before:
```dart
Text('Hello, World!')
```

#### After:
```dart
AutoTranslate(
  child: Text('Hello, World!'),
)
```

**That's it! Your text now auto-translates! 🎉**

### 3. Add Language Selector
```dart
IconButton(
  icon: Icon(Icons.language),
  onPressed: () async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LanguageSelectionScreen(),
      ),
    );
    setState(() {}); // Rebuild to show new language
  },
)
```

## Examples

### Wrap Custom Text Widgets
```dart
// Your existing custom widget
class CustomTextOne extends StatelessWidget {
  final String text;
  
  CustomTextOne({required this.text});

  @override
  Widget build(BuildContext context) {
    return AutoTranslate(  // ← Just wrap it!
      child: Text(
        text,
        style: TextStyle(fontSize: 20),
      ),
    );
  }
}
```

### Disable Translation for Specific Text
```dart
AutoTranslate(
  enable: false,  // ← Disable translation
  child: Text('API_KEY_12345'),
)
```

### Override Language
```dart
AutoTranslate(
  languageCode: 'es',  // ← Force Spanish
  child: Text('Hello'),
)
```

## How It Works

1. **Wrap** any Text widget with `AutoTranslate`
2. **Extract** text automatically
3. **Translate** using Google Translate
4. **Cache** locally for instant loading
5. **Display** translated text

## API

### AutoTranslate Widget

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| child | Widget | required | Text widget to translate |
| languageCode | String? | null | Override global language |
| enable | bool | true | Enable/disable translation |
| loadingWidget | Widget? | null | Custom loading indicator |

### TranslationService
```dart
// Get current language
TranslationService().currentLanguage

// Set language
await TranslationService().setLanguage('es');

// Clear cache
await TranslationService().clearCache();
```

## Benefits

✅ **No Code Refactoring** - Works with existing widgets  
✅ **Type Safe** - Full Dart type support  
✅ **Performance** - Cached translations load instantly  
✅ **Flexible** - Use globally or per-widget  
✅ **Beautiful** - Pre-built language selector UI  

## License

MIT
