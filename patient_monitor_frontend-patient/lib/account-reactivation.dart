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
      appBar: AppBar(
        title: const Text(
          'Account Reactivation',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView( // Added SingleChildScrollView to prevent overflow
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_reactivationSuccess) _buildReactivationForm(),
            if (_reactivationSuccess) _buildSuccessCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildReactivationForm() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(
              Icons.lock_open_rounded,
              size: 48,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            const Text(
              'Reactivate Account',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            if (widget.userEmail == null)
              TextFormField(
                controller: _userEmailController,
                decoration: const InputDecoration(
                  labelText: 'User Email to Reactivate',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                  hintText: 'e.g user@example.com',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            if (widget.userEmail != null)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
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
            if (widget.userEmail == null) const SizedBox(height: 20),
            TextFormField(
              controller: _adminEmailController,
              decoration: const InputDecoration(
                labelText: 'Admin Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.admin_panel_settings),
                hintText: 'e.g admin@example.com',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _reactivateAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Reactivate Account',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
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
            'https://patient-monitor-backend-patient.fly.dev/api/v1/users/reactivate-account/$userEmail'),
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