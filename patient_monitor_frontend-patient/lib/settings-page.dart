import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  TextEditingController emailController = TextEditingController();
  TextEditingController oldPasswordController = TextEditingController(); // For old password
  TextEditingController newPasswordController = TextEditingController(); // For new password
  TextEditingController nameController = TextEditingController(); // For name
  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;

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
        appBar: AppBar(
          title: const Text(
            "Settings",
             style: TextStyle(
            color: Colors.white,
          ),
          ),
          centerTitle: true,
          backgroundColor: Colors.blueAccent,
        ),
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
              _inputField("Email", emailController, icon: Icons.email_outlined),
              const SizedBox(height: 20),
              _passwordField("Old Password", oldPasswordController, _obscureOldPassword, (value) {
                setState(() {
                  _obscureOldPassword = value;
                });
              }),
              const SizedBox(height: 20),
              _passwordField("New Password", newPasswordController, _obscureNewPassword, (value) {
                setState(() {
                  _obscureNewPassword = value;
                });
              }),
              const SizedBox(height: 20),
              _inputField("Name", nameController),
              const SizedBox(height: 20),
              _saveBtn(),
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
          'assets/pregnant.png', // Update the path as needed
          width: 120,
          height: 120,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _inputField(String labelText, TextEditingController controller, {bool isPassword = false, IconData? icon}) {
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

  Widget _passwordField(String labelText, TextEditingController controller, bool obscureText, Function(bool) onToggle) {
    return TextField(
      style: const TextStyle(color: Colors.white),
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: Colors.white70,
          ),
          onPressed: () {
            onToggle(!obscureText);
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

  Widget _saveBtn() {
    return ElevatedButton(
      onPressed: _saveSettings,
      style: ElevatedButton.styleFrom(
        shape: const StadiumBorder(),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: const SizedBox(
        width: double.infinity,
        child: Text(
          "Save Settings",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }

  Future<void> _saveSettings() async {
    String email = emailController.text; // Get email from input
    String oldPassword = oldPasswordController.text; // Get old password from input
    String newPassword = newPasswordController.text; // Get new password from input
    String name = nameController.text; // Get name from input

    try {
      final response = await http.patch(
        Uri.parse('http://localhost:3100/api/v1/users/update-password-or-name'), // Your API endpoint
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          'email': email,
          'oldPassword': oldPassword,
          'newPassword': newPassword,
          'name': name,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success']) {
        _showSnackbar("Settings updated successfully", Colors.green);
      } else {
        _showSnackbar(responseData['message'] ?? "Failed to update settings", Colors.red);
      }
    } catch (error) {
      _showSnackbar("Failed to connect to the server.", Colors.red);
    }
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }
}