import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

class PinUpdateScreen extends StatefulWidget {
  const PinUpdateScreen({Key? key}) : super(key: key);

  @override
  _PinUpdateScreenState createState() => _PinUpdateScreenState();
}

class _PinUpdateScreenState extends State<PinUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController userIdController = TextEditingController();
  final TextEditingController newPinController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  List<TextEditingController> _pinControllers = [];
  List<FocusNode> _pinFocusNodes = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    // Clear existing controllers if any
    _disposeControllers();
    
    // Initialize new controllers
    _pinControllers = List.generate(6, (index) => TextEditingController());
    _pinFocusNodes = List.generate(6, (index) => FocusNode());
    
    // Add listeners to focus nodes
    for (int i = 0; i < _pinFocusNodes.length; i++) {
      _pinFocusNodes[i].addListener(() {
        if (mounted) setState(() {});
      });
    }
  }

  void _disposeControllers() {
    for (var controller in _pinControllers) {
      controller.dispose();
    }
    for (var focusNode in _pinFocusNodes) {
      focusNode.dispose();
    }
  }

  Future<void> updatePin() async {
    if (!_formKey.currentState!.validate()) return;

    final oldPin = _pinControllers.map((c) => c.text.trim()).join('');
    if (oldPin.length != 6) {
      _showErrorDialog("Please enter complete 6-digit old PIN");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('http://localhost:3100/api/v1/pin');
      final requestBody = {
        "userId": userIdController.text.trim(),
        "oldPin": oldPin,
        "newPin": newPinController.text.trim(),
        "phone": phoneController.text.trim(),
      };

      print('Request: ${jsonEncode(requestBody)}');

      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      print('Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        _showSuccessDialog(responseData['message'] ?? 'PIN updated successfully');
      } else {
        String error = "Failed to update PIN (${response.statusCode})";
        try {
          error = jsonDecode(response.body)['message'] ?? error;
        } catch (_) {}
        _showErrorDialog(error);
      }
    } catch (e) {
      print('Error: $e');
      String error = "Error occurred: ";
      if (e.toString().contains('TimeoutException')) {
        error += "Request timed out";
      } else if (e.toString().contains('SocketException')) {
        error += "Network error";
      } else {
        error += e.toString();
      }
      _showErrorDialog(error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        content: Text(message ?? "PIN updated successfully"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
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
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _clearAllFields() {
    userIdController.clear();
    newPinController.clear();
    phoneController.clear();
    for (var c in _pinControllers) c.clear();
    FocusScope.of(context).requestFocus(FocusNode());
    if (mounted) setState(() {});
  }

  Widget _buildPinInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Enter your old PIN:",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 45,
              height: 55,
              child: TextFormField(
                controller: _pinControllers[index],
                focusNode: _pinFocusNodes[index],
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(1),
                ],
                obscureText: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _pinFocusNodes[index].hasFocus 
                          ? Colors.blueAccent 
                          : Colors.grey,
                      width: 2,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.grey, width: 1.5),
                  ),
                  filled: true,
                  fillColor: _pinFocusNodes[index].hasFocus
                      ? Colors.blue.shade50
                      : Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty && index < 5) {
                    FocusScope.of(context).requestFocus(_pinFocusNodes[index + 1]);
                  } else if (value.isEmpty && index > 0) {
                    FocusScope.of(context).requestFocus(_pinFocusNodes[index - 1]);
                  }
                  if (mounted) setState(() {});
                },
                validator: (value) => 
                    value?.isEmpty ?? true ? '' : null,
              ),
            );
          }),
        ),
      ],
    );
  }

  @override
  void dispose() {
    userIdController.dispose();
    newPinController.dispose();
    phoneController.dispose();
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Update PIN"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        foregroundColor: Colors.white,
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
                      labelText: 'User Name',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                    ),
                    validator: (value) => 
                        value?.trim().isEmpty ?? true 
                            ? 'Please enter user name' 
                            : null,
                  ),
                  const SizedBox(height: 24),
                  _buildPinInput(),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: newPinController,
                    decoration: InputDecoration(
                      labelText: 'New PIN',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter new PIN';
                      }
                      if (value.trim().length < 4) {
                        return 'PIN must be at least 4 digits';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                    ),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter phone number';
                      }
                      if (value.trim().length < 10) {
                        return 'Please enter a valid phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : updatePin,
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
                        : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_open),
                              SizedBox(width: 8),
                              Text("Update PIN"),
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