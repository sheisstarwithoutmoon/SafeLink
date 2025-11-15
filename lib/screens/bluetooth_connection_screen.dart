import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../theme/app_theme.dart';
import '../widgets/device_card.dart';
import '../widgets/status_indicator.dart';
import '../widgets/loading_indicator.dart';
import '../services/bluetooth_service.dart';

class BluetoothConnectionScreen extends StatefulWidget {
  const BluetoothConnectionScreen({Key? key}) : super(key: key);

  @override
  State<BluetoothConnectionScreen> createState() => _BluetoothConnectionScreenState();
}

class _BluetoothConnectionScreenState extends State<BluetoothConnectionScreen>
    with SingleTickerProviderStateMixin {
  final BluetoothService _bluetoothService = BluetoothService();
  late TabController _tabController;

  List<BluetoothDevice> _pairedDevices = [];
  List<BluetoothDiscoveryResult> _discoveredDevices = [];
  bool _isScanning = false;
  bool _isBluetoothEnabled = false;
  bool _hasPermissions = false;
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeBluetooth();
    _setupListeners();
  }

  Future<void> _initializeBluetooth() async {
    final result = await _bluetoothService.initialize();
    setState(() {
      _hasPermissions = result['hasPermissions'] ?? false;
      _isBluetoothEnabled = result['isEnabled'] ?? false;
    });

    if (_hasPermissions && _isBluetoothEnabled) {
      _loadPairedDevices();
    }
  }

  void _setupListeners() {
    _bluetoothService.connectionStateStream?.listen((isConnected) {
      if (mounted) {
        setState(() {
          _connectionStatus = isConnected
              ? ConnectionStatus.connected
              : ConnectionStatus.disconnected;
        });
      }
    });
  }

  Future<void> _loadPairedDevices() async {
    final devices = await _bluetoothService.getBondedDevices();
    setState(() {
      _pairedDevices = devices;
    });
  }

  void _startScanning() {
    setState(() {
      _isScanning = true;
      _discoveredDevices.clear();
    });

    _bluetoothService.startDiscovery().listen(
      (result) {
        setState(() {
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
          _isScanning = false;
        });
      },
      onError: (error) {
        setState(() {
          _isScanning = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Scan error: $error'),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() {
      _connectionStatus = ConnectionStatus.syncing;
    });

    try {
      final success = await _bluetoothService.connectToDevice(device);
      
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected to ${device.name}'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection failed'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _connectionStatus = ConnectionStatus.disconnected;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _connectionStatus = ConnectionStatus.disconnected;
      });
    }
  }

  Future<void> _disconnectDevice() async {
    await _bluetoothService.disconnect();
    setState(() {
      _connectionStatus = ConnectionStatus.disconnected;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Disconnected'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Connection'),
        backgroundColor: AppTheme.primaryBackground,
        foregroundColor: AppTheme.primaryAccent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryAccent,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryAccent,
          tabs: const [
            Tab(text: 'Paired Devices'),
            Tab(text: 'Scan'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Connection status header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.softGray,
              border: Border(
                bottom: BorderSide(color: AppTheme.borderGray),
              ),
            ),
            child: Row(
              children: [
                StatusIndicator(
                  status: _connectionStatus,
                  label: _bluetoothService.connectedDevice?.name ?? 'No device',
                ),
                const Spacer(),
                if (_connectionStatus == ConnectionStatus.connected)
                  TextButton.icon(
                    onPressed: _disconnectDevice,
                    icon: const Icon(Icons.bluetooth_disabled),
                    label: const Text('Disconnect'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.emergencyRed,
                    ),
                  ),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPairedDevicesTab(),
                _buildScanTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPairedDevicesTab() {
    if (!_hasPermissions || !_isBluetoothEnabled) {
      return _buildPermissionMessage();
    }

    if (_pairedDevices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bluetooth_disabled,
              size: 64,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No paired devices',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Scan for nearby devices',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pairedDevices.length,
      itemBuilder: (context, index) {
        final device = _pairedDevices[index];
        final isConnected = _bluetoothService.connectedDevice?.address == device.address;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DeviceCard(
            deviceName: device.name ?? 'Unknown Device',
            macAddress: device.address,
            isPaired: true,
            isConnected: isConnected,
            onConnect: () => _connectToDevice(device),
            onDisconnect: _disconnectDevice,
          ),
        );
      },
    );
  }

  Widget _buildScanTab() {
    if (!_hasPermissions || !_isBluetoothEnabled) {
      return _buildPermissionMessage();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _isScanning
                      ? 'Scanning for devices...'
                      : 'Tap to scan for nearby devices',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isScanning ? null : _startScanning,
                icon: Icon(_isScanning ? Icons.stop : Icons.search),
                label: Text(_isScanning ? 'Stop' : 'Scan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isScanning && _discoveredDevices.isEmpty
              ? const LoadingIndicator(message: 'Scanning...')
              : _discoveredDevices.isEmpty
                  ? Center(
                      child: Text(
                        'No devices found',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _discoveredDevices.length,
                      itemBuilder: (context, index) {
                        final result = _discoveredDevices[index];
                        final device = result.device;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: DeviceCard(
                            deviceName: device.name ?? 'Unknown Device',
                            macAddress: device.address,
                            signalStrength: result.rssi,
                            isPaired: false,
                            isConnected: false,
                            onConnect: () => _connectToDevice(device),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildPermissionMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 64,
              color: AppTheme.emergencyRed,
            ),
            const SizedBox(height: 16),
            Text(
              !_hasPermissions
                  ? 'Bluetooth Permission Required'
                  : 'Bluetooth is Disabled',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              !_hasPermissions
                  ? 'Please grant Bluetooth permission in app settings'
                  : 'Please enable Bluetooth in device settings',
              style: TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
