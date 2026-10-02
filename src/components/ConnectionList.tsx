import React from 'react';
import { UserConnection } from '../types/terminal';
import { PhoneCall } from 'lucide-react';

interface ConnectionListProps {
  connections: UserConnection[];
  onCallUser: (handle: string) => void;
}

export const ConnectionList: React.FC<ConnectionListProps> = ({
  connections,
  onCallUser,
}) => {
  const getStatusBadge = (status: UserConnection['status']) => {
    switch (status) {
      case 'READY':
        return <span className="text-[#22c55e] font-semibold">(Status: READY)</span>;
      case 'BUSY':
        return <span className="text-[#eab308] font-semibold">(Status: BUSY)</span>;
      case 'OFFLINE':
        return <span className="text-[#737373] font-semibold">(Status: OFFLINE)</span>;
      default:
        return null;
    }
  };

  return (
    <div className="px-4 py-2.5 font-mono text-xs select-none shrink-0">
      <div className="text-[#a3a3a3] font-semibold tracking-wider mb-2">
        [ CONNECTION LIST ]
      </div>

      <div className="space-y-1">
        {connections.map((user) => {
          const isOffline = user.status === 'OFFLINE';

          return (
            <div
              key={user.id}
              className="flex items-center justify-between py-1.5 px-2 rounded-sm hover:bg-[#0f0f0f] transition-colors border border-transparent hover:border-[#262626] group"
            >
              <div className="flex items-center space-x-3 min-w-0">
                <span className="text-white font-semibold group-hover:text-white truncate">
                  * {user.handle.padEnd(7, ' ')}
                </span>
                
                <button
                  type="button"
                  onClick={() => onCallUser(user.handle)}
                  className={`px-2 py-0.5 text-[11px] font-mono tracking-wider font-semibold border transition-colors focus:outline-none focus:ring-1 focus:ring-white flex items-center space-x-1 cursor-pointer active:translate-y-0.5 ${
                    isOffline
                      ? 'bg-[#121212] text-[#525252] border-[#262626] hover:bg-[#1a1a1a] hover:text-[#737373]'
                      : 'bg-[#171717] text-[#e5e5e5] border-[#333333] hover:bg-white hover:text-black'
                  }`}
                  aria-label={`Call ${user.handle} (Status: ${user.status})`}
                >
                  <PhoneCall className="w-2.5 h-2.5 inline-block" aria-hidden="true" />
                  <span>[CALL]</span>
                </button>
              </div>

              <div className="pl-2 flex-shrink-0 text-right">
                {getStatusBadge(user.status)}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};
