import 'dart:io';
import 'dart:typed_data';
import 'dart:html' as html;
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
  File? _selectedImage;
  Uint8List? _webImage;
  bool _isLoading = false;

  Future<void> _pickImageFromGallery() async {
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

  Future<void> _openWebCamera() async {
    if (!kIsWeb) return;
    
    final html.DivElement cameraContainer = html.DivElement()
      ..id = 'camera-container'
      ..style.position = 'fixed'
      ..style.top = '0'
      ..style.left = '0'
      ..style.width = '100vw'
      ..style.height = '100vh'
      ..style.backgroundColor = 'rgba(0,0,0,0.9)'
      ..style.zIndex = '9999'
      ..style.display = 'flex'
      ..style.flexDirection = 'column'
      ..style.alignItems = 'center'
      ..style.justifyContent = 'center';

    final html.VideoElement video = html.VideoElement()
      ..style.width = '80%'
      ..style.maxWidth = '640px'
      ..style.height = 'auto'
      ..style.borderRadius = '10px'
      ..autoplay = true;

    final html.ButtonElement captureBtn = html.ButtonElement()
      ..text = 'Capture Photo'
      ..style.marginTop = '20px'
      ..style.padding = '15px 30px'
      ..style.fontSize = '16px'
      ..style.backgroundColor = '#2196F3'
      ..style.color = 'white'
      ..style.border = 'none'
      ..style.borderRadius = '25px'
      ..style.cursor = 'pointer';

    final html.ButtonElement closeBtn = html.ButtonElement()
      ..text = 'Close'
      ..style.marginTop = '10px'
      ..style.padding = '10px 20px'
      ..style.fontSize = '14px'
      ..style.backgroundColor = '#f44336'
      ..style.color = 'white'
      ..style.border = 'none'
      ..style.borderRadius = '20px'
      ..style.cursor = 'pointer';

    cameraContainer.children.addAll([video, captureBtn, closeBtn]);
    html.document.body?.append(cameraContainer);

    try {
      final stream = await html.window.navigator.mediaDevices?.getUserMedia({
        'video': {'facingMode': 'user'},
        'audio': false,
      });

      if (stream != null) {
        video.srcObject = stream;

        captureBtn.onClick.listen((_) {
          _captureFromVideo(video, stream);
          cameraContainer.remove();
        });

        closeBtn.onClick.listen((_) {
          stream.getTracks().forEach((track) => track.stop());
          cameraContainer.remove();
        });
      }
    } catch (e) {
      cameraContainer.remove();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Camera access failed: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _captureFromVideo(html.VideoElement video, html.MediaStream stream) {
    final html.CanvasElement canvas = html.CanvasElement()
      ..width = video.videoWidth
      ..height = video.videoHeight;
    
    final canvasContext = canvas.getContext('2d') as html.CanvasRenderingContext2D;
    canvasContext.drawImage(video, 0, 0);
    
    stream.getTracks().forEach((track) => track.stop());
    
    final dataUrl = canvas.toDataUrl('image/jpeg', 0.8);
    final base64 = dataUrl.split(',')[1];
    final bytes = base64Decode(base64);
    
    setState(() {
      _webImage = bytes;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Photo captured successfully!"),
          backgroundColor: Colors.green,
        ),
      );
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
                      _openWebCamera();
                    },
                    child: Container(
                      width: 100,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.camera_alt, size: 40, color: Colors.blue),
                          const SizedBox(height: 8),
                          const Text(
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
                      child: Column(
                        children: [
                          const Icon(Icons.photo_library, size: 40, color: Colors.blue),
                          const SizedBox(height: 8),
                          const Text(
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
    if (_selectedImage == null && _webImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please capture or select an image")),
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
        title: const Text('Live Face Login'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
        //   TextButton(
        //     onPressed: () {
        //       Navigator.pushReplacement(
        //         context,
        //         MaterialPageRoute(builder: (context) => const LoginPage()),
        //       );
        //     },
        //     // child: const Text(
        //     //   'Use Email/Password',
        //     //   style: TextStyle(color: Colors.white),
        //     // ),
        //   ),
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
                              maxHeight: 160,
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
                                  maxHeight: 160,
                                  maxWidth: MediaQuery.of(context).size.width - 32,
                                ),
                                child: Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.contain,
                                ),
                              ),
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
              ),
              const SizedBox(height: 20),
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
              _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
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
                      'Click Me To Register Your Face On Awo)Pa',
                      style: TextStyle(
                        color: Colors.white,
                        fontStyle: FontStyle.italic
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}