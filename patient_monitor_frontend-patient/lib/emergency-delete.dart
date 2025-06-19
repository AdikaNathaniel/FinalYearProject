import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DeleteEmergencyContactPage extends StatefulWidget {
  @override
  _DeleteEmergencyContactPageState createState() => _DeleteEmergencyContactPageState();
}

class _DeleteEmergencyContactPageState extends State<DeleteEmergencyContactPage> {
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _deleteContact(String name) async {
    setState(() => _isLoading = true);

    final url = Uri.parse('http://localhost:3100/api/v1/emergency/contacts/$name');
    final response = await http.delete(url);

    setState(() => _isLoading = false);

    if (response.statusCode == 200) {
      _nameController.clear();

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.green[50],
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 80),
              SizedBox(height: 16),
              Text(
                'Contact Successfully Deleted',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

      // Auto dismiss after 2 seconds
      await Future.delayed(Duration(seconds: 2));
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete contact')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Delete Emergency Contact',
         style: TextStyle(
      color: Colors.white, // Makes the title white
    ),       
        ),
        backgroundColor: Colors.redAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Enter Contact Name',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(width: 10),
            _isLoading
                ? CircularProgressIndicator()
                : IconButton(
                    icon: Icon(Icons.delete, color: Colors.red, size: 30),
                    onPressed: () {
                      final name = _nameController.text.trim();
                      if (name.isNotEmpty) {
                        _deleteContact(name);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Please enter a contact name')),
                        );
                      }
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
