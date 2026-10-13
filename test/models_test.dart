import 'package:flutter_test/flutter_test.dart';
import 'package:noti_mobile/models/noti_alert.dart';
import 'package:noti_mobile/models/noti_user.dart';

void main() {
  group('NotiAlert Model Tests', () {
    test('serialization and deserialization with JSON', () {
      final now = DateTime.now();
      final alert = NotiAlert(
        id: 'test_alert_1',
        senderId: 'user_1',
        senderUsername: '@sender',
        recipientId: 'user_2',
        recipientUsername: '@recipient',
        title: 'Emergency',
        message: 'Critical system notice',
        createdAt: now,
        priority: NotiAlertPriority.emergency,
        status: NotiAlertStatus.sent,
        failureReason: null,
      );

      final json = alert.toJson();
      expect(json['id'], 'test_alert_1');
      expect(json['priority'], 'emergency');
      expect(json['status'], 'sent');

      final deserialized = NotiAlert.fromJson(json);
      expect(deserialized.id, alert.id);
      expect(deserialized.senderUsername, '@sender');
      expect(deserialized.priority, NotiAlertPriority.emergency);
      expect(deserialized.status, NotiAlertStatus.sent);
    });

    test('priority and status labels', () {
      expect(NotiAlertPriority.normal.label, 'NORMAL');
      expect(NotiAlertPriority.emergency.label, 'EMERGENCY');

      expect(NotiAlertStatus.pending.label, 'PENDING');
      expect(NotiAlertStatus.sent.label, 'SENT');
      expect(NotiAlertStatus.delivered.label, 'DELIVERED');
      expect(NotiAlertStatus.failed.label, 'FAILED');
    });

    test('copyWith works correctly', () {
      final alert = NotiAlert(
        id: 'id_1',
        senderId: 's1',
        senderUsername: '@s1',
        recipientId: 'r1',
        recipientUsername: '@r1',
        title: 'Title',
        message: 'Msg',
        createdAt: DateTime.now(),
        priority: NotiAlertPriority.normal,
        status: NotiAlertStatus.pending,
      );

      final updated = alert.copyWith(
        status: NotiAlertStatus.delivered,
        failureReason: 'None',
      );

      expect(updated.status, NotiAlertStatus.delivered);
      expect(updated.failureReason, 'None');
      expect(updated.id, 'id_1');
    });
  });

  group('NotiUser Model Tests', () {
    test('serialization and deserialization', () {
      const user = NotiUser(
        id: 'u1',
        username: '@ceviz',
        displayName: 'Ceviz',
        fcmToken: 'token_123',
        isOnline: true,
      );

      final json = user.toJson();
      expect(json['username'], '@ceviz');
      expect(json['fcmToken'], 'token_123');

      final deserialized = NotiUser.fromJson(json);
      expect(deserialized.id, 'u1');
      expect(deserialized.isOnline, true);
    });
  });
}
