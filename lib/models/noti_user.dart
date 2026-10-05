class NotiUser {
  final String id;
  final String username;
  final String displayName;
  final String? fcmToken;
  final bool isOnline;

  const NotiUser({
    required this.id,
    required this.username,
    required this.displayName,
    this.fcmToken,
    required this.isOnline,
  });

  NotiUser copyWith({
    String? id,
    String? username,
    String? displayName,
    String? fcmToken,
    bool? isOnline,
  }) {
    return NotiUser(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      fcmToken: fcmToken ?? this.fcmToken,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'displayName': displayName,
        'fcmToken': fcmToken,
        'isOnline': isOnline,
      };

  factory NotiUser.fromJson(Map<String, dynamic> json) => NotiUser(
        id: json['id'] as String,
        username: json['username'] as String,
        displayName: json['displayName'] as String,
        fcmToken: json['fcmToken'] as String?,
        isOnline: json['isOnline'] as bool,
      );
}
