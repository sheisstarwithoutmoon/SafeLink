import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/api_config.dart';
import 'storage_service.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  final StorageService _storage = StorageService();
  
  bool get isConnected => _socket?.connected ?? false;

  // Callbacks
  Function(Map<String, dynamic>)? onEmergencyAlert;
  Function(String, String)? onAlertSent;
  Function(String)? onAlertCancelled;
  Function()? onConnected;
  Function()? onDisconnected;
  Function(dynamic)? onError;

  Future<void> connect() async {
    if (_socket != null && _socket!.connected) {
      print('Socket already connected');
      return;
    }

    // If socket exists but disconnected, try to reconnect
    if (_socket != null && !_socket!.connected) {
      print('Reconnecting existing socket...');
      _socket!.connect();
      return;
    }

    try {
      final userId = await _storage.getUserId();
      if (userId == null) {
        print('Socket.IO: User not logged in, skipping connection');
        return; // Don't throw error, just skip connection
      }

      print('Creating new socket connection...');

      _socket = IO.io(
        ApiConfig.socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(10) // Increased attempts
            .setReconnectionDelay(1000)
            .setReconnectionDelayMax(5000)
            .build(),
      );

      _setupEventHandlers();

      _socket!.connect();

      // Authenticate after connection
      _socket!.on('connect', (_) {
        print('Socket connected');
        authenticate(userId);
        onConnected?.call();
      });

      _socket!.on('disconnect', (reason) {
        print('Socket disconnected: $reason');
        onDisconnected?.call();
      });

      _socket!.on('reconnect', (attemptNumber) {
        print('Socket reconnected after $attemptNumber attempts');
        authenticate(userId);
      });

      _socket!.on('reconnect_attempt', (attemptNumber) {
        print('Socket reconnection attempt: $attemptNumber');
      });

      _socket!.on('reconnect_failed', (_) {
        print('Socket reconnection failed');
      });

      _socket!.on('error', (error) {
        print('Socket error: $error');
        onError?.call(error);
      });

    } catch (e) {
      print('Error connecting to socket: $e');
      rethrow;
    }
  }

  void _setupEventHandlers() {
    if (_socket == null) return;

    // Authentication response
    _socket!.on('authenticated', (data) {
      print('Socket authenticated: $data');
    });

    // Emergency alert received (for emergency contacts)
    _socket!.on('emergency:alert', (data) {
      print('Emergency alert received: $data');
      if (data is Map<String, dynamic>) {
        onEmergencyAlert?.call(data);
      }
    });

    // Alert sent confirmation
    _socket!.on('alert:sent', (data) {
      print('Alert sent: $data');
      if (data is Map && data['alertId'] != null && data['message'] != null) {
        onAlertSent?.call(data['alertId'].toString(), data['message'].toString());
      }
    });

    // Alert cancelled
    _socket!.on('emergency:cancelled', (data) {
      print('Alert cancelled: $data');
      if (data is Map && data['alertId'] != null) {
        onAlertCancelled?.call(data['alertId'].toString());
      }
    });

    // Countdown update
    _socket!.on('countdown:update', (data) {
      print('Countdown update: $data');
    });
  }

  void authenticate(String userId) {
    if (_socket?.connected == true) {
      _socket!.emit('authenticate', {'userId': userId});
    }
  }

  void createEmergency({
    required String alertId,
    required double latitude,
    required double longitude,
    int? magnitude,
    String? address,
  }) {
    if (_socket?.connected != true) {
      print('Socket not connected');
      return;
    }

    _socket!.emit('emergency:create', {
      'alertId': alertId,
      'latitude': latitude,
      'longitude': longitude,
      'magnitude': magnitude,
      'address': address,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void updateLocation({
    required String alertId,
    required double latitude,
    required double longitude,
    String? address,
  }) {
    if (_socket?.connected != true) {
      print('Socket not connected');
      return;
    }

    _socket!.emit('location:update', {
      'alertId': alertId,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void cancelEmergency(String alertId) {
    if (_socket?.connected != true) {
      print('Socket not connected');
      return;
    }

    _socket!.emit('emergency:cancel', {
      'alertId': alertId,
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void dispose() {
    disconnect();
  }
}
