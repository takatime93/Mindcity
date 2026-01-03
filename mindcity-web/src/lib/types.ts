// MARK: - Enums

export type ContentType = 'text' | 'quote' | 'image' | 'diagram' | 'link' | 'voice';

export const ContentTypeInfo: Record<ContentType, { icon: string; displayName: string }> = {
  text: { icon: 'file-text', displayName: 'Note' },
  quote: { icon: 'quote', displayName: 'Quote' },
  image: { icon: 'image', displayName: 'Image' },
  diagram: { icon: 'bar-chart', displayName: 'Diagram' },
  link: { icon: 'link', displayName: 'Link' },
  voice: { icon: 'mic', displayName: 'Voice' },
};

export type KnowledgeCategory = 'philosophy' | 'technical' | 'creative' | 'science' | 'personal' | 'general';

export const CategoryInfo: Record<KnowledgeCategory, { displayName: string; icon: string; color: string }> = {
  philosophy: { displayName: 'Philosophy & Wisdom', icon: 'brain', color: '#9333EA' },
  technical: { displayName: 'Technical & Code', icon: 'wrench', color: '#3B82F6' },
  creative: { displayName: 'Creative & Art', icon: 'palette', color: '#F97316' },
  science: { displayName: 'Science & Facts', icon: 'atom', color: '#22C55E' },
  personal: { displayName: 'Personal & Goals', icon: 'star', color: '#EAB308' },
  general: { displayName: 'General', icon: 'grid', color: '#6B7280' },
};

export type BuildingType =
  // Philosophy
  | 'temple' | 'garden' | 'library'
  // Technical
  | 'workshop' | 'laboratory' | 'forge'
  // Creative
  | 'studio' | 'gallery' | 'theater'
  // Science
  | 'observatory' | 'museum' | 'researchCenter'
  // Personal
  | 'monument' | 'milestone' | 'shrine'
  // General
  | 'house' | 'tower' | 'archive';

export const BuildingTypeInfo: Record<BuildingType, { category: KnowledgeCategory; displayName: string; icon: string }> = {
  temple: { category: 'philosophy', displayName: 'Temple', icon: 'building-columns' },
  garden: { category: 'philosophy', displayName: 'Garden', icon: 'leaf' },
  library: { category: 'philosophy', displayName: 'Library', icon: 'books' },
  workshop: { category: 'technical', displayName: 'Workshop', icon: 'wrench' },
  laboratory: { category: 'technical', displayName: 'Laboratory', icon: 'flask' },
  forge: { category: 'technical', displayName: 'Forge', icon: 'flame' },
  studio: { category: 'creative', displayName: 'Studio', icon: 'paintbrush' },
  gallery: { category: 'creative', displayName: 'Gallery', icon: 'frame' },
  theater: { category: 'creative', displayName: 'Theater', icon: 'masks' },
  observatory: { category: 'science', displayName: 'Observatory', icon: 'moon' },
  museum: { category: 'science', displayName: 'Museum', icon: 'building' },
  researchCenter: { category: 'science', displayName: 'Research Center', icon: 'search' },
  monument: { category: 'personal', displayName: 'Monument', icon: 'obelisk' },
  milestone: { category: 'personal', displayName: 'Milestone', icon: 'flag' },
  shrine: { category: 'personal', displayName: 'Shrine', icon: 'sparkles' },
  house: { category: 'general', displayName: 'House', icon: 'home' },
  tower: { category: 'general', displayName: 'Tower', icon: 'building' },
  archive: { category: 'general', displayName: 'Archive', icon: 'archive' },
};

export type Era = 'stoneAge' | 'ancient' | 'medieval' | 'renaissance' | 'industrial' | 'modern' | 'future';

export const EraInfo: Record<Era, { displayName: string; requiredItems: number; themeColor: string }> = {
  stoneAge: { displayName: 'Stone Age', requiredItems: 0, themeColor: '#8B4513' },
  ancient: { displayName: 'Ancient', requiredItems: 50, themeColor: '#F5F5DC' },
  medieval: { displayName: 'Medieval', requiredItems: 150, themeColor: '#808080' },
  renaissance: { displayName: 'Renaissance', requiredItems: 300, themeColor: '#FFD700' },
  industrial: { displayName: 'Industrial', requiredItems: 500, themeColor: '#4A4A4A' },
  modern: { displayName: 'Modern', requiredItems: 800, themeColor: '#C0C0C0' },
  future: { displayName: 'Future', requiredItems: 1200, themeColor: '#00FFFF' },
};

export const EraOrder: Era[] = ['stoneAge', 'ancient', 'medieval', 'renaissance', 'industrial', 'modern', 'future'];

export type EvolutionLevel = 'scaffolding' | 'basic' | 'polished' | 'landmark';

export const EvolutionInfo: Record<EvolutionLevel, { displayName: string; opacity: number; scale: number }> = {
  scaffolding: { displayName: 'Under Construction', opacity: 0.6, scale: 0.85 },
  basic: { displayName: 'Established', opacity: 0.8, scale: 1.0 },
  polished: { displayName: 'Flourishing', opacity: 0.95, scale: 1.1 },
  landmark: { displayName: 'Landmark', opacity: 1.0, scale: 1.2 },
};

export type DecayState = 'none' | 'muted' | 'overgrown';

export type ReviewResult = 'gotIt' | 'forgot';

// MARK: - Models

export interface KnowledgeItem {
  id: string;
  content: string;
  contentType: ContentType;
  category: KnowledgeCategory;
  tags: string[];
  sourceURL?: string;
  imageData?: string; // Base64 encoded
  createdAt: Date;
  updatedAt: Date;

  // FSRS Fields
  stability: number;
  difficulty: number;
  lastReview?: Date;
  nextReview: Date;
  retrievability: number;
  reviewCount: number;
  consecutiveCorrect: number;

  // Spatial Fields
  isPlaced: boolean;
  positionX?: number;
  positionY?: number;
  buildingId?: string;
}

export interface Building {
  id: string;
  name?: string;
  buildingType: BuildingType;
  createdAt: Date;
  // IMMUTABLE after creation - spatial positions never change
  positionX: number;
  positionY: number;
  knowledgeItemId?: string;
}

export interface UserStats {
  id: string;
  currentStreak: number;
  longestStreak: number;
  lastReviewDate?: Date;
  streakFreezeAvailable: boolean;
  streakFreezeUsedToday: boolean;
  achievementEra: Era;
  displayEra: Era;
  totalItemsAdded: number;
  totalItemsMastered: number;
  totalReviewsCompleted: number;
}

// MARK: - Helpers

export function getEvolutionLevel(reviewCount: number, retrievability: number): EvolutionLevel {
  if (reviewCount <= 2) return 'scaffolding';
  if (reviewCount <= 7) return 'basic';
  if (reviewCount <= 15 || retrievability < 0.90) return 'polished';
  return 'landmark';
}

export function getDecayState(daysSinceLastReview: number, isPlaced: boolean): DecayState {
  if (!isPlaced) return 'none';
  if (daysSinceLastReview < 3) return 'none';
  if (daysSinceLastReview < 7) return 'muted';
  return 'overgrown';
}

export function getBuildingTypesForCategory(category: KnowledgeCategory): BuildingType[] {
  return (Object.keys(BuildingTypeInfo) as BuildingType[])
    .filter(type => BuildingTypeInfo[type].category === category);
}
