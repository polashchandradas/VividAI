import SwiftUI
import UIKit
import Combine

// MARK: - Real-Time Preview View

struct RealTimePreviewView: View {
    @StateObject private var realTimeService = RealTimeGenerationService.shared
    @EnvironmentObject var appCoordinator: AppCoordinator
    @EnvironmentObject var analyticsService: AnalyticsService
    
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
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
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
                .padding(.horizontal, 20)
                .padding(.top, 20)
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
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            Button(action: {
                appCoordinator.navigationCoordinator.navigateBack()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Text("Real-Time Preview")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            Spacer()
            
            // Settings button
            Button(action: {
                // Show settings
            }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
            }
        }
    }
    
    // MARK: - Image Preview Section
    
    private var imagePreviewSection: some View {
        VStack(spacing: 12) {
            Text("Upload Photo")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            Button(action: {
                selectImage()
            }) {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 200)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                        .frame(height: 200)
                        .overlay(
                            VStack(spacing: 12) {
                                Image(systemName: "photo.badge.plus")
                                    .font(.system(size: 40))
                                    .foregroundColor(.blue)
                                
                                Text("Tap to upload photo")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                            }
                        )
                }
            }
        }
    }
    
    // MARK: - Real-Time Preview Section
    
    private var realTimePreviewSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Live Preview")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Auto-generate toggle
                Toggle("Auto", isOn: $autoGenerate)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    .scaleEffect(0.8)
            }
            
            if let preview = currentPreview {
                Image(uiImage: preview)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.blue, lineWidth: 2)
                    )
                    .overlay(
                        // Generation progress overlay
                        Group {
                            if isGenerating {
                                VStack {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(1.2)
                                    
                                    Text("Generating...")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(16)
                            }
                        }
                    )
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
                    .frame(height: 200)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 30))
                                .foregroundColor(.blue)
                            
                            Text("Select a style to see preview")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    )
            }
        }
    }
    
    // MARK: - Style Selection Section
    
    private var styleSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose Style")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
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
                .padding(.horizontal, 4)
            }
        }
    }
    
    // MARK: - Action Buttons Section
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            // Generate Full Quality Button
            Button(action: {
                generateFullQuality()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Text("GENERATE FULL QUALITY")
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
            .disabled(selectedImage == nil || selectedStyle == nil)
            .opacity(selectedImage == nil || selectedStyle == nil ? 0.6 : 1.0)
            
            // Quick Actions
            HStack(spacing: 16) {
                Button(action: {
                    clearPreview()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .semibold))
                        
                        Text("Clear")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
                }
                
                Button(action: {
                    savePreview()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 16, weight: .semibold))
                        
                        Text("Save")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupRealTimePreview() {
        analyticsService.track(event: "realtime_preview_opened")
        
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
        
        analyticsService.track(event: "image_selected_for_realtime")
        
        if autoGenerate && selectedStyle != nil {
            generatePreview()
        }
    }
    
    private func selectStyle(_ style: AvatarStyle) {
        selectedStyle = style
        analyticsService.track(event: "style_selected_for_realtime", parameters: ["style": style.name])
        
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
                let preview = try await realTimeService.generateInstantPreview(from: image, style: style)
                
                DispatchQueue.main.async {
                    self.currentPreview = preview
                    self.isGenerating = false
                    self.generationProgress = 1.0
                }
                
                analyticsService.track(event: "realtime_preview_generated", parameters: [
                    "style": style.name,
                    "generation_time": realTimeService.getAverageGenerationTime()
                ])
                
            } catch {
                DispatchQueue.main.async {
                    self.isGenerating = false
                    self.generationProgress = 0.0
                }
                
                analyticsService.track(event: "realtime_preview_failed", parameters: [
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
        
        analyticsService.track(event: "full_quality_generation_started", parameters: ["style": style.name])
        
        // Navigate to full processing
        appCoordinator.processImage(image)
    }
    
    private func clearPreview() {
        currentPreview = nil
        selectedImage = nil
        selectedStyle = nil
        
        analyticsService.track(event: "realtime_preview_cleared")
    }
    
    private func savePreview() {
        guard let preview = currentPreview else { return }
        
        // Save to photo library
        UIImageWriteToSavedPhotosAlbum(preview, nil, nil, nil)
        
        analyticsService.track(event: "realtime_preview_saved")
    }
}

// MARK: - Style Card Component

struct StyleCard: View {
    let style: AvatarStyle
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Style Icon
                Image(systemName: styleIcon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .blue)
                
                // Style Name
                Text(style.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                // Premium Badge
                if style.isPremium {
                    Text("PRO")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange)
                        .cornerRadius(4)
                }
            }
            .frame(width: 80, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
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
            HStack(spacing: 16) {
                // Style Icon
                Image(systemName: styleIcon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.blue)
                    .frame(width: 40, height: 40)
                
                // Style Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(style.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(style.description)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("\(Int(style.processingTime))s")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        if style.isPremium {
                            Text("PRO")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .cornerRadius(4)
                        }
                    }
                }
                
                Spacer()
                
                // Selection Indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 8)
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
        .environmentObject(AppCoordinator())
        .environmentObject(AnalyticsService())
}
