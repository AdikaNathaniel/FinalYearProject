import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
          titleTextStyle: TextStyle(color: Colors.blue, fontSize: 20), // AppBar title text color and size
        ),
      ),
      home: UserListPage(),
    );
  }
}

class UserListPage extends StatefulWidget {
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

  // Function to fetch users from the API
  Future<void> fetchUsers() async {
    final response = await http.get(Uri.parse('http://localhost:3100/api/v1/users'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body)['result'];
      setState(() {
        users = data.map((userData) => User.fromJson(userData)).toList();
        isLoading = false;
      });
    } else {
      // Handle error
      setState(() {
        isLoading = false;
      });
      print('Failed to load users');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Users'),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
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
            ? Center(child: CircularProgressIndicator())
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

  UserCard({required this.user});

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
      margin: EdgeInsets.all(10),
      elevation: 5,
      child: ListTile(
        leading: Icon(userTypeIcon, color: Colors.blue, size: 40),
        title: Text(user.name, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            Text(userTypeText, style: TextStyle(color: Colors.grey)), // Display user type
          ],
        ),
        trailing: Icon(
          user.isVerified ? Icons.check_circle : Icons.cancel,
          color: user.isVerified ? Colors.green : Colors.red,
        ),
        isThreeLine: true,
        onTap: () {
          // Handle tap if needed
        },
      ),
    );
  }
}