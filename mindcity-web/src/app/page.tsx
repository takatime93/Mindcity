'use client';

import { useState } from 'react';
import { useMindCity } from '@/hooks/useMindCity';
import TabBar from '@/components/TabBar';
import CityView from '@/components/CityView';
import InboxView from '@/components/InboxView';
import ReviewView from '@/components/ReviewView';
import CaptureSheet from '@/components/CaptureSheet';
import StatsView from '@/components/StatsView';
import ErrorToast from '@/components/ErrorToast';
import LoadingScreen from '@/components/LoadingScreen';

type Tab = 'city' | 'inbox' | 'review' | 'stats';

export default function Home() {
  const [activeTab, setActiveTab] = useState<Tab>('city');
  const [showCapture, setShowCapture] = useState(false);
  const [selectedItemId, setSelectedItemId] = useState<string | null>(null);

  const {
    items,
    buildings,
    stats,
    isLoading,
    error,
    setError,
    inboxItems,
    dueItems,
    dueCount,
    addItem,
    deleteItem,
    placeBuilding,
    getReviewSession,
    submitReview,
  } = useMindCity();

  if (isLoading) {
    return <LoadingScreen />;
  }

  const handleCapture = async (
    content: string,
    category: string,
    contentType: string
  ) => {
    await addItem(
      content,
      contentType as any,
      category as any
    );
    setShowCapture(false);
  };

  const renderContent = () => {
    switch (activeTab) {
      case 'city':
        return (
          <CityView
            buildings={buildings}
            items={items}
            onPlaceBuilding={(itemId, type, x, y) => placeBuilding(itemId, type, x, y)}
            selectedItemId={selectedItemId}
            onSelectItem={setSelectedItemId}
          />
        );
      case 'inbox':
        return (
          <InboxView
            items={inboxItems}
            onSelectItem={(id) => {
              setSelectedItemId(id);
              setActiveTab('city');
            }}
            onDeleteItem={deleteItem}
          />
        );
      case 'review':
        return (
          <ReviewView
            dueItems={dueItems}
            onSubmitReview={submitReview}
            getReviewSession={getReviewSession}
          />
        );
      case 'stats':
        return (
          <StatsView
            stats={stats}
            items={items}
          />
        );
    }
  };

  return (
    <main className="flex flex-col h-screen bg-gray-50 dark:bg-gray-950">
      {/* Main Content */}
      <div className="flex-1 overflow-hidden">
        {renderContent()}
      </div>

      {/* Tab Bar */}
      <TabBar
        activeTab={activeTab}
        onTabChange={setActiveTab}
        onCapturePress={() => setShowCapture(true)}
        inboxCount={inboxItems.length}
        dueCount={dueCount}
      />

      {/* Capture Sheet */}
      {showCapture && (
        <CaptureSheet
          onClose={() => setShowCapture(false)}
          onCapture={handleCapture}
        />
      )}

      {/* Error Toast */}
      {error && (
        <ErrorToast
          message={error}
          onDismiss={() => setError(null)}
        />
      )}
    </main>
  );
}
