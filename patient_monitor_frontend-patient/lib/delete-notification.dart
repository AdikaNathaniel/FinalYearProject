import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DeleteNotificationPage extends StatefulWidget {
  const DeleteNotificationPage({super.key});

  @override
  State<DeleteNotificationPage> createState() => _DeleteNotificationPageState();
}

class _DeleteNotificationPageState extends State<DeleteNotificationPage> {
  final TextEditingController _idController = TextEditingController();

// Future<void> _deleteNotification(String id) async {
//     try {
//       final url = Uri.parse("http://localhost:3100/api/v1/notifications/$id");
//       final response = await http.delete(url);

//       if (response.statusCode == 200) {
//         _showSuccessDialog();
//       } else {
//         _showErrorDialog("Failed to delete notification. Status: ${response.statusCode}");
//       }
//     } catch (e) {
//       _showErrorDialog("Error: ${e.toString()}");
//     }
//   }



Future<void> _deleteNotification(String id) async {
  try {
    final url = Uri.parse("http://localhost:3100/api/v1/notifications/$id");
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
        backgroundColor: Colors.redAccent,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              "Enter Notification ID to Delete:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _idController,
              decoration: InputDecoration(
                hintText: "Notification ID",
                prefixIcon: const Icon(Icons.vpn_key),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _onDeletePressed,
              icon: const Icon(Icons.delete_outline),
              label: const Text("Delete Notification"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                textStyle: const TextStyle(fontSize: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
