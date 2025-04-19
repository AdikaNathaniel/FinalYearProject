import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
  bool _obscurePassword = true; // Track password visibility
  bool _allowRelative = false; // Track toggle state for allowing relative

  // Function to handle registration
  Future<void> _register(String name, String email, String card, String password, String type) async {
    // Validate fields
    if (name.isEmpty || email.isEmpty || password.isEmpty || type.isEmpty || card.isEmpty) {
      _showError("All fields are required!");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Register the user
      final response = await http.post(
        Uri.parse('http://localhost:3100/api/v1/users'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          'name': name,
          'email': email,
          'card': card,
          'password': password,
          'type': type,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201 && responseData['success']) {
        // If the user is registered successfully
        _showSuccess("Registration successful", email);
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

  // Function to show dialog for entering relative's details and register
  Future<void> _showRelativeRegistrationDialog(String userCard) async {
    final _relativeNameController = TextEditingController();
    final _relativeEmailController = TextEditingController();
    final _relativePasswordController = TextEditingController();
    final _relativeCardNumberController = TextEditingController();

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Register Relative"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _relativeNameController,
                  decoration: const InputDecoration(
                    labelText: "Relative's Name",
                  ),
                ),
                TextField(
                  controller: _relativeEmailController,
                  decoration: const InputDecoration(
                    labelText: "Relative's Email",
                  ),
                ),
                TextField(
                  controller: _relativePasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Relative's Password",
                  ),
                ),
                TextField(
                  controller: _relativeCardNumberController,
                  decoration: const InputDecoration(
                    labelText: "Relative's Card Number",
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                final relativeName = _relativeNameController.text;
                final relativeEmail = _relativeEmailController.text;
                final relativePassword = _relativePasswordController.text;
                final relativeCardNumber = _relativeCardNumberController.text;

                if (relativeName.isEmpty || relativeEmail.isEmpty || relativePassword.isEmpty || relativeCardNumber.isEmpty) {
                  _showError("All fields for relative are required!");
                  return;
                }

                // Register the relative
                await _register(relativeName, relativeEmail, relativeCardNumber, relativePassword, 'relative');
                // Call _showSuccess after registration
                _showSuccess("Relative registered successfully", relativeEmail);
                Navigator.of(context).pop(); // Close the dialog after success
              },
              child: const Text("Register"),
            ),
          ],
        );
      },
    );
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
                MaterialPageRoute(builder: (context) => LoginPage()),
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
                  _inputField("Full Name", _nameController, Icons.person),
                  const SizedBox(height: 20),
                  _inputField("Email", _emailController, Icons.email_outlined),
                  const SizedBox(height: 20),
                  _passwordField(), // Password field with visibility toggle
                  const SizedBox(height: 20),
                  _inputField("User Type", _typeController, Icons.person_outline),
                  const SizedBox(height: 20),
                  _inputField("Ghana Card Number", _cardController, Icons.credit_card),
                  const SizedBox(height: 20),

                  // Toggle for allowing relative to view vitals
                  SwitchListTile(
                    title: const Text("Allow relative to view my vitals"),
                    value: _allowRelative,
                    onChanged: (value) {
                      setState(() {
                        _allowRelative = value;
                      });
                      if (value) {
                        // Automatically show the registration dialog for the relative
                        _showRelativeRegistrationDialog(_cardController.text);
                      }
                    },
                    activeColor: Colors.green,
                    inactiveThumbColor: Colors.grey,
                  ),

                  const SizedBox(height: 50),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : _registerBtn(),
                  const SizedBox(height: 20),
                  _extraText(),
                  const SizedBox(height: 20),
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

  Widget _inputField(String labelText, TextEditingController controller, IconData iconData, {bool isPassword = false}) {
    return TextField(
      style: const TextStyle(color: Colors.white),
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(iconData, color: Colors.white70),
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
      obscureText: isPassword,
    );
  }

  Widget _passwordField() {
    return TextField(
      style: const TextStyle(color: Colors.white),
      controller: _passwordController,
      obscureText: _obscurePassword, // Use the state variable to control visibility
      decoration: InputDecoration(
        labelText: "Password",
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.white70,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword; // Toggle password visibility
            });
          },
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

  Widget _registerBtn() {
    return ElevatedButton(
      onPressed: () {
        _register(
          _nameController.text,
          _emailController.text,
          _cardController.text,
          _passwordController.text,
          _typeController.text,
        );
      },
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
          MaterialPageRoute(builder: (context) => LoginPage()),
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
}