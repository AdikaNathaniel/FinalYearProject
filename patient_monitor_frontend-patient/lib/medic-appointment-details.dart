import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';

class DoctorAppointmentsStatsPage extends StatefulWidget {
  const DoctorAppointmentsStatsPage({super.key});

  @override
  State<DoctorAppointmentsStatsPage> createState() => _DoctorAppointmentsStatsPageState();
}

class _DoctorAppointmentsStatsPageState extends State<DoctorAppointmentsStatsPage> {
  final TextEditingController _nameController = TextEditingController();
  bool isLoading = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Future<void> _fetchAndShowStats() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('http://localhost:3100/api/v1/doctors/${Uri.encodeComponent(_nameController.text.trim())}/appointments/stats'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _showStatsDialog(data['result']['data']);
      } else {
        _showErrorDialog('Doctor not found (Status: ${response.statusCode})');
      }
    } catch (e) {
      _showErrorDialog('Error fetching stats: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showStatsDialog(Map<String, dynamic> data) {
    final stats = data['stats'] ?? {};
    final pending = data['pending'] ?? {};
    final confirmed = data['confirmed'] ?? {};
    final canceled = data['canceled'] ?? {};
    final upcoming = data['upcoming'] ?? {};

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Center(child: Text('Appointment Statistics for ${_nameController.text.trim()}')),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Stats Summary Cards
                _buildStatsSummary(stats),
                
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),
                
                // Detailed Sections
                _buildAppointmentsSection('Pending Appointments (${pending['count']})', pending['appointments']),
                _buildAppointmentsSection('Confirmed Appointments (${confirmed['count']})', confirmed['appointments']),
                _buildAppointmentsSection('Canceled Appointments (${canceled['count']})', canceled['appointments']),
                _buildAppointmentsSection('Upcoming Appointments (${upcoming['count']})', upcoming['appointments']),
              ],
            ),
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

  Widget _buildStatsSummary(Map<String, dynamic> stats) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Appointment Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(Icons.check_circle, 'Confirmed', stats['confirmed']?.toString() ?? '0', Colors.green),
                _buildStatItem(Icons.pending, 'Pending', stats['pending']?.toString() ?? '0', Colors.orange),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(Icons.cancel, 'Canceled', stats['canceled']?.toString() ?? '0', Colors.red),
                _buildStatItem(Icons.trending_up, 'Confirmation Rate', stats['confirmationRate']?.toString() ?? '0%', Colors.blue),
              ],
            ),
            const SizedBox(height: 8),
            Divider(color: Colors.grey[300]),
            const SizedBox(height: 8),
            Text(
              'Total Appointments: ${stats['total']?.toString() ?? '0'}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, size: 30, color: color),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[600])),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildAppointmentsSection(String title, List<dynamic>? appointments) {
    if (appointments == null || appointments.isEmpty) {
      return const SizedBox.shrink();
    }

    return ExpansionTile(
      leading: const Icon(Icons.calendar_today, color: Colors.blue),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
      children: [
        ...appointments.map((appt) => _buildAppointmentCard(appt)).toList(),
      ],
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final date = DateTime.tryParse(appointment['date'] ?? '');
    final formattedDate = date != null 
        ? DateFormat('MMM dd, yyyy - hh:mm a').format(date.toLocal())
        : 'Date not specified';
    
    final appointmentId = appointment['_id']?.toString() ?? 'No ID';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Appointment ID Row (Copiable)
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tag, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  const Text(
                    'ID: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      appointmentId,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 16),
                    onPressed: () => _copyToClipboard(appointmentId),
                    tooltip: 'Copy ID',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Patient Name Row
            Row(
              children: [
                const Icon(Icons.person, size: 18, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  appointment['patientName'] ?? 'No name',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Phone Row
            Row(
              children: [
                const Icon(Icons.phone, size: 18, color: Colors.green),
                const SizedBox(width: 8),
                Text(appointment['phone'] ?? 'No phone'),
              ],
            ),
            const SizedBox(height: 8),
            
            // Date Row
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 18, color: Colors.purple),
                const SizedBox(width: 8),
                Text(formattedDate),
              ],
            ),
            const SizedBox(height: 8),
            
            // Location Row
            Row(
              children: [
                const Icon(Icons.location_on, size: 18, color: Colors.red),
                const SizedBox(width: 8),
                Text(appointment['location'] ?? 'No location'),
              ],
            ),
            const SizedBox(height: 8),
            
            // Purpose Row
            Row(
              children: [
                const Icon(Icons.medical_services, size: 18, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(appointment['purpose'] ?? 'No purpose specified'),
                ),
              ],
            ),
            
            // Status Badge
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.info, size: 18, color: Colors.blueGrey),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(appointment['status']),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    appointment['status']?.toString().toUpperCase() ?? 'UNKNOWN',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'canceled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ID copied to clipboard: ${text.substring(0, 8)}...'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
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
        title: const Text('Doctor Appointments Stats'),
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
                        Icons.medical_services,
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
                          hintText: 'e.g., Dr. Frank Amegah',
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Please enter a name' : null,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _fetchAndShowStats,
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
                                  'Get Statistics',
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