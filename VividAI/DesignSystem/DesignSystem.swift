import SwiftUI
import UIKit

// MARK: - Modern Design System for VividAI
// Based on 2025 UI/UX Trends

struct DesignSystem {
    
    // MARK: - 8-Point Grid System
    struct Spacing {
        static let xs: CGFloat = 4      // 4px
        static let sm: CGFloat = 8      // 8px
        static let md: CGFloat = 16     // 16px
        static let lg: CGFloat = 24     // 24px
        static let xl: CGFloat = 32     // 32px
        static let xxl: CGFloat = 48    // 48px
        static let xxxl: CGFloat = 64   // 64px
        
        // Additional spacing for modern layouts
        static let section: CGFloat = 40    // Between major sections
        static let card: CGFloat = 20       // Card internal padding
        static let button: CGFloat = 12     // Button internal padding
    }
    
    // MARK: - Modern Typography System
    struct Typography {
        // Headings - 4 sizes only
        static let h1 = Font.system(size: 32, weight: .bold, design: .rounded)
        static let h2 = Font.system(size: 24, weight: .semibold, design: .rounded)
        static let h3 = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let h4 = Font.system(size: 18, weight: .semibold, design: .rounded)
        
        // Body text - 2 weights only
        static let body = Font.system(size: 16, weight: .regular)
        static let bodyBold = Font.system(size: 16, weight: .semibold)
        
        // Supporting text
        static let caption = Font.system(size: 14, weight: .medium)
        static let captionBold = Font.system(size: 14, weight: .semibold)
        static let small = Font.system(size: 12, weight: .medium)
        static let smallBold = Font.system(size: 12, weight: .semibold)
        
        // Special cases
        static let button = Font.system(size: 16, weight: .bold)
        static let buttonLarge = Font.system(size: 18, weight: .bold)
        static let monospace = Font.system(size: 16, weight: .regular, design: .monospaced)
    }
    
    // MARK: - Modern Color System (60-30-10 Rule)
    struct Colors {
        // Primary Colors (10% of UI)
        static let primary = Color(red: 0.04, green: 0.52, blue: 0.89)  // Blue
        static let primaryLight = Color(red: 0.2, green: 0.7, blue: 0.95)
        static let primaryDark = Color(red: 0.02, green: 0.35, blue: 0.6)
        
        // Secondary Colors (30% of UI)
        static let secondary = Color(red: 0.42, green: 0.36, blue: 0.91)  // Purple
        static let accent = Color(red: 0.91, green: 0.36, blue: 0.91)     // Pink
        
        // Neutral Colors (60% of UI)
        static let neutral = Color(.systemGray6)
        static let neutralLight = Color(.systemGray5)
        static let neutralDark = Color(.systemGray4)
        static let neutralDarker = Color(.systemGray3)
        
        // Semantic Colors
        static let success = Color(red: 0.2, green: 0.78, blue: 0.35)
        static let warning = Color(red: 1.0, green: 0.58, blue: 0.0)
        static let error = Color(red: 0.96, green: 0.26, blue: 0.21)
        static let info = Color(red: 0.0, green: 0.48, blue: 1.0)
        
        // Background Colors
        static let background = Color(.systemBackground)
        static let backgroundSecondary = Color(.secondarySystemBackground)
        static let backgroundTertiary = Color(.tertiarySystemBackground)
        
        // Text Colors
        static let textPrimary = Color(.label)
        static let textSecondary = Color(.secondaryLabel)
        static let textTertiary = Color(.tertiaryLabel)
        static let textQuaternary = Color(.quaternaryLabel)
        
