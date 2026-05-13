import 'package:flutter/material.dart';
import 'package:flutter_auto_translate/flutter_auto_translate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TranslationService().init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // No need to call setState anywhere - AutoTranslate listens to the
        // service and updates automatically when the language changes.
        title: const AutoTranslate(
          child: Text('Auto Translate Demo'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LanguageSelectionScreen(),
                ),
              );
            },
          ),
        ],
      ),
      // AutoTranslateScope shows a single full-screen loader while the
      // first batch of translations for this screen is being fetched, and
      // again briefly when the user changes the language.
      body: AutoTranslateScope(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AutoTranslate(
                child: Text(
                  'Welcome to Flutter!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              const AutoTranslate(
                child: Text(
                  'This subtitle will be translated automatically.',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 24),

              // 1. Translating a hint on a regular TextField — wrap with
              //    AutoTranslate.
              AutoTranslate(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search products',
                    labelText: 'Search',
                    helperText: 'Type to filter the catalogue',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Or use the dedicated AutoTranslateField. Best choice
              //    when you need the explicit TextField API surface.
              AutoTranslateField(
                controller: _emailController,
                decoration: const InputDecoration(
                  hintText: 'you@example.com',
                  labelText: 'Email address',
                  helperText: 'We will never share your email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // 3. Disable translation for specific text.
              const AutoTranslate(
                enable: false,
                child: Text(
                  'API_KEY_12345',
                  style: TextStyle(fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 24),

              const CustomTextOne(text: 'Hello from a custom widget'),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LanguageSelectionScreen(),
                    ),
                  );
                },
                child: const AutoTranslate(
                  child: Text('Change language'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
