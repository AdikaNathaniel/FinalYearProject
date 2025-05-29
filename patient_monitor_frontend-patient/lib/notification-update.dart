import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationUpdatePage extends StatefulWidget {
  const NotificationUpdatePage({super.key});

  @override
  State<NotificationUpdatePage> createState() => _NotificationUpdatePageState();
}

class _NotificationUpdatePageState extends State<NotificationUpdatePage> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool isLoading = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Future<void> _updateNotification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final response = await http.put(
        Uri.parse('http://localhost:3100/api/v1/notifications/${_idController.text.trim()}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'message': _messageController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        _showSuccessDialog();
      } else {
        final errorData = json.decode(response.body);
        _showErrorDialog(errorData['message'] ?? 'Failed to update notification (Status: ${response.statusCode})');
      }
    } catch (e) {
      _showErrorDialog('Error updating notification: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 60,
            ),
            SizedBox(height: 16),
            Text(
              'Message Updated Successfully!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _idController.clear();
              _messageController.clear();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Notification'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.edit_notifications,
                        size: 48,
                        color: Colors.deepPurple,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Update Notification Message',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _idController,
                        decoration: const InputDecoration(
                          labelText: 'Notification ID',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.notifications),
                          hintText: 'Enter notification ID',
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Please enter an ID' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          labelText: 'New Message',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.message),
                          hintText: 'Enter new message content',
                        ),
                        maxLines: 3,
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Please enter a message' : null,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _updateNotification,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'Update Message',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _idController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}