enum ConnectionStatus {
  ready,
  busy,
  offline;

  String get label {
    switch (this) {
      case ConnectionStatus.ready:
        return 'READY';
      case ConnectionStatus.busy:
        return 'BUSY';
      case ConnectionStatus.offline:
        return 'OFFLINE';
    }
  }
}

class UserConnection {
  final String id;
  final String handle;
  final String name;
  final ConnectionStatus status;
  final String? lastActive;

  const UserConnection({
    required this.id,
    required this.handle,
    required this.name,
    required this.status,
    this.lastActive,
  });

  UserConnection copyWith({
    String? id,
    String? handle,
    String? name,
    ConnectionStatus? status,
    String? lastActive,
  }) {
    return UserConnection(
      id: id ?? this.id,
      handle: handle ?? this.handle,
      name: name ?? this.name,
      status: status ?? this.status,
      lastActive: lastActive ?? this.lastActive,
    );
  }
}