        // Modern Gradient Colors
        static let gradientPrimary = LinearGradient(
            gradient: Gradient(colors: [primary, secondary, accent]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let gradientSecondary = LinearGradient(
            gradient: Gradient(colors: [secondary, accent]),
            startPoint: .leading,
            endPoint: .trailing
        )
        
        static let gradientNeutral = LinearGradient(
            gradient: Gradient(colors: [neutral, neutralLight]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Shadow color helper (legacy support)
        static let shadow = Color.black.opacity(0.1)
    }
    
    // MARK: - Modern Corner Radius System
    struct CornerRadius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let round: CGFloat = 50
    }
    
    // MARK: - Modern Shadow System
    struct Shadows {
        static let small = Shadow(
            color: Color.black.opacity(0.05),
            radius: 2,
            x: 0,
            y: 1
        )
        
        static let medium = Shadow(
            color: Color.black.opacity(0.1),
            radius: 8,
            x: 0,
            y: 4
        )
        
        static let large = Shadow(
            color: Color.black.opacity(0.15),
            radius: 16,
            x: 0,
            y: 8
        )
        
        static let xlarge = Shadow(
            color: Color.black.opacity(0.2),
            radius: 24,
            x: 0,
            y: 12
        )
        
        // Colored shadows for modern effects
        static let primary = Shadow(
            color: Colors.primary.opacity(0.3),
            radius: 12,
            x: 0,
            y: 6
        )
        
        static let secondary = Shadow(
            color: Colors.secondary.opacity(0.3),
            radius: 12,
            x: 0,
            y: 6
        )
    }
    
    // MARK: - Animation System
    struct Animations {
        static let quick = Animation.easeInOut(duration: 0.2)
        static let standard = Animation.easeInOut(duration: 0.3)
        static let slow = Animation.easeInOut(duration: 0.5)
        static let spring = Animation.spring(response: 0.3, dampingFraction: 0.8)
        static let springBouncy = Animation.spring(response: 0.4, dampingFraction: 0.6)
    }
    
    // MARK: - Modern Component Heights
    struct Heights {
        static let button: CGFloat = 48
        static let buttonLarge: CGFloat = 56
        static let buttonSmall: CGFloat = 40
        static let input: CGFloat = 48
        static let card: CGFloat = 100
        static let cardLarge: CGFloat = 120
        static let header: CGFloat = 60
        static let tabBar: CGFloat = 80
    }
    
    // MARK: - Modern Icon Sizes
    struct IconSizes {
        static let xs: CGFloat = 12      // Extra small
        static let small: CGFloat = 16
        static let medium: CGFloat = 20
        static let large: CGFloat = 24
        static let xlarge: CGFloat = 32
        static let xxlarge: CGFloat = 40
    }
}

// MARK: - Shadow Helper
struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Modern Visual Effects
struct ModernVisualEffects {
    
    // Glass morphism effect
    static func glassMorphism(
        cornerRadius: CGFloat = DesignSystem.CornerRadius.lg,
        blur: CGFloat = 20
    ) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.2),
                                Color.clear
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
    
    // Glass morphism background for Bento Box cards
    static func glassMorphismBackground() -> some ShapeStyle {
        .ultraThinMaterial
    }
    
    // Modern card with subtle effects
    static func modernCard(
        cornerRadius: CGFloat = DesignSystem.CornerRadius.lg,
        shadow: Shadow = DesignSystem.Shadows.medium
    ) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(DesignSystem.Colors.background)
            .shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                DesignSystem.Colors.primary.opacity(0.1),
                                DesignSystem.Colors.secondary.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
    
    // Floating card effect
    static func floatingCard(
        cornerRadius: CGFloat = DesignSystem.CornerRadius.lg
    ) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(DesignSystem.Colors.background)
            .shadow(color: DesignSystem.Shadows.large.color, radius: DesignSystem.Shadows.large.radius, x: DesignSystem.Shadows.large.x, y: DesignSystem.Shadows.large.y)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.3),
                                Color.clear
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
    
    // Glow effect for buttons
    static func glowEffect(
        color: Color = DesignSystem.Colors.primary,
        intensity: CGFloat = 0.3
    ) -> some View {
        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
            .shadow(color: color.opacity(intensity), radius: 12, x: 0, y: 6)
    }
}

// MARK: - Modern Button Styles
struct ModernButtonStyle: ButtonStyle {
    let variant: ButtonVariant
    let size: ButtonSize
    
    enum ButtonVariant {
        case primary
        case secondary
        case ghost
        case destructive
    }
    
    enum ButtonSize {
        case small
        case medium
        case large
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(buttonFont)
            .foregroundColor(buttonTextColor)
            .frame(height: buttonHeight)
            .frame(maxWidth: .infinity)
            .background(buttonBackground(configuration.isPressed))
            .cornerRadius(DesignSystem.CornerRadius.lg)
            .overlay(buttonOverlay)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(DesignSystem.Animations.quick, value: configuration.isPressed)
    }
    
    private var buttonFont: Font {
        switch size {
        case .small: return DesignSystem.Typography.captionBold
        case .medium: return DesignSystem.Typography.button
        case .large: return DesignSystem.Typography.buttonLarge
        }
    }
    
