import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';

class DoctorAppointmentsPage extends StatefulWidget {
  const DoctorAppointmentsPage({Key? key}) : super(key: key);

  @override
  _DoctorAppointmentsPageState createState() => _DoctorAppointmentsPageState();
}

class _DoctorAppointmentsPageState extends State<DoctorAppointmentsPage> {
  List<dynamic> appointments = [];
  bool isLoading = false;
  String selectedStatus = 'pending';
  DateTime? startDate;
  DateTime? endDate;
  final DateFormat dateFormatter = DateFormat('yyyy-MM-dd');
  final doctorNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize with current month dates
    final now = DateTime.now();
    startDate = DateTime(now.year, now.month, 1);
    endDate = DateTime(now.year, now.month + 1, 0);
  }

  Future<void> _fetchAppointments() async {
    if (doctorNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter doctor name')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final encodedDoctorName = Uri.encodeComponent(doctorNameController.text.trim());
      String url = 'http://localhost:3100/api/v1/doctors/$encodedDoctorName/appointments?status=$selectedStatus';

      if (startDate != null && endDate != null) {
        final startDateStr = dateFormatter.format(startDate!);
        final endDateStr = dateFormatter.format(endDate!);
        url += '&startDate=$startDateStr&endDate=$endDateStr';
      }

      print('API URL: $url'); // Debug print to see the actual URL

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('Response Status: ${response.statusCode}'); // Debug print
      print('Response Body: ${response.body}'); // Debug print

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['success'] == true && 
            responseData['result'] != null && 
            responseData['result']['appointments'] != null) {
          setState(() {
            appointments = responseData['result']['appointments'];
          });
          
          // Show results in dialog instead of snackbar
          _showAppointmentsDialog();
        } else {
          setState(() {
            appointments = [];
          });
          _showAppointmentsDialog();
        }
      } else {
        setState(() {
          appointments = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${response.statusCode} - ${response.reasonPhrase}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        appointments = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showAppointmentsDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Dialog Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Appointment Results',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            Text(
                              appointments.isEmpty 
                                  ? 'No appointments found'
                                  : 'Found ${appointments.length} appointment${appointments.length == 1 ? '' : 's'}',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Search Summary
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.search, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          const Text(
                            'Search Criteria:',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Doctor: ${doctorNameController.text}'),
                      Text('Status: ${selectedStatus.toUpperCase()}'),
                      if (startDate != null && endDate != null)
                        Text('Date Range: ${dateFormatter.format(startDate!)} to ${dateFormatter.format(endDate!)}'),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Appointments List
                Expanded(
                  child: appointments.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No appointments found',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try adjusting your search criteria',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: appointments.length,
                          itemBuilder: (context, index) {
                            final appointment = appointments[index];
                            return _buildDialogAppointmentCard(appointment);
                          },
                        ),
                ),
                
                const SizedBox(height: 16),
                
                // Dialog Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _fetchAppointments(); // Refresh search
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Refresh'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogAppointmentCard(Map<String, dynamic> appointment) {
    Color statusColor;
    switch (appointment['status']) {
      case 'confirmed':
        statusColor = Colors.green;
        break;
      case 'canceled':
        statusColor = Colors.red;
        break;
      case 'pending':
      default:
        statusColor = Colors.orange;
    }

    // Handle different date parsing scenarios
    DateTime appointmentDate;
    try {
      appointmentDate = DateTime.parse(appointment['date']);
    } catch (e) {
      appointmentDate = DateTime.now(); // Fallback
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    appointment['patientName'] ?? 'No Name',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    appointment['status'].toString().toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: statusColor,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildDialogInfoRow(Icons.medical_services, appointment['purpose'] ?? 'N/A'),
            const SizedBox(height: 4),
            _buildDialogInfoRow(
              Icons.schedule,
              DateFormat('MMM dd, yyyy – HH:mm').format(appointmentDate),
            ),
            const SizedBox(height: 4),
            _buildDialogInfoRow(Icons.location_on, appointment['location'] ?? 'N/A'),
            const SizedBox(height: 4),
            _buildDialogInfoRow(Icons.phone, appointment['phone'] ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogInfoRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    
    if (picked != null && picked != startDate) {
      setState(() {
        startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    
    if (picked != null && picked != endDate) {
      setState(() {
        endDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Appointments'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filter controls
          Card(
            margin: const EdgeInsets.all(16),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Doctor name text field
                  TextFormField(
                    controller: doctorNameController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person),
                      labelText: 'Doctor Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.blue, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator: (value) => value == null || value.isEmpty 
                        ? 'Doctor name is required' 
                        : null,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Status dropdown
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.filter_alt),
                      labelText: 'Appointment Status',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.blue, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    items: const [
                      DropdownMenuItem(value: 'pending', child: Text('Pending')),
                      DropdownMenuItem(value: 'confirmed', child: Text('Confirmed')),
                      DropdownMenuItem(value: 'canceled', child: Text('Canceled')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedStatus = value!;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Start date text field with picker
                  TextFormField(
                    readOnly: true,
                    controller: TextEditingController(
                      text: startDate != null ? dateFormatter.format(startDate!) : '',
                    ),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.calendar_today),
                      labelText: 'Start Date',
                      hintText: 'Select start date',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.blue, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    onTap: () => _selectStartDate(context),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // End date text field with picker
                  TextFormField(
                    readOnly: true,
                    controller: TextEditingController(
                      text: endDate != null ? dateFormatter.format(endDate!) : '',
                    ),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.calendar_today),
                      labelText: 'End Date',
                      hintText: 'Select end date',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.blue, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    onTap: () => _selectEndDate(context),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Date range display
                  if (startDate != null && endDate != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.date_range, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            'Selected Range: ${dateFormatter.format(startDate!)} to ${dateFormatter.format(endDate!)}',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Search button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isLoading ? null : _fetchAppointments,
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "SEARCH APPOINTMENTS",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
                  // Empty space since results will show in dialog
          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search,
                    size: 64,
                    color: Colors.grey,
                  ),
                  // SizedBox(height: 16),
                  // Text(
                  //   'Enter search criteria and click "Search Appointments"',
                  //   style: TextStyle(
                  //     fontSize: 16,
                  //     color: Colors.grey,
                  //   ),
                  //   textAlign: TextAlign.center,
                  // ),
                  SizedBox(height: 8),
                  Text(
                    'Results will be displayed in a dialog box',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    Color statusColor;
    switch (appointment['status']) {
      case 'confirmed':
        statusColor = Colors.green;
        break;
      case 'canceled':
        statusColor = Colors.red;
        break;
      case 'pending':
      default:
        statusColor = Colors.orange;
    }

    // Handle different date parsing scenarios
    DateTime appointmentDate;
    try {
      appointmentDate = DateTime.parse(appointment['date']);
    } catch (e) {
      appointmentDate = DateTime.now(); // Fallback
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    appointment['patientName'] ?? 'No Name',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    appointment['status'].toString().toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: statusColor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.badge, 'Patient ID', appointment['patientId'] ?? 'N/A'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.medical_services, 'Purpose', appointment['purpose'] ?? 'N/A'),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.schedule,
              'Date & Time',
              DateFormat('MMM dd, yyyy – HH:mm').format(appointmentDate),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.location_on, 'Location', appointment['location'] ?? 'N/A'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.phone, 'Phone', appointment['phone'] ?? 'N/A'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.person, 'Doctor', appointment['doctor'] ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.black87),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    doctorNameController.dispose();
    super.dispose();
  }
}