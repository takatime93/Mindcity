'use client';

import { FC } from 'react';

type Tab = 'city' | 'inbox' | 'review' | 'stats';

interface TabBarProps {
  activeTab: Tab;
  onTabChange: (tab: Tab) => void;
  onCapturePress: () => void;
  inboxCount: number;
  dueCount: number;
}

const TabBar: FC<TabBarProps> = ({
  activeTab,
  onTabChange,
  onCapturePress,
  inboxCount,
  dueCount,
}) => {
  const tabs: { id: Tab; label: string; icon: string }[] = [
    { id: 'city', label: 'City', icon: '🏙️' },
    { id: 'inbox', label: 'Inbox', icon: '📥' },
    { id: 'review', label: 'Review', icon: '🧠' },
    { id: 'stats', label: 'Stats', icon: '📊' },
  ];

  return (
    <div className="bg-white dark:bg-gray-900 border-t border-gray-200 dark:border-gray-800 pb-safe">
      <div className="flex items-center justify-around px-2 h-16">
        {tabs.slice(0, 2).map((tab) => (
          <button
            key={tab.id}
            onClick={() => onTabChange(tab.id)}
            className={`flex flex-col items-center justify-center flex-1 py-2 relative btn-active
              ${activeTab === tab.id ? 'text-blue-500' : 'text-gray-500 dark:text-gray-400'}`}
          >
            <span className="text-xl">{tab.icon}</span>
            <span className="text-xs mt-0.5">{tab.label}</span>
            {tab.id === 'inbox' && inboxCount > 0 && (
              <span className="absolute top-1 right-1/4 bg-blue-500 text-white text-xs w-5 h-5 rounded-full flex items-center justify-center">
                {inboxCount > 9 ? '9+' : inboxCount}
              </span>
            )}
          </button>
        ))}

        {/* Center Capture Button */}
        <button
          onClick={onCapturePress}
          className="w-14 h-14 -mt-4 bg-blue-500 rounded-full flex items-center justify-center shadow-lg btn-active"
        >
          <svg
            className="w-7 h-7 text-white"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2.5}
              d="M12 4v16m8-8H4"
            />
          </svg>
        </button>

        {tabs.slice(2).map((tab) => (
          <button
            key={tab.id}
            onClick={() => onTabChange(tab.id)}
            className={`flex flex-col items-center justify-center flex-1 py-2 relative btn-active
              ${activeTab === tab.id ? 'text-blue-500' : 'text-gray-500 dark:text-gray-400'}`}
          >
            <span className="text-xl">{tab.icon}</span>
            <span className="text-xs mt-0.5">{tab.label}</span>
            {tab.id === 'review' && dueCount > 0 && (
              <span className="absolute top-1 right-1/4 bg-orange-500 text-white text-xs w-5 h-5 rounded-full flex items-center justify-center">
                {dueCount > 9 ? '9+' : dueCount}
              </span>
            )}
          </button>
        ))}
      </div>
    </div>
  );
};

export default TabBar;
