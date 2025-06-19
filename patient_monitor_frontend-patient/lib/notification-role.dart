import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class NotificationsByRolePage extends StatefulWidget {
  const NotificationsByRolePage({super.key});

  @override
  State<NotificationsByRolePage> createState() => _NotificationsByRolePageState();
}

class _NotificationsByRolePageState extends State<NotificationsByRolePage> {
  final List<String> roles = ['Admin', 'Doctor', 'Relative', 'Pregnant Woman'];
  String? selectedRole;
  bool isLoading = false;
  List<dynamic> notifications = [];

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      return DateFormat('MMM d, yyyy \'at\' h:mm a').format(DateTime.parse(dateString));
    } catch (e) {
      return dateString;
    }
  }

  Future<void> _fetchNotificationsByRole() async {
    if (selectedRole == null) return;

    setState(() {
      isLoading = true;
      notifications = [];
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:3100/api/v1/notifications/role/$selectedRole'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] is List) {
          setState(() {
            notifications = data['result'];
          });
          _showNotificationsDialog();
        }
      } else {
        _showErrorDialog('Failed to fetch notifications (Status: ${response.statusCode})');
      }
    } catch (e) {
      _showErrorDialog('Error fetching notifications: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showNotificationsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$selectedRole Notifications (${notifications.length})'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationCard(notification);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification['message'] ?? 'No message',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(notification['scheduledAt']),
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  notification['isSent'] == true 
                    ? Icons.check_circle 
                    : Icons.error,
                  size: 16,
                  color: notification['isSent'] == true 
                    ? Colors.green 
                    : Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  notification['isSent'] == true ? 'Sent' : 'Pending',
                  style: TextStyle(
                    color: notification['isSent'] == true 
                      ? Colors.green 
                      : Colors.orange,
                  ),
                ),
                const Spacer(),
                Icon(
                  notification['isRead'] == true 
                    ? Icons.mark_email_read 
                    : Icons.mark_email_unread,
                  size: 16,
                  color: notification['isRead'] == true 
                    ? Colors.blue 
                    : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  notification['isRead'] == true ? 'Read' : 'Unread',
                  style: TextStyle(
                    color: notification['isRead'] == true 
                      ? Colors.blue 
                      : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
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
        title: const Text('Notifications by Role'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.group,
                      size: 48,
                      color: Colors.deepPurple,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Select Role to View Notifications',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Select Role',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.people_alt),
                      ),
                      items: roles.map((String role) {
                        return DropdownMenuItem<String>(
                          value: role,
                          child: Text(role),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedRole = newValue;
                        });
                      },
                      validator: (value) => value == null ? 'Please select a role' : null,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: (selectedRole == null || isLoading)
                            ? null
                            : _fetchNotificationsByRole,
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
                                'View Notifications',
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
    );
  }
}