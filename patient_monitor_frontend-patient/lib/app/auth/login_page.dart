import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';
import 'auth_state.dart';
import 'package:patient_monitor/app/models/face_auth_response.dart';
import 'package:patient_monitor/app/utils/face_api_utils.dart';
import 'package:patient_monitor/app/app_routes.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final html.VideoElement _videoElement = html.VideoElement();
  final html.CanvasElement _canvasElement = html.CanvasElement(width: 640, height: 480);
  bool _isLoading = false;
  bool _isCameraReady = false;
  String _message = '';

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

  Future<void> _detectAndLogin() async {
    setState(() {
      _isLoading = true;
      _message = 'Detecting face...';
    });

    try {
      final descriptor = await FaceApiUtils.getFaceDescriptorFromVideo(_videoElement);
      if (descriptor == null) {
        setState(() => _message = 'No face detected');
        return;
      }

      final response = await AuthService.verifyFace(descriptor);
      if (response.success) {
        final authState = Provider.of<AuthState>(context, listen: false);
        authState.login(response.user!, response.accessToken!);
        
        Navigator.pushReplacementNamed(
          context,
          response.user!.role == 'admin' ? AppRoutes.admin : AppRoutes.home,
        );
      } else {
        setState(() => _message = response.message ?? 'Authentication failed');
      }
    } catch (e) {
      setState(() => _message = 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Face Login')),
      body: Center(
              child: SingleChildScrollView(
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
              ElevatedButton(
                onPressed: _isLoading ? null : _detectAndLogin,
                child: _isLoading 
                    ? const CircularProgressIndicator()
                    : const Text('Login with Face'),
              ),
            ] else ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              const Text('Initializing camera...'),
            ],
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
              onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
              child: const Text('Register new user'),
            ),
          ],
        ),
      ),
      ),
    );
  }

  @override
  void dispose() {
    (_videoElement.srcObject as html.MediaStream?)?.getTracks().forEach((track) => track.stop());
    super.dispose();
  }
}