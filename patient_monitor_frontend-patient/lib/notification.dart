// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';

// class NotificationFormPage extends StatefulWidget {
//   @override
//   _NotificationFormPageState createState() => _NotificationFormPageState();
// }

// class _NotificationFormPageState extends State<NotificationFormPage> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _roleController = TextEditingController();
//   final TextEditingController _messageController = TextEditingController();
//   final TextEditingController _scheduledAtController = TextEditingController();

//   Future<void> sendNotification() async {
//     final url = Uri.parse('http://localhost:3100/api/v1/notifications');

//     final payload = {
//       "role": _roleController.text,
//       "message": _messageController.text,
//       "scheduledAt": _scheduledAtController.text,
//     };

//     try {
//       final response = await http.post(
//         url,
//         headers: {"Content-Type": "application/json"},
//         body: json.encode(payload),
//       );

//       if (response.statusCode == 201) {
//         _showDialog(
//           title: "Success",
//           icon: Icons.check_circle,
//           iconColor: Colors.green,
//           message: "Notification has been successfully created.",
//         );
//       } else {
//         _showDialog(
//           title: "Error",
//           icon: Icons.error,
//           iconColor: Colors.red,
//           message: "Failed to create notification. Status code: ${response.statusCode}",
//         );
//       }
//     } catch (e) {
//       _showDialog(
//         title: "Error",
//         icon: Icons.error_outline,
//         iconColor: Colors.red,
//         message: "An error occurred: $e",
//       );
//     }
//   }

//   void _showDialog({required String title, required IconData icon, required Color iconColor, required String message}) {
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: Row(
//           children: [
//             Icon(icon, color: iconColor),
//             SizedBox(width: 10),
//             Text(title),
//           ],
//         ),
//         content: Text(message),
//         actions: [
//           TextButton(
//             child: Text('OK'),
//             onPressed: () => Navigator.of(context).pop(),
//           )
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _roleController.dispose();
//     _messageController.dispose();
//     _scheduledAtController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Create Notification")),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             children: [
//               TextFormField(
//                 controller: _roleController,
//                 decoration: InputDecoration(
//                   labelText: "Role",
//                   hintText: "e.g. Admin",
//                   border: OutlineInputBorder(),
//                 ),
//                 validator: (value) => value == null || value.isEmpty ? "Please enter a role" : null,
//               ),
//               SizedBox(height: 16),
//               TextFormField(
//                 controller: _messageController,
//                 decoration: InputDecoration(
//                   labelText: "Message",
//                   hintText: "e.g. System Maintenance Tomorrow please!",
//                   border: OutlineInputBorder(),
//                 ),
//                 validator: (value) => value == null || value.isEmpty ? "Please enter a message" : null,
//               ),
//               SizedBox(height: 16),
//               TextFormField(
//                 controller: _scheduledAtController,
//                 decoration: InputDecoration(
//                   labelText: "Scheduled At (ISO8601 format)",
//                   hintText: "e.g. 2025-05-22T01:40:00Z",
//                   border: OutlineInputBorder(),
//                 ),
//                 validator: (value) => value == null || value.isEmpty ? "Please enter scheduled time" : null,
//               ),
//               SizedBox(height: 24),
//               ElevatedButton.icon(
//                 icon: Icon(Icons.send),
//                 label: Text("Submit"),
//                 onPressed: () {
//                   if (_formKey.currentState!.validate()) {
//                     sendNotification();
//                   }
//                 },
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
