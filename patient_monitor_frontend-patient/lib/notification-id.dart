import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class NotificationByIdPage extends StatefulWidget {
  const NotificationByIdPage({super.key});

  @override
  State<NotificationByIdPage> createState() => _NotificationByIdPageState();
}

class _NotificationByIdPageState extends State<NotificationByIdPage> {
  final TextEditingController _idController = TextEditingController();
  bool isLoading = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      return DateFormat('MMM d, yyyy \'at\' h:mm a').format(DateTime.parse(dateString));
    } catch (e) {
      return dateString;
    }
  }

  Future<void> _fetchAndShowNotification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('http://localhost:3100/api/v1/notifications/${_idController.text.trim()}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final notification = data['result'] ?? data;
        _showNotificationDialog(notification);
      } else {
        _showErrorDialog('Notification not found (Status: ${response.statusCode})');
      }
    } catch (e) {
      _showErrorDialog('Error fetching notification: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }



void _showNotificationDialog(Map<String, dynamic> notification) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Notification Details'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('ID:', notification['_id'] ?? notification['id'] ?? 'N/A'),
            const Divider(),
            _buildDetailRow('Role:', notification['role'] ?? 'N/A'),
            const Divider(),
            _buildDetailRow('Message:', notification['message'] ?? 'No message'),
            const Divider(),
            _buildDetailRow('Scheduled At:', _formatDate(notification['scheduledAt'])),
            const Divider(),
            _buildDetailRow('Sent At:', _formatDate(notification['sentAt'])),
            const Divider(),
            _buildStatusRow(
              'Status:', 
              notification['isSent'] == true ? 'Sent' : 'Not Sent',
              notification['isSent'] == true ? Colors.green : Colors.red,
            ),
            const Divider(),
            _buildStatusRow(
              'Read Status:', 
              notification['isRead'] == true ? 'Read' : 'Unread',
              notification['isRead'] == true ? Colors.blue : Colors.orange,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  ).then((_) {
    // Clear the field after dialog is closed
    _idController.clear();
  });
}

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Icon(
            value == 'Sent' ? Icons.check_circle : 
            value == 'Read' ? Icons.mark_email_read : Icons.mark_email_unread,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
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
        title: const Text('Find Notification by ID'),
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
                        Icons.search,
                        size: 48,
                        color: Colors.deepPurple,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Enter Notification ID',
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
                          hintText: 'e.g., 682e926c2217b2bca7722bef',
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Please enter an ID' : null,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _fetchAndShowNotification,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ), // Fixed: Added missing closing parenthesis
                          child: isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'Find Notification',
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
    super.dispose();
  }
}