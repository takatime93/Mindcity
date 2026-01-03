'use client';

import { useState, useEffect, useCallback } from 'react';
import {
  KnowledgeItem,
  Building,
  UserStats,
  ReviewResult,
  KnowledgeCategory,
  BuildingType,
  ContentType,
} from '@/lib/types';
import * as db from '@/lib/database';
import { processReview, selectReviewItems, calculateAchievementEra, FSRSUpdate } from '@/lib/fsrs';

export function useMindCity() {
  const [items, setItems] = useState<KnowledgeItem[]>([]);
  const [buildings, setBuildings] = useState<Building[]>([]);
  const [stats, setStats] = useState<UserStats | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Load initial data
  useEffect(() => {
    loadData();
  }, []);

  const loadData = useCallback(async () => {
    try {
      setIsLoading(true);
      const [loadedItems, loadedBuildings, loadedStats] = await Promise.all([
        db.getAllKnowledgeItems(),
        db.getAllBuildings(),
        db.getOrCreateUserStats(),
      ]);
      setItems(loadedItems);
      setBuildings(loadedBuildings);
      setStats(loadedStats);
      setError(null);
    } catch (err) {
      setError('Failed to load data');
      console.error('Load error:', err);
    } finally {
      setIsLoading(false);
    }
  }, []);

  // Computed values
  const inboxItems = items.filter(item => !item.isPlaced);
  const placedItems = items.filter(item => item.isPlaced);
  const dueItems = items.filter(
    item => item.isPlaced && new Date(item.nextReview) <= new Date()
  );
  const dueCount = dueItems.length;

  // MARK: - Item Operations

  const addItem = useCallback(async (
    content: string,
    contentType: ContentType = 'text',
    category: KnowledgeCategory = 'general',
    tags: string[] = [],
    sourceURL?: string,
    imageData?: string
  ) => {
    try {
      const newItem = await db.createKnowledgeItem(
        content,
        contentType,
        category,
        tags,
        sourceURL,
        imageData
      );
      setItems(prev => [...prev, newItem]);

      // Update stats
      if (stats) {
        const newTotal = stats.totalItemsAdded + 1;
        await db.updateUserStats({ totalItemsAdded: newTotal });
        setStats({ ...stats, totalItemsAdded: newTotal });
      }

      // Haptic feedback (vibration API)
      if (navigator.vibrate) navigator.vibrate(50);

      return newItem;
    } catch (err) {
      setError('Failed to add item');
      console.error('Add item error:', err);
      throw err;
    }
  }, [stats]);

  const deleteItem = useCallback(async (id: string) => {
    try {
      await db.deleteKnowledgeItem(id);
      setItems(prev => prev.filter(item => item.id !== id));
      setBuildings(prev => prev.filter(b => b.knowledgeItemId !== id));

      if (navigator.vibrate) navigator.vibrate(30);
    } catch (err) {
      setError('Failed to delete item');
      console.error('Delete item error:', err);
      throw err;
    }
  }, []);

  // MARK: - Building Operations

  const placeBuilding = useCallback(async (
    itemId: string,
    buildingType: BuildingType,
    positionX: number,
    positionY: number
  ) => {
    try {
      // Check if cell is occupied
      const gridX = Math.floor(positionX / 60);
      const gridY = Math.floor(positionY / 60);
      const occupied = await db.isCellOccupied(gridX, gridY);

      if (occupied) {
        setError('This location is already occupied');
        if (navigator.vibrate) navigator.vibrate([50, 50, 50]);
        return null;
      }

      const building = await db.createBuilding(buildingType, positionX, positionY, itemId);
      setBuildings(prev => [...prev, building]);

      // Update item in state
      setItems(prev => prev.map(item =>
        item.id === itemId
          ? { ...item, isPlaced: true, positionX, positionY, buildingId: building.id }
          : item
      ));

      if (navigator.vibrate) navigator.vibrate(100);

      return building;
    } catch (err) {
      setError('Failed to place building');
      console.error('Place building error:', err);
      throw err;
    }
  }, []);

  // MARK: - Review Operations

  const getReviewSession = useCallback((quick: boolean = false) => {
    if (quick) {
      return selectReviewItems(items, 5, 5);
    }
    return selectReviewItems(items);
  }, [items]);

  const submitReview = useCallback(async (
    itemId: string,
    result: ReviewResult
  ) => {
    try {
      const item = items.find(i => i.id === itemId);
      if (!item) throw new Error('Item not found');

      const update: FSRSUpdate = processReview(item, result);

      // Update item in database
      await db.updateKnowledgeItem(itemId, {
        stability: update.stability,
        difficulty: update.difficulty,
        retrievability: update.retrievability,
        nextReview: update.nextReview,
        lastReview: update.lastReview,
        reviewCount: update.reviewCount,
        consecutiveCorrect: update.consecutiveCorrect,
      });

      // Update item in state
      setItems(prev => prev.map(i =>
        i.id === itemId
          ? {
              ...i,
              stability: update.stability,
              difficulty: update.difficulty,
              retrievability: update.retrievability,
              nextReview: update.nextReview,
              lastReview: update.lastReview,
              reviewCount: update.reviewCount,
              consecutiveCorrect: update.consecutiveCorrect,
            }
          : i
      ));

      // Update streak
      await db.checkAndUpdateStreak();

      // Update stats
      if (stats) {
        const newReviewCount = stats.totalReviewsCompleted + 1;
        const newEra = calculateAchievementEra(items);
        const masteredCount = items.filter(i =>
          i.reviewCount >= 15 && i.retrievability >= 0.90
        ).length;

        await db.updateUserStats({
          totalReviewsCompleted: newReviewCount,
          achievementEra: newEra,
          totalItemsMastered: masteredCount,
        });

        const updatedStats = await db.getOrCreateUserStats();
        setStats(updatedStats);
      }

      // Haptic feedback
      if (navigator.vibrate) {
        navigator.vibrate(result === 'gotIt' ? 50 : [30, 30, 30]);
      }

      return update;
    } catch (err) {
      setError('Failed to submit review');
      console.error('Submit review error:', err);
      throw err;
    }
  }, [items, stats]);

  // MARK: - Data Export/Import

  const exportData = useCallback(async () => {
    try {
      const data = await db.exportAllData();
      const json = JSON.stringify(data, null, 2);
      const blob = new Blob([json], { type: 'application/json' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `mindcity-backup-${new Date().toISOString().slice(0, 10)}.json`;
      a.click();
      URL.revokeObjectURL(url);
    } catch (err) {
      setError('Failed to export data');
      console.error('Export error:', err);
    }
  }, []);

  const importData = useCallback(async (file: File) => {
    try {
      const text = await file.text();
      const data = JSON.parse(text);
      await db.importData(data);
      await loadData();
    } catch (err) {
      setError('Failed to import data');
      console.error('Import error:', err);
    }
  }, [loadData]);

  return {
    // State
    items,
    buildings,
    stats,
    isLoading,
    error,
    setError,

    // Computed
    inboxItems,
    placedItems,
    dueItems,
    dueCount,

    // Operations
    addItem,
    deleteItem,
    placeBuilding,
    getReviewSession,
    submitReview,
    exportData,
    importData,
    loadData,
  };
}
