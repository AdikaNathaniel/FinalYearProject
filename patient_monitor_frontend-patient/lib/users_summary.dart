import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'admin-notification.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'User List',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
        ),   
        appBarTheme: AppBarTheme(
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
          backgroundColor: Colors.blueAccent,
          iconTheme: IconThemeData(color: Colors.white),
        ),
      ),
      home: UserListPage(userEmail: 'admin@example.com'), // Default email for demo
    );
  }
}

class UserListPage extends StatefulWidget {
  final String userEmail;

  const UserListPage({Key? key, required this.userEmail}) : super(key: key);

  @override
  _UserListPageState createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  bool isLoading = true;
  List<User> users = [];

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    final response = await http.get(Uri.parse('http://localhost:3100/api/v1/users'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body)['result'];
      setState(() {
        users = data.map((userData) => User.fromJson(userData)).toList();
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      print('Failed to load users');
    }
  }

  void _showSnackbar(BuildContext context, String message, Color color) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: color,
      duration: const Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

 void _showUserInfoDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Center(child: Text('Profile')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 40, // Fixed width for icon column
                child: Icon(Icons.email),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(widget.userEmail)),
            ],
          ),
        
        // const SizedBox(height: 10),
// InkWell(
//   onTap: () {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => NotificationSettingsPage(userEmail: widget.userEmail),
//       ),
//     );
//   },
//   child: Padding(
//     padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
//     child: Row(
//       children: [
//         const SizedBox(
//           width: 40, // Same fixed width for icon column
//           child: Icon(Icons.admin_panel_settings, color: Colors.deepPurple),
//         ),
//         const SizedBox(width: 10),
//         const Expanded(
//           child: Text(
//             'Admin Panel',
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w500,
//               color: Colors.blueAccent,
//             ),
//           ),
//         ),
//       ],
//     ),
//   ),
// ),
          const SizedBox(height: 10),
          Row(
            children: [
              const SizedBox(
                width: 40, // Same fixed width for icon column
                child: Icon(Icons.settings),
              ),
              const SizedBox(width: 10),
              const Expanded(child: Text('Settings')),
            ],
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () async {
              final response = await http.put(
                Uri.parse('http://localhost:3100/api/v1/users/logout'),
                headers: {'Content-Type': 'application/json'},
              );

              if (response.statusCode == 200) {
                final responseData = json.decode(response.body);
                if (responseData['success']) {
                  Navigator.of(context).pop(); // Close dialog
                  // Navigate to login page or wherever appropriate
                } else {
                  _showSnackbar(
                      context,
                      "Logout failed: ${responseData['message']}",
                      Colors.red);
                }
              } else {
                _showSnackbar(
                    context, "Logout failed: Server error", Colors.red);
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: CircleAvatar(
              child: Text(
                widget.userEmail.isNotEmpty ? widget.userEmail[0].toUpperCase() : 'U',
                style: const TextStyle(color: Colors.blue),
              ),
              backgroundColor: Colors.white,
            ),
            onPressed: () {
              _showUserInfoDialog(context);
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Colors.blue,
              Colors.red,
            ],
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  return UserCard(user: users[index]);
                },
              ),
      ),
    );
  }
}

class User {
  final String name;
  final String email;
  final String type;
  final bool isVerified;

  User({required this.name, required this.email, required this.type, required this.isVerified});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'],
      email: json['email'],
      type: json['type'],
      isVerified: json['isVerified'],
    );
  }
}

class UserCard extends StatelessWidget {
  final User user;

  const UserCard({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    IconData userTypeIcon = Icons.account_circle;
    String userTypeText = 'Unknown';

    if (user.type == 'doctor') {
      userTypeIcon = Icons.medical_services;
      userTypeText = 'Doctor';
    } else if (user.type == 'admin') {
      userTypeIcon = Icons.admin_panel_settings;
      userTypeText = 'Admin';
    } else if (user.type == 'relative') {
      userTypeIcon = Icons.family_restroom;
      userTypeText = 'Relative';
    }

    return Card(
      margin: const EdgeInsets.all(10),
      elevation: 5,
      child: ListTile(
        leading: Icon(userTypeIcon, color: Colors.blue, size: 40),
        title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            Text(userTypeText, style: const TextStyle(color: Colors.grey)),
          ],
        ),
        trailing: Icon(
          user.isVerified ? Icons.check_circle : Icons.cancel,
          color: user.isVerified ? Colors.green : Colors.red,
        ),
        isThreeLine: true,
      ),
    );
  }
}