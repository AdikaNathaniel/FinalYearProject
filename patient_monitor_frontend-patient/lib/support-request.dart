import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SupportRequestsPage extends StatefulWidget {
  const SupportRequestsPage({super.key});

  @override
  State<SupportRequestsPage> createState() => _SupportRequestsPageState();
}

class _SupportRequestsPageState extends State<SupportRequestsPage> {
  List<dynamic> supportRequests = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSupportRequests();
  }

  Future<void> fetchSupportRequests() async {
    final response =
        await http.get(Uri.parse('http://localhost:3100/api/v1/support'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        supportRequests = data['result'];
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: 'Failed to load support requests');
    }
  }

  String formatDate(String isoDate) {
    final dateTime = DateTime.parse(isoDate).toLocal();
    final formatter = DateFormat("d MMMM yyyy 'at' h:mma");
    return formatter.format(dateTime);
  }

  void copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    Fluttertoast.showToast(msg: 'ID copied to clipboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     appBar: AppBar(
        title: const Text('Support Requests'),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: supportRequests.length,
              itemBuilder: (context, index) {
                final request = supportRequests[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.vpn_key, color: Colors.blueGrey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SelectableText(
                                request['_id'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed: () =>
                                  copyToClipboard(request['_id']),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        infoRow(Icons.person, 'Name', request['name']),
                        infoRow(Icons.phone, 'Phone', request['phoneNumber']),
                        infoRow(Icons.email, 'Email', request['email']),
                        infoRow(Icons.message, 'Message', request['message']),
                        infoRow(Icons.calendar_today, 'Created At',
                            formatDate(request['createdAt'])),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.indigo),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label: $value',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
