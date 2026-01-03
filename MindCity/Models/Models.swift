import Foundation
import SwiftData

// MARK: - Enums

enum ContentType: String, Codable, CaseIterable {
    case text
    case quote
    case image
    case diagram
    case link
    case voice

    var iconName: String {
        switch self {
        case .text: return "doc.text"
        case .quote: return "quote.opening"
        case .image: return "photo"
        case .diagram: return "chart.bar.doc.horizontal"
        case .link: return "link"
        case .voice: return "waveform"
        }
    }

    var displayName: String {
        switch self {
        case .text: return "Note"
        case .quote: return "Quote"
        case .image: return "Image"
        case .diagram: return "Diagram"
        case .link: return "Link"
        case .voice: return "Voice"
        }
    }
}

enum KnowledgeCategory: String, Codable, CaseIterable {
    case philosophy
    case technical
    case creative
    case science
    case personal
    case general

    var displayName: String {
        switch self {
        case .philosophy: return "Philosophy & Wisdom"
        case .technical: return "Technical & Code"
        case .creative: return "Creative & Art"
        case .science: return "Science & Facts"
        case .personal: return "Personal & Goals"
        case .general: return "General"
        }
    }

    var iconName: String {
        switch self {
        case .philosophy: return "brain.head.profile"
        case .technical: return "hammer"
        case .creative: return "paintpalette"
        case .science: return "atom"
        case .personal: return "star"
        case .general: return "square.grid.2x2"
        }
    }

    var color: String {
        switch self {
        case .philosophy: return "purple"
        case .technical: return "blue"
        case .creative: return "orange"
        case .science: return "green"
        case .personal: return "yellow"
        case .general: return "gray"
        }
    }
}

enum BuildingType: String, Codable, CaseIterable {
    // Philosophy
    case temple
    case garden
    case library

    // Technical
    case workshop
    case laboratory
    case forge

    // Creative
    case studio
    case gallery
    case theater

    // Science
    case observatory
    case museum
    case researchCenter

    // Personal
    case monument
    case milestone
    case shrine

    // General
    case house
    case tower
    case archive

    var category: KnowledgeCategory {
        switch self {
        case .temple, .garden, .library:
            return .philosophy
        case .workshop, .laboratory, .forge:
            return .technical
        case .studio, .gallery, .theater:
            return .creative
        case .observatory, .museum, .researchCenter:
            return .science
        case .monument, .milestone, .shrine:
            return .personal
        case .house, .tower, .archive:
            return .general
        }
    }

    var displayName: String {
        switch self {
        case .temple: return "Temple"
        case .garden: return "Garden"
        case .library: return "Library"
        case .workshop: return "Workshop"
        case .laboratory: return "Laboratory"
        case .forge: return "Forge"
        case .studio: return "Studio"
        case .gallery: return "Gallery"
        case .theater: return "Theater"
        case .observatory: return "Observatory"
        case .museum: return "Museum"
        case .researchCenter: return "Research Center"
        case .monument: return "Monument"
        case .milestone: return "Milestone"
        case .shrine: return "Shrine"
        case .house: return "House"
        case .tower: return "Tower"
        case .archive: return "Archive"
        }
    }

    var iconName: String {
        switch self {
        case .temple: return "building.columns"
        case .garden: return "leaf"
        case .library: return "books.vertical"
        case .workshop: return "wrench.and.screwdriver"
        case .laboratory: return "flask"
        case .forge: return "flame"
        case .studio: return "paintbrush"
        case .gallery: return "photo.artframe"
        case .theater: return "theatermasks"
        case .observatory: return "moon.stars"
        case .museum: return "building.2"
        case .researchCenter: return "magnifyingglass"
        case .monument: return "obelisk"
        case .milestone: return "flag"
        case .shrine: return "sparkles"
        case .house: return "house"
        case .tower: return "building"
        case .archive: return "archivebox"
        }
    }

    static func buildingTypes(for category: KnowledgeCategory) -> [BuildingType] {
        allCases.filter { $0.category == category }
    }
}

enum Era: Int, Codable, CaseIterable, Comparable {
    case stoneAge = 0
    case ancient = 1
    case medieval = 2
    case renaissance = 3
    case industrial = 4
    case modern = 5
    case future = 6

