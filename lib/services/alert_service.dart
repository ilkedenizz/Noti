import '../models/noti_alert.dart';
import 'alert_repository.dart';
import 'mock_alert_repository.dart';
import 'notification_service.dart';

class AlertService {
  static final AlertService _instance = AlertService._internal();

  factory AlertService() => _instance;

  AlertService._internal();

  AlertRepository _repository = MockAlertRepository();

  /// Inject or replace the alert repository (e.g. FirebaseAlertRepository for production)
  void setRepository(AlertRepository repository) {
    _repository = repository;
  }

  AlertRepository get repository => _repository;

  Future<NotiAlert> dispatchAlert({
    required String senderId,
    required String senderUsername,
    required String recipientId,
    required String recipientUsername,
    required String title,
    required String message,
    NotiAlertPriority priority = NotiAlertPriority.normal,
  }) async {
    final id = 'alert_${DateTime.now().millisecondsSinceEpoch}';
    final initialAlert = NotiAlert(
      id: id,
      senderId: senderId,
      senderUsername: senderUsername,
      recipientId: recipientId,
      recipientUsername: recipientUsername,
      title: title,
      message: message,
      createdAt: DateTime.now(),
      priority: priority,
      status: NotiAlertStatus.pending,
    );

    try {
      final sentAlert = await _repository.sendAlert(initialAlert);

      // Notify local listeners & trigger notification channel
      await NotificationService().showLocalAlert(sentAlert);

      return sentAlert;
    } catch (e) {
      final reason = e.toString();
      final failedAlert = initialAlert.copyWith(
        status: NotiAlertStatus.failed,
        failureReason: reason,
      );
      try {
        await _repository.markFailed(id, reason);
      } catch (_) {}
      return failedAlert;
    }
  }

  Future<List<NotiAlert>> getAlertHistory() async {
    return _repository.getHistory();
  }

  Future<NotiAlert> retryAlert(String alertId) async {
    final retried = await _repository.retryAlert(alertId);
    if (retried.status == NotiAlertStatus.sent) {
      await NotificationService().showLocalAlert(retried);
    }
    return retried;
  }
}
