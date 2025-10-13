import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class VitalsHistoryPage extends StatefulWidget {
  const VitalsHistoryPage({super.key});

  @override
  State<VitalsHistoryPage> createState() => _VitalsHistoryPageState();
}

class _VitalsHistoryPageState extends State<VitalsHistoryPage> {
  final TextEditingController _userIdController = TextEditingController();
  DateTime? startDateTime;
  DateTime? endDateTime;
  bool isLoading = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  List<dynamic> vitalsData = [];

  // Pick DateTime
  Future<DateTime?> pickDateTime(BuildContext context, DateTime? initial) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) return null;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial ?? DateTime.now()),
    );

    if (pickedTime == null) return null;

    return DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
  }

  // Fetch vitals data
  Future<void> _fetchVitals() async {
    if (!_formKey.currentState!.validate()) return;

    if (_userIdController.text.isEmpty || startDateTime == null || endDateTime == null) {
      _showErrorDialog('Please fill in all fields');
      return;
    }

    setState(() => isLoading = true);

    try {
      final url = Uri.parse(
        "https://patient-monitor-backend-patient.fly.dev/api/v1/vitals-health-data"
        "?userId=${_userIdController.text}"
        "&startDate=${startDateTime!.toUtc().toIso8601String()}"
        "&endDate=${endDateTime!.toUtc().toIso8601String()}",
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        setState(() {
          vitalsData = jsonResponse["result"]["data"] ?? [];
        });
        
        if (vitalsData.isNotEmpty) {
          _showVitalsDialog();
        } else {
          _showErrorDialog('No vitals data found for the selected criteria');
        }
      } else {
        _showErrorDialog('Error fetching vitals: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorDialog('Error fetching vitals: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showVitalsDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'User ID: ${_userIdController.text}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Period: ${_formatDate(startDateTime!.toString())} - ${_formatDate(endDateTime!.toString())}',
                  // style: const TextStyle(fontSize: 14, color: Colors.grey),
                  style: const TextStyle(
                  fontSize: 9,
                  color: Colors.black,
                 fontWeight: FontWeight.bold,
  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    shrinkWrap: true,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: vitalsData.length,
                    itemBuilder: (context, index) => _buildVitalsCard(vitalsData[index]),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) {
      // Clear the fields after dialog is closed
      _userIdController.clear();
      setState(() {
        startDateTime = null;
        endDateTime = null;
        vitalsData = [];
      });
    });
  }

  Widget _buildVitalsCard(dynamic item) {
    return Card(
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              _formatDateTime(item["timestamp"]?.toString() ?? ''),
              // style: const TextStyle(fontSize: 10, color: Colors.grey),
              style: const TextStyle(
    fontSize: 9,
    color: Colors.black,
    fontWeight: FontWeight.bold,
  ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Column(
                children: [
                  // First Row: BP opposite to HR
                  Expanded(
                    child: Row(
                      children: [
                        // BP Card
                        Expanded(
                          child: _buildSmallVitalCard(
                            'Blood Pressure',
                            item["bloodPressure"] != null 
                                ? '${item["bloodPressure"]["systolic"]}/${item["bloodPressure"]["diastolic"]}'
                                : 'N/A',
                            Icons.favorite,
                            Colors.pink,
                          ),
                        ),
                        const SizedBox(width: 4),
                        // HR Card
                        Expanded(
                          child: _buildSmallVitalCard(
                            'Heart Rate',
                            item["heartRate"] != null ? '${item["heartRate"]}' : 'N/A',
                            Icons.monitor_heart,
                            Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Second Row: SpO2 opposite to Glucose
                  Expanded(
                    child: Row(
                      children: [
                        // SpO2 Card
                        Expanded(
                          child: _buildSmallVitalCard(
                            'SpO₂',
                            item["spO2"] != null ? '${item["spO2"]}%' : 'N/A',
                            Icons.air,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Glucose Card
                        Expanded(
                          child: _buildSmallVitalCard(
                            'Glucose',
                            item["bloodGlucose"] != null ? '${item["bloodGlucose"]}' : 'N/A',
                            Icons.water_drop,
                            Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // Text(
            //   'Method: ${item["inputMethod"]}',
            //   style: const TextStyle(fontSize: 9, color: Colors.grey),
            //   maxLines: 1,
            //   overflow: TextOverflow.ellipsis,
            // ),


            Text(
  'Method: ${item["inputMethod"]}',
  style: const TextStyle(
    fontSize: 9,
    color: Colors.black,
    fontWeight: FontWeight.bold,
  ),
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallVitalCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.2),
            ),
            child: Icon(
              icon,
              color: color,
              size: 10,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 9,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVitalMetric(String title, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.2),
            ),
            child: Icon(
              icon,
              color: color,
              size: 12,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
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

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      String day = date.day.toString().padLeft(2, '0');
      String month = date.month.toString().padLeft(2, '0');
      String year = date.year.toString();
      return '$day/$month/$year';
    } catch (e) {
      return dateString;
    }
  }

  String _formatDateTime(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}\n${date.day}/${date.month}/${date.year}';
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
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vitals History'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
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
                          Icons.history,
                          size: 48,
                          color: Colors.blueAccent,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'View Vitals History',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _userIdController,
                          decoration: const InputDecoration(
                            labelText: 'User ID',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                            hintText: 'Enter user ID',
                          ),
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Please enter a user ID' : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.calendar_today, size: 18),
                                label: Text(
                                  startDateTime == null
                                      ? "Pick Start Date & Time"
                                      : "Start: ${_formatDateTime(startDateTime.toString())}",
                                  overflow: TextOverflow.ellipsis,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () async {
                                  final picked = await pickDateTime(context, startDateTime);
                                  if (picked != null) setState(() => startDateTime = picked);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.calendar_today, size: 18),
                                label: Text(
                                  endDateTime == null
                                      ? "Pick End Date & Time"
                                      : "End: ${_formatDateTime(endDateTime.toString())}",
                                  overflow: TextOverflow.ellipsis,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () async {
                                  final picked = await pickDateTime(context, endDateTime);
                                  if (picked != null) setState(() => endDateTime = picked);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _fetchVitals,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                                    'Fetch Vitals',
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
      ),
    );
  }
}