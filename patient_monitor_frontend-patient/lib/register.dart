import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'otp_page.dart';
import 'login_page.dart';

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
  bool _obscurePassword = true;
  bool _allowRelative = false;

  static const String _baseUrl = 'http://localhost:3100';

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidCard(String card) {
    return RegExp(r'^\d+$').hasMatch(card) && card.length >= 6 && card.length <= 15;
  }

  String _sanitizeInput(String input) {
    return input.trim();
  }

  Future<void> _register(String name, String email, String card, String password, String type) async {
    name = _sanitizeInput(name);
    email = _sanitizeInput(email.toLowerCase());
    card = _sanitizeInput(card);
    password = _sanitizeInput(password);
    type = _sanitizeInput(type.toLowerCase());

    if (name.isEmpty || email.isEmpty || password.isEmpty || type.isEmpty || card.isEmpty) {
      _showError("All fields are required!");
      return;
    }

    if (!_isValidEmail(email)) {
      _showError("Please enter a valid email address!");
      return;
    }

    if (!_isValidCard(card)) {
      _showError("Ghana Card Number must be 6-15 digits!");
      return;
    }

    if (password.length < 6) {
      _showError("Password must be at least 6 characters!");
      return;
    }

    List<String> validTypes = ['patient', 'relative', 'doctor', 'nurse'];
    if (!validTypes.contains(type)) {
      _showError("User type must be one of: ${validTypes.join(', ')}");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final requestBody = {
        'name': name,
        'email': email,
        'card': int.parse(card),
        'password': password,
        'type': type,
      };

      final response = await http.post(
        Uri.parse('${_baseUrl}/api/v1/users'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 15));

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        if (responseData['success'] == true) {
          _showSuccess("Registration Successful", email);
        } else {
          _showError(responseData['message'] ?? "Registration failed");
        }
      } else {
        _showError(responseData['message'] ?? "Registration failed with status ${response.statusCode}");
      }
    } on FormatException {
      _showError("Invalid card number format");
    } on http.ClientException catch (e) {
      _showError("Failed to connect: ${e.message}");
    } on TimeoutException {
      _showError("Request timed out");
    } catch (e) {
      _showError("An error occurred");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccess(String message, String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 80,
              ),
              const SizedBox(height: 20),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                "Your account has been created successfully!",
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OTPVerificationPage(email: email),
                      ),
                    );
                  },
                  child: const Text(
                    "Continue",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> _showRelativeRegistrationDialog(String userCard) async {
    final _relativeNameController = TextEditingController();
    final _relativeEmailController = TextEditingController();
    final _relativePasswordController = TextEditingController();
    final _relativeCardNumberController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Register Relative"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _relativeNameController,
                decoration: const InputDecoration(labelText: "Name"),
              ),
              TextField(
                controller: _relativeEmailController,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              TextField(
                controller: _relativePasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password"),
              ),
              TextField(
                controller: _relativeCardNumberController,
                decoration: const InputDecoration(labelText: "Card Number"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              final name = _relativeNameController.text;
              final email = _relativeEmailController.text;
              final password = _relativePasswordController.text;
              final card = _relativeCardNumberController.text;

              if (name.isEmpty || email.isEmpty || password.isEmpty || card.isEmpty) {
                _showError("All fields are required!");
                return;
              }

              await _register(name, email, card, password, 'relative');
              Navigator.pop(context);
            },
            child: const Text("Register"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _typeController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue, Colors.red],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginPage()),
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
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
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 60),
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                  _inputField("Full Name", _nameController, Icons.person),
                  const SizedBox(height: 20),
                  _inputField("Email", _emailController, Icons.email),
                  const SizedBox(height: 20),
                  _passwordField(),
                  const SizedBox(height: 20),
                  _inputField("User Type", _typeController, Icons.person_outline),
                  const SizedBox(height: 20),
                  _inputField("Ghana Card Number", _cardController, Icons.credit_card),
                  const SizedBox(height: 20),
                  SwitchListTile(
                    title: const Text("Allow relative to view vitals", style: TextStyle(color: Colors.white)),
                    value: _allowRelative,
                    onChanged: (value) {
                      setState(() => _allowRelative = value);
                      if (value) _showRelativeRegistrationDialog(_cardController.text);
                    },
                    activeColor: Colors.green,
                  ),
                  const SizedBox(height: 50),
                  _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : _registerButton(),
                  const SizedBox(height: 20),
                  _loginText(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField(String label, TextEditingController controller, IconData icon) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.white),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
      ),
    );
  }

  Widget _passwordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: "Password",
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: const Icon(Icons.lock, color: Colors.white70),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.white70,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.white),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
      ),
    );
  }

  Widget _registerButton() {
    return ElevatedButton(
      onPressed: () => _register(
        _nameController.text,
        _emailController.text,
        _cardController.text,
        _passwordController.text,
        _typeController.text,
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue,
        padding: const EdgeInsets.symmetric(vertical: 16),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      child: const Text(
        "Register",
        style: TextStyle(fontSize: 20),
      ),
    );
  }

  Widget _loginText() {
    return GestureDetector(
      onTap: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      ),
      child: const Text(
        "Already have an account? Login",
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}