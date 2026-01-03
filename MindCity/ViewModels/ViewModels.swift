import Foundation
import SwiftUI
import SwiftData

// MARK: - Capture ViewModel

@MainActor
@Observable
final class CaptureViewModel {
    var content: String = ""
    var contentType: ContentType = .text
    var category: KnowledgeCategory = .general
    var tags: [String] = []
    var tagInput: String = ""
    var sourceURL: String = ""
    var imageData: Data?
    var isShowingImagePicker: Bool = false
    var isSaving: Bool = false
    var showSaveConfirmation: Bool = false

    var isValid: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func addTag() {
        let tag = tagInput.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !tag.isEmpty && !tags.contains(tag) {
            tags.append(tag)
            HapticService.shared.lightTap()
        }
        tagInput = ""
    }

    func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
        HapticService.shared.lightTap()
    }

    func save(context: ModelContext, stats: UserStats) -> Bool {
        guard isValid else {
            HapticService.shared.error()
            return false
        }

        isSaving = true

        let item = KnowledgeItem(
            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
            contentType: contentType,
            category: category,
            tags: tags,
            sourceURL: sourceURL.isEmpty ? nil : sourceURL,
            imageData: imageData
        )

        context.insert(item)

        // Update stats
        stats.totalItemsAdded += 1

        do {
            try context.save()
            HapticService.shared.knowledgeCaptured()
            showSaveConfirmation = true
            reset()
            isSaving = false
            return true
        } catch {
            HapticService.shared.error()
            isSaving = false
            return false
        }
    }

    func reset() {
        content = ""
        contentType = .text
        category = .general
        tags = []
        tagInput = ""
        sourceURL = ""
        imageData = nil
    }
}

// MARK: - Inbox ViewModel

@MainActor
@Observable
final class InboxViewModel {
    var selectedItem: KnowledgeItem?
    var selectedBuildingType: BuildingType?
    var isShowingBuildingPicker: Bool = false
    var isShowingPlacementView: Bool = false
    var placementPosition: CGPoint?

    var availableBuildingTypes: [BuildingType] {
        guard let item = selectedItem else { return [] }
        return BuildingType.buildingTypes(for: item.category)
    }

    func selectItemForPlacement(_ item: KnowledgeItem) {
        selectedItem = item
        selectedBuildingType = availableBuildingTypes.first
        isShowingBuildingPicker = true
        HapticService.shared.lightTap()
    }

    func selectBuildingType(_ type: BuildingType) {
        selectedBuildingType = type
        HapticService.shared.selectionChanged()
    }

    func confirmBuildingType() {
        guard selectedBuildingType != nil else { return }
        isShowingBuildingPicker = false
        isShowingPlacementView = true
        HapticService.shared.mediumTap()
    }

    func placeBuilding(
        at position: CGPoint,
        context: ModelContext
    ) -> Bool {
        guard let item = selectedItem,
              let buildingType = selectedBuildingType else {
            HapticService.shared.error()
            return false
        }

        // Create building
        let building = Building(
            buildingType: buildingType,
            positionX: Double(position.x),
            positionY: Double(position.y)
        )

        // Link item to building
        item.isPlaced = true
        item.positionX = Double(position.x)
        item.positionY = Double(position.y)
        item.building = building
        building.knowledgeItem = item

        context.insert(building)

        do {
            try context.save()
            HapticService.shared.buildingPlaced()
            reset()
            return true
        } catch {
            HapticService.shared.error()
            return false
        }
    }

    func reset() {
        selectedItem = nil
        selectedBuildingType = nil
        isShowingBuildingPicker = false
        isShowingPlacementView = false
        placementPosition = nil
    }

    func cancelPlacement() {
        reset()
        HapticService.shared.modalDismissed()
    }
}

// MARK: - Review ViewModel

@MainActor
@Observable
final class ReviewViewModel {
    var reviewItems: [KnowledgeItem] = []
    var currentIndex: Int = 0
    var isShowingContent: Bool = false
    var isSessionActive: Bool = false
    var isSessionComplete: Bool = false

    // Session stats
    var correctCount: Int = 0
    var incorrectCount: Int = 0
    var sessionStartTime: Date?

    var currentItem: KnowledgeItem? {
        guard currentIndex < reviewItems.count else { return nil }
        return reviewItems[currentIndex]
    }

    var progress: Double {
        guard !reviewItems.isEmpty else { return 0 }
        return Double(currentIndex) / Double(reviewItems.count)
    }

    var remainingCount: Int {
        max(0, reviewItems.count - currentIndex)
    }

