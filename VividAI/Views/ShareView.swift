import SwiftUI
import AVFoundation
import AVKit
import UIKit
import Photos

struct ShareView: View {
    @EnvironmentObject var unifiedState: UnifiedAppStateManager
    @State private var isGeneratingVideo = false
    @State private var generatedVideoURL: URL?
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: DesignSystem.Spacing.xl) {
                    // Header
                    headerSection
                    
                    if isGeneratingVideo {
                        // Video Generation
                        videoGenerationSection
                    } else if let videoURL = generatedVideoURL {
                        // Video Preview
                        videoPreviewSection(videoURL: videoURL)
                    } else {
                        // Initial State
                        initialSection
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.top, DesignSystem.Spacing.lg)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingShareSheet) {
                if let videoURL = generatedVideoURL {
                    ShareSheet(items: [videoURL])
                }
            }
        }
        .onAppear {
            ServiceContainer.shared.analyticsService.track(event: "share_screen_viewed")
            // Get video URL from navigation coordinator
            if let videoURL = ServiceContainer.shared.navigationCoordinator.generatedVideoURL {
                generatedVideoURL = videoURL
            } else {
                generateTransformationVideo()
            }
        }
    }
    
    private var headerSection: some View {
        HStack {
            Button(action: { 
                ServiceContainer.shared.navigationCoordinator.navigateBack()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: DesignSystem.IconSizes.medium, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
            
            Spacer()
            
            Text("Ready to Share! ✨")
                .font(DesignSystem.Typography.h4)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Spacer()
            
            // Invisible spacer for balance
            Color.clear
                .frame(width: DesignSystem.IconSizes.medium, height: DesignSystem.IconSizes.medium)
        }
    }
    
    private var initialSection: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            // Icon
            Image(systemName: "video.fill")
                .font(.system(size: 60))
                .foregroundColor(DesignSystem.Colors.primary)
            
            Text("Creating your transformation video...")
                .font(DesignSystem.Typography.h4)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var videoGenerationSection: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            // Progress Animation
            ZStack {
                Circle()
                    .stroke(DesignSystem.Colors.neutralDark, lineWidth: 4)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        DesignSystem.Colors.gradientSecondary,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(DesignSystem.Animations.standard.repeatForever(autoreverses: true), value: isGeneratingVideo)
                
                Image(systemName: "video.fill")
                    .font(.system(size: DesignSystem.IconSizes.large))
                    .foregroundColor(DesignSystem.Colors.primary)
            }
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text("Generating 5-second video...")
                    .font(DesignSystem.Typography.bodyBold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("This will be perfect for TikTok and Instagram!")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private func videoPreviewSection(videoURL: URL) -> some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            // Video Preview
            VideoPlayer(player: AVPlayer(url: videoURL))
                .frame(height: 400)
                .cornerRadius(DesignSystem.CornerRadius.lg)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                        .stroke(DesignSystem.Colors.neutralDark, lineWidth: 1)
                )
            
            // Video Details
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text("Your transformation video is ready!")
                    .font(DesignSystem.Typography.h4)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("5 seconds • Vertical format • Watermarked")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            // Share Options
            shareOptionsSection
        }
    }
    
    private var shareOptionsSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Primary Share Button
            Button(action: {
                ServiceContainer.shared.analyticsService.track(event: "share_video_tapped")
                showingShareSheet = true
            }) {
                HStack(spacing: DesignSystem.Spacing.md) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: DesignSystem.IconSizes.medium, weight: .semibold))
                    
                    Text("SHARE TO...")
                        .font(DesignSystem.Typography.button)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: DesignSystem.Heights.button)
                .background(DesignSystem.Colors.gradientPrimary)
                .cornerRadius(DesignSystem.CornerRadius.lg)
                .shadow(color: DesignSystem.Colors.shadow, radius: DesignSystem.Shadows.medium.radius, x: 0, y: 4)
            }
            
            // Platform-specific buttons
            HStack(spacing: DesignSystem.Spacing.md) {
                platformButton(icon: "video.fill", name: "TikTok", color: .black)
                platformButton(icon: "camera.fill", name: "Instagram", color: .pink)
                platformButton(icon: "bird.fill", name: "Twitter", color: .blue)
                platformButton(icon: "ellipsis", name: "More", color: .gray)
            }
            
            // Save Video Button
            Button(action: {
                ServiceContainer.shared.analyticsService.track(event: "save_video_tapped")
                saveVideoToPhotos()
            }) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: DesignSystem.IconSizes.small, weight: .semibold))
                    
                    Text("SAVE VIDEO")
                        .font(DesignSystem.Typography.captionBold)
                }
                .foregroundColor(DesignSystem.Colors.success)
                .frame(maxWidth: .infinity)
                .frame(height: DesignSystem.Heights.buttonSmall)
                .background(DesignSystem.Colors.success.opacity(0.1))
                .cornerRadius(DesignSystem.CornerRadius.md)
            }
            
            // Premium Notice
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(DesignSystem.Colors.warning)
                
                Text("Premium: Remove watermark")
                    .font(DesignSystem.Typography.small)
                    .foregroundColor(DesignSystem.Colors.warning)
            }
        }
    }
    
    private func platformButton(icon: String, name: String, color: Color) -> some View {
        Button(action: {
            ServiceContainer.shared.analyticsService.track(event: "platform_share_tapped", parameters: ["platform": name])
            showingShareSheet = true
        }) {
            VStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: DesignSystem.IconSizes.medium, weight: .semibold))
                    .foregroundColor(color)
                
                Text(name)
                    .font(DesignSystem.Typography.small)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(DesignSystem.Colors.neutral)
            .cornerRadius(DesignSystem.CornerRadius.md)
        }
    }
    
    private func generateTransformationVideo() {
        isGeneratingVideo = true
        
        Task {
            await generateVideoAsync()
        }
    }
    
    private func generateVideoAsync() async {
        guard let originalImage = ServiceContainer.shared.navigationCoordinator.selectedImage,
              let enhancedImage = ServiceContainer.shared.navigationCoordinator.processingResults.first?.image else {
            await MainActor.run {
                self.isGeneratingVideo = false
            }
            return
        }
        
        do {
            let videoURL = try await ServiceContainer.shared.videoGenerationService.generateTransformationVideoAsync(
                from: originalImage,
                to: enhancedImage
            )
            
            await MainActor.run {
                self.generatedVideoURL = videoURL
                ServiceContainer.shared.navigationCoordinator.generatedVideoURL = videoURL
                self.isGeneratingVideo = false
                ServiceContainer.shared.analyticsService.track(event: "video_generated")
            }
        } catch {
            await MainActor.run {
                self.isGeneratingVideo = false
                ServiceContainer.shared.analyticsService.track(event: "video_generation_failed", parameters: [
                    "error": error.localizedDescription
                ])
            }
        }
    }
    
    private func saveVideoToPhotos() {
        guard let videoURL = generatedVideoURL else { return }
        
        PHPhotoLibrary.requestAuthorization { status in
            switch status {
            case .authorized, .limited:
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
                }) { success, error in
                    DispatchQueue.main.async {
                        if success {
                            ServiceContainer.shared.analyticsService.track(event: "video_saved_to_photos")
                        } else {
                            ServiceContainer.shared.analyticsService.track(event: "video_save_failed", parameters: [
                                "error": error?.localizedDescription ?? "Unknown error"
                            ])
                        }
                    }
                }
            case .denied, .restricted:
                ServiceContainer.shared.analyticsService.track(event: "video_save_permission_denied")
            case .notDetermined:
                break
            @unknown default:
                break
            }
        }
    }
}

// MARK: - Supporting Views

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ShareView()
        .environmentObject(UnifiedAppStateManager.shared)
}
