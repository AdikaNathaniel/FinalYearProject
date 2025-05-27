import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PinDeleteScreen extends StatefulWidget {
  const PinDeleteScreen({Key? key}) : super(key: key);

  @override
  _PinDeleteScreenState createState() => _PinDeleteScreenState();
}

class _PinDeleteScreenState extends State<PinDeleteScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController userIdController = TextEditingController();
  bool _isLoading = false;

  Future<void> deletePin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse('http://localhost:3100/api/v1/pin/${userIdController.text.trim()}');

      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final message = responseData['message'] ?? 'PIN deleted successfully';
        _showSuccessDialog(message);
      } else {
        String errorMessage = "Failed to delete PIN (Status: ${response.statusCode})";
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (e) {
          // If response body is not JSON, use default message
        }
        _showErrorDialog(errorMessage);
      }
    } catch (e) {
      String errorMessage = "Error occurred: ";
      if (e.toString().contains('TimeoutException')) {
        errorMessage += "Request timed out. Please try again.";
      } else if (e.toString().contains('SocketException')) {
        errorMessage += "Network error. Please check your connection.";
      } else {
        errorMessage += e.toString();
      }
      _showErrorDialog(errorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessDialog([String? message]) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 10),
            Text("Success"),
          ],
        ),
        content: Text(message ?? "PIN deleted successfully."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearAllFields();
            },
            child: const Text("OK", style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 10),
            Text("Error"),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _clearAllFields() {
    userIdController.clear();
    FocusScope.of(context).requestFocus(FocusNode());
  }

  @override
  void dispose() {
    userIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Delete PIN"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFF8F9FA)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: userIdController,
                    decoration: InputDecoration(
                      labelText: 'UserName',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.grey, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    validator: (value) => 
                        (value == null || value.trim().isEmpty) ? 'Please enter user name' : null,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : deletePin,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.lock_open, color: Colors.white),
                              SizedBox(width: 8),
                              Text("Delete PIN"),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}