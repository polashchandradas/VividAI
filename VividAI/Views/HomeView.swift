import SwiftUI
import UIKit

struct HomeView: View {
    @EnvironmentObject var unifiedState: UnifiedAppStateManager
    
    // Modern UI State
    @State private var isDarkMode = false
    @State private var selectedStyle: AvatarStyle?
    @State private var showingRealTimePreview = false
    @State private var animateGradient = false
    @State private var showMicroInteractions = false
    @State private var animateCards = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Modern Background with Gradient Animation
                modernBackground
                
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.xl) {
                        // Modern Header with Dark Mode Toggle
                        modernHeaderSection
                        
                        // Hero Section with Real-Time Preview
                        modernHeroSection
                        
                        // Real-Time Preview Section
                        realTimePreviewSection
                        
                        // Smart Trial Status
                        smartTrialStatusSection
                        
                        // Modern Secondary Features
                        modernSecondaryFeaturesSection
                        
                        // Social Proof with Animation
                        modernSocialProofSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationBarHidden(true)
            .preferredColorScheme(isDarkMode ? .dark : .light)
        }
        .onAppear {
            ServiceContainer.shared.analyticsService.track(event: "home_screen_viewed")
            startAnimations()
        }
        .sheet(isPresented: $showingRealTimePreview) {
            RealTimePreviewView()
        }
    }
    
    // MARK: - Modern Background
    private var modernBackground: some View {
        ZStack {
            // Base background
            DesignSystem.Colors.background
                .ignoresSafeArea()
            
            // Modern animated gradient overlay
            LinearGradient(
                gradient: Gradient(colors: [
                    DesignSystem.Colors.primary.opacity(0.08),
                    DesignSystem.Colors.secondary.opacity(0.05),
                    DesignSystem.Colors.accent.opacity(0.08)
                ]),
                startPoint: animateGradient ? .topLeading : .bottomTrailing,
                endPoint: animateGradient ? .bottomTrailing : .topLeading
            )
            .ignoresSafeArea()
            .animation(DesignSystem.Animations.slow.repeatForever(autoreverses: true), value: animateGradient)
            
            // Subtle noise texture for depth
            RoundedRectangle(cornerRadius: 0)
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.clear,
                            DesignSystem.Colors.neutral.opacity(0.02)
                        ]),
                        center: .center,
                        startRadius: 100,
                        endRadius: 300
                    )
                )
                .ignoresSafeArea()
        }
    }
    
    // MARK: - Modern Header Section
    private var modernHeaderSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text("Welcome to")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .opacity(0.8)
                
                Text("VividAI")
                    .font(DesignSystem.Typography.h1)
                    .foregroundStyle(DesignSystem.Colors.gradientPrimary)
            }
            
            Spacer()
            
            HStack(spacing: DesignSystem.Spacing.md) {
                // Dark Mode Toggle
                Button(action: {
                    withAnimation(DesignSystem.Animations.standard) {
                        isDarkMode.toggle()
                    }
                }) {
                    Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
                        .font(.system(size: DesignSystem.IconSizes.medium, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .frame(width: DesignSystem.Heights.buttonSmall, height: DesignSystem.Heights.buttonSmall)
                        .background(
                            ModernVisualEffects.glassMorphism(cornerRadius: DesignSystem.CornerRadius.md)
                        )
                }
                .scaleEffect(showMicroInteractions ? 1.05 : 1.0)
                .animation(DesignSystem.Animations.spring, value: showMicroInteractions)
                
                // Settings Button
                Button(action: { 
                    ServiceContainer.shared.navigationCoordinator.showSettings()
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: DesignSystem.IconSizes.medium, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .frame(width: DesignSystem.Heights.buttonSmall, height: DesignSystem.Heights.buttonSmall)
                        .background(
                            ModernVisualEffects.glassMorphism(cornerRadius: DesignSystem.CornerRadius.md)
                        )
                }
                .scaleEffect(showMicroInteractions ? 1.05 : 1.0)
                .animation(DesignSystem.Animations.spring, value: showMicroInteractions)
            }
        }
    }
    
    // MARK: - Modern Hero Section
    private var modernHeroSection: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            // Main CTA with Modern Typography
            VStack(spacing: DesignSystem.Spacing.lg) {
                Text("Create Your Professional")
                    .font(DesignSystem.Typography.h2)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("AI Headshot")
                    .font(DesignSystem.Typography.h2)
                    .foregroundStyle(DesignSystem.Colors.gradientPrimary)
                    .multilineTextAlignment(.center)
                
                // Modern Before/After Comparison
                modernBeforeAfterComparison
            }
            
            // Modern Primary CTA Button with Animation
            Button(action: {
                ServiceContainer.shared.analyticsService.track(event: "create_headshot_tapped")
                withAnimation(DesignSystem.Animations.spring) {
                    showMicroInteractions.toggle()
                }
                ServiceContainer.shared.navigationCoordinator.startPhotoUpload()
            }) {
                HStack(spacing: DesignSystem.Spacing.md) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: DesignSystem.IconSizes.large, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("CREATE YOUR HEADSHOT")
                        .font(DesignSystem.Typography.buttonLarge)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: DesignSystem.Heights.buttonLarge + 12)
                .background(
                    DesignSystem.Colors.gradientPrimary
                )
                .cornerRadius(DesignSystem.CornerRadius.xl)
                .overlay(
                    ModernVisualEffects.glowEffect(
                        color: DesignSystem.Colors.primary,
                        intensity: 0.4
                    )
                )
                .scaleEffect(showMicroInteractions ? 1.02 : 1.0)
                .animation(DesignSystem.Animations.spring, value: showMicroInteractions)
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
        }
    }
    
    // MARK: - Real-Time Preview Section
    private var realTimePreviewSection: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            HStack {
                Text("Real-Time Preview")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    ServiceContainer.shared.analyticsService.track(event: "realtime_preview_tapped")
                    showingRealTimePreview = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "bolt.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.orange)
                        
                        Text("Try Now")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.orange.opacity(0.1))
                    )
                }
            }
            
            // Real-Time Preview Cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(AvatarStyle.allStyles.prefix(4), id: \.id) { style in
                        RealTimePreviewCard(
                            style: style,
                            isGenerating: ServiceContainer.shared.realTimeGenerationService.isGeneratingPreview,
                            onTap: {
                                selectedStyle = style
                                ServiceContainer.shared.analyticsService.track(event: "style_preview_tapped", parameters: ["style": style.name])
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Modern Before/After Comparison
    private var modernBeforeAfterComparison: some View {
        ModernCard(
            padding: DesignSystem.Spacing.xl,
            cornerRadius: DesignSystem.CornerRadius.xl,
            shadow: DesignSystem.Shadows.medium
        ) {
            HStack(spacing: DesignSystem.Spacing.xl) {
                // Before
                VStack(spacing: DesignSystem.Spacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                            .fill(DesignSystem.Colors.neutralDark)
                            .frame(width: 90, height: 110)
                            .overlay(
                                Image(systemName: "person.crop.circle")
                                    .font(.system(size: 45))
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                            )
                        
                        // Loading animation
                        if showMicroInteractions {
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                                .stroke(DesignSystem.Colors.primary, lineWidth: 2)
                                .frame(width: 90, height: 110)
                                .opacity(0.6)
                        }
                    }
                    
                    Text("Before")
                        .font(DesignSystem.Typography.captionBold)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                // Animated Arrow
                VStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "arrow.right")
                        .font(.system(size: DesignSystem.IconSizes.large, weight: .bold))
                        .foregroundColor(DesignSystem.Colors.primary)
                        .scaleEffect(showMicroInteractions ? 1.2 : 1.0)
                        .animation(DesignSystem.Animations.standard.repeatForever(autoreverses: true), value: showMicroInteractions)
                    
                    Text("AI Magic")
                        .font(DesignSystem.Typography.small)
                        .foregroundColor(DesignSystem.Colors.primary)
                }
                
                // After
                VStack(spacing: DesignSystem.Spacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        DesignSystem.Colors.primary.opacity(0.3),
                                        DesignSystem.Colors.secondary.opacity(0.3),
                                        DesignSystem.Colors.accent.opacity(0.3)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 90, height: 110)
                            .overlay(
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.system(size: 45))
                                    .foregroundColor(DesignSystem.Colors.primary)
                            )
                        
                        // Premium badge
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "sparkles")
                                    .font(.system(size: DesignSystem.IconSizes.small))
                                    .foregroundColor(DesignSystem.Colors.warning)
                                    .padding(DesignSystem.Spacing.xs)
                                    .background(Color.white)
                                    .clipShape(Circle())
                            }
                            Spacer()
                        }
                        .padding(DesignSystem.Spacing.sm)
                    }
                    
                    Text("After")
                        .font(DesignSystem.Typography.captionBold)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
    }
    
    // MARK: - Modern Secondary Features Section
    private var modernSecondaryFeaturesSection: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            HStack {
                Text("Also Try")
                    .font(DesignSystem.Typography.h3)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
            }
            
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: DesignSystem.Spacing.md), count: 2),
                spacing: DesignSystem.Spacing.md
            ) {
                // Real-Time Preview
                ModernFeatureCard(
                    icon: "bolt.circle.fill",
                    title: "Real-Time",
                    subtitle: "Preview",
                    color: DesignSystem.Colors.warning,
                    action: {
                        ServiceContainer.shared.analyticsService.track(event: "realtime_preview_tapped")
                        showingRealTimePreview = true
                    }
                )
                
                // Background Removal
                ModernFeatureCard(
                    icon: "photo.on.rectangle.angled",
                    title: "Background",
                    subtitle: "Removal",
                    color: DesignSystem.Colors.primary,
                    action: {
                        ServiceContainer.shared.analyticsService.track(event: "background_removal_tapped")
                        ServiceContainer.shared.navigationCoordinator.startPhotoUpload()
                    }
                )
                
                // Photo Enhancement
                ModernFeatureCard(
                    icon: "wand.and.stars",
                    title: "Photo",
                    subtitle: "Enhance",
                    color: DesignSystem.Colors.secondary,
                    action: {
                        ServiceContainer.shared.analyticsService.track(event: "photo_enhancement_tapped")
                        ServiceContainer.shared.navigationCoordinator.startPhotoUpload()
                    }
                )
                
                // Video Generation
                ModernFeatureCard(
                    icon: "video.fill",
                    title: "Video",
                    subtitle: "Generation",
                    color: DesignSystem.Colors.success,
                    action: {
                        ServiceContainer.shared.analyticsService.track(event: "video_generation_tapped")
                        ServiceContainer.shared.navigationCoordinator.startPhotoUpload()
                    }
                )
            }
        }
    }
    
    // MARK: - Smart Trial Status Section
    private var smartTrialStatusSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            if ServiceContainer.shared.subscriptionStateManager.isTrialActive {
                // Active Trial Status
                ModernCard(
                    padding: DesignSystem.Spacing.md,
                    cornerRadius: DesignSystem.CornerRadius.lg,
                    shadow: DesignSystem.Shadows.small
                ) {
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(DesignSystem.Colors.warning)
                            
                            Text("Free Trial Active")
                                .font(DesignSystem.Typography.bodyBold)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            
                            Spacer()
                            
                            Text("\(ServiceContainer.shared.subscriptionStateManager.trialDaysRemaining) days left")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                        
                        HStack {
                            Text("\(ServiceContainer.shared.subscriptionStateManager.trialGenerationsUsed)/\(ServiceContainer.shared.subscriptionStateManager.trialMaxGenerations) generations used")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            
                            Spacer()
                            
                            if ServiceContainer.shared.subscriptionStateManager.canGenerate {
                                Text("Can generate")
                                    .font(DesignSystem.Typography.captionBold)
                                    .foregroundColor(DesignSystem.Colors.success)
                            } else {
                                Text("Limit reached")
                                    .font(DesignSystem.Typography.captionBold)
                                    .foregroundColor(DesignSystem.Colors.warning)
                            }
                        }
                    }
                }
                .background(DesignSystem.Colors.warning.opacity(0.1))
            } else if !unifiedState.isPremiumUser {
                // Free User Status
                ModernCard(
                    padding: DesignSystem.Spacing.md,
                    cornerRadius: DesignSystem.CornerRadius.lg,
                    shadow: DesignSystem.Shadows.small
                ) {
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        HStack {
                            Image(systemName: "gift.fill")
                                .foregroundColor(DesignSystem.Colors.primary)
                            
                            Text("Free User")
                                .font(DesignSystem.Typography.bodyBold)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            
                            Spacer()
                            
                            Button("Start Free Trial") {
                                ServiceContainer.shared.appCoordinator.startFreeTrial(type: .limited)
                                ServiceContainer.shared.analyticsService.track(event: "start_free_trial_tapped")
                            }
                            .font(DesignSystem.Typography.captionBold)
                            .foregroundColor(DesignSystem.Colors.primary)
                        }
                        
                        HStack {
                            Text("\(ServiceContainer.shared.subscriptionStateManager.getRemainingGenerations()) generations remaining today")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            
                            Spacer()
                            
                            Button("Upgrade to Pro") {
                                ServiceContainer.shared.navigationCoordinator.showPaywall()
                                ServiceContainer.shared.analyticsService.track(event: "upgrade_to_pro_tapped")
                            }
                            .font(DesignSystem.Typography.captionBold)
                            .foregroundColor(DesignSystem.Colors.success)
                        }
                    }
                }
                .background(DesignSystem.Colors.primary.opacity(0.1))
            } else {
                // Premium User Status
                ModernCard(
                    padding: DesignSystem.Spacing.md,
                    cornerRadius: DesignSystem.CornerRadius.lg,
                    shadow: DesignSystem.Shadows.small
                ) {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundColor(DesignSystem.Colors.warning)
                        
                        Text("Pro Member - Unlimited Generations")
                            .font(DesignSystem.Typography.bodyBold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Spacer()
                        
                        Text("✓")
                            .font(DesignSystem.Typography.bodyBold)
                            .foregroundColor(DesignSystem.Colors.success)
                    }
                }
                .background(DesignSystem.Colors.success.opacity(0.1))
            }
        }
    }
    
    // MARK: - Modern Social Proof Section
    private var modernSocialProofSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Trust indicators
            HStack(spacing: DesignSystem.Spacing.lg) {
                TrustIndicator(
                    icon: "checkmark.shield.fill",
                    text: "No signup required",
                    color: DesignSystem.Colors.success
                )
                
                TrustIndicator(
                    icon: "lock.shield.fill",
                    text: "Privacy protected",
                    color: DesignSystem.Colors.primary
                )
            }
            
            // Social proof with animation
            ModernCard(
                padding: DesignSystem.Spacing.lg,
                cornerRadius: DesignSystem.CornerRadius.lg,
                shadow: DesignSystem.Shadows.small
            ) {
                HStack(spacing: DesignSystem.Spacing.md) {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        ForEach(0..<5) { index in
                            Image(systemName: "star.fill")
                                .font(.system(size: DesignSystem.IconSizes.small))
                                .foregroundColor(DesignSystem.Colors.warning)
                                .scaleEffect(showMicroInteractions ? 1.1 : 1.0)
                                .animation(DesignSystem.Animations.standard.delay(Double(index) * 0.1), value: showMicroInteractions)
                        }
                    }
                    
                    Text("2.3M+ headshots created")
                        .font(DesignSystem.Typography.bodyBold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
            }
        }
    }
    
    // MARK: - Animation Functions
    private func startAnimations() {
        withAnimation(DesignSystem.Animations.slow.repeatForever(autoreverses: true)) {
            animateGradient.toggle()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(DesignSystem.Animations.spring) {
                showMicroInteractions.toggle()
            }
        }
    }
}

