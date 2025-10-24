import SwiftUI
import UIKit

struct HomeView: View {
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    @EnvironmentObject var appCoordinator: AppCoordinator
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var analyticsService: AnalyticsService
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        headerSection
                        
                        // Hero CTA Section
                        heroSection
                        
                        // Secondary Features
                        secondaryFeaturesSection
                        
                        // Social Proof
                        socialProofSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            analyticsService.track(event: "home_screen_viewed")
        }
    }
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome to")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text("VividAI")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Button(action: { 
                navigationCoordinator.showSettings()
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.primary)
            }
        }
    }
    
    private var heroSection: some View {
        VStack(spacing: 24) {
            // Main CTA
            VStack(spacing: 16) {
                Text("Create Your Professional")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("AI Headshot")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                // Before/After Comparison
                beforeAfterComparison
            }
            
            // Primary CTA Button
            Button(action: {
                analyticsService.track(event: "create_headshot_tapped")
                navigationCoordinator.startPhotoUpload()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 20, weight: .semibold))
                    
                    Text("CREATE YOUR HEADSHOT")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.04, green: 0.52, blue: 0.89), // #0984E3
                            Color(red: 0.42, green: 0.36, blue: 0.91)  // #6C5CE7
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var beforeAfterComparison: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
                .frame(height: 200)
            
            HStack(spacing: 16) {
                // Before
                VStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray4))
                        .frame(width: 80, height: 100)
                        .overlay(
                            Image(systemName: "person.crop.circle")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                        )
                    
                    Text("Before")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                // Arrow
                Image(systemName: "arrow.right")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                
                // After
                VStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.blue.opacity(0.3),
                                    Color.purple.opacity(0.3)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 100)
                        .overlay(
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.blue)
                        )
                    
                    Text("After")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var secondaryFeaturesSection: some View {
        VStack(spacing: 16) {
            Text("Also Try")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            HStack(spacing: 16) {
                // Background Removal
                Button(action: {
                    analyticsService.track(event: "background_removal_tapped")
                    navigationCoordinator.startPhotoUpload()
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                        
                        Text("Background")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Text("Removal")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                // Photo Enhancement
                Button(action: {
                    analyticsService.track(event: "photo_enhancement_tapped")
                    navigationCoordinator.startPhotoUpload()
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 24))
                            .foregroundColor(.purple)
                        
                        Text("Photo")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Text("Enhance")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
        }
    }
    
    private var socialProofSection: some View {
        VStack(spacing: 12) {
            Text("No signup required")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.yellow)
                
                Text("2.3M+ headshots created")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(SubscriptionManager())
        .environmentObject(AnalyticsService())
}
