import 'dart:convert';
import 'dart:io';
import '../models/noti_alert.dart';
import 'alert_repository.dart';

/// Firebase Cloud Functions implementation of AlertRepository.
/// Interacts with the `sendNotiAlert` Cloud Function backend.
class FirebaseAlertRepository implements AlertRepository {
  final String functionsBaseUrl;

  FirebaseAlertRepository({
    required this.functionsBaseUrl,
  });

  @override
  Future<NotiAlert> sendAlert(NotiAlert alert) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$functionsBaseUrl/sendNotiAlert');
      final request = await client.postUrl(uri);
      
      request.headers.contentType = ContentType.json;

      final payload = {
        'recipientToken': 'MOCK_RECIPIENT_FCM_TOKEN', // Fetched from user directory in production
        'alertId': alert.id,
        'senderId': alert.senderId,
        'senderUsername': alert.senderUsername,
        'recipientId': alert.recipientId,
        'recipientUsername': alert.recipientUsername,
        'title': alert.title,
        'message': alert.message,
        'priority': alert.priority.label,
        'createdAt': alert.createdAt.toIso8601String(),
      };

      request.write(jsonEncode(payload));
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final json = jsonDecode(responseBody);
        if (json['success'] == true) {
          return alert.copyWith(status: NotiAlertStatus.sent);
        }
      }

      return alert.copyWith(
        status: NotiAlertStatus.failed,
        failureReason: 'HTTP_${response.statusCode}: $responseBody',
      );
    } catch (e) {
      return alert.copyWith(
        status: NotiAlertStatus.failed,
        failureReason: e.toString(),
      );
    } finally {
      client.close();
    }
  }

  @override
  Future<NotiAlert?> receiveAlert(String alertId) async {
    return null;
  }

  @override
  Future<NotiAlert> markDelivered(String alertId) async {
    return NotiAlert(
      id: alertId,
      senderId: 'unknown',
      senderUsername: '@unknown',
      recipientId: 'self',
      recipientUsername: '@me',
      title: 'Delivered',
      message: 'Delivered',
      createdAt: DateTime.now(),
      priority: NotiAlertPriority.normal,
      status: NotiAlertStatus.delivered,
    );
  }

  @override
  Future<NotiAlert> markFailed(String alertId, String reason) async {
    return NotiAlert(
      id: alertId,
      senderId: 'unknown',
      senderUsername: '@unknown',
      recipientId: 'self',
      recipientUsername: '@me',
      title: 'Failed',
      message: reason,
      createdAt: DateTime.now(),
      priority: NotiAlertPriority.normal,
      status: NotiAlertStatus.failed,
      failureReason: reason,
    );
  }
}
