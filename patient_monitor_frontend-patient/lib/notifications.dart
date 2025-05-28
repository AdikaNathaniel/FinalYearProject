import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationsPage extends StatefulWidget {
  final String userEmail;
  
  const NotificationsPage({super.key, required this.userEmail});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = false;

  Future<void> _fetchNotifications() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:3100/api/v1/notifications'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Debug: Print the response to understand the structure
        print('API Response: $data');
        print('Response type: ${data.runtimeType}');
        
        setState(() {
          // Handle different possible response structures
          if (data is List) {
            // Case 1: Direct array response
            notifications = List<Map<String, dynamic>>.from(data);
          } else if (data is Map<String, dynamic>) {
            // Case 2: Object with notifications array
            if (data.containsKey('result') && data['result'] is List) {
              notifications = List<Map<String, dynamic>>.from(data['result']);
            } else if (data.containsKey('notifications') && data['notifications'] is List) {
              notifications = List<Map<String, dynamic>>.from(data['notifications']);
            } else if (data.containsKey('data') && data['data'] is List) {
              notifications = List<Map<String, dynamic>>.from(data['data']);
            } else if (data.containsKey('results') && data['results'] is List) {
              notifications = List<Map<String, dynamic>>.from(data['results']);
            } else {
              // If it's a single notification object, wrap it in a list
              notifications = [Map<String, dynamic>.from(data)];
            }
          } else {
            notifications = [];
          }
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        _showErrorDialog('Failed to fetch notifications: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorDialog('Error fetching notifications: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showNotificationsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('All Notifications'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: notifications.isEmpty
                ? const Center(child: Text('No notifications found'))
                : ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'ID: ${notification['_id'] ?? notification['id'] ?? 'N/A'}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: notification['role'] == 'Admin'
                                          ? Colors.red.withOpacity(0.1)
                                          : Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      notification['role'] ?? 'N/A',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: notification['role'] == 'Admin'
                                            ? Colors.red
                                            : Colors.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                notification['message'] ?? 'No message',
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Scheduled: ${notification['scheduledAt'] ?? 'N/A'}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        notification['isSent'] == true
                                            ? Icons.check_circle
                                            : Icons.cancel,
                                        size: 14,
                                        color: notification['isSent'] == true
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        notification['isSent'] == true ? 'Sent' : 'Not Sent',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: notification['isSent'] == true
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        notification['isRead'] == true
                                            ? Icons.mark_email_read
                                            : Icons.mark_email_unread,
                                        size: 14,
                                        color: notification['isRead'] == true
                                            ? Colors.blue
                                            : Colors.orange,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        notification['isRead'] == true ? 'Read' : 'Unread',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: notification['isRead'] == true
                                              ? Colors.blue
                                              : Colors.orange,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNotificationCard({
    required IconData icon,
    required String title,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: iconColor.withOpacity(0.1),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, 
                size: 16, 
                color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications Management'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // User Information Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      border: const Border(bottom: BorderSide(color: Colors.grey)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.account_circle, size: 30, color: Colors.blueAccent),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Current User', 
                              style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text(widget.userEmail,
                              style: const TextStyle(
                                fontSize: 16, 
                                fontWeight: FontWeight.w500,
                                color: Colors.black87)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Notification Actions
                  _buildNotificationCard(
                    icon: Icons.notifications,
                    title: 'View All Notifications',
                    iconColor: Colors.blue,
                    onTap: () async {
                      await _fetchNotifications();
                      _showNotificationsDialog();
                    },
                  ),
                  
                  _buildNotificationCard(
                    icon: Icons.notification_important,
                    title: 'Find Notification by ID',
                    iconColor: Colors.orange,
                    onTap: () {
                      _showNotificationIdDialog(context);
                    },
                  ),

                  const SizedBox(height: 16),

                  // Additional Info Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      elevation: 1,
                      color: Colors.grey[50],
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'View and manage all your system notifications here',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _showNotificationIdDialog(BuildContext context) {
    final TextEditingController idController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Notification ID'),
          content: TextField(
            controller: idController,
            decoration: const InputDecoration(
              hintText: 'Notification ID',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.text,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('View'),
              onPressed: () {
                final notificationId = idController.text.trim();
                if (notificationId.isNotEmpty) {
                  Navigator.of(context).pop();
                  // TODO: Add navigation or action for viewing the notification
                }
              },
            ),
          ],
        );
      },
    );
  }
}