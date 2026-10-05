import 'dart:async';
import 'package:flutter/material.dart';

class StatusBarWidget extends StatefulWidget {
  const StatusBarWidget({super.key});

  @override
  State<StatusBarWidget> createState() => _StatusBarWidgetState();
}

class _StatusBarWidgetState extends State<StatusBarWidget> {
  late String _currentTime;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();
    final hours = now.hour.toString().padLeft(2, '0');
    final minutes = now.minute.toString().padLeft(2, '0');
    if (mounted) {
      setState(() {
        _currentTime = '$hours:$minutes';
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(
          bottom: BorderSide(color: Color(0xFF262626), width: 1.0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                _currentTime,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'monospace',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.wifi, color: Color(0xFFE5E5E5), size: 14),
            ],
          ),
          const Row(
            children: [
              Icon(Icons.battery_charging_full, color: Color(0xFFE5E5E5), size: 14),
              SizedBox(width: 4),
              Text(
                'BATTERY 82%',
                style: TextStyle(
                  color: Color(0xFFD4D4D4),
                  fontFamily: 'monospace',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.terminal, color: Color(0xFFE5E5E5), size: 14),
            ],
          ),
        ],
      ),
    );
  }
}
