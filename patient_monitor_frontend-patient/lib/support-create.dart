import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SupportFormPage extends StatefulWidget {
  @override
  _SupportFormPageState createState() => _SupportFormPageState();
}

class _SupportFormPageState extends State<SupportFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  bool _isLoading = false;

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final url = Uri.parse('http://localhost:3100/api/v1/support');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': _nameController.text,
        'phoneNumber': _phoneController.text,
        'email': _emailController.text,
        'message': _messageController.text,
      }),
    );

    setState(() => _isLoading = false);

    if (response.statusCode == 200 || response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Support request sent successfully!')),
      );
      _formKey.currentState!.reset();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send support request.')),
      );
    }
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon),
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
    title: const Text(
    'Support Form',
    style: TextStyle(color: Colors.white),
  ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
            //   Text("Get Support", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: _buildInputDecoration('Name', Icons.person),
                validator: (value) => value!.isEmpty ? 'Enter your name' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: _buildInputDecoration('Phone Number', Icons.phone),
                keyboardType: TextInputType.phone,
                validator: (value) => value!.isEmpty ? 'Enter your phone number' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: _buildInputDecoration('Email', Icons.email),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value!.isEmpty || !value.contains('@') ? 'Enter a valid email' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _messageController,
                decoration: _buildInputDecoration('Message', Icons.message),
                maxLines: 5,
                validator: (value) => value!.isEmpty ? 'Enter your message' : null,
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                icon: Icon(Icons.send),
                label: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Send Support Request'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  textStyle: TextStyle(fontSize: 16),
                ),
                onPressed: _isLoading ? null : _submitForm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
