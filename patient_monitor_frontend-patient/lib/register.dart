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
  final _cardPart1Controller = TextEditingController();
  final _cardPart2Controller = TextEditingController();
  final _cardPart3Controller = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _allowRelative = false;
  String _selectedUserType = 'pregnant-woman';

  static const String _baseUrl = 'https://patient-monitor-backend-patient.fly.dev';

  // User type options
  final List<String> _userTypes = [
    'pregnant-woman',
    'relative', 
    'doctor',
    'admin',
    'midwife',
    'wellness-user'
  ];

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidCardPart(String part) {
    return RegExp(r'^\d+$').hasMatch(part);
  }

  String _buildCardNumber() {
    String part1 = _cardPart1Controller.text.trim();
    String part2 = _cardPart2Controller.text.trim();
    String part3 = _cardPart3Controller.text.trim();
    
    if (part1.isEmpty || part2.isEmpty || part3.isEmpty) {
      return '';
    }
    
    return 'GHA-$part1-$part2';
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

    if (password.length < 6) {
      _showError("Password must be at least 6 characters!");
      return;
    }

    List<String> validTypes = ['pregnant-woman', 'relative', 'doctor', 'admin','midwife', 'wellness-user'];
    if (!validTypes.contains(type)) {
      _showError("Please select a valid user type");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final requestBody = {
        'name': name,
        'email': email,
        'card': card, 
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
    final _relativeCardPart1Controller = TextEditingController();
    final _relativeCardPart2Controller = TextEditingController();
    final _relativeCardPart3Controller = TextEditingController();
    String _relativeSelectedType = 'relative';

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Register Relative"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _relativeNameController,
                  decoration: const InputDecoration(labelText: "Name"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _relativeEmailController,
                  decoration: const InputDecoration(labelText: "Email"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _relativePasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Password"),
                ),
                const SizedBox(height: 10),
                const Text("Ghana Card Number", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _relativeCardPart1Controller,
                        decoration: const InputDecoration(
                          labelText: "GHA",
                          enabled: false,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text("-", style: TextStyle(fontSize: 18)),
                    ),
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _relativeCardPart2Controller,
                        keyboardType: TextInputType.number,
                        maxLength: 9,
                        decoration: const InputDecoration(
                          labelText: "Number",
                          counterText: "",
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text("-", style: TextStyle(fontSize: 18)),
                    ),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _relativeCardPart3Controller,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        decoration: const InputDecoration(
                          labelText: "Digit",
                          counterText: "",
                        ),
                      ),
                    ),
                  ],
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
                final part1 = _relativeCardPart1Controller.text;
                final part2 = _relativeCardPart2Controller.text;
                final part3 = _relativeCardPart3Controller.text;

                if (name.isEmpty || email.isEmpty || password.isEmpty || part2.isEmpty || part3.isEmpty) {
                  _showError("All fields are required!");
                  return;
                }

                String card = 'GHA-$part2-$part3';
                
                // Close the dialog first
                Navigator.pop(context);
                
                // Then register the relative using the original _register method
                await _register(name, email, card, password, _relativeSelectedType);
              },
              child: const Text("Register"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _cardPart1Controller.dispose();
    _cardPart2Controller.dispose();
    _cardPart3Controller.dispose();
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
                  _userTypeDropdown(),
                  const SizedBox(height: 20),
                  _cardNumberField(),
                  const SizedBox(height: 20),
                  SwitchListTile(
                    title: const Text("Allow relative to view vitals", style: TextStyle(color: Colors.white)),
                    value: _allowRelative,
                    onChanged: (value) {
                      setState(() => _allowRelative = value);
                      if (value) _showRelativeRegistrationDialog(_buildCardNumber());
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

  Widget _userTypeDropdown() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white),
        color: Colors.white.withOpacity(0.1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedUserType,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
            iconSize: 24,
            elevation: 16,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            dropdownColor: Colors.blue[800],
            isExpanded: true,
            onChanged: (String? newValue) {
              setState(() {
                _selectedUserType = newValue!;
              });
            },
            items: _userTypes.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value.replaceAll('-', ' ').toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _cardNumberField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 12, bottom: 8),
          child: Text(
            "Ghana Card Number",
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white),
            color: Colors.white.withOpacity(0.1),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Fixed "GHA" part
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _cardPart1Controller..text = "GHA",
                  enabled: false,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text("-", style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
              // Middle part (9 digits)
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _cardPart2Controller,
                  keyboardType: TextInputType.number,
                  maxLength: 9,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    counterText: "",
                    hintText: "000000000",
                    hintStyle: TextStyle(color: Colors.white54),
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text("-", style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
              // Last part (1 digit)
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _cardPart3Controller,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    counterText: "",
                    hintText: "0",
                    hintStyle: TextStyle(color: Colors.white54),
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _registerButton() {
    return ElevatedButton(
      onPressed: () {
        String card = _buildCardNumber();
        if (card.isEmpty) {
          _showError("Please complete the Ghana Card number");
          return;
        }
        _register(
          _nameController.text,
          _emailController.text,
          card,
          _passwordController.text,
          _selectedUserType,
        );
      },
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