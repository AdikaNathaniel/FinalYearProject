import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logger/logger.dart';
import 'health_metrics.dart';
import 'relax-page.dart';

class VitalsHealthDataPage extends StatefulWidget {
  final String userEmail;

  const VitalsHealthDataPage({Key? key, required this.userEmail}) : super(key: key);

  @override
  _VitalsHealthDataPageState createState() => _VitalsHealthDataPageState();
}

class _VitalsHealthDataPageState extends State<VitalsHealthDataPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController userIdController = TextEditingController();
  final TextEditingController heartRateController = TextEditingController();
  final TextEditingController systolicController = TextEditingController();
  final TextEditingController diastolicController = TextEditingController();
  final TextEditingController bloodGlucoseController = TextEditingController();
  final Logger logger = Logger();

  String? inputMethod;
  bool isSubmitting = false;

  // Validation error messages
  String? _heartRateError;
  String? _systolicError;
  String? _diastolicError;
  String? _bloodGlucoseError;

  @override
  void initState() {
    super.initState();
    userIdController.text = widget.userEmail;
  }

  Widget _buildSelectionCard({
    required String title,
    required String subtitle,
    required String imageUrl,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [Color(0xFF2196F3).withOpacity(0.1), Color(0xFF64B5F6).withOpacity(0.1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Color(0xFF2196F3),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    width: 65,
                    height: 65,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / 
                                loadingProgress.expectedTotalBytes!
                              : null,
                          color: Color(0xFF2196F3),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Color(0xFF2196F3).withOpacity(0.1),
                        child: Icon(
                          Icons.image_not_supported,
                          color: Color(0xFF2196F3),
                          size: 30,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2196F3),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 13,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  String? _validateHeartRate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Heart rate is required';
    }
    
    final intValue = int.tryParse(value);
    if (intValue == null) {
      return 'Please enter a valid number';
    }
    
    if (intValue < 30) {
      return 'Heart rate must not be less than 30';
    }
    
    return null;
  }

  String? _validateSystolic(String? value) {
    if (value == null || value.isEmpty) {
      return 'Systolic BP is required';
    }
    
    final intValue = int.tryParse(value);
    if (intValue == null) {
      return 'Please enter a valid number';
    }
    
    if (intValue < 60) {
      return 'Systolic BP must not be less than 60';
    }
    
    return null;
  }

  String? _validateDiastolic(String? value) {
    if (value == null || value.isEmpty) {
      return 'Diastolic BP is required';
    }
    
    final intValue = int.tryParse(value);
    if (intValue == null) {
      return 'Please enter a valid number';
    }
    
    if (intValue < 40) {
      return 'Diastolic BP must not be less than 40';
    }
    
    return null;
  }

  String? _validateBloodGlucose(String? value) {
    if (value == null || value.isEmpty) {
      return 'Blood glucose is required';
    }
    
    final intValue = int.tryParse(value);
    if (intValue == null) {
      return 'Please enter a valid number';
    }
    
    if (intValue < 50) {
      return 'Blood glucose must not be less than 50';
    }
    
    return null;
  }

  Future<void> submitVitalsData() async {
    setState(() {
      _heartRateError = _validateHeartRate(heartRateController.text);
      _systolicError = _validateSystolic(systolicController.text);
      _diastolicError = _validateDiastolic(diastolicController.text);
      _bloodGlucoseError = _validateBloodGlucose(bloodGlucoseController.text);
    });

    if (_heartRateError != null || 
        _systolicError != null || 
        _diastolicError != null || 
        _bloodGlucoseError != null) {
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isSubmitting = true;
    });

    try {
      final requestData = {
        "userId": userIdController.text,
        "inputMethod": inputMethod,
        "bloodPressure": {
          "systolic": int.parse(systolicController.text),
          "diastolic": int.parse(diastolicController.text),
        },
        "heartRate": int.parse(heartRateController.text),
        "bloodGlucose": int.parse(bloodGlucoseController.text),
      };
      
      logger.d('Sending vitals data: $requestData');
      
      final response = await http.post(
        Uri.parse('https://patient-monitor-backend-patient.fly.dev/api/v1/vitals-health-data'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestData),
      );

      logger.d('Response status: ${response.statusCode}');
      logger.d('Response body: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        await _showSuccessDialog(responseData);
        _resetForm();
      } else {
        String errorMessage = 'Failed to submit vitals data';
        if (response.body.isNotEmpty) {
          try {
            final errorData = json.decode(response.body);
            errorMessage = errorData['message'] ?? errorMessage;
          } catch (e) {
            errorMessage = 'Server error: ${response.statusCode}';
          }
        }
        
        _showErrorSnackBar(errorMessage);
      }
    } catch (e) {
      logger.d('Exception occurred: $e');
      _showErrorSnackBar('Error: ${e.toString()}');
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  Future<void> _showSuccessDialog(Map<String, dynamic> responseData) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.green.shade700,
                        size: 48,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  const Center(
                    child: Text(
                      'Vitals Data Submitted Successfully!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  _buildResponseItem(
                    Icons.person,
                    'User ID',
                    responseData['result']['userId'].toString(),
                  ),
                  
                  _buildResponseItem(
                    Icons.input,
                    'Input Method',
                    responseData['result']['inputMethod'].toString(),
                  ),
                  
                  _buildResponseItem(
                    Icons.favorite,
                    'Heart Rate',
                    '${responseData['result']['heartRate']} bpm',
                  ),
                  
                  _buildResponseItem(
                    Icons.monitor_heart,
                    'Blood Pressure (Systolic)',
                    '${responseData['result']['bloodPressure']['systolic']} mmHg',
                  ),
                  
                  _buildResponseItem(
                    Icons.monitor_heart,
                    'Blood Pressure (Diastolic)',
                    '${responseData['result']['bloodPressure']['diastolic']} mmHg',
                  ),
                  
                  _buildResponseItem(
                    Icons.water_drop,
                    'Blood Glucose',
                    '${responseData['result']['bloodGlucose']} mg/dL',
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Text(
                    'Submitted: ${_formatDateTime(responseData['result']['createdAt'])}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'OK',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResponseItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF2196F3),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF2196F3),
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String dateTimeString) {
    final dateTime = DateTime.parse(dateTimeString);
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    userIdController.text = widget.userEmail;
    heartRateController.clear();
    systolicController.clear();
    diastolicController.clear();
    bloodGlucoseController.clear();
    
    setState(() {
      _heartRateError = null;
      _systolicError = null;
      _diastolicError = null;
      _bloodGlucoseError = null;
    });
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
    String hint, {
    TextInputType? keyboardType,
    bool enabled = true,
    String? errorText,
    void Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        enabled: enabled,
        decoration: InputDecoration(
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFF2196F3).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Color(0xFF2196F3),
              size: 20,
            ),
          ),
          labelText: label,
          hintText: hint,
          errorText: errorText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF2196F3), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          filled: true,
          fillColor: enabled ? Colors.grey[50] : Colors.grey[200],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          labelStyle: TextStyle(color: Colors.grey[700]),
          hintStyle: TextStyle(color: Colors.grey[500]),
        ),
        onChanged: onChanged,
        validator: (value) {
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mode of Vitals Recording'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFF2196F3),
        foregroundColor: Colors.white,
        leading: inputMethod == "manual"
            ? IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    inputMethod = null;
                  });
                },
              )
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: inputMethod == "manual" 
          ? _buildManualEntryForm()
          : _buildSelectionScreen(),
      ),
    );
  }

  Widget _buildSelectionScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    ),
                  child: const Icon(
                    Icons.monitor_heart,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose Your Preferred Method Of Vitals Capture',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.visible,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        Column(
          children: [
            _buildSelectionCard(
              title: "Wearable Device",
              subtitle: "Sync Your Data With Your Smart Device",
              imageUrl: 'https://raw.githubusercontent.com/AdikaNathaniel/FinalYearProject/awopa/AppScreenshots/WearableArm.jpeg',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RelaxPage(
                      userEmail: widget.userEmail,
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 20),
            
            _buildSelectionCard(
              title: "Manual Entry",
              subtitle: "Enter Your Vitals Manually",
              imageUrl: 'https://raw.githubusercontent.com/AdikaNathaniel/FinalYearProject/awopa/AppScreenshots/ManualEntry.jpg',
              onTap: () {
                setState(() => inputMethod = "manual");
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildManualEntryForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.monitor_heart,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Manual Vitals Entry',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // SizedBox(height: 4),
                        // Text(
                        //   'Enter your health measurements manually',
                        //   style: TextStyle(
                        //     color: Colors.white70,
                        //     fontSize: 14,
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          _buildTextField(
            userIdController,
            "User ID",
            Icons.person,
            "Enter your user ID",
          ),
          
          _buildTextField(
            heartRateController,
            "Heart Rate",
            Icons.favorite,
            "Enter heart rate (bpm)",
            keyboardType: TextInputType.number,
            errorText: _heartRateError,
            onChanged: (value) {
              setState(() {
                _heartRateError = _validateHeartRate(value);
              });
            },
          ),
          
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  systolicController,
                  "Systolic",
                  Icons.monitor_heart,
                  "Systolic (mmHg)",
                  keyboardType: TextInputType.number,
                  errorText: _systolicError,
                  onChanged: (value) {
                    setState(() {
                      _systolicError = _validateSystolic(value);
                    });
                  },
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  diastolicController,
                  "Diastolic",
                  Icons.monitor_heart,
                  "Diastolic (mmHg)",
                  keyboardType: TextInputType.number,
                  errorText: _diastolicError,
                  onChanged: (value) {
                    setState(() {
                      _diastolicError = _validateDiastolic(value);
                    });
                  },
                ),
              ),
            ],
          ),
          
          _buildTextField(
            bloodGlucoseController,
            "Blood Glucose",
            Icons.water_drop,
            "Enter blood glucose (mg/dL)",
            keyboardType: TextInputType.number,
            errorText: _bloodGlucoseError,
            onChanged: (value) {
              setState(() {
                _bloodGlucoseError = _validateBloodGlucose(value);
              });
            },
          ),

          const SizedBox(height: 32),

          Container(
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF2196F3).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: isSubmitting ? null : submitVitalsData,
              child: isSubmitting
                  ? const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 24,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Submit Data",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  @override
  void dispose() {
    userIdController.dispose();
    heartRateController.dispose();
    systolicController.dispose();
    diastolicController.dispose();
    bloodGlucoseController.dispose();
    super.dispose();
  }
}