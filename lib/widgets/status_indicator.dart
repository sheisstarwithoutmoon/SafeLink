import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum ConnectionStatus { connected, disconnected, syncing }

class StatusIndicator extends StatelessWidget {
  final ConnectionStatus status;
  final String label;
  final bool showLabel;

  const StatusIndicator({
    Key? key,
    required this.status,
    required this.label,
    this.showLabel = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color color;
    String statusText;

    switch (status) {
      case ConnectionStatus.connected:
        color = AppTheme.successGreen;
        statusText = 'Connected';
        break;
      case ConnectionStatus.disconnected:
        color = AppTheme.emergencyRed;
        statusText = 'Not Connected';
        break;
      case ConnectionStatus.syncing:
        color = Colors.orange;
        statusText = 'Syncing...';
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        if (showLabel) ...[
          const SizedBox(width: 8),
          Text(
            label.isNotEmpty ? label : statusText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ],
    );
  }
}
