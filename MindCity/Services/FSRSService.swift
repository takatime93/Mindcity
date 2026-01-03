import Foundation

// MARK: - FSRS v4 Algorithm
//
// Free Spaced Repetition Scheduler (FSRS) is a modern spaced repetition algorithm
// that outperforms the classic SM-2 algorithm used by Anki.
//
// ## Core Concepts
//
// 1. **Retrievability (R)**: The probability of successfully recalling an item.
//    Starts at 1.0 after review and decays over time following the forgetting curve.
//
// 2. **Stability (S)**: How long (in days) it takes for retrievability to drop
//    from 100% to 90%. Higher stability = slower forgetting = longer intervals.
//
// 3. **Difficulty (D)**: How inherently hard an item is to remember (1-10 scale).
//    Affects how much stability increases on successful recall.
//
// ## The Formula
//
// ```
// R(t, S) = (1 + t/(9×S))^(-1)
// ```
//
// Where:
// - t = days since last review
// - S = stability in days
// - 9 = the decay factor (determines curve shape)
//
// This power-law forgetting curve matches empirical memory research better than
// exponential decay used in older algorithms.
//
// ## Example
//
// With stability S=10 days:
// - Day 0:  R = 100% (just reviewed)
// - Day 5:  R = 95%
// - Day 10: R = 90%
// - Day 20: R = 82%
// - Day 50: R = 64%
//
// ## Two-Button Simplification
//
// MindCity uses a simplified 2-button system ("Got it" / "Forgot"):
// - "Got it": Increases stability, slightly decreases difficulty
// - "Forgot": Decreases stability significantly, increases difficulty
//
// This reduces cognitive load while maintaining algorithm effectiveness.

/// FSRS v4 (Free Spaced Repetition Scheduler) implementation
/// Core formula: R(t,S) = (1 + t/(9×S))^(-1)
/// Where:
///   R = retrievability (probability of recall, 0-1)
///   t = days since last review
///   S = stability (days for retention to drop from 100% to 90%)
final class FSRSService {
    // MARK: - Constants

    /// Target retention rate (user-adjustable 80-95%)
    static let targetRetention: Double = 0.85

    /// Factor in the FSRS formula: R = (1 + t/(factor×S))^(-1)
    private static let decayFactor: Double = 9.0

    /// Default difficulty for new items (scale 1-10)
    static let defaultDifficulty: Double = 5.0

    /// Initial stability for new items (in days)
    static let initialStability: Double = 1.0

    /// Maximum stability cap (in days)
    static let maxStability: Double = 365.0

    /// Minimum stability floor (in days)
    static let minStability: Double = 0.1

    // MARK: - FSRS v4 Parameters (optimized defaults)

    /// Weights for stability calculation after successful recall
    private static let successWeights: (base: Double, difficultyMod: Double, stabilityMod: Double) = (
        base: 1.0,
        difficultyMod: -0.1,
        stabilityMod: 0.5
    )

    /// Weights for stability calculation after failed recall
    private static let failureWeights: (base: Double, difficultyMod: Double, stabilityMod: Double) = (
        base: 0.2,
        difficultyMod: -0.05,
        stabilityMod: 0.1
    )

    // MARK: - Core Calculations

    /// Calculate retrievability (probability of recall) using FSRS formula
    /// R(t,S) = (1 + t/(9×S))^(-1)
    static func calculateRetrievability(daysSinceReview: Double, stability: Double) -> Double {
        guard stability > 0 else { return 0 }
        let t = max(0, daysSinceReview)
        let denominator = 1.0 + (t / (decayFactor * stability))
        return pow(denominator, -1)
    }

    /// Calculate days until retrievability drops to target retention
    static func daysUntilTargetRetention(stability: Double, targetRetention: Double = targetRetention) -> Double {
        // Solve for t: targetRetention = (1 + t/(9×S))^(-1)
        // (1 + t/(9S)) = targetRetention^(-1)
        // t/(9S) = targetRetention^(-1) - 1
        // t = 9S × (targetRetention^(-1) - 1)
        guard targetRetention > 0 && targetRetention < 1 else { return 0 }
        return decayFactor * stability * (pow(targetRetention, -1) - 1)
    }

