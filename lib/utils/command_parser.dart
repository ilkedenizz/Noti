import '../models/user_connection.dart';
import '../models/terminal_log.dart';
import '../models/noti_alert.dart';
import '../services/alert_service.dart';
import '../services/notification_service.dart';

class CommandContext {
  final List<UserConnection> connections;

  const CommandContext({required this.connections});
}

enum CommandActionType {
  none,
  clearLogs,
  updateConnections,
}

class LogOutput {
  final LogType type;
  final String text;

  const LogOutput({required this.type, required this.text});
}

class CommandExecutionResult {
  final CommandActionType actionType;
  final List<UserConnection>? updatedConnections;
  final List<LogOutput> logsToAppend;

  const CommandExecutionResult({
    this.actionType = CommandActionType.none,
    this.updatedConnections,
    required this.logsToAppend,
  });
}

class CommandParser {
  static Future<CommandExecutionResult> parseAndExecute(
    String rawInput,
    CommandContext ctx,
  ) async {
    final trimmed = rawInput.trim();
    if (trimmed.isEmpty) {
      return const CommandExecutionResult(logsToAppend: []);
    }

    final parts = trimmed.split(RegExp(r'\s+'));
    final commandName = parts[0].toLowerCase();
    final rawArgs = parts.sublist(1);

    final commandLog = LogOutput(
      type: LogType.command,
      text: '~\$ $trimmed',
    );

    switch (commandName) {
      case '/help':
        return CommandExecutionResult(
          logsToAppend: [
            commandLog,
            const LogOutput(
              type: LogType.output,
              text: 'AVAILABLE COMMANDS:\n'
                  '  /help                             - Show available commands\n'
                  '  /status                           - Show detailed system status\n'
                  '  /users                            - List connected peers and status\n'
                  '  /alerts                           - Show alert dispatch and receive history\n'
                  '  /retry <alert_id>                 - Retry dispatching a failed alert\n'
                  '  /permit                           - Request Android notification permission\n'
                  '  /send_alert [--emergency] @user   - Dispatch alert signal (Normal/Emergency)\n'
                  '  /clear                            - Clear terminal log output',
            ),
          ],
        );

      case '/status':
        final ready = ctx.connections.where((u) => u.status == ConnectionStatus.ready).length;
        final busy = ctx.connections.where((u) => u.status == ConnectionStatus.busy).length;
        final offline = ctx.connections.where((u) => u.status == ConnectionStatus.offline).length;
        final fcmActive = NotificationService().isFirebaseInitialized;
        final hasPermission = NotificationService().hasNotificationPermission;

        return CommandExecutionResult(
          logsToAppend: [
            commandLog,
            LogOutput(
              type: LogType.output,
              text: '> SYS_DIAGNOSTICS: OPTIMAL\n'
                  '> NETWORK_NODES: ${ctx.connections.length} TOTAL ($ready READY, $busy BUSY, $offline OFFLINE)\n'
                  '> ENCRYPTION: 4096-BIT RSA / ACTIVE\n'
                  '> ALERT_SERVICE: ONLINE (REPOS: MOCK_ADAPTER)\n'
                  '> FCM_SERVICE: ${fcmActive ? 'ACTIVE' : 'STANDBY (PENDING_CONNECT)'}\n'
                  '> NOTIF_CHANNEL: [EMERGENCY_READY] (PERMISSION: ${hasPermission ? 'GRANTED' : 'REQUIRED'})',
            ),
          ],
        );

      case '/users':
        final userLines = ctx.connections
            .map((u) => '  * ${u.handle.padRight(8)} (${u.name.padRight(5)}) [STATUS: ${u.status.label}]')
            .join('\n');

        return CommandExecutionResult(
          logsToAppend: [
            commandLog,
            LogOutput(
              type: LogType.output,
              text: '> CONNECTED PEERS (${ctx.connections.length}):\n$userLines',
            ),
          ],
        );

      case '/clear':
        return const CommandExecutionResult(
          actionType: CommandActionType.clearLogs,
          logsToAppend: [],
        );

      case '/permit':
        final granted = await NotificationService().requestNotificationPermission();
        return CommandExecutionResult(
          logsToAppend: [
            commandLog,
            LogOutput(
              type: granted ? LogType.success : LogType.error,
              text: granted
                  ? '> PERMISSION_GRANTED: Notification and emergency channel active.'
                  : '> PERMISSION_DENIED: Android notification permission was not granted.',
            ),
          ],
        );

      case '/alerts':
      case '/history':
        final history = await AlertService().getAlertHistory();
        if (history.isEmpty) {
          return CommandExecutionResult(
            logsToAppend: [
              commandLog,
              const LogOutput(
                type: LogType.output,
                text: '> ALERT_HISTORY: No alerts recorded yet.',
              ),
            ],
          );
        }

        final alertLines = history.take(8).map((a) {
          final time = '${a.createdAt.hour.toString().padLeft(2, '0')}:${a.createdAt.minute.toString().padLeft(2, '0')}:${a.createdAt.second.toString().padLeft(2, '0')}';
          return '  [${a.priority.label.padRight(9)}] -> ${a.recipientUsername.padRight(8)} '
              'STATUS: ${a.status.label.padRight(9)} TIME: $time ID: ${a.id}';
        }).join('\n');

        return CommandExecutionResult(
          logsToAppend: [
            commandLog,
            LogOutput(
              type: LogType.output,
              text: '> RECENT ALERTS (${history.length}):\n$alertLines',
            ),
          ],
        );

      case '/retry':
        if (rawArgs.isEmpty) {
          return CommandExecutionResult(
            logsToAppend: [
              commandLog,
              const LogOutput(
                type: LogType.error,
                text: '> ERROR: MISSING_ALERT_ID. Usage: /retry <alert_id>',
              ),
            ],
          );
        }

        final targetAlertId = rawArgs[0];
        try {
          final retried = await AlertService().retryAlert(targetAlertId);
          return CommandExecutionResult(
            logsToAppend: [
              commandLog,
              LogOutput(
                type: retried.status == NotiAlertStatus.sent ? LogType.success : LogType.error,
                text: '[RETRY_DISPATCH]\n'
                    'ID: ${retried.id}\n'
                    'TARGET: ${retried.recipientUsername}\n'
                    'PRIORITY: ${retried.priority.label}\n'
                    'STATUS: ${retried.status.label}',
              ),
            ],
          );
        } catch (e) {
          return CommandExecutionResult(
            logsToAppend: [
              commandLog,
              LogOutput(
                type: LogType.error,
                text: '> ERROR: RETRY_FAILED: $e',
              ),
            ],
          );
        }

      case '/send_alert':
        if (rawArgs.isEmpty) {
          return CommandExecutionResult(
            logsToAppend: [
              commandLog,
              const LogOutput(
                type: LogType.error,
                text: '> ERROR: MISSING_TARGET. Usage: /send_alert [--emergency] @username',
              ),
            ],
          );
        }

        // Check for emergency flag (--emergency, -e)
        bool isEmergency = false;
        final cleanArgs = <String>[];
        for (final arg in rawArgs) {
          final lower = arg.toLowerCase();
          if (lower == '--emergency' || lower == '-e' || lower == '-emergency') {
            isEmergency = true;
          } else {
            cleanArgs.add(arg);
          }
        }

        if (cleanArgs.isEmpty) {
          return CommandExecutionResult(
            logsToAppend: [
              commandLog,
              const LogOutput(
                type: LogType.error,
                text: '> ERROR: MISSING_TARGET. Usage: /send_alert [--emergency] @username',
              ),
            ],
          );
        }

        final targetArg = cleanArgs[0];
        final cleanTarget = targetArg.startsWith('@') ? targetArg : '@$targetArg';
        final priority = isEmergency ? NotiAlertPriority.emergency : NotiAlertPriority.normal;

        final matchedIndex = ctx.connections.indexWhere(
          (u) => u.handle.toLowerCase() == cleanTarget.toLowerCase(),
        );

        if (matchedIndex == -1) {
          return CommandExecutionResult(
            logsToAppend: [
              commandLog,
              LogOutput(
                type: LogType.error,
                text: '[ALERT]\n'
                    'TARGET: $cleanTarget\n'
                    'STATUS: FAILED\n'
                    'REASON: UNKNOWN_USER',
              ),
            ],
          );
        }

        final matchedUser = ctx.connections[matchedIndex];

        if (matchedUser.status == ConnectionStatus.offline) {
          return CommandExecutionResult(
            logsToAppend: [
              commandLog,
              LogOutput(
                type: LogType.error,
                text: '[ALERT]\n'
                    'TARGET: ${matchedUser.handle}\n'
                    'PRIORITY: ${priority.label}\n'
                    'STATUS: FAILED\n'
                    'REASON: TARGET_OFFLINE',
              ),
            ],
          );
        }

        if (matchedUser.status == ConnectionStatus.busy) {
          final alertResult = await AlertService().dispatchAlert(
            senderId: 'self',
            senderUsername: '@me',
            recipientId: matchedUser.handle,
            recipientUsername: matchedUser.handle,
            title: 'NOTI ALERT',
            message: 'High priority alert to ${matchedUser.handle}',
            priority: priority,
          );

          return CommandExecutionResult(
            logsToAppend: [
              commandLog,
              LogOutput(
                type: LogType.output,
                text: '[ALERT]\n'
                    'TARGET: ${matchedUser.handle}\n'
                    'PRIORITY: ${priority.label}\n'
                    'STATUS: QUEUED (${alertResult.status.label}_BUSY)',
              ),
            ],
          );
        }

        // Matched user is READY -> dispatch alert & update connection status to BUSY
        final alertResult = await AlertService().dispatchAlert(
          senderId: 'self',
          senderUsername: '@me',
          recipientId: matchedUser.handle,
          recipientUsername: matchedUser.handle,
          title: 'NOTI ALERT',
          message: 'Direct alert signal to ${matchedUser.handle}',
          priority: priority,
        );

        final updated = List<UserConnection>.from(ctx.connections);
        updated[matchedIndex] = matchedUser.copyWith(
          status: ConnectionStatus.busy,
          lastActive: 'NOW',
        );

        return CommandExecutionResult(
          actionType: CommandActionType.updateConnections,
          updatedConnections: updated,
          logsToAppend: [
            commandLog,
            LogOutput(
              type: LogType.success,
              text: '[ALERT]\n'
                  'TARGET: ${matchedUser.handle}\n'
                  'PRIORITY: ${priority.label}\n'
                  'STATUS: ${alertResult.status.label}',
            ),
          ],
        );

      default:
        return CommandExecutionResult(
          logsToAppend: [
            commandLog,
            LogOutput(
              type: LogType.error,
              text: "> ERROR: UNKNOWN_COMMAND: '${parts[0]}'. Type /help for assistance.",
            ),
          ],
        );
    }
  }
}
