import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatefulWidget {
  final String userEmail;

  const NotificationsPage({Key? key, required this.userEmail}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = false;
  Map<String, dynamic>? singleNotification;
  Set<String> markingAsRead = {};

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'N/A';
    }
    
    try {
      DateTime dateTime = DateTime.parse(dateString);
      String day = dateTime.day.toString();
      String suffix;

      if (day.endsWith('1') && day != '11') {
        suffix = 'st';
      } else if (day.endsWith('2') && day != '12') {
        suffix = 'nd';
      } else if (day.endsWith('3') && day != '13') {
        suffix = 'rd';
      } else {
        suffix = 'th';
      }

      String formattedDate = DateFormat('d\'$suffix\' MMMM, yyyy \'at\' h:mm a').format(dateTime);
      return formattedDate;
    } catch (e) {
      return dateString;
    }
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:3100/api/v1/notifications'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          notifications = List<Map<String, dynamic>>.from(data);
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
                  _buildUserHeader(),
                  const SizedBox(height: 16),
                  _buildNotificationCard(),
                  const SizedBox(height: 32),
                  _buildInfoCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildUserHeader() {
    return Container(
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
              const Text('Current User', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text(widget.userEmail, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard() {
    return GestureDetector(
      onTap: () async {
        await _fetchNotifications();
        _showNotificationsDialog();
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.notifications, color: Colors.blue),
              const SizedBox(width: 16),
              Expanded(child: const Text('View All Notifications')),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey),
            ],
          ),
        ),
      ),
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
                      return ListTile(
                        title: Text(notification['message'] ?? 'No message'),
                        subtitle: Text(_formatDate(notification['scheduledAt'])),
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

  Widget _buildInfoCard() {
    return Padding(
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
    );
  }
}