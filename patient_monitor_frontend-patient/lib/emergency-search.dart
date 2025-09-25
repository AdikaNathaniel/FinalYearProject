import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EmergencyContactSearch extends StatefulWidget {
  const EmergencyContactSearch({super.key});

  @override
  State<EmergencyContactSearch> createState() => _EmergencyContactSearchState();
}

class _EmergencyContactSearchState extends State<EmergencyContactSearch> {
  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic>? contact;
  bool isLoading = false;
  String errorMessage = '';

  Future<void> _searchContact() async {
    final name = _searchController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      isLoading = true;
      errorMessage = '';
      contact = null;
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:3100/api/v1/emergency/contacts/$name'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['result'] != null) {
          setState(() {
            contact = data['result'];
          });
        } else {
          setState(() {
            errorMessage = data['message'] ?? 'Contact not found';
          });
        }
      } else {
        setState(() {
          errorMessage = 'Error: ${response.statusCode}';
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

  Widget _buildContactInfo() {
    if (contact == null) return const SizedBox();

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildInfoRow(Icons.person_outline, 'Name', contact!['name']),
            const Divider(height: 30),
            _buildInfoRow(Icons.phone, 'Phone', contact!['phoneNumber']),
            const Divider(height: 30),
            _buildInfoRow(Icons.email, 'Email', contact!['email']),
            const Divider(height: 30),
            _buildInfoRow(Icons.group, 'Relationship', contact!['relationship']),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.redAccent, size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Emergency Contact'),
        centerTitle: true,
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Enter contact name',
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.search, color: Colors.white),
                    onPressed: isLoading ? null : _searchContact,
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (errorMessage.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            )
          else
            Expanded(child: _buildContactInfo()),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}