import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DeviceCard extends StatelessWidget {
  final String deviceName;
  final String macAddress;
  final bool isConnected;
  final bool isConnecting;
  final bool isPaired;
  final int? signalStrength;
  final VoidCallback? onConnect;
  final VoidCallback? onDisconnect;

  const DeviceCard({
    Key? key,
    required this.deviceName,
    required this.macAddress,
    this.isConnected = false,
    this.isConnecting = false,
    this.isPaired = false,
    this.signalStrength,
    this.onConnect,
    this.onDisconnect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isConnected ? AppTheme.successGreen.withOpacity(0.1) : AppTheme.cardGray,
        borderRadius: BorderRadius.circular(16),
        border: isConnected ? Border.all(color: AppTheme.successGreen, width: 2) : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(
          isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
          color: isConnected ? AppTheme.successGreen : AppTheme.primaryAccent,
          size: 32,
        ),
        title: Text(
          deviceName,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isConnected ? FontWeight.bold : FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              macAddress,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textTertiary,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                if (isPaired)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Paired',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (signalStrength != null) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.signal_cellular_alt,
                    size: 14,
                    color: signalStrength! > -70 ? AppTheme.successGreen : Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$signalStrength dBm',
                    style: TextStyle(
                      fontSize: 11,
                      color: signalStrength! > -70 ? AppTheme.successGreen : Colors.orange,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: isConnected
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: AppTheme.successGreen),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: onDisconnect,
                    child: const Text('Disconnect'),
                  ),
                ],
              )
            : SizedBox(
                width: 100,
                child: ElevatedButton(
                  onPressed: isConnecting ? null : onConnect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: Text(isConnecting ? 'Connecting...' : 'Connect'),
                ),
              ),
      ),
    );
  }
}
