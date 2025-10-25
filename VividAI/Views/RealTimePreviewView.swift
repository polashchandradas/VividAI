import SwiftUI
import UIKit
import Combine

// MARK: - Real-Time Preview View

struct RealTimePreviewView: View {
    @EnvironmentObject var serviceContainer: ServiceContainer
    @EnvironmentObject var appCoordinator: AppCoordinator
    @EnvironmentObject var subscriptionStateManager: SubscriptionStateManager
    
    @State private var selectedImage: UIImage?
    @State private var selectedStyle: AvatarStyle?
    @State private var isShowingStylePicker = false
    @State private var previews: [StylePreview] = []
    @State private var isGenerating = false
    @State private var generationProgress: Double = 0.0
    
    // Real-time preview state
    @State private var currentPreview: UIImage?
    @State private var previewTimer: Timer?
    @State private var autoGenerate = true
    
    var body: some View {
        NavigationView {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Header
                    headerSection
                    
                    // Image Preview Section
                    imagePreviewSection
                    
                    // Real-Time Preview Section
                    realTimePreviewSection
                    
                    // Style Selection
                    styleSelectionSection
                    
                    // Action Buttons
                    actionButtonsSection
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.top, DesignSystem.Spacing.lg)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $isShowingStylePicker) {
                StylePickerView(selectedStyle: $selectedStyle)
            }
        }
        .onAppear {
            setupRealTimePreview()
        }
        .onDisappear {
            stopRealTimePreview()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            stopRealTimePreview()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            Button(action: {
                serviceContainer.navigationCoordinator.navigateBack()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: DesignSystem.IconSizes.medium, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
            
            Spacer()
            
            Text("Real-Time Preview")
                .font(DesignSystem.Typography.h4)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Spacer()
            
            // Settings button
            Button(action: {
                // Show settings
            }) {
                Image(systemName: "gearshape")
                    .font(.system(size: DesignSystem.IconSizes.medium, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
        }
    }
    
    // MARK: - Image Preview Section
    
    private var imagePreviewSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Text("Upload Photo")
                .font(DesignSystem.Typography.bodyBold)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Button(action: {
                selectImage()
            }) {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 200)
                        .cornerRadius(DesignSystem.CornerRadius.lg)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                                .stroke(DesignSystem.Colors.neutralDark, lineWidth: 1)
                        )
                } else {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                        .fill(DesignSystem.Colors.neutral)
                        .frame(height: 200)
                        .overlay(
                            VStack(spacing: DesignSystem.Spacing.md) {
                                Image(systemName: "photo.badge.plus")
                                    .font(.system(size: DesignSystem.IconSizes.xxlarge))
                                    .foregroundColor(DesignSystem.Colors.primary)
                                
                                Text("Tap to upload photo")
                                    .font(DesignSystem.Typography.body)
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                            }
                        )
                }
            }
        }
    }
    
    // MARK: - Real-Time Preview Section
    
    private var realTimePreviewSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            HStack {
                Text("Live Preview")
                    .font(DesignSystem.Typography.bodyBold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                // Auto-generate toggle
                Toggle("Auto", isOn: $autoGenerate)
                    .toggleStyle(SwitchToggleStyle(tint: DesignSystem.Colors.primary))
                    .scaleEffect(0.8)
            }
            
            if let preview = currentPreview {
                Image(uiImage: preview)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200)
                    .cornerRadius(DesignSystem.CornerRadius.lg)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                            .stroke(DesignSystem.Colors.primary, lineWidth: 2)
                    )
                    .overlay(
                        // Generation progress overlay
                        Group {
                            if isGenerating {
                                VStack {
                                    ModernLoadingIndicator(size: 30, color: .white)
                                    
                                    Text("Generating...")
                                        .font(DesignSystem.Typography.small)
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(DesignSystem.CornerRadius.lg)
                            }
                        }
                    )
            } else {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                    .fill(DesignSystem.Colors.neutral)
                    .frame(height: 200)
                    .overlay(
                        VStack(spacing: DesignSystem.Spacing.sm) {
                            Image(systemName: "wand.and.stars")
                                .font(.system(size: DesignSystem.IconSizes.xlarge))
                                .foregroundColor(DesignSystem.Colors.primary)
                            
                            Text("Select a style to see preview")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                    )
            }
        }
    }
    
    // MARK: - Style Selection Section
    
    private var styleSelectionSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Choose Style")
                .font(DesignSystem.Typography.bodyBold)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.md) {
                    ForEach(AvatarStyle.allStyles) { style in
                        StyleCard(
                            style: style,
                            isSelected: selectedStyle?.id == style.id,
                            onTap: {
                                selectStyle(style)
                            }
                        )
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.xs)
            }
        }
    }
    
    // MARK: - Action Buttons Section
    
    private var actionButtonsSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Generate Full Quality Button
            Button(action: {
                generateFullQuality()
            }) {
                HStack(spacing: DesignSystem.Spacing.md) {
                    Image(systemName: "sparkles")
                        .font(.system(size: DesignSystem.IconSizes.medium, weight: .semibold))
                    
                    Text("GENERATE FULL QUALITY")
                        .font(DesignSystem.Typography.button)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: DesignSystem.Heights.button)
                .background(DesignSystem.Colors.gradientPrimary)
                .cornerRadius(DesignSystem.CornerRadius.lg)
                .shadow(color: DesignSystem.Colors.shadow, radius: DesignSystem.Shadows.medium.radius, x: 0, y: 4)
            }
            .disabled(selectedImage == nil || selectedStyle == nil)
            .opacity(selectedImage == nil || selectedStyle == nil ? 0.6 : 1.0)
            
            // Quick Actions
            HStack(spacing: DesignSystem.Spacing.md) {
                Button(action: {
                    clearPreview()
                }) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "trash")
                            .font(.system(size: DesignSystem.IconSizes.small, weight: .semibold))
                        
                        Text("Clear")
                            .font(DesignSystem.Typography.captionBold)
                    }
                    .foregroundColor(DesignSystem.Colors.error)
                    .frame(maxWidth: .infinity)
                    .frame(height: DesignSystem.Heights.buttonSmall)
                    .background(DesignSystem.Colors.error.opacity(0.1))
                    .cornerRadius(DesignSystem.CornerRadius.md)
                }
                
                Button(action: {
                    savePreview()
                }) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: DesignSystem.IconSizes.small, weight: .semibold))
                        
                        Text("Save")
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
    
    // MARK: - Helper Methods
    
    private func setupRealTimePreview() {
        serviceContainer.analyticsService.track(event: "realtime_preview_opened")
        
        // Start auto-generation if enabled
        if autoGenerate {
            startAutoGeneration()
        }
    }
    
    private func stopRealTimePreview() {
        previewTimer?.invalidate()
        previewTimer = nil
    }
    
    private func selectImage() {
        // Implement image picker
        // For now, use a mock image
        selectedImage = UIImage(systemName: "person.circle.fill")
        
        serviceContainer.analyticsService.track(event: "image_selected_for_realtime")
        
        if autoGenerate && selectedStyle != nil {
            generatePreview()
        }
    }
    
    private func selectStyle(_ style: AvatarStyle) {
        selectedStyle = style
        serviceContainer.analyticsService.track(event: "style_selected_for_realtime", parameters: ["style": style.name])
        
        if autoGenerate && selectedImage != nil {
            generatePreview()
        }
    }
    
    private func generatePreview() {
        guard let image = selectedImage, let style = selectedStyle else { return }
        
        isGenerating = true
        generationProgress = 0.0
        
        // Use hybrid processing service for real-time preview
        appCoordinator.generateRealTimePreview(image, style: style)
        
        // For now, use the existing real-time service as fallback
        Task {
            do {
                let preview = try await serviceContainer.realTimeGenerationService.generateInstantPreview(from: image, style: style)
                
                DispatchQueue.main.async {
                    self.currentPreview = preview
                    self.isGenerating = false
                    self.generationProgress = 1.0
                }
                
                serviceContainer.analyticsService.track(event: "realtime_preview_generated", parameters: [
                    "style": style.name,
                    "generation_time": serviceContainer.realTimeGenerationService.getAverageGenerationTime()
                ])
                
            } catch {
                DispatchQueue.main.async {
                    self.isGenerating = false
                    self.generationProgress = 0.0
                }
                
                serviceContainer.analyticsService.track(event: "realtime_preview_failed", parameters: [
                    "error": error.localizedDescription
                ])
            }
        }
    }
    
    private func startAutoGeneration() {
        previewTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            if autoGenerate && selectedImage != nil && selectedStyle != nil {
                generatePreview()
            }
        }
    }
    
    private func generateFullQuality() {
        guard let image = selectedImage, let style = selectedStyle else { return }
        
        serviceContainer.analyticsService.track(event: "full_quality_generation_started", parameters: ["style": style.name])
        
        // Navigate to full processing
        appCoordinator.processImage(image)
    }
    
    private func clearPreview() {
        currentPreview = nil
        selectedImage = nil
        selectedStyle = nil
        
        serviceContainer.analyticsService.track(event: "realtime_preview_cleared")
    }
    
    private func savePreview() {
        guard let preview = currentPreview else { return }
        
        // Save to photo library
        UIImageWriteToSavedPhotosAlbum(preview, nil, nil, nil)
        
        serviceContainer.analyticsService.track(event: "realtime_preview_saved")
    }
}