    func startSession(items: [KnowledgeItem], quickMode: Bool = false) {
        let selectedItems = quickMode
            ? FSRSService.selectQuickReviewItems(from: items)
            : FSRSService.selectReviewItems(from: items)

        guard !selectedItems.isEmpty else {
            HapticService.shared.warning()
            return
        }

        reviewItems = selectedItems
        currentIndex = 0
        isShowingContent = false
        isSessionActive = true
        isSessionComplete = false
        correctCount = 0
        incorrectCount = 0
        sessionStartTime = Date()

        HapticService.shared.mediumTap()
    }

    func revealContent() {
        isShowingContent = true
        HapticService.shared.cardFlip()
    }

    func submitReview(
        result: ReviewResult,
        context: ModelContext,
        stats: UserStats
    ) {
        guard let item = currentItem else { return }

        // Process with FSRS
        let update = FSRSService.processReview(item: item, result: result)
        update.apply(to: item)

        // Update session stats
        if result.isCorrect {
            correctCount += 1
            HapticService.shared.reviewCorrect()
        } else {
            incorrectCount += 1
            HapticService.shared.reviewIncorrect()
        }

        // Update user stats
        stats.totalReviewsCompleted += 1
        if item.isMastered && result.isCorrect {
            stats.totalItemsMastered = max(stats.totalItemsMastered, item.reviewCount)
        }

        // Move to next item
        currentIndex += 1
        isShowingContent = false

        if currentIndex >= reviewItems.count {
            completeSession(context: context, stats: stats)
        } else {
            HapticService.shared.swipe()
        }

        try? context.save()
    }

    private func completeSession(context: ModelContext, stats: UserStats) {
        isSessionComplete = true
        isSessionActive = false

        // Update streak
        stats.checkAndUpdateStreak()

        // Check for era progression
        // This would need access to all items to calculate properly
        // Handled in the view with @Query

        HapticService.shared.walkCompleted()
        try? context.save()
    }

    func endSession() {
        isSessionActive = false
        isSessionComplete = false
        reviewItems = []
        currentIndex = 0
        HapticService.shared.modalDismissed()
    }

    func skipToNext() {
        guard currentIndex < reviewItems.count - 1 else { return }
        currentIndex += 1
        isShowingContent = false
        HapticService.shared.swipe()
    }

    func goToPrevious() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
        isShowingContent = false
        HapticService.shared.swipe()
    }
}

// MARK: - City ViewModel

@MainActor
@Observable
final class CityViewModel {
    var scale: CGFloat = 1.0
    var offset: CGSize = .zero
    var selectedBuilding: Building?
    var isShowingBuildingDetail: Bool = false

    // Grid settings
    let gridSize: CGFloat = 60
    let citySize: CGFloat = 2000  // Total city canvas size

    var minScale: CGFloat = 0.3
    var maxScale: CGFloat = 3.0

    func selectBuilding(_ building: Building) {
        selectedBuilding = building
        isShowingBuildingDetail = true
        HapticService.shared.mediumTap()
    }

    func deselectBuilding() {
        selectedBuilding = nil
        isShowingBuildingDetail = false
        HapticService.shared.lightTap()
    }

    func zoomIn() {
        withAnimation(.spring(response: 0.3)) {
            scale = min(maxScale, scale * 1.5)
        }
        HapticService.shared.lightTap()
    }

    func zoomOut() {
        withAnimation(.spring(response: 0.3)) {
            scale = max(minScale, scale / 1.5)
        }
        HapticService.shared.lightTap()
    }

    func resetView() {
        withAnimation(.spring(response: 0.4)) {
            scale = 1.0
            offset = .zero
        }
        HapticService.shared.mediumTap()
    }

    func updateScale(_ newScale: CGFloat) {
        scale = min(maxScale, max(minScale, newScale))
    }

    func updateOffset(_ newOffset: CGSize) {
        offset = newOffset
    }

    // Find available position for new building
    func findAvailablePosition(existingBuildings: [Building]) -> CGPoint {
        let occupiedPositions = Set(existingBuildings.map { GridPosition(x: Int($0.positionX / Double(gridSize)), y: Int($0.positionY / Double(gridSize))) })

        // Spiral outward from center to find empty spot
        let centerX = Int(citySize / 2 / gridSize)
        let centerY = Int(citySize / 2 / gridSize)

        for radius in 0..<50 {
            for dx in -radius...radius {
                for dy in -radius...radius {
                    if abs(dx) == radius || abs(dy) == radius {
                        let pos = GridPosition(x: centerX + dx, y: centerY + dy)
                        if !occupiedPositions.contains(pos) {
                            return CGPoint(
                                x: CGFloat(pos.x) * gridSize + gridSize / 2,
                                y: CGFloat(pos.y) * gridSize + gridSize / 2
                            )
                        }
                    }
                }
            }
        }

        // Fallback to center if somehow all positions taken
        return CGPoint(x: citySize / 2, y: citySize / 2)
    }

