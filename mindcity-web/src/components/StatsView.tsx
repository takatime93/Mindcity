'use client';

import { FC } from 'react';
import { UserStats, KnowledgeItem, EraInfo, EraOrder, CategoryInfo } from '@/lib/types';

interface StatsViewProps {
  stats: UserStats | null;
  items: KnowledgeItem[];
}

const StatsView: FC<StatsViewProps> = ({ stats, items }) => {
  if (!stats) {
    return (
      <div className="flex items-center justify-center h-full">
        <p className="text-gray-500">Loading stats...</p>
      </div>
    );
  }

  const placedItems = items.filter(i => i.isPlaced);
  const masteredItems = placedItems.filter(
    i => i.reviewCount >= 15 && i.retrievability >= 0.90
  );
  const averageRetention = placedItems.length > 0
    ? placedItems.reduce((sum, i) => sum + i.retrievability, 0) / placedItems.length
    : 0;

  // Category distribution
  const categoryStats = Object.keys(CategoryInfo).map(cat => ({
    category: cat,
    count: placedItems.filter(i => i.category === cat).length,
    color: CategoryInfo[cat as keyof typeof CategoryInfo].color,
  })).filter(c => c.count > 0);

  return (
    <div className="h-full overflow-auto hide-scrollbar">
      <div className="p-4 space-y-4">
        <h2 className="text-xl font-bold text-gray-900 dark:text-gray-100">
          Your Progress
        </h2>

        {/* Era Progress */}
        <div className="card p-4">
          <div className="flex items-center gap-3 mb-3">
            <span className="text-3xl">
              {stats.achievementEra === 'stoneAge' ? '🪨' :
               stats.achievementEra === 'ancient' ? '🏛️' :
               stats.achievementEra === 'medieval' ? '🏰' :
               stats.achievementEra === 'renaissance' ? '🎨' :
               stats.achievementEra === 'industrial' ? '🏭' :
               stats.achievementEra === 'modern' ? '🏙️' : '🚀'}
            </span>
            <div>
              <h3 className="font-semibold text-gray-900 dark:text-gray-100">
                {EraInfo[stats.achievementEra].displayName}
              </h3>
              <p className="text-sm text-gray-500">Current Era</p>
            </div>
          </div>

          {/* Era progress bar */}
          {stats.achievementEra !== 'future' && (
            <div>
              <div className="flex justify-between text-xs text-gray-500 mb-1">
                <span>{masteredItems.length} mastered</span>
                <span>
                  {EraInfo[EraOrder[EraOrder.indexOf(stats.achievementEra) + 1]].requiredItems} needed
                </span>
              </div>
              <div className="h-2 bg-gray-200 dark:bg-gray-700 rounded-full overflow-hidden">
                <div
                  className="h-full bg-gradient-to-r from-blue-500 to-purple-500 transition-all duration-500"
                  style={{
                    width: `${Math.min(100,
                      (masteredItems.length /
                        EraInfo[EraOrder[EraOrder.indexOf(stats.achievementEra) + 1]].requiredItems) *
                        100
                    )}%`,
                  }}
                />
              </div>
            </div>
          )}
        </div>

        {/* Streak */}
        <div className="card p-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <span className="text-3xl">🔥</span>
              <div>
                <p className="text-2xl font-bold text-gray-900 dark:text-gray-100">
                  {stats.currentStreak}
                </p>
                <p className="text-sm text-gray-500">Day Streak</p>
              </div>
            </div>
            <div className="text-right">
              <p className="text-lg font-semibold text-gray-700 dark:text-gray-300">
                {stats.longestStreak}
              </p>
              <p className="text-xs text-gray-500">Best</p>
            </div>
          </div>
          {stats.streakFreezeAvailable && (
            <div className="mt-3 flex items-center gap-2 text-sm text-blue-500">
              <span>❄️</span>
              <span>Streak freeze available</span>
            </div>
          )}
        </div>

        {/* Quick Stats */}
        <div className="grid grid-cols-2 gap-3">
          <div className="card p-4 text-center">
            <p className="text-2xl font-bold text-gray-900 dark:text-gray-100">
              {placedItems.length}
            </p>
            <p className="text-sm text-gray-500">Buildings</p>
          </div>
          <div className="card p-4 text-center">
            <p className="text-2xl font-bold text-gray-900 dark:text-gray-100">
              {Math.round(averageRetention * 100)}%
            </p>
            <p className="text-sm text-gray-500">Avg. Retention</p>
          </div>
          <div className="card p-4 text-center">
            <p className="text-2xl font-bold text-gray-900 dark:text-gray-100">
              {stats.totalReviewsCompleted}
            </p>
            <p className="text-sm text-gray-500">Total Reviews</p>
          </div>
          <div className="card p-4 text-center">
            <p className="text-2xl font-bold text-gray-900 dark:text-gray-100">
              {masteredItems.length}
            </p>
            <p className="text-sm text-gray-500">Mastered</p>
          </div>
        </div>

        {/* Category Distribution */}
        {categoryStats.length > 0 && (
          <div className="card p-4">
            <h3 className="font-semibold text-gray-900 dark:text-gray-100 mb-3">
              Knowledge Distribution
            </h3>
            <div className="space-y-2">
              {categoryStats.sort((a, b) => b.count - a.count).map((cat) => (
                <div key={cat.category} className="flex items-center gap-3">
                  <div
                    className="w-3 h-3 rounded-full"
                    style={{ backgroundColor: cat.color }}
                  />
                  <span className="flex-1 text-sm text-gray-700 dark:text-gray-300 capitalize">
                    {cat.category}
                  </span>
                  <span className="text-sm font-medium text-gray-900 dark:text-gray-100">
                    {cat.count}
                  </span>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Version */}
        <p className="text-center text-xs text-gray-400 py-4">
          MindCity Web v1.0.0
        </p>
      </div>
    </div>
  );
};

export default StatsView;
