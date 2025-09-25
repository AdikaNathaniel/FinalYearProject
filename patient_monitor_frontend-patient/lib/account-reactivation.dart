import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AccountReactivationPage extends StatefulWidget {
  final String? userEmail; // Made nullable

  const AccountReactivationPage({Key? key, this.userEmail}) : super(key: key);

  @override
  _AccountReactivationPageState createState() =>
      _AccountReactivationPageState();
}

class _AccountReactivationPageState extends State<AccountReactivationPage> {
  final TextEditingController _adminEmailController = TextEditingController();
  final TextEditingController _userEmailController = TextEditingController();
  bool _isLoading = false;
  bool _reactivationSuccess = false;
  String? _reactivatedUserName;
  String? _reactivatedByEmail;

  @override
  void initState() {
    super.initState();
    if (widget.userEmail != null) {
      _userEmailController.text = widget.userEmail!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Account Reactivation',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 4,
        backgroundColor: Colors.blue.shade800,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_reactivationSuccess) _buildReactivationForm(),
            if (_reactivationSuccess) _buildSuccessCard(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildReactivationForm() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blue.shade50,
              child: const Icon(
                Icons.lock_open_rounded,
                size: 40,
                color: Colors.blue,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Reactivate Account',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Enter Credentials To Reactivate An Account',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 28),

          if (widget.userEmail == null)
            _buildInputField(
              controller: _userEmailController,
              label: 'User Email to Reactivate',
              icon: Icons.email_rounded,
              keyboardType: TextInputType.emailAddress,
            ),

          if (widget.userEmail != null)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_outline, color: Colors.blue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Account to reactivate: ${widget.userEmail}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          _buildInputField(
            controller: _adminEmailController,
            label: 'Admin Email',
            icon: Icons.admin_panel_settings_rounded,
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _reactivateAccount,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade800,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'REACTIVATE ACCOUNT',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blue.shade700),
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade700, width: 1.5),
          ),
        ),
        keyboardType: keyboardType,
      ),
    );
  }

  Widget _buildSuccessCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.green.shade50,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 60,
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          Text(
            'Account Reactivated Successfully!',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.green.shade800,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildDetailRow('User Email:',
              widget.userEmail ?? _userEmailController.text),
          _buildDetailRow('User Name:', _reactivatedUserName ?? ''),
          _buildDetailRow('Reactivated By:', _reactivatedByEmail ?? ''),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade800,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
            child: const Text(
              'BACK TO DASHBOARD',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _reactivateAccount() async {
    final adminEmail = _adminEmailController.text.trim();
    final userEmail = widget.userEmail ?? _userEmailController.text.trim();

    if (adminEmail.isEmpty || !adminEmail.contains('@')) {
      _showErrorDialog('Please enter a valid admin email');
      return;
    }

    if (userEmail.isEmpty || !userEmail.contains('@')) {
      _showErrorDialog('Please enter a valid user email to reactivate');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.put(
        Uri.parse(
            'http://localhost:3100/api/v1/users/reactivate-account/$userEmail'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'adminEmail': adminEmail,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        setState(() {
          _reactivationSuccess = true;
          _reactivatedUserName = responseData['result']['name'];
          _reactivatedByEmail = responseData['result']['reactivatedBy'];
        });
      } else {
        _showErrorDialog(
            responseData['message'] ?? 'Failed to reactivate account');
      }
    } catch (e) {
      _showErrorDialog('An error occurred: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _adminEmailController.dispose();
    _userEmailController.dispose();
    super.dispose();
  }
}
