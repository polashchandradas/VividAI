import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    @EnvironmentObject var appCoordinator: AppCoordinator
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var analyticsService: AnalyticsService
    @State private var notificationsEnabled = false
    @State private var saveToPhotosEnabled = true
    @State private var hdQualityEnabled = true
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Account Section
                        accountSection
                        
                        // Subscription Section
                        subscriptionSection
                        
                        // Preferences Section
                        preferencesSection
                        
                        // Help Section
                        helpSection
                        
                        // Legal Section
                        legalSection
                        
                        // App Version
                        versionSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            analyticsService.track(event: "settings_screen_viewed")
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
            
            Text("Settings")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            Spacer()
            
            // Invisible spacer for balance
            Color.clear
                .frame(width: 18, height: 18)
        }
    }
    
    private var accountSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("ACCOUNT")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
                    .tracking(1)
                
                Spacer()
            }
            
            HStack(spacing: 16) {
                // Profile Photo
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Free Account")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    if !subscriptionManager.isPremiumUser {
                        Button(action: {
                            analyticsService.track(event: "upgrade_tapped_from_settings")
                            navigationCoordinator.showPaywall()
                        }) {
                            Text("⭐ Upgrade to Pro")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(8)
                        }
                    } else {
                        Text("Pro Member")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private var subscriptionSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("SUBSCRIPTION")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
                    .tracking(1)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                settingsRow(
                    icon: "creditcard.fill",
                    title: "Manage Subscription",
                    action: {
                        analyticsService.track(event: "manage_subscription_tapped")
                        // Open subscription management
                    }
                )
                
                settingsRow(
                    icon: "arrow.clockwise",
                    title: "Restore Purchases",
                    action: {
                        analyticsService.track(event: "restore_purchases_tapped")
                        appCoordinator.handleSubscriptionAction(.restorePurchases)
                    }
                )
            }
        }
    }
    
    private var preferencesSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("PREFERENCES")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
                    .tracking(1)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                settingsToggleRow(
                    icon: "bell.fill",
                    title: "Notifications",
                    isOn: $notificationsEnabled
                )
                
                settingsToggleRow(
                    icon: "photo.fill",
                    title: "Save to Photos",
                    isOn: $saveToPhotosEnabled
                )
                
                settingsToggleRow(
                    icon: "4k.tv.fill",
                    title: "Quality: HD",
                    isOn: $hdQualityEnabled
                )
            }
        }
    }
    
    private var helpSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("HELP")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
                    .tracking(1)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                settingsRow(
                    icon: "play.fill",
                    title: "Tutorial",
                    action: {
                        analyticsService.track(event: "tutorial_tapped")
                        // Show tutorial
                    }
                )
                
                settingsRow(
                    icon: "questionmark.circle.fill",
                    title: "FAQ",
                    action: {
                        analyticsService.track(event: "faq_tapped")
                        // Show FAQ
                    }
                )
                
                settingsRow(
                    icon: "envelope.fill",
                    title: "Contact Support",
                    action: {
                        analyticsService.track(event: "contact_support_tapped")
                        // Open support
                    }
                )
                
                settingsRow(
                    icon: "star.fill",
                    title: "Rate App ⭐⭐⭐⭐⭐",
                    action: {
                        analyticsService.track(event: "rate_app_tapped")
                        // Open App Store rating
                    }
                )
            }
        }
    }
    
    private var legalSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("LEGAL")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
                    .tracking(1)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                settingsRow(
                    icon: "doc.text.fill",
                    title: "Terms of Service",
                    action: {
                        analyticsService.track(event: "terms_tapped")
                        // Open terms
                    }
                )
                
                settingsRow(
                    icon: "hand.raised.fill",
                    title: "Privacy Policy",
                    action: {
                        analyticsService.track(event: "privacy_tapped")
                        // Open privacy policy
                    }
                )
            }
        }
    }
    
    private var versionSection: some View {
        VStack(spacing: 8) {
            Text("Version 1.0.0")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
            
            Text("Made with ❤️ by VividAI Team")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.top, 20)
    }
    
    private func settingsRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func settingsToggleRow(icon: String, title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    SettingsView()
        .environmentObject(SubscriptionManager())
        .environmentObject(AnalyticsService())
}
