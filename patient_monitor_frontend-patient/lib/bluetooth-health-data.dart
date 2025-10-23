import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'dart:math';

// Import your other pages
import 'create_cancel-appointment.dart';
import 'login_page.dart';
import 'wellness-page.dart';
import 'protein-strip.dart';
import 'pregnancy-health.dart';
import 'pregnancy-chatbot.dart';
import 'pregnant-woman-chat.dart';
import 'create-emergency.dart';
import 'emergency-contact.dart';
import 'notification-list.dart'; 
import 'support-create.dart';
import 'medic-list.dart';
import 'doctor-by-name.dart';
import 'symptom-checker.dart';
import 'set_profile.dart'; 
import 'map.dart';
import 'hardware_vitals.dart';
import 'paystack-home.dart';
import 'anemia-assessment.dart';
import 'chart-data.dart';
import 'appointment-schedule-by-medic.dart';
import 'bluetooth-wearable.dart';

// Glucose Unit Enum
enum GlucoseUnit {
  mgDL,
  mmolL
}

// ✅ FIXED: Bluetooth Service Singleton with proper instance handling
class BluetoothHealthService {
  static final BluetoothHealthService _instance = BluetoothHealthService._internal();
  factory BluetoothHealthService() => _instance;
  BluetoothHealthService._internal();

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _vitalsCharacteristic;
  bool _isConnected = false;
  StreamSubscription<List<int>>? _dataSubscription;

  // UUIDs matching your ESP32 code
  final String serviceUUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  final String characteristicUUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

  // Connection state stream
  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;

  // Data received stream
  final StreamController<Map<String, dynamic>> _dataController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get dataStream => _dataController.stream;

  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      _connectedDevice = device;
      
      List<BluetoothService> services = await device.discoverServices();
      
      for (BluetoothService service in services) {
        if (service.uuid.toString().toLowerCase() == serviceUUID.toLowerCase()) {
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            if (characteristic.uuid.toString().toLowerCase() == characteristicUUID.toLowerCase()) {
              _vitalsCharacteristic = characteristic;
              
              // Enable notifications
              await characteristic.setNotifyValue(true);
              
              // Listen for incoming data
              _dataSubscription = characteristic.onValueReceived.listen((value) {
                _handleIncomingData(value);
              });
              
              _isConnected = true;
              _connectionController.add(true);
              
              print('✅ Bluetooth connected and notifications enabled');
              return true;
            }
          }
        }
      }
      
      // If we get here, connection failed
      await device.disconnect();
      _isConnected = false;
      return false;
    } catch (e) {
      print('❌ Bluetooth connection error: $e');
      _isConnected = false;
      return false;
    }
  }

  void _handleIncomingData(List<int> data) {
    try {
      String jsonString = utf8.decode(data);
      Map<String, dynamic> parsedData = json.decode(jsonString);
      
      print('📱 Received Bluetooth data: $parsedData');
      _dataController.add(parsedData);
    } catch (e) {
      print('❌ Error parsing Bluetooth data: $e');
    }
  }

  Future<void> disconnect() async {
    _dataSubscription?.cancel();
    _dataSubscription = null;
    
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
    }
    
    _isConnected = false;
    _connectedDevice = null;
    _vitalsCharacteristic = null;
    _connectionController.add(false);
    
    print('🔌 Bluetooth disconnected');
  }

  bool get isConnected => _isConnected;
  BluetoothDevice? get connectedDevice => _connectedDevice;

  void dispose() {
    _dataSubscription?.cancel();
    _connectionController.close();
    _dataController.close();
  }
}

// ✅ ADDED: Camera Color Scanner Screen
class CameraColorScanner extends StatefulWidget {
  final List<Color> proteinColors;
  final Function(int level, Color color) onColorDetected;

  const CameraColorScanner({
    Key? key,
    required this.proteinColors,
    required this.onColorDetected,
  }) : super(key: key);

  @override
  _CameraColorScannerState createState() => _CameraColorScannerState();
}

