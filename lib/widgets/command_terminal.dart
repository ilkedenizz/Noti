import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/terminal_log.dart';
import '../models/user_connection.dart';
import '../models/noti_alert.dart';
import '../services/notification_service.dart';
import '../utils/command_parser.dart';

class CommandTerminalWidget extends StatefulWidget {
  final List<UserConnection> connections;
  final ValueChanged<List<UserConnection>> onUpdateConnections;
  final String? externalCommand;
  final VoidCallback? onClearExternalCommand;

  const CommandTerminalWidget({
    super.key,
    required this.connections,
    required this.onUpdateConnections,
    this.externalCommand,
    this.onClearExternalCommand,
  });

  @override
  State<CommandTerminalWidget> createState() => _CommandTerminalWidgetState();
}

class _CommandTerminalWidgetState extends State<CommandTerminalWidget> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  StreamSubscription<NotiAlert>? _alertSubscription;
  StreamSubscription<NotiAlert>? _tapSubscription;

  final List<String> _commandHistory = [];
  int _historyIndex = 0;

  final List<TerminalLogItem> _logs = [
    TerminalLogItem(
      id: 'init-1',
      type: LogType.system,
      text: 'NOTI OS v0.1 initialized.',
      timestamp: DateTime.now(),
    ),
    TerminalLogItem(
      id: 'init-2',
      type: LogType.system,
      text: 'Type /help to view available terminal commands.',
      timestamp: DateTime.now(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _setupNotificationListeners();
  }

  void _setupNotificationListeners() {
    _alertSubscription = NotificationService().alertStream.listen((alert) {
      if (!mounted) return;
      final time =
          '${alert.createdAt.hour.toString().padLeft(2, '0')}:${alert.createdAt.minute.toString().padLeft(2, '0')}:${alert.createdAt.second.toString().padLeft(2, '0')}';
      final isEmergency = alert.priority == NotiAlertPriority.emergency;

      final logItem = TerminalLogItem(
        id: 'rx_${DateTime.now().millisecondsSinceEpoch}_${alert.id}',
        type: isEmergency ? LogType.error : LogType.output,
        text: '[ALERT RECEIVED]\n'
            'TARGET: ${alert.recipientUsername}\n'
            'FROM: ${alert.senderUsername}\n'
            'PRIORITY: ${alert.priority.label}\n'
            'TITLE: ${alert.title}\n'
            'MSG: ${alert.message}\n'
            'TIME: $time\n'
            'ID: ${alert.id}',
        timestamp: DateTime.now(),
      );

      setState(() {
        _logs.add(logItem);
      });
      _scrollToBottom();
    });

    _tapSubscription = NotificationService().notificationTapStream.listen((alert) {
      if (!mounted) return;
      final logItem = TerminalLogItem(
        id: 'tap_${DateTime.now().millisecondsSinceEpoch}_${alert.id}',
        type: LogType.success,
        text: '> NOTIFICATION_INTERACTION: Direct alert focus [${alert.id}] from ${alert.senderUsername}.',
        timestamp: DateTime.now(),
      );

      setState(() {
        _logs.add(logItem);
      });
      _scrollToBottom();
      _focusNode.requestFocus();
    });
  }

  @override
  void didUpdateWidget(covariant CommandTerminalWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.externalCommand != null && widget.externalCommand!.isNotEmpty) {
      final cmd = widget.externalCommand!;
      widget.onClearExternalCommand?.call();
      _executeCommand(cmd);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _navigateHistory(true);
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _navigateHistory(false);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  void _navigateHistory(bool up) {
    if (_commandHistory.isEmpty) return;
    if (up) {
      if (_historyIndex > 0) {
        _historyIndex--;
      } else {
        _historyIndex = 0;
      }
      _controller.text = _commandHistory[_historyIndex];
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    } else {
      if (_historyIndex < _commandHistory.length - 1) {
        _historyIndex++;
        _controller.text = _commandHistory[_historyIndex];
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
      } else {
        _historyIndex = _commandHistory.length;
        _controller.clear();
      }
    }
  }

  void _executeCommand(String rawCmd) async {
    final trimmed = rawCmd.trim();
    if (trimmed.isEmpty) return;

    // Track command in history
    if (_commandHistory.isEmpty || _commandHistory.last != trimmed) {
      _commandHistory.add(trimmed);
    }
    _historyIndex = _commandHistory.length;

    final result = await CommandParser.parseAndExecute(
      trimmed,
      CommandContext(connections: widget.connections),
    );

    if (result.actionType == CommandActionType.clearLogs) {
      setState(() {
        _logs.clear();
      });
      return;
    }

    if (result.actionType == CommandActionType.updateConnections &&
        result.updatedConnections != null) {
      widget.onUpdateConnections(result.updatedConnections!);
    }

    if (result.logsToAppend.isNotEmpty) {
      final now = DateTime.now();
      final newLogs = result.logsToAppend.map((log) {
        return TerminalLogItem(
          id: '${now.millisecondsSinceEpoch}_${log.text.hashCode}',
          type: log.type,
          text: log.text,
          timestamp: now,
        );
      }).toList();

      setState(() {
        _logs.addAll(newLogs);
      });
      _scrollToBottom();
    }
  }

  void _handleSubmit(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;

    _controller.clear();
    _executeCommand(trimmed);
  }

  Color _getLogColor(LogType type) {
    switch (type) {
      case LogType.command:
        return Colors.white;
      case LogType.system:
        return const Color(0xFFA3A3A3);
      case LogType.output:
        return const Color(0xFFD4D4D4);
      case LogType.error:
        return const Color(0xFFEF4444);
      case LogType.success:
        return const Color(0xFF22C55E);
    }
  }

  @override
  void dispose() {
    _alertSubscription?.cancel();
    _tapSubscription?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _focusNode.requestFocus(),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(color: Color(0xFF262626), height: 1, thickness: 1),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Text(
                    '> ',
                    style: TextStyle(
                      color: Color(0xFF525252),
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'WAITING_FOR_COMMAND....',
                    style: TextStyle(
                      color: Color(0xFFA3A3A3),
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Scrollable Terminal Logs
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        log.text,
                        style: TextStyle(
                          color: _getLogColor(log.type),
                          fontFamily: 'monospace',
                          fontSize: 12,
                          height: 1.4,
                          fontWeight: (log.type == LogType.error || log.type == LogType.success)
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Terminal Command Input
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xFF171717), width: 1.0),
                  ),
                ),
                child: Row(
                  children: [
                    const Text(
                      '~\$ ',
                      style: TextStyle(
                        color: Color(0xFF737373),
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Focus(
                        onKeyEvent: _handleKeyEvent,
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          onSubmitted: _handleSubmit,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                          cursorColor: Colors.white,
                          autocorrect: false,
                          enableSuggestions: false,
                          decoration: const InputDecoration(
                            hintText: '/send_alert @ceviz',
                            hintStyle: TextStyle(
                              color: Color(0xFF404040),
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
