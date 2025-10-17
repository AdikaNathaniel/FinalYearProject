import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'login_page.dart';
import 'pregnancy-calculator.dart';
import 'predictions.dart';
import 'face_register.dart';

class LiveFaceLoginPage extends StatefulWidget {
  const LiveFaceLoginPage({Key? key}) : super(key: key);

  @override
  State<LiveFaceLoginPage> createState() => _LiveFaceLoginPageState();
}

class _LiveFaceLoginPageState extends State<LiveFaceLoginPage> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _webImage;
  bool _isLoading = false;

  Future<void> _pickImageFromGallery() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImage = bytes;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Image selected successfully!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error picking image: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 90,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImage = bytes;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Live photo captured successfully!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Camera error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
      // Fallback to gallery if camera fails
      _pickImageFromGallery();
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Image Source',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _takePhoto();
                    },
                    child: Container(
                      width: 100,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.camera_alt, size: 40, color: Colors.blue),
                          SizedBox(height: 8),
                          Text(
                            'Camera',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageFromGallery();
                    },
                    child: Container(
                      width: 100,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.photo_library, size: 40, color: Colors.blue),
                          SizedBox(height: 8),
                          Text(
                            'Gallery',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'For best results, use camera for live face authentication',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
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
    if (_webImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please capture or select an image"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final uri = Uri.parse('https://patient-monitor-backend-patient.fly.dev/api/v1/face/detect');
    
    try {
      final request = http.MultipartRequest('POST', uri)
        ..files.add(http.MultipartFile.fromBytes(
          'image',
          _webImage!,
          filename: 'face_login_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseBody);

      setState(() => _isLoading = false);

      if (response.statusCode == 201 && jsonResponse['success'] == true) {
        final result = jsonResponse['result'];
        
        if (result['faces'] == null || 
            result['faces'].isEmpty || 
            result['match'] == null) {
          _showErrorNotification('No face detected or invalid user');
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
      _showErrorNotification("Network error: ${e.toString()}");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  void _clearImage() {
    setState(() {
      _webImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Face Login'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          if (_webImage != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _clearImage,
              tooltip: 'Clear Image',
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
            children: [
              const SizedBox(height: 20),
              
              // Image Preview Section
              Container(
                height: 200,
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
                child: _webImage != null
                    ? Stack(
                        children: [
                          Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                constraints: BoxConstraints(
                                  maxHeight: 180,
                                  maxWidth: MediaQuery.of(context).size.width - 32,
                                ),
                                child: Image.memory(
                                  _webImage!,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: CircleAvatar(
                              backgroundColor: Colors.black54,
                              radius: 16,
                              child: IconButton(
                                icon: const Icon(Icons.close, size: 16, color: Colors.white),
                                onPressed: _clearImage,
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.face_retouching_natural,
                            size: 60,
                            color: Colors.white.withOpacity(0.5),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "No image selected",
                            style: TextStyle(color: Colors.white70),
                          ),
                          const Text(
                            "Take a live photo for authentication",
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
              ),
              
              const SizedBox(height: 20),
              
              // Capture Button
              ElevatedButton.icon(
                onPressed: _showImageSourceDialog,
                icon: const Icon(Icons.camera_alt, color: Colors.white),
                label: const Text('Capture Live Photo'),
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
              
              // Login Button
              _isLoading
                  ? const Column(
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 10),
                        Text(
                          "Authenticating...",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    )
                  : ElevatedButton.icon(
                      onPressed: _loginWithFaceAuth,
                      icon: const Icon(Icons.login, color: Colors.white),
                      label: const Text('Login with Face'),
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
              
              // Alternative Options
              Column(
                children: [
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
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const FaceRegisterPage()),
                      );
                    },
                    child: const Text(
                      'Click Me To Register Your Face On AwoaPa',
                      style: TextStyle(
                        color: Colors.white,
                        fontStyle: FontStyle.italic
                      ),
                    ),
                  ),
                ],
              ),
              
              // Instructions
              Container(
                margin: const EdgeInsets.only(top: 20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white30),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Face Login Instructions:",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "• Ensure good lighting\n• Face the camera directly\n• Keep a neutral expression\n• Remove glasses if possible",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}