import 'package:flutter/material.dart';
import 'register.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'health_metrics.dart';

// Main App Widget remains the same
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Login Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // Add this for better floating label appearance
        inputDecorationTheme: InputDecorationTheme(
          floatingLabelStyle: TextStyle(color: Colors.white),
        ),
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  String selectedUserType = 'Doctor'; // Default value
  bool _obscurePassword = true; // Track password visibility state

  final List<String> userTypes = ['Doctor', 'Pregnant Woman', 'Family Relative', 'Admin'];
  bool _isLoading = false; // Loading state

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
        body: _page(),
      ),
    );
  }

  Widget _page() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _icon(),
              const SizedBox(height: 50),
              _inputField(
                "Email", 
                emailController,
                icon: Icons.email_outlined,
              ),
              const SizedBox(height: 20),
              _passwordField(), // Special password field with visibility toggle
              const SizedBox(height: 20),
              _userTypeDropdown(),
              const SizedBox(height: 50),
              _loginBtn(),
              const SizedBox(height: 20),
              _extraText(),
            ],
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

  Widget _inputField(
    String labelText, 
    TextEditingController controller, 
    {bool isPassword = false, IconData? icon}
  ) {
    return TextField(
      style: const TextStyle(color: Colors.white),
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: icon != null 
            ? Icon(icon, color: Colors.white70) 
            : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.white),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
      ),
      obscureText: isPassword,
    );
  }

  // Special password field with visibility toggle
  Widget _passwordField() {
    return TextField(
      style: const TextStyle(color: Colors.white),
      controller: passwordController,
      obscureText: _obscurePassword, // Use the state variable to control visibility
      decoration: InputDecoration(
        labelText: "Password",
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
        suffixIcon: IconButton(
          icon: Icon(
            // Change the icon based on the password visibility state
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.white70,
          ),
          onPressed: () {
            setState(() {
              // Toggle password visibility when the button is pressed
              _obscurePassword = !_obscurePassword;
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
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
      ),
    );
  }

  Color _mixColors(Color color1, Color color2, double amount) {
    return Color.lerp(color1, color2, amount)!;
  }

  Widget _userTypeDropdown() {
    return Container(
      height: 60, // Match TextField default height
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white),
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withOpacity(0.1),
      ),
      child: Row(
        children: [
          Icon(Icons.person_outline, color: Colors.white70),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedUserType,
                isExpanded: true,
                dropdownColor: _mixColors(Colors.blue, Colors.red, 0.5),
                style: const TextStyle(color: Colors.white, fontSize: 16),
                hint: const Text(
                  'Login As',
                  style: TextStyle(color: Colors.white),
                ),
                items: userTypes.map((String userType) {
                  return DropdownMenuItem<String>(
                    value: userType,
                    child: Text(
                      userType,
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedUserType = newValue!;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loginBtn() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _login, // Disable button during loading
      style: ElevatedButton.styleFrom(
        shape: const StadiumBorder(),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: _isLoading
          ? const CircularProgressIndicator() // Show loading indicator
          : const SizedBox(
              width: double.infinity,
              child: Text(
                "Login",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20),
              ),
            ),
    );
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true; // Set loading state
    });

    String email = emailController.text;
    String password = passwordController.text;

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3100/api/v1/users/login'), // Your API endpoint
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success']) {
        _showSnackbar("Login successful", Colors.green);

        if (selectedUserType.toLowerCase() == 'doctor') {
          // Navigate to the appropriate page for Doctor
          // if (mounted) {
          //   Navigator.pushReplacement(
          //     context,
          //     MaterialPageRoute(
          //       builder: (context) => DoctorPage(),
          //     ),
          //   );
          // }
        } else if (selectedUserType.toLowerCase() == 'pregnant woman' || selectedUserType.toLowerCase() == 'family relative') {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const HealthDashboard(),
              ),
            );
          }
        } else if (selectedUserType.toLowerCase() == 'admin') {
          // Fetch totals and navigate to SummaryPage
          // int totalProducts = await _fetchTotalProducts();
          // int totalItemsInCart = await _fetchTotalItemsInCart();
          // int totalOrders = await _fetchTotalOrders();
          // int totalUsers = await _fetchTotalUsers();

          // if (mounted) {
          //   Navigator.pushReplacement(
          //     context,
          //     MaterialPageRoute(
          //       builder: (context) => SummaryPage(
          //         totalProducts: totalProducts,
          //         totalItemsInCart: totalItemsInCart,
          //         totalOrders: totalOrders,
          //         totalUsers: totalUsers,
          //         userEmail: email,
          //       ),
          //     ),
          //   );
          // }
        } else {
          _showSnackbar("Invalid user type.", Colors.red);
        }
      } else {
        _showSnackbar(responseData['message'] ?? "Wrong credentials.", Colors.red);
      }
    } catch (error) {
      _showSnackbar("Failed to connect to the server.", Colors.red);
    } finally {
      setState(() {
        _isLoading = false; // Reset loading state
      });
    }
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  Widget _extraText() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RegisterPage()),
        );
      },
      child: const Text(
        "Don't have an account? Register here",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          color: Colors.white,
        ),
      ),
    );
  }
}