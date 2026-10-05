enum NotiAlertPriority {
  normal,
  emergency;

  String get label {
    switch (this) {
      case NotiAlertPriority.normal:
        return 'NORMAL';
      case NotiAlertPriority.emergency:
        return 'EMERGENCY';
    }
  }
}

enum NotiAlertStatus {
  pending,
  sent,
  delivered,
  failed;

  String get label {
    switch (this) {
      case NotiAlertStatus.pending:
        return 'PENDING';
      case NotiAlertStatus.sent:
        return 'SENT';
      case NotiAlertStatus.delivered:
        return 'DELIVERED';
      case NotiAlertStatus.failed:
        return 'FAILED';
    }
  }
}

class NotiAlert {
  final String id;
  final String senderId;
  final String senderUsername;
  final String recipientId;
  final String recipientUsername;
  final String title;
  final String message;
  final DateTime createdAt;
  final NotiAlertPriority priority;
  final NotiAlertStatus status;
  final String? failureReason;

  const NotiAlert({
    required this.id,
    required this.senderId,
    required this.senderUsername,
    required this.recipientId,
    required this.recipientUsername,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.priority,
    required this.status,
    this.failureReason,
  });

  NotiAlert copyWith({
    String? id,
    String? senderId,
    String? senderUsername,
    String? recipientId,
    String? recipientUsername,
    String? title,
    String? message,
    DateTime? createdAt,
    NotiAlertPriority? priority,
    NotiAlertStatus? status,
    String? failureReason,
  }) {
    return NotiAlert(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderUsername: senderUsername ?? this.senderUsername,
      recipientId: recipientId ?? this.recipientId,
      recipientUsername: recipientUsername ?? this.recipientUsername,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      failureReason: failureReason ?? this.failureReason,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderId': senderId,
        'senderUsername': senderUsername,
        'recipientId': recipientId,
        'recipientUsername': recipientUsername,
        'title': title,
        'message': message,
        'createdAt': createdAt.toIso8601String(),
        'priority': priority.name,
        'status': status.name,
        'failureReason': failureReason,
      };

  factory NotiAlert.fromJson(Map<String, dynamic> json) => NotiAlert(
        id: json['id'] as String,
        senderId: json['senderId'] as String,
        senderUsername: json['senderUsername'] as String,
        recipientId: json['recipientId'] as String,
        recipientUsername: json['recipientUsername'] as String,
        title: json['title'] as String,
        message: json['message'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        priority: NotiAlertPriority.values.byName(json['priority'] as String),
        status: NotiAlertStatus.values.byName(json['status'] as String),
        failureReason: json['failureReason'] as String?,
      );
}