class _CameraColorScannerState extends State<CameraColorScanner> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  Color? _detectedColor;
  int? _detectedLevel;
  bool _isLoading = true;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _controller = CameraController(_cameras![0], ResolutionPreset.medium);
        await _controller!.initialize();
        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error initializing camera: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _captureAndAnalyze() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      final image = await _controller!.takePicture();
      final bytes = await image.readAsBytes();
      final imageData = img.decodeImage(bytes);

      if (imageData != null) {
        _analyzeImageColor(imageData);
      }
    } catch (e) {
      print('Error capturing image: $e');
    } finally {
      setState(() {
        _isCapturing = false;
      });
    }
  }

  void _analyzeImageColor(img.Image image) {
    // Sample color from center of image
    final centerX = image.width ~/ 2;
    final centerY = image.height ~/ 2;
    
    final pixel = image.getPixel(centerX, centerY);
    
    // CORRECTED: Use the proper way to get RGB values from the image package
    final r = pixel.r.toInt();
    final g = pixel.g.toInt();
    final b = pixel.b.toInt();
    
    final detectedColor = Color.fromRGBO(r, g, b, 1.0);

    // Find the closest matching color from protein colors
    int closestLevel = 0;
    Color closestColor = widget.proteinColors[0];
    double minDistance = double.maxFinite;

    for (int i = 0; i < widget.proteinColors.length; i++) {
      final color = widget.proteinColors[i];
      final distance = _colorDistance(detectedColor, color);
      
      if (distance < minDistance) {
        minDistance = distance;
        closestLevel = i;
        closestColor = color;
      }
    }

    setState(() {
      _detectedColor = detectedColor;
      _detectedLevel = closestLevel;
    });

    // If color is close enough to one of our protein colors
    if (minDistance < 100) { // Adjust threshold as needed
      widget.onColorDetected(closestLevel, closestColor);
      _showResultDialog(closestLevel, closestColor, detectedColor);
    } else {
      _showNoMatchDialog(detectedColor);
    }
  }

  // CORRECTED: Proper math functions usage
  double _colorDistance(Color c1, Color c2) {
    return sqrt(
      pow(c1.red - c2.red, 2) +
      pow(c1.green - c2.green, 2) +
      pow(c1.blue - c2.blue, 2)
    );
  }

  void _showResultDialog(int level, Color matchedColor, Color detectedColor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Color Detected!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Detected Protein Level: $level'),
            SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: detectedColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black),
                  ),
                ),
                SizedBox(width: 10),
                Text('Detected Color'),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: matchedColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black),
                  ),
                ),
                SizedBox(width: 10),
                Text('Matched Level $level'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to dashboard
            },
            child: Text('Use This Level'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Scan Again'),
          ),
        ],
      ),
    );
  }

  void _showNoMatchDialog(Color detectedColor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('No Match Found'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('The detected color doesn\'t match any protein level.'),
            SizedBox(height: 10),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: detectedColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black),
              ),
            ),
            SizedBox(height: 10),
            Text('Please try again with better lighting or a clearer urine strip.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan Urine Strip'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _controller == null || !_controller!.value.isInitialized
              ? Center(child: Text('Camera not available'))
              : Column(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          CameraPreview(_controller!),
                          // Center targeting crosshair
                          Center(
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.rectangle,
                                border: Border.all(color: Colors.white, width: 2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Instructions
                          Positioned(
                            bottom: 20,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: EdgeInsets.all(16),
                              color: Colors.black54,
                              child: Text(
                                'Point the camera at the urine strip. Ensure good lighting and center the strip in the frame.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          if (_detectedColor != null) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: _detectedColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.black),
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  _detectedLevel != null
                                      ? 'Detected Level: $_detectedLevel'
                                      : 'Color detected',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                            SizedBox(height: 10),
                          ],
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isCapturing ? null : _captureAndAnalyze,
                              icon: Icon(_isCapturing ? Icons.camera : Icons.camera_alt),
                              label: Text(_isCapturing ? 'Processing...' : 'Capture & Analyze'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 15),
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text('Cancel'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

class BluetoothHealthMetricsPage extends StatefulWidget {
  final String userEmail;
  final Map<String, dynamic>? initialBluetoothData;

  const BluetoothHealthMetricsPage({
    Key? key, 
    required this.userEmail,
    this.initialBluetoothData
  }) : super(key: key);

  @override
  _BluetoothHealthMetricsPageState createState() => _BluetoothHealthMetricsPageState();
}

class _BluetoothHealthMetricsPageState extends State<BluetoothHealthMetricsPage> {
  final TextEditingController _emergencyMessageController = TextEditingController();
  final BluetoothHealthService _bluetoothService = BluetoothHealthService();
  
  Map<String, dynamic>? vitalData;
  Map<String, dynamic>? bluetoothVitalData;
  bool isLoading = true;
  String errorMessage = '';
  int? selectedProteinLevel;
  Color? selectedProteinColor;
  Timer? _alertTimer;
  bool _showAlertDialog = false;
  bool _hasPostedInitialData = false;
  bool _isOnDashboardPage = false;
  bool _wearableDialogShown = false;

  // Glucose unit state
  GlucoseUnit _glucoseUnit = GlucoseUnit.mgDL;

  // Color detection variables
  final List<Color> _proteinColors = [
    Color(0xFF00C2C7), 
    Color(0xFFE5B7A5), 
    Color(0xFFB794C0), 
    Color(0xFFD8D8D8), 
    Color(0xFFF0D56D), 
    Color(0xFFF5C243), 
    Color(0xFFFFA500), 
    Color(0xFFFFD700), 
    Color(0xFFD2B48C), 
    Color(0xFF8B5A2B), 
  ];

  StreamSubscription<bool>? _connectionSubscription;
  StreamSubscription<Map<String, dynamic>>? _dataSubscription;

  @override
  void initState() {
    super.initState();
    _isOnDashboardPage = true;
    
    // Initialize with initial Bluetooth data if provided
    if (widget.initialBluetoothData != null) {
      setState(() {
        bluetoothVitalData = widget.initialBluetoothData;
        vitalData = _convertBluetoothData(widget.initialBluetoothData!);
        isLoading = false;
      });
      // Auto-post initial Bluetooth data to server
      _postBluetoothDataToServer(widget.initialBluetoothData!);
    } else {
      _fetchVitalData();
    }
    
    // Set up Bluetooth listeners
    _setupBluetoothListeners();
    
    // Start periodic tasks
    Timer.periodic(const Duration(seconds: 120), (Timer t) => _fetchVitalData());
    
    _alertTimer = Timer.periodic(const Duration(minutes: 3), (Timer t) {
      if (_isOnDashboardPage && mounted) {
        _checkAlarmingValues();
        _sendPredictionData();
      }
    });
  }

  // Glucose conversion functions
  double _convertGlucoseToMgDl(double? mmolL) {
    if (mmolL == null) return 0.0;
    return mmolL * 18.0;
  }

  double _convertGlucoseToMmolL(double? mgDl) {
    if (mgDl == null) return 0.0;
    return mgDl / 18.0;
  }

  String _getGlucoseDisplayValue() {
    final rawGlucose = vitalData?['glucose']?.toDouble();
    if (rawGlucose == null) return 'N/A';
    
    switch (_glucoseUnit) {
      case GlucoseUnit.mgDL:
        return '${rawGlucose.toStringAsFixed(1)} mg/dL';
      case GlucoseUnit.mmolL:
        final mmolL = _convertGlucoseToMmolL(rawGlucose);
        return '${mmolL.toStringAsFixed(1)} mmol/L';
    }
  }

  void _toggleGlucoseUnit() {
    setState(() {
      _glucoseUnit = _glucoseUnit == GlucoseUnit.mgDL 
          ? GlucoseUnit.mmolL 
          : GlucoseUnit.mgDL;
    });
  }

  // ✅ FIXED: Post Bluetooth data to Render server
  Future<void> _postBluetoothDataToServer(Map<String, dynamic> bluetoothData) async {
    try {
      print('📤 Posting Bluetooth data to server...');
      
      // Convert Bluetooth data format to match server expectations
      final Map<String, dynamic> postData = {
        'g': bluetoothData['glucose']?.toDouble() ?? bluetoothData['g']?.toDouble(),
        's': bluetoothData['systolic_bp']?.toDouble() ?? bluetoothData['s']?.toDouble(),
        'd': bluetoothData['diastolic_bp']?.toDouble() ?? bluetoothData['d']?.toDouble(),
        'h': bluetoothData['heart_rate']?.toDouble() ?? bluetoothData['h']?.toDouble(),
        'sp': bluetoothData['spo2']?.toDouble() ?? bluetoothData['sp']?.toDouble(),
        'sk': bluetoothData['skin_temp']?.toDouble() ?? bluetoothData['sk']?.toDouble(),
        'b': bluetoothData['body_temp']?.toDouble() ?? bluetoothData['b']?.toDouble(),
        'aclX': bluetoothData['accel_x']?.toDouble() ?? bluetoothData['aclX']?.toDouble(),
        'aclY': bluetoothData['accel_y']?.toDouble() ?? bluetoothData['aclY']?.toDouble(),
        'aclZ': bluetoothData['accel_z']?.toDouble() ?? bluetoothData['aclZ']?.toDouble(),
        'gyX': bluetoothData['gyro_x']?.toDouble() ?? bluetoothData['gyX']?.toDouble(),
        'gyY': bluetoothData['gyro_y']?.toDouble() ?? bluetoothData['gyY']?.toDouble(),
        'gyZ': bluetoothData['gyro_z']?.toDouble() ?? bluetoothData['gyZ']?.toDouble(),
        'source': 'bluetooth',
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Remove null values
      postData.removeWhere((key, value) => value == null);

      final response = await http.post(
        Uri.parse('https://patient-monitor-backend-patient.fly.dev/api/v1/heltec-live-vitals'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(postData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          print('✅ Bluetooth data posted successfully to server');
        } else {
          print('❌ Server returned error: ${responseData['message']}');
        }
      } else {
        print('❌ HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error posting Bluetooth data: $e');
    }
  }

  // Camera Color Detection Functionality
  void _showCameraColorScanner(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraColorScanner(
          proteinColors: _proteinColors,
          onColorDetected: (int level, Color color) {
            setState(() {
              selectedProteinLevel = level;
              selectedProteinColor = color;
            });
            _sendProteinLevelToBackend(level);
          },
        ),
      ),
    );
  }

  void _showUrineStripDialog(BuildContext context) {
    _showCameraColorScanner(context);
  }

  // Set up Bluetooth event listeners
  void _setupBluetoothListeners() {
    // Listen for connection state changes
    _connectionSubscription = _bluetoothService.connectionStream.listen((connected) {
      if (mounted) {
        setState(() {});
      }
    });

    // Listen for incoming Bluetooth data
    _dataSubscription = _bluetoothService.dataStream.listen((data) {
      if (mounted) {
        _handleBluetoothData(data);
      }
    });
  }

  // Handle incoming Bluetooth data
  void _handleBluetoothData(Map<String, dynamic> data) {
    print('🔄 Processing Bluetooth data: $data');
    
    setState(() {
      bluetoothVitalData = data;
      vitalData = _convertBluetoothData(data);
      isLoading = false;
    });

    // Post Bluetooth data to server
    _postBluetoothDataToServer(data);
    
    _checkAlarmingValues();
    _checkForZeroVitals();
  }

  void _checkForZeroVitals() {
    if (vitalData == null || !mounted || _wearableDialogShown) return;

    final heartRate = vitalData?['heartRate']?.toDouble() ?? 0.0;
    final spo2 = vitalData?['spo2']?.toDouble() ?? 0.0;

    if (heartRate == 0 || spo2 == 0) {
      _wearableDialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showWearableCheckDialog(context);
        }
      });
    }
  }

  // Helper method to convert Bluetooth data format
  Map<String, dynamic> _convertBluetoothData(Map<String, dynamic> data) {
    return {
      'glucose': data['glucose']?.toDouble() ?? data['g']?.toDouble(),
      'systolicBP': data['systolic_bp']?.toDouble() ?? data['s']?.toDouble(),
      'diastolicBP': data['diastolic_bp']?.toDouble() ?? data['d']?.toDouble(),
      'heartRate': data['heart_rate']?.toDouble() ?? data['h']?.toDouble(),
      'spo2': data['spo2']?.toDouble() ?? data['sp']?.toDouble(),
      'bodyTemp': data['body_temp']?.toDouble() ?? data['b']?.toDouble(),
      'skinTemp': data['skin_temp']?.toDouble() ?? data['sk']?.toDouble(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  @override
  void dispose() {
    _isOnDashboardPage = false;
    _alertTimer?.cancel();
    _connectionSubscription?.cancel();
    _dataSubscription?.cancel();
    _bluetoothService.dispose();
    super.dispose();
  }

  Future<void> _fetchVitalData() async {
    try {
      final response = await http.get(
        Uri.parse('https://patient-monitor-backend-patient.fly.dev/api/v1/heltec-live-vitals/latest'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          setState(() {
            vitalData = responseData['result'];
            isLoading = false;
          });
          if (_isOnDashboardPage && mounted) {
            _checkAlarmingValues();
            _checkForZeroVitals();
          }
        } else {
          setState(() {
            errorMessage = responseData['message'] ?? 'Failed to fetch data';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Server error: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Future<void> _fetchLatestNonZeroVitalData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      final response = await http.get(
        Uri.parse('https://patient-monitor-backend-patient.fly.dev/api/v1/heltec-live-vitals'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['result'] != null) {
          List<dynamic> allData = responseData['result'];
          
          Map<String, dynamic>? latestValidData;
          
          for (var data in allData) {
            final heartRate = data['heartRate']?.toDouble() ?? 0.0;
            final spo2 = data['spo2']?.toDouble() ?? 0.0;
            
            if (heartRate != 0 && spo2 != 0) {
              latestValidData = data;
              break;
            }
          }
          
          if (latestValidData != null) {
            setState(() {
              vitalData = latestValidData;
              isLoading = false;
              errorMessage = '';
              _wearableDialogShown = false;
            });
            if (_isOnDashboardPage && mounted) {
              _checkAlarmingValues();
            }
          } else {
            setState(() {
              errorMessage = 'No valid vital data available';
              isLoading = false;
            });
          }
        } else {
          setState(() {
            errorMessage = responseData['message'] ?? 'Failed to fetch data';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Server error: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  double _scaleProteinLevel(double rawLevel) {
    return rawLevel;
  }

  Future<void> _sendPredictionData() async {
    try {
      final systolicBP = vitalData?['systolicBP']?.toDouble() ?? 0.0;
      final diastolicBP = vitalData?['diastolicBP']?.toDouble() ?? 0.0;
      final rawProteinLevel = selectedProteinLevel?.toDouble() ?? 0.0;
      final proteinUrine = _scaleProteinLevel(rawProteinLevel);

      final response = await http.put(
        Uri.parse('https://patient-monitor-backend-patient.fly.dev/api/v1/heltec-esp32-predictions/patient/001'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'systolicBP': systolicBP,
          'diastolicBP': diastolicBP,
          'proteinUrine': proteinUrine,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          _hasPostedInitialData = true;
        }
      }
    } catch (e) {
      print('Error sending prediction data: ${e.toString()}');
    }
  }

  void _checkAlarmingValues() {
    if (vitalData == null || !_isOnDashboardPage || !mounted) return;
    
    final systolicBP = vitalData?['systolicBP']?.toDouble();
    final diastolicBP = vitalData?['diastolicBP']?.toDouble();
    final heartRate = vitalData?['heartRate']?.toDouble();
    final spo2 = vitalData?['spo2']?.toDouble();
    final bodyTemp = vitalData?['bodyTemp']?.toDouble();
    final proteinLevel = selectedProteinLevel ?? vitalData?['proteinLevel']?.toInt();
    
    List<String> alerts = [];

    if (systolicBP != null && diastolicBP != null) {
      final map = diastolicBP + (1/3) * (systolicBP - diastolicBP);

      if (map >= 107 && proteinLevel != null && proteinLevel >= 2) {
        alerts.add('Please consult your clinical team for blood pressure management and urine infection treatment.');
      } else if (map >= 107) {
        alerts.add('Please consult your clinical team for blood pressure management.');
      } else if (proteinLevel != null && proteinLevel >= 2) {
        alerts.add('Please consult your clinical team to treat urine infections.');
      }
    }

    if (heartRate != null && (heartRate < 60 || heartRate > 130)) {
      alerts.add('Please check in with your clinical care team for guidance on your heart rate monitoring.');
    }

    if (spo2 != null && spo2 < 94) {
      alerts.add('Please check in with your clinical care team for guidance on your oxygen monitoring.');
    }

    if (bodyTemp != null && (bodyTemp >= 38 || bodyTemp <= 30)) {
      alerts.add('Please check in with your clinical care team for guidance on your temperature monitoring.');
    }

    if (alerts.isNotEmpty && !_showAlertDialog && _isOnDashboardPage && mounted) {
      _showAlertDialog = true;
      _showAlarmingValuesAlert(alerts);
    }
  }

  void _showAlarmingValuesAlert(List<String> alerts) {
    if (!mounted || !_isOnDashboardPage) return;
    
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "Health Alerts",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          ),
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            elevation: 12,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.health_and_safety,
                      color: Colors.teal, size: 28),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "Health Alerts",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                children: alerts.asMap().entries.map((entry) {
                  int index = entry.key + 1;
                  String msg = entry.value;
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.teal.shade100),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.teal.shade100,
                          radius: 16,
                          child: Text(
                            "$index",
                            style: const TextStyle(
                                color: Colors.teal, 
                                fontWeight: FontWeight.bold,
                                fontSize: 14),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            msg,
                            style: const TextStyle(fontSize: 15, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            actionsPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            actions: [
              TextButton(
                onPressed: () {
                  _showAlertDialog = false;
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.teal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("OK", style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendProteinLevelToBackend(int proteinLevel) async {
    try {
      final response = await http.patch(
        Uri.parse('https://patient-monitor-backend-patient.fly.dev/api/v1/heltec-live-vitals/latest/protein-level'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"proteinLevel": proteinLevel}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          _showSnackbar(context, "Protein level updated successfully!", Colors.green);
          _sendPredictionData();
        } else {
          _showSnackbar(context, "Failed to update protein level: ${responseData['message']}", Colors.red);
        }
      } else {
        _showSnackbar(context, "Failed to update protein level: Server error ${response.statusCode}", Colors.red);
      }
    } catch (e) {
      _showSnackbar(context, "Error updating protein level: ${e.toString()}", Colors.red);
    }
  }

  String _getTimeAgo(String timestamp) {
    try {
      final createdAt = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(createdAt);

      if (difference.inSeconds < 1) return 'Just now';
      if (difference.inSeconds < 60) return '${difference.inSeconds}s ago';
      if (difference.inMinutes < 60) return '${difference.inMinutes}min ago';
      if (difference.inHours < 24) return '${difference.inHours}h ago';
      return '${difference.inDays}d ago';
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<void> _sendEmergencyAlert(String message) async {
    try {
      final response = await http.post(
        Uri.parse('https://patient-monitor-backend-patient.fly.dev/api/v1/emergency/contacts/send'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"message": message}),
      );

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        if (responseData['success']) {
          _showSnackbar(context, "Emergency alert sent successfully!", Colors.green);
        } else {
          _showSnackbar(context, "Failed to send alert: ${responseData['message']}", Colors.red);
        }
      } else {
        _showSnackbar(context, "Failed to send alert: Server error", Colors.red);
      }
    } catch (e) {
      _showSnackbar(context, "Error: ${e.toString()}", Colors.red);
    }
  }

  void _showEmergencyAlertDialog(BuildContext context) {
    final List<String> emergencyMessages = [
      "I'm pregnant and need help now.",
      "I feel dizzy",
      "I need to go to the hospital urgently.",
      "I'm bleeding",
      "My water just broke,I need assistance.",
    ];

    String? selectedMessage;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Emergency Alert'),
          content: StatefulBuilder(
            builder: (context, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Select an emergency message:'),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedMessage,
                  onChanged: (value) => setState(() => selectedMessage = value),
                  items: emergencyMessages.map((message) {
                    return DropdownMenuItem<String>(
                      value: message,
                      child: Text(
                        message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  isExpanded: true,
                  validator: (value) =>
                      value == null ? 'Please select a message' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedMessage != null && selectedMessage!.isNotEmpty) {
                  Navigator.pop(context);
                  _sendEmergencyAlert(selectedMessage!);
                } else {
                  _showSnackbar(context, "Please select an emergency message", Colors.red);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Send Alert'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Health Metrics',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _fetchLatestNonZeroVitalData();
            },
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: CircleAvatar(
              radius: 16,
              child: Text(
                widget.userEmail.isNotEmpty ? widget.userEmail[0].toUpperCase() : 'U',
                style: const TextStyle(color: Colors.blue, fontSize: 16),
              ),
              backgroundColor: Colors.white,
            ),
            onPressed: () {
              _showUserInfoDialog(context);
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Center(
                child: Text(
                  'PREGNANT WOMAN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today, color: Colors.blue),
              title: const Text('Schedule Appointment'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AppointmentScheduleByMedicPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.health_and_safety, color: Colors.blue),
              title: const Text('Pregnancy Tips'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WellnessTipsScreen(userEmail: widget.userEmail),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.pregnant_woman, color: Colors.blue),
              title: const Text('Pregnancy Chatbot'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PregChatBotPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.emergency, color: Colors.blue), 
              title: const Text('Emergency Contacts'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EmergencyContactsPage(userEmail: widget.userEmail),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_money, color: Colors.blue),
              title: const Text('Make Payment'), 
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaystackInitiatePage(), 
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.medical_services, color: Colors.blue),
              title: const Text('View All Medics Profile'), 
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MedicsListPage(), 
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.pregnant_woman, color: Colors.blue),
              title: const Text('Anemia Assessment'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AnaemiaAssessmentScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.healing, color: Colors.blue),
              title: const Text('How Are You Feeling?'), 
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SymptomForm(), 
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.bloodtype, color: Colors.blue),
              title: Text('Charts'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChartsDataPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.search, color: Colors.blue),
              title: const Text(
                'Find Your Favorite Medic',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FindDoctorByNamePage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(12),
          child: isLoading 
            ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
            : errorMessage.isNotEmpty
              ? Center(
                  child: Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.red, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                )
              : Column(
                  children: [
                    GridView.count(
                      crossAxisCount: 2,
                      childAspectRatio: 1.0, // Increased from 0.95 to 1.0 for more space
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        // Glucose Card with Unit Toggle
                        GestureDetector(
                          onTap: _toggleGlucoseUnit,
                          child: MetricCard(
                            title: 'Blood Glucose',
                            value: _getGlucoseDisplayValue(),
                            icon: Icons.water_drop,
                            color: Colors.purple,
                            lastUpdated: _getTimeAgo(vitalData?['updatedAt'] ?? ''),
                            showUnitToggle: true,
                          ),
                        ),
                        
                        MetricCard(
                          title: 'Blood Pressure',
                          value: '${vitalData?['systolicBP']?.toStringAsFixed(0) ?? 'N/A'}/${vitalData?['diastolicBP']?.toStringAsFixed(0) ?? 'N/A'} mmHg',
                          icon: Icons.favorite,
                          color: Colors.pink,
                          lastUpdated: _getTimeAgo(vitalData?['updatedAt'] ?? ''),
                        ),
                        
                        MetricCard(
                          title: 'Heart Rate',
                          value: '${vitalData?['heartRate']?.toStringAsFixed(0) ?? 'N/A'} BPM',
                          icon: Icons.monitor_heart,
                          color: Colors.red,
                          lastUpdated: _getTimeAgo(vitalData?['updatedAt'] ?? ''),
                        ),
                        
                        MetricCard(
                          title: 'Oxygen Saturation',
                          value: '${vitalData?['spo2']?.toStringAsFixed(0) ?? 'N/A'}%',
                          icon: Icons.air,
                          color: Colors.blue,
                          lastUpdated: _getTimeAgo(vitalData?['updatedAt'] ?? ''),
                        ),
                        
                        MetricCard(
                          title: 'Body Temperature',
                          value: '${vitalData?['bodyTemp']?.toStringAsFixed(1) ?? 'N/A'}°C',
                          icon: Icons.thermostat,
                          color: Colors.orange,
                          lastUpdated: _getTimeAgo(vitalData?['updatedAt'] ?? ''),
                        ),
                        
                        GestureDetector(
                          onTap: () => _showUrineStripDialog(context),
                          child: MetricCard(
                            title: 'Protein in Urine',
                            value: selectedProteinLevel != null 
                                ? 'Level: $selectedProteinLevel'
                                : 'Tap to Scan',
                            icon: Icons.science,
                            color: Colors.indigo,
                            lastUpdated: selectedProteinLevel != null 
                                ? 'Just now'
                                : 'Click to scan',
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

  void _showUserInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Profile',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  _buildProfileItem(
                    icon: Icons.email_outlined,
                    text: widget.userEmail,
                    onTap: null,
                  ),
                  
                  _buildProfileItem(
                    icon: Icons.emergency,
                    text: 'Send An Emergency Alert',
                    onTap: () {
                      Navigator.pop(context);
                      _showEmergencyAlertDialog(context);
                    },
                  ),
                  
                  _buildProfileItem(
                    icon: Icons.settings_outlined,
                    text: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SetProfilePage(userEmail: widget.userEmail),
                        ),
                      );
                    },
                  ),

                  _buildProfileItem(
                    icon: Icons.bluetooth,
                    text: 'Pair With Bluetooth Device',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WearableDevicePairingPage(userEmail: widget.userEmail),
                        ),
                      );
                    },
                  ),

                  _buildProfileItem(
                    icon: Icons.notifications_active_outlined,
                    text: 'Notifications',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NotificationListPage(),
                        ),
                      );
                    },
                  ),
                  
                  _buildProfileItem(
                    icon: Icons.help_outline,
                    text: 'Need Help?',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SupportFormPage(),
                        ),
                      );
                    },
                  ),
                  
                  _buildProfileItem(
                    icon: Icons.location_on,
                    text: 'View Location Of PregMama',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MapPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  TextButton(
                    onPressed: () async {
                      final response = await http.put(
                        Uri.parse('https://patient-monitor-backend-patient.fly.dev/api/v1/users/logout'),
                        headers: {'Content-Type': 'application/json'},
                      );

                      if (response.statusCode == 200) {
                        final responseData = json.decode(response.body);
                        if (responseData['success']) {
                          await _bluetoothService.disconnect();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => LoginPage()),
                          );
                        } else {
                          _showSnackbar(
                              context,
                              "Logout failed: ${responseData['message']}",
                              Colors.red);
                        }
                      } else {
                          _showSnackbar(
                              context,
                              "Logout failed: Server error",
                              Colors.red);
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileItem({
    required IconData icon,
    required String text,
    required VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Colors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onTap != null) 
                const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showWearableCheckDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Wearable Check'),
        content: const Text('Are You Wearing The Wearable?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _fetchLatestNonZeroVitalData();
            },
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WearableDevicePairingPage(userEmail: widget.userEmail),
                ),
              );
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  void _showSnackbar(BuildContext context, String message, Color color) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: color,
      duration: const Duration(seconds: 2),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}

// ✅ UPDATED: Optimized MetricCard to prevent overflow
class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String lastUpdated;
  final bool showUnitToggle;

  const MetricCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.lastUpdated,
    this.showUnitToggle = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10), // Reduced from 12 to 10
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Centered icon - optimized size
            Container(
              width: 42, // Reduced from 50 to 42
              height: 42, // Reduced from 50 to 42
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.2),
              ),
              child: Icon(
                icon,
                color: color,
                size: 22, // Reduced from 28 to 22
              ),
            ),
            
            const SizedBox(height: 6), // Reduced from 8 to 6
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11, // Reduced from 13 to 11
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3), // Reduced from 4 to 3
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 14, // Reduced from 16 to 14
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
            ),
            const SizedBox(height: 3), // Reduced from 4 to 3
            Text(
              lastUpdated,
              style: TextStyle(
                fontSize: 9, // Reduced from 10 to 9
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Unit toggle hint - only for glucose card
            if (showUnitToggle) ...[
              const SizedBox(height: 2), // Reduced from 4 to 2
              Text(
                'Tap to switch units',
                style: TextStyle(
                  fontSize: 8, // Reduced from 9 to 8
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
            ],
          ],
        ),
      ),
    );
  }
}