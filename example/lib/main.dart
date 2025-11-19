import 'package:flutter/material.dart';
import 'package:flutter_auto_translate/flutter_auto_translate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TranslationService().init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auto Translate Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AutoTranslate(
          child: Text('My App'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LanguageSelectionScreen(),
                ),
              );
              setState(() {}); // Rebuild to show translations
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Example 1: Wrap your existing Text widget
            const AutoTranslate(
              child: Text(
                'Welcome to Flutter!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 20),

            // Example 2: Your custom text widget wrapped
            const AutoTranslate(
              child: Text(
                'This is a subtitle text that will be translated automatically.',
                style: TextStyle(fontSize: 16),
              ),
            ),

            const SizedBox(height: 20),

            // Example 3: Disable translation for specific text
            const AutoTranslate(
              enable: false,
              child: Text(
                'API_KEY_12345', // Won't be translated
                style: TextStyle(fontFamily: 'monospace'),
              ),
            ),

            const SizedBox(height: 40),

            // Your existing custom widgets work too!
            const CustomTextOne(text: 'Hello from custom widget'),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LanguageSelectionScreen(),
                  ),
                );
                setState(() {});
              },
              child: const AutoTranslate(
                child: Text('Change Language'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Your existing custom text widget - just wrap with AutoTranslate!
class CustomTextOne extends StatelessWidget {
  final String text;

  const CustomTextOne({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return AutoTranslate(
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.blue,
        ),
      ),
    );
  }
}
