'use client';

import { FC, useState } from 'react';
import { KnowledgeItem, CategoryInfo } from '@/lib/types';

interface InboxViewProps {
  items: KnowledgeItem[];
  onSelectItem: (id: string) => void;
  onDeleteItem: (id: string) => void;
}

const CategoryEmoji: Record<string, string> = {
  philosophy: '🧠',
  technical: '🔧',
  creative: '🎨',
  science: '🔬',
  personal: '⭐',
  general: '📦',
};

const InboxView: FC<InboxViewProps> = ({ items, onSelectItem, onDeleteItem }) => {
  const [confirmDelete, setConfirmDelete] = useState<string | null>(null);

  const handleDelete = (id: string) => {
    if (confirmDelete === id) {
      onDeleteItem(id);
      setConfirmDelete(null);
    } else {
      setConfirmDelete(id);
      // Auto-reset after 3 seconds
      setTimeout(() => setConfirmDelete(null), 3000);
    }
  };

  if (items.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center h-full p-8 text-center">
        <span className="text-6xl mb-4">📥</span>
        <h3 className="text-lg font-medium text-gray-900 dark:text-gray-100">
          Inbox Empty
        </h3>
        <p className="text-sm text-gray-500 dark:text-gray-400 mt-2">
          Capture some knowledge to get started!
        </p>
      </div>
    );
  }

  return (
    <div className="h-full overflow-auto hide-scrollbar">
      <div className="p-4">
        <h2 className="text-xl font-bold mb-4 text-gray-900 dark:text-gray-100">
          Inbox ({items.length})
        </h2>
        <p className="text-sm text-gray-500 dark:text-gray-400 mb-4">
          Tap to place in your city
        </p>

        <div className="space-y-3">
          {items.map((item) => (
            <div
              key={item.id}
              className="card p-4 active:scale-[0.98] transition-transform"
            >
              <div className="flex items-start gap-3">
                {/* Category Icon */}
                <span className="text-2xl">{CategoryEmoji[item.category]}</span>

                {/* Content */}
                <div className="flex-1 min-w-0">
                  <p className="text-gray-900 dark:text-gray-100 line-clamp-3">
                    {item.content}
                  </p>
                  <div className="flex items-center gap-2 mt-2">
                    <span
                      className="text-xs px-2 py-0.5 rounded-full"
                      style={{
                        backgroundColor: CategoryInfo[item.category].color + '20',
                        color: CategoryInfo[item.category].color,
                      }}
                    >
                      {CategoryInfo[item.category].displayName}
                    </span>
                    <span className="text-xs text-gray-400">
                      {new Date(item.createdAt).toLocaleDateString()}
                    </span>
                  </div>
                </div>

                {/* Actions */}
                <div className="flex flex-col gap-2">
                  <button
                    onClick={() => onSelectItem(item.id)}
                    className="p-2 bg-blue-100 dark:bg-blue-900/30 text-blue-500 rounded-lg btn-active"
                  >
                    🏗️
                  </button>
                  <button
                    onClick={() => handleDelete(item.id)}
                    className={`p-2 rounded-lg btn-active transition-colors ${
                      confirmDelete === item.id
                        ? 'bg-red-500 text-white'
                        : 'bg-gray-100 dark:bg-gray-800 text-gray-500'
                    }`}
                  >
                    {confirmDelete === item.id ? '✓' : '🗑️'}
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

export default InboxView;
