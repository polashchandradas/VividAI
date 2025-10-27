import SwiftUI
import UIKit

// MARK: - Style Examples Gallery View

struct StyleExamplesGalleryView: View {
    @StateObject private var styleManager = StyleExampleManager.shared
    @State private var selectedExample: StyleExample? = nil
    @State private var showingDetailView = false
    @State private var viewMode: ViewMode = .grid
    @State private var showingFilters = false
    
    let onExampleSelected: (StyleExample) -> Void
    let onClose: () -> Void
    
    enum ViewMode {
        case grid
        case list
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Filters
                if showingFilters {
                    filtersView
                }
                
                // Content
                contentView
            }
            .navigationTitle("Style Examples")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Close", action: onClose),
                trailing: HStack(spacing: DesignSystem.Spacing.md) {
                    // Filter Button
                    Button(action: {
                        showingFilters.toggle()
                    }) {
                        Image(systemName: showingFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .font(.system(size: DesignSystem.IconSizes.medium))
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                    
                    // View Mode Toggle
                    Button(action: {
                        viewMode = viewMode == .grid ? .list : .grid
                    }) {
                        Image(systemName: viewMode == .grid ? "list.bullet" : "square.grid.2x2")
                            .font(.system(size: DesignSystem.IconSizes.medium))
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                }
            )
        }
        .onAppear {
            ServiceContainer.shared.analyticsService.track(event: "style_examples_gallery_opened")
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                TextField("Search styles...", text: $styleManager.searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onChange(of: styleManager.searchText) { _ in
                        styleManager.updateFilteredExamples()
                    }
                
                if !styleManager.searchText.isEmpty {
                    Button(action: {
                        styleManager.setSearchText("")
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
            }
            .padding(DesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .fill(DesignSystem.Colors.neutral)
            )
            
            // Results Count
            HStack {
                Text("\(styleManager.filteredExamples.count) styles")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Spacer()
                
                if styleManager.selectedCategory != nil {
                    Button("Clear Filter") {
                        styleManager.setCategory(nil)
                    }
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.primary)
                }
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.top, DesignSystem.Spacing.sm)
    }
    
    // MARK: - Filters View
    
    private var filtersView: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Category Filters
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text("Categories")
                    .font(DesignSystem.Typography.captionBold)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        // All Categories
                        categoryFilterButton(
                            title: "All",
                            isSelected: styleManager.selectedCategory == nil
                        ) {
                            styleManager.setCategory(nil)
                        }
                        
                        // Category Filters
                        ForEach(StyleCategory.allCases, id: \.self) { category in
                            categoryFilterButton(
                                title: category.rawValue,
                                isSelected: styleManager.selectedCategory == category,
                                color: category.color
                            ) {
                                styleManager.setCategory(category)
                            }
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                }
            }
            
            // Premium Filter
            HStack {
                Text("Show Premium Styles")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                Toggle("", isOn: .constant(true))
                    .labelsHidden()
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.vertical, DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.neutral.opacity(0.5))
    }
    
    private func categoryFilterButton(title: String, isSelected: Bool, color: Color = DesignSystem.Colors.primary, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(DesignSystem.Typography.captionBold)
                .foregroundColor(isSelected ? .white : color)
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                        .fill(isSelected ? color : color.opacity(0.1))
                )
        }
    }
    
    // MARK: - Content View
    
    private var contentView: some View {
        Group {
            if styleManager.filteredExamples.isEmpty {
                emptyStateView
            } else {
                switch viewMode {
                case .grid:
                    StyleExampleGridView(
                        examples: styleManager.filteredExamples,
                        selectedExample: selectedExample,
                        onExampleTap: { example in
                            selectedExample = example
                            onExampleSelected(example)
                        },
                        onInfoTap: { example in
                            selectedExample = example
                            showingDetailView = true
                        }
                    )
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    
                case .list:
                    StyleExampleListView(
                        examples: styleManager.filteredExamples,
                        selectedExample: selectedExample,
                        onExampleTap: { example in
                            selectedExample = example
                            onExampleSelected(example)
                        },
                        onInfoTap: { example in
                            selectedExample = example
                            showingDetailView = true
                        }
                    )
                }
            }
        }
        .sheet(isPresented: $showingDetailView) {
            if let example = selectedExample {
                StyleExampleDetailView(
                    example: example,
                    onSelect: {
                        onExampleSelected(example)
                        showingDetailView = false
                    },
                    onClose: {
                        showingDetailView = false
                    }
                )
            }
        }
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            Text("No styles found")
                .font(DesignSystem.Typography.h4)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text("Try adjusting your search or filters")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
            
            Button("Clear Filters") {
                styleManager.setSearchText("")
                styleManager.setCategory(nil)
            }
            .font(DesignSystem.Typography.button)
            .foregroundColor(.white)
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.primary)
            .cornerRadius(DesignSystem.CornerRadius.md)
        }
        .padding(.horizontal, DesignSystem.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Style Examples Quick View

struct StyleExamplesQuickView: View {
    let onExampleSelected: (StyleExample) -> Void
    let onViewAll: () -> Void
    
    @StateObject private var styleManager = StyleExampleManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // Header
            HStack {
                Text("Style Examples")
                    .font(DesignSystem.Typography.h4)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                Button("View All") {
                    onViewAll()
                }
                .font(DesignSystem.Typography.captionBold)
                .foregroundColor(DesignSystem.Colors.primary)
            }
            
            // Popular Examples Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DesignSystem.Spacing.sm), count: 3), spacing: DesignSystem.Spacing.sm) {
                ForEach(styleManager.getPopularExamples(limit: 6)) { example in
                    StyleExampleView(
                        example: example,
                        isSelected: false,
                        onTap: {
                            onExampleSelected(example)
                        }
                    )
                }
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
    }
}

// MARK: - Style Examples Category View

struct StyleExamplesCategoryView: View {
    let category: StyleCategory
    let onExampleSelected: (StyleExample) -> Void
    let onClose: () -> Void
    
    @StateObject private var styleManager = StyleExampleManager.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: DesignSystem.Spacing.md) {
                    ForEach(styleManager.getExamplesForCategory(category)) { example in
                        StyleExampleRowView(
                            example: example,
                            isSelected: false,
                            onTap: {
                                onExampleSelected(example)
                            },
                            onInfoTap: nil
                        )
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
            }
            .navigationTitle(category.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Close", action: onClose))
        }
        .onAppear {
            ServiceContainer.shared.analyticsService.track(event: "style_examples_category_viewed", parameters: [
                "category": category.rawValue
            ])
        }
    }
}

// MARK: - Style Examples Integration Helper

struct StyleExamplesIntegrationHelper {
    static func showStyleExamples(
        from view: some View,
        onExampleSelected: @escaping (StyleExample) -> Void
    ) -> some View {
        view.sheet(isPresented: .constant(false)) {
            StyleExamplesGalleryView(
                onExampleSelected: onExampleSelected,
                onClose: {}
            )
        }
    }
}

// MARK: - Preview

#Preview {
    StyleExamplesGalleryView(
        onExampleSelected: { _ in },
        onClose: {}
    )
}
