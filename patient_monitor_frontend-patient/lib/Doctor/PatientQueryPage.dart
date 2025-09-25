import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PatientQueryPage extends StatefulWidget {
  @override
  _PatientQueryPageState createState() => _PatientQueryPageState();
}

class _PatientQueryPageState extends State<PatientQueryPage> {
  final _formKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
  final _questionController = TextEditingController();
  bool _isLoading = false;
  String _responseText = '';

  @override
  void dispose() {
    _patientNameController.dispose();
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _submitQuery() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _responseText = '';
    });

    try {
      final response = await http.get(
        Uri.parse(
          'http://localhost:3100/api/v1/health-analytics/query?patientName=${Uri.encodeComponent(_patientNameController.text)}&question=${Uri.encodeComponent(_questionController.text)}',
        ),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success']) {
          setState(() {
            _responseText = responseData['result'];
          });
        } else {
          throw Exception('Error: ${responseData['message']}');
        }
      } else {
        throw Exception('Failed to fetch response: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<TextSpan> _processBoldText(String text) {
    final List<TextSpan> textSpans = [];
    if (text.contains('**')) {
      final regex = RegExp(r'\*\*(.*?)\*\*|([^*]+)');
      final matches = regex.allMatches(text);
      for (var match in matches) {
        if (match.group(1) != null) {
          textSpans.add(TextSpan(
            text: match.group(1),
            style: TextStyle(fontWeight: FontWeight.bold),
          ));
        } else if (match.group(2) != null) {
          textSpans.add(TextSpan(
            text: match.group(2),
            style: TextStyle(),
          ));
        }
      }
    } else {
      textSpans.add(TextSpan(text: text, style: TextStyle()));
    }
    return textSpans;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Query Tool'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _patientNameController,
                        decoration: const InputDecoration(
                          labelText: 'Patient Name',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _questionController,
                        decoration: const InputDecoration(
                          labelText: 'Your Question',
                          prefixIcon: Icon(Icons.question_answer),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _submitQuery,
                        icon: const Icon(Icons.send),
                        label: const Text('Submit Query'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_responseText.isNotEmpty)
              Expanded(
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Response:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          RichText(
                            text: TextSpan(
                              children: _processBoldText(_responseText),
                              style: TextStyle(color: Colors.black), // Default text color
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}