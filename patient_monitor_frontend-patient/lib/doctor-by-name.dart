import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FindDoctorByNamePage extends StatefulWidget {
  const FindDoctorByNamePage({super.key});

  @override
  State<FindDoctorByNamePage> createState() => _FindDoctorByNamePageState();
}

class _FindDoctorByNamePageState extends State<FindDoctorByNamePage> {
  final TextEditingController _nameController = TextEditingController();
  bool isLoading = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Future<void> _fetchAndShowDoctor() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('http://localhost:3100/api/v1/medics/${_nameController.text.trim()}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Fix: Access the nested medic data correctly
        final doctor = data['result']['medic'] ?? {};
        _showDoctorDialog(doctor);
      } else {
        _showErrorDialog('Doctor not found (Status: ${response.statusCode})');
      }
    } catch (e) {
      _showErrorDialog('Error fetching doctor: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showDoctorDialog(Map<String, dynamic> doctor) {
    // Convert languages list to comma-separated string
    final languages = doctor['languagesSpoken'] is List
        ? (doctor['languagesSpoken'] as List).join(', ')
        : 'N/A';

    // Format consultation hours - Fix the days array handling
    final consultationHours = doctor['consultationHours'] ?? {};
    String days = 'N/A';
    
    if (consultationHours['days'] is List) {
      final daysList = consultationHours['days'] as List;
      if (daysList.isNotEmpty) {
        // Handle the case where days might be stored as "Mon,Tue,Wed" in a single string
        if (daysList.first is String && daysList.first.contains(',')) {
          days = daysList.first.toString();
        } else {
          days = daysList.join(', ');
        }
      }
    }
    
    final hours = consultationHours['startTime'] != null && consultationHours['endTime'] != null
        ? '${consultationHours['startTime']} - ${consultationHours['endTime']}'
        : 'N/A';

    // Build the profile photo URL correctly
    String? profilePhotoUrl;
    if (doctor['profilePhoto'] != null && doctor['profilePhoto'].toString().isNotEmpty) {
      final photoPath = doctor['profilePhoto'].toString();
      // Construct full URL for the profile photo
      profilePhotoUrl = photoPath.startsWith('http') 
          ? photoPath 
          : 'http://localhost:3100${photoPath}';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Center(  
      child: const Text('Doctor Details'),
    ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Profile Photo with error handling
              if (profilePhotoUrl != null)
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(profilePhotoUrl),
                    onBackgroundImageError: (exception, stackTrace) {
                      // Handle image loading error
                      print('Error loading profile photo: $exception');
                    },
                    child: profilePhotoUrl == null 
                        ? const Icon(Icons.person, size: 50) 
                        : null,
                  ),
                )
              else
                const Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                ),
              const SizedBox(height: 16),
              _buildDetailRow('Name:', doctor['fullName']?.toString() ?? 'N/A'),
              const Divider(),
              _buildDetailRow('Specialization:', doctor['specialization']?.toString() ?? 'N/A'),
              const Divider(),
              _buildDetailRow('Hospital:', doctor['hospital']?.toString() ?? 'N/A'),
              const Divider(),
              _buildDetailRow('Years of Practice:', doctor['yearsOfPractice']?.toString() ?? 'N/A'),
              const Divider(),
              _buildDetailRow('Languages:', languages),
              const Divider(),
              _buildDetailRow('Consultation Fee:', doctor['consultationFee']?.toString() ?? 'N/A'),
              const Divider(),
              _buildDetailRow('Available Days:', days),
              const Divider(),
              _buildDetailRow('Available Hours:', hours),
              const Divider(),
              _buildDetailRow('Created:', _formatDate(doctor['createdAt']?.toString())),
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
      _nameController.clear();
    });
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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
        title: const Text('Find Doctor by Name'),
        backgroundColor: Colors.blue,
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
                        Icons.search,
                        size: 48,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Enter Doctor Name',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Doctor Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                          hintText: 'e.g., Dr. John Smith',
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Please enter a name' : null,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _fetchAndShowDoctor,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'Find Doctor',
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