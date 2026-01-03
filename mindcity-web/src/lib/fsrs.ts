import { KnowledgeItem, ReviewResult, Era, EraOrder } from './types';

/**
 * FSRS v4 (Free Spaced Repetition Scheduler) Implementation
 *
 * Core formula: R(t,S) = (1 + t/(9*S))^(-1)
 *
 * Where:
 *   R = retrievability (probability of recall, 0-1)
 *   t = days since last review
 *   S = stability (days for retention to drop from 100% to 90%)
 *
 * This power-law forgetting curve matches empirical memory research better than
 * exponential decay used in older algorithms like SM-2.
 */

// MARK: - Constants

/** Target retention rate (user-adjustable 80-95%) */
export const TARGET_RETENTION = 0.85;

/** Factor in the FSRS formula: R = (1 + t/(factor*S))^(-1) */
const DECAY_FACTOR = 9.0;

/** Default difficulty for new items (scale 1-10) */
export const DEFAULT_DIFFICULTY = 5.0;

/** Initial stability for new items (in days) */
export const INITIAL_STABILITY = 1.0;

/** Maximum stability cap (in days) */
export const MAX_STABILITY = 365.0;

/** Minimum stability floor (in days) */
export const MIN_STABILITY = 0.1;

// MARK: - Core Calculations

/**
 * Calculate retrievability (probability of recall) using FSRS formula
 * R(t,S) = (1 + t/(9*S))^(-1)
 */
export function calculateRetrievability(daysSinceReview: number, stability: number): number {
  if (stability <= 0) return 0;
  const t = Math.max(0, daysSinceReview);
  const denominator = 1.0 + (t / (DECAY_FACTOR * stability));
  return Math.pow(denominator, -1);
}

/**
 * Calculate days until retrievability drops to target retention
 */
export function daysUntilTargetRetention(stability: number, targetRetention: number = TARGET_RETENTION): number {
  // Solve for t: targetRetention = (1 + t/(9*S))^(-1)
  // (1 + t/(9S)) = targetRetention^(-1)
  // t/(9S) = targetRetention^(-1) - 1
  // t = 9S * (targetRetention^(-1) - 1)
  if (targetRetention <= 0 || targetRetention >= 1) return 0;
  return DECAY_FACTOR * stability * (Math.pow(targetRetention, -1) - 1);
}

/**
 * Calculate next review date based on current stability
 */
export function calculateNextReviewDate(stability: number, from: Date = new Date()): Date {
  const days = daysUntilTargetRetention(stability);
  const ms = days * 24 * 60 * 60 * 1000;
  return new Date(from.getTime() + ms);
}

// MARK: - Stability Updates

/**
 * Update stability after successful recall
 */
function updateStabilityOnSuccess(
  currentStability: number,
  difficulty: number,
  retrievability: number
): number {
  // FSRS v4 stability increase formula (simplified for 2-button)
  const difficultyFactor = (11 - difficulty) / 10.0; // Higher = easier = bigger boost
  const stabilityDecay = Math.pow(currentStability, -0.2); // Diminishing returns
  const retrievabilityBonus = 2.0 - retrievability; // Harder recalls = bigger boost

  const multiplier = 1.0 + (difficultyFactor * stabilityDecay * retrievabilityBonus);
  const newStability = currentStability * Math.max(1.1, Math.min(multiplier, 3.0));

  return Math.min(MAX_STABILITY, Math.max(MIN_STABILITY, newStability));
}

/**
 * Update stability after failed recall
 */
function updateStabilityOnFailure(currentStability: number, difficulty: number): number {
  // FSRS v4 stability decrease - much more punitive than increase
  const difficultyFactor = difficulty / 10.0;
  const retentionFactor = 0.3 + (0.2 * (1 - difficultyFactor));

  const newStability = currentStability * retentionFactor;

  return Math.max(MIN_STABILITY, Math.min(newStability, currentStability * 0.5));
}

// MARK: - Difficulty Updates

/**
 * Update difficulty after successful recall
 */
function updateDifficultyOnSuccess(currentDifficulty: number, retrievability: number): number {
  // Easy recall (high retrievability) = decrease difficulty more
  const adjustment = (retrievability - 0.5) * 0.5;
  const newDifficulty = currentDifficulty - adjustment;
  return Math.min(10.0, Math.max(1.0, newDifficulty));
}

/**
 * Update difficulty after failed recall
 */
function updateDifficultyOnFailure(currentDifficulty: number): number {
  const newDifficulty = currentDifficulty + 0.5;
  return Math.min(10.0, Math.max(1.0, newDifficulty));
}

// MARK: - FSRS Update Result

export interface FSRSUpdate {
  stability: number;
  difficulty: number;
  retrievability: number;
  nextReview: Date;
  lastReview: Date;
  reviewCount: number;
  consecutiveCorrect: number;
}

// MARK: - Review Processing

/**
 * Process a review result and return updated FSRS parameters
 */