    /// Calculate next review date based on current stability
    static func calculateNextReviewDate(stability: Double, from date: Date = Date()) -> Date {
        let days = daysUntilTargetRetention(stability: stability)
        return Calendar.current.date(byAdding: .second, value: Int(days * 86400), to: date) ?? date
    }

    // MARK: - Review Processing

    /// Process a review result and return updated FSRS parameters
    static func processReview(
        item: KnowledgeItem,
        result: ReviewResult
    ) -> FSRSUpdate {
        let now = Date()
        let daysSinceReview = item.daysSinceLastReview

        // Calculate current retrievability before this review
        let currentRetrievability = calculateRetrievability(
            daysSinceReview: daysSinceReview,
            stability: item.stability
        )

        // Update parameters based on result
        let newDifficulty: Double
        let newStability: Double
        let newConsecutiveCorrect: Int

        switch result {
        case .gotIt:
            // Successful recall - increase stability, adjust difficulty down slightly
            newDifficulty = updateDifficultyOnSuccess(
                currentDifficulty: item.difficulty,
                retrievability: currentRetrievability
            )
            newStability = updateStabilityOnSuccess(
                currentStability: item.stability,
                difficulty: newDifficulty,
                retrievability: currentRetrievability
            )
            newConsecutiveCorrect = item.consecutiveCorrect + 1

        case .forgot:
            // Failed recall - decrease stability significantly, adjust difficulty up
            newDifficulty = updateDifficultyOnFailure(
                currentDifficulty: item.difficulty
            )
            newStability = updateStabilityOnFailure(
                currentStability: item.stability,
                difficulty: newDifficulty
            )
            newConsecutiveCorrect = 0
        }

        // Calculate new retrievability (will be ~1.0 right after review)
        let newRetrievability = calculateRetrievability(
            daysSinceReview: 0,
            stability: newStability
        )

        // Calculate next review date
        let nextReview = calculateNextReviewDate(stability: newStability, from: now)

        return FSRSUpdate(
            stability: newStability,
            difficulty: newDifficulty,
            retrievability: newRetrievability,
            nextReview: nextReview,
            lastReview: now,
            reviewCount: item.reviewCount + 1,
            consecutiveCorrect: newConsecutiveCorrect
        )
    }

    // MARK: - Stability Updates

    /// Update stability after successful recall
    private static func updateStabilityOnSuccess(
        currentStability: Double,
        difficulty: Double,
        retrievability: Double
    ) -> Double {
        // FSRS v4 stability increase formula
        // S' = S × (1 + e^(factor) × (11 - D) × S^(-0.2) × (e^(w×(1-R)) - 1))
        // Simplified version for 2-button:
        let difficultyFactor = (11 - difficulty) / 10.0  // Higher = easier = bigger boost
        let stabilityDecay = pow(currentStability, -0.2)  // Diminishing returns on high stability
        let retrievabilityBonus = 2.0 - retrievability  // Harder recalls = bigger boost

        let multiplier = 1.0 + (difficultyFactor * stabilityDecay * retrievabilityBonus)
        let newStability = currentStability * max(1.1, min(multiplier, 3.0))

        return min(maxStability, max(minStability, newStability))
    }

    /// Update stability after failed recall
    private static func updateStabilityOnFailure(
        currentStability: Double,
        difficulty: Double
    ) -> Double {
        // FSRS v4 stability decrease - much more punitive than increase
        // Relearn from a lower base, but not all the way to zero
        let difficultyFactor = difficulty / 10.0  // Higher difficulty = more stability loss
        let retentionFactor = 0.3 + (0.2 * (1 - difficultyFactor))

        let newStability = currentStability * retentionFactor

        // Floor at minimum stability to allow quick re-learning
        return max(minStability, min(newStability, currentStability * 0.5))
    }

    // MARK: - Difficulty Updates

    /// Update difficulty after successful recall
    private static func updateDifficultyOnSuccess(
        currentDifficulty: Double,
        retrievability: Double
    ) -> Double {
        // Easy recall (high retrievability) = decrease difficulty more
        // Hard recall (low retrievability) = small decrease or none
        let adjustment = (retrievability - 0.5) * 0.5  // Range: -0.25 to +0.25
        let newDifficulty = currentDifficulty - adjustment

        return min(10.0, max(1.0, newDifficulty))
    }

