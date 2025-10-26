import SwiftUI
import UIKit

// MARK: - Style Example View

struct StyleExampleView: View {
    let example: StyleExample
    let isSelected: Bool
    let onTap: () -> Void
    let onInfoTap: (() -> Void)?
    
    @State private var isPressed = false
    
    init(example: StyleExample, isSelected: Bool = false, onTap: @escaping () -> Void, onInfoTap: (() -> Void)? = nil) {
        self.example = example
        self.isSelected = isSelected
        self.onTap = onTap
        self.onInfoTap = onInfoTap
    }
    
    var body: some View {
        Button(action: {
            onTap()
            StyleExampleManager.shared.trackStyleExampleSelected(example)
        }) {
            VStack(spacing: DesignSystem.Spacing.sm) {
                // Sample Image
                sampleImageView
                
                // Style Info
                styleInfoView
                
                // Premium Badge
                if example.isPremium {
                    premiumBadgeView
                }
            }
            .padding(DesignSystem.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .fill(backgroundFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                            .stroke(borderColor, lineWidth: borderWidth)
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(DesignSystem.Animations.standard, value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0) { pressing in
            isPressed = pressing
        } perform: {
            // Long press action
        }
    }
    
    // MARK: - Sample Image View
    
    private var sampleImageView: some View {
        ZStack {
            // Sample Image
            if let uiImage = example.uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 120)
                    .clipped()
                    .cornerRadius(DesignSystem.CornerRadius.sm)
            } else {
                // Placeholder for missing image
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                    .fill(DesignSystem.Colors.neutral)
                    .frame(width: 120, height: 120)
                    .overlay(
                        VStack(spacing: DesignSystem.Spacing.xs) {
                            Image(systemName: "photo")
                                .font(.system(size: DesignSystem.IconSizes.large))
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            
                            Text("Sample")
                                .font(DesignSystem.Typography.small)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                    )
            }
            
            // Selection Overlay
            if isSelected {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                    .fill(Color.black.opacity(0.3))
                    .frame(width: 120, height: 120)
                    .overlay(
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: DesignSystem.IconSizes.large))
                            .foregroundColor(.white)
                    )
            }
            
            // Info Button
            if let onInfoTap = onInfoTap {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: onInfoTap) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: DesignSystem.IconSizes.small))
                                .foregroundColor(.white)
                                .background(
                                    Circle()
                                        .fill(Color.black.opacity(0.6))
                                        .frame(width: 20, height: 20)
                                )
                        }
                    }
                    Spacer()
                }
                .padding(DesignSystem.Spacing.xs)
            }
        }
    }
    
    // MARK: - Style Info View
    
    private var styleInfoView: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            // Style Name
            Text(example.styleName)
                .font(DesignSystem.Typography.captionBold)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            // Category Badge
            HStack {
                Image(systemName: example.category.icon)
                    .font(.system(size: DesignSystem.IconSizes.xs))
                    .foregroundColor(example.category.color)
                
                Text(example.category.rawValue)
                    .font(DesignSystem.Typography.small)
                    .foregroundColor(example.category.color)
            }
            .padding(.horizontal, DesignSystem.Spacing.xs)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xs)
                    .fill(example.category.color.opacity(0.1))
            )
            
            // Processing Time
            HStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: "clock")
                    .font(.system(size: DesignSystem.IconSizes.xs))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Text(example.processingTimeText)
                    .font(DesignSystem.Typography.small)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            // Popularity Stars
            Text(example.popularityStars)
                .font(.system(size: 10))
                .foregroundColor(.yellow)
        }
    }
    
    // MARK: - Premium Badge View
    
    private var premiumBadgeView: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: "crown.fill")
                .font(.system(size: DesignSystem.IconSizes.xs))
                .foregroundColor(.white)
            
            Text("PRO")
                .font(DesignSystem.Typography.smallBold)
                .foregroundColor(.white)
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xs)
                .fill(DesignSystem.Colors.warning)
        )
    }
    
    // MARK: - Computed Properties
    
    private var backgroundFill: Color {
        if isSelected {
            return DesignSystem.Colors.primary.opacity(0.1)
        } else {
            return DesignSystem.Colors.neutral
        }
    }
    
    private var borderColor: Color {
        if isSelected {
            return DesignSystem.Colors.primary
        } else {
            return Color.clear
        }
    }
    
    private var borderWidth: CGFloat {
        isSelected ? 2 : 0
    }
}

