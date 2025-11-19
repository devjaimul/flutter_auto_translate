import 'package:shared_preferences/shared_preferences.dart';
import 'package:translator/translator.dart';
import 'dart:convert';

/// Service for managing translations and caching
class TranslationService {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  final GoogleTranslator _translator = GoogleTranslator();
  SharedPreferences? _prefs;
  String _currentLanguage = 'en';

  static const String _cachePrefix = 'auto_translate_cache_';
  static const String _languageKey = 'auto_translate_language';

  /// Initialize the service
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    _currentLanguage = _prefs?.getString(_languageKey) ?? 'en';
  }

  /// Get current language
  String get currentLanguage => _currentLanguage;

  /// Set current language
  Future<void> setLanguage(String languageCode) async {
    _currentLanguage = languageCode;
    await _prefs?.setString(_languageKey, languageCode);
  }

  String _getCacheKey(String text, String targetLang) {
    return '$_cachePrefix${targetLang}_${text.hashCode}';
  }

  String? _getCachedTranslation(String text, String targetLang) {
    final key = _getCacheKey(text, targetLang);
    final cached = _prefs?.getString(key);

    if (cached != null) {
      try {
        final Map<String, dynamic> data = json.decode(cached);
        return data['translation'] as String?;
      } catch (e) {
        _prefs?.remove(key);
      }
    }
    return null;
  }

  Future<void> _saveToCache(String text, String targetLang, String translation) async {
    final key = _getCacheKey(text, targetLang);
    final data = {
      'original': text,
      'translation': translation,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    await _prefs?.setString(key, json.encode(data));
  }

  /// Translate text with caching
  Future<String> translate(String text, {String? targetLang}) async {
    if (_prefs == null) await init();

    final lang = targetLang ?? _currentLanguage;

    if (lang.isEmpty || lang == 'en' || text.trim().isEmpty) {
      return text;
    }

    final cached = _getCachedTranslation(text, lang);
    if (cached != null) return cached;

    try {
      final translation = await _translator.translate(text, from: 'auto', to: lang);
      final translatedText = translation.text;
      await _saveToCache(text, lang, translatedText);
      return translatedText;
    } catch (e) {
      return text;
    }
  }

  /// Clear all cache
  Future<void> clearCache() async {
    if (_prefs == null) await init();

    final keys = _prefs?.getKeys() ?? {};
    for (final key in keys) {
      if (key.startsWith(_cachePrefix)) {
        await _prefs?.remove(key);
      }
    }
  }

  /// Clear cache for specific language
  Future<void> clearCacheForLanguage(String targetLang) async {
    if (_prefs == null) await init();

    final keys = _prefs?.getKeys() ?? {};
    for (final key in keys) {
      if (key.startsWith('$_cachePrefix$targetLang')) {
        await _prefs?.remove(key);
      }
    }
  }
}