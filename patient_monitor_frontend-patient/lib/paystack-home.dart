import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class PaystackInitiatePage extends StatefulWidget {
  const PaystackInitiatePage({Key? key}) : super(key: key);

  @override
  _PaystackInitiatePageState createState() => _PaystackInitiatePageState();
}

class _PaystackInitiatePageState extends State<PaystackInitiatePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  bool isLoading = false;

  Future<void> initiatePayment() async {
    final email = emailController.text.trim();
    final amount = int.tryParse(amountController.text.trim()) ?? 0;

    if (email.isEmpty || amount <= 0) {
      _showMessage("Please enter a valid email and amount.");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse("https://patient-monitor-backend-patient.fly.dev/api/v1/paystack/initiate"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"email": email, "amount": amount}),
      );

      final result = jsonDecode(response.body);

      if (response.statusCode == 201 && result['success'] == true) {
        final url = result['result']['data']['authorization_url'];
        emailController.clear(); 
        amountController.clear(); 
        _showAuthorizationDialog(url);
      } else {
        _showMessage(result['message'] ?? 'Failed to initiate payment.');
      }
    } catch (e) {
      _showMessage("Error: ${e.toString()}");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showAuthorizationDialog(String url) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.payment, color: Colors.blue),
            SizedBox(width: 10),
            Text("Payment Link"),
          ],
        ),
        content: const Text("Click To Complete Your Payment."),
        actions: [
          TextButton(
            child: const Text("Open Payment Link"),
            onPressed: () async {
              Navigator.of(context).pop();
              if (await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(
                  Uri.parse(url),
                  mode: LaunchMode.inAppWebView,
                );
              } else {
                _showMessage("Could not open Paystack URL.");
              }
            },
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    emailController.clear();
    amountController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paystack Payment'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: Text(
                  "Enter your email and amount to initiate a Paystack payment.",
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
              ),
              
              // Email Field
              _buildTextField(
                emailController, 
                "Email", 
                Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
              
              // Amount Field
              _buildTextField(
                amountController, 
                "Amount ", 
                Icons.attach_money,
                keyboardType: TextInputType.number,
              ),
              
              const SizedBox(height: 24),
              
              // Submit Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: isLoading ? null : initiatePayment,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Initiate Payment",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),

              const SizedBox(height: 16),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, 
    String label, 
    IconData icon, 
    {TextInputType? keyboardType}
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        validator: (value) => value == null || value.isEmpty ? 'This field is required' : null,
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    amountController.dispose();
    super.dispose();
  }
}