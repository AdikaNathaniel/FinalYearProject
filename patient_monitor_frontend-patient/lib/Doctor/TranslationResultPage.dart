import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class TranslationResultPage extends StatefulWidget {
  final String originalText;
  final String translation;
  final String timestamp;

 
 TranslationResultPage({
    this.originalText = '',
    this.translation = '',
    String? timestamp,
  }) : this.timestamp = timestamp ?? DateTime.now().toIso8601String();

  @override
  _TranslationResultPageState createState() => _TranslationResultPageState();
}

class _TranslationResultPageState extends State<TranslationResultPage> {
  late String _filteredTranslation;

  @override
  void initState() {
    super.initState();
    _filteredTranslation = _filterOutEnglish(widget.translation);
    _saveTranslation();
  }

  // Filter out English text and characters
  String _filterOutEnglish(String text) {
    // Define regex pattern for common English characters and words
    // This regex matches sequences that look like English words
    // (a-z and A-Z characters separated by spaces or punctuation)
    RegExp englishPattern = RegExp(r'[a-zA-Z]+\s*[a-zA-Z]*\s*[a-zA-Z]*');
    
    // If the API returns something like "English: [text] | Twi: [translation]"
    // Extract only the part after a separator like "|", ":", or "-"
    if (text.contains(":")) {
      final parts = text.split(":");
      if (parts.length > 1) {
        return _filterOutEnglish(parts.sublist(1).join(":").trim());
      }
    }
    
    if (text.contains("|")) {
      final parts = text.split("|");
      if (parts.length > 1) {
        return _filterOutEnglish(parts.last.trim());
      }
    }
    
    if (text.contains("-")) {
      final parts = text.split("-");
      if (parts.length > 1 && parts[0].trim().contains(englishPattern)) {
        return _filterOutEnglish(parts.last.trim());
      }
    }

    // Replace sequences that look like English words with empty strings
    String filtered = text.replaceAll(englishPattern, '');
    
    // Remove any double spaces created by the replacements
    filtered = filtered.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // If after filtering we have an empty string, return the original
    // (This is a fallback in case our filtering was too aggressive)
    return filtered.isEmpty ? text : filtered;
  }

  Future<void> _saveTranslation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('translation_history') ?? [];

    final entry = json.encode({
      'text': widget.originalText,
      'translation': widget.translation,
      'filteredTranslation': _filteredTranslation,
      'timestamp': widget.timestamp,
    });

    history.add(entry);
    await prefs.setStringList('translation_history', history);
  }

  @override
  Widget build(BuildContext context) {
    DateTime dt = DateTime.parse(widget.timestamp);
    String formattedDate = "${dt.toLocal()}";

    return Scaffold(
      appBar: AppBar(
        title: Text('Translation Result'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show only the filtered translated text
            ListTile(
              leading: Icon(Icons.translate, color: Colors.teal),
              title: Text('Translated Text', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(_filteredTranslation),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.access_time, color: Colors.teal),
              title: Text('Translation Time', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(formattedDate),
            ),
          ],
        ),
      ),
    );
  }
}