import SwiftUI
import SwiftData

struct StatsView: View {
    @Query private var items: [KnowledgeItem]
    @Query private var buildings: [Building]
    @Query private var stats: [UserStats]

    @State private var viewModel = StatsViewModel()

    private var userStats: UserStats? {
        stats.first
    }

    private var placedItems: [KnowledgeItem] {
        items.filter { $0.isPlaced }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Streak Section
                    streakSection

                    // Overview Stats
                    overviewSection

                    // Category Breakdown
                    categorySection

                    // Era Progress
                    eraProgressSection

                    // Activity Chart
                    activitySection
                }
                .padding()
            }
            .navigationTitle("Stats")
            .background(Color(.systemGroupedBackground))
        }
    }

    // MARK: - Streak Section

    private var streakSection: some View {
        VStack(spacing: 16) {
            if let stats = userStats {
                HStack(spacing: 24) {
                    // Current streak
                    VStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(.orange)
                            Text("\(stats.currentStreak)")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                        }

                        Text("Current Streak")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Divider()
                        .frame(height: 50)

                    // Longest streak
                    VStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: "trophy.fill")
                                .foregroundStyle(.yellow)
                            Text("\(stats.longestStreak)")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                        }

                        Text("Best Streak")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Streak message
                Text(viewModel.streakMessage(stats: stats))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                // Streak freeze indicator
                if stats.streakFreezeAvailable {
                    HStack(spacing: 6) {
                        Image(systemName: "snowflake")
                            .foregroundStyle(.cyan)

                        Text("Streak freeze available")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.cyan.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Overview Section

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Overview")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatCard(
                    icon: "tray.full",
                    iconColor: .blue,
                    value: "\(items.filter { !$0.isPlaced }.count)",
                    label: "In Inbox"
                )

                StatCard(
                    icon: "building.2",
                    iconColor: .purple,
                    value: "\(buildings.count)",
                    label: "Buildings"
                )

                StatCard(
                    icon: "bell.badge",
                    iconColor: .orange,
                    value: "\(viewModel.calculateDueCount(items: items))",
                    label: "Due Today"
                )

                StatCard(
                    icon: "star.fill",
                    iconColor: .yellow,
                    value: "\(viewModel.calculateMasteredCount(items: items))",
                    label: "Mastered"
                )

                StatCard(
                    icon: "chart.line.uptrend.xyaxis",
                    iconColor: .green,
                    value: "\(Int(viewModel.calculateRetentionRate(items: items) * 100))%",
                    label: "Retention"
                )

                StatCard(
                    icon: "arrow.trianglehead.2.counterclockwise.rotate.90",
                    iconColor: .teal,
                    value: "\(userStats?.totalReviewsCompleted ?? 0)",
                    label: "Reviews"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Category Section

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("By Category")
                .font(.headline)

            let categoryCounts = viewModel.itemsByCategory(items: items)

            ForEach(KnowledgeCategory.allCases, id: \.self) { category in
                let count = categoryCounts[category] ?? 0
                if count > 0 {
                    CategoryRow(
                        category: category,
                        count: count,
                        total: items.count
                    )
                }
            }

            if items.isEmpty {
                Text("No items yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Era Progress Section

    private var eraProgressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Era Progress")
                .font(.headline)

            if let stats = userStats {
                // Current era
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Era")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(stats.achievementEra.displayName)
                            .font(.title2)
                            .fontWeight(.semibold)
                    }

                    Spacer()

                    Image(systemName: eraIcon(for: stats.achievementEra))
                        .font(.largeTitle)
                        .foregroundStyle(eraColor(for: stats.achievementEra))
                }

                // Progress to next era
                if stats.achievementEra < Era.future {
                    let nextEra = Era(rawValue: stats.achievementEra.rawValue + 1) ?? .future
                    let masteredCount = viewModel.calculateMasteredCount(items: items)
                    let required = nextEra.requiredItemsAt80Percent
                    let progress = min(1.0, Double(masteredCount) / Double(required))

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Next: \(nextEra.displayName)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Spacer()

                            Text("\(masteredCount)/\(required)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color(.systemGray5))
                                    .frame(height: 8)
                                    .clipShape(Capsule())

                                Rectangle()
                                    .fill(eraColor(for: nextEra))
                                    .frame(width: geometry.size.width * progress, height: 8)
                                    .clipShape(Capsule())
                            }
                        }
                        .frame(height: 8)
                    }
                }

                // Era selection (display era)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Display Era")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Era.allCases, id: \.self) { era in
                                let isUnlocked = era <= stats.achievementEra
                                let isSelected = era == stats.displayEra

                                Button {
                                    if isUnlocked {
                                        stats.displayEra = era
                                        HapticService.shared.selectionChanged()
                                    }
                                } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: eraIcon(for: era))
                                            .font(.title3)
                                            .foregroundStyle(isUnlocked ? eraColor(for: era) : .gray)

                                        Text(era.displayName)
                                            .font(.caption2)
                                            .foregroundStyle(isUnlocked ? .primary : .secondary)
                                    }
                                    .frame(width: 60, height: 60)
                                    .background(isSelected ? eraColor(for: era).opacity(0.15) : Color(.systemGray6))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .strokeBorder(isSelected ? eraColor(for: era) : Color.clear, lineWidth: 2)
                                    )
                                    .opacity(isUnlocked ? 1.0 : 0.5)
                                }
                                .disabled(!isUnlocked)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Activity Section

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Last 7 Days")
                .font(.headline)

            let activity = viewModel.recentActivity(items: items, days: 7)
            let sortedDays = activity.keys.sorted()
            let maxCount = activity.values.max() ?? 1

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(sortedDays, id: \.self) { date in
                    let count = activity[date] ?? 0
                    let height = maxCount > 0 ? CGFloat(count) / CGFloat(maxCount) : 0

                    VStack(spacing: 4) {
                        Text("\(count)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(count > 0 ? Color.blue : Color(.systemGray5))
                            .frame(height: max(4, 60 * height))

                        Text(dayLabel(for: date))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 100)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Helpers

    private func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    private func eraIcon(for era: Era) -> String {
        switch era {
        case .stoneAge: return "mountain.2"
        case .ancient: return "building.columns"
        case .medieval: return "shield"
        case .renaissance: return "paintpalette"
        case .industrial: return "gear"
        case .modern: return "building.2"
        case .future: return "sparkles"
        }
    }

    private func eraColor(for era: Era) -> Color {
        switch era {
        case .stoneAge: return .brown
        case .ancient: return .orange
        case .medieval: return .gray
        case .renaissance: return .purple
        case .industrial: return .indigo
        case .modern: return .blue
        case .future: return .cyan
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(iconColor)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Category Row

struct CategoryRow: View {
    let category: KnowledgeCategory
    let count: Int
    let total: Int

    private var progress: Double {
        total > 0 ? Double(count) / Double(total) : 0
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: category.iconName)
                .font(.title3)
                .foregroundStyle(categoryColor)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(category.displayName)
                        .font(.subheadline)

                    Spacer()

                    Text("\(count)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .frame(height: 6)
                            .clipShape(Capsule())

                        Rectangle()
                            .fill(categoryColor)
                            .frame(width: geometry.size.width * progress, height: 6)
                            .clipShape(Capsule())
                    }
                }
                .frame(height: 6)
            }
        }
    }

    private var categoryColor: Color {
        switch category {
        case .philosophy: return .purple
        case .technical: return .blue
        case .creative: return .orange
        case .science: return .green
        case .personal: return .yellow
        case .general: return .gray
        }
    }
}

#Preview {
    StatsView()
        .modelContainer(for: [KnowledgeItem.self, Building.self, UserStats.self], inMemory: true)
}
