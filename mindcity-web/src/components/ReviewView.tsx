'use client';

import { FC, useState, useEffect } from 'react';
import { KnowledgeItem, ReviewResult, CategoryInfo } from '@/lib/types';
import { FSRSUpdate } from '@/lib/fsrs';

interface ReviewViewProps {
  dueItems: KnowledgeItem[];
  onSubmitReview: (itemId: string, result: ReviewResult) => Promise<FSRSUpdate>;
  getReviewSession: (quick?: boolean) => KnowledgeItem[];
}

const CategoryEmoji: Record<string, string> = {
  philosophy: '🧠',
  technical: '🔧',
  creative: '🎨',
  science: '🔬',
  personal: '⭐',
  general: '📦',
};

const ReviewView: FC<ReviewViewProps> = ({
  dueItems,
  onSubmitReview,
  getReviewSession,
}) => {
  const [session, setSession] = useState<KnowledgeItem[]>([]);
  const [currentIndex, setCurrentIndex] = useState(0);
  const [showContent, setShowContent] = useState(false);
  const [isAnimating, setIsAnimating] = useState(false);
  const [sessionComplete, setSessionComplete] = useState(false);
  const [sessionStats, setSessionStats] = useState({ correct: 0, forgot: 0 });

  // Start a new session
  const startSession = (quick: boolean = false) => {
    const items = getReviewSession(quick);
    setSession(items);
    setCurrentIndex(0);
    setShowContent(false);
    setSessionComplete(false);
    setSessionStats({ correct: 0, forgot: 0 });
  };

  const currentItem = session[currentIndex];

  const handleReview = async (result: ReviewResult) => {
    if (!currentItem || isAnimating) return;

    setIsAnimating(true);

    // Vibrate feedback
    if (navigator.vibrate) {
      navigator.vibrate(result === 'gotIt' ? 50 : [30, 30, 30]);
    }

    await onSubmitReview(currentItem.id, result);

    // Update stats
    setSessionStats(prev => ({
      correct: prev.correct + (result === 'gotIt' ? 1 : 0),
      forgot: prev.forgot + (result === 'forgot' ? 1 : 0),
    }));

    // Animate out
    setTimeout(() => {
      if (currentIndex < session.length - 1) {
        setCurrentIndex(prev => prev + 1);
        setShowContent(false);
      } else {
        setSessionComplete(true);
      }
      setIsAnimating(false);
    }, 300);
  };

  // No items due
  if (dueItems.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center h-full p-8 text-center">
        <span className="text-6xl mb-4">🎉</span>
        <h3 className="text-lg font-medium text-gray-900 dark:text-gray-100">
          All Caught Up!
        </h3>
        <p className="text-sm text-gray-500 dark:text-gray-400 mt-2">
          No items due for review. Great job!
        </p>
      </div>
    );
  }

  // No active session
  if (session.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center h-full p-8">
        <span className="text-6xl mb-4">🧠</span>
        <h3 className="text-xl font-bold text-gray-900 dark:text-gray-100 mb-2">
          {dueItems.length} Items Due
        </h3>
        <p className="text-sm text-gray-500 dark:text-gray-400 mb-8 text-center">
          Strengthen your memory palace with a review session
        </p>

        <div className="space-y-3 w-full max-w-xs">
          <button
            onClick={() => startSession(true)}
            className="w-full py-4 bg-blue-100 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400 rounded-2xl font-medium btn-active"
          >
            Quick Review (5 items)
          </button>
          <button
            onClick={() => startSession(false)}
            className="w-full py-4 bg-blue-500 text-white rounded-2xl font-medium btn-active"
          >
            Full Session ({Math.min(15, dueItems.length)} items)
          </button>
        </div>
      </div>
    );
  }

  // Session complete
  if (sessionComplete) {
    const accuracy = Math.round(
      (sessionStats.correct / (sessionStats.correct + sessionStats.forgot)) * 100
    );

    return (
      <div className="flex flex-col items-center justify-center h-full p-8 text-center">
        <span className="text-6xl mb-4">
          {accuracy >= 80 ? '🌟' : accuracy >= 60 ? '👍' : '💪'}
        </span>
        <h3 className="text-xl font-bold text-gray-900 dark:text-gray-100 mb-2">
          Session Complete!
        </h3>
        <div className="flex gap-8 my-6">
          <div className="text-center">
            <p className="text-3xl font-bold text-green-500">{sessionStats.correct}</p>
            <p className="text-sm text-gray-500">Got it</p>
          </div>
          <div className="text-center">
            <p className="text-3xl font-bold text-red-500">{sessionStats.forgot}</p>
            <p className="text-sm text-gray-500">Forgot</p>
          </div>
        </div>
        <p className="text-lg font-medium text-gray-700 dark:text-gray-300 mb-8">
          {accuracy}% accuracy
        </p>
        <button
          onClick={() => setSession([])}
          className="py-3 px-8 bg-blue-500 text-white rounded-2xl font-medium btn-active"
        >
          Done
        </button>
      </div>
    );
  }

  // Active review
  return (
    <div className="flex flex-col h-full p-4">
      {/* Progress */}
      <div className="flex items-center gap-2 mb-4">
        <div className="flex-1 h-2 bg-gray-200 dark:bg-gray-800 rounded-full overflow-hidden">
          <div
            className="h-full bg-blue-500 transition-all duration-300"
            style={{ width: `${((currentIndex + 1) / session.length) * 100}%` }}
          />
        </div>
        <span className="text-sm text-gray-500 dark:text-gray-400">
          {currentIndex + 1}/{session.length}
        </span>
      </div>

      {/* Card */}
      <div
        className={`flex-1 card p-6 flex flex-col transition-all duration-300
          ${isAnimating ? 'opacity-0 scale-95' : 'opacity-100 scale-100'}`}
      >
        {/* Category Badge */}
        <div className="flex items-center gap-2 mb-4">
          <span className="text-xl">{CategoryEmoji[currentItem.category]}</span>
          <span
            className="text-xs px-2 py-0.5 rounded-full"
            style={{
              backgroundColor: CategoryInfo[currentItem.category].color + '20',
              color: CategoryInfo[currentItem.category].color,
            }}
          >
            {CategoryInfo[currentItem.category].displayName}
          </span>
        </div>

        {/* Content */}
        <div className="flex-1 flex items-center justify-center">
          {!showContent ? (
            <button
              onClick={() => setShowContent(true)}
              className="text-center"
            >
              <span className="text-4xl block mb-4">🤔</span>
              <p className="text-gray-500 dark:text-gray-400">
                Tap to reveal
              </p>
            </button>
          ) : (
            <p className="text-lg text-center text-gray-900 dark:text-gray-100">
              {currentItem.content}
            </p>
          )}
        </div>

        {/* Stats */}
        {showContent && (
          <div className="flex justify-center gap-4 text-sm text-gray-500 dark:text-gray-400 mb-4">
            <span>Reviews: {currentItem.reviewCount}</span>
            <span>Streak: {currentItem.consecutiveCorrect}</span>
          </div>
        )}
      </div>

      {/* Review Buttons */}
      {showContent && (
        <div className="flex gap-4 mt-4">
          <button
            onClick={() => handleReview('forgot')}
            disabled={isAnimating}
            className="flex-1 py-4 bg-red-100 dark:bg-red-900/30 text-red-600 dark:text-red-400 rounded-2xl font-medium btn-active disabled:opacity-50"
          >
            <span className="text-2xl block mb-1">😕</span>
            Forgot
          </button>
          <button
            onClick={() => handleReview('gotIt')}
            disabled={isAnimating}
            className="flex-1 py-4 bg-green-100 dark:bg-green-900/30 text-green-600 dark:text-green-400 rounded-2xl font-medium btn-active disabled:opacity-50"
          >
            <span className="text-2xl block mb-1">😊</span>
            Got it!
          </button>
        </div>
      )}
    </div>
  );
};

export default ReviewView;
