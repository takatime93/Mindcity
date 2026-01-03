'use client';

import { FC, useEffect } from 'react';

interface ErrorToastProps {
  message: string;
  onDismiss: () => void;
}

const ErrorToast: FC<ErrorToastProps> = ({ message, onDismiss }) => {
  useEffect(() => {
    const timer = setTimeout(onDismiss, 5000);
    return () => clearTimeout(timer);
  }, [onDismiss]);

  return (
    <div className="fixed bottom-20 left-4 right-4 z-50 animate-in slide-in-from-bottom-4">
      <div className="bg-red-500 text-white p-4 rounded-xl shadow-lg flex items-center gap-3">
        <span className="text-xl">⚠️</span>
        <p className="flex-1 text-sm">{message}</p>
        <button
          onClick={onDismiss}
          className="p-1 hover:bg-white/20 rounded"
        >
          ✕
        </button>
      </div>
    </div>
  );
};

export default ErrorToast;
