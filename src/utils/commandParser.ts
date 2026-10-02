import { CommandContext, CommandExecutionResult } from '../types/terminal';

type CommandHandler = (args: string[], ctx: CommandContext) => CommandExecutionResult;

const handleHelp: CommandHandler = () => ({
  actionType: 'NONE',
  logsToAppend: [
    {
      type: 'output',
      text: `AVAILABLE COMMANDS:\n  /help                 - Show available commands\n  /status               - Show detailed system status\n  /users                - List connected users and status\n  /send_alert @username - Dispatch emergency signal to user\n  /clear                - Clear terminal log output`,
    },
  ],
});

const handleStatus: CommandHandler = (_, ctx) => {
  const ready = ctx.connections.filter((u) => u.status === 'READY').length;
  const busy = ctx.connections.filter((u) => u.status === 'BUSY').length;
  const offline = ctx.connections.filter((u) => u.status === 'OFFLINE').length;

  return {
    actionType: 'NONE',
    logsToAppend: [
      {
        type: 'output',
        text: `> SYS_DIAGNOSTICS: OPTIMAL\n> NETWORK_NODES: ${ctx.connections.length} TOTAL (${ready} READY, ${busy} BUSY, ${offline} OFFLINE)\n> ENCRYPTION: 4096-BIT RSA / ACTIVE\n> NODE_LATENCY: 14ms`,
      },
    ],
  };
};

const handleUsers: CommandHandler = (_, ctx) => {
  const userLines = ctx.connections
    .map((u) => `  * ${u.handle.padEnd(8, ' ')} (${u.name.padEnd(5, ' ')}) [STATUS: ${u.status}]`)
    .join('\n');
  return {
    actionType: 'NONE',
    logsToAppend: [
      {
        type: 'output',
        text: `> CONNECTED PEERS (${ctx.connections.length}):\n${userLines}`,
      },
    ],
  };
};

const handleClear: CommandHandler = () => ({
  actionType: 'CLEAR_LOGS',
  logsToAppend: [],
});

const handleSendAlert: CommandHandler = (args, ctx) => {
  const target = args[0];
  if (!target) {
    return {
      actionType: 'NONE',
      logsToAppend: [
        {
          type: 'error',
          text: `> ERROR: MISSING_TARGET. Usage: /send_alert @username`,
        },
      ],
    };
  }

  const cleanTarget = target.startsWith('@') ? target : `@${target}`;
  const matchedUser = ctx.connections.find(
    (u) => u.handle.toLowerCase() === cleanTarget.toLowerCase()
  );

  if (!matchedUser) {
    return {
      actionType: 'NONE',
      logsToAppend: [
        {
          type: 'error',
          text: `> ERROR: UNKNOWN_USER. Target '${cleanTarget}' is not in connection network.`,
        },
      ],
    };
  }

  if (matchedUser.status === 'OFFLINE') {
    return {
      actionType: 'NONE',
      logsToAppend: [
        {
          type: 'error',
          text: `> ERROR: TARGET_UNREACHABLE. ${matchedUser.handle} (${matchedUser.name}) is currently OFFLINE.`,
        },
      ],
    };
  }

  if (matchedUser.status === 'BUSY') {
    return {
      actionType: 'NONE',
      logsToAppend: [
        {
          type: 'output',
          text: `> ALERT_QUEUED: ${matchedUser.handle} (${matchedUser.name}) is currently BUSY. High-priority signal queued.`,
        },
      ],
    };
  }

  // User is READY -> Dispatch alert & transition state to BUSY
  const updatedConnections = ctx.connections.map((u) =>
    u.id === matchedUser.id ? { ...u, status: 'BUSY' as const, lastActive: 'NOW' } : u
  );

  return {
    actionType: 'UPDATE_CONNECTIONS',
    updatedConnections,
    logsToAppend: [
      {
        type: 'success',
        text: `> ALERT_SENT: Emergency signal dispatched to ${matchedUser.handle} (${matchedUser.name}). Status updated: [BUSY].`,
      },
    ],
  };
};

// Pure Command Registry Map
const COMMAND_REGISTRY: Record<string, CommandHandler> = {
  '/help': handleHelp,
  '/status': handleStatus,
  '/users': handleUsers,
  '/clear': handleClear,
  '/send_alert': handleSendAlert,
};

export function parseAndExecuteCommand(
  rawInput: string,
  ctx: CommandContext
): CommandExecutionResult {
  const trimmed = rawInput.trim();
  if (!trimmed) {
    return { actionType: 'NONE', logsToAppend: [] };
  }

  const parts = trimmed.split(/\s+/);
  const commandName = parts[0].toLowerCase();
  const args = parts.slice(1);

  const commandLog = {
    type: 'command' as const,
    text: `~$ ${trimmed}`,
  };

  const handler = COMMAND_REGISTRY[commandName];

  if (!handler) {
    return {
      actionType: 'NONE',
      logsToAppend: [
        commandLog,
        {
          type: 'error',
          text: `> ERROR: UNKNOWN_COMMAND: '${parts[0]}'. Type /help for assistance.`,
        },
      ],
    };
  }

  const result = handler(args, ctx);

  if (result.actionType === 'CLEAR_LOGS') {
    return result;
  }

  return {
    ...result,
    logsToAppend: [commandLog, ...result.logsToAppend],
  };
}
