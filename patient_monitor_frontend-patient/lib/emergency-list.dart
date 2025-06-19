import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EmergencyContactsList extends StatefulWidget {
  const EmergencyContactsList({super.key});

  @override
  State<EmergencyContactsList> createState() => _EmergencyContactsListState();
}

class _EmergencyContactsListState extends State<EmergencyContactsList> {
  List<dynamic> contacts = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchEmergencyContacts();
  }

  Future<void> _fetchEmergencyContacts() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:3100/api/v1/emergency/contacts'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            contacts = data['result'];
          });
        } else {
          setState(() {
            errorMessage = data['message'] ?? 'Failed to load contacts';
          });
        }
      } else {
        setState(() {
          errorMessage = 'Failed to load contacts: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Network error: ${e.toString()}';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildContactCard(Map<String, dynamic> contact) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name Row
            _buildContactInfoRow(
              Icons.person_outline,
              contact['name'] ?? 'No name provided',
            ),
            const SizedBox(height: 12),
            
            // Phone Row
            _buildContactInfoRow(
              Icons.phone_android,
              contact['phoneNumber'] ?? 'No phone provided',
            ),
            const SizedBox(height: 12),
            
            // Email Row
            _buildContactInfoRow(
              Icons.email_outlined,
              contact['email'] ?? 'No email provided',
            ),
            const SizedBox(height: 12),
            
            // Relationship Row
            _buildContactInfoRow(
              Icons.group_outlined,
              contact['relationship'] ?? 'No relationship specified',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.blueAccent),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        centerTitle: true,
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchEmergencyContacts,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : contacts.isEmpty
                  ? const Center(child: Text('No emergency contacts found'))
                  : RefreshIndicator(
                      onRefresh: _fetchEmergencyContacts,
                      child: ListView.builder(
                        itemCount: contacts.length,
                        itemBuilder: (context, index) {
                          return _buildContactCard(contacts[index]);
                        },
                      ),
                    )
    //   floatingActionButton: FloatingActionButton(
    //     backgroundColor: Colors.redAccent,
    //     child: const Icon(Icons.add, color: Colors.white),
    //     onPressed: () {
    //       // TODO: Navigate to create contact page
    //     },
    //   ),
    );
  }
}