import XCTest
@testable import MindCity

/// Unit tests for FSRS v4 algorithm implementation
final class FSRSServiceTests: XCTestCase {

    // MARK: - Core Formula Tests

    /// Test that the core formula R(t,S) = (1 + t/(9×S))^(-1) is correctly implemented
    func testRetrievabilityFormula() {
        // At t=0, R should be 1.0 (just reviewed)
        XCTAssertEqual(FSRSService.calculateRetrievability(daysSinceReview: 0, stability: 1.0), 1.0, accuracy: 0.001)

        // With stability=1, at t=9 days, R = (1 + 9/(9×1))^(-1) = (1+1)^(-1) = 0.5
        XCTAssertEqual(FSRSService.calculateRetrievability(daysSinceReview: 9, stability: 1.0), 0.5, accuracy: 0.001)

        // With stability=10, at t=9 days, R = (1 + 9/(9×10))^(-1) = (1+0.1)^(-1) ≈ 0.909
        XCTAssertEqual(FSRSService.calculateRetrievability(daysSinceReview: 9, stability: 10.0), 0.909, accuracy: 0.01)

        // With stability=1, at t=18 days, R = (1 + 18/(9×1))^(-1) = (1+2)^(-1) = 0.333
        XCTAssertEqual(FSRSService.calculateRetrievability(daysSinceReview: 18, stability: 1.0), 0.333, accuracy: 0.01)
    }

    /// Test retrievability edge cases
    func testRetrievabilityEdgeCases() {
        // Zero stability should return 0 (guard clause)
        XCTAssertEqual(FSRSService.calculateRetrievability(daysSinceReview: 5, stability: 0), 0)

        // Negative stability should return 0
        XCTAssertEqual(FSRSService.calculateRetrievability(daysSinceReview: 5, stability: -1), 0)

        // Negative days should be treated as 0
        XCTAssertEqual(FSRSService.calculateRetrievability(daysSinceReview: -5, stability: 1.0), 1.0, accuracy: 0.001)

        // Very high stability should maintain high retrievability
        let highStabilityR = FSRSService.calculateRetrievability(daysSinceReview: 30, stability: 365)
        XCTAssertGreaterThan(highStabilityR, 0.95)
    }

    // MARK: - Next Review Date Tests

    /// Test that next review date is calculated correctly based on target retention
    func testDaysUntilTargetRetention() {
        // With 85% target retention and stability=1:
        // 0.85 = (1 + t/(9×1))^(-1)
        // 1 + t/9 = 1/0.85 = 1.176
        // t/9 = 0.176
        // t = 1.588 days
        let days = FSRSService.daysUntilTargetRetention(stability: 1.0)
        XCTAssertEqual(days, 1.588, accuracy: 0.01)

        // With stability=10:
        // t = 9 × 10 × (1/0.85 - 1) = 90 × 0.176 = 15.88 days
        let days10 = FSRSService.daysUntilTargetRetention(stability: 10.0)
        XCTAssertEqual(days10, 15.88, accuracy: 0.1)
    }

    func testNextReviewDateCalculation() {
        let now = Date()
        let nextReview = FSRSService.calculateNextReviewDate(stability: 1.0, from: now)

        // Should be approximately 1.6 days from now
        let interval = nextReview.timeIntervalSince(now)
        let days = interval / 86400
        XCTAssertEqual(days, 1.588, accuracy: 0.01)
    }

    // MARK: - First Review Tests

    /// Test first review with "Got it" rating
    func testFirstReviewGotIt() {
        let item = createTestItem()
        XCTAssertEqual(item.reviewCount, 0)
        XCTAssertEqual(item.stability, 1.0)
        XCTAssertEqual(item.difficulty, 5.0)

        let update = FSRSService.processReview(item: item, result: .gotIt)

        // Stability should increase
        XCTAssertGreaterThan(update.stability, 1.0)

        // Difficulty should stay near 5 (slight decrease for successful recall)
        XCTAssertLessThanOrEqual(update.difficulty, 5.0)
        XCTAssertGreaterThanOrEqual(update.difficulty, 1.0)

        // Review count incremented
        XCTAssertEqual(update.reviewCount, 1)

        // Consecutive correct incremented
        XCTAssertEqual(update.consecutiveCorrect, 1)

        // Next review should be in the future
        XCTAssertGreaterThan(update.nextReview, Date())
    }

