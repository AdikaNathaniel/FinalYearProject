import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'bluetooth-health-data.dart';

class WearableDevicePairingPage extends StatefulWidget {
  final String userEmail;
  final bool autoRequestRunningAverages; 
  
  const WearableDevicePairingPage({
    super.key, 
    required this.userEmail,
    this.autoRequestRunningAverages = false, 
  });

  @override
  State<WearableDevicePairingPage> createState() => _WearableDevicePairingPageState();
}

class _WearableDevicePairingPageState extends State<WearableDevicePairingPage> {
  bool isRegistered = false;
  bool isScanning = false;
  bool isConnecting = false;
  bool isConnected = false;
  
  String? savedDeviceId;
  String? savedDeviceName;
  DateTime? lastConnected;
  String? lastReceivedData;
  
  List<ScanResult> scanResults = [];
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? vitalsCharacteristic;
  BluetoothCharacteristic? instantCharacteristic;
  StreamSubscription<List<ScanResult>>? scanSubscription;
  StreamSubscription<BluetoothConnectionState>? connectionSubscription;
  StreamSubscription<List<int>>? characteristicSubscription;
  StreamSubscription<List<int>>? instantCharacteristicSubscription;

  // For auto-request feature
  bool isRequestingData = false;
  bool hasRequestedData = false;
  Timer? autoRequestTimer;

  // ESP32 Service and Characteristic UUIDs
  static const String SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  static const String INSTANT_READING_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a9";

  @override
  void initState() {
    super.initState();
    _loadSavedDevice();
    _checkBluetoothState();
    
    // Auto-request data if parameter is true
    if (widget.autoRequestRunningAverages) {
      _initAutoRequest();
    }
  }

  @override
  void dispose() {
    scanSubscription?.cancel();
    connectionSubscription?.cancel();
    characteristicSubscription?.cancel();
    instantCharacteristicSubscription?.cancel();
    autoRequestTimer?.cancel();
    super.dispose();
  }

  // Initialize auto-request sequence
  Future<void> _initAutoRequest() async {
    // Wait a bit for UI to settle
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Check if device is already connected
    if (isConnected && instantCharacteristic != null) {
      await _requestInstantReading();
    } else if (savedDeviceId != null) {
      // Try to reconnect and then request
      await _reconnectToSavedDevice();
      
      // Wait for connection to establish
      autoRequestTimer = Timer(const Duration(seconds: 3), () async {
        if (isConnected && instantCharacteristic != null) {
          await _requestInstantReading();
        } else {
          _showErrorDialog('Could not connect to device. Please ensure device is powered on and nearby.');
        }
      });
    } else {
      _showErrorDialog('No paired device found. Please pair with your wearable device first.');
    }
  }

  // Request instant reading via the instant characteristic
  Future<void> _requestInstantReading() async {
    if (instantCharacteristic == null) {
      _showErrorDialog('Not connected to device');
      return;
    }

    setState(() {
      isRequestingData = true;
      hasRequestedData = false;
    });

    try {
      // Show loading indicator
      _showLoadingDialog('Requesting instant readings from device...');
      
      print('📱 Sending instant reading request to MCU...');
      
      // METHOD 1: Write command to trigger instant reading
      List<int> commandBytes = utf8.encode('get_reading');
      await instantCharacteristic!.write(commandBytes);
      print('✅ Sent instant reading request to MCU');
      
      // Wait for response via notification
      await Future.delayed(const Duration(seconds: 3));
      
      // METHOD 2: Alternatively, read the characteristic directly if no notification received
      if (!hasRequestedData) {
        print('🔄 No notification received, trying direct read...');
        List<int> response = await instantCharacteristic!.read();
        _handleInstantData(response);
      }
      
    } catch (e) {
      print('❌ Error requesting instant reading: $e');
      _showErrorDialog('Failed to request data: $e');
      setState(() {
        isRequestingData = false;
      });
      Navigator.of(context).pop(); // Close loading dialog if open
    }
  }

