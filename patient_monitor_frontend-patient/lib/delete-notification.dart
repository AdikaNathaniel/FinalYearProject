import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DeleteNotificationPage extends StatefulWidget {
  const DeleteNotificationPage({super.key});

  @override
  State<DeleteNotificationPage> createState() => _DeleteNotificationPageState();
}

class _DeleteNotificationPageState extends State<DeleteNotificationPage> {
  final TextEditingController _idController = TextEditingController();
  bool isLoading = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Future<void> _deleteNotification(String id) async {
    try {
      final url = Uri.parse("https://patient-monitor-backend-patient.fly.dev/api/v1/notifications/$id");
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        _idController.clear(); 
        _showSuccessDialog();
      } else {
        _showErrorDialog("Failed to delete notification. Status: ${response.statusCode}");
      }
    } catch (e) {
      _showErrorDialog("Error: ${e.toString()}");
    }
  }

  void _showConfirmDialog(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Are you sure?"),
        content: const Text("Do you really want to delete this notification?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop(); // Close confirmation dialog
              _deleteNotification(id);
            },
            icon: const Icon(Icons.delete),
            label: const Text("Yes, Delete"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.check_circle, color: Colors.green, size: 60),
            SizedBox(height: 10),
            Text("Notification Successfully Deleted!",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _onDeletePressed() {
    if (!_formKey.currentState!.validate()) return;
    
    final id = _idController.text.trim();
    if (id.isEmpty) {
      _showErrorDialog("Please enter a Notification ID.");
    } else {
      _showConfirmDialog(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Delete Notification"),
        backgroundColor: Colors.blue,
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
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Enter Notification ID to Delete',
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
                          onPressed: _onDeletePressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Delete Notification',
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