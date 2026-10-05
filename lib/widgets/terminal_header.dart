import 'package:flutter/material.dart';

class TerminalHeaderWidget extends StatelessWidget {
  const TerminalHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '[TERMINAL.EXE] EMER_SIGNAL_V0.1',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'monospace',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'SYS_STAT: ',
                      style: TextStyle(color: Color(0xFFA3A3A3)),
                    ),
                    TextSpan(
                      text: '[RUNNING]',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                style: TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ],
          ),
          SizedBox(height: 8),
          Divider(color: Color(0xFF262626), height: 1, thickness: 1),
        ],
      ),
    );
  }
}
