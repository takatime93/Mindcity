'use client';

import { FC } from 'react';

const LoadingScreen: FC = () => {
  return (
    <div className="flex flex-col items-center justify-center h-screen bg-gray-50 dark:bg-gray-950">
      <div className="text-6xl mb-4 animate-bounce-gentle">🏙️</div>
      <h1 className="text-2xl font-bold text-gray-900 dark:text-gray-100 mb-2">
        MindCity
      </h1>
      <p className="text-gray-500 dark:text-gray-400">
        Loading your knowledge city...
      </p>
      <div className="mt-8 w-12 h-12 border-4 border-blue-200 dark:border-blue-800 border-t-blue-500 rounded-full animate-spin" />
    </div>
  );
};

export default LoadingScreen;
