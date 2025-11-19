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
  flutter_auto_translate: ^1.0.3
```

## Quick Start

### 1. Initialize
```dart
import 'package:flutter_auto_translate/flutter_auto_translate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TranslationService().init();
  runApp(MyApp());
}
```

### 2. Wrap Your Text
```dart
// Before
Text('Hello, World!')

// After  
AutoTranslate(
  child: Text('Hello, World!'),
)
```

**That's it! Your text now auto-translates!** 🎉

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

## Supported Languages

85+ languages including: English, Spanish, French, German, Chinese, Japanese, Korean, Arabic, Hindi, Bengali, Portuguese, Russian, Turkish, Italian, and many more!

## API Reference

### AutoTranslate Widget

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| child | Widget | required | Text widget to translate |
| languageCode | String? | null | Override global language |
| enable | bool | true | Enable/disable translation |
| loadingWidget | Widget? | null | Custom loading indicator |

### TranslationService
```dart
// Initialize service
await TranslationService().init();

// Get current language
String lang = TranslationService().currentLanguage;

// Set language
await TranslationService().setLanguage('es');

// Clear cache
await TranslationService().clearCache();

// Clear cache for specific language
await TranslationService().clearCacheForLanguage('es');
```

## How It Works

1. **Wrap** any Text widget with AutoTranslate
2. **Extract** text automatically from child
3. **Translate** using Google Translate API
4. **Cache** locally for instant loading
5. **Display** translated text with original styling

## Benefits

✅ **No Code Refactoring** - Works with existing widgets  
✅ **Type Safe** - Full Dart type support  
✅ **Performance** - Cached translations load instantly  
✅ **Flexible** - Use globally or per-widget  
✅ **Beautiful** - Pre-built language selector UI

## Example App

Check out the [example](example/) directory for a complete working app.

## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Support

If you find this package helpful, please give it a ⭐ on [GitHub](https://github.com/devjaimul/flutter_auto_translate)!
EOF