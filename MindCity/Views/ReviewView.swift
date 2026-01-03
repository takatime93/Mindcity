import SwiftUI
import SwiftData

struct ReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var items: [KnowledgeItem]
    @Query private var stats: [UserStats]

    @State private var viewModel = ReviewViewModel()
    @State private var cardOffset: CGFloat = 0
    @State private var cardRotation: Double = 0

    private var userStats: UserStats? {
        stats.first
    }

    var body: some View {
        Group {
            if viewModel.isSessionComplete {
                sessionCompleteView
            } else if viewModel.isSessionActive {
                reviewSessionView
            } else {
                sessionStartView
            }
        }
        .onAppear {
            HapticService.shared.prepareAll()
        }
    }

    // MARK: - Session Start View

    private var sessionStartView: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                // Walking illustration
                VStack(spacing: 16) {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)

                    Text("Daily Walk")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Review your knowledge by walking through your city")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Due items count
                let dueCount = items.filter { $0.isPlaced && $0.isDue }.count

                if dueCount > 0 {
                    VStack(spacing: 8) {
                        Text("\(dueCount)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(.blue)

                        Text("buildings to visit")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.green)

                        Text("All caught up!")
                            .font(.headline)

                        Text("No items due for review right now")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }

                Spacer()

                // Start buttons
                VStack(spacing: 12) {
                    if dueCount > 0 {
                        // Full session
                        Button {
                            viewModel.startSession(items: items, quickMode: false)
                        } label: {
                            Label("Start Walk", systemImage: "figure.walk")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        // Quick mode
                        if dueCount > 5 {
                            Button {
                                viewModel.startSession(items: items, quickMode: true)
                            } label: {
                                Label("Just 5", systemImage: "hare")
                                    .font(.subheadline)
                                    .foregroundStyle(.blue)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Review Session View

    private var reviewSessionView: some View {
        ZStack {
            // Background
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress header
                progressHeader

                // Card area
                if let item = viewModel.currentItem {
                    cardView(for: item)
                }

                // Review buttons
                if viewModel.isShowingContent {
                    reviewButtons
                }
            }
        }
    }

    // MARK: - Progress Header

    private var progressHeader: some View {
        VStack(spacing: 8) {
            // Close button and progress
            HStack {
                Button {
                    viewModel.endSession()
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .frame(width: 44, height: 44)
                }

                Spacer()

                Text("\(viewModel.currentIndex + 1) / \(viewModel.reviewItems.count)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                Spacer()

                // Score
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("\(viewModel.correctCount)")
                            .fontWeight(.medium)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                        Text("\(viewModel.incorrectCount)")
                            .fontWeight(.medium)
                    }
                }
                .font(.subheadline)
            }
            .padding(.horizontal)

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))

                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * viewModel.progress)
                }
            }
            .frame(height: 4)
        }
        .padding(.top, 8)
    }

    // MARK: - Card View

    private func cardView(for item: KnowledgeItem) -> some View {
        GeometryReader { geometry in
            VStack {
                Spacer()

                // Card
                ZStack {
                    // Card background
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)

                    // Card content
                    VStack(spacing: 20) {
                        // Building header
                        if let building = item.building {
                            HStack(spacing: 12) {
                                Image(systemName: building.buildingType.iconName)
                                    .font(.title2)
                                    .foregroundStyle(categoryColor(for: item.category))
                                    .frame(width: 44, height: 44)
                                    .background(categoryColor(for: item.category).opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(building.displayName)
                                        .font(.headline)

                                    Text(item.category.displayName)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.top)
                        }

                        Divider()
                            .padding(.horizontal)

                        // Content area
                        if viewModel.isShowingContent {
                            // Show full content
                            ScrollView {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(item.content)
                                        .font(.body)

                                    if !item.tags.isEmpty {
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 8) {
                                                ForEach(item.tags, id: \.self) { tag in
                                                    Text("#\(tag)")
                                                        .font(.caption)
                                                        .foregroundStyle(.secondary)
                                                        .padding(.horizontal, 8)
                                                        .padding(.vertical, 4)
                                                        .background(Color(.systemGray5))
                                                        .clipShape(Capsule())
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        } else {
                            // Prompt to recall
                            VStack(spacing: 16) {
                                Spacer()

                                Image(systemName: "brain.head.profile")
                                    .font(.system(size: 50))
                                    .foregroundStyle(.tertiary)

                                Text("Try to recall...")
                                    .font(.title3)
                                    .foregroundStyle(.secondary)

                                Spacer()

                                Button {
                                    viewModel.revealContent()
                                } label: {
                                    Text("Show Answer")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .padding(.horizontal)
                            }
                            .padding()
                        }

                        Spacer()
                    }
                }
                .frame(width: geometry.size.width - 32)
                .frame(height: geometry.size.height * 0.7)
                .offset(x: cardOffset)
                .rotationEffect(.degrees(cardRotation))
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if viewModel.isShowingContent {
                                cardOffset = value.translation.width
                                cardRotation = Double(value.translation.width / 20)
                            }
                        }
                        .onEnded { value in
                            if viewModel.isShowingContent {
                                let threshold: CGFloat = 100

                                if value.translation.width > threshold {
                                    // Swipe right = Got it
                                    withAnimation(.spring(response: 0.3)) {
                                        cardOffset = 500
                                    }
                                    submitReview(.gotIt)
                                } else if value.translation.width < -threshold {
                                    // Swipe left = Forgot
                                    withAnimation(.spring(response: 0.3)) {
                                        cardOffset = -500
                                    }
                                    submitReview(.forgot)
                                } else {
                                    withAnimation(.spring(response: 0.3)) {
                                        cardOffset = 0
                                        cardRotation = 0
                                    }
                                }
                            }
                        }
                )

                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Review Buttons

    private var reviewButtons: some View {
        HStack(spacing: 20) {
            // Forgot button
            Button {
                submitReview(.forgot)
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: "xmark")
                        .font(.title)
                        .foregroundStyle(.white)
                        .frame(width: 70, height: 70)
                        .background(Color.red)
                        .clipShape(Circle())

                    Text("Forgot")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Got it button
            Button {
                submitReview(.gotIt)
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark")
                        .font(.title)
                        .foregroundStyle(.white)
                        .frame(width: 70, height: 70)
                        .background(Color.green)
                        .clipShape(Circle())

                    Text("Got it")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 24)
    }

    // MARK: - Session Complete View

    private var sessionCompleteView: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                // Celebration
                VStack(spacing: 16) {
                    Image(systemName: "flag.checkered")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)

                    Text("Walk Complete!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }

                // Stats
                VStack(spacing: 16) {
                    HStack(spacing: 40) {
                        VStack(spacing: 4) {
                            Text("\(viewModel.reviewItems.count)")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundStyle(.blue)

                            Text("Reviewed")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        VStack(spacing: 4) {
                            Text("\(viewModel.correctCount)")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundStyle(.green)

                            Text("Correct")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        VStack(spacing: 4) {
                            Text("\(viewModel.incorrectCount)")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundStyle(.red)

                            Text("Forgot")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Accuracy
                    if viewModel.reviewItems.count > 0 {
                        let accuracy = Double(viewModel.correctCount) / Double(viewModel.reviewItems.count)
                        VStack(spacing: 4) {
                            Text("\(Int(accuracy * 100))%")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(accuracy >= 0.8 ? .green : accuracy >= 0.6 ? .orange : .red)

                            Text("Accuracy")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)

                // Streak update
                if let stats = userStats {
                    VStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(.orange)

                            Text("\(stats.currentStreak) day streak")
                                .fontWeight(.semibold)
                        }
                        .font(.headline)

                        if stats.currentStreak > stats.longestStreak {
                            Text("New record!")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                }

                Spacer()

                // Done button
                Button {
                    viewModel.endSession()
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: - Actions

    private func submitReview(_ result: ReviewResult) {
        guard let stats = userStats else { return }

        // Reset card position
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            cardOffset = 0
            cardRotation = 0
        }

        viewModel.submitReview(result: result, context: modelContext, stats: stats)

        // Check for era progression
        let newEra = FSRSService.calculateAchievementEra(items: items)
        if newEra > stats.achievementEra {
            stats.achievementEra = newEra
            stats.displayEra = newEra
            HapticService.shared.eraUnlocked()
        }
    }

    private func categoryColor(for category: KnowledgeCategory) -> Color {
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
    ReviewView()
        .modelContainer(for: [KnowledgeItem.self, Building.self, UserStats.self], inMemory: true)
}
