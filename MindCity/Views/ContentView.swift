import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var stats: [UserStats]

    @State private var appState = AppStateViewModel()
    @State private var showingCapture = false
    @State private var showingReview = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // Main tab content
            TabView(selection: $appState.selectedTab) {
                CityView(showReview: $showingReview)
                    .tag(AppStateViewModel.AppTab.city)

                InboxView()
                    .tag(AppStateViewModel.AppTab.inbox)

                StatsView()
                    .tag(AppStateViewModel.AppTab.stats)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Custom tab bar
            CustomTabBar(
                selectedTab: $appState.selectedTab,
                onCapturePressed: {
                    showingCapture = true
                    HapticService.shared.modalPresented()
                }
            )
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showingCapture) {
            CaptureView()
        }
        .fullScreenCover(isPresented: $showingReview) {
            ReviewView()
        }
        .onAppear {
            setupAppearance()
            resetDailyFreezeIfNeeded()
        }
    }

    private func setupAppearance() {
        // Prepare haptics
        HapticService.shared.prepareAll()
    }

    private func resetDailyFreezeIfNeeded() {
        guard let userStats = stats.first else { return }

        // Check if it's a new day
        if let lastReview = userStats.lastReviewDate {
            if !Calendar.current.isDateInToday(lastReview) {
                userStats.streakFreezeUsedToday = false
            }
        }
    }
}

// MARK: - Custom Tab Bar

struct CustomTabBar: View {
    @Binding var selectedTab: AppStateViewModel.AppTab
    let onCapturePressed: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            // City tab
            TabBarButton(
                icon: "building.2",
                title: "City",
                isSelected: selectedTab == .city
            ) {
                selectedTab = .city
                HapticService.shared.tabSwitch()
            }

            // Capture button (center)
            CaptureButton(action: onCapturePressed)
                .offset(y: -20)

            // Inbox tab
            TabBarButton(
                icon: "tray",
                title: "Inbox",
                isSelected: selectedTab == .inbox
            ) {
                selectedTab = .inbox
                HapticService.shared.tabSwitch()
            }

            // Stats tab
            TabBarButton(
                icon: "chart.bar",
                title: "Stats",
                isSelected: selectedTab == .stats
            ) {
                selectedTab = .stats
                HapticService.shared.tabSwitch()
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 24)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, y: -5)
                .ignoresSafeArea()
        )
    }
}

// MARK: - Tab Bar Button

struct TabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)
                    .symbolVariant(isSelected ? .fill : .none)

                Text(title)
                    .font(.caption2)
            }
            .foregroundStyle(isSelected ? .blue : .secondary)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Capture Button

struct CaptureButton: View {
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .shadow(color: .blue.opacity(0.4), radius: 10, y: 5)

                Image(systemName: "plus")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
            }
            .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.spring(response: 0.2)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.2)) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - Home View (Alternative to CityView for first-run experience)

struct HomeView: View {
    @Query private var items: [KnowledgeItem]
    @Query private var buildings: [Building]
    @Query private var stats: [UserStats]

    @Binding var showReview: Bool

    private var userStats: UserStats? {
        stats.first
    }

    private var inboxCount: Int {
        items.filter { !$0.isPlaced }.count
    }

    private var dueCount: Int {
        items.filter { $0.isPlaced && $0.isDue }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Welcome header
                    welcomeHeader

                    // Quick actions
                    quickActions

                    // Stats overview
                    statsOverview

                    // Recent activity
                    recentActivity
                }
                .padding()
            }
            .navigationTitle("MindCity")
            .background(Color(.systemGroupedBackground))
        }
    }

    private var welcomeHeader: some View {
        VStack(spacing: 8) {
            if let stats = userStats {
                if stats.currentStreak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                        Text("\(stats.currentStreak) day streak")
                            .fontWeight(.medium)
                    }
                    .font(.subheadline)
                }
            }

            Text(greeting)
                .font(.title2)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())

        if hour < 12 {
            return "Good morning!"
        } else if hour < 17 {
            return "Good afternoon!"
        } else {
            return "Good evening!"
        }
    }

    private var quickActions: some View {
        HStack(spacing: 12) {
            // Review action
            if dueCount > 0 {
                QuickActionCard(
                    icon: "figure.walk",
                    iconColor: .blue,
                    title: "Start Walk",
                    subtitle: "\(dueCount) items due"
                ) {
                    showReview = true
                    HapticService.shared.mediumTap()
                }
            }

            // Inbox action
            if inboxCount > 0 {
                QuickActionCard(
                    icon: "hammer",
                    iconColor: .purple,
                    title: "Build",
                    subtitle: "\(inboxCount) items waiting"
                ) {
                    // Navigate to inbox
                    HapticService.shared.mediumTap()
                }
            }
        }
    }

    private var statsOverview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your City")
                .font(.headline)

            HStack(spacing: 16) {
                MiniStatView(
                    icon: "building.2",
                    value: "\(buildings.count)",
                    label: "Buildings"
                )

                MiniStatView(
                    icon: "star.fill",
                    value: "\(items.filter { $0.isMastered }.count)",
                    label: "Mastered"
                )

                if let stats = userStats {
                    MiniStatView(
                        icon: "trophy",
                        value: "\(stats.longestStreak)",
                        label: "Best Streak"
                    )
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var recentActivity: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent")
                .font(.headline)

            if items.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "plus.circle")
                        .font(.largeTitle)
                        .foregroundStyle(.tertiary)

                    Text("Capture your first piece of knowledge")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                ForEach(items.prefix(5)) { item in
                    RecentItemRow(item: item)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Quick Action Card

struct QuickActionCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(iconColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Mini Stat View

struct MiniStatView: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Recent Item Row

struct RecentItemRow: View {
    let item: KnowledgeItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.category.iconName)
                .font(.subheadline)
                .foregroundStyle(categoryColor)
                .frame(width: 28, height: 28)
                .background(categoryColor.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(item.content)
                    .font(.subheadline)
                    .lineLimit(1)

                Text(item.createdAt.formatted(.relative(presentation: .named)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if item.isPlaced {
                Image(systemName: "building.2")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var categoryColor: Color {
        switch item.category {
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
    ContentView()
        .modelContainer(for: [KnowledgeItem.self, Building.self, UserStats.self], inMemory: true)
}
