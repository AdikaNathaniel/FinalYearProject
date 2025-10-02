import 'dart:io';
import 'dart:typed_data';
import 'dart:html' as html;
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'face_login.dart';
import 'login_page.dart';

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

  Future<void> _takePhotoWeb() async {
    if (!kIsWeb) {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
      return;
    }

    final html.FileUploadInputElement uploadInput = html.FileUploadInputElement()
      ..accept = 'image/*'
      ..setAttribute('capture', 'environment');
    
    html.document.body?.append(uploadInput);
    uploadInput.click();
    
    uploadInput.onChange.listen((e) {
      final files = uploadInput.files;
      if (files != null && files.isNotEmpty) {
        final file = files[0];
        final reader = html.FileReader();
        
        reader.onLoadEnd.listen((e) {
          final dataUrl = reader.result as String;
          final base64 = dataUrl.split(',')[1];
          final bytes = base64Decode(base64);
          
          setState(() {
            _webImage = bytes;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Photo captured successfully!"),
              backgroundColor: Colors.green,
            ),
          );
        });
        
        reader.readAsDataUrl(file);
      }
      uploadInput.remove();
    });
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
    
    // Convert canvas to data URL directly
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

  void _capturePhoto(html.VideoElement video, html.CanvasElement canvas, html.MediaStream stream) {
    final canvasContext = canvas.getContext('2d') as html.CanvasRenderingContext2D;
    canvasContext.drawImage(video, 0, 0);
    
    stream.getTracks().forEach((track) => track.stop());
    
    // Convert canvas to data URL directly
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

  Future<void> _takePhotoFallback() async {
    if (kIsWeb) {
      final html.FileUploadInputElement uploadInput = html.FileUploadInputElement()
        ..accept = 'image/*'
        ..setAttribute('capture', 'user');
      
      uploadInput.click();
      
      uploadInput.onChange.listen((e) {
        final files = uploadInput.files;
        if (files!.isNotEmpty) {
          final file = files[0];
          final reader = html.FileReader();
          
          reader.onLoadEnd.listen((e) {
            final bytes = reader.result as Uint8List;
            setState(() {
              _webImage = bytes;
            });
          });
          
          reader.readAsArrayBuffer(file);
        }
      });
    } else {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                  _buildSourceOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      _openWebCamera();
                    },
                  ),
                  _buildSourceOption(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageFromGallery();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (kIsWeb)
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _takePhotoFallback();
                  },
                  child: const Text('Alternative Camera Access'),
                ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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
            Icon(
              icon,
              size: 40,
              color: Colors.blue,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
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

      setState(() => _isLoading = false);

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
      barrierDismissible: false,
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
            const SizedBox(height: 10),
            const Text(
              "You can now login with your face",
              style: TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Continue to Face Login'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blueAccent,
                  ),
                  child: const Text('Return to Login Page'),
                ),
              ],
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
  title: const Text(
    'Register My Face for Authentication',
    style: TextStyle(color: Colors.white), 
  ),
  centerTitle: true,
  backgroundColor: Colors.blueAccent, 
  iconTheme: const IconThemeData(color: Colors.white), 
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
              _inputField("UserName", _userIdController),
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
                                  Icons.person_outline,
                                  size: 60,
                                  color: Colors.white.withOpacity(0.5),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  "No image selected",
                                  style: TextStyle(color: Colors.white70),
                                ),
                                const Text(
                                  "Take a photo or select from gallery",
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
                icon: const Icon(Icons.add_a_photo, color: Colors.white),
                label: const Text('Add Photo'),
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
              const SizedBox(height: 10),
              if (_webImage == null && _selectedImage == null)
                TextButton.icon(
                  onPressed: _openWebCamera,
                  icon: const Icon(Icons.camera_front, color: Colors.white70),
                  label: const Text(
                    'Quick Camera Capture',
                    style: TextStyle(color: Colors.white70),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  ),
                ),
              const SizedBox(height: 20),
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