import SwiftUI

struct QualitySelectionView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator
    @EnvironmentObject var analyticsService: AnalyticsService
    @Binding var selectedImage: UIImage?
    @State private var selectedQuality: HybridProcessingService.QualityLevel = .standard
    @State private var showingProcessing = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
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
                .padding(.horizontal, 20)
                .padding(.top, 20)
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
                // Go back
            }) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Text("Choose Quality")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            Spacer()
            
            Color.clear
                .frame(width: 18, height: 18)
        }
    }
    
    private var imagePreviewSection: some View {
        VStack(spacing: 12) {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 200)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.blue, lineWidth: 2)
                    )
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
                    .frame(height: 200)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            
                            Text("No image selected")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    )
            }
        }
    }
    
    private var qualityOptionsSection: some View {
        VStack(spacing: 16) {
            Text("Select Processing Quality")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
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
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                
                Text("Processing Information")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
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
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            Button(action: {
                startProcessing()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Text("START PROCESSING")
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
            .disabled(selectedImage == nil || showingProcessing)
            .opacity(selectedImage == nil || showingProcessing ? 0.6 : 1.0)
            
            if showingProcessing {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    
                    Text("Processing with \(selectedQuality) quality...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private func processingInfoRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
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
            HStack(spacing: 16) {
                // Selection Indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: 2)
                        .frame(width: 20, height: 20)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 12, height: 12)
                    }
                }
                
                // Quality Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        if quality == .premium || quality == .ultra {
                            Text("PRO")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .cornerRadius(4)
                        }
                        
                        Spacer()
                    }
                    
                    Text(description)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Text(time)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    QualitySelectionView(selectedImage: .constant(nil))
        .environmentObject(AppCoordinator())
        .environmentObject(AnalyticsService())
}