    /// Test first review with "Forgot" rating
    func testFirstReviewForgot() {
        let item = createTestItem()

        let update = FSRSService.processReview(item: item, result: .forgot)

        // Stability should decrease (but floor at minimum)
        XCTAssertLessThanOrEqual(update.stability, 1.0)
        XCTAssertGreaterThanOrEqual(update.stability, FSRSService.minStability)

        // Difficulty should increase
        XCTAssertGreaterThan(update.difficulty, 5.0)

        // Consecutive correct reset
        XCTAssertEqual(update.consecutiveCorrect, 0)

        // Review count still incremented
        XCTAssertEqual(update.reviewCount, 1)
    }

    // MARK: - Subsequent Review Tests

    func testSubsequentReviewsIncreaseStability() {
        var item = createTestItem()
        var lastStability = item.stability

        // Simulate 5 consecutive correct reviews
        for _ in 1...5 {
            let update = FSRSService.processReview(item: item, result: .gotIt)
            update.apply(to: item)

            XCTAssertGreaterThan(item.stability, lastStability, "Stability should increase after correct review")
            lastStability = item.stability
        }

        // After 5 correct reviews, stability should be significantly higher
        XCTAssertGreaterThan(item.stability, 5.0)
    }

    func testForgotAfterHighStabilityDecreasesSignificantly() {
        var item = createTestItem()

        // Build up high stability
        for _ in 1...10 {
            let update = FSRSService.processReview(item: item, result: .gotIt)
            update.apply(to: item)
        }

        let stabilityBeforeFail = item.stability
        XCTAssertGreaterThan(stabilityBeforeFail, 10.0)

        // Now fail
        let update = FSRSService.processReview(item: item, result: .forgot)

        // Stability should drop significantly (at most 50% of previous)
        XCTAssertLessThanOrEqual(update.stability, stabilityBeforeFail * 0.5)
        XCTAssertGreaterThanOrEqual(update.stability, FSRSService.minStability)
    }

    // MARK: - Difficulty Bounds Tests

    func testDifficultyStaysWithinBounds() {
        var item = createTestItem()

        // Many consecutive failures should not push difficulty above 10
        for _ in 1...20 {
            let update = FSRSService.processReview(item: item, result: .forgot)
            update.apply(to: item)
            XCTAssertLessThanOrEqual(item.difficulty, 10.0)
            XCTAssertGreaterThanOrEqual(item.difficulty, 1.0)
        }

        // Reset and test lower bound
        item = createTestItem()
        item.difficulty = 2.0

        for _ in 1...20 {
            let update = FSRSService.processReview(item: item, result: .gotIt)
            update.apply(to: item)
            XCTAssertLessThanOrEqual(item.difficulty, 10.0)
            XCTAssertGreaterThanOrEqual(item.difficulty, 1.0)
        }
    }

    // MARK: - Stability Bounds Tests

    func testStabilityStaysWithinBounds() {
        var item = createTestItem()

        // Many successes should not exceed max stability
        for _ in 1...100 {
            let update = FSRSService.processReview(item: item, result: .gotIt)
            update.apply(to: item)
            XCTAssertLessThanOrEqual(item.stability, FSRSService.maxStability)
        }

        // Many failures should not go below min stability
        for _ in 1...50 {
            let update = FSRSService.processReview(item: item, result: .forgot)
            update.apply(to: item)
            XCTAssertGreaterThanOrEqual(item.stability, FSRSService.minStability)
        }
    }

