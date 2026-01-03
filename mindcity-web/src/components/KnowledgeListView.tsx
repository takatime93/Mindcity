'use client';

import { FC, useState, useMemo } from 'react';
import { KnowledgeItem, Building, KnowledgeCategory, CategoryInfo, BuildingTypeInfo, getEvolutionLevel, EvolutionInfo } from '@/lib/types';

interface KnowledgeListViewProps {
  items: KnowledgeItem[];
  buildings: Building[];
  onClose: () => void;
  onSelectItem: (id: string) => void;
}

type SortOption = 'recent' | 'oldest' | 'retention-low' | 'retention-high' | 'reviews';
type FilterOption = 'all' | 'placed' | 'inbox' | KnowledgeCategory;

const CategoryEmoji: Record<string, string> = {
  philosophy: '🧠',
  technical: '🔧',
  creative: '🎨',
  science: '🔬',
  personal: '⭐',
  general: '📦',
};

const KnowledgeListView: FC<KnowledgeListViewProps> = ({
  items,
  buildings,
  onClose,
  onSelectItem,
}) => {
  const [searchQuery, setSearchQuery] = useState('');
  const [sortBy, setSortBy] = useState<SortOption>('recent');
  const [filterBy, setFilterBy] = useState<FilterOption>('all');
  const [selectedItem, setSelectedItem] = useState<KnowledgeItem | null>(null);

  const getBuildingForItem = (itemId: string) => {
    return buildings.find(b => b.knowledgeItemId === itemId);
  };

  const filteredAndSortedItems = useMemo(() => {
    let result = [...items];

    // Apply search filter
    if (searchQuery.trim()) {
      const query = searchQuery.toLowerCase();
      result = result.filter(item =>
        item.content.toLowerCase().includes(query) ||
        item.tags.some(tag => tag.toLowerCase().includes(query))
      );
    }

    // Apply category/status filter
    if (filterBy === 'placed') {
      result = result.filter(item => item.isPlaced);
    } else if (filterBy === 'inbox') {
      result = result.filter(item => !item.isPlaced);
    } else if (filterBy !== 'all') {
      result = result.filter(item => item.category === filterBy);
    }

    // Apply sorting
    switch (sortBy) {
      case 'recent':
        result.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
        break;
      case 'oldest':
        result.sort((a, b) => new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime());
        break;
      case 'retention-low':
        result.sort((a, b) => a.retrievability - b.retrievability);
        break;
      case 'retention-high':
        result.sort((a, b) => b.retrievability - a.retrievability);
        break;
      case 'reviews':
        result.sort((a, b) => b.reviewCount - a.reviewCount);
        break;
    }

    return result;
  }, [items, searchQuery, sortBy, filterBy]);

  const formatDate = (date: Date | string) => {
    const d = new Date(date);
    return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
  };

  const getRetentionColor = (retention: number) => {
    if (retention >= 0.9) return 'bg-green-500';
    if (retention >= 0.7) return 'bg-yellow-500';
    return 'bg-red-500';
  };

  return (
    <div className="fixed inset-0 bg-white dark:bg-gray-950 z-30 flex flex-col">
      {/* Header */}
      <div className="flex items-center justify-between p-4 border-b border-gray-200 dark:border-gray-800">
        <h2 className="text-xl font-bold text-gray-900 dark:text-gray-100">
          All Knowledge
        </h2>
        <button
          onClick={onClose}
          className="p-2 text-gray-500 hover:text-gray-700 dark:hover:text-gray-300"
        >
          ✕
        </button>
      </div>

      {/* Search */}
      <div className="p-4 border-b border-gray-200 dark:border-gray-800">
        <div className="relative">
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search knowledge..."
            className="w-full px-4 py-3 pl-10 bg-gray-100 dark:bg-gray-800 rounded-xl text-gray-900 dark:text-gray-100 placeholder-gray-500"
          />
          <span className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400">🔍</span>
        </div>

        {/* Filters */}
        <div className="flex gap-2 mt-3 overflow-x-auto hide-scrollbar pb-1">
          {(['all', 'placed', 'inbox'] as FilterOption[]).map((filter) => (
            <button
              key={filter}
              onClick={() => setFilterBy(filter)}
              className={`px-3 py-1.5 rounded-full text-sm whitespace-nowrap transition-colors
                ${filterBy === filter
                  ? 'bg-blue-500 text-white'
                  : 'bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-400'
                }`}
            >
              {filter === 'all' ? 'All' : filter === 'placed' ? '🏙️ In City' : '📥 Inbox'}
            </button>
          ))}
          {(Object.keys(CategoryInfo) as KnowledgeCategory[]).map((cat) => (
            <button
              key={cat}
              onClick={() => setFilterBy(cat)}
              className={`px-3 py-1.5 rounded-full text-sm whitespace-nowrap transition-colors
                ${filterBy === cat
                  ? 'bg-blue-500 text-white'
                  : 'bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-400'
                }`}
            >
              {CategoryEmoji[cat]} {cat.charAt(0).toUpperCase() + cat.slice(1)}
            </button>
          ))}
        </div>

        {/* Sort */}
        <div className="flex items-center gap-2 mt-3">
          <span className="text-sm text-gray-500">Sort:</span>
          <select
            value={sortBy}
            onChange={(e) => setSortBy(e.target.value as SortOption)}
            className="bg-gray-100 dark:bg-gray-800 text-gray-700 dark:text-gray-300 text-sm px-2 py-1 rounded-lg"
          >
            <option value="recent">Most Recent</option>
            <option value="oldest">Oldest First</option>
            <option value="retention-low">Needs Review</option>
            <option value="retention-high">Best Retained</option>
            <option value="reviews">Most Reviewed</option>
          </select>
          <span className="ml-auto text-sm text-gray-400">
            {filteredAndSortedItems.length} items
          </span>
        </div>
      </div>

      {/* List */}
      <div className="flex-1 overflow-auto hide-scrollbar">
        {filteredAndSortedItems.length === 0 ? (
          <div className="flex flex-col items-center justify-center h-full text-gray-500 dark:text-gray-400">
            <span className="text-4xl mb-2">🔍</span>
            <p>No items found</p>
          </div>
        ) : (
          <div className="p-4 space-y-2">
            {filteredAndSortedItems.map((item) => {
              const building = getBuildingForItem(item.id);
              const evolutionLevel = getEvolutionLevel(item.reviewCount, item.retrievability);

              return (
                <div
                  key={item.id}
                  onClick={() => setSelectedItem(item)}
                  className="bg-gray-50 dark:bg-gray-900 rounded-xl p-4 cursor-pointer active:scale-[0.98] transition-transform"
                >
                  <div className="flex items-start gap-3">
                    {/* Category Icon / Building */}
                    <div className="text-2xl">
                      {building
                        ? BuildingTypeInfo[building.buildingType as keyof typeof BuildingTypeInfo]?.displayName
                          ? '🏛️'
                          : CategoryEmoji[item.category]
                        : CategoryEmoji[item.category]
                      }
                    </div>

                    {/* Content */}
                    <div className="flex-1 min-w-0">
                      <p className="text-gray-900 dark:text-gray-100 line-clamp-2">
                        {item.content}
                      </p>
                      <div className="flex items-center gap-2 mt-2 flex-wrap">
                        <span
                          className="text-xs px-2 py-0.5 rounded-full"
                          style={{
                            backgroundColor: CategoryInfo[item.category].color + '20',
                            color: CategoryInfo[item.category].color,
                          }}
                        >
                          {item.category}
                        </span>
                        {item.isPlaced && (
                          <span className="text-xs px-2 py-0.5 rounded-full bg-blue-100 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400">
                            {EvolutionInfo[evolutionLevel].displayName}
                          </span>
                        )}
                        {!item.isPlaced && (
                          <span className="text-xs px-2 py-0.5 rounded-full bg-gray-200 dark:bg-gray-700 text-gray-600 dark:text-gray-400">
                            In Inbox
                          </span>
                        )}
                        <span className="text-xs text-gray-400">
                          {formatDate(item.createdAt)}
                        </span>
                      </div>
                    </div>

                    {/* Retention indicator */}
                    <div className="flex flex-col items-center">
                      <div className={`w-2 h-8 rounded-full ${getRetentionColor(item.retrievability)}`} />
                      <span className="text-xs text-gray-500 mt-1">
                        {Math.round(item.retrievability * 100)}%
                      </span>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>

      {/* Item Detail Sheet */}
      {selectedItem && (
        <div
          className="absolute inset-0 bg-black/50 flex items-end justify-center z-40"
          onClick={() => setSelectedItem(null)}
        >
          <div
            className="bg-white dark:bg-gray-900 w-full max-w-md rounded-t-3xl p-6 pb-safe max-h-[85vh] overflow-auto"
            onClick={(e) => e.stopPropagation()}
          >
            {/* Header */}
            <div className="flex items-start justify-between mb-4">
              <div className="flex items-center gap-3">
                <span className="text-3xl">{CategoryEmoji[selectedItem.category]}</span>
                <div>
                  <span
                    className="text-xs px-2 py-0.5 rounded-full"
                    style={{
                      backgroundColor: CategoryInfo[selectedItem.category].color + '20',
                      color: CategoryInfo[selectedItem.category].color,
                    }}
                  >
                    {CategoryInfo[selectedItem.category].displayName}
                  </span>
                </div>
              </div>
              <button
                onClick={() => setSelectedItem(null)}
                className="p-2 text-gray-400 hover:text-gray-600"
              >
                ✕
              </button>
            </div>

            {/* Content */}
            <div className="bg-gray-50 dark:bg-gray-800 rounded-xl p-4 mb-4">
              <p className="text-gray-900 dark:text-gray-100 whitespace-pre-wrap">
                {selectedItem.content}
              </p>
            </div>

            {/* Stats */}
            <div className="grid grid-cols-3 gap-2 mb-4">
              <div className="bg-gray-50 dark:bg-gray-800 rounded-xl p-3 text-center">
                <p className="text-xs text-gray-500">Retention</p>
                <p className="text-lg font-bold text-gray-900 dark:text-gray-100">
                  {Math.round(selectedItem.retrievability * 100)}%
                </p>
              </div>
              <div className="bg-gray-50 dark:bg-gray-800 rounded-xl p-3 text-center">
                <p className="text-xs text-gray-500">Reviews</p>
                <p className="text-lg font-bold text-gray-900 dark:text-gray-100">
                  {selectedItem.reviewCount}
                </p>
              </div>
              <div className="bg-gray-50 dark:bg-gray-800 rounded-xl p-3 text-center">
                <p className="text-xs text-gray-500">Streak</p>
                <p className="text-lg font-bold text-gray-900 dark:text-gray-100">
                  🔥 {selectedItem.consecutiveCorrect}
                </p>
              </div>
            </div>

            {/* Actions */}
            {!selectedItem.isPlaced && (
              <button
                onClick={() => {
                  onSelectItem(selectedItem.id);
                  setSelectedItem(null);
                  onClose();
                }}
                className="w-full py-3 bg-blue-500 text-white rounded-xl font-medium btn-active mb-2"
              >
                🏗️ Place in City
              </button>
            )}

            <p className="text-xs text-center text-gray-400 mt-2">
              Added {new Date(selectedItem.createdAt).toLocaleDateString()}
            </p>
          </div>
        </div>
      )}
    </div>
  );
};

export default KnowledgeListView;
