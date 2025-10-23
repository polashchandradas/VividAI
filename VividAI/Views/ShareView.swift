import SwiftUI
import AVFoundation
import AVKit

struct ShareView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var analyticsService: AnalyticsService
    @State private var isGeneratingVideo = false
    @State private var generatedVideoURL: URL?
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 32) {
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
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingShareSheet) {
                if let videoURL = generatedVideoURL {
                    ShareSheet(items: [videoURL])
                }
            }
        }
        .onAppear {
            analyticsService.track(event: "share_screen_viewed")
            generateTransformationVideo()
        }
    }
    
    private var headerSection: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Text("Ready to Share! ✨")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            Spacer()
            
            // Invisible spacer for balance
            Color.clear
                .frame(width: 18, height: 18)
        }
    }
    
    private var initialSection: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: "video.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Creating your transformation video...")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var videoGenerationSection: some View {
        VStack(spacing: 24) {
            // Progress Animation
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 4)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isGeneratingVideo)
                
                Image(systemName: "video.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
            }
            
            VStack(spacing: 8) {
                Text("Generating 5-second video...")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("This will be perfect for TikTok and Instagram!")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private func videoPreviewSection(videoURL: URL) -> some View {
        VStack(spacing: 24) {
            // Video Preview
            VideoPlayer(player: AVPlayer(url: videoURL))
                .frame(height: 400)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
            
            // Video Details
            VStack(spacing: 8) {
                Text("Your transformation video is ready!")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("5 seconds • Vertical format • Watermarked")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            // Share Options
            shareOptionsSection
        }
    }
    
    private var shareOptionsSection: some View {
        VStack(spacing: 16) {
            // Primary Share Button
            Button(action: {
                analyticsService.track(event: "share_video_tapped")
                showingShareSheet = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Text("SHARE TO...")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
            }
            
            // Platform-specific buttons
            HStack(spacing: 16) {
                platformButton(icon: "video.fill", name: "TikTok", color: .black)
                platformButton(icon: "camera.fill", name: "Instagram", color: .pink)
                platformButton(icon: "bird.fill", name: "Twitter", color: .blue)
                platformButton(icon: "ellipsis", name: "More", color: .gray)
            }
            
            // Save Video Button
            Button(action: {
                analyticsService.track(event: "save_video_tapped")
                saveVideoToPhotos()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text("SAVE VIDEO")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.green)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            }
            
            // Premium Notice
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                
                Text("Premium: Remove watermark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.orange)
            }
        }
    }
    
    private func platformButton(icon: String, name: String, color: Color) -> some View {
        Button(action: {
            analyticsService.track(event: "platform_share_tapped", parameters: ["platform": name])
            showingShareSheet = true
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
                
                Text(name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private func generateTransformationVideo() {
        isGeneratingVideo = true
        
        // Simulate video generation
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            // Create a mock video URL
            // In a real implementation, this would generate an actual video
            self.generatedVideoURL = createMockVideoURL()
            self.isGeneratingVideo = false
            
            self.analyticsService.track(event: "video_generated")
        }
    }
    
    private func createMockVideoURL() -> URL {
        // This would be replaced with actual video generation
        // For now, return a placeholder URL
        return URL(string: "file:///mock/video.mp4")!
    }
    
    private func saveVideoToPhotos() {
        // Save video to Photos library
        // This would use PHPhotoLibrary to save the video
        analyticsService.track(event: "video_saved_to_photos")
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
        .environmentObject(AnalyticsService())
}
