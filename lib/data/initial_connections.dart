import '../models/user_connection.dart';

const List<UserConnection> initialConnections = [
  UserConnection(
    id: '1',
    handle: '@ceviz',
    name: 'Ceviz',
    status: ConnectionStatus.ready,
    lastActive: 'NOW',
  ),
  UserConnection(
    id: '2',
    handle: '@pasa',
    name: 'Pasa',
    status: ConnectionStatus.busy,
    lastActive: '2m ago',
  ),
  UserConnection(
    id: '3',
    handle: '@racc',
    name: 'Racc',
    status: ConnectionStatus.offline,
    lastActive: '1h ago',
  ),
];
