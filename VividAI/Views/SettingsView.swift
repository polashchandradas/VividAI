import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject var unifiedState: UnifiedAppStateManager
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    @EnvironmentObject var analyticsService: AnalyticsService
    @EnvironmentObject var authenticationService: AuthenticationService
    @EnvironmentObject var appCoordinator: AppCoordinator
    @State private var notificationsEnabled = false
    @State private var saveToPhotosEnabled = true
    @State private var hdQualityEnabled = true
    
    var body: some View {
        NavigationView {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.xl) {
                        // Header
                        headerSection
                        
                        // Account Section
                        accountSection
                        
                        // Authentication Section
                        authenticationSection
                        
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
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.top, DesignSystem.Spacing.lg)
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
                    .font(.system(size: DesignSystem.IconSizes.medium, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
            
            Spacer()
            
            Text("Settings")
                .font(DesignSystem.Typography.h4)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Spacer()
            
            // Invisible spacer for balance
            Color.clear
                .frame(width: DesignSystem.IconSizes.medium, height: DesignSystem.IconSizes.medium)
        }
    }
    
    private var accountSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            HStack {
                Text("ACCOUNT")
                    .font(DesignSystem.Typography.smallBold)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .tracking(1)
                
                Spacer()
            }
            
            ModernCard(
                padding: DesignSystem.Spacing.md,
                cornerRadius: DesignSystem.CornerRadius.md,
                shadow: DesignSystem.Shadows.small
            ) {
                HStack(spacing: DesignSystem.Spacing.md) {
                    // Profile Photo
                    Circle()
                        .fill(DesignSystem.Colors.neutralDark)
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: DesignSystem.IconSizes.large))
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        )
                    
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text(authenticationService.currentUser?.displayName ?? "User")
                            .font(DesignSystem.Typography.bodyBold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Text(authenticationService.currentUser?.email ?? "user@example.com")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        if !unifiedState.isPremiumUser {
                            Button(action: {
                                analyticsService.track(event: "upgrade_tapped_from_settings")
                                navigationCoordinator.showPaywall()
                            }) {
                                Text("⭐ Upgrade to Pro")
                                    .font(DesignSystem.Typography.captionBold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, DesignSystem.Spacing.md)
                                    .padding(.vertical, DesignSystem.Spacing.sm)
                                    .background(DesignSystem.Colors.gradientPrimary)
                                    .cornerRadius(DesignSystem.CornerRadius.sm)
                            }
                        } else {
                            Text("Pro Member")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.success)
                        }
                    }
                    
                    Spacer()
                }
            }
        }
    }
    
    private var authenticationSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            HStack {
                Text("AUTHENTICATION")
                    .font(DesignSystem.Typography.smallBold)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .tracking(1)
                
                Spacer()
            }
            
            VStack(spacing: DesignSystem.Spacing.md) {
                settingsRow(
                    icon: "person.circle",
                    title: "Profile",
                    action: {
                        analyticsService.track(event: "profile_tapped")
                        // Show profile management
                    }
                )
                
                settingsRow(
                    icon: "key.fill",
                    title: "Change Password",
                    action: {
                        analyticsService.track(event: "change_password_tapped")
                        // Show change password flow
                    }
                )
                
                settingsRow(
                    icon: "arrow.right.square",
                    title: "Sign Out",
                    action: {
                        analyticsService.track(event: "sign_out_tapped")
                        appCoordinator.signOut()
                    }
                )
            }
        }
    }
    
    private var subscriptionSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            HStack {
                Text("SUBSCRIPTION")
                    .font(DesignSystem.Typography.smallBold)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .tracking(1)
                
                Spacer()
            }
            
            VStack(spacing: DesignSystem.Spacing.md) {
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
        VStack(spacing: DesignSystem.Spacing.md) {
            HStack {
                Text("PREFERENCES")
                    .font(DesignSystem.Typography.smallBold)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .tracking(1)
                
                Spacer()
            }
            
            VStack(spacing: DesignSystem.Spacing.md) {
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
        VStack(spacing: DesignSystem.Spacing.md) {
            HStack {
                Text("HELP")
                    .font(DesignSystem.Typography.smallBold)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .tracking(1)
                
                Spacer()
            }
            
            VStack(spacing: DesignSystem.Spacing.md) {
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
        VStack(spacing: DesignSystem.Spacing.md) {
            HStack {
                Text("LEGAL")
                    .font(DesignSystem.Typography.smallBold)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .tracking(1)
                
                Spacer()
            }
            
            VStack(spacing: DesignSystem.Spacing.md) {
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
        VStack(spacing: DesignSystem.Spacing.sm) {
            Text("Version 1.0.0")
                .font(DesignSystem.Typography.small)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            Text("Made with ❤️ by VividAI Team")
                .font(DesignSystem.Typography.small)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .padding(.top, DesignSystem.Spacing.lg)
    }
    
    private func settingsRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ModernCard(
                padding: DesignSystem.Spacing.md,
                cornerRadius: DesignSystem.CornerRadius.md,
                shadow: DesignSystem.Shadows.small
            ) {
                HStack(spacing: DesignSystem.Spacing.md) {
                    Image(systemName: icon)
                        .font(.system(size: DesignSystem.IconSizes.small, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.primary)
                        .frame(width: 24)
                    
                    Text(title)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: DesignSystem.IconSizes.xs, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func settingsToggleRow(icon: String, title: String, isOn: Binding<Bool>) -> some View {
        ModernCard(
            padding: DesignSystem.Spacing.md,
            cornerRadius: DesignSystem.CornerRadius.md,
            shadow: DesignSystem.Shadows.small
        ) {
            HStack(spacing: DesignSystem.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: DesignSystem.IconSizes.small, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.primary)
                    .frame(width: 24)
                
                Text(title)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                Toggle("", isOn: isOn)
                    .labelsHidden()
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(UnifiedAppStateManager.shared)
        .environmentObject(NavigationCoordinator())
        .environmentObject(AnalyticsService.shared)
        .environmentObject(AuthenticationService())
        .environmentObject(AppCoordinator())
}