// MARK: - Style Example Grid View

struct StyleExampleGridView: View {
    let examples: [StyleExample]
    let selectedExample: StyleExample?
    let onExampleTap: (StyleExample) -> Void
    let onInfoTap: ((StyleExample) -> Void)?
    
    @State private var columns = 2
    
    init(examples: [StyleExample], selectedExample: StyleExample? = nil, onExampleTap: @escaping (StyleExample) -> Void, onInfoTap: ((StyleExample) -> Void)? = nil) {
        self.examples = examples
        self.selectedExample = selectedExample
        self.onExampleTap = onExampleTap
        self.onInfoTap = onInfoTap
    }
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DesignSystem.Spacing.md), count: columns), spacing: DesignSystem.Spacing.md) {
            ForEach(examples) { example in
                StyleExampleView(
                    example: example,
                    isSelected: selectedExample?.id == example.id,
                    onTap: {
                        onExampleTap(example)
                    },
                    onInfoTap: onInfoTap != nil ? {
                        onInfoTap?(example)
                    } : nil
                )
            }
        }
        .onAppear {
            // Track view
            ServiceContainer.shared.analyticsService.track(event: "style_example_grid_viewed", parameters: [
                "example_count": examples.count,
                "columns": columns
            ])
        }
    }
}

// MARK: - Style Example List View

struct StyleExampleListView: View {
    let examples: [StyleExample]
    let selectedExample: StyleExample?
    let onExampleTap: (StyleExample) -> Void
    let onInfoTap: ((StyleExample) -> Void)?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: DesignSystem.Spacing.md) {
                ForEach(examples) { example in
                    StyleExampleRowView(
                        example: example,
                        isSelected: selectedExample?.id == example.id,
                        onTap: {
                            onExampleTap(example)
                        },
                        onInfoTap: onInfoTap != nil ? {
                            onInfoTap?(example)
                        } : nil
                    )
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
        }
        .onAppear {
            // Track view
            ServiceContainer.shared.analyticsService.track(event: "style_example_list_viewed", parameters: [
                "example_count": examples.count
            ])
        }
    }
}

// MARK: - Style Example Row View