    var displayName: String {
        switch self {
        case .stoneAge: return "Stone Age"
        case .ancient: return "Ancient"
        case .medieval: return "Medieval"
        case .renaissance: return "Renaissance"
        case .industrial: return "Industrial"
        case .modern: return "Modern"
        case .future: return "Future"
        }
    }

    var requiredItemsAt80Percent: Int {
        switch self {
        case .stoneAge: return 0
        case .ancient: return 50
        case .medieval: return 150
        case .renaissance: return 300
        case .industrial: return 500
        case .modern: return 800
        case .future: return 1200
        }
    }

    var requiredRetention: Double {
        switch self {
        case .future: return 0.85
        default: return 0.80
        }
    }

    var themeColor: String {
        switch self {
        case .stoneAge: return "brown"
        case .ancient: return "cream"
        case .medieval: return "stone"
        case .renaissance: return "gold"
        case .industrial: return "iron"
        case .modern: return "steel"
        case .future: return "holographic"
        }
    }

    static func < (lhs: Era, rhs: Era) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

enum EvolutionLevel: Int, Codable, CaseIterable {
    case scaffolding = 0    // 0-2 reviews
    case basic = 1          // 3-7 reviews
    case polished = 2       // 8-15 reviews at 80%+
    case landmark = 3       // 15+ reviews at 90%+

    var displayName: String {
        switch self {
        case .scaffolding: return "Under Construction"
        case .basic: return "Established"
        case .polished: return "Flourishing"
        case .landmark: return "Landmark"
        }
    }

    var opacity: Double {
        switch self {
        case .scaffolding: return 0.6
        case .basic: return 0.8
        case .polished: return 0.95
        case .landmark: return 1.0
        }
    }

    var scale: Double {
        switch self {
        case .scaffolding: return 0.85
        case .basic: return 1.0
        case .polished: return 1.1
        case .landmark: return 1.2
        }
    }
}

// MARK: - SwiftData Models

@Model
final class KnowledgeItem {
    var id: UUID
    var content: String
    var contentType: ContentType
    var category: KnowledgeCategory
    var tags: [String]
    var sourceURL: String?
    var imageData: Data?
    var createdAt: Date
    var updatedAt: Date

    // FSRS Fields
    var stability: Double           // Days for retention to drop 100%→90%
    var difficulty: Double          // Scale 1-10, default 5
    var lastReview: Date?
    var nextReview: Date
    var retrievability: Double      // Probability of recall (0-1)
    var reviewCount: Int
    var consecutiveCorrect: Int     // Streak of consecutive correct recalls

    // Spatial Fields
    var isPlaced: Bool
    var positionX: Double?
    var positionY: Double?

    @Relationship(deleteRule: .cascade, inverse: \Building.knowledgeItem)
    var building: Building?

    init(
        content: String,
        contentType: ContentType = .text,
        category: KnowledgeCategory = .general,
        tags: [String] = [],
        sourceURL: String? = nil,
        imageData: Data? = nil
    ) {
        self.id = UUID()
        self.content = content
        self.contentType = contentType
        self.category = category
        self.tags = tags
        self.sourceURL = sourceURL
        self.imageData = imageData
        self.createdAt = Date()
        self.updatedAt = Date()

        // FSRS defaults for new items
        self.stability = 1.0
        self.difficulty = 5.0
        self.lastReview = nil
        self.nextReview = Date()  // Due immediately for first review
        self.retrievability = 1.0
        self.reviewCount = 0
        self.consecutiveCorrect = 0

        // Not placed initially
        self.isPlaced = false
        self.positionX = nil
        self.positionY = nil
        self.building = nil
    }

    var isDue: Bool {
        nextReview <= Date()
    }

    var evolutionLevel: EvolutionLevel {
        if reviewCount <= 2 {
            return .scaffolding
        } else if reviewCount <= 7 {
            return .basic
        } else if reviewCount <= 15 || retrievability < 0.90 {
            return .polished
        } else {
            return .landmark
        }
    }

