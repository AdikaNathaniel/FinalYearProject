import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'admin-notification.dart';
import 'login_page.dart'; 
import 'support-settings.dart';
import 'users_summary.dart';
import 'set_profile.dart';
import 'map.dart';

class AdminHomePage extends StatefulWidget {
  final String userEmail;
  
  const AdminHomePage({super.key, required this.userEmail});

  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  String _selectedPage = 'Users';

  Future<void> _logout(BuildContext context) async {
    try {
      final response = await http.put(
        Uri.parse('https://patient-monitor-backend-patient.fly.dev/api/v1/users/logout'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success']) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => LoginPage()),
            (Route<dynamic> route) => false
          );
        } else {
          _showSnackbar(
            context, 
            "Logout failed: ${responseData['message']}", 
            Colors.red
          );
        }
      } else {
        _showSnackbar(
          context, 
          "Logout failed: Server error", 
          Colors.red
        );
      }
    } catch (e) {
      _showSnackbar(
        context, 
        "Logout failed: ${e.toString()}", 
        Colors.red
      );
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
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title
                  const Text(
                    'Profile',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Email row
                  _buildProfileItem(
                    icon: Icons.email_outlined,
                    text: widget.userEmail,
                    onTap: null,
                  ),
                  
                  // Settings row
                  _buildProfileItem(
                    icon: Icons.settings_outlined,
                    text: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SetProfilePage(userEmail: widget.userEmail),
                        ),
                      );
                    },
                  ),
                  
                  // Map row
                  _buildProfileItem(
                    icon: Icons.location_on,
                    text: 'View Location Of PregMama',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MapPage(),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Logout button
                  TextButton(
                    onPressed: () async {
                      await _logout(context);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // Close button
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileItem({
    required IconData icon,
    required String text,
    required VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Colors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onTap != null) 
                const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedPage == 'Users' 
          ? AppBar(
              title: const Text('All Users'),
              centerTitle: true,
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              actions: [
                IconButton(
                  icon: CircleAvatar(
                    radius: 16,
                    child: Text(
                      widget.userEmail.isNotEmpty ? widget.userEmail[0].toUpperCase() : 'A',
                      style: const TextStyle(color: Colors.blue, fontSize: 16),
                    ),
                    backgroundColor: Colors.white,
                  ),
                  onPressed: () {
                    _showUserInfoDialog(context);
                  },
                ),
              ],
            )
          : AppBar(
              title: Text(_selectedPage),
              centerTitle: true,
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _selectedPage = 'Users';
                  });
                },
              ),
              actions: [
                IconButton(
                  icon: CircleAvatar(
                    radius: 16,
                    child: Text(
                      widget.userEmail.isNotEmpty ? widget.userEmail[0].toUpperCase() : 'A',
                      style: const TextStyle(color: Colors.blue, fontSize: 16),
                    ),
                    backgroundColor: Colors.white,
                  ),
                  onPressed: () {
                    _showUserInfoDialog(context);
                  },
                ),
              ],
            ),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              const DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blue,
                ),
                child: Center(
                  child: Text(
                    'ADMIN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.supervised_user_circle, color: Colors.blue),
                title: const Text('All Users'),
                selected: _selectedPage == 'Users',
                onTap: () {
                  setState(() {
                    _selectedPage = 'Users';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications, color: Colors.blue),
                title: const Text('Notifications'),
                selected: _selectedPage == 'Notifications',
                onTap: () {
                  setState(() {
                    _selectedPage = 'Notifications';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.support_agent, color: Colors.blue),
                title: const Text('Support'),
                selected: _selectedPage == 'Support',
                onTap: () {
                  setState(() {
                    _selectedPage = 'Support';
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
      body: _buildContent(_selectedPage),
    );
  }

  Widget _buildContent(String page) {
    switch (page) {
      case 'Users':
        return UserListPage(userEmail: widget.userEmail);
      case 'Notifications':
        return NotificationSettingsPage(userEmail: widget.userEmail);
      case 'Support':
        return SupportSettingsPage(userEmail: widget.userEmail);
      default:
        return UserListPage(userEmail: widget.userEmail);
    }
  }
}

// UserListPage with updated UI
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
    final response = await http.get(Uri.parse('https://patient-monitor-backend-patient.fly.dev/api/v1/users'));

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

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : users.isEmpty
            ? const Center(
                child: Text(
                  'No users found',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              )
            : ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  return UserCard(user: users[index]);
                },
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
    Color userTypeColor = Colors.grey;

    if (user.type == 'doctor') {
      userTypeIcon = Icons.medical_services;
      userTypeText = 'Doctor';
      userTypeColor = Colors.blue;
    } else if (user.type == 'admin') {
      userTypeIcon = Icons.admin_panel_settings;
      userTypeText = 'Admin';
      userTypeColor = Colors.red;
    } else if (user.type == 'relative') {
      userTypeIcon = Icons.family_restroom;
      userTypeText = 'Relative';
      userTypeColor = Colors.green;
    } else if (user.type == 'pregnantWoman') {
      userTypeIcon = Icons.pregnant_woman;
      userTypeText = 'Pregnant Woman';
      userTypeColor = Colors.pink;
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: userTypeColor.withOpacity(0.2),
              ),
              child: Icon(
                userTypeIcon,
                color: userTypeColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userTypeText,
                    style: TextStyle(
                      fontSize: 12,
                      color: userTypeColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              user.isVerified ? Icons.verified : Icons.pending,
              color: user.isVerified ? Colors.green : Colors.orange,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}