import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MedicsListPage extends StatefulWidget {
  const MedicsListPage({Key? key}) : super(key: key);

  @override
  _MedicsListPageState createState() => _MedicsListPageState();
}

class _MedicsListPageState extends State<MedicsListPage> {
  List<dynamic> medics = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchMedics();
  }

  Future<void> _fetchMedics() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:3100/api/v1/medics'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          medics = data['result']['medics'];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load medics: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching medics: $e';
        isLoading = false;
      });
    }
  }

  Widget _buildMedicCard(Map<String, dynamic> medic) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Profile photo in circle avatar
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: medic['profilePhoto'] != null && 
                                    medic['profilePhoto'].isNotEmpty
                      ? NetworkImage(
                          'http://localhost:3100${medic['profilePhoto']}',
                        )
                      : null,
                  child: medic['profilePhoto'] == null || medic['profilePhoto'].isEmpty
                      ? const Icon(Icons.person, size: 40, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medic['fullName'] ?? 'No Name',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        medic['specialization'] ?? 'No Specialization',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.local_hospital, medic['hospital'] ?? 'No Hospital'),
            _buildInfoRow(Icons.work, '${medic['yearsOfPractice'] ?? '0'} years of experience'),
            _buildInfoRow(Icons.phone, medic['phoneNumber'] ?? 'No Phone'),
            _buildInfoRow(Icons.attach_money, '\$${medic['consultationFee'] ?? '0'} Consultaticn Fee'),
            _buildInfoRow(
              Icons.language,
              (medic['languagesSpoken'] as List<dynamic>?)?.join(', ') ?? 'No Languages',
            ),
            const SizedBox(height: 16),
            const Text(
              'Consultation Hours:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            if (medic['consultationHours'] != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildConsultationHoursRow(
                    'Days',
                    (medic['consultationHours']['days'] as List<dynamic>?)?.join(', ') ?? 'Not specified',
                  ),
                  _buildConsultationHoursRow(
                    'Time',
                    '${medic['consultationHours']['startTime'] ?? ''} - ${medic['consultationHours']['endTime'] ?? ''}',
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationHoursRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Directory'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchMedics,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : medics.isEmpty
                  ? const Center(child: Text('No doctors found'))
                  : RefreshIndicator(
                      onRefresh: _fetchMedics,
                      child: ListView.builder(
                        itemCount: medics.length,
                        itemBuilder: (context, index) {
                          return _buildMedicCard(medics[index]);
                        },
                      ),
                    ),
    );
  }
}