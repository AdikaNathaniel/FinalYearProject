import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class SupportByNamePage extends StatefulWidget {
  const SupportByNamePage({super.key});

  @override
  State<SupportByNamePage> createState() => _SupportByNamePageState();
}

class _SupportByNamePageState extends State<SupportByNamePage> {
  final TextEditingController _nameController = TextEditingController();
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

  Future<void> _fetchAndShowSupportTickets() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('http://localhost:3100/api/v1/support/by-name/${_nameController.text.trim()}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> supportTickets = data['result'] ?? [];
        if (supportTickets.isNotEmpty) {
          _showSupportTicketsDialog(supportTickets);
        } else {
          _showErrorDialog('No support tickets found for this name');
        }
      } else {
        _showErrorDialog('Error fetching support tickets (Status: ${response.statusCode})');
      }
    } catch (e) {
      _showErrorDialog('Error fetching support tickets: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showSupportTicketsDialog(List<dynamic> supportTickets) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Center(child: const Text('Support Tickets')),
        content: SingleChildScrollView(
          child: Column(
            children: [
              Text(
                'Found ${supportTickets.length} ticket(s) for ${_nameController.text.trim()}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...supportTickets.map((ticket) => 
                _buildSupportTicketCard(ticket as Map<String, dynamic>)
              ).toList(),
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
      _nameController.clear();
    });
  }

  Widget _buildSupportTicketCard(Map<String, dynamic> ticket) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Ticket ID:', ticket['_id'] ?? 'N/A'),
            const Divider(height: 8),
            _buildDetailRow('Name:', ticket['name'] ?? 'N/A'),
            const Divider(height: 8),
            _buildDetailRow('Email:', ticket['email'] ?? 'N/A'),
            const Divider(height: 8),
            _buildDetailRow('Phone:', ticket['phoneNumber'] ?? 'N/A'),
            const Divider(height: 8),
            _buildDetailRow('Message:', ticket['message'] ?? 'No message'),
            const Divider(height: 8),
            _buildDetailRow('Created:', _formatDate(ticket['createdAt'])),
            // const Divider(height: 8),
            // _buildDetailRow('Last Updated:', _formatDate(ticket['updatedAt'])),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
              style: const TextStyle(fontSize: 14),
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
        title: const Text('Find Support Tickets by Name'),
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
                        'Enter Customer Name',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                          hintText: 'e.g., Mercy Adika',
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Please enter a name' : null,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _fetchAndShowSupportTickets,
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
                                  'Find Tickets',
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
    _nameController.dispose();
    super.dispose();
  }
}