import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'verify-pin.dart'; 

class CreatePinPage extends StatefulWidget {
  @override
  _CreatePinPageState createState() => _CreatePinPageState();
}

class _CreatePinPageState extends State<CreatePinPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  List<TextEditingController> _pinControllers = List.generate(6, (index) => TextEditingController());
  List<FocusNode> _pinFocusNodes = List.generate(6, (index) => FocusNode());
  bool _isLoading = false;

  String get _pin => _pinControllers.map((controller) => controller.text).join('');

  Future<void> _submitPin() async {
    if (!_formKey.currentState!.validate() || _pin.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill in all fields and enter 6-digit PIN")),
      );
      return;
    }

    final url = Uri.parse('http://localhost:3100/api/v1/pin');
    final body = {
      "userId": _userIdController.text.trim(),
      "pin": _pin,
      "phone": _phoneController.text.trim()
    };

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201 && responseData['success'] == true) {
        _showSuccessDialog();
      } else {
        _showErrorSnackbar(responseData['message'] ?? 'Failed to create PIN.');
      }
    } catch (e) {
      _showErrorSnackbar('Something went wrong. Try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 80),
            SizedBox(height: 16),
            Text("PIN Created Successfully", textAlign: TextAlign.center),
          ],
        ),
        
        actions: [
  TextButton(
    onPressed: () {
      Navigator.of(context).pop(); // close the dialog first
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => PinVerifyScreen()),
      );
    },
    child: Text("Kindly verify the Pin", style: TextStyle(fontSize: 18)),
  )
],
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Widget _buildPinInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(6, (index) {
        return Container(
          width: 45,
          height: 55,
          decoration: BoxDecoration(
            border: Border.all(
              color: _pinFocusNodes[index].hasFocus ? Colors.teal : Colors.grey,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
            color: _pinFocusNodes[index].hasFocus 
                ? Colors.grey.shade200 
                : Colors.grey.shade100,
          ),
          child: TextFormField(
            controller: _pinControllers[index],
            focusNode: _pinFocusNodes[index],
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(1),
            ],
            obscureText: true,
            decoration: InputDecoration(
              border: InputBorder.none,
              counterText: '',
            ),
            onChanged: (value) {
              if (value.isNotEmpty && index < 5) {
                FocusScope.of(context).requestFocus(_pinFocusNodes[index + 1]);
              } else if (value.isEmpty && index > 0) {
                FocusScope.of(context).requestFocus(_pinFocusNodes[index - 1]);
              }
              setState(() {}); // Refresh to update border colors
            },
            validator: (value) => value == null || value.isEmpty ? '' : null,
          ),
        );
      }),
    );
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _phoneController.dispose();
    for (var controller in _pinControllers) {
      controller.dispose();
    }
    for (var focusNode in _pinFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Create Your PIN"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                "Kindly Enter Your Details To Create A Secure PIN",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 20),

              TextFormField(
                controller: _userIdController,
                decoration: InputDecoration(
                  labelText: 'User Name',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent, width: 2),
                  ),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter your user ID' : null,
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent, width: 2),
                  ),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter your phone number' : null,
              ),
              SizedBox(height: 24),

              Text(
                "Enter a 6-digit PIN", 
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)
              ),
              SizedBox(height: 16),

              _buildPinInput(),
              SizedBox(height: 24),

              _isLoading
                  ? CircularProgressIndicator(color: Colors.blueAccent)
                  : ElevatedButton.icon(
                      onPressed: _submitPin,
                      icon: Icon(Icons.lock_open, color: Colors.white),
                      label: Text("Create PIN", style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                        textStyle: TextStyle(fontSize: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.blueAccent, // Fixed: use backgroundColor instead of primary
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}