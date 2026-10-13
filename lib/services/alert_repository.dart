import '../models/noti_alert.dart';

abstract class AlertRepository {
  Future<NotiAlert> sendAlert(NotiAlert alert);
  Future<NotiAlert?> receiveAlert(String alertId);
  Future<NotiAlert> markDelivered(String alertId);
  Future<NotiAlert> markFailed(String alertId, String reason);
  Future<List<NotiAlert>> getHistory();
  Future<NotiAlert> retryAlert(String alertId);
}
