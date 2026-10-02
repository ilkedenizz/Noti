import React from 'react';

export const TerminalHeader: React.FC = () => {
  return (
    <div className="px-4 pt-3 pb-1 font-mono text-xs select-none shrink-0">
      <div className="flex items-center justify-between text-[#e5e5e5] font-semibold tracking-tight">
        <span className="text-white tracking-wide">[TERMINAL.EXE] EMER_SIGNAL_V0.1</span>
        <span className="text-[#a3a3a3]">
          SYS_STAT: <span className="text-white font-bold">[RUNNING]</span>
        </span>
      </div>
      <div className="mt-2.5 border-b border-[#262626] w-full" aria-hidden="true" />
    </div>
  );
};
