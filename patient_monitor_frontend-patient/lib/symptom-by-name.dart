import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FindSymptomPage extends StatefulWidget {
  const FindSymptomPage({super.key});

  @override
  State<FindSymptomPage> createState() => _FindSymptomPageState();
}

class _FindSymptomPageState extends State<FindSymptomPage> {
  final TextEditingController _searchController = TextEditingController();
  bool isLoading = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Future<void> _fetchAndShowSymptoms() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('https://finalyearproject-3-y6io.onrender.com/api/v1/symptoms/search?query=${_searchController.text.trim()}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['result'] == null || data['result'] is! List || data['result'].isEmpty) {
          _showErrorDialog('No symptom records found');
          return;
        }

        _showAllSymptomsDialog(data['result']);
      } else {
        _showErrorDialog('Error fetching records (Status: ${response.statusCode})');
      }
    } on http.ClientException catch (e) {
      _showErrorDialog('Network error: ${e.message}');
    } on FormatException catch (e) {
      _showErrorDialog('Data format error: ${e.message}');
    } catch (e) {
      _showErrorDialog('Unexpected error: ${e.toString()}');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showAllSymptomsDialog(List<dynamic> symptoms) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Patient Symptoms',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Found ${symptoms.length} records',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: symptoms.length,
                    separatorBuilder: (context, index) => const Divider(height: 20),
                    itemBuilder: (context, index) {
                      final symptom = symptoms[index] as Map<String, dynamic>;
                      return _buildSymptomCard(symptom);
                    },
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) {
      _searchController.clear();
    });
  }

  Widget _buildSymptomCard(Map<String, dynamic> symptom) {
    String formatYesNo(String? value) {
      if (value == null) return 'Not specified';
      return value.toLowerCase() == 'yes' ? 'Yes' : 'No';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Patient Info
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blue,
                child: Icon(Icons.person, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      symptom['username']?.toString() ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: ${symptom['patientId']?.toString() ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Symptoms Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 3.5,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            children: [
              _buildSymptomChip(
                Icons.headset, 
                Colors.red, 
                'Headache', 
                formatYesNo(symptom['feelingHeadache']),
              ),
              _buildSymptomChip(
                Icons.air, 
                Colors.orange, 
                'Dizziness', 
                formatYesNo(symptom['feelingDizziness']),
              ),
              _buildSymptomChip(
                Icons.sick, 
                Colors.green, 
                'Nausea', 
                formatYesNo(symptom['vomitingAndNausea']),
              ),
              _buildSymptomChip(
                Icons.medical_services, 
                Colors.blue, 
                'Tummy Pain', 
                formatYesNo(symptom['painAtTopOfTommy']),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Date
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Recorded: ${_formatDateTime(symptom['createdAt'])}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomChip(IconData icon, Color color, String label, String value) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString).toLocal();
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
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
        title: const Text('Find Patient Symptoms'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.search,
                        size: 40,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Search Patient Records',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Enter patient name or ID to search',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          labelText: 'Name or ID',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.search),
                          hintText: 'e.g., Michelle or 001',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Please enter a name or ID' : null,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _fetchAndShowSymptoms,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white),
                                )
                              : const Text(
                                  'Search Records',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
