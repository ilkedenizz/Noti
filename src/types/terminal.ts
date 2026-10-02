export type ConnectionStatus = 'READY' | 'BUSY' | 'OFFLINE';

export interface UserConnection {
  id: string;
  handle: string;
  name: string;
  status: ConnectionStatus;
  lastActive?: string;
}

export type LogType = 'system' | 'command' | 'output' | 'error' | 'success';

export interface TerminalLogItem {
  id: string;
  type: LogType;
  text: string;
  timestamp: string;
}

export interface CommandContext {
  connections: UserConnection[];
}

export interface LogOutput {
  type: LogType;
  text: string;
}

export type CommandActionType = 'NONE' | 'CLEAR_LOGS' | 'UPDATE_CONNECTIONS';

export interface CommandExecutionResult {
  actionType: CommandActionType;
  updatedConnections?: UserConnection[];
  logsToAppend: LogOutput[];
}
