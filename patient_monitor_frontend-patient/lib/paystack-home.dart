import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class PaystackInitiatePage extends StatefulWidget {
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
        emailController.clear(); // Clear email
        amountController.clear(); // Clear amount
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
            Icon(Icons.payment, color: Colors.green),
            SizedBox(width: 10),
            Text("Payment Link"),
          ],
        ),
        content: const Text("Click below to complete your payment."),
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
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paystack Payment'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text(
                "Enter your email and amount to initiate a Paystack payment.",
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount (in pesewas)',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                        icon: const Icon(Icons.send),
                        label: const Text("Initiate Payment"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 20),
                          backgroundColor: Colors.teal,
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                        onPressed: initiatePayment,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
