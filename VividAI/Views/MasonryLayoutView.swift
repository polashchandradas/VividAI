import SwiftUI
import UIKit

// MARK: - Masonry Layout View (Bento Box Style - 2025 Trend)

/// Modern masonry layout inspired by Apple's Bento Box design pattern
/// Supports dynamic sizing, smooth animations, and modern interactivity
struct MasonryLayoutView<Data, ItemView>: View where Data: RandomAccessCollection, Data.Element: Identifiable, ItemView: View {
    
    // MARK: - Properties
    let items: Data
    let columns: Int
    let spacing: CGFloat
    let itemBuilder: (Data.Element) -> ItemView
    let itemSizes: [Data.Element.ID: CGSize]
    let onItemAppear: ((Data.Element) -> Void)?
    
    @State private var viewHeight: CGFloat = 0
    
    // MARK: - Initializer
    
    init(
        items: Data,
        columns: Int = 2,
        spacing: CGFloat = 16,
        itemSizes: [Data.Element.ID: CGSize] = [:],
        onItemAppear: ((Data.Element) -> Void)? = nil,
        @ViewBuilder itemBuilder: @escaping (Data.Element) -> ItemView
    ) {
        self.items = items
        self.columns = columns
        self.spacing = spacing
        self.itemSizes = itemSizes
        self.onItemAppear = onItemAppear
        self.itemBuilder = itemBuilder
    }
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            let columnWidth = (geometry.size.width - spacing * CGFloat(columns - 1)) / CGFloat(columns)
            
            ScrollView {
                LazyVStack(spacing: spacing) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        let size = itemSizes[item.id] ?? CGSize(width: columnWidth, height: 150)
                        
                        itemBuilder(item)
                            .frame(width: columnWidth, height: size.height)
                            .modifier(MasonryCardModifier())
                            .onAppear {
                                onItemAppear?(item)
                            }
                    }
                }
                .padding(.horizontal, spacing)
            }
        }
    }
}

// MARK: - Masonry Card Modifier

struct MasonryCardModifier: ViewModifier {
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(ModernVisualEffects.glassMorphismBackground())
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.3),
                                Color.clear
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(
                color: Color.black.opacity(0.1),
                radius: 10,
                x: 0,
                y: 5
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
    }
}

// MARK: - Bento Box Card View

struct BentoBoxCard: View {
    let item: MasonryItem
    let onTap: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Icon or Image
                if let icon = item.icon {
                    Image(systemName: icon)
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(item.gradient)
                }
                
                // Title
                Text(item.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                // Subtitle
                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Badge
                if let badge = item.badge {
                    HStack {
                        Text(badge)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(item.gradient)
                            )
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(isHovered ? 0.5 : 0.2),
                                Color.clear
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isHovered ? 2 : 1
                    )
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Masonry Item Model

struct MasonryItem: Identifiable {
    let id: String
    let title: String
    let subtitle: String?
    let icon: String?
    let badge: String?
    let gradient: LinearGradient
    let size: CGSize
    
    static let examples: [MasonryItem] = [
        MasonryItem(
            id: "1",
            title: "AI Headshots",
            subtitle: "Professional quality in seconds",
            icon: "person.crop.circle.fill.badge.plus",
            badge: "Popular",
            gradient: LinearGradient(
                colors: [Color.blue, Color.purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            size: CGSize(width: 1, height: 200)
        ),
        MasonryItem(
            id: "2",
            title: "Background Removal",
            subtitle: "One-tap magic",
            icon: "photo.on.rectangle.angled",
            badge: nil,
            gradient: LinearGradient(
                colors: [Color.green, Color.blue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            size: CGSize(width: 1, height: 150)
        ),
        MasonryItem(
            id: "3",
            title: "Photo Enhancement",
            subtitle: "Transform your photos with AI",
            icon: "wand.and.stars",
            badge: "New",
            gradient: LinearGradient(
                colors: [Color.pink, Color.orange],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            size: CGSize(width: 1, height: 180)
        ),
        MasonryItem(
            id: "4",
            title: "Video Generation",
            subtitle: "Create stunning transformation videos",
            icon: "video.fill",
            badge: nil,
            gradient: LinearGradient(
                colors: [Color.purple, Color.pink],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            size: CGSize(width: 1, height: 160)
        ),
        MasonryItem(
            id: "5",
            title: "Real-Time Preview",
            subtitle: "See results before generating",
            icon: "bolt.circle.fill",
            badge: "Featured",
            gradient: LinearGradient(
                colors: [Color.orange, Color.red],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            size: CGSize(width: 1, height: 170)
        ),
        MasonryItem(
            id: "6",
            title: "Style Gallery",
            subtitle: "20+ professional styles",
            icon: "square.grid.3x3.fill",
            badge: nil,
            gradient: LinearGradient(
                colors: [Color.cyan, Color.blue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            size: CGSize(width: 1, height: 140)
        )
    ]
}

// MARK: - Bento Box Feature Card (HomeView Integration)

struct BentoBoxFeatureCard: View {
    let item: MasonryItem
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Icon
                if let icon = item.icon {
                    Image(systemName: icon)
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(item.gradient)
                }
                
                // Title
                Text(item.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                
                // Subtitle
                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Badge
                if let badge = item.badge {
                    HStack {
                        Text(badge)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(item.gradient)
                            )
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: item.size.height)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(isHovered ? 0.5 : 0.2),
                                Color.clear
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isHovered ? 2 : 1
                    )
            )
            .shadow(
                color: Color.black.opacity(isHovered ? 0.15 : 0.05),
                radius: isHovered ? 15 : 8,
                x: 0,
                y: isHovered ? 8 : 4
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    isHovered = true
                }
                .onEnded { _ in
                    isHovered = false
                }
        )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(MasonryItem.examples) { item in
                    BentoBoxCard(item: item) {
                        print("Tapped: \(item.title)")
                    }
                }
            }
            .padding()
        }
    }
}
