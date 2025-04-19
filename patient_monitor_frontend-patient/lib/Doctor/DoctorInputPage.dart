import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'TranslationResultPage.dart';

class DoctorInputPage extends StatefulWidget {
  @override
  _DoctorInputPageState createState() => _DoctorInputPageState();
}

class _DoctorInputPageState extends State<DoctorInputPage> {
  final _textController = TextEditingController();
  final _languageController = TextEditingController();
  bool _loading = false;

  Future<void> _submitTranslation() async {
    setState(() {
      _loading = true;
    });

    final response = await http.post(
      Uri.parse('http://localhost:3100/api/v1/health-analytics/translate'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'text': _textController.text,
        'targetLanguage': _languageController.text,
      }),
    );

    setState(() {
      _loading = false;
    });

    if (response.statusCode == 201) {
      final Map<String, dynamic> responseData = json.decode(response.body);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TranslationResultPage(
            translation: responseData['result'], // only pass the translation
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Translation failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Center(
          child: Text(
            'Doctor Comment Translation',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
        ),
        backgroundColor: Colors.blue,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.red],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _textController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Doctor\'s Comment',
                  prefixIcon: Icon(Icons.comment),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _languageController,
                decoration: InputDecoration(
                  labelText: 'Target Language (e.g. Twi)',
                  prefixIcon: Icon(Icons.language),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              _loading
                  ? CircularProgressIndicator()
                  : ElevatedButton.icon(
                      onPressed: _submitTranslation,
                      icon: Icon(Icons.translate),
                      label: Text('Translate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}