import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class SystemStatusWidget extends StatelessWidget {
  final int totalConnections;
  final String userProfile;

  const SystemStatusWidget({
    super.key,
    required this.totalConnections,
    this.userProfile = '@hocam',
  });

  @override
  Widget build(BuildContext context) {
    final fcmActive = NotificationService().isFirebaseInitialized;
    final hasPermission = NotificationService().hasNotificationPermission;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRow('SYSTEM_STATUS:', '[ACTIVE]'),
          const SizedBox(height: 2),
          _buildRow('USER_PROFILE:', userProfile),
          const SizedBox(height: 2),
          _buildRow('CONNECTIONS:', '[$totalConnections TOTAL]'),
          const SizedBox(height: 2),
          _buildRow(
            'FCM_LINK:',
            fcmActive ? '[ACTIVE]' : '[STANDBY]',
            valueColor: fcmActive ? const Color(0xFF22C55E) : const Color(0xFFEAB308),
          ),
          const SizedBox(height: 2),
          _buildRow(
            'ALERT_CHANNEL:',
            hasPermission ? '[EMERGENCY_READY]' : '[PERM_REQUIRED]',
            valueColor: hasPermission ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        const Text(
          '> ',
          style: TextStyle(
            color: Color(0xFF525252),
            fontFamily: 'monospace',
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '$label ',
          style: const TextStyle(
            color: Color(0xFFD4D4D4),
            fontFamily: 'monospace',
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontFamily: 'monospace',
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
