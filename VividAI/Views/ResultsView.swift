import SwiftUI
import UIKit

struct ResultsView: View {
    @EnvironmentObject var unifiedState: UnifiedAppStateManager
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    @EnvironmentObject var analyticsService: AnalyticsService
    @EnvironmentObject var appCoordinator: AppCoordinator
    @State private var selectedHeadshot: HeadshotStyle?
    @State private var showingPaywall = false
    @State private var showingShareView = false
    @State private var showingFullScreen = false
    
    // Get headshot styles from navigation coordinator
    private var headshotStyles: [HeadshotStyle] {
        navigationCoordinator.processingResults.map { result in
            HeadshotStyle(
                id: result.id,
                name: result.style,
                image: result.imageURL,
                isPremium: result.isPremium
            )
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.xl) {
                        // Header
                        headerSection
                        
                        // Results Grid
                        resultsGridSection
                        
                        // Watermark Notice
                        watermarkNoticeSection
                        
                        // Action Buttons
                        actionButtonsSection
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.top, DesignSystem.Spacing.lg)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showingShareView) {
                ShareView()
            }
            .fullScreenCover(isPresented: $showingFullScreen) {
                if let selected = selectedHeadshot {
                    FullScreenHeadshotView(headshot: selected)
                }
            }
        }
        .onAppear {
            analyticsService.track(event: "results_screen_viewed")
        }
    }
    
    private var headerSection: some View {
        HStack {
            Button(action: { 
                navigationCoordinator.navigateBack()
            }) {
                Image(systemName: "arrow.left")
                    .font(.system(size: DesignSystem.IconSizes.medium, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
            
            Spacer()
            
            Text("Your Headshots")
                .font(DesignSystem.Typography.h4)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Spacer()
            
            Button(action: { 
                navigationCoordinator.showSettings()
            }) {
                Image(systemName: "gearshape")
                    .font(.system(size: DesignSystem.IconSizes.medium, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
        }
    }
    
    private var resultsGridSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Text("Tap any to view full")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DesignSystem.Spacing.md), count: 2), spacing: DesignSystem.Spacing.md) {
                ForEach(headshotStyles) { headshot in
                    HeadshotCard(
                        headshot: headshot,
                        onTap: {
                            selectedHeadshot = headshot
                            if headshot.isPremium && !unifiedState.isPremiumUser {
                                navigationCoordinator.showPaywall()
                            } else {
                                showingFullScreen = true
                            }
                        }
                    )
                }
            }
        }
    }
    
    private var watermarkNoticeSection: some View {
        ModernCard(
            padding: DesignSystem.Spacing.md,
            cornerRadius: DesignSystem.CornerRadius.md,
            shadow: DesignSystem.Shadows.small
        ) {
            HStack(spacing: DesignSystem.Spacing.md) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(DesignSystem.Colors.warning)
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Watermarked (Free)")
                        .font(DesignSystem.Typography.captionBold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text("Upgrade to remove watermarks and unlock all styles")
                        .font(DesignSystem.Typography.small)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
            }
        }
        .background(DesignSystem.Colors.warning.opacity(0.1))
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Primary CTA - Remove Watermark
            Button(action: {
                analyticsService.track(event: "remove_watermark_tapped")
                navigationCoordinator.showPaywall()
            }) {
                HStack(spacing: DesignSystem.Spacing.md) {
                    Image(systemName: "lock.open.fill")
                        .font(.system(size: DesignSystem.IconSizes.medium, weight: .semibold))
                    
                    Text("REMOVE WATERMARK")
                        .font(DesignSystem.Typography.button)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: DesignSystem.Heights.button)
                .background(DesignSystem.Colors.gradientPrimary)
                .cornerRadius(DesignSystem.CornerRadius.lg)
                .shadow(color: DesignSystem.Colors.shadow, radius: DesignSystem.Shadows.medium.radius, x: 0, y: 4)
            }
            
            // Secondary Actions
            HStack(spacing: DesignSystem.Spacing.md) {
                Button(action: {
                    analyticsService.track(event: "share_tapped")
                    // Generate video and show share view
                    if let originalImage = navigationCoordinator.selectedImage,
                       let firstResult = navigationCoordinator.processingResults.first {
                        // Use actual AI-generated headshot for video generation
                        let _ = loadHeadshotImage(from: firstResult.imageURL) ?? originalImage
                        // Video generation handled by coordinator
                        // appCoordinator.generateTransformationVideo(from: originalImage, to: enhancedImage)
                    }
                }) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: DesignSystem.IconSizes.small, weight: .semibold))
                        
                        Text("SHARE")
                            .font(DesignSystem.Typography.captionBold)
                    }
                    .foregroundColor(DesignSystem.Colors.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: DesignSystem.Heights.buttonSmall)
                    .background(DesignSystem.Colors.primary.opacity(0.1))
                    .cornerRadius(DesignSystem.CornerRadius.md)
                }
                
                Button(action: {
                    analyticsService.track(event: "save_tapped")
                    // Save functionality
                }) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: DesignSystem.IconSizes.small, weight: .semibold))
                        
                        Text("SAVE")
                            .font(DesignSystem.Typography.captionBold)
                    }
                    .foregroundColor(DesignSystem.Colors.success)
                    .frame(maxWidth: .infinity)
                    .frame(height: DesignSystem.Heights.buttonSmall)
                    .background(DesignSystem.Colors.success.opacity(0.1))
                    .cornerRadius(DesignSystem.CornerRadius.md)
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct HeadshotCard: View {
    let headshot: HeadshotStyle
    @EnvironmentObject var unifiedState: UnifiedAppStateManager
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: DesignSystem.Spacing.sm) {
                // Image
                ZStack {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                        .fill(DesignSystem.Colors.neutral)
                        .frame(height: 120)
                        .overlay(
                            VStack(spacing: DesignSystem.Spacing.sm) {
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.system(size: DesignSystem.IconSizes.xxlarge))
                                    .foregroundColor(DesignSystem.Colors.primary)
                                
                                if headshot.isPremium && !unifiedState.isPremiumUser {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: DesignSystem.IconSizes.small))
                                        .foregroundColor(DesignSystem.Colors.warning)
                                }
                            }
                        )
                    
                    // Premium Badge
                    if headshot.isPremium && !unifiedState.isPremiumUser {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "crown.fill")
                                    .font(.system(size: DesignSystem.IconSizes.xs))
                                    .foregroundColor(DesignSystem.Colors.warning)
                                    .padding(4)
                                    .background(Color.white)
                                    .clipShape(Circle())
                            }
                            Spacer()
                        }
                        .padding(DesignSystem.Spacing.sm)
                    }
                }
                
                // Style Name
                Text(headshot.name)
                    .font(DesignSystem.Typography.small)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FullScreenHeadshotView: View {
    let headshot: HeadshotStyle
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Full Screen Image
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                        .fill(DesignSystem.Colors.neutral)
                        .frame(maxWidth: .infinity, maxHeight: 400)
                        .overlay(
                            VStack(spacing: DesignSystem.Spacing.md) {
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(DesignSystem.Colors.primary)
                                
                                Text(headshot.name)
                                    .font(DesignSystem.Typography.h4)
                                    .foregroundColor(.white)
                            }
                        )
                    
                    // Style Name
                    Text(headshot.name)
                        .font(DesignSystem.Typography.h3)
                        .foregroundColor(.white)
                    
                    // Action Buttons
                    HStack(spacing: DesignSystem.Spacing.md) {
                        Button("Share") {
                            // Share functionality
                        }
                        .font(DesignSystem.Typography.button)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: DesignSystem.Heights.buttonSmall)
                        .background(DesignSystem.Colors.primary)
                        .cornerRadius(DesignSystem.CornerRadius.md)
                        
                        Button("Save") {
                            // Save functionality
                        }
                        .font(DesignSystem.Typography.button)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: DesignSystem.Heights.buttonSmall)
                        .background(DesignSystem.Colors.success)
                        .cornerRadius(DesignSystem.CornerRadius.md)
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

// MARK: - Helper Functions

private func loadHeadshotImage(from urlString: String) -> UIImage? {
    guard let url = URL(string: urlString) else { return nil }
    
    do {
        let data = try Data(contentsOf: url)
        return UIImage(data: data)
    } catch {
        print("Failed to load headshot image: \(error.localizedDescription)")
        return nil
    }
}

// MARK: - Data Models

struct HeadshotStyle: Identifiable {
    let id: Int
    let name: String
    let image: String
    let isPremium: Bool
}

#Preview {
    ResultsView()
        .environmentObject(UnifiedAppStateManager.shared)
        .environmentObject(NavigationCoordinator())
        .environmentObject(AnalyticsService.shared)
        .environmentObject(AppCoordinator())
}
