import 'package:flutter_test/flutter_test.dart';
import 'package:noti_mobile/models/user_connection.dart';
import 'package:noti_mobile/models/terminal_log.dart';
import 'package:noti_mobile/utils/command_parser.dart';

void main() {
  group('CommandParser Tests', () {
    final List<UserConnection> testConnections = [
      const UserConnection(id: '1', handle: '@ceviz', name: 'CEVIZ', status: ConnectionStatus.ready),
      const UserConnection(id: '2', handle: '@pasa', name: 'PASA', status: ConnectionStatus.busy),
      const UserConnection(id: '3', handle: '@racc', name: 'RACC', status: ConnectionStatus.offline),
    ];

    late CommandContext ctx;

    setUp(() {
      ctx = CommandContext(connections: testConnections);
    });

    test('/help returns available command list', () async {
      final res = await CommandParser.parseAndExecute('/help', ctx);
      expect(res.logsToAppend.length, 2);
      expect(res.logsToAppend[1].text, contains('AVAILABLE COMMANDS:'));
      expect(res.logsToAppend[1].text, contains('/send_alert'));
    });

    test('/status returns system status information', () async {
      final res = await CommandParser.parseAndExecute('/status', ctx);
      expect(res.logsToAppend.length, 2);
      expect(res.logsToAppend[1].text, contains('SYS_DIAGNOSTICS: OPTIMAL'));
      expect(res.logsToAppend[1].text, contains('NETWORK_NODES: 3 TOTAL'));
    });

    test('/users returns peer list with statuses', () async {
      final res = await CommandParser.parseAndExecute('/users', ctx);
      expect(res.logsToAppend.length, 2);
      expect(res.logsToAppend[1].text, contains('@ceviz'));
      expect(res.logsToAppend[1].text, contains('@pasa'));
      expect(res.logsToAppend[1].text, contains('@racc'));
    });

    test('/clear returns clearLogs action type', () async {
      final res = await CommandParser.parseAndExecute('/clear', ctx);
      expect(res.actionType, CommandActionType.clearLogs);
      expect(res.logsToAppend.isEmpty, true);
    });

    test('/alerts returns history output', () async {
      final res = await CommandParser.parseAndExecute('/alerts', ctx);
      expect(res.logsToAppend.length, 2);
      expect(res.logsToAppend[1].type, LogType.output);
    });

    test('/send_alert without arguments produces MISSING_TARGET error', () async {
      final res = await CommandParser.parseAndExecute('/send_alert', ctx);
      expect(res.logsToAppend[1].type, LogType.error);
      expect(res.logsToAppend[1].text, contains('MISSING_TARGET'));
    });

    test('/send_alert with unknown user produces UNKNOWN_USER error', () async {
      final res = await CommandParser.parseAndExecute('/send_alert @unknown', ctx);
      expect(res.logsToAppend[1].type, LogType.error);
      expect(res.logsToAppend[1].text, contains('UNKNOWN_USER'));
    });

    test('/send_alert with offline user produces TARGET_OFFLINE error', () async {
      final res = await CommandParser.parseAndExecute('/send_alert @racc', ctx);
      expect(res.logsToAppend[1].type, LogType.error);
      expect(res.logsToAppend[1].text, contains('TARGET_OFFLINE'));
    });

    test('/send_alert with busy user queues the alert', () async {
      final res = await CommandParser.parseAndExecute('/send_alert @pasa', ctx);
      expect(res.logsToAppend[1].text, contains('STATUS: QUEUED'));
    });

    test('/send_alert with ready user dispatches alert and marks user busy', () async {
      final res = await CommandParser.parseAndExecute('/send_alert @ceviz', ctx);
      expect(res.actionType, CommandActionType.updateConnections);
      expect(res.updatedConnections != null, true);
      expect(res.updatedConnections!.firstWhere((u) => u.handle == '@ceviz').status, ConnectionStatus.busy);
      expect(res.logsToAppend[1].type, LogType.success);
      expect(res.logsToAppend[1].text, contains('PRIORITY: NORMAL'));
    });

    test('/send_alert --emergency flag sets priority to EMERGENCY', () async {
      final res = await CommandParser.parseAndExecute('/send_alert --emergency @ceviz', ctx);
      expect(res.logsToAppend[1].text, contains('PRIORITY: EMERGENCY'));
    });

    test('unknown command produces UNKNOWN_COMMAND error', () async {
      final res = await CommandParser.parseAndExecute('/invalid_cmd', ctx);
      expect(res.logsToAppend[1].type, LogType.error);
      expect(res.logsToAppend[1].text, contains('UNKNOWN_COMMAND'));
    });
  });
}
