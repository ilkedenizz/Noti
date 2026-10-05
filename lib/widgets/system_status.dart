import 'package:flutter/material.dart';

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
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
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
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'monospace',
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
