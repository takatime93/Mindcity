import SwiftUI
import SwiftData

struct CityView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var buildings: [Building]
    @Query private var items: [KnowledgeItem]
    @Query private var stats: [UserStats]

    @State private var viewModel = CityViewModel()
    @Binding var showReview: Bool

    @GestureState private var magnifyBy = 1.0
    @State private var lastScale: CGFloat = 1.0

    private var userStats: UserStats? {
        stats.first
    }

    private var dueItemsCount: Int {
        items.filter { $0.isPlaced && $0.isDue }.count
    }

    var body: some View {
        ZStack {
            // City canvas
            cityCanvas

            // Floating UI
            VStack {
                // Header with stats
                headerOverlay

                Spacer()

                // Bottom controls
                bottomControls
            }

            // Building detail sheet
            if viewModel.isShowingBuildingDetail, let building = viewModel.selectedBuilding {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        viewModel.deselectBuilding()
                    }

                BuildingDetailCard(building: building) {
                    viewModel.deselectBuilding()
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: viewModel.isShowingBuildingDetail)
    }

    // MARK: - City Canvas

    private var cityCanvas: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color(.systemGray6)
                    .ignoresSafeArea()

                // Grid
                cityGrid(in: geometry.size)

                // Buildings
                ForEach(buildings) { building in
                    CityBuildingView(
                        building: building,
                        gridSize: viewModel.gridSize,
                        scale: viewModel.scale,
                        offset: viewModel.offset,
                        containerSize: geometry.size
                    ) {
                        viewModel.selectBuilding(building)
                    }
                }
            }
            .gesture(combinedGesture)
        }
    }

    // MARK: - City Grid

    private func cityGrid(in size: CGSize) -> some View {
        let gridCount = Int(viewModel.citySize / viewModel.gridSize)
        let gridSize = viewModel.gridSize * viewModel.scale
        let offsetX = viewModel.offset.width + size.width / 2 - (viewModel.citySize * viewModel.scale) / 2
        let offsetY = viewModel.offset.height + size.height / 2 - (viewModel.citySize * viewModel.scale) / 2

        return Canvas { context, canvasSize in
            // Draw grid
            for i in 0...gridCount {
                let x = offsetX + CGFloat(i) * gridSize
                let y = offsetY + CGFloat(i) * gridSize

                // Vertical line
                var vPath = Path()
                vPath.move(to: CGPoint(x: x, y: max(0, offsetY)))
                vPath.addLine(to: CGPoint(x: x, y: min(canvasSize.height, offsetY + CGFloat(gridCount) * gridSize)))
                context.stroke(vPath, with: .color(.gray.opacity(0.15)), lineWidth: 1)

                // Horizontal line
                var hPath = Path()
                hPath.move(to: CGPoint(x: max(0, offsetX), y: y))
                hPath.addLine(to: CGPoint(x: min(canvasSize.width, offsetX + CGFloat(gridCount) * gridSize), y: y))
                context.stroke(hPath, with: .color(.gray.opacity(0.15)), lineWidth: 1)
            }

            // Draw center marker
            let centerX = offsetX + (viewModel.citySize * viewModel.scale) / 2
            let centerY = offsetY + (viewModel.citySize * viewModel.scale) / 2

            var centerPath = Path()
            centerPath.addEllipse(in: CGRect(x: centerX - 4, y: centerY - 4, width: 8, height: 8))
            context.fill(centerPath, with: .color(.blue.opacity(0.3)))
        }
    }

    // MARK: - Header Overlay

    private var headerOverlay: some View {
        VStack(spacing: 0) {
            HStack {
                // Era badge
                if let stats = userStats {
                    EraBadge(era: stats.displayEra)
                }

                Spacer()

                // Streak display
                if let stats = userStats {
                    StreakBadge(streak: stats.currentStreak)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            // Due items notification
            if dueItemsCount > 0 {
                DueItemsBanner(count: dueItemsCount) {
                    showReview = true
                    HapticService.shared.mediumTap()
                }
                .padding(.horizontal)
                .padding(.top, 12)
            }
        }
        .background(
            LinearGradient(
                colors: [Color(.systemBackground), Color(.systemBackground).opacity(0)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 150)
            .allowsHitTesting(false),
            alignment: .top
        )
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        HStack {
            // Zoom controls
            VStack(spacing: 8) {
                Button {
                    viewModel.zoomIn()
                } label: {
                    Image(systemName: "plus")
                        .font(.title3)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }

                Button {
                    viewModel.zoomOut()
                } label: {
                    Image(systemName: "minus")
                        .font(.title3)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }

                Button {
                    viewModel.resetView()
                } label: {
                    Image(systemName: "location.fill")
                        .font(.title3)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
            }
            .padding()

            Spacer()

            // City stats
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(buildings.count) buildings")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("\(items.filter { $0.isMastered }.count) mastered")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding()
        }
    }

    // MARK: - Gestures

    private var combinedGesture: some Gesture {
        SimultaneousGesture(
            MagnificationGesture()
                .updating($magnifyBy) { value, state, _ in
                    state = value
                }
                .onChanged { value in
                    let newScale = lastScale * value
                    viewModel.updateScale(newScale)
                }
                .onEnded { value in
                    lastScale = viewModel.scale
                },
            DragGesture()
                .onChanged { value in
                    viewModel.updateOffset(CGSize(
                        width: viewModel.offset.width + value.translation.width * 0.5,
                        height: viewModel.offset.height + value.translation.height * 0.5
                    ))
                }
        )
    }
}

// MARK: - City Building View

struct CityBuildingView: View {
    let building: Building
    let gridSize: CGFloat
    let scale: CGFloat
    let offset: CGSize
    let containerSize: CGSize
    let onTap: () -> Void

    private var screenPosition: CGPoint {
        let cityOffset = CGPoint(
            x: offset.width + containerSize.width / 2 - (2000 * scale) / 2,
            y: offset.height + containerSize.height / 2 - (2000 * scale) / 2
        )

        return CGPoint(
            x: cityOffset.x + CGFloat(building.positionX) * scale,
            y: cityOffset.y + CGFloat(building.positionY) * scale
        )
    }

    private var isVisible: Bool {
        let margin: CGFloat = 100
        return screenPosition.x > -margin &&
               screenPosition.x < containerSize.width + margin &&
               screenPosition.y > -margin &&
               screenPosition.y < containerSize.height + margin
    }

    var body: some View {
        if isVisible {
            Button(action: onTap) {
                VStack(spacing: 2 * scale) {
                    // Building icon
                    ZStack {
                        // Decay overlay
                        if let item = building.knowledgeItem {
                            Circle()
                                .fill(decayColor(for: item.decayState))
                                .frame(width: 40 * scale, height: 40 * scale)
                        }

                        Image(systemName: building.buildingType.iconName)
                            .font(.system(size: 20 * scale))
                            .foregroundStyle(buildingColor)
                    }
                    .frame(width: 44 * scale, height: 44 * scale)
                    .background(
                        RoundedRectangle(cornerRadius: 8 * scale)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.1), radius: 4 * scale)
                    )

                    // Building name
                    if scale > 0.7 {
                        Text(building.displayName)
                            .font(.system(size: 10 * scale))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .frame(maxWidth: gridSize * scale)
                    }
                }
                .scaleEffect(building.evolutionLevel.scale)
                .opacity(building.evolutionLevel.opacity)
            }
            .buttonStyle(.plain)
            .position(screenPosition)
        }
    }

    private var buildingColor: Color {
        switch building.buildingType.category {
        case .philosophy: return .purple
        case .technical: return .blue
        case .creative: return .orange
        case .science: return .green
        case .personal: return .yellow
        case .general: return .gray
        }
    }

    private func decayColor(for state: DecayState) -> Color {
        switch state {
        case .none: return .clear
        case .muted: return .gray.opacity(state.overlayOpacity)
        case .overgrown: return .brown.opacity(state.overlayOpacity)
        }
    }
}

// MARK: - Building Detail Card

struct BuildingDetailCard: View {
    let building: Building
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                // Handle
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(.systemGray4))
                    .frame(width: 36, height: 4)
                    .padding(.top, 8)

                // Building header
                HStack(spacing: 12) {
                    Image(systemName: building.buildingType.iconName)
                        .font(.title)
                        .foregroundStyle(categoryColor)
                        .frame(width: 50, height: 50)
                        .background(categoryColor.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(building.displayName)
                            .font(.headline)

                        HStack(spacing: 8) {
                            Text(building.buildingType.category.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text("•")
                                .foregroundStyle(.tertiary)

                            Text(building.evolutionLevel.displayName)
                                .font(.caption)
                                .foregroundStyle(evolutionColor)
                        }
                    }

                    Spacer()

                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)

                // Knowledge content
                if let item = building.knowledgeItem {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(item.content)
                            .font(.body)
                            .foregroundStyle(.primary)

                        // Tags
                        if !item.tags.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(item.tags, id: \.self) { tag in
                                        Text("#\(tag)")
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color(.systemGray5))
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }

                        // Stats
                        HStack(spacing: 16) {
                            StatItem(
                                icon: "arrow.trianglehead.2.counterclockwise.rotate.90",
                                value: "\(item.reviewCount)",
                                label: "Reviews"
                            )

                            StatItem(
                                icon: "chart.line.uptrend.xyaxis",
                                value: "\(Int(item.retrievability * 100))%",
                                label: "Retention"
                            )

                            StatItem(
                                icon: "flame",
                                value: "\(item.consecutiveCorrect)",
                                label: "Streak"
                            )

                            Spacer()
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal)
                }

                Spacer()
                    .frame(height: 20)
            }
            .frame(maxHeight: 350)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(radius: 20)
            .padding()
        }
    }

    private var categoryColor: Color {
        switch building.buildingType.category {
        case .philosophy: return .purple
        case .technical: return .blue
        case .creative: return .orange
        case .science: return .green
        case .personal: return .yellow
        case .general: return .gray
        }
    }

    private var evolutionColor: Color {
        switch building.evolutionLevel {
        case .scaffolding: return .orange
        case .basic: return .blue
        case .polished: return .green
        case .landmark: return .purple
        }
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            Text(label)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }
}

// MARK: - Era Badge

struct EraBadge: View {
    let era: Era

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: eraIcon)
                .font(.caption)

            Text(era.displayName)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }

    private var eraIcon: String {
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
}

// MARK: - Streak Badge

struct StreakBadge: View {
    let streak: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: streak > 0 ? "flame.fill" : "flame")
                .font(.caption)
                .foregroundStyle(streak > 0 ? .orange : .secondary)

            Text("\(streak)")
                .font(.caption)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
}

// MARK: - Due Items Banner

struct DueItemsBanner: View {
    let count: Int
    let onStartReview: () -> Void

    var body: some View {
        Button(action: onStartReview) {
            HStack {
                Image(systemName: "bell.fill")
                    .foregroundStyle(.white)

                Text("\(count) items due for review")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)

                Spacer()

                Text("Start Walk")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)

                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CityView(showReview: .constant(false))
        .modelContainer(for: [KnowledgeItem.self, Building.self, UserStats.self], inMemory: true)
}
