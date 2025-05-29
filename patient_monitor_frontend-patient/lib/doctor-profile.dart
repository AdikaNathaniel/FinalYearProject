import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class DoctorProfilePage extends StatefulWidget {
  const DoctorProfilePage({Key? key}) : super(key: key);

  @override
  _DoctorProfilePageState createState() => _DoctorProfilePageState();
}

class _DoctorProfilePageState extends State<DoctorProfilePage> {
  final _formKey = GlobalKey<FormState>();
  File? _image;
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
  bool success = false;

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isSubmitting = true;
      success = false;
    });

    try {
      final uri = Uri.parse('http://localhost:3100/api/v1/medics');
      final request = http.MultipartRequest('POST', uri);

      if (_image != null) {
        request.files.add(
          await http.MultipartFile.fromPath('profilePhoto', _image!.path),
        );
      }

      request.fields.addAll({
        'fullName': fullNameController.text,
        'specialization': specializationController.text,
        'email': emailController.text,
        'phoneNumber': phoneController.text,
        'address': addressController.text,
        'hospital': hospitalController.text,
        'yearsOfPractice': yearsController.text,
        'languagesSpoken': jsonEncode(languagesController.text.split(',')),
        'consultationFee': feeController.text,
        'consultationHours': jsonEncode({
          "days": selectedDays,
          "startTime": startTime?.format(context),
          "endTime": endTime?.format(context),
        }),
      });

      final response = await request.send();
      
      setState(() {
        success = response.statusCode == 201;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Doctor profile created successfully!')),
        );
        _resetForm();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _image = null;
      selectedDays.clear();
      startTime = null;
      endTime = null;
    });
  }

  Widget _buildTimePicker(String label, TimeOfDay? time, Function(TimeOfDay) onPicked) {
    return ListTile(
      leading: const Icon(Icons.access_time),
      title: Text('$label: ${time?.format(context) ?? "--:--"}'),
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (picked != null) onPicked(picked);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Doctor Profile'),
        centerTitle: true,
        elevation: 0,
      ),
      body: success
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 100),
                  const SizedBox(height: 20),
                  const Text(
                    'Profile Created Successfully!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => setState(() => success = false),
                    child: const Text('Create Another Profile'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundImage: _image != null ? FileImage(_image!) : null,
                            child: _image == null
                                ? const Icon(Icons.person, size: 60)
                                : null,
                          ),
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
                    _buildTextField(emailController, "Email", Icons.email),
                    _buildTextField(phoneController, "Phone Number", Icons.phone),
                    _buildTextField(addressController, "Address", Icons.location_on),
                    _buildTextField(hospitalController, "Hospital", Icons.local_hospital),
                    _buildTextField(yearsController, "Years of Practice", Icons.work_history),
                    _buildTextField(languagesController, "Languages (comma separated)", Icons.language),
                    _buildTextField(feeController, "Consultation Fee", Icons.attach_money),
                    
                    const SizedBox(height: 16),
                    const Text(
                      "Available Days:",
                      style: TextStyle(fontWeight: FontWeight.bold),
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
                    
                    _buildTimePicker("Start Time", startTime, (val) => setState(() => startTime = val)),
                    _buildTimePicker("End Time", endTime, (val) => setState(() => endTime = val)),
                    
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isSubmitting ? null : _submitForm,
                      child: isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "SUBMIT PROFILE",
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        validator: (value) => value == null || value.isEmpty ? 'Required field' : null,
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