    func snapToGrid(_ point: CGPoint) -> CGPoint {
        let x = round(point.x / gridSize) * gridSize + gridSize / 2
        let y = round(point.y / gridSize) * gridSize + gridSize / 2
        return CGPoint(x: x, y: y)
    }

    func isPositionOccupied(_ point: CGPoint, existingBuildings: [Building]) -> Bool {
        let gridX = Int(point.x / gridSize)
        let gridY = Int(point.y / gridSize)

        return existingBuildings.contains { building in
            let buildingGridX = Int(building.positionX / Double(gridSize))
            let buildingGridY = Int(building.positionY / Double(gridSize))
            return buildingGridX == gridX && buildingGridY == gridY
        }
    }
}

private struct GridPosition: Hashable {
    let x: Int
    let y: Int
}

// MARK: - Stats ViewModel

@MainActor
@Observable
final class StatsViewModel {
    var selectedTimeRange: TimeRange = .week

    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
        case allTime = "All Time"
    }

    func calculateRetentionRate(items: [KnowledgeItem]) -> Double {
        let placedItems = items.filter { $0.isPlaced }
        guard !placedItems.isEmpty else { return 0 }

        let totalRetrievability = placedItems.reduce(0.0) { $0 + $1.retrievability }
        return totalRetrievability / Double(placedItems.count)
    }

    func calculateDueCount(items: [KnowledgeItem]) -> Int {
        items.filter { $0.isPlaced && $0.isDue }.count
    }

    func calculateMasteredCount(items: [KnowledgeItem]) -> Int {
        items.filter { $0.isMastered }.count
    }

    func itemsByCategory(items: [KnowledgeItem]) -> [KnowledgeCategory: Int] {
        var counts: [KnowledgeCategory: Int] = [:]
        for category in KnowledgeCategory.allCases {
            counts[category] = items.filter { $0.category == category }.count
        }
        return counts
    }

    func recentActivity(items: [KnowledgeItem], days: Int = 7) -> [Date: Int] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        var activity: [Date: Int] = [:]

        for dayOffset in 0..<days {
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate) {
                let dayStart = calendar.startOfDay(for: date)
                activity[dayStart] = 0
            }
        }

        for item in items {
            if let lastReview = item.lastReview,
               lastReview >= startDate {
                let dayStart = calendar.startOfDay(for: lastReview)
                activity[dayStart, default: 0] += 1
            }
        }

        return activity
    }

    func formatStreak(_ count: Int) -> String {
        if count == 0 { return "No streak" }
        if count == 1 { return "1 day" }
        return "\(count) days"
    }

    func streakMessage(stats: UserStats) -> String {
        if stats.currentStreak == 0 {
            return "Start your streak today!"
        } else if stats.currentStreak >= 7 {
            return "You're on fire! 🔥"
        } else if stats.currentStreak >= 3 {
            return "Great momentum!"
        } else {
            return "Keep it going!"
        }
    }
}

// MARK: - App State ViewModel

@MainActor
@Observable
final class AppStateViewModel {
    var selectedTab: AppTab = .city
    var isShowingCapture: Bool = false
    var isShowingReview: Bool = false

    enum AppTab: Int, CaseIterable {
        case city = 0
        case inbox = 1
        case stats = 2

        var title: String {
            switch self {
            case .city: return "City"
            case .inbox: return "Inbox"
            case .stats: return "Stats"
            }
        }

        var iconName: String {
            switch self {
            case .city: return "building.2"
            case .inbox: return "tray"
            case .stats: return "chart.bar"
            }
        }
    }

    func switchTab(to tab: AppTab) {
        selectedTab = tab
        HapticService.shared.tabSwitch()
    }

    func showCapture() {
        isShowingCapture = true
        HapticService.shared.modalPresented()
    }

    func hideCapture() {
        isShowingCapture = false
        HapticService.shared.modalDismissed()
    }

    func showReview() {
        isShowingReview = true
        HapticService.shared.modalPresented()
    }

    func hideReview() {
        isShowingReview = false
        HapticService.shared.modalDismissed()
    }
}
