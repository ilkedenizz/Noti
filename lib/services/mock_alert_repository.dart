import 'dart:async';
import '../models/noti_alert.dart';
import 'alert_repository.dart';

class MockAlertRepository implements AlertRepository {
  final Map<String, NotiAlert> _alerts = {};

  @override
  Future<NotiAlert> sendAlert(NotiAlert alert) async {
    // Simulate short async network layer operation
    await Future.delayed(const Duration(milliseconds: 30));
    final sentAlert = alert.copyWith(status: NotiAlertStatus.sent);
    _alerts[sentAlert.id] = sentAlert;
    return sentAlert;
  }

  @override
  Future<NotiAlert?> receiveAlert(String alertId) async {
    return _alerts[alertId];
  }

  @override
  Future<NotiAlert> markDelivered(String alertId) async {
    final alert = _alerts[alertId];
    if (alert == null) {
      throw Exception('Alert $alertId not found');
    }
    final updated = alert.copyWith(status: NotiAlertStatus.delivered);
    _alerts[alertId] = updated;
    return updated;
  }

  @override
  Future<NotiAlert> markFailed(String alertId, String reason) async {
    final alert = _alerts[alertId];
    if (alert == null) {
      throw Exception('Alert $alertId not found');
    }
    final updated = alert.copyWith(
      status: NotiAlertStatus.failed,
      failureReason: reason,
    );
    _alerts[alertId] = updated;
    return updated;
  }
}