    /// Update difficulty after failed recall
    private static func updateDifficultyOnFailure(
        currentDifficulty: Double
    ) -> Double {
        // Failed recall increases difficulty
        let newDifficulty = currentDifficulty + 0.5

        return min(10.0, max(1.0, newDifficulty))
    }

    // MARK: - Session Selection

    /// Select items for a review session with variety balancing
    static func selectReviewItems(
        from items: [KnowledgeItem],
        targetCount: Int = 15,
        maxCount: Int = 20
    ) -> [KnowledgeItem] {
        // Filter to due items (placed items that need review)
        let dueItems = items.filter { $0.isPlaced && $0.isDue }

        guard !dueItems.isEmpty else { return [] }

        // Sort by urgency (how overdue + lower stability = more urgent)
        let sortedByUrgency = dueItems.sorted { item1, item2 in
            let urgency1 = calculateUrgency(item: item1)
            let urgency2 = calculateUrgency(item: item2)
            return urgency1 > urgency2
        }

        // Take top candidates (2x target to allow variety balancing)
        let candidates = Array(sortedByUrgency.prefix(maxCount * 2))

        // Apply variety balancing (Spotify-style shuffle for category diversity)
        let balanced = balanceForVariety(items: candidates, targetCount: min(targetCount, candidates.count))

        return Array(balanced.prefix(maxCount))
    }

    /// Calculate urgency score for prioritization
    private static func calculateUrgency(item: KnowledgeItem) -> Double {
        let overdueDays = max(0, -item.nextReview.timeIntervalSinceNow / 86400)
        let stabilityFactor = 1.0 / max(0.1, item.stability)
        let retrievability = calculateRetrievability(
            daysSinceReview: item.daysSinceLastReview,
            stability: item.stability
        )

        // Lower retrievability = more urgent
        // More overdue = more urgent
        // Lower stability = more urgent (fragile memories need more attention)
        return overdueDays + (1 - retrievability) * 10 + stabilityFactor
    }

    /// Balance items for category variety (prevents clustering)
    private static func balanceForVariety(
        items: [KnowledgeItem],
        targetCount: Int
    ) -> [KnowledgeItem] {
        guard items.count > 1 else { return items }

        var result: [KnowledgeItem] = []
        var remaining = items
        var lastCategory: KnowledgeCategory?

        while result.count < targetCount && !remaining.isEmpty {
            // Find items with different category than last added
            let differentCategory = remaining.filter { $0.category != lastCategory }

            if let next = differentCategory.first {
                result.append(next)
                remaining.removeAll { $0.id == next.id }
                lastCategory = next.category
            } else if let next = remaining.first {
                // Fall back to same category if no alternatives
                result.append(next)
                remaining.removeAll { $0.id == next.id }
                lastCategory = next.category
            }
        }

        return result
    }

    // MARK: - Quick Review Mode

    /// Select items for a quick "just 5" review session
    static func selectQuickReviewItems(from items: [KnowledgeItem]) -> [KnowledgeItem] {
        return selectReviewItems(from: items, targetCount: 5, maxCount: 5)
    }
}

// MARK: - FSRS Update Result

struct FSRSUpdate {
    let stability: Double
    let difficulty: Double
    let retrievability: Double
    let nextReview: Date
    let lastReview: Date
    let reviewCount: Int
    let consecutiveCorrect: Int

    /// Apply this update to a KnowledgeItem
    func apply(to item: KnowledgeItem) {
        item.stability = stability
        item.difficulty = difficulty
        item.retrievability = retrievability
        item.nextReview = nextReview
        item.lastReview = lastReview
        item.reviewCount = reviewCount
        item.consecutiveCorrect = consecutiveCorrect
        item.updatedAt = Date()
    }
}

// MARK: - Era Calculation

extension FSRSService {
    /// Calculate the era a user should have based on mastered items
    static func calculateAchievementEra(
        items: [KnowledgeItem]
    ) -> Era {
        let masteredAt80 = items.filter { $0.retrievability >= 0.80 }.count
        let masteredAt85 = items.filter { $0.retrievability >= 0.85 }.count

        // Check eras from highest to lowest
        if masteredAt85 >= Era.future.requiredItemsAt80Percent {
            return .future
        }

        for era in Era.allCases.reversed() {
            if era == .future { continue }
            if masteredAt80 >= era.requiredItemsAt80Percent {
                return era
            }
        }

        return .stoneAge
    }
}
