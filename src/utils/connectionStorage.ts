import { UserConnection, ConnectionStatus } from '../types/terminal';
import { INITIAL_CONNECTIONS } from '../data/connections';

const STORAGE_KEY = 'noti_connection_state_v1';

const VALID_STATUSES: Set<ConnectionStatus> = new Set(['READY', 'BUSY', 'OFFLINE']);

/**
 * Type guard to safely validate a UserConnection object retrieved from storage.
 */
function isValidUserConnection(item: unknown): item is UserConnection {
  if (typeof item !== 'object' || item === null) return false;

  const obj = item as Record<string, unknown>;

  return (
    typeof obj.id === 'string' &&
    typeof obj.handle === 'string' &&
    typeof obj.name === 'string' &&
    typeof obj.status === 'string' &&
    VALID_STATUSES.has(obj.status as ConnectionStatus) &&
    (obj.lastActive === undefined || typeof obj.lastActive === 'string')
  );
}

/**
 * Safely loads connection state from browser localStorage.
 * Falls back to INITIAL_CONNECTIONS if data is missing, corrupted, or invalid.
 */
export function loadConnections(): UserConnection[] {
  try {
    const rawData = localStorage.getItem(STORAGE_KEY);
    if (!rawData) {
      return INITIAL_CONNECTIONS;
    }

    const parsed: unknown = JSON.parse(rawData);

    if (!Array.isArray(parsed) || parsed.length === 0) {
      return INITIAL_CONNECTIONS;
    }

    const validConnections: UserConnection[] = [];
    for (const item of parsed) {
      if (isValidUserConnection(item)) {
        validConnections.push(item);
      }
    }

    if (validConnections.length === 0) {
      return INITIAL_CONNECTIONS;
    }

    return validConnections;
  } catch {
    return INITIAL_CONNECTIONS;
  }
}

/**
 * Saves current connection state to browser localStorage.
 */
export function saveConnections(connections: UserConnection[]): void {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(connections));
  } catch {
    // Handle storage quota or access restriction gracefully
  }
}

/**
 * Helper to reset stored connections state back to initial defaults.
 */
export function clearConnectionsStorage(): void {
  try {
    localStorage.removeItem(STORAGE_KEY);
  } catch {
    // Handle storage access restriction gracefully
  }
}
