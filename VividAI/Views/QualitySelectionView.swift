import SwiftUI

struct QualitySelectionView: View {
    @EnvironmentObject var unifiedState: UnifiedAppStateManager
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    @EnvironmentObject var analyticsService: AnalyticsService
    @EnvironmentObject var appCoordinator: AppCoordinator
    @Binding var selectedImage: UIImage?
    @State private var selectedQuality: HybridProcessingService.QualityLevel = .standard
    @State private var showingProcessing = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Header
                    headerSection
                    
                    // Image Preview
                    imagePreviewSection
                    
                    // Quality Options
                    qualityOptionsSection
                    
                    // Processing Info
                    processingInfoSection
                    
                    // Action Buttons
                    actionButtonsSection
                    
                    Spacer()
                }
                .padding(.horizontal, DesignSystem.Spacing.card)
                .padding(.top, DesignSystem.Spacing.card)
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            analyticsService.track(event: "quality_selection_viewed")
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
            
            Text("Choose Quality")
                .font(DesignSystem.Typography.h4)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Spacer()
            
            Color.clear
                .frame(width: DesignSystem.IconSizes.medium, height: DesignSystem.IconSizes.medium)
        }
    }
    
    private var imagePreviewSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 200)
                    .cornerRadius(DesignSystem.CornerRadius.lg)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                            .stroke(DesignSystem.Colors.primary, lineWidth: 2)
                    )
            } else {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                    .fill(DesignSystem.Colors.neutral)
                    .frame(height: 200)
                    .overlay(
                        VStack(spacing: DesignSystem.Spacing.sm) {
                            Image(systemName: "photo")
                                .font(.system(size: DesignSystem.IconSizes.xxlarge))
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            
                            Text("No image selected")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                    )
            }
        }
    }
    
    private var qualityOptionsSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Text("Select Processing Quality")
                .font(DesignSystem.Typography.h4)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            VStack(spacing: DesignSystem.Spacing.md) {
                QualityOptionCard(
                    quality: .preview,
                    title: "Preview",
                    description: "Fast, on-device processing",
                    time: "2-3 seconds",
                    isSelected: selectedQuality == .preview,
                    onTap: { selectedQuality = .preview }
                )
                
                QualityOptionCard(
                    quality: .standard,
                    title: "Standard",
                    description: "Balanced quality and speed",
                    time: "5-10 seconds",
                    isSelected: selectedQuality == .standard,
                    onTap: { selectedQuality = .standard }
                )
                
                QualityOptionCard(
                    quality: .premium,
                    title: "Premium",
                    description: "High-quality cloud processing",
                    time: "15-30 seconds",
                    isSelected: selectedQuality == .premium,
                    onTap: { selectedQuality = .premium }
                )
                
                QualityOptionCard(
                    quality: .ultra,
                    title: "Ultra",
                    description: "Maximum quality, cloud processing",
                    time: "30-60 seconds",
                    isSelected: selectedQuality == .ultra,
                    onTap: { selectedQuality = .ultra }
                )
            }
        }
    }
    
    private var processingInfoSection: some View {
        ModernCard(
            padding: DesignSystem.Spacing.md,
            cornerRadius: DesignSystem.CornerRadius.md,
            shadow: DesignSystem.Shadows.small
        ) {
            VStack(spacing: DesignSystem.Spacing.md) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(DesignSystem.Colors.primary)
                    
                    Text("Processing Information")
                        .font(DesignSystem.Typography.bodyBold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    processingInfoRow(
                        icon: "bolt.fill",
                        title: "Speed",
                        value: getSpeedDescription(for: selectedQuality)
                    )
                    
                    processingInfoRow(
                        icon: "star.fill",
                        title: "Quality",
                        value: getQualityDescription(for: selectedQuality)
                    )
                    
                    processingInfoRow(
                        icon: "wifi",
                        title: "Network",
                        value: getNetworkDescription(for: selectedQuality)
                    )
                }
            }
        }
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Button(action: {
                startProcessing()
            }) {
                HStack(spacing: DesignSystem.Spacing.md) {
                    Image(systemName: "sparkles")
                        .font(.system(size: DesignSystem.IconSizes.medium, weight: .semibold))
                    
                    Text("START PROCESSING")
                        .font(DesignSystem.Typography.button)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: DesignSystem.Heights.button)
                .background(DesignSystem.Colors.gradientPrimary)
                .cornerRadius(DesignSystem.CornerRadius.lg)
                .shadow(color: DesignSystem.Colors.shadow, radius: DesignSystem.Shadows.medium.radius, x: 0, y: 4)
            }
            .disabled(selectedImage == nil || showingProcessing)
            .opacity(selectedImage == nil || showingProcessing ? 0.6 : 1.0)
            
            if showingProcessing {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    ModernLoadingIndicator(size: 20, color: DesignSystem.Colors.primary)
                    
                    Text("Processing with \(selectedQuality) quality...")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
        }
    }
    
    private func processingInfoRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: DesignSystem.IconSizes.small, weight: .semibold))
                .foregroundColor(DesignSystem.Colors.primary)
                .frame(width: 20)
            
            Text(title)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Spacer()
            
            Text(value)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
    }
    
    private func getSpeedDescription(for quality: HybridProcessingService.QualityLevel) -> String {
        switch quality {
        case .preview: return "Very Fast"
        case .standard: return "Fast"
        case .premium: return "Medium"
        case .ultra: return "Slow"
        }
    }
    
    private func getQualityDescription(for quality: HybridProcessingService.QualityLevel) -> String {
        switch quality {
        case .preview: return "Basic"
        case .standard: return "Good"
        case .premium: return "High"
        case .ultra: return "Maximum"
        }
    }
    
    private func getNetworkDescription(for quality: HybridProcessingService.QualityLevel) -> String {
        switch quality {
        case .preview: return "Not Required"
        case .standard: return "Optional"
        case .premium: return "Required"
        case .ultra: return "Required"
        }
    }
    
    private func startProcessing() {
        guard let image = selectedImage else { return }
        
        showingProcessing = true
        
        analyticsService.track(event: "processing_started_with_quality", parameters: [
            "quality": "\(selectedQuality)",
            "image_width": image.size.width,
            "image_height": image.size.height
        ])
        
        // Use hybrid processing with selected quality
        appCoordinator.processImageWithQuality(image, quality: selectedQuality)
    }
}

// MARK: - Quality Option Card

struct QualityOptionCard: View {
    let quality: HybridProcessingService.QualityLevel
    let title: String
    let description: String
    let time: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignSystem.Spacing.md) {
                // Selection Indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.neutralDark, lineWidth: 2)
                        .frame(width: 20, height: 20)
                    
                    if isSelected {
                        Circle()
                            .fill(DesignSystem.Colors.primary)
                            .frame(width: 12, height: 12)
                    }
                }
                
                // Quality Info
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    HStack {
                        Text(title)
                            .font(DesignSystem.Typography.bodyBold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        if quality == .premium || quality == .ultra {
                            Text("PRO")
                                .font(DesignSystem.Typography.smallBold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(DesignSystem.Colors.warning)
                                .cornerRadius(4)
                        }
                        
                        Spacer()
                    }
                    
                    Text(description)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    HStack {
                        Image(systemName: "clock")
                            .font(.system(size: DesignSystem.IconSizes.xs))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        Text(time)
                            .font(DesignSystem.Typography.small)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.md)
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

#Preview {
    QualitySelectionView(selectedImage: .constant(nil))
        .environmentObject(UnifiedAppStateManager.shared)
}
