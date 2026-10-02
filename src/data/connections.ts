import { UserConnection } from '../types/terminal';

export const INITIAL_CONNECTIONS: UserConnection[] = [
  {
    id: '1',
    handle: '@ceviz',
    name: 'Ceviz',
    status: 'READY',
    lastActive: 'NOW',
  },
  {
    id: '2',
    handle: '@pasa',
    name: 'Pasa',
    status: 'BUSY',
    lastActive: '2m ago',
  },
  {
    id: '3',
    handle: '@racc',
    name: 'Racc',
    status: 'OFFLINE',
    lastActive: '1h ago',
  },
];