// MARK: - Supporting Views

struct RealTimePreviewCard: View {
    let style: AvatarStyle
    let isGenerating: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: DesignSystem.Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                        .fill(DesignSystem.Colors.gradientNeutral)
                        .frame(width: 100, height: 120)
                        .overlay(
                            VStack(spacing: DesignSystem.Spacing.sm) {
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.system(size: DesignSystem.IconSizes.xlarge))
                                    .foregroundColor(DesignSystem.Colors.primary)
                                
                                if isGenerating {
                                    ModernLoadingIndicator(size: 20, color: DesignSystem.Colors.primary)
                                }
                            }
                        )
                    
                    // Premium badge
                    if style.isPremium {
                        VStack {
                            HStack {
                                Spacer()
                                ModernBadge(
                                    text: "PRO",
                                    color: DesignSystem.Colors.warning,
                                    size: .small
                                )
                            }
                            Spacer()
                        }
                        .padding(DesignSystem.Spacing.sm)
                    }
                }
                
                Text(style.name)
                    .font(DesignSystem.Typography.captionBold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ModernFeatureCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignSystem.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: DesignSystem.IconSizes.xlarge, weight: .semibold))
                    .foregroundColor(color)
                
                VStack(spacing: DesignSystem.Spacing.xs) {
                    Text(title)
                        .font(DesignSystem.Typography.captionBold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text(subtitle)
                        .font(DesignSystem.Typography.captionBold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: DesignSystem.Heights.card)
            .background(
                ModernVisualEffects.modernCard(
                    cornerRadius: DesignSystem.CornerRadius.lg,
                    shadow: DesignSystem.Shadows.small
                )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(DesignSystem.Animations.quick, value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onTapGesture {
            withAnimation(DesignSystem.Animations.quick) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(DesignSystem.Animations.quick) {
                    isPressed = false
                }
            }
        }
    }
}

struct TrustIndicator: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: DesignSystem.IconSizes.small, weight: .semibold))
                .foregroundColor(color)
            
            Text(text)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                .fill(color.opacity(0.1))
        )
    }
}

struct RealTimePreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedImage: UIImage?
    @State private var selectedStyle: AvatarStyle?
    @State private var isShowingImagePicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                Text("Real-Time Preview")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                
                // Image selection
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 200)
                        .cornerRadius(16)
                } else {
                    Button("Select Image") {
                        isShowingImagePicker = true
                    }
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.blue)
                    )
                }
                
                // Style selection
                if selectedImage != nil {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(AvatarStyle.allStyles, id: \.id) { style in
                                StyleSelectionCard(
                                    style: style,
                                    isSelected: selectedStyle?.id == style.id,
                                    onTap: {
                                        selectedStyle = style
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $isShowingImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
    }
}

struct StyleSelectionCard: View {
    let style: AvatarStyle
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color(.systemGray6))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(isSelected ? .white : .blue)
                    )
                
                Text(style.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(UnifiedAppStateManager.shared)
}