export function processReview(item: KnowledgeItem, result: ReviewResult): FSRSUpdate {
  const now = new Date();
  const daysSinceReview = item.lastReview
    ? (now.getTime() - new Date(item.lastReview).getTime()) / (24 * 60 * 60 * 1000)
    : 0;

  // Calculate current retrievability before this review
  const currentRetrievability = calculateRetrievability(daysSinceReview, item.stability);

  let newDifficulty: number;
  let newStability: number;
  let newConsecutiveCorrect: number;

  if (result === 'gotIt') {
    // Successful recall - increase stability, adjust difficulty down slightly
    newDifficulty = updateDifficultyOnSuccess(item.difficulty, currentRetrievability);
    newStability = updateStabilityOnSuccess(item.stability, newDifficulty, currentRetrievability);
    newConsecutiveCorrect = item.consecutiveCorrect + 1;
  } else {
    // Failed recall - decrease stability significantly, adjust difficulty up
    newDifficulty = updateDifficultyOnFailure(item.difficulty);
    newStability = updateStabilityOnFailure(item.stability, newDifficulty);
    newConsecutiveCorrect = 0;
  }

  // Calculate new retrievability (will be ~1.0 right after review)
  const newRetrievability = calculateRetrievability(0, newStability);

  // Calculate next review date
  const nextReview = calculateNextReviewDate(newStability, now);

  return {
    stability: newStability,
    difficulty: newDifficulty,
    retrievability: newRetrievability,
    nextReview,
    lastReview: now,
    reviewCount: item.reviewCount + 1,
    consecutiveCorrect: newConsecutiveCorrect,
  };
}

// MARK: - Session Selection

/**
 * Calculate urgency score for prioritization
 */
function calculateUrgency(item: KnowledgeItem): number {
  const now = new Date();
  const nextReviewTime = new Date(item.nextReview).getTime();
  const overdueDays = Math.max(0, (now.getTime() - nextReviewTime) / (24 * 60 * 60 * 1000));
  const stabilityFactor = 1.0 / Math.max(0.1, item.stability);

  const daysSinceReview = item.lastReview
    ? (now.getTime() - new Date(item.lastReview).getTime()) / (24 * 60 * 60 * 1000)
    : 0;
  const retrievability = calculateRetrievability(daysSinceReview, item.stability);

  // Lower retrievability = more urgent
  // More overdue = more urgent
  // Lower stability = more urgent (fragile memories need more attention)
  return overdueDays + (1 - retrievability) * 10 + stabilityFactor;
}

/**
 * Balance items for category variety (prevents clustering)
 */
function balanceForVariety(items: KnowledgeItem[], targetCount: number): KnowledgeItem[] {
  if (items.length <= 1) return items;

  const result: KnowledgeItem[] = [];
  let remaining = [...items];
  let lastCategory: string | null = null;

  while (result.length < targetCount && remaining.length > 0) {
    // Find items with different category than last added
    const differentCategory = remaining.filter(item => item.category !== lastCategory);

    if (differentCategory.length > 0) {
      const next = differentCategory[0];
      result.push(next);
      remaining = remaining.filter(item => item.id !== next.id);
      lastCategory = next.category;
    } else if (remaining.length > 0) {
      // Fall back to same category if no alternatives
      const next = remaining[0];
      result.push(next);
      remaining = remaining.filter(item => item.id !== next.id);
      lastCategory = next.category;
    }
  }

  return result;
}

/**
 * Select items for a review session with variety balancing
 */
export function selectReviewItems(
  items: KnowledgeItem[],
  targetCount: number = 15,
  maxCount: number = 20
): KnowledgeItem[] {
  const now = new Date();

  // Filter to due items (placed items that need review)
  const dueItems = items.filter(item =>
    item.isPlaced && new Date(item.nextReview) <= now
  );

  if (dueItems.length === 0) return [];

  // Sort by urgency (how overdue + lower stability = more urgent)
  const sortedByUrgency = [...dueItems].sort((a, b) => {
    return calculateUrgency(b) - calculateUrgency(a);
  });

  // Take top candidates (2x target to allow variety balancing)
  const candidates = sortedByUrgency.slice(0, maxCount * 2);

  // Apply variety balancing
  const balanced = balanceForVariety(candidates, Math.min(targetCount, candidates.length));

  return balanced.slice(0, maxCount);
}

/**
 * Select items for a quick "just 5" review session
 */
export function selectQuickReviewItems(items: KnowledgeItem[]): KnowledgeItem[] {
  return selectReviewItems(items, 5, 5);
}

// MARK: - Era Calculation

/**
 * Calculate the era a user should have based on mastered items
 */
export function calculateAchievementEra(items: KnowledgeItem[]): Era {
  const masteredAt80 = items.filter(item => item.retrievability >= 0.80).length;
  const masteredAt85 = items.filter(item => item.retrievability >= 0.85).length;

  // Check for future era (requires 85% retention)
  if (masteredAt85 >= 1200) return 'future';

  // Check eras from highest to lowest
  for (let i = EraOrder.length - 2; i >= 0; i--) {
    const era = EraOrder[i];
    const required = era === 'stoneAge' ? 0 :
      era === 'ancient' ? 50 :
      era === 'medieval' ? 150 :
      era === 'renaissance' ? 300 :
      era === 'industrial' ? 500 :
      era === 'modern' ? 800 : 0;

    if (masteredAt80 >= required) return era;
  }

  return 'stoneAge';
}
