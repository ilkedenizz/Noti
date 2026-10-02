import React, { useState } from 'react';
import { StatusBar } from './components/StatusBar';
import { TerminalHeader } from './components/TerminalHeader';
import { SystemStatus } from './components/SystemStatus';
import { ConnectionList } from './components/ConnectionList';
import { CommandTerminal } from './components/CommandTerminal';
import { UserConnection } from './types/terminal';
import { loadConnections, saveConnections } from './utils/connectionStorage';

export const App: React.FC = () => {
  const [connections, setConnections] = useState<UserConnection[]>(() => loadConnections());
  const [externalCommand, setExternalCommand] = useState<string | null>(null);

  const handleCallUser = (handle: string) => {
    setExternalCommand(`/send_alert ${handle}`);
  };

  const handleClearExternalCommand = () => {
    setExternalCommand(null);
  };

  const handleUpdateConnections = (updatedConnections: UserConnection[]) => {
    setConnections(updatedConnections);
    saveConnections(updatedConnections);
  };

  return (
    <main className="w-full h-dvh bg-black flex items-center justify-center p-0 md:p-6 overflow-hidden select-none antialiased">
      {/* 
        Desktop view container mimicking a high-end minimalist terminal frame.
        Mobile view takes full screen (100dvh).
      */}
      <div className="w-full h-full md:max-w-lg md:h-[840px] md:max-h-[92vh] bg-black border-0 md:border md:border-[#262626] md:rounded-xl flex flex-col shadow-[0_0_60px_rgba(0,0,0,0.9)] relative overflow-hidden">
        {/* Top Status Bar */}
        <StatusBar />

        {/* Scrollable Container / Terminal Content */}
        <div className="flex-1 flex flex-col min-h-0 pt-safe pb-safe">
          {/* Header section */}
          <TerminalHeader />

          {/* System info */}
          <SystemStatus totalConnections={connections.length} />

          {/* Connection List */}
          <ConnectionList
            connections={connections}
            onCallUser={handleCallUser}
          />

          {/* Interactive Command Terminal */}
          <CommandTerminal
            connections={connections}
            onUpdateConnections={handleUpdateConnections}
            externalCommand={externalCommand}
            onClearExternalCommand={handleClearExternalCommand}
          />
        </div>
      </div>
    </main>
  );
};

export default App;
