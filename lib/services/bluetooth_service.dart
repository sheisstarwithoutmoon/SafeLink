import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:typed_data';

class BluetoothService {
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  BluetoothService._internal();

  FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  BluetoothConnection? _connection;
  
  bool _isConnecting = false;
  bool get isConnecting => _isConnecting;
  
  bool _isConnected = false;
  bool get isConnected => _isConnected;
  
  BluetoothDevice? _connectedDevice;
  BluetoothDevice? get connectedDevice => _connectedDevice;

  final StreamController<String> _dataController = StreamController<String>.broadcast();
  Stream<String> get dataStream => _dataController.stream;

  final StreamController<bool> _connectionStateController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStateStream => _connectionStateController.stream;

  /// Request all necessary Bluetooth permissions
  Future<bool> requestPermissions() async {
    try {
      print('🔐 Requesting Bluetooth permissions...');
      
      // Request Bluetooth permissions
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location, // Required for Bluetooth scanning
      ].request();

      // Check if all permissions are granted
      bool allGranted = statuses.values.every((status) => status.isGranted);
      
      if (allGranted) {
        print('✅ All Bluetooth permissions granted');
      } else {
        print('❌ Some Bluetooth permissions denied:');
        statuses.forEach((permission, status) {
          print('   ${permission.toString()}: ${status.toString()}');
        });
      }

      return allGranted;
    } catch (e) {
      print('❌ Error requesting Bluetooth permissions: $e');
      return false;
    }
  }

  /// Check if Bluetooth is enabled
  Future<bool> isBluetoothEnabled() async {
    try {
      bool? isEnabled = await _bluetooth.isEnabled;
      return isEnabled ?? false;
    } catch (e) {
      print('❌ Error checking Bluetooth state: $e');
      return false;
    }
  }

  /// Request to enable Bluetooth
  Future<bool> enableBluetooth() async {
    try {
      print('📡 Requesting to enable Bluetooth...');
      bool? result = await _bluetooth.requestEnable();
      if (result == true) {
        print('✅ Bluetooth enabled');
        return true;
      } else {
        print('❌ User denied Bluetooth enable request');
        return false;
      }
    } catch (e) {
      print('❌ Error enabling Bluetooth: $e');
      return false;
    }
  }

  /// Get list of bonded (paired) devices
  Future<List<BluetoothDevice>> getBondedDevices() async {
    try {
      print('📱 Getting bonded devices...');
      List<BluetoothDevice> devices = await _bluetooth.getBondedDevices();
      print('✅ Found ${devices.length} bonded devices');
      return devices;
    } catch (e) {
      print('❌ Error getting bonded devices: $e');
      return [];
    }
  }

  /// Scan for available Bluetooth devices
  Stream<BluetoothDiscoveryResult> startDiscovery() {
    print('🔍 Starting Bluetooth discovery...');
    return _bluetooth.startDiscovery();
  }

  /// Connect to a Bluetooth device
  Future<bool> connectToDevice(BluetoothDevice device, {int maxRetries = 2}) async {
    if (_isConnecting) {
      print('Already connecting to a device, please wait...');
      return false;
    }

    // If already connected to this device, return success
    if (_isConnected && _connectedDevice?.address == device.address) {
      print('Already connected to ${device.name ?? device.address}');
      return true;
    }

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        _isConnecting = true;
        print('Connecting to ${device.name ?? device.address}... (Attempt $attempt/$maxRetries)');

        // Disconnect from current device if connected to a different device
        if (_isConnected && _connectedDevice?.address != device.address) {
          await disconnect();
          await Future.delayed(const Duration(milliseconds: 500));
        }

        _connection = await BluetoothConnection.toAddress(device.address)
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () {
                throw Exception('Connection timeout - HC-05 not responding');
              },
            );
        
        _isConnected = true;
        _isConnecting = false;
        _connectedDevice = device;
        _connectionStateController.add(true);

        print('Connected to ${device.name ?? device.address}');

        // Listen to incoming data
        _connection!.input!.listen(
          (data) {
            String message = String.fromCharCodes(data);
            print('Received: $message');
            _dataController.add(message);
          },
          onDone: () {
            print('Connection closed by remote device');
            _handleDisconnection();
          },
          onError: (error) {
            print('Connection error: $error');
            _handleDisconnection();
          },
          cancelOnError: false,
        );

        return true;
      } catch (e) {
        String errorMsg = e.toString();
        if (errorMsg.contains('read failed')) {
          print('Attempt $attempt failed: HC-05 socket error (device may be paired with another phone)');
        } else if (errorMsg.contains('timeout')) {
          print('Attempt $attempt failed: Connection timeout');
        } else {
          print('Attempt $attempt failed: $errorMsg');
        }
        
        _isConnecting = false;
        _isConnected = false;
        _connectionStateController.add(false);
        
        if (attempt < maxRetries) {
          print('Retrying in 2 seconds...');
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    }
    
    print('Failed to connect after $maxRetries attempts. Try:');
    print('1. Unpair HC-05 from other devices');
    print('2. Move closer to HC-05');
    print('3. Reset Arduino and HC-05 module');
    return false;
  }

  /// Send data to connected device
  Future<bool> sendData(String data) async {
    if (!_isConnected || _connection == null) {
      print('⚠️ Not connected to any device');
      return false;
    }

    try {
      _connection!.output.add(Uint8List.fromList(data.codeUnits));
      await _connection!.output.allSent;
      print('📤 Sent: $data');
      return true;
    } catch (e) {
      print('❌ Error sending data: $e');
      return false;
    }
  }

  /// Disconnect from current device
  Future<void> disconnect() async {
    if (_connection != null) {
      try {
        await _connection!.close();
        print('🔌 Disconnected from ${_connectedDevice?.name ?? 'device'}');
      } catch (e) {
        print('❌ Error during disconnect: $e');
      }
    }
    _handleDisconnection();
  }

  void _handleDisconnection() {
    _isConnected = false;
    _isConnecting = false;
    _connectedDevice = null;
    _connection = null;
    _connectionStateController.add(false);
  }

  /// Initialize Bluetooth service (check permissions and state)
  Future<Map<String, dynamic>> initialize() async {
    try {
      print('🚀 Initializing Bluetooth service...');
      
      // Check and request permissions
      bool hasPermissions = await requestPermissions();
      if (!hasPermissions) {
        return {
          'success': false,
          'error': 'Bluetooth permissions not granted',
          'needsPermissions': true,
        };
      }

      // Check if Bluetooth is enabled
      bool isEnabled = await isBluetoothEnabled();
      if (!isEnabled) {
        // Try to enable Bluetooth
        bool enabled = await enableBluetooth();
        if (!enabled) {
          return {
            'success': false,
            'error': 'Bluetooth is not enabled',
            'needsBluetooth': true,
          };
        }
      }

      print('✅ Bluetooth service initialized successfully');
      return {
        'success': true,
        'hasPermissions': true,
        'isEnabled': true,
      };
    } catch (e) {
      print('❌ Error initializing Bluetooth service: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _dataController.close();
    _connectionStateController.close();
  }
}