  // Handle data from instant characteristic
  void _handleInstantData(List<int> value) {
    try {
      String data = utf8.decode(value);
      print('📱 Received INSTANT data: $data');
      
      setState(() {
        lastReceivedData = data;
      });
      
      // Parse JSON data
      Map<String, dynamic> vitalsData = json.decode(data);
      
      print('📊 Parsed INSTANT vitals data:');
      print('Type: ${vitalsData['type'] ?? 'N/A'}');
      print('Glucose: ${vitalsData['g'] ?? vitalsData['glucose']} mg/dL');
      print('Blood Pressure: ${vitalsData['s'] ?? vitalsData['systolic_bp']}/${vitalsData['d'] ?? vitalsData['diastolic_bp']} mmHg');
      print('Heart Rate: ${vitalsData['h'] ?? vitalsData['heart_rate']} bpm');
      print('SpO2: ${vitalsData['sp'] ?? vitalsData['spo2']} %');
      print('Body Temperature: ${vitalsData['b'] ?? vitalsData['body_temp']} °C');
      
      // Handle auto-request completion
      if (widget.autoRequestRunningAverages && !hasRequestedData) {
        hasRequestedData = true;
        setState(() {
          isRequestingData = false;
        });
        
        // Close loading dialog if open
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✓ Instant readings received!',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Return data to calling page
        Navigator.of(context).pop(vitalsData);
        return;
      }
      
      // Show notification to user for regular readings
      _showVitalsNotification(vitalsData);
      
    } catch (e) {
      print('❌ Error parsing instant data: $e');
      
      // Handle error during auto-request
      if (widget.autoRequestRunningAverages && !hasRequestedData) {
        setState(() {
          isRequestingData = false;
        });
        
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        
        _showErrorDialog('Failed to parse instant data: $e');
      }
    }
  }

  // Show loading dialog
  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  // Check Bluetooth state
  Future<void> _checkBluetoothState() async {
    try {
      if (Platform.isAndroid) {
        final adapterState = await FlutterBluePlus.adapterState.first;
        if (adapterState != BluetoothAdapterState.on) {
          _showBluetoothDialog();
        }
      }
    } catch (e) {
      print('Error checking Bluetooth state: $e');
    }
  }

