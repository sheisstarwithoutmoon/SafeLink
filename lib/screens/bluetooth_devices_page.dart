import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:safe_ride/services/bluetooth_service.dart';

class BluetoothDevicesPage extends StatefulWidget {
  const BluetoothDevicesPage({Key? key}) : super(key: key);

  @override
  State<BluetoothDevicesPage> createState() => _BluetoothDevicesPageState();
}

class _BluetoothDevicesPageState extends State<BluetoothDevicesPage> {
  final BluetoothService _bluetoothService = BluetoothService();
  
  List<BluetoothDevice> _bondedDevices = [];
  List<BluetoothDiscoveryResult> _discoveredDevices = [];
  bool _isDiscovering = false;
  bool _isBluetoothEnabled = false;
  bool _hasPermissions = false;

  @override
  void initState() {
    super.initState();
    _checkBluetoothState();
    
    // Listen to connection state changes
    _bluetoothService.connectionStateStream.listen((isConnected) {
      if (mounted) {
        setState(() {});
        if (isConnected) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Connected to ${_bluetoothService.connectedDevice?.name}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    });

    // Listen to incoming data
    _bluetoothService.dataStream.listen((data) {
      print('📩 Bluetooth Data: $data');
      // Handle incoming data (e.g., accident detection signal)
      if (data.contains('ACCIDENT') || data.contains('CRASH')) {
        _handleAccidentDetected();
      }
    });
  }

  Future<void> _checkBluetoothState() async {
    final initResult = await _bluetoothService.initialize();
    
    setState(() {
      _hasPermissions = initResult['hasPermissions'] ?? false;
      _isBluetoothEnabled = initResult['isEnabled'] ?? false;
    });

    if (_hasPermissions && _isBluetoothEnabled) {
      _loadBondedDevices();
    }
  }

  Future<void> _loadBondedDevices() async {
    final devices = await _bluetoothService.getBondedDevices();
    setState(() {
      _bondedDevices = devices;
    });
  }

  void _startDiscovery() {
    setState(() {
      _isDiscovering = true;
      _discoveredDevices.clear();
    });

    _bluetoothService.startDiscovery().listen(
      (result) {
        setState(() {
          // Add device if not already in list
          final existingIndex = _discoveredDevices.indexWhere(
            (item) => item.device.address == result.device.address,
          );
          if (existingIndex >= 0) {
            _discoveredDevices[existingIndex] = result;
          } else {
            _discoveredDevices.add(result);
          }
        });
      },
      onDone: () {
        setState(() {
          _isDiscovering = false;
        });
      },
      onError: (error) {
        print('Discovery error: $error');
        setState(() {
          _isDiscovering = false;
        });
      },
    );
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    final success = await _bluetoothService.connectToDevice(device);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Connected to ${device.name ?? device.address}'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to connect to ${device.name ?? device.address}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleAccidentDetected() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 32),
            SizedBox(width: 12),
            Text('Accident Detected!'),
          ],
        ),
        content: const Text(
          'The accelerometer has detected a potential accident. Emergency alert will be sent in 15 seconds.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Cancel emergency alert
            },
            child: const Text('I\'m OK - Cancel Alert'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Devices'),
        actions: [
          if (_bluetoothService.isConnected)
            IconButton(
              icon: const Icon(Icons.bluetooth_connected),
              onPressed: () {
                _bluetoothService.disconnect();
              },
              tooltip: 'Disconnect',
            ),
        ],
      ),
      body: !_hasPermissions || !_isBluetoothEnabled
          ? _buildSetupRequired()
          : Column(
              children: [
                // Connection status
                if (_bluetoothService.isConnected)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.green.shade100,
                    child: Row(
                      children: [
                        const Icon(Icons.bluetooth_connected, color: Colors.green),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Connected to ${_bluetoothService.connectedDevice?.name ?? "Device"}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => _bluetoothService.disconnect(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Disconnect'),
                        ),
                      ],
                    ),
                  ),

                // Bonded devices section
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Paired devices
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Paired Devices',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: _loadBondedDevices,
                            tooltip: 'Refresh',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_bondedDevices.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'No paired devices found.\nPair your HC-05 module in system Bluetooth settings first.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        ..._bondedDevices.map((device) => _buildDeviceCard(device, true)),

                      const SizedBox(height: 24),

                      // Discovered devices
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Available Devices',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _isDiscovering ? null : _startDiscovery,
                            icon: _isDiscovering
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.search),
                            label: Text(_isDiscovering ? 'Scanning...' : 'Scan'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_discoveredDevices.isEmpty && !_isDiscovering)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'No devices found.\nTap "Scan" to discover nearby devices.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        ..._discoveredDevices.map(
                          (result) => _buildDeviceCard(result.device, false, result.rssi),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSetupRequired() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _hasPermissions ? Icons.bluetooth_disabled : Icons.location_off,
              size: 64,
              color: Colors.orange,
            ),
            const SizedBox(height: 24),
            Text(
              !_hasPermissions
                  ? 'Bluetooth Permissions Required'
                  : 'Bluetooth is Disabled',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              !_hasPermissions
                  ? 'Safe Ride needs Bluetooth and Location permissions to connect to your accident detection device.'
                  : 'Please enable Bluetooth to connect to your accident detection device.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _checkBluetoothState,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceCard(BluetoothDevice device, bool isBonded, [int? rssi]) {
    final isConnected = _bluetoothService.isConnected &&
        _bluetoothService.connectedDevice?.address == device.address;
    final isConnecting = _bluetoothService.isConnecting;

    return Card(
      elevation: isConnected ? 4 : 1,
      color: isConnected ? Colors.green.shade50 : null,
      child: ListTile(
        leading: Icon(
          isBonded ? Icons.bluetooth_connected : Icons.bluetooth,
          color: isConnected ? Colors.green : Colors.blue,
          size: 32,
        ),
        title: Text(
          device.name ?? 'Unknown Device',
          style: TextStyle(
            fontWeight: isConnected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(device.address),
            if (rssi != null)
              Text(
                'Signal: $rssi dBm',
                style: TextStyle(
                  color: rssi > -70 ? Colors.green : Colors.orange,
                  fontSize: 12,
                ),
              ),
            if (isBonded)
              const Text(
                'Paired',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        trailing: isConnected
            ? const Icon(Icons.check_circle, color: Colors.green)
            : ElevatedButton(
                onPressed: isConnecting ? null : () => _connectToDevice(device),
                child: Text(isConnecting ? 'Connecting...' : 'Connect'),
              ),
      ),
    );
  }

  @override
  void dispose() {
    // Don't dispose the service here as it's a singleton
    super.dispose();
  }
}
