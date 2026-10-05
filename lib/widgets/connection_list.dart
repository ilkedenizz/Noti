import 'package:flutter/material.dart';
import '../models/user_connection.dart';

class ConnectionListWidget extends StatelessWidget {
  final List<UserConnection> connections;
  final ValueChanged<String> onCallUser;

  const ConnectionListWidget({
    super.key,
    required this.connections,
    required this.onCallUser,
  });

  Widget _buildStatusBadge(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.ready:
        return const Text(
          '(Status: READY)',
          style: TextStyle(
            color: Color(0xFF22C55E),
            fontFamily: 'monospace',
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        );
      case ConnectionStatus.busy:
        return const Text(
          '(Status: BUSY)',
          style: TextStyle(
            color: Color(0xFFEAB308),
            fontFamily: 'monospace',
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        );
      case ConnectionStatus.offline:
        return const Text(
          '(Status: OFFLINE)',
          style: TextStyle(
            color: Color(0xFF737373),
            fontFamily: 'monospace',
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '[ CONNECTION LIST ]',
            style: TextStyle(
              color: Color(0xFFA3A3A3),
              fontFamily: 'monospace',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          ...connections.map((user) {
            final isOffline = user.status == ConnectionStatus.offline;
            return Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: Colors.transparent),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        '* ${user.handle.padRight(7)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => onCallUser(user.handle),
                        borderRadius: BorderRadius.circular(2),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isOffline ? const Color(0xFF121212) : const Color(0xFF171717),
                            border: Border.all(
                              color: isOffline ? const Color(0xFF262626) : const Color(0xFF333333),
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.phone,
                                size: 10,
                                color: isOffline ? const Color(0xFF525252) : const Color(0xFFE5E5E5),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '[CALL]',
                                style: TextStyle(
                                  color: isOffline ? const Color(0xFF525252) : const Color(0xFFE5E5E5),
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  _buildStatusBadge(user.status),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