  void _showBluetoothDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.bluetooth_disabled, color: Colors.orange),
            SizedBox(width: 8),
            Text('Bluetooth Off'),
          ],
        ),
        content: const Text('Please turn on Bluetooth to scan for devices.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Request Bluetooth permissions
  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();

      bool allGranted = statuses.values.every((status) => status.isGranted);
      
      if (!allGranted) {
        _showErrorDialog('Bluetooth permissions are required to scan for devices.');
        return false;
      }
      return true;
    }
    return true;
  }

  // Load saved device information
  Future<void> _loadSavedDevice() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      savedDeviceId = prefs.getString('wearable_device_id');
      savedDeviceName = prefs.getString('wearable_device_name');
      final timestamp = prefs.getInt('last_connected');
      if (timestamp != null) {
        lastConnected = DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      isRegistered = savedDeviceId != null;
    });
  }

  // Save device information
  Future<void> _saveDevice(String deviceId, String deviceName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('wearable_device_id', deviceId);
    await prefs.setString('wearable_device_name', deviceName);
    await prefs.setInt('last_connected', DateTime.now().millisecondsSinceEpoch);
    
    setState(() {
      savedDeviceId = deviceId;
      savedDeviceName = deviceName;
      lastConnected = DateTime.now();
      isRegistered = true;
    });
  }

  // Clear saved device (reset/unpair)
  Future<void> _resetDevice() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('wearable_device_id');
    await prefs.remove('wearable_device_name');
    await prefs.remove('last_connected');
    
    if (connectedDevice != null) {
      try {
        await connectedDevice!.disconnect();
      } catch (e) {
        print('Error disconnecting: $e');
      }
    }
    
    setState(() {
      savedDeviceId = null;
      savedDeviceName = null;
      lastConnected = null;
      isRegistered = false;
      isConnected = false;
      connectedDevice = null;
      vitalsCharacteristic = null;
      instantCharacteristic = null;
      scanResults.clear();
      lastReceivedData = null;
    });
    
    _showSuccessDialog('Device reset successfully');
  }

  // Start scanning for Bluetooth devices
  Future<void> _startScan() async {
    bool hasPermissions = await _requestPermissions();
    if (!hasPermissions) return;

    setState(() {
      isScanning = true;
      scanResults.clear();
    });

    try {
      if (await FlutterBluePlus.isSupported == false) {
        _showErrorDialog('Bluetooth is not supported on this device');
        setState(() => isScanning = false);
        return;
      }

      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        _showBluetoothDialog();
        setState(() => isScanning = false);
        return;
      }

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        androidUsesFineLocation: true,
      );
      
      scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        setState(() {
          // Filter for ESP32-Vitals-Monitor devices or devices with names
          scanResults = results.where((r) => 
            r.device.platformName.isNotEmpty || 
            r.device.advName.isNotEmpty
          ).toList();
        });
      });

      await Future.delayed(const Duration(seconds: 15));
      await FlutterBluePlus.stopScan();
      setState(() => isScanning = false);
      
      if (scanResults.isEmpty) {
        _showErrorDialog('No devices found. Make sure your ESP32 is powered on and nearby.');
      }
      
    } catch (e) {
      _showErrorDialog('Error scanning: $e');
      setState(() => isScanning = false);
    }
  }

  // Enhanced connection with better debugging
  Future<void> _connectToDevice(BluetoothDevice device) async {
    print('🔗 Starting connection to ${device.platformName}...');
    setState(() => isConnecting = true);

    try {
      // Add connection state listener BEFORE connecting
      connectionSubscription = device.connectionState.listen((state) {
        print('🔗 Connection state changed: $state');
        setState(() {
          isConnected = state == BluetoothConnectionState.connected;
        });
        
        if (state == BluetoothConnectionState.disconnected) {
          _showErrorDialog('Device disconnected');
        }
      });

      await device.connect(timeout: const Duration(seconds: 15));
      
      // Wait a bit for connection to stabilize
      await Future.delayed(const Duration(milliseconds: 500));
      
      final currentState = await device.connectionState.first;
      print('✅ Final connection state: $currentState');
      
      if (currentState == BluetoothConnectionState.connected) {
        // Add service discovery with timeout
        try {
          print('🔍 Discovering services...');
          List<BluetoothService> services = await device.discoverServices().timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('Service discovery timed out');
            },
          );
          
          print('📡 Discovered ${services.length} services');
          
          // Find the vitals service and characteristics
          bool foundService = false;
          for (var service in services) {
            String serviceUuid = service.uuid.toString().toLowerCase();
            print('🔧 Service UUID: $serviceUuid');
            
            if (serviceUuid == SERVICE_UUID.toLowerCase()) {
              foundService = true;
              print('✅ Found target service!');
              
              for (var characteristic in service.characteristics) {
                String charUuid = characteristic.uuid.toString().toLowerCase();
                print('🔧 Characteristic UUID: $charUuid');
                
                // Handle main vitals characteristic
                if (charUuid == CHARACTERISTIC_UUID.toLowerCase()) {
                  vitalsCharacteristic = characteristic;
                  print('✅ Found vitals characteristic');
                  
                  // Subscribe to notifications for regular data
                  await characteristic.setNotifyValue(true);
                  characteristicSubscription = characteristic.onValueReceived.listen((value) {
                    print('📥 Received data on vitals characteristic');
                    _handleReceivedData(value);
                  });
                }
                
                // Handle instant reading characteristic
                else if (charUuid == INSTANT_READING_UUID.toLowerCase()) {
                  instantCharacteristic = characteristic;
                  print('✅ Found instant characteristic');
                  
                  // Subscribe to notifications for instant data
                  await characteristic.setNotifyValue(true);
                  instantCharacteristicSubscription = characteristic.onValueReceived.listen((value) {
                    print('📥 Received data on instant characteristic');
                    _handleInstantData(value);
                  });
                }
              }
              break;
            }
          }
          
          if (!foundService) {
            throw Exception('Target service not found. Available services: ${services.map((s) => s.uuid.toString()).toList()}');
          }
          
          await _saveDevice(device.remoteId.toString(), device.platformName);
          setState(() {
            connectedDevice = device;
            isConnecting = false;
            isConnected = true;
          });
          
          _showSuccessDialog('Connected to ${device.platformName}\nReady to receive vitals data!');
          
        } catch (e) {
          print('❌ Service discovery failed: $e');
          throw e;
        }
      } else {
        setState(() => isConnecting = false);
        _showErrorDialog('Failed to connect to device');
      }
    } catch (e) {
      print('❌ Connection failed: $e');
      _showErrorDialog('Connection failed: $e');
      setState(() => isConnecting = false);
    }
  }

  // Handle received data from main vitals characteristic
  void _handleReceivedData(List<int> value) {
    try {
      String data = utf8.decode(value);
      print('📥 Received data: $data');
      
      setState(() {
        lastReceivedData = data;
      });
      
      // Parse JSON data
      Map<String, dynamic> vitalsData = json.decode(data);
      
      print('📊 Received regular vitals data:');
      print('Type: ${vitalsData['type'] ?? 'N/A'}');
      print('Glucose: ${vitalsData['glucose']} mg/dL');
      print('Blood Pressure: ${vitalsData['systolic_bp']}/${vitalsData['diastolic_bp']} mmHg');
      print('Heart Rate: ${vitalsData['heart_rate']} bpm');
      print('SpO2: ${vitalsData['spo2']} %');
      print('Body Temperature: ${vitalsData['body_temp']} °C');
      
      // Show notification to user
      _showVitalsNotification(vitalsData);
      
    } catch (e) {
      print('❌ Error parsing received data: $e');
    }
  }

  void _showVitalsNotification(Map<String, dynamic> vitals) {
    String dataType = vitals['type'] == 'running_averages' 
        ? 'Running Averages' 
        : vitals['type'] == 'current_reading'
        ? 'Current Reading'
        : 'New Data';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$dataType received!\nHR: ${vitals['heart_rate'] ?? vitals['h']} bpm | SpO2: ${vitals['spo2'] ?? vitals['sp']}%',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Reconnect to saved device
  Future<void> _reconnectToSavedDevice() async {
    if (savedDeviceId == null) return;

    setState(() => isConnecting = true);

    try {
      final connectedDevices = await FlutterBluePlus.connectedDevices;
      
      BluetoothDevice? device;
      for (var d in connectedDevices) {
        if (d.remoteId.toString() == savedDeviceId) {
          device = d;
          break;
        }
      }

      if (device == null) {
        throw Exception('Device not found. Please scan again.');
      }

      await _connectToDevice(device);
    } catch (e) {
      _showErrorDialog('Could not reconnect: $e\nPlease scan for the device again.');
      setState(() => isConnecting = false);
    }
  }

  void _showErrorDialog(String message) {
    print('❌ Error: $message');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    print('✅ Success: $message');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green),
            SizedBox(width: 8),
            Text('Success'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Device'),
        content: const Text('Are you sure you want to unpair this device?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetDevice();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  // Get instant readings button
  Widget _buildGetInstantReadingsButton() {
    return ElevatedButton.icon(
      onPressed: isConnected && !isRequestingData ? _requestInstantReading : null,
      icon: isRequestingData 
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.refresh),
      label: Text(isRequestingData ? 'Requesting...' : 'Get Instant Readings'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // Navigate to BluetoothHealthMetricsPage
  void _navigateToHealthMetrics() {
    if (lastReceivedData == null) {
      _showErrorDialog('No data received yet');
      return;
    }
    
    try {
      Map<String, dynamic> vitals = json.decode(lastReceivedData!);
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BluetoothHealthMetricsPage(
            userEmail: widget.userEmail,
            initialBluetoothData: vitals,
          ),
        ),
      );
    } catch (e) {
      _showErrorDialog('Error displaying data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Bluetooth Connect'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Container(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 20),
            
            if (!isRegistered) ...[
              _buildRegistrationSection(),
            ] else ...[
              _buildConnectedSection(),
            ],
            
            if (isScanning || scanResults.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildScanResultsSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    IconData icon;
    Color iconColor;
    String statusText;
    String? subtitle;

    if (isConnected) {
      icon = Icons.bluetooth_connected;
      iconColor = Colors.green;
      statusText = 'Connected';
      subtitle = savedDeviceName ?? 'ESP32 Device';
    } else if (isRegistered) {
      icon = Icons.bluetooth;
      iconColor = Colors.orange;
      statusText = 'Paired (Not Connected)';
      subtitle = savedDeviceName ?? 'ESP32 Device';
    } else {
      icon = Icons.bluetooth_disabled;
      iconColor = Colors.grey;
      statusText = 'Not Paired';
      subtitle = 'Scan for Awoapa-Wearable';
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(icon, size: 64, color: iconColor),
            const SizedBox(height: 12),
            Text(
              statusText,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
            if (lastConnected != null) ...[
              const SizedBox(height: 8),
              Text(
                'Last connected: ${_formatDateTime(lastConnected!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
            if (isConnected) ...[
              const SizedBox(height: 12),
              _buildGetInstantReadingsButton(),
              if (lastReceivedData != null) ...[
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _navigateToHealthMetrics,
                  icon: const Icon(Icons.show_chart, size: 18),
                  label: const Text('View Latest Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: isScanning ? null : _startScan,
          icon: isScanning
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.search),
          label: Text(isScanning ? 'Scanning...' : 'Scan for Devices'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Device Management',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 16),
        
        if (isConnected) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Device Connected',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        'Receiving vitals data from ${savedDeviceName ?? "ESP32"}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ] else ...[
          ElevatedButton.icon(
            onPressed: isConnecting ? null : _reconnectToSavedDevice,
            icon: isConnecting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh),
            label: const Text('Reconnect to Device'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        OutlinedButton.icon(
          onPressed: _startScan,
          icon: const Icon(Icons.search),
          label: const Text('Scan for New Device'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.blue,
            side: const BorderSide(color: Colors.blue),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        OutlinedButton.icon(
          onPressed: _showResetConfirmation,
          icon: const Icon(Icons.settings_backup_restore),
          label: const Text('Reset / Unpair Device'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScanResultsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Available Devices',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 12),
        if (scanResults.isEmpty && !isScanning)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Icon(Icons.devices_other, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'No devices found',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Make sure ESP32 is powered on',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
          )
        else
          ...scanResults.map((result) {
            String deviceName = result.device.platformName.isNotEmpty 
                ? result.device.platformName 
                : (result.device.advName.isNotEmpty 
                    ? result.device.advName 
                    : 'Unknown Device');
            
            bool isESP32 = deviceName.toLowerCase().contains('esp32') || 
                          deviceName.toLowerCase().contains('vitals');
            
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: isESP32 ? Colors.green[50] : Colors.white,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isESP32 ? Colors.green : Colors.blue,
                  child: Icon(
                    isESP32 ? Icons.monitor_heart : Icons.bluetooth,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                title: Text(
                  deviceName,
                  style: TextStyle(
                    fontWeight: isESP32 ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  result.device.remoteId.toString(),
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: isConnecting
                    ? const CircularProgressIndicator()
                    : IconButton(
                        icon: Icon(
                          Icons.link,
                          color: isESP32 ? Colors.green : Colors.blue,
                        ),
                        onPressed: () => _connectToDevice(result.device),
                      ),
              ),
            );
          }),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}