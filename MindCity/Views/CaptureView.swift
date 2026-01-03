import SwiftUI
import SwiftData
import PhotosUI

struct CaptureView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var stats: [UserStats]

    @State private var viewModel = CaptureViewModel()

    private var userStats: UserStats? {
        stats.first
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Content Type Picker
                    contentTypePicker

                    // Main Content Input
                    contentInput

                    // Category Picker
                    categoryPicker

                    // Tags Section
                    tagsSection

                    // Source URL (optional)
                    if viewModel.contentType == .link || viewModel.contentType == .quote {
                        sourceURLInput
                    }

                    // Image Picker (for image/diagram types)
                    if viewModel.contentType == .image || viewModel.contentType == .diagram {
                        imageSection
                    }

                    Spacer(minLength: 100)
                }
                .padding()
            }
            .navigationTitle("Capture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        HapticService.shared.lightTap()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveItem()
                    }
                    .fontWeight(.semibold)
                    .disabled(!viewModel.isValid || viewModel.isSaving)
                }
            }
            .overlay(alignment: .bottom) {
                if viewModel.showSaveConfirmation {
                    saveConfirmationToast
                }
            }
        }
    }

    // MARK: - Content Type Picker

    private var contentTypePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Type")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ContentType.allCases, id: \.self) { type in
                        ContentTypeButton(
                            type: type,
                            isSelected: viewModel.contentType == type
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                viewModel.contentType = type
                            }
                            HapticService.shared.selectionChanged()
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }

    // MARK: - Content Input

    private var contentInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Content")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ZStack(alignment: .topLeading) {
                if viewModel.content.isEmpty {
                    Text(placeholderText)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                }

                TextEditor(text: $viewModel.content)
                    .frame(minHeight: 120)
                    .padding(8)
                    .scrollContentBackground(.hidden)
            }
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var placeholderText: String {
        switch viewModel.contentType {
        case .text: return "Write your note..."
        case .quote: return "Enter the quote..."
        case .image: return "Add a caption for the image..."
        case .diagram: return "Describe the diagram..."
        case .link: return "Paste or describe the link..."
        case .voice: return "Voice transcription will appear here..."
        }
    }

    // MARK: - Category Picker

    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Category")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(KnowledgeCategory.allCases, id: \.self) { category in
                        CategoryButton(
                            category: category,
                            isSelected: viewModel.category == category
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                viewModel.category = category
                            }
                            HapticService.shared.selectionChanged()
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }

    // MARK: - Tags Section

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tags")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Tag input
            HStack {
                TextField("Add tag", text: $viewModel.tagInput)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .onSubmit {
                        viewModel.addTag()
                    }

                Button {
                    viewModel.addTag()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }
                .disabled(viewModel.tagInput.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            // Existing tags
            if !viewModel.tags.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(viewModel.tags, id: \.self) { tag in
                        TagChip(tag: tag) {
                            viewModel.removeTag(tag)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Source URL Input

    private var sourceURLInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Source URL")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            TextField("https://...", text: $viewModel.sourceURL)
                .textFieldStyle(.plain)
                .keyboardType(.URL)
                .textContentType(.URL)
                .autocapitalization(.none)
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Image Section

    private var imageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Image")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let imageData = viewModel.imageData,
               let uiImage = UIImage(data: imageData) {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            viewModel.imageData = nil
                        }
                        HapticService.shared.lightTap()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white, .black.opacity(0.6))
                    }
                    .padding(8)
                }
            } else {
                Button {
                    viewModel.isShowingImagePicker = true
                    HapticService.shared.lightTap()
                } label: {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)

                        Text("Tap to add image")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .photosPicker(
            isPresented: $viewModel.isShowingImagePicker,
            selection: Binding(
                get: { nil },
                set: { newValue in
                    if let newValue {
                        loadImage(from: newValue)
                    }
                }
            ),
            matching: .images
        )
    }

    // MARK: - Save Confirmation Toast

    private var saveConfirmationToast: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)

            Text("Added to Inbox — build later")
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(radius: 10)
        .padding(.bottom, 20)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.spring(response: 0.3)) {
                    viewModel.showSaveConfirmation = false
                }
                dismiss()
            }
        }
    }

    // MARK: - Actions

    private func saveItem() {
        guard let stats = userStats else { return }

        if viewModel.save(context: modelContext, stats: stats) {
            // Success handled by viewModel
        }
    }

    private func loadImage(from item: PhotosPickerItem) {
        Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                await MainActor.run {
                    withAnimation(.spring(response: 0.3)) {
                        viewModel.imageData = data
                    }
                    HapticService.shared.success()
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct ContentTypeButton: View {
    let type: ContentType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: type.iconName)
                    .font(.title3)

                Text(type.displayName)
                    .font(.caption)
            }
            .frame(width: 60, height: 60)
            .foregroundStyle(isSelected ? .white : .primary)
            .background(isSelected ? Color.blue : Color(.systemGray5))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

struct CategoryButton: View {
    let category: KnowledgeCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.iconName)
                    .font(.subheadline)

                Text(category.displayName)
                    .font(.caption)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .foregroundStyle(isSelected ? .white : .primary)
            .background(isSelected ? categoryColor : Color(.systemGray5))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
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

struct TagChip: View {
    let tag: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text("#\(tag)")
                .font(.subheadline)

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.systemGray5))
        .clipShape(Capsule())
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)

        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}

#Preview {
    CaptureView()
        .modelContainer(for: [KnowledgeItem.self, Building.self, UserStats.self], inMemory: true)
}
