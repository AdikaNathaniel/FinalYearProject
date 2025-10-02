import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'login_page.dart';
import 'pregnancy-calculator.dart';
import 'predictions.dart';
import 'face_register.dart'; // Make sure to import your FaceRegisterPage

class FaceLoginPage extends StatefulWidget {
  const FaceLoginPage({Key? key}) : super(key: key);

  @override
  State<FaceLoginPage> createState() => _FaceLoginPageState();
}

class _FaceLoginPageState extends State<FaceLoginPage> {
  File? _selectedImage;
  Uint8List? _webImage;
  bool _isLoading = false;

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

  Future<void> _showConfirmationDialog(String userId, String faceGender) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Identity Confirmation'),
          content: Text('Are you $userId?'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
                _showErrorNotification('Kindly upload a new Image for Access');
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                Navigator.of(context).pop();
                _handleSuccessfulLogin(userId, faceGender);
              },
            ),
          ],
        );
      },
    );
  }

 
 void _handleSuccessfulLogin(String userId, String faceGender) {
  if (userId == 'Einsteina Owoh') {
    _showSuccessNotification('Logging In As Pregnant Woman');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => PregnancyCalculatorScreen(userEmail: userId),
      ),
      (route) => false, 
    );
  } 
  else if (userId == 'Dr.George Anane') {
    _showSuccessNotification('Logging In As Medic');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => PregnancyComplicationsPage(userEmail: userId),
      ),
      (route) => false,
    );
  }
  else {
    _showErrorNotification('Invalid user');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }
}

  void _showSuccessNotification(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorNotification(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _showLowConfidenceDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red, size: 30),
              SizedBox(width: 10),
              Text('Low Confidence', style: TextStyle(fontSize: 20)),
            ],
          ),
          content: const Text('Kindly use email and password to log in',
              style: TextStyle(fontSize: 16)),
          actions: <Widget>[
            TextButton(
              child: const Text('OK', style: TextStyle(fontSize: 16)),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _loginWithFaceAuth() async {
    if (_selectedImage == null && _webImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an image")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final uri = Uri.parse('http://localhost:3100/api/v1/face/detect');
    final request = http.MultipartRequest('POST', uri);

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
      final jsonResponse = json.decode(responseBody);

      setState(() => _isLoading = false);

      if (response.statusCode == 201 && jsonResponse['success'] == true) {
        final result = jsonResponse['result'];
        
        if (result['faces'] == null || 
            result['faces'].isEmpty || 
            result['match'] == null) {
          _showErrorNotification('Invalid user');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
          return;
        }

        final match = result['match'];
        final confidence = match['confidence']?.toDouble() ?? 0.0;
        
        if (confidence > 0.40) {
          await _showLowConfidenceDialog();
          return;
        }

        final face = result['faces'][0];
        final faceGender = face['gender'] ?? '';
        final userId = match['userId'] ?? '';

        if (userId.isNotEmpty) {
          await _showConfirmationDialog(userId, faceGender);
        } else {
          _showErrorNotification('Unable to verify identity');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      } else {
        final errorMessage = jsonResponse['error'] ?? 
                           jsonResponse['message'] ?? 
                           'Authentication failed';
        _showErrorNotification(errorMessage.toString());
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorNotification("Error: ${e.toString()}");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Authentication Login'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            child: const Text(
              'Use Email/Password',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
              const SizedBox(height: 30),
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
              _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : ElevatedButton.icon(
                      onPressed: _loginWithFaceAuth,
                      icon: const Icon(Icons.face, color: Colors.white),
                      label: const Text('Authenticate with Face'),
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
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                child: const Text(
                  'Login with Email/Password instead',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 10),
              // Added register face link/button
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FaceRegisterPage()),
                  );
                },
                child: const Text(
                  'Click Me To Register Your Face On Awo)Pa',
                  style: TextStyle(
                    color: Colors.white,
                    fontStyle: FontStyle.italic
                  ),
                ),
                 
              ),
            ],
          ),
        ),
      ),
    );
  }
}