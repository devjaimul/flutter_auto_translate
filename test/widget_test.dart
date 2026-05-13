import 'package:flutter/material.dart';
import 'package:flutter_auto_translate/flutter_auto_translate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    // Reset SharedPreferences and the singleton state before each test so
    // tests cannot leak language / cache state across each other.
    SharedPreferences.setMockInitialValues(<String, Object>{});
    TranslationService().debugReset();
    // Prevent the translator package from making real network requests
    // during tests; uncached strings simply resolve to their originals.
    TranslationService().debugDisableNetwork = true;
    await TranslationService().init();
  });

  group('TranslationService', () {
    test('returns original text when target language is English', () async {
      final translated =
          await TranslationService().translate('Hello', targetLang: 'en');
      expect(translated, 'Hello');
    });

    test('returns original text for empty input', () async {
      final translated =
          await TranslationService().translate('', targetLang: 'es');
      expect(translated, '');
    });

    test('exposes ChangeNotifier semantics on setLanguage', () async {
      var notifications = 0;
      void listener() => notifications++;
      TranslationService().addListener(listener);
      addTearDown(() => TranslationService().removeListener(listener));

      await TranslationService().setLanguage('es');
      expect(TranslationService().currentLanguage, 'es');
      expect(notifications, greaterThanOrEqualTo(1));

      // Setting the same language again is a no-op (no extra notification)
      // so reactive widgets don't rebuild unnecessarily.
      final beforeSame = notifications;
      await TranslationService().setLanguage('es');
      expect(notifications, beforeSame);
    });

    test('isCached / getCached are synchronous for English source', () {
      expect(
        TranslationService().isCached('Hello', targetLang: 'en'),
        isTrue,
      );
      expect(
        TranslationService().getCached('Hello', targetLang: 'en'),
        'Hello',
      );
    });

    test('debugSetCachedTranslation makes getCached resolve immediately',
        () async {
      TranslationService().debugSetCachedTranslation(
        'Hello',
        targetLang: 'es',
        translation: 'Hola',
      );
      expect(
        TranslationService().getCached('Hello', targetLang: 'es'),
        'Hola',
      );
      expect(
        TranslationService().isCached('Hello', targetLang: 'es'),
        isTrue,
      );
    });

    test('translate falls back to original text when network is disabled',
        () async {
      await TranslationService().setLanguage('es');
      final result = await TranslationService().translate('Hello');
      expect(result, 'Hello');
    });
  });

  group('AutoTranslate', () {
    testWidgets('renders the original Text when language is English',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AutoTranslate(child: Text('Hello world')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Hello world'), findsOneWidget);
    });

    testWidgets('does NOT show a per-widget loader by default',
        (tester) async {
      await TranslationService().setLanguage('es');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AutoTranslate(child: Text('Hello world')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // No spinner should be visible — we keep showing the original text
      // instead of swapping to a loading indicator.
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Hello world'), findsOneWidget);
    });

    testWidgets('renders cached translation when available', (tester) async {
      TranslationService().debugSetCachedTranslation(
        'Hello world',
        targetLang: 'es',
        translation: 'Hola mundo',
      );
      await TranslationService().setLanguage('es');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AutoTranslate(child: Text('Hello world')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hola mundo'), findsOneWidget);
      expect(find.text('Hello world'), findsNothing);
    });

    testWidgets('translates the hintText of a wrapped TextField',
        (tester) async {
      const original = 'Search products';
      const translated = 'Buscar productos';
      TranslationService().debugSetCachedTranslation(
        original,
        targetLang: 'es',
        translation: translated,
      );
      await TranslationService().setLanguage('es');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AutoTranslate(
              child: TextField(
                decoration: InputDecoration(hintText: original),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textFieldWidget =
          tester.widget<TextField>(find.byType(TextField));
      expect(textFieldWidget.decoration?.hintText, translated);
    });

    testWidgets('updates reactively when the language changes',
        (tester) async {
      TranslationService().debugSetCachedTranslation(
        'Hello',
        targetLang: 'es',
        translation: 'Hola',
      );
      TranslationService().debugSetCachedTranslation(
        'Hello',
        targetLang: 'fr',
        translation: 'Bonjour',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AutoTranslate(child: Text('Hello')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Hello'), findsOneWidget);

      await TranslationService().setLanguage('es');
      await tester.pumpAndSettle();
      expect(find.text('Hola'), findsOneWidget);
      expect(find.text('Hello'), findsNothing);

      await TranslationService().setLanguage('fr');
      await tester.pumpAndSettle();
      expect(find.text('Bonjour'), findsOneWidget);
      expect(find.text('Hola'), findsNothing);
    });
  });

  group('AutoTranslateField', () {
    testWidgets('translates hintText, labelText and helperText',
        (tester) async {
      TranslationService().debugSetCachedTranslation(
        'Email address',
        targetLang: 'es',
        translation: 'Correo electrónico',
      );
      TranslationService().debugSetCachedTranslation(
        'you@example.com',
        targetLang: 'es',
        translation: 'tu@ejemplo.com',
      );
      TranslationService().debugSetCachedTranslation(
        'We will never share your email',
        targetLang: 'es',
        translation: 'Nunca compartiremos tu correo',
      );
      await TranslationService().setLanguage('es');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AutoTranslateField(
              decoration: InputDecoration(
                hintText: 'you@example.com',
                labelText: 'Email address',
                helperText: 'We will never share your email',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.decoration?.hintText, 'tu@ejemplo.com');
      expect(field.decoration?.labelText, 'Correo electrónico');
      expect(
        field.decoration?.helperText,
        'Nunca compartiremos tu correo',
      );
    });

    testWidgets('respects enableTranslation = false', (tester) async {
      TranslationService().debugSetCachedTranslation(
        'Search',
        targetLang: 'es',
        translation: 'Buscar',
      );
      await TranslationService().setLanguage('es');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AutoTranslateField(
              enableTranslation: false,
              decoration: InputDecoration(hintText: 'Search'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.decoration?.hintText, 'Search');
    });
  });

  group('AutoTranslateScope', () {
    testWidgets('hides the loader once pending translations resolve',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AutoTranslateScope(
              minLoaderDuration: Duration(milliseconds: 50),
              child: Center(child: AutoTranslate(child: Text('Hello'))),
            ),
          ),
        ),
      );
      // Loader is visible immediately because showOnFirstBuild defaults to
      // true.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 80));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('skips the loader when showOnFirstBuild is false',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AutoTranslateScope(
              showOnFirstBuild: false,
              child: Text('Hi'),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Hi'), findsOneWidget);
    });

    testWidgets('flashes the loader on language change', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AutoTranslateScope(
              showOnFirstBuild: false,
              minLoaderDuration: Duration(milliseconds: 100),
              child: AutoTranslate(child: Text('Hello')),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await TranslationService().setLanguage('es');
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
