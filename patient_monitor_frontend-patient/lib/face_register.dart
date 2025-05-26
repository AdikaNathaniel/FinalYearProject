import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'face_login.dart';

class FaceRegisterPage extends StatefulWidget {
  const FaceRegisterPage({Key? key}) : super(key: key);

  @override
  State<FaceRegisterPage> createState() => _FaceRegisterPageState();
}

class _FaceRegisterPageState extends State<FaceRegisterPage> {
  final TextEditingController _userIdController = TextEditingController();
  File? _selectedImage;
  Uint8List? _webImage;
  bool _isLoading = false;
  bool _registrationSuccess = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImage = bytes;
        });
      } else {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    }
  }

  Future<void> _submitData() async {
    final userId = _userIdController.text.trim();

    if (userId.isEmpty || (_selectedImage == null && _webImage == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User ID and image are required")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final uri = Uri.parse('http://localhost:3100/api/v1/face/register');
    final request = http.MultipartRequest('POST', uri)
      ..fields['userId'] = userId;

    try {
      if (kIsWeb) {
        request.files.add(http.MultipartFile.fromBytes(
          'image',
          _webImage!,
          filename: 'face.jpg',
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath(
          'image',
          _selectedImage!.path,
        ));
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      setState(() {
        _isLoading = false;
        if (response.statusCode == 201) {
          _registrationSuccess = true;
        }
      });

      if (response.statusCode == 201) {
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to register: $responseBody")),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        contentPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 20),
            const Text(
              "Registration Successful",
              style: TextStyle(fontSize: 18, color: Colors.green),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FaceLoginPage(),
                  ),
                );
              },
              child: const Text('Continue to Face Login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
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
        title: const Text('Register My Face for Authentication'),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Colors.blue, Colors.red],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (!_registrationSuccess) ...[
                _inputField("UserName", _userIdController),
                const SizedBox(height: 20),
                // Image Preview Container
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: (kIsWeb && _webImage != null)
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              constraints: BoxConstraints(
                                maxHeight: 600,
                                maxWidth: MediaQuery.of(context).size.width - 32,
                              ),
                              child: Image.memory(
                                _webImage!,
                                fit: BoxFit.contain,
                              ),
                            ),
                          )
                        : (!kIsWeb && _selectedImage != null)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  constraints: BoxConstraints(
                                    maxHeight: 180,
                                    maxWidth: MediaQuery.of(context).size.width - 32,
                                  ),
                                  child: Image.file(
                                    _selectedImage!,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              )
                            : const Text(
                                "No image selected",
                                style: TextStyle(color: Colors.white70),
                              ),
                  ),
                ),
                const SizedBox(height: 20),
                // Select Image Button
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image, color: Colors.white),
                  label: const Text('Select Image'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 4,
                  ),
                ),
                const SizedBox(height: 20),
                // Register Button
                _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : ElevatedButton.icon(
                        onPressed: _submitData,
                        icon: const Icon(Icons.upload_rounded, color: Colors.white),
                        label: const Text('Register'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 4,
                        ),
                      ),
              ] else ...[
                const SizedBox(height: 40),
                const Icon(Icons.check_circle, color: Colors.white, size: 80),
                const SizedBox(height: 20),
                const Text(
                  "Registration Complete!",
                  style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                const Text(
                  "You can now login with your face",
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 40),
                _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FaceLoginPage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.face, color: Colors.white),
                        label: const Text('Login with Face Authentication'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 4,
                        ),
                      ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField(String labelText, TextEditingController controller) {
    return TextField(
      style: const TextStyle(color: Colors.white),
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.white),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
      ),
    );
  }
}