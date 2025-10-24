import SwiftUI
import UIKit

struct ResultsView: View {
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    @EnvironmentObject var appCoordinator: AppCoordinator
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var analyticsService: AnalyticsService
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
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Results Grid
                        resultsGridSection
                        
                        // Watermark Notice
                        watermarkNoticeSection
                        
                        // Action Buttons
                        actionButtonsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
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
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Text("Your Headshots")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            Spacer()
            
            Button(action: { 
                navigationCoordinator.showSettings()
            }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
            }
        }
    }
    
    private var resultsGridSection: some View {
        VStack(spacing: 16) {
            Text("Tap any to view full")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                ForEach(headshotStyles) { headshot in
                    HeadshotCard(
                        headshot: headshot,
                        isPremium: subscriptionManager.isPremiumUser,
                        onTap: {
                            selectedHeadshot = headshot
                            if headshot.isPremium && !subscriptionManager.isPremiumUser {
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
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Watermarked (Free)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("Upgrade to remove watermarks and unlock all styles")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            // Primary CTA - Remove Watermark
            Button(action: {
                analyticsService.track(event: "remove_watermark_tapped")
                navigationCoordinator.showPaywall()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "lock.open.fill")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Text("REMOVE WATERMARK")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.blue,
                            Color.purple
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
            }
            
            // Secondary Actions
            HStack(spacing: 16) {
                Button(action: {
                    analyticsService.track(event: "share_tapped")
                    // Generate video and show share view
                    if let originalImage = navigationCoordinator.selectedImage,
                       let firstResult = navigationCoordinator.processingResults.first {
                        // Create a mock enhanced image for video generation
                        let enhancedImage = UIImage(systemName: "person.crop.circle.fill") ?? originalImage
                        appCoordinator.generateTransformationVideo(from: originalImage, to: enhancedImage)
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                        
                        Text("SHARE")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
                
                Button(action: {
                    analyticsService.track(event: "save_tapped")
                    // Save functionality
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 16, weight: .semibold))
                        
                        Text("SAVE")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct HeadshotCard: View {
    let headshot: HeadshotStyle
    let isPremium: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Image
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                        .frame(height: 120)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.blue)
                                
                                if headshot.isPremium && !isPremium {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.orange)
                                }
                            }
                        )
                    
                    // Premium Badge
                    if headshot.isPremium && !isPremium {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.orange)
                                    .padding(4)
                                    .background(Color.white)
                                    .clipShape(Circle())
                            }
                            Spacer()
                        }
                        .padding(8)
                    }
                }
                
                // Style Name
                Text(headshot.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
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
                
                VStack(spacing: 20) {
                    // Full Screen Image
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                        .frame(maxWidth: .infinity, maxHeight: 400)
                        .overlay(
                            VStack(spacing: 16) {
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(.blue)
                                
                                Text(headshot.name)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        )
                    
                    // Style Name
                    Text(headshot.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    // Action Buttons
                    HStack(spacing: 16) {
                        Button("Share") {
                            // Share functionality
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.blue)
                        .cornerRadius(12)
                        
                        Button("Save") {
                            // Save functionality
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.green)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)
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

// MARK: - Data Models

struct HeadshotStyle: Identifiable {
    let id: Int
    let name: String
    let image: String
    let isPremium: Bool
}

#Preview {
    ResultsView()
        .environmentObject(SubscriptionManager())
        .environmentObject(AnalyticsService())
}