    // MARK: - Retrievability at Various Intervals

    func testRetrievabilityAtCommonIntervals() {
        let stability: Double = 10.0

        // Day 0: Should be 1.0
        XCTAssertEqual(FSRSService.calculateRetrievability(daysSinceReview: 0, stability: stability), 1.0, accuracy: 0.001)

        // Day 1
        let r1 = FSRSService.calculateRetrievability(daysSinceReview: 1, stability: stability)
        XCTAssertGreaterThan(r1, 0.98)

        // Day 7
        let r7 = FSRSService.calculateRetrievability(daysSinceReview: 7, stability: stability)
        XCTAssertGreaterThan(r7, 0.92)

        // Day 30
        let r30 = FSRSService.calculateRetrievability(daysSinceReview: 30, stability: stability)
        XCTAssertGreaterThan(r30, 0.75)

        // Values should decrease over time
        XCTAssertGreaterThan(r1, r7)
        XCTAssertGreaterThan(r7, r30)
    }

    // MARK: - Session Selection Tests

    func testSelectReviewItemsFiltersPlaced() {
        let items = [
            createTestItem(isPlaced: true, isDue: true),
            createTestItem(isPlaced: false, isDue: true),  // Not placed - should be excluded
            createTestItem(isPlaced: true, isDue: false),  // Not due - should be excluded
            createTestItem(isPlaced: true, isDue: true),
        ]

        let selected = FSRSService.selectReviewItems(from: items)

        // Should only select placed AND due items
        XCTAssertEqual(selected.count, 2)
        XCTAssertTrue(selected.allSatisfy { $0.isPlaced && $0.isDue })
    }

    func testSelectReviewItemsRespectsMaxCount() {
        var items: [KnowledgeItem] = []
        for _ in 1...50 {
            items.append(createTestItem(isPlaced: true, isDue: true))
        }

        let selected = FSRSService.selectReviewItems(from: items, targetCount: 15, maxCount: 20)

        XCTAssertLessThanOrEqual(selected.count, 20)
    }

    func testQuickReviewSelectsFiveOrLess() {
        var items: [KnowledgeItem] = []
        for _ in 1...30 {
            items.append(createTestItem(isPlaced: true, isDue: true))
        }

        let selected = FSRSService.selectQuickReviewItems(from: items)

        XCTAssertLessThanOrEqual(selected.count, 5)
    }

    // MARK: - Era Calculation Tests

    func testEraCalculation() {
        // No items = Stone Age
        XCTAssertEqual(FSRSService.calculateAchievementEra(items: []), .stoneAge)

        // 50 items at 80%+ = Ancient
        var items: [KnowledgeItem] = []
        for _ in 1...50 {
            let item = createTestItem()
            item.retrievability = 0.85
            items.append(item)
        }
        XCTAssertEqual(FSRSService.calculateAchievementEra(items: items), .ancient)

        // 150 items at 80%+ = Medieval
        for _ in 1...100 {
            let item = createTestItem()
            item.retrievability = 0.85
            items.append(item)
        }
        XCTAssertEqual(FSRSService.calculateAchievementEra(items: items), .medieval)
    }

    // MARK: - Helper Methods

    private func createTestItem(isPlaced: Bool = false, isDue: Bool = true) -> KnowledgeItem {
        let item = KnowledgeItem(content: "Test content", category: .general)
        item.isPlaced = isPlaced
        if !isDue {
            item.nextReview = Date().addingTimeInterval(86400 * 7) // Due in 7 days
        }
        return item
    }
}

// MARK: - Model Tests

final class ModelTests: XCTestCase {

    func testKnowledgeItemDefaults() {
        let item = KnowledgeItem(content: "Test")

        XCTAssertEqual(item.stability, 1.0)
        XCTAssertEqual(item.difficulty, 5.0)
        XCTAssertEqual(item.reviewCount, 0)
        XCTAssertEqual(item.consecutiveCorrect, 0)
        XCTAssertEqual(item.retrievability, 1.0)
        XCTAssertFalse(item.isPlaced)
        XCTAssertNil(item.positionX)
        XCTAssertNil(item.positionY)
    }