    var isMastered: Bool {
        reviewCount >= 15 && retrievability >= 0.90
    }

    var daysSinceLastReview: Double {
        guard let lastReview = lastReview else { return 0 }
        return Date().timeIntervalSince(lastReview) / 86400.0
    }

    var decayState: DecayState {
        guard isPlaced else { return .none }
        let days = daysSinceLastReview
        if days < 3 { return .none }
        if days < 7 { return .muted }
        return .overgrown
    }
}

enum DecayState {
    case none
    case muted      // 3+ days: Muted colors, slight dust
    case overgrown  // 7+ days: Overgrowth, "paused in time"

    var overlayOpacity: Double {
        switch self {
        case .none: return 0
        case .muted: return 0.2
        case .overgrown: return 0.4
        }
    }
}

@Model
final class Building {
    var id: UUID
    var name: String?
    var buildingType: BuildingType
    var positionX: Double
    var positionY: Double
    var createdAt: Date

    var knowledgeItem: KnowledgeItem?

    init(
        buildingType: BuildingType,
        positionX: Double,
        positionY: Double,
        name: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.buildingType = buildingType
        self.positionX = positionX
        self.positionY = positionY
        self.createdAt = Date()
    }

    var evolutionLevel: EvolutionLevel {
        knowledgeItem?.evolutionLevel ?? .scaffolding
    }

    var displayName: String {
        name ?? buildingType.displayName
    }
}

@Model
final class UserStats {
    var id: UUID
    var currentStreak: Int
    var longestStreak: Int
    var lastReviewDate: Date?
    var streakFreezeAvailable: Bool
    var streakFreezeUsedToday: Bool
    var achievementEra: Era
    var displayEra: Era
    var totalItemsAdded: Int
    var totalItemsMastered: Int
    var totalReviewsCompleted: Int

    init() {
        self.id = UUID()
        self.currentStreak = 0
        self.longestStreak = 0
        self.lastReviewDate = nil
        self.streakFreezeAvailable = true
        self.streakFreezeUsedToday = false
        self.achievementEra = .stoneAge
        self.displayEra = .stoneAge
        self.totalItemsAdded = 0
        self.totalItemsMastered = 0
        self.totalReviewsCompleted = 0
    }

    var canMaintainStreak: Bool {
        guard let lastReview = lastReviewDate else { return true }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastReviewDay = calendar.startOfDay(for: lastReview)
        let daysDiff = calendar.dateComponents([.day], from: lastReviewDay, to: today).day ?? 0
        return daysDiff <= 1
    }

    var hasReviewedToday: Bool {
        guard let lastReview = lastReviewDate else { return false }
        return Calendar.current.isDateInToday(lastReview)
    }

    func checkAndUpdateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        guard let lastReview = lastReviewDate else {
            // First review ever
            currentStreak = 1
            longestStreak = max(longestStreak, 1)
            lastReviewDate = Date()
            return
        }

        let lastReviewDay = calendar.startOfDay(for: lastReview)
        let daysDiff = calendar.dateComponents([.day], from: lastReviewDay, to: today).day ?? 0

        switch daysDiff {
        case 0:
            // Already reviewed today, no change
            break
        case 1:
            // Consecutive day - increment streak
            currentStreak += 1
            longestStreak = max(longestStreak, currentStreak)
            lastReviewDate = Date()
        case 2:
            // Missed one day - use freeze if available
            if streakFreezeAvailable && !streakFreezeUsedToday {
                streakFreezeUsedToday = true
                streakFreezeAvailable = false
                currentStreak += 1
                longestStreak = max(longestStreak, currentStreak)
            } else {
                currentStreak = 1
            }
            lastReviewDate = Date()
        default:
            // Streak broken
            currentStreak = 1
            lastReviewDate = Date()
        }
    }

    func resetDailyFreeze() {
        streakFreezeUsedToday = false
        // Freeze replenishes after 7 days of streak
        if currentStreak >= 7 && !streakFreezeAvailable {
            streakFreezeAvailable = true
        }
    }
}

// MARK: - Review Result

enum ReviewResult {
    case gotIt
    case forgot

    var isCorrect: Bool {
        self == .gotIt
    }
}
