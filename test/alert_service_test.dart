import 'package:flutter_test/flutter_test.dart';
import 'package:noti_mobile/models/noti_alert.dart';
import 'package:noti_mobile/services/alert_service.dart';
import 'package:noti_mobile/services/mock_alert_repository.dart';

void main() {
  group('AlertService & MockAlertRepository Tests', () {
    late AlertService alertService;
    late MockAlertRepository mockRepository;

    setUp(() {
      alertService = AlertService();
      mockRepository = MockAlertRepository();
      alertService.setRepository(mockRepository);
    });

    test('dispatchAlert sends alert successfully', () async {
      final alert = await alertService.dispatchAlert(
        senderId: 'user_1',
        senderUsername: '@hocam',
        recipientId: '@ceviz',
        recipientUsername: '@ceviz',
        title: 'TEST_ALERT',
        message: 'Hello test',
        priority: NotiAlertPriority.emergency,
      );

      expect(alert.status, NotiAlertStatus.sent);
      expect(alert.priority, NotiAlertPriority.emergency);
      expect(alert.recipientUsername, '@ceviz');

      final history = await alertService.getAlertHistory();
      expect(history.length, 1);
      expect(history.first.id, alert.id);
    });

    test('retryAlert re-dispatches existing alert', () async {
      final alert = await alertService.dispatchAlert(
        senderId: 'user_1',
        senderUsername: '@hocam',
        recipientId: '@pasa',
        recipientUsername: '@pasa',
        title: 'ALERT_2',
        message: 'Hello retry',
        priority: NotiAlertPriority.normal,
      );

      final retried = await alertService.retryAlert(alert.id);
      expect(retried.status, NotiAlertStatus.sent);
      expect(retried.id, alert.id);
    });
  });
}