struct StyleExampleRowView: View {
    let example: StyleExample
    let isSelected: Bool
    let onTap: () -> Void
    let onInfoTap: (() -> Void)?
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignSystem.Spacing.md) {
                // Sample Image
                if let uiImage = example.uiImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .clipped()
                        .cornerRadius(DesignSystem.CornerRadius.sm)
                } else {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                        .fill(DesignSystem.Colors.neutral)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: DesignSystem.IconSizes.medium))
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        )
                }
                
                // Style Info
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(example.styleName)
                        .font(DesignSystem.Typography.bodyBold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .multilineTextAlignment(.leading)
                    
                    Text(example.description)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        // Category Badge
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Image(systemName: example.category.icon)
                                .font(.system(size: DesignSystem.IconSizes.xs))
                                .foregroundColor(example.category.color)
                            
                            Text(example.category.rawValue)
                                .font(DesignSystem.Typography.small)
                                .foregroundColor(example.category.color)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.xs)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xs)
                                .fill(example.category.color.opacity(0.1))
                        )
                        
                        // Processing Time
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Image(systemName: "clock")
                                .font(.system(size: DesignSystem.IconSizes.xs))
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            
                            Text(example.processingTimeText)
                                .font(DesignSystem.Typography.small)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                        
                        Spacer()
                        
                        // Premium Badge
                        if example.isPremium {
                            Text("PRO")
                                .font(DesignSystem.Typography.smallBold)
                                .foregroundColor(.white)
                                .padding(.horizontal, DesignSystem.Spacing.xs)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xs)
                                        .fill(DesignSystem.Colors.warning)
                                )
                        }
                    }
                }
                
                Spacer()
                
                // Selection Indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: DesignSystem.IconSizes.medium))
                        .foregroundColor(DesignSystem.Colors.primary)
                } else if let onInfoTap = onInfoTap {
                    Button(action: onInfoTap) {
                        Image(systemName: "info.circle")
                            .font(.system(size: DesignSystem.IconSizes.medium))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
            }
            .padding(DesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .fill(isSelected ? DesignSystem.Colors.primary.opacity(0.1) : DesignSystem.Colors.neutral)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                            .stroke(isSelected ? DesignSystem.Colors.primary : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Style Example Detail View

struct StyleExampleDetailView: View {
    let example: StyleExample
    let onSelect: () -> Void
    let onClose: () -> Void
    
    @State private var showingFullImage = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.xl) {
                    // Large Sample Image
                    sampleImageView
                    
                    // Style Information
                    styleInformationView
                    
                    // Tags
                    tagsView
                    
                    // Action Buttons
                    actionButtonsView
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
            }
            .navigationTitle(example.styleName)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Close", action: onClose))
        }
        .onAppear {
            StyleExampleManager.shared.trackStyleExampleViewed(example)
        }
    }
    
    private var sampleImageView: some View {
        Button(action: {
            showingFullImage = true
        }) {
            if let uiImage = example.uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 300)
                    .cornerRadius(DesignSystem.CornerRadius.lg)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                            .stroke(DesignSystem.Colors.neutralDark, lineWidth: 1)
                    )
            } else {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                    .fill(DesignSystem.Colors.neutral)
                    .frame(height: 300)
                    .overlay(
                        VStack(spacing: DesignSystem.Spacing.md) {
                            Image(systemName: "photo")
                                .font(.system(size: DesignSystem.IconSizes.xxlarge))
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            
                            Text("Sample Image")
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                    )
            }
        }
        .sheet(isPresented: $showingFullImage) {
            if let uiImage = example.uiImage {
                FullScreenImageView(image: uiImage)
            }
        }
    }
    
    private var styleInformationView: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Description
            Text(example.description)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .multilineTextAlignment(.center)
            
            // Category and Processing Time
            HStack(spacing: DesignSystem.Spacing.lg) {
                // Category
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: example.category.icon)
                        .font(.system(size: DesignSystem.IconSizes.small))
                        .foregroundColor(example.category.color)
                    
                    Text(example.category.rawValue)
                        .font(DesignSystem.Typography.bodyBold)
                        .foregroundColor(example.category.color)
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                        .fill(example.category.color.opacity(0.1))
                )
                
                // Processing Time
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "clock")
                        .font(.system(size: DesignSystem.IconSizes.small))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Text("Processing: \(example.processingTimeText)")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
            
            // Popularity
            HStack(spacing: DesignSystem.Spacing.sm) {
                Text("Popularity:")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Text(example.popularityStars)
                    .font(.system(size: 16))
                    .foregroundColor(.yellow)
            }
        }
    }
    
    private var tagsView: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Tags")
                .font(DesignSystem.Typography.bodyBold)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: DesignSystem.Spacing.sm) {
                ForEach(example.tags, id: \.self) { tag in
                    Text(tag)
                        .font(DesignSystem.Typography.small)
                        .foregroundColor(DesignSystem.Colors.primary)
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                        .padding(.vertical, DesignSystem.Spacing.xs)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                                .fill(DesignSystem.Colors.primary.opacity(0.1))
                        )
                }
            }
        }
    }
    
    private var actionButtonsView: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Button(action: onSelect) {
                HStack(spacing: DesignSystem.Spacing.md) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: DesignSystem.IconSizes.medium))
                    
                    Text("SELECT THIS STYLE")
                        .font(DesignSystem.Typography.button)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: DesignSystem.Heights.button)
                .background(DesignSystem.Colors.gradientPrimary)
                .cornerRadius(DesignSystem.CornerRadius.lg)
            }
            
            if example.isPremium {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: DesignSystem.IconSizes.small))
                        .foregroundColor(DesignSystem.Colors.warning)
                    
                    Text("Premium Style - Requires Pro Subscription")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.warning)
                }
            }
        }
    }
}

// MARK: - Full Screen Image View

struct FullScreenImageView: View {
    let image: UIImage
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .ignoresSafeArea()
            
            VStack {
                HStack {
                    Spacer()
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                    .padding()
                }
                Spacer()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    StyleExampleView(
        example: StyleExample.mockExamples[0],
        isSelected: true,
        onTap: {},
        onInfoTap: {}
    )
}
