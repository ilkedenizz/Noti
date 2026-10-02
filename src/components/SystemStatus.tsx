import React from 'react';

interface SystemStatusProps {
  userProfile?: string;
  totalConnections: number;
}

export const SystemStatus: React.FC<SystemStatusProps> = ({
  userProfile = '@hocam',
  totalConnections,
}) => {
  return (
    <div className="px-4 py-2 font-mono text-xs space-y-1 text-[#d4d4d4] shrink-0 select-none">
      <div className="flex items-center space-x-2">
        <span className="text-[#525252] font-semibold">&gt;</span>
        <span>
          SYSTEM_STATUS: <span className="text-white font-bold">[ACTIVE]</span>
        </span>
      </div>
      <div className="flex items-center space-x-2">
        <span className="text-[#525252] font-semibold">&gt;</span>
        <span>
          USER_PROFILE: <span className="text-white font-bold">{userProfile}</span>
        </span>
      </div>
      <div className="flex items-center space-x-2">
        <span className="text-[#525252] font-semibold">&gt;</span>
        <span>
          CONNECTIONS: <span className="text-white font-bold">[{totalConnections} TOTAL]</span>
        </span>
      </div>
    </div>
  );
};
