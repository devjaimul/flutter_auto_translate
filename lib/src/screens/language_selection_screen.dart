import 'package:flutter/material.dart';
import '../models/language_model.dart';
import '../data/language_data.dart';
import '../services/translation_service.dart';

class LanguageSelectionScreen extends StatefulWidget {
  final String appBarTitle;
  final Color? primaryColor;

  const LanguageSelectionScreen({
    super.key,
    this.appBarTitle = 'Select Language',
    this.primaryColor,
  });

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  List<LanguageModel> allLanguages = [];
  List<LanguageModel> filteredLanguages = [];
  String selectedLanguageCode = 'en';
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLanguages();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _loadLanguages() {
    setState(() {
      allLanguages = LanguageData.getAllLanguages();
      filteredLanguages = allLanguages;
      selectedLanguageCode = TranslationService().currentLanguage;
    });
  }

  void _filterLanguages(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredLanguages = allLanguages;
      } else {
        filteredLanguages = allLanguages.where((language) {
          return language.name.toLowerCase().contains(query.toLowerCase()) ||
              language.code.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _selectLanguage(LanguageModel language) async {
    await TranslationService().setLanguage(language.code);

    setState(() {
      selectedLanguageCode = language.code;
    });

    if (mounted) {
      Navigator.pop(context, language);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = widget.primaryColor ?? theme.primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.appBarTitle),
        backgroundColor: primaryColor,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: primaryColor.withValues(alpha: 0.1),
            child: TextField(
              controller: searchController,
              onChanged: _filterLanguages,
              decoration: InputDecoration(
                hintText: 'Search languages...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          _filterLanguages('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredLanguages.length,
              itemBuilder: (context, index) {
                final language = filteredLanguages[index];
                final isSelected = language.code == selectedLanguageCode;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: isSelected ? 4 : 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? primaryColor : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: ListTile(
                    onTap: () => _selectLanguage(language),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primaryColor.withValues(alpha: 0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          language.flag,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                    title: Text(
                      language.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? primaryColor : Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      language.code.toUpperCase(),
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle, color: primaryColor)
                        : const Icon(Icons.circle_outlined, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
