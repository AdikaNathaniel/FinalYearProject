import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

// Only import dart:io on non-web platforms
import 'dart:io' as io show File;

class DoctorProfilePage extends StatefulWidget {
  const DoctorProfilePage({Key? key}) : super(key: key);

  @override
  _DoctorProfilePageState createState() => _DoctorProfilePageState();
}

class _DoctorProfilePageState extends State<DoctorProfilePage> {
  final _formKey = GlobalKey<FormState>();
  
  // For mobile platforms
  io.File? _imageFile;
  
  // For web platform
  Uint8List? _webImage;
  String? _imageName;
  
  final picker = ImagePicker();

  // Controllers
  final fullNameController = TextEditingController();
  final specializationController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final hospitalController = TextEditingController();
  final yearsController = TextEditingController();
  final languagesController = TextEditingController();
  final feeController = TextEditingController();

  List<String> selectedDays = [];
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  bool isSubmitting = false;

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      if (kIsWeb) {
        // For web platform
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImage = bytes;
          _imageName = pickedFile.name;
        });
      } else {
        // For mobile platforms
        setState(() {
          _imageFile = io.File(pickedFile.path);
        });
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one available day')),
      );
      return;
    }

    if (startTime == null || endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set both start time and end time')),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final uri = Uri.parse('http://localhost:3100/api/v1/medics');
      final request = http.MultipartRequest('POST', uri);

      // Handle image upload
      if (kIsWeb && _webImage != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'profilePhoto',
            _webImage!,
            filename: _imageName ?? 'profile_image.jpg',
          ),
        );
      } else if (!kIsWeb && _imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('profilePhoto', _imageFile!.path),
        );
      }

      // Prepare languages array
      final languages = languagesController.text
          .split(',')
          .map((lang) => lang.trim())
          .where((lang) => lang.isNotEmpty)
          .toList();

      // Add languages as separate fields
      for (int i = 0; i < languages.length; i++) {
        request.fields['languagesSpoken[$i]'] = languages[i];
      }

      // Add consultation hours as separate fields
      request.fields['consultationHours[days][]'] = selectedDays.join(',');
      request.fields['consultationHours[startTime]'] = startTime!.format(context);
      request.fields['consultationHours[endTime]'] = endTime!.format(context);

      // Add other form fields
      request.fields.addAll({
        'fullName': fullNameController.text.trim(),
        'specialization': specializationController.text.trim(),
        'email': emailController.text.trim(),
        'phoneNumber': phoneController.text.trim(),
        'address': addressController.text.trim(),
        'hospital': hospitalController.text.trim(),
        'yearsOfPractice': yearsController.text.trim(),
        'consultationFee': feeController.text.trim(),
      });

      final response = await request.send();
      
      if (response.statusCode == 201) {
        // Show success dialog
        await _showSuccessDialog();
        _resetForm();
      } else {
        final responseBody = await response.stream.bytesToString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${response.statusCode} - $responseBody'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  Future<void> _showSuccessDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button to close
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Icon(Icons.check_circle, color: Colors.green, size: 60),
                SizedBox(height: 20),
                Text('Doctor profile created successfully!'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    fullNameController.clear();
    specializationController.clear();
    emailController.clear();
    phoneController.clear();
    addressController.clear();
    hospitalController.clear();
    yearsController.clear();
    languagesController.clear();
    feeController.clear();
    
    setState(() {
      _imageFile = null;
      _webImage = null;
      _imageName = null;
      selectedDays.clear();
      startTime = null;
      endTime = null;
    });
  }

  Widget _buildImageWidget() {
    if (kIsWeb && _webImage != null) {
      return CircleAvatar(
        radius: 60,
        backgroundImage: MemoryImage(_webImage!),
      );
    } else if (!kIsWeb && _imageFile != null) {
      return CircleAvatar(
        radius: 60,
        backgroundImage: FileImage(_imageFile!),
      );
    } else {
      return CircleAvatar(
        radius: 60,
        backgroundColor: Colors.grey[300],
        child: const Icon(Icons.person, size: 60, color: Colors.grey),
      );
    }
  }

  Widget _buildTimePicker(String label, TimeOfDay? time, Function(TimeOfDay) onPicked) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.access_time),
        title: Text('$label: ${time?.format(context) ?? "--:--"}'),
        onTap: () async {
          final picked = await showTimePicker(
            context: context,
            initialTime: time ?? TimeOfDay.now(),
          );
          if (picked != null) onPicked(picked);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Doctor Profile'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Stack(
                  children: [
                    _buildImageWidget(),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, color: Colors.white),
                          onPressed: _pickImage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildTextField(fullNameController, "Full Name", Icons.person),
              _buildTextField(specializationController, "Specialization", Icons.medical_services),
              _buildTextField(emailController, "Email", Icons.email, keyboardType: TextInputType.emailAddress),
              _buildTextField(phoneController, "Phone Number", Icons.phone, keyboardType: TextInputType.phone),
              _buildTextField(addressController, "Address", Icons.location_on),
              _buildTextField(hospitalController, "Hospital", Icons.local_hospital),
              _buildTextField(yearsController, "Years of Practice", Icons.work_history, keyboardType: TextInputType.number),
              _buildTextField(languagesController, "Languages (comma separated)", Icons.language),
              _buildTextField(feeController, "Consultation Fee", Icons.attach_money, keyboardType: TextInputType.number),
              
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Available Days:",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                            .map((day) => FilterChip(
                                  label: Text(day),
                                  selected: selectedDays.contains(day),
                                  onSelected: (val) {
                                    setState(() {
                                      val ? selectedDays.add(day) : selectedDays.remove(day);
                                    });
                                  },
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              _buildTimePicker("Start Time", startTime, (val) => setState(() => startTime = val)),
              _buildTimePicker("End Time", endTime, (val) => setState(() => endTime = val)),
              
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: isSubmitting ? null : _submitForm,
                child: isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "SUBMIT PROFILE",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, 
    String label, 
    IconData icon, 
    {TextInputType? keyboardType}
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          labelText: label,
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
        validator: (value) => value == null || value.isEmpty ? 'This field is required' : null,
      ),
    );
  }

  @override
  void dispose() {
    fullNameController.dispose();
    specializationController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    hospitalController.dispose();
    yearsController.dispose();
    languagesController.dispose();
    feeController.dispose();
    super.dispose();
  }
}