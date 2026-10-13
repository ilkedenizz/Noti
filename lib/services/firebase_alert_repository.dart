import 'dart:convert';
import 'dart:io';
import '../models/noti_alert.dart';
import 'alert_repository.dart';

/// Firebase Cloud Functions implementation of AlertRepository.
/// Interacts with the `sendNotiAlert` Cloud Function backend.
class FirebaseAlertRepository implements AlertRepository {
  final String functionsBaseUrl;
  final Duration timeout;
  final int maxRetries;
  final Map<String, NotiAlert> _localCache = {};

  FirebaseAlertRepository({
    required this.functionsBaseUrl,
    this.timeout = const Duration(seconds: 10),
    this.maxRetries = 2,
  });

  @override
  Future<NotiAlert> sendAlert(NotiAlert alert) async {
    _localCache[alert.id] = alert;
    int attempt = 0;
    String? lastError;

    while (attempt <= maxRetries) {
      attempt++;
      final client = HttpClient();
      client.connectionTimeout = timeout;

      try {
        final uri = Uri.parse('$functionsBaseUrl/sendNotiAlert');
        final request = await client.postUrl(uri).timeout(timeout);

        request.headers.contentType = ContentType.json;

        final payload = {
          'recipientToken': 'MOCK_RECIPIENT_FCM_TOKEN',
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
        final response = await request.close().timeout(timeout);
        final responseBody = await response.transform(utf8.decoder).join();

        if (response.statusCode == 200) {
          final json = jsonDecode(responseBody) as Map<String, dynamic>;
          if (json['success'] == true) {
            final sent = alert.copyWith(
              status: NotiAlertStatus.sent,
              failureReason: null,
            );
            _localCache[alert.id] = sent;
            return sent;
          }
        }

        lastError = 'HTTP_${response.statusCode}: $responseBody';
      } catch (e) {
        lastError = e.toString();
        if (attempt <= maxRetries) {
          await Future.delayed(Duration(milliseconds: 300 * attempt));
        }
      } finally {
        client.close();
      }
    }

    final failed = alert.copyWith(
      status: NotiAlertStatus.failed,
      failureReason: lastError ?? 'Unknown network failure',
    );
    _localCache[alert.id] = failed;
    return failed;
  }

  @override
  Future<NotiAlert?> receiveAlert(String alertId) async {
    return _localCache[alertId];
  }

  @override
  Future<NotiAlert> markDelivered(String alertId) async {
    final alert = _localCache[alertId];
    if (alert != null) {
      final delivered = alert.copyWith(status: NotiAlertStatus.delivered);
      _localCache[alertId] = delivered;
      return delivered;
    }
    final placeholder = NotiAlert(
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
    _localCache[alertId] = placeholder;
    return placeholder;
  }

  @override
  Future<NotiAlert> markFailed(String alertId, String reason) async {
    final alert = _localCache[alertId];
    if (alert != null) {
      final failed = alert.copyWith(
        status: NotiAlertStatus.failed,
        failureReason: reason,
      );
      _localCache[alertId] = failed;
      return failed;
    }
    final placeholder = NotiAlert(
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
    _localCache[alertId] = placeholder;
    return placeholder;
  }

  @override
  Future<List<NotiAlert>> getHistory() async {
    return _localCache.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<NotiAlert> retryAlert(String alertId) async {
    final existing = _localCache[alertId];
    if (existing == null) {
      throw Exception('Alert $alertId not found in repository cache');
    }
    final refreshed = existing.copyWith(
      createdAt: DateTime.now(),
      status: NotiAlertStatus.pending,
      failureReason: null,
    );
    return sendAlert(refreshed);
  }
}