    func testEvolutionLevels() {
        let item = KnowledgeItem(content: "Test")

        // 0-2 reviews = scaffolding
        item.reviewCount = 0
        XCTAssertEqual(item.evolutionLevel, .scaffolding)
        item.reviewCount = 2
        XCTAssertEqual(item.evolutionLevel, .scaffolding)

        // 3-7 reviews = basic
        item.reviewCount = 3
        XCTAssertEqual(item.evolutionLevel, .basic)
        item.reviewCount = 7
        XCTAssertEqual(item.evolutionLevel, .basic)

        // 8-15 reviews = polished (if < 90% retention)
        item.reviewCount = 8
        item.retrievability = 0.85
        XCTAssertEqual(item.evolutionLevel, .polished)

        // 15+ at 90%+ = landmark
        item.reviewCount = 16
        item.retrievability = 0.92
        XCTAssertEqual(item.evolutionLevel, .landmark)
    }

    func testIsMastered() {
        let item = KnowledgeItem(content: "Test")

        // Not mastered by default
        XCTAssertFalse(item.isMastered)

        // Need 15+ reviews AND 90%+ retention
        item.reviewCount = 14
        item.retrievability = 0.95
        XCTAssertFalse(item.isMastered)

        item.reviewCount = 15
        item.retrievability = 0.89
        XCTAssertFalse(item.isMastered)

        item.reviewCount = 15
        item.retrievability = 0.90
        XCTAssertTrue(item.isMastered)
    }

    func testDecayState() {
        let item = KnowledgeItem(content: "Test")
        item.isPlaced = true

        // Not placed = no decay
        item.isPlaced = false
        item.lastReview = Date().addingTimeInterval(-86400 * 10)
        XCTAssertEqual(item.decayState, .none)

        // Placed, reviewed recently = no decay
        item.isPlaced = true
        item.lastReview = Date().addingTimeInterval(-86400 * 1)
        XCTAssertEqual(item.decayState, .none)

        // Placed, 3-6 days = muted
        item.lastReview = Date().addingTimeInterval(-86400 * 4)
        XCTAssertEqual(item.decayState, .muted)

        // Placed, 7+ days = overgrown
        item.lastReview = Date().addingTimeInterval(-86400 * 8)
        XCTAssertEqual(item.decayState, .overgrown)
    }

    func testStreakLogic() {
        let stats = UserStats()

        // First review
        stats.checkAndUpdateStreak()
        XCTAssertEqual(stats.currentStreak, 1)
        XCTAssertEqual(stats.longestStreak, 1)

        // Same day - no change
        stats.checkAndUpdateStreak()
        XCTAssertEqual(stats.currentStreak, 1)

        // Simulate next day
        stats.lastReviewDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        stats.checkAndUpdateStreak()
        XCTAssertEqual(stats.currentStreak, 2)

        // Miss 3+ days - streak resets
        stats.lastReviewDate = Calendar.current.date(byAdding: .day, value: -5, to: Date())
        stats.checkAndUpdateStreak()
        XCTAssertEqual(stats.currentStreak, 1)
    }

    func testStreakFreeze() {
        let stats = UserStats()
        stats.currentStreak = 5
        stats.longestStreak = 5
        stats.streakFreezeAvailable = true

        // Miss exactly 2 days (yesterday skipped, reviewing today)
        stats.lastReviewDate = Calendar.current.date(byAdding: .day, value: -2, to: Date())
        stats.checkAndUpdateStreak()

        // Streak should be preserved via freeze
        XCTAssertEqual(stats.currentStreak, 6)
        XCTAssertFalse(stats.streakFreezeAvailable)
        XCTAssertTrue(stats.streakFreezeUsedToday)
    }
}
