import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:patient_monitor/app/auth/auth_service.dart';
import 'package:patient_monitor/app/utils/face_api_utils.dart';
import 'package:patient_monitor/app/app_routes.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final html.VideoElement _videoElement = html.VideoElement();
  final TextEditingController _usernameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isCameraReady = false;
  String _message = '';
  String _role = 'user';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    FaceApiUtils.initialize();
  }

  Future<void> _initializeCamera() async {
    try {
      final stream = await html.window.navigator.mediaDevices?.getUserMedia({
        'video': {'facingMode': 'user'},
        'audio': false,
      });
      
      if (stream != null) {
        _videoElement.srcObject = stream;
        _videoElement.play();
        setState(() => _isCameraReady = true);
      }
    } catch (e) {
      setState(() => _message = 'Failed to access camera: $e');
    }
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _message = 'Capturing face...';
    });

    try {
      final descriptor = await FaceApiUtils.getFaceDescriptorFromVideo(_videoElement);
      if (descriptor == null) {
        setState(() => _message = 'No face detected');
        return;
      }

      await AuthService.registerUser(
        _usernameController.text,
        _role,
        descriptor,
      );

      Navigator.pushReplacementNamed(context, AppRoutes.login);
    } catch (e) {
      setState(() => _message = 'Registration failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register New User')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isCameraReady) ...[
                  SizedBox(
                    width: 640,
                    height: 480,
                    child: HtmlElementView(viewType: 'video'),
                  ),
                  const SizedBox(height: 20),
                ] else ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  const Text('Initializing camera...'),
                ],
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'Username'),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter username' : null,
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _role,
                  items: const [
                    DropdownMenuItem(value: 'user', child: Text('Regular User')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: (value) => setState(() => _role = value!),
                  decoration: const InputDecoration(labelText: 'Role'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _registerUser,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Register Face'),
                ),
                if (_message.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    _message,
                    style: TextStyle(
                      color: _message.contains('failed') ? Colors.red : Colors.green,
                    ),
                  ),
                ],
                TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
                  child: const Text('Back to Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    (_videoElement.srcObject as html.MediaStream?)?.getTracks().forEach((track) => track.stop());
    _usernameController.dispose();
    super.dispose();
  }
}