    private var buttonHeight: CGFloat {
        switch size {
        case .small: return DesignSystem.Heights.buttonSmall
        case .medium: return DesignSystem.Heights.button
        case .large: return DesignSystem.Heights.buttonLarge
        }
    }
    
    private var buttonTextColor: Color {
        switch variant {
        case .primary: return .white
        case .secondary: return DesignSystem.Colors.primary
        case .ghost: return DesignSystem.Colors.textPrimary
        case .destructive: return .white
        }
    }
    
    @ViewBuilder
    private func buttonBackground(_ isPressed: Bool) -> some View {
        switch variant {
        case .primary:
            DesignSystem.Colors.gradientPrimary
        case .secondary:
            DesignSystem.Colors.primary.opacity(0.1)
        case .ghost:
            Color.clear
        case .destructive:
            DesignSystem.Colors.error
        }
    }
    
    @ViewBuilder
    private var buttonOverlay: some View {
        switch variant {
        case .primary:
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.2),
                            Color.clear
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        case .secondary:
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(DesignSystem.Colors.primary, lineWidth: 2)
        case .ghost:
            EmptyView()
        case .destructive:
            EmptyView()
        }
    }
}

// MARK: - Modern Card Component
struct ModernCard<Content: View>: View {
    let content: Content
    let padding: CGFloat
    let cornerRadius: CGFloat
    let shadow: Shadow
    
    init(
        padding: CGFloat = DesignSystem.Spacing.card,
        cornerRadius: CGFloat = DesignSystem.CornerRadius.lg,
        shadow: Shadow = DesignSystem.Shadows.medium,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.shadow = shadow
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                ModernVisualEffects.modernCard(
                    cornerRadius: cornerRadius,
                    shadow: shadow
                )
            )
    }
}

// MARK: - Modern Input Field
struct ModernInputField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String?
    let isSecure: Bool
    
    init(
        placeholder: String,
        text: Binding<String>,
        icon: String? = nil,
        isSecure: Bool = false
    ) {
        self.placeholder = placeholder
        self._text = text
        self.icon = icon
        self.isSecure = isSecure
    }
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: DesignSystem.IconSizes.medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .frame(width: DesignSystem.IconSizes.medium)
            }
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            } else {
                TextField(placeholder, text: $text)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .frame(height: DesignSystem.Heights.input)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .fill(DesignSystem.Colors.backgroundSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                        .stroke(DesignSystem.Colors.neutralDark, lineWidth: 1)
                )
        )
    }
}

// MARK: - Modern Loading Indicator
struct ModernLoadingIndicator: View {
    let size: CGFloat
    let color: Color
    
    init(size: CGFloat = 24, color: Color = DesignSystem.Colors.primary) {
        self.size = size
        self.color = color
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 3)
                .frame(width: size, height: size)
            
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [color, color.opacity(0.5)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: UUID())
        }
    }
}

// MARK: - Modern Badge Component
struct ModernBadge: View {
    let text: String
    let color: Color
    let size: BadgeSize
    
    enum BadgeSize {
        case small
        case medium
        case large
    }
    
    init(text: String, color: Color = DesignSystem.Colors.primary, size: BadgeSize = .medium) {
        self.text = text
        self.color = color
        self.size = size
    }
    
    var body: some View {
        Text(text)
            .font(badgeFont)
            .foregroundColor(.white)
            .padding(.horizontal, badgeHorizontalPadding)
            .padding(.vertical, badgeVerticalPadding)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                    .fill(color)
            )
    }
    
    private var badgeFont: Font {
        switch size {
        case .small: return DesignSystem.Typography.smallBold
        case .medium: return DesignSystem.Typography.captionBold
        case .large: return DesignSystem.Typography.bodyBold
        }
    }
    
    private var badgeHorizontalPadding: CGFloat {
        switch size {
        case .small: return DesignSystem.Spacing.sm
        case .medium: return DesignSystem.Spacing.md
        case .large: return DesignSystem.Spacing.lg
        }
    }
    
    private var badgeVerticalPadding: CGFloat {
        switch size {
        case .small: return DesignSystem.Spacing.xs
        case .medium: return DesignSystem.Spacing.sm
        case .large: return DesignSystem.Spacing.md
        }
    }
}


