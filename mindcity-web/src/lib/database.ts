import Dexie, { Table } from 'dexie';
import { KnowledgeItem, Building, UserStats } from './types';
import { v4 as uuidv4 } from 'uuid';

// Database schema for IndexedDB
class MindCityDatabase extends Dexie {
  items!: Table<KnowledgeItem>;
  buildings!: Table<Building>;
  stats!: Table<UserStats>;

  constructor() {
    super('MindCityDB');
    this.version(1).stores({
      items: 'id, category, isPlaced, nextReview, createdAt',
      buildings: 'id, positionX, positionY, knowledgeItemId',
      stats: 'id',
    });
  }
}

export const db = new MindCityDatabase();

// MARK: - Knowledge Item Operations

export async function createKnowledgeItem(
  content: string,
  contentType: KnowledgeItem['contentType'] = 'text',
  category: KnowledgeItem['category'] = 'general',
  tags: string[] = [],
  sourceURL?: string,
  imageData?: string
): Promise<KnowledgeItem> {
  const now = new Date();
  const item: KnowledgeItem = {
    id: uuidv4(),
    content,
    contentType,
    category,
    tags,
    sourceURL,
    imageData,
    createdAt: now,
    updatedAt: now,
    // FSRS defaults
    stability: 1.0,
    difficulty: 5.0,
    lastReview: undefined,
    nextReview: now, // Due immediately for first review
    retrievability: 1.0,
    reviewCount: 0,
    consecutiveCorrect: 0,
    // Not placed initially
    isPlaced: false,
    positionX: undefined,
    positionY: undefined,
    buildingId: undefined,
  };

  await db.items.add(item);
  return item;
}

export async function updateKnowledgeItem(
  id: string,
  updates: Partial<KnowledgeItem>
): Promise<void> {
  await db.items.update(id, {
    ...updates,
    updatedAt: new Date(),
  });
}

export async function deleteKnowledgeItem(id: string): Promise<void> {
  const item = await db.items.get(id);
  if (item?.buildingId) {
    await db.buildings.delete(item.buildingId);
  }
  await db.items.delete(id);
}

export async function getKnowledgeItem(id: string): Promise<KnowledgeItem | undefined> {
  return db.items.get(id);
}

export async function getAllKnowledgeItems(): Promise<KnowledgeItem[]> {
  return db.items.toArray();
}

export async function getInboxItems(): Promise<KnowledgeItem[]> {
  return db.items.filter(item => !item.isPlaced).toArray();
}

export async function getPlacedItems(): Promise<KnowledgeItem[]> {
  return db.items.filter(item => item.isPlaced).toArray();
}

export async function getDueItems(): Promise<KnowledgeItem[]> {
  const now = new Date();
  return db.items
    .filter(item => item.isPlaced && new Date(item.nextReview) <= now)
    .toArray();
}

// MARK: - Building Operations

export async function createBuilding(
  buildingType: Building['buildingType'],
  positionX: number,
  positionY: number,
  knowledgeItemId?: string,
  name?: string
): Promise<Building> {
  const building: Building = {
    id: uuidv4(),
    name,
    buildingType,
    createdAt: new Date(),
    positionX,
    positionY,
    knowledgeItemId,
  };

  await db.buildings.add(building);

  // Link building to knowledge item if provided
  if (knowledgeItemId) {
    await db.items.update(knowledgeItemId, {
      isPlaced: true,
      positionX,
      positionY,
      buildingId: building.id,
    });
  }

  return building;
}

export async function getBuilding(id: string): Promise<Building | undefined> {
  return db.buildings.get(id);
}

export async function getAllBuildings(): Promise<Building[]> {
  return db.buildings.toArray();
}

export async function deleteBuilding(id: string): Promise<void> {
  const building = await db.buildings.get(id);
  if (building?.knowledgeItemId) {
    await db.items.update(building.knowledgeItemId, {
      isPlaced: false,
      positionX: undefined,
      positionY: undefined,
      buildingId: undefined,
    });
  }
  await db.buildings.delete(id);
}

export async function isCellOccupied(gridX: number, gridY: number): Promise<boolean> {
  const buildings = await db.buildings.toArray();
  return buildings.some(b => {
    const bGridX = Math.floor(b.positionX / 60);
    const bGridY = Math.floor(b.positionY / 60);
    return bGridX === gridX && bGridY === gridY;
  });
}

// MARK: - User Stats Operations

const DEFAULT_STATS_ID = 'user-stats';

export async function getOrCreateUserStats(): Promise<UserStats> {
  let stats = await db.stats.get(DEFAULT_STATS_ID);

  if (!stats) {
    stats = {
      id: DEFAULT_STATS_ID,
      currentStreak: 0,
      longestStreak: 0,
      lastReviewDate: undefined,
      streakFreezeAvailable: true,
      streakFreezeUsedToday: false,
      achievementEra: 'stoneAge',
      displayEra: 'stoneAge',
      totalItemsAdded: 0,
      totalItemsMastered: 0,
      totalReviewsCompleted: 0,
    };
    await db.stats.add(stats);
  }

  return stats;
}

export async function updateUserStats(updates: Partial<UserStats>): Promise<void> {
  await db.stats.update(DEFAULT_STATS_ID, updates);
}

export async function checkAndUpdateStreak(): Promise<void> {
  const stats = await getOrCreateUserStats();
  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());

  if (!stats.lastReviewDate) {
    // First review ever
    await updateUserStats({
      currentStreak: 1,
      longestStreak: Math.max(stats.longestStreak, 1),
      lastReviewDate: now,
    });
    return;
  }

  const lastReview = new Date(stats.lastReviewDate);
  const lastReviewDay = new Date(
    lastReview.getFullYear(),
    lastReview.getMonth(),
    lastReview.getDate()
  );

  const daysDiff = Math.floor(
    (today.getTime() - lastReviewDay.getTime()) / (24 * 60 * 60 * 1000)
  );

  if (daysDiff === 0) {
    // Already reviewed today, no change
    return;
  } else if (daysDiff === 1) {
    // Consecutive day - increment streak
    const newStreak = stats.currentStreak + 1;
    await updateUserStats({
      currentStreak: newStreak,
      longestStreak: Math.max(stats.longestStreak, newStreak),
      lastReviewDate: now,
    });
  } else if (daysDiff === 2 && stats.streakFreezeAvailable && !stats.streakFreezeUsedToday) {
    // Missed one day - use freeze
    const newStreak = stats.currentStreak + 1;
    await updateUserStats({
      streakFreezeUsedToday: true,
      streakFreezeAvailable: false,
      currentStreak: newStreak,
      longestStreak: Math.max(stats.longestStreak, newStreak),
      lastReviewDate: now,
    });
  } else {
    // Streak broken
    await updateUserStats({
      currentStreak: 1,
      lastReviewDate: now,
    });
  }
}

// MARK: - Export/Import

export async function exportAllData(): Promise<{
  items: KnowledgeItem[];
  buildings: Building[];
  stats: UserStats;
}> {
  const items = await db.items.toArray();
  const buildings = await db.buildings.toArray();
  const stats = await getOrCreateUserStats();

  return { items, buildings, stats };
}

export async function importData(data: {
  items: KnowledgeItem[];
  buildings: Building[];
  stats: UserStats;
}): Promise<void> {
  await db.transaction('rw', [db.items, db.buildings, db.stats], async () => {
    await db.items.clear();
    await db.buildings.clear();
    await db.stats.clear();

    await db.items.bulkAdd(data.items);
    await db.buildings.bulkAdd(data.buildings);
    await db.stats.add(data.stats);
  });
}
