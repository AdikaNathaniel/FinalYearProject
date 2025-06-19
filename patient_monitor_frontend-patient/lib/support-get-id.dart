import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class SupportByIdPage extends StatefulWidget {
  const SupportByIdPage({super.key});

  @override
  State<SupportByIdPage> createState() => _SupportByIdPageState();
}

class _SupportByIdPageState extends State<SupportByIdPage> {
  final TextEditingController _idController = TextEditingController();
  bool isLoading = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      final day = date.day;
      String daySuffix;
      
      if (day >= 11 && day <= 13) {
        daySuffix = 'th';
      } else {
        switch (day % 10) {
          case 1: daySuffix = 'st'; break;
          case 2: daySuffix = 'nd'; break;
          case 3: daySuffix = 'rd'; break;
          default: daySuffix = 'th';
        }
      }
      
      return DateFormat("d'$daySuffix' MMMM, y 'at' h:mm a").format(date);
    } catch (e) {
      return dateString;
    }
  }

  Future<void> _fetchAndShowSupportTicket() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('http://localhost:3100/api/v1/support/${_idController.text.trim()}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final supportTicket = data['result'] ?? data;
        _showSupportTicketDialog(supportTicket);
      } else {
        _showErrorDialog('Support ticket not found (Status: ${response.statusCode})');
      }
    } catch (e) {
      _showErrorDialog('Error fetching support ticket: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showSupportTicketDialog(Map<String, dynamic> supportTicket) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
      title: Center(child: const Text('Support Ticket Details')),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Ticket ID:', supportTicket['_id'] ?? 'N/A'),
              const Divider(),
              _buildDetailRow('Name:', supportTicket['name'] ?? 'N/A'),
              const Divider(),
              _buildDetailRow('Email:', supportTicket['email'] ?? 'N/A'),
              const Divider(),
              _buildDetailRow('Phone:', supportTicket['phoneNumber'] ?? 'N/A'),
              const Divider(),
              _buildDetailRow('Message:', supportTicket['message'] ?? 'No message'),
              const Divider(),
              _buildDetailRow('Created At:', _formatDate(supportTicket['createdAt'])),
            //   const Divider(),
            //   _buildDetailRow('Updated At:', _formatDate(supportTicket['updatedAt'])),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    ).then((_) {
      // Clear the field after dialog is closed
      _idController.clear();
    });
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Support Ticket by ID'),
        backgroundColor: Colors.deepPurple,
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
                        Icons.support_agent,
                        size: 48,
                        color: Colors.deepPurple,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Enter Support Ticket ID',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _idController,
                        decoration: const InputDecoration(
                          labelText: 'Ticket ID',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.confirmation_num),
                          hintText: 'e.g., 682ea205d98953b08251975c',
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Please enter an ID' : null,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _fetchAndShowSupportTicket,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'Find Ticket',
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