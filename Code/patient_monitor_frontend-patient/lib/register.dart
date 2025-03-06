import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart'; // Import for rootBundle
import 'dart:html' as html; // Import for web download
import 'otp_page.dart'; // Import the OTP verification page
import 'login_page.dart'; // Import the login page

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _typeController = TextEditingController(); 
  final _cardController = TextEditingController();
  bool _isLoading = false;

  // Function to handle registration
  Future<void> _register() async {
    final name = _nameController.text;
    final email = _emailController.text;
    final card = _cardController.text;
    final password = _passwordController.text;
    final type = _typeController.text; // Get user type from the new field

    // Validate fields
    if (name.isEmpty || email.isEmpty || password.isEmpty || type.isEmpty) {
      _showError("All fields are required!");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3100/api/v1/users'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          'name': name,
          'email': email,
          'card': card,
          'password': password,
          'type': type, // Include user type in the request
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201 && responseData['success']) {
        _showSuccess("Registration successful", email); // Pass email to success dialog
      } else {
        _showError(responseData['message'] ?? "Something went wrong.");
      }
    } catch (error) {
      _showError("Failed to connect to the server.");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Show error messages in dialog
  void _showError(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Center(child: Text('Error')),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text('OK'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  // Show success messages in dialog and navigate to OTP page
  void _showSuccess(String message, String email) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Center(child: Text('You are a registered user!')),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text('OK'),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OTPVerificationPage(email: email), // Navigate to OTP page
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Function to download the PDF
  Future<void> _downloadPDF() async {
    final ByteData bytes = await rootBundle.load('Gaming_Ecommerce_Terms.pdf');
    final buffer = bytes.buffer.asUint8List();

    // Create a blob and trigger a download
    final blob = html.Blob([buffer], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'Gaming_Ecommerce_Terms.pdf')
      ..click();
    html.Url.revokeObjectUrl(url); // Clean up the URL
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Colors.blue,
            Colors.red,
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _icon(),
                  const SizedBox(height: 50),
                  _inputField("Full Name", _nameController),
                  const SizedBox(height: 20),
                  _inputField("Email", _emailController),
                  const SizedBox(height: 20),
                  _inputField("Password", _passwordController, isPassword: true),
                  const SizedBox(height: 20),
                  _inputField("User Type", _typeController),
                     const SizedBox(height: 20),
                  _inputField("Ghana Card Number", _cardController),
                  const SizedBox(height: 50),
                  _isLoading
                      ? CircularProgressIndicator()
                      : _registerBtn(),
                  const SizedBox(height: 20),
                  _extraText(),
                  const SizedBox(height: 20),
                  // _termsText(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _icon() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 2),
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/pregnant.png',
          width: 120,
          height: 120,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _inputField(String hintText, TextEditingController controller,
      {bool isPassword = false}) {
    var border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Colors.white),
    );
    return TextField(
      style: const TextStyle(color: Colors.white),
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white),
        enabledBorder: border,
        focusedBorder: border,
      ),
      obscureText: isPassword,
    );
  }

  Widget _registerBtn() {
    return ElevatedButton(
      onPressed: _register,
      style: ElevatedButton.styleFrom(
        shape: const StadiumBorder(),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: const SizedBox(
        width: double.infinity,
        child: Text(
          "Register",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }

  Widget _extraText() {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      },
      child: const Text(
        "Already have an account? Login",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          color: Colors.white,
        ),
      ),
    );
  }

  // Widget _termsText() {
  //   return Row(
  //     mainAxisAlignment: MainAxisAlignment.center,
  //     children: [
  //       Text("By clicking Register, you agree to "),
  //       GestureDetector(
  //         onTap: _downloadPDF,
  //         child: Text(
  //           "our Terms of Service and Privacy Policy",
  //           style: TextStyle(
  //             color: Colors.blue,
  //             fontWeight: FontWeight.bold,
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }
}