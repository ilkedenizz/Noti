enum LogType {
  system,
  command,
  output,
  error,
  success,
}

class TerminalLogItem {
  final String id;
  final LogType type;
  final String text;
  final DateTime timestamp;

  const TerminalLogItem({
    required this.id,
    required this.type,
    required this.text,
    required this.timestamp,
  });
}
