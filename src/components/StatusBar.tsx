import React, { useState, useEffect } from 'react';
import { Wifi, SquareTerminal, Battery } from 'lucide-react';

export const StatusBar: React.FC = () => {
  const [time, setTime] = useState<string>('');

  useEffect(() => {
    const updateTime = () => {
      const now = new Date();
      const hours = String(now.getHours()).padStart(2, '0');
      const minutes = String(now.getMinutes()).padStart(2, '0');
      setTime(`${hours}:${minutes}`);
    };

    updateTime();
    const interval = setInterval(updateTime, 1000);
    return () => clearInterval(interval);
  }, []);

  return (
    <header 
      className="flex items-center justify-between px-4 py-2.5 border-b border-[#262626] text-xs font-mono text-[#a3a3a3] select-none bg-black shrink-0"
      aria-label="System status bar"
    >
      <div className="flex items-center space-x-2.5">
        <span className="font-bold text-white tracking-wider">{time || '21:30'}</span>
        <Wifi className="w-3.5 h-3.5 text-[#e5e5e5]" aria-hidden="true" />
      </div>
      
      <div className="flex items-center space-x-3">
        <div className="flex items-center space-x-1.5">
          <Battery className="w-3.5 h-3.5 text-[#e5e5e5]" aria-hidden="true" />
          <span className="tracking-tight text-[#d4d4d4] font-medium">BATTERY 82%</span>
        </div>
        <SquareTerminal className="w-3.5 h-3.5 text-[#e5e5e5]" aria-hidden="true" />
      </div>
    </header>
  );
};
