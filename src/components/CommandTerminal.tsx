import React, { useState, useRef, useEffect, useCallback, FormEvent, KeyboardEvent } from 'react';
import { TerminalLogItem, UserConnection } from '../types/terminal';
import { parseAndExecuteCommand } from '../utils/commandParser';

interface CommandTerminalProps {
  connections: UserConnection[];
  onUpdateConnections: (updatedConnections: UserConnection[]) => void;
  externalCommand?: string | null;
  onClearExternalCommand?: () => void;
}

export const CommandTerminal: React.FC<CommandTerminalProps> = ({
  connections,
  onUpdateConnections,
  externalCommand,
  onClearExternalCommand,
}) => {
  const [inputVal, setInputVal] = useState<string>('');
  const [draftInput, setDraftInput] = useState<string>('');
  const [history, setHistory] = useState<string[]>([]);
  const [historyIdx, setHistoryIdx] = useState<number>(-1);

  const [logs, setLogs] = useState<TerminalLogItem[]>([
    {
      id: 'init-1',
      type: 'system',
      text: 'NOTI OS v0.1 initialized.',
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
    },
    {
      id: 'init-2',
      type: 'system',
      text: 'Type /help to view available terminal commands.',
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
    },
  ]);

  const inputRef = useRef<HTMLInputElement>(null);
  const logsEndRef = useRef<HTMLDivElement>(null);

  const scrollToBottom = useCallback(() => {
    logsEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, []);

  // Auto-scroll to bottom of logs on new entry
  useEffect(() => {
    scrollToBottom();
  }, [logs, scrollToBottom]);

  // Execute command centrally
  const dispatchCommand = useCallback(
    (rawCmd: string) => {
      const result = parseAndExecuteCommand(rawCmd, { connections });

      if (result.action === 'clear') {
        setLogs([]);
        return;
      }

      if (result.updatedConnections) {
        onUpdateConnections(result.updatedConnections);
      }

      if (result.logsToAppend.length > 0) {
        const formattedLogs: TerminalLogItem[] = result.logsToAppend.map((log, index) => ({
          id: (Date.now() + index).toString() + Math.random().toString(36).substring(2, 5),
          type: log.type,
          text: log.text,
          timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
        }));

        setLogs((prev) => [...prev, ...formattedLogs]);
      }
    },
    [connections, onUpdateConnections]
  );

  // Handle external command execution (e.g. clicking [CALL] on user)
  useEffect(() => {
    if (!externalCommand) return;
    const trimmed = externalCommand.trim();
    if (trimmed) {
      setHistory((prev) => [...prev, trimmed]);
      setHistoryIdx(-1);
      dispatchCommand(trimmed);
    }
    onClearExternalCommand?.();
  }, [externalCommand, dispatchCommand, onClearExternalCommand]);

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault();
    const trimmed = inputVal.trim();
    if (!trimmed) return;

    setHistory((prev) => [...prev, trimmed]);
    setHistoryIdx(-1);
    setDraftInput('');
    dispatchCommand(trimmed);
    setInputVal('');
  };

  const handleKeyDown = (e: KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'ArrowUp') {
      e.preventDefault();
      if (history.length === 0) return;

      if (historyIdx === -1) {
        setDraftInput(inputVal);
      }

      const nextIdx = historyIdx < history.length - 1 ? historyIdx + 1 : historyIdx;
      setHistoryIdx(nextIdx);
      setInputVal(history[history.length - 1 - nextIdx] || '');
    } else if (e.key === 'ArrowDown') {
      e.preventDefault();
      if (historyIdx > 0) {
        const nextIdx = historyIdx - 1;
        setHistoryIdx(nextIdx);
        setInputVal(history[history.length - 1 - nextIdx] || '');
      } else if (historyIdx === 0) {
        setHistoryIdx(-1);
        setInputVal(draftInput);
      }
    }
  };

  const handleInputFocus = () => {
    setTimeout(scrollToBottom, 150);
  };

  const handleContainerClick = () => {
    inputRef.current?.focus();
  };

  return (
    <div
      onClick={handleContainerClick}
      className="flex-1 flex flex-col font-mono text-xs min-h-0 px-4 select-text cursor-text"
    >
      <div className="border-b border-[#262626] w-full my-2 shrink-0" aria-hidden="true" />

      <div className="text-[#737373] mb-2 select-none flex items-center space-x-1 shrink-0">
        <span className="text-[#525252] font-semibold">&gt;</span>
        <span className="text-[#a3a3a3]">WAITING_FOR_COMMAND....</span>
      </div>

      {/* Scrollable Log Output */}
      <div className="flex-1 overflow-y-auto space-y-2 pr-1 pb-2 scroll-smooth">
        {logs.map((log) => (
          <div key={log.id} className="whitespace-pre-wrap leading-relaxed">
            {log.type === 'command' && (
              <span className="text-white font-medium">{log.text}</span>
            )}
            {log.type === 'system' && (
              <span className="text-[#a3a3a3]">{log.text}</span>
            )}
            {log.type === 'output' && (
              <span className="text-[#d4d4d4]">{log.text}</span>
            )}
            {log.type === 'error' && (
              <span className="text-[#ef4444] font-semibold">{log.text}</span>
            )}
            {log.type === 'success' && (
              <span className="text-[#22c55e] font-semibold">{log.text}</span>
            )}
          </div>
        ))}
        <div ref={logsEndRef} />
      </div>

      {/* Command Input Form */}
      <form onSubmit={handleSubmit} className="py-3 mt-auto border-t border-[#171717] bg-black shrink-0">
        <label htmlFor="terminal-command-input" className="sr-only">
          Terminal Command Input
        </label>
        <div className="flex items-center text-xs font-mono text-white">
          <span className="text-[#737373] mr-1.5 select-none font-semibold">~$</span>
          
          <div className="relative flex-1 flex items-center">
            <input
              id="terminal-command-input"
              ref={inputRef}
              type="text"
              value={inputVal}
              onChange={(e) => setInputVal(e.target.value)}
              onKeyDown={handleKeyDown}
              onFocus={handleInputFocus}
              placeholder="/send_alert @ceviz"
              spellCheck={false}
              autoComplete="off"
              autoCapitalize="off"
              className="w-full bg-transparent text-white focus:outline-none font-mono text-xs placeholder:text-[#404040] caret-white"
            />
          </div>
        </div>
      </form>
    </div>
  );
};
