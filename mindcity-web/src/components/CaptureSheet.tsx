'use client';

import { FC, useState } from 'react';
import { KnowledgeCategory, ContentType, CategoryInfo } from '@/lib/types';

interface CaptureSheetProps {
  onClose: () => void;
  onCapture: (content: string, category: string, contentType: string) => Promise<void>;
}

const CategoryEmoji: Record<string, string> = {
  philosophy: '🧠',
  technical: '🔧',
  creative: '🎨',
  science: '🔬',
  personal: '⭐',
  general: '📦',
};

const categories: KnowledgeCategory[] = [
  'philosophy',
  'technical',
  'creative',
  'science',
  'personal',
  'general',
];

const CaptureSheet: FC<CaptureSheetProps> = ({ onClose, onCapture }) => {
  const [content, setContent] = useState('');
  const [category, setCategory] = useState<KnowledgeCategory>('general');
  const [contentType, setContentType] = useState<ContentType>('text');
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleSubmit = async () => {
    if (!content.trim() || isSubmitting) return;

    setIsSubmitting(true);
    try {
      await onCapture(content.trim(), category, contentType);
    } finally {
      setIsSubmitting(false);
    }
  };

  const isQuote = content.trim().startsWith('"') || content.trim().startsWith("'");

  return (
    <div className="fixed inset-0 bg-black/50 flex items-end z-50">
      <div
        className="bg-white dark:bg-gray-900 w-full rounded-t-3xl max-h-[90vh] overflow-auto"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="flex items-center justify-between p-4 border-b border-gray-200 dark:border-gray-800">
          <button
            onClick={onClose}
            className="text-gray-500 dark:text-gray-400 px-4 py-2"
          >
            Cancel
          </button>
          <h2 className="font-semibold text-gray-900 dark:text-gray-100">
            Capture Knowledge
          </h2>
          <button
            onClick={handleSubmit}
            disabled={!content.trim() || isSubmitting}
            className="text-blue-500 font-semibold px-4 py-2 disabled:opacity-50"
          >
            {isSubmitting ? 'Saving...' : 'Save'}
          </button>
        </div>

        {/* Content */}
        <div className="p-4 space-y-4 pb-safe">
          {/* Text Input */}
          <div>
            <textarea
              value={content}
              onChange={(e) => {
                setContent(e.target.value);
                // Auto-detect quote
                if (e.target.value.trim().startsWith('"') || e.target.value.trim().startsWith("'")) {
                  setContentType('quote');
                } else if (contentType === 'quote') {
                  setContentType('text');
                }
              }}
              placeholder="What did you learn today?"
              className="w-full h-32 p-4 bg-gray-100 dark:bg-gray-800 rounded-xl resize-none text-gray-900 dark:text-gray-100 placeholder-gray-500"
              autoFocus
            />
            {isQuote && (
              <p className="text-xs text-purple-500 mt-1">
                Detected as quote
              </p>
            )}
          </div>

          {/* Category Selection */}
          <div>
            <label className="text-sm font-medium text-gray-700 dark:text-gray-300 mb-2 block">
              Category
            </label>
            <div className="grid grid-cols-3 gap-2">
              {categories.map((cat) => (
                <button
                  key={cat}
                  onClick={() => setCategory(cat)}
                  className={`p-3 rounded-xl flex flex-col items-center gap-1 transition-colors btn-active
                    ${category === cat
                      ? 'bg-blue-100 dark:bg-blue-900/40 border-2 border-blue-500'
                      : 'bg-gray-100 dark:bg-gray-800 border-2 border-transparent'
                    }`}
                >
                  <span className="text-xl">{CategoryEmoji[cat]}</span>
                  <span className="text-xs text-gray-600 dark:text-gray-400">
                    {cat.charAt(0).toUpperCase() + cat.slice(1)}
                  </span>
                </button>
              ))}
            </div>
          </div>

          {/* Content Type (hidden for now, auto-detected) */}
          {/* Could add URL detection, image paste, etc. */}

          {/* Tips */}
          <div className="bg-blue-50 dark:bg-blue-900/20 p-4 rounded-xl">
            <p className="text-sm text-blue-700 dark:text-blue-300">
              <span className="font-medium">Tip:</span> Start with a quote mark to capture a quote, or paste a URL to save a link.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default CaptureSheet;