// MARK: - Style Card Component

struct StyleCard: View {
    let style: AvatarStyle
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: DesignSystem.Spacing.sm) {
                // Style Icon
                Image(systemName: styleIcon)
                    .font(.system(size: DesignSystem.IconSizes.large, weight: .semibold))
                    .foregroundColor(isSelected ? .white : DesignSystem.Colors.primary)
                
                // Style Name
                Text(style.name)
                    .font(DesignSystem.Typography.small)
                    .foregroundColor(isSelected ? .white : DesignSystem.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                // Premium Badge
                if style.isPremium {
                    Text("PRO")
                        .font(DesignSystem.Typography.smallBold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(DesignSystem.Colors.warning)
                        .cornerRadius(4)
                }
            }
            .frame(width: 80, height: 80)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .fill(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.neutral)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .stroke(isSelected ? DesignSystem.Colors.primary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var styleIcon: String {
        switch style.name {
        case "Professional Headshot":
            return "person.crop.circle"
        case "Anime/Cartoon Style":
            return "face.smiling"
        case "Renaissance Art":
            return "paintbrush"
        case "Cyberpunk Future":
            return "bolt.circle"
        case "Disney/Pixar Style":
            return "star.circle"
        case "AI Yearbook Photos":
            return "graduationcap"
        case "Age Progression":
            return "person.crop.circle.badge.clock"
        case "Age Regression":
            return "person.crop.circle.badge.minus"
        default:
            return "wand.and.stars"
        }
    }
}

// MARK: - Style Picker View

struct StylePickerView: View {
    @Binding var selectedStyle: AvatarStyle?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List(AvatarStyle.allStyles) { style in
                StyleRow(style: style, isSelected: selectedStyle?.id == style.id) {
                    selectedStyle = style
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .navigationTitle("Choose Style")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// MARK: - Style Row Component

struct StyleRow: View {
    let style: AvatarStyle
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignSystem.Spacing.md) {
                // Style Icon
                Image(systemName: styleIcon)
                    .font(.system(size: DesignSystem.IconSizes.large, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.primary)
                    .frame(width: 40, height: 40)
                
                // Style Info
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(style.name)
                        .font(DesignSystem.Typography.bodyBold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text(style.description)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    HStack {
                        Text("\(Int(style.processingTime))s")
                            .font(DesignSystem.Typography.small)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        if style.isPremium {
                            Text("PRO")
                                .font(DesignSystem.Typography.smallBold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(DesignSystem.Colors.warning)
                                .cornerRadius(4)
                        }
                    }
                }
                
                Spacer()
                
                // Selection Indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: DesignSystem.IconSizes.medium, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.primary)
                }
            }
            .padding(.vertical, DesignSystem.Spacing.sm)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var styleIcon: String {
        switch style.name {
        case "Professional Headshot":
            return "person.crop.circle"
        case "Anime/Cartoon Style":
            return "face.smiling"
        case "Renaissance Art":
            return "paintbrush"
        case "Cyberpunk Future":
            return "bolt.circle"
        case "Disney/Pixar Style":
            return "star.circle"
        case "AI Yearbook Photos":
            return "graduationcap"
        case "Age Progression":
            return "person.crop.circle.badge.clock"
        case "Age Regression":
            return "person.crop.circle.badge.minus"
        default:
            return "wand.and.stars"
        }
    }
}

// MARK: - Preview

#Preview {
    RealTimePreviewView()
        .environmentObject(ServiceContainer.shared)
        .environmentObject(AppCoordinator())
}
