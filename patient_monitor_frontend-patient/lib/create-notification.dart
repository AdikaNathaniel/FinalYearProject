import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CreateNotificationPage extends StatefulWidget {
  const CreateNotificationPage({super.key});

  @override
  State<CreateNotificationPage> createState() => _CreateNotificationPageState();
}

class _CreateNotificationPageState extends State<CreateNotificationPage> {
  final TextEditingController _messageController = TextEditingController();
  DateTime? _scheduledAt;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_validateForm);
  }

  void _validateForm() {
    setState(() {
      _isFormValid = _messageController.text.trim().isNotEmpty && _scheduledAt != null;
    });
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          _scheduledAt = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          ).toUtc(); // Convert to UTC
        });
        _validateForm(); // Revalidate form after date selection
      }
    }
  }

  Future<void> _submitNotification() async {
    if (!_isFormValid) return;

    try {
      final url = Uri.parse('http://localhost:3100/api/v1/notifications');

      final body = {
        'role': 'Admin',
        'message': _messageController.text.trim(),
        'scheduledAt': _scheduledAt?.toIso8601String(),
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 201) {
        _showSuccessDialog();
      } else {
        final errorData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${errorData['message'] ?? 'Failed to create notification'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.check_circle, size: 60, color: Colors.green),
            SizedBox(height: 20),
            Text(
              'Notification Successfully Created!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _messageController.clear();
              setState(() {
                _scheduledAt = null;
              });
              _validateForm(); // Revalidate after clearing
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.removeListener(_validateForm);
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String formattedDate = _scheduledAt != null
        ? _scheduledAt!.toLocal().toString().substring(0, 16) // Better formatting
        : 'Select Date & Time';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Notification'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Notification Message',
                border: OutlineInputBorder(),
                helperText: 'Enter your notification message',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            ListTile(
              title: Text(
                formattedDate,
                style: TextStyle(
                  color: _scheduledAt != null ? Colors.black : Colors.grey,
                ),
              ),
              leading: const Icon(Icons.calendar_today),
              trailing: const Icon(Icons.access_time),
              onTap: _pickDateTime,
              tileColor: Colors.grey.shade200,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _isFormValid ? _submitNotification : null,
              icon: const Icon(Icons.send),
              label: const Text('Send Notification'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade600,
              ),
            ),
            if (!_isFormValid)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Please enter a message and select a date/time',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}