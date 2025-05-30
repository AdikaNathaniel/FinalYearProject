import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class NotificationListPage extends StatefulWidget {
  const NotificationListPage({super.key});

  @override
  State<NotificationListPage> createState() => _NotificationListPageState();
}

class _NotificationListPageState extends State<NotificationListPage> {
  List<dynamic> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:3100/api/v1/notifications'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Check if the response has the expected structure
        if (data is Map<String, dynamic> && data.containsKey('result')) {
          setState(() {
            notifications = data['result'] ?? []; // Extract the result array
            isLoading = false;
          });
        } else {
          throw Exception('Invalid response structure');
        }
      } else {
        throw Exception('Failed to load notifications: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'N/A';
    
    try {
      final date = DateTime.parse(isoString).toLocal();
      return DateFormat("d'th' MMMM, y 'at' h:mm a").format(date);
    } catch (e) {
      return 'Invalid date';
    }
  }

  Future<void> _refreshNotifications() async {
    setState(() {
      isLoading = true;
    });
    await fetchNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Notifications"),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshNotifications,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text("No notifications found."),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _refreshNotifications,
                        child: const Text("Refresh"),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refreshNotifications,
                  child: ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notif = notifications[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Notification ID Row
                              Row(
                                children: [
                                  const Icon(Icons.vpn_key_rounded, size: 20, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      "ID: ${notif["_id"] ?? "N/A"}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy, size: 18),
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: notif["_id"] ?? ""));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Notification ID copied"),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                  )
                                ],
                              ),
                              const SizedBox(height: 8),
                              
                              // Role Row
                              Row(
                                children: [
                                  const Icon(Icons.verified_user, size: 20, color: Colors.blue),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Role: ${notif["role"] ?? "N/A"}",
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              
                              // Message Row
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.message_outlined, size: 20, color: Colors.green),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      "Message: ${notif["message"] ?? "No message"}",
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              
                              // Scheduled At Row
                              Row(
                                children: [
                                  const Icon(Icons.schedule_outlined, size: 20, color: Colors.orange),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      "Scheduled: ${formatDate(notif["scheduledAt"])}",
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              
                              // Created At Row
                              Row(
                                children: [
                                  const Icon(Icons.event_note, size: 20, color: Colors.purple),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      "Created: ${formatDate(notif["createdAt"])}",
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              
                              // Status Row
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: (notif["isSent"] == true) ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.send,
                                          size: 16,
                                          color: (notif["isSent"] == true) ? Colors.green : Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          notif["isSent"] == true ? "Sent" : "Pending",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: (notif["isSent"] == true) ? Colors.green : Colors.grey,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: (notif["isRead"] == true) ? Colors.teal.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.mark_email_read,
                                          size: 16,
                                          color: (notif["isRead"] == true) ? Colors.teal : Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          notif["isRead"] == true ? "Read" : "Unread",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: (notif["isRead"] == true) ? Colors.teal : Colors.grey,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
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
    );
  }
}