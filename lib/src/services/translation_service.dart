import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:translator/translator.dart';

/// Service for managing translations and caching.
///
/// Exposes a [ChangeNotifier] surface so widgets can react to language changes
/// and cache updates without triggering full screen rebuilds via [setState].
///
/// The service keeps a synchronous in-memory cache that mirrors the persistent
/// [SharedPreferences] cache so widgets can look up translations during build
/// without flickering between the original and translated text.
class TranslationService extends ChangeNotifier {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  final GoogleTranslator _translator = GoogleTranslator();
  SharedPreferences? _prefs;
  String _currentLanguage = 'en';

  /// Language codes that should always be returned as-is (no API call).
  static const String _defaultSourceLanguage = 'en';

  static const String _cachePrefix = 'auto_translate_cache_';
  static const String _languageKey = 'auto_translate_language';

  /// Synchronous mirror of the on-disk cache. Allows widgets to resolve
  /// translations during build without async work.
  final Map<String, String> _memoryCache = <String, String>{};

  /// Deduplicates in-flight translation requests for the same text+language.
  final Map<String, Future<String>> _inFlight = <String, Future<String>>{};

  /// Number of translation requests currently in flight. Listeners can use
  /// this to render a single full-screen loader instead of per-widget
  /// shimmer effects.
  final ValueNotifier<int> _pendingCount = ValueNotifier<int>(0);

  /// Read-only listenable for the number of pending translation requests.
  ValueListenable<int> get pendingCount => _pendingCount;

  /// `true` while at least one translation is being fetched.
  bool get isTranslating => _pendingCount.value > 0;

  bool _initialized = false;

  /// When `true`, [translate] returns the input text without making any
  /// network request. Intended exclusively for widget tests that should not
  /// hit the live Google Translate API.
  @visibleForTesting
  bool debugDisableNetwork = false;

  /// Initialize the service. Loads the persisted language and pre-warms the
  /// in-memory cache from disk so subsequent reads are synchronous.
  Future<void> init() async {
    if (_initialized) return;
    _prefs ??= await SharedPreferences.getInstance();
    _currentLanguage = _prefs?.getString(_languageKey) ?? _defaultSourceLanguage;
    _hydrateMemoryCache();
    _initialized = true;
  }

  void _hydrateMemoryCache() {
    final keys = _prefs?.getKeys() ?? <String>{};
    for (final key in keys) {
      if (!key.startsWith(_cachePrefix)) continue;
      final raw = _prefs?.getString(key);
      if (raw == null) continue;
      try {
        final Map<String, dynamic> data =
            json.decode(raw) as Map<String, dynamic>;
        final translation = data['translation'] as String?;
        if (translation != null) {
          _memoryCache[key] = translation;
        }
      } catch (_) {
        // Ignore corrupted entries; they will be overwritten on next fetch.
      }
    }
  }

  /// Current target language code.
  String get currentLanguage => _currentLanguage;

  /// Update the active language. Notifies listeners so reactive widgets can
  /// rebuild without forcing the developer to call [State.setState].
  Future<void> setLanguage(String languageCode) async {
    if (!_initialized) await init();
    if (_currentLanguage == languageCode) return;
    _currentLanguage = languageCode;
    await _prefs?.setString(_languageKey, languageCode);
    notifyListeners();
  }

  String _cacheKey(String text, String targetLang) =>
      '$_cachePrefix${targetLang}_${text.hashCode}';

  /// Returns `true` when [text] does not require a translation call for
  /// [targetLang] (empty input or same language as the source).
  bool _isNoOp(String text, String targetLang) {
    return text.trim().isEmpty ||
        targetLang.isEmpty ||
        targetLang == _defaultSourceLanguage;
  }

  /// Synchronously returns the cached translation for [text] in
  /// [targetLang], or `null` if no cached value exists. Returns the original
  /// [text] for no-op cases (empty text or source language).
  String? getCached(String text, {String? targetLang}) {
    final lang = targetLang ?? _currentLanguage;
    if (_isNoOp(text, lang)) return text;
    return _memoryCache[_cacheKey(text, lang)];
  }

  /// Whether [text] is already translated for [targetLang].
  bool isCached(String text, {String? targetLang}) {
    final lang = targetLang ?? _currentLanguage;
    if (_isNoOp(text, lang)) return true;
    return _memoryCache.containsKey(_cacheKey(text, lang));
  }

  Future<void> _persistTranslation(
      String text, String lang, String translation) async {
    final key = _cacheKey(text, lang);
    _memoryCache[key] = translation;
    final payload = <String, dynamic>{
      'original': text,
      'translation': translation,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    await _prefs?.setString(key, json.encode(payload));
  }

  /// Translate [text] into [targetLang] (or the current language) and cache
  /// the result. Concurrent requests for the same text are deduplicated.
  Future<String> translate(String text, {String? targetLang}) async {
    if (!_initialized) await init();

    final lang = targetLang ?? _currentLanguage;
    if (_isNoOp(text, lang)) return text;
    if (debugDisableNetwork) return text;

    final cached = _memoryCache[_cacheKey(text, lang)];
    if (cached != null) return cached;

    final key = _cacheKey(text, lang);
    final existing = _inFlight[key];
    if (existing != null) return existing;

    _pendingCount.value = _pendingCount.value + 1;
    final future = _performTranslation(text, lang);
    _inFlight[key] = future;

    // Decrement the pending counter and notify listeners after the work is
    // done. We do this on a separate future chain so callers that re-await
    // the in-flight future still see the same result.
    future.whenComplete(() {
      _inFlight.remove(key);
      _pendingCount.value =
          (_pendingCount.value - 1).clamp(0, 1 << 31).toInt();
      // Notify so reactive widgets can refresh once new translations are
      // available in the cache.
      notifyListeners();
    });

    return future;
  }

  Future<String> _performTranslation(String text, String lang) async {
    try {
      final result =
          await _translator.translate(text, from: 'auto', to: lang);
      final translated = result.text;
      await _persistTranslation(text, lang, translated);
      return translated;
    } catch (_) {
      // On failure, fall back to the original text so the UI stays usable.
      return text;
    }
  }

  /// Pre-fetch translations for a batch of texts. Useful for warming the
  /// cache for a screen before showing it.
  Future<void> preload(Iterable<String> texts, {String? targetLang}) async {
    final lang = targetLang ?? _currentLanguage;
    if (lang == _defaultSourceLanguage) return;
    await Future.wait(
      texts.where((t) => t.trim().isNotEmpty).map(
            (t) => translate(t, targetLang: lang),
          ),
    );
  }

  /// Clear all cached translations across every language.
  Future<void> clearCache() async {
    if (!_initialized) await init();
    final keys = _prefs?.getKeys() ?? <String>{};
    for (final key in keys) {
      if (key.startsWith(_cachePrefix)) {
        await _prefs?.remove(key);
      }
    }
    _memoryCache.clear();
    notifyListeners();
  }

  /// Clear cached translations for a single language.
  Future<void> clearCacheForLanguage(String targetLang) async {
    if (!_initialized) await init();
    final prefix = '$_cachePrefix${targetLang}_';
    final keys = _prefs?.getKeys() ?? <String>{};
    for (final key in keys) {
      if (key.startsWith(prefix)) {
        await _prefs?.remove(key);
        _memoryCache.remove(key);
      }
    }
    notifyListeners();
  }

  /// Test-only helper that seeds the in-memory cache with a known
  /// translation. This bypasses both the on-disk cache and the network
  /// call inside [translate], so widget tests can exercise the
  /// translated-render path without hitting Google Translate.
  @visibleForTesting
  void debugSetCachedTranslation(
    String text, {
    required String targetLang,
    required String translation,
  }) {
    _memoryCache[_cacheKey(text, targetLang)] = translation;
  }

  /// Test-only helper that resets the singleton's runtime state. Useful in
  /// `setUp` to keep tests isolated.
  @visibleForTesting
  void debugReset() {
    _memoryCache.clear();
    _inFlight.clear();
    _pendingCount.value = 0;
    _currentLanguage = _defaultSourceLanguage;
    _initialized = false;
    _prefs = null;
    debugDisableNetwork = false;
  }

  @override
  void dispose() {
    _pendingCount.dispose();
    super.dispose();
  }
}
