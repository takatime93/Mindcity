import SwiftUI
import SwiftData

struct InboxView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<KnowledgeItem> { !$0.isPlaced },
           sort: \KnowledgeItem.createdAt,
           order: .reverse)
    private var inboxItems: [KnowledgeItem]

    @Query private var buildings: [Building]

    @State private var viewModel = InboxViewModel()
    @State private var searchText = ""

    private var filteredItems: [KnowledgeItem] {
        if searchText.isEmpty {
            return inboxItems
        }
        return inboxItems.filter {
            $0.content.localizedCaseInsensitiveContains(searchText) ||
            $0.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if inboxItems.isEmpty {
                    emptyState
                } else {
                    itemsList
                }
            }
            .navigationTitle("Inbox")
            .searchable(text: $searchText, prompt: "Search items")
            .sheet(isPresented: $viewModel.isShowingBuildingPicker) {
                buildingPickerSheet
            }
            .fullScreenCover(isPresented: $viewModel.isShowingPlacementView) {
                PlacementView(
                    item: viewModel.selectedItem,
                    buildingType: viewModel.selectedBuildingType,
                    existingBuildings: buildings,
                    onPlace: { position in
                        _ = viewModel.placeBuilding(at: position, context: modelContext)
                    },
                    onCancel: {
                        viewModel.cancelPlacement()
                    }
                )
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundStyle(.tertiary)

            Text("Inbox Empty")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Capture knowledge to see it here.\nThen build it into your city.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Items List

    private var itemsList: some View {
        List {
            Section {
                ForEach(filteredItems) { item in
                    InboxItemRow(item: item) {
                        viewModel.selectItemForPlacement(item)
                    }
                }
                .onDelete(perform: deleteItems)
            } header: {
                Text("\(filteredItems.count) items ready to build")
                    .textCase(nil)
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Building Picker Sheet

    private var buildingPickerSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Item preview
                if let item = viewModel.selectedItem {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(item.content)
                            .font(.subheadline)
                            .lineLimit(3)
                            .foregroundStyle(.secondary)

                        HStack {
                            Label(item.category.displayName, systemImage: item.category.iconName)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Spacer()

                            Text(item.contentType.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }

                // Building type selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Choose a Building")
                        .font(.headline)
                        .padding(.horizontal)

                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ForEach(viewModel.availableBuildingTypes, id: \.self) { type in
                                BuildingTypeCard(
                                    type: type,
                                    isSelected: viewModel.selectedBuildingType == type
                                ) {
                                    viewModel.selectBuildingType(type)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                Spacer()

                // Confirm button
                Button {
                    viewModel.confirmBuildingType()
                } label: {
                    Text("Choose Location")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal)
                .padding(.bottom)
                .disabled(viewModel.selectedBuildingType == nil)
            }
            .navigationTitle("Build")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.cancelPlacement()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Actions

    private func deleteItems(at offsets: IndexSet) {
        HapticService.shared.deleteAction()
        for index in offsets {
            let item = filteredItems[index]
            modelContext.delete(item)
        }
        try? modelContext.save()
    }
}

// MARK: - Inbox Item Row

struct InboxItemRow: View {
    let item: KnowledgeItem
    let onBuild: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            Image(systemName: item.category.iconName)
                .font(.title3)
                .foregroundStyle(categoryColor)
                .frame(width: 36, height: 36)
                .background(categoryColor.opacity(0.15))
                .clipShape(Circle())

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(item.content)
                    .font(.subheadline)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Label(item.contentType.displayName, systemImage: item.contentType.iconName)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if !item.tags.isEmpty {
                        Text("• \(item.tags.first ?? "")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text(item.createdAt.formatted(.relative(presentation: .named)))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            // Build button
            Button {
                onBuild()
            } label: {
                Image(systemName: "hammer.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
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

// MARK: - Building Type Card

struct BuildingTypeCard: View {
    let type: BuildingType
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                Image(systemName: type.iconName)
                    .font(.title)
                    .foregroundStyle(isSelected ? .white : .primary)

                Text(type.displayName)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .white : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? Color.blue : Color(.systemGray5))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Placement View

struct PlacementView: View {
    let item: KnowledgeItem?
    let buildingType: BuildingType?
    let existingBuildings: [Building]
    let onPlace: (CGPoint) -> Void
    let onCancel: () -> Void

    @State private var cityViewModel = CityViewModel()
    @State private var dragPosition: CGPoint?
    @State private var isDragging = false
    @GestureState private var magnifyBy = 1.0

    var body: some View {
        ZStack {
            // City grid background
            cityGrid

            // Existing buildings
            ForEach(existingBuildings) { building in
                PlacedBuildingView(building: building, gridSize: cityViewModel.gridSize)
            }

            // Draggable new building
            if let buildingType = buildingType {
                draggableBuilding(type: buildingType)
            }

            // UI overlay
            VStack {
                // Header
                header

                Spacer()

                // Instructions
                instructions
            }
        }
        .background(Color(.systemBackground))
        .gesture(magnificationGesture)
        .simultaneousGesture(dragGesture)
    }

    // MARK: - City Grid

    private var cityGrid: some View {
        GeometryReader { geometry in
            let gridCount = Int(cityViewModel.citySize / cityViewModel.gridSize)

            Canvas { context, size in
                let gridSize = cityViewModel.gridSize * cityViewModel.scale
                let offsetX = cityViewModel.offset.width + size.width / 2 - (cityViewModel.citySize * cityViewModel.scale) / 2
                let offsetY = cityViewModel.offset.height + size.height / 2 - (cityViewModel.citySize * cityViewModel.scale) / 2

                // Draw grid lines
                context.stroke(
                    Path { path in
                        for i in 0...gridCount {
                            let x = offsetX + CGFloat(i) * gridSize
                            path.move(to: CGPoint(x: x, y: offsetY))
                            path.addLine(to: CGPoint(x: x, y: offsetY + CGFloat(gridCount) * gridSize))

                            let y = offsetY + CGFloat(i) * gridSize
                            path.move(to: CGPoint(x: offsetX, y: y))
                            path.addLine(to: CGPoint(x: offsetX + CGFloat(gridCount) * gridSize, y: y))
                        }
                    },
                    with: .color(.gray.opacity(0.2)),
                    lineWidth: 1
                )
            }
            .scaleEffect(1)
        }
    }

    // MARK: - Draggable Building

    private func draggableBuilding(type: BuildingType) -> some View {
        GeometryReader { geometry in
            let position = dragPosition ?? CGPoint(
                x: geometry.size.width / 2,
                y: geometry.size.height / 2
            )

            let snappedPosition = cityViewModel.snapToGrid(screenToCity(position, in: geometry.size))
            let isOccupied = cityViewModel.isPositionOccupied(snappedPosition, existingBuildings: existingBuildings)

            VStack(spacing: 4) {
                Image(systemName: type.iconName)
                    .font(.system(size: 30))
                    .foregroundStyle(isOccupied ? .red : .blue)

                Text(type.displayName)
                    .font(.caption2)
                    .foregroundStyle(isOccupied ? .red : .primary)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isOccupied ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(isOccupied ? Color.red : Color.blue, lineWidth: 2, antialiased: true)
                    )
            )
            .scaleEffect(isDragging ? 1.1 : 1.0)
            .shadow(color: .black.opacity(isDragging ? 0.3 : 0.1), radius: isDragging ? 10 : 4)
            .position(position)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if !isDragging {
                            isDragging = true
                            HapticService.shared.dragStart()
                        }
                        dragPosition = value.location
                    }
                    .onEnded { value in
                        isDragging = false
                        let finalPosition = cityViewModel.snapToGrid(screenToCity(value.location, in: geometry.size))

                        if !cityViewModel.isPositionOccupied(finalPosition, existingBuildings: existingBuildings) {
                            onPlace(finalPosition)
                        } else {
                            HapticService.shared.error()
                            // Reset to center
                            withAnimation(.spring(response: 0.3)) {
                                dragPosition = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                            }
                        }
                    }
            )
            .animation(.spring(response: 0.2), value: isDragging)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button {
                onCancel()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let item = item {
                VStack(spacing: 2) {
                    Text("Placing")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(item.content)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Zoom controls
            HStack(spacing: 12) {
                Button {
                    cityViewModel.zoomOut()
                } label: {
                    Image(systemName: "minus.magnifyingglass")
                        .font(.title3)
                }

                Button {
                    cityViewModel.zoomIn()
                } label: {
                    Image(systemName: "plus.magnifyingglass")
                        .font(.title3)
                }
            }
            .foregroundStyle(.primary)
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    // MARK: - Instructions

    private var instructions: some View {
        VStack(spacing: 8) {
            Text("Drag to place your building")
                .font(.headline)

            Text("Position is permanent — choose wisely!")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
    }

    // MARK: - Gestures

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .updating($magnifyBy) { currentState, gestureState, _ in
                gestureState = currentState
            }
            .onEnded { value in
                cityViewModel.updateScale(cityViewModel.scale * value)
            }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                // Only update offset if not dragging the building
                if !isDragging {
                    cityViewModel.updateOffset(CGSize(
                        width: cityViewModel.offset.width + value.translation.width,
                        height: cityViewModel.offset.height + value.translation.height
                    ))
                }
            }
    }

    // MARK: - Coordinate Conversion

    private func screenToCity(_ screenPoint: CGPoint, in size: CGSize) -> CGPoint {
        let offsetX = cityViewModel.offset.width + size.width / 2 - (cityViewModel.citySize * cityViewModel.scale) / 2
        let offsetY = cityViewModel.offset.height + size.height / 2 - (cityViewModel.citySize * cityViewModel.scale) / 2

        return CGPoint(
            x: (screenPoint.x - offsetX) / cityViewModel.scale,
            y: (screenPoint.y - offsetY) / cityViewModel.scale
        )
    }
}

// MARK: - Placed Building View

struct PlacedBuildingView: View {
    let building: Building
    let gridSize: CGFloat

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: building.buildingType.iconName)
                .font(.title3)

            Text(building.displayName)
                .font(.caption2)
                .lineLimit(1)
        }
        .foregroundStyle(.primary.opacity(building.evolutionLevel.opacity))
        .scaleEffect(building.evolutionLevel.scale * 0.8)
        .frame(width: gridSize, height: gridSize)
        .background(Color(.systemGray5).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .position(x: CGFloat(building.positionX), y: CGFloat(building.positionY))
    }
}

#Preview {
    InboxView()
        .modelContainer(for: [KnowledgeItem.self, Building.self, UserStats.self], inMemory: true)
}
