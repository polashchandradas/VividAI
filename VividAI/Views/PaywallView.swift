import SwiftUI
import StoreKit
import UIKit

struct PaywallView: View {
    @EnvironmentObject var unifiedState: UnifiedAppStateManager
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    @EnvironmentObject var subscriptionStateManager: SubscriptionStateManager
    @EnvironmentObject var appCoordinator: AppCoordinator
    @EnvironmentObject var analyticsService: AnalyticsService
    @State private var selectedPlan: SubscriptionManager.SubscriptionPlan = .annual
    @State private var showingTrial = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.xl) {
                        // Header
                        headerSection
                        
                        // Benefits List
                        benefitsSection
                        
                        // Subscription Plans
                        subscriptionPlansSection
                        
                        // Smart Trial Options
                        smartTrialOptionsSection
                        
                        // Social Proof
                        socialProofSection
                        
                        // Legal Links
                        legalSection
                    }
                    .padding(.horizontal, DesignSystem.Spacing.card)
                    .padding(.top, DesignSystem.Spacing.card)
                }
            }
            .navigationBarHidden(true)
            .alert("Free Trial Started", isPresented: $showingTrial) {
                Button("OK") {
                    ServiceContainer.shared.navigationCoordinator.navigateBack()
                }
            } message: {
                Text("Your 3-day free trial has started. You can cancel anytime.")
            }
        }
        .onAppear {
            ServiceContainer.shared.analyticsService.track(event: "paywall_viewed")
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            HStack {
                Button(action: { 
                    navigationCoordinator.navigateBack()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: DesignSystem.IconSizes.medium, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
                
                Spacer()
            }
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text("⭐ Go Pro & Unlock All")
                    .font(DesignSystem.Typography.h2)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Transform your photos with professional AI")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var benefitsSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            ForEach(benefits, id: \.title) { benefit in
                ModernCard(
                    padding: DesignSystem.Spacing.md,
                    cornerRadius: DesignSystem.CornerRadius.md,
                    shadow: DesignSystem.Shadows.small
                ) {
                    HStack(spacing: DesignSystem.Spacing.md) {
                        Image(systemName: benefit.icon)
                            .font(.system(size: DesignSystem.IconSizes.medium, weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.success)
                            .frame(width: DesignSystem.IconSizes.large)
                        
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text(benefit.title)
                                .font(DesignSystem.Typography.bodyBold)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            
                            Text(benefit.description)
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                        
                        Spacer()
                    }
                }
            }
        }
    }
    
    private var subscriptionPlansSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Annual Plan (Recommended)
            SubscriptionPlanCard(
                plan: .annual,
                isSelected: selectedPlan == .annual,
                onTap: { selectedPlan = .annual }
            )
            
            // Weekly Plan
            SubscriptionPlanCard(
                plan: .weekly,
                isSelected: selectedPlan == .weekly,
                onTap: { selectedPlan = .weekly }
            )
            
            // Lifetime Plan
            SubscriptionPlanCard(
                plan: .lifetime,
                isSelected: selectedPlan == .lifetime,
                onTap: { selectedPlan = .lifetime }
            )
        }
    }
    
    private var smartTrialOptionsSection: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            if !subscriptionStateManager.isTrialActive {
                // Trial Options
                VStack(spacing: DesignSystem.Spacing.md) {
                    Text("Choose Your Free Trial")
                        .font(DesignSystem.Typography.h4)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    // Limited Trial (3 generations, 7 days)
                    TrialOptionCard(
                        title: "Limited Trial",
                        subtitle: "3 generations, 7 days",
                        description: "Perfect for trying out the app",
                        icon: "star.fill",
                        color: DesignSystem.Colors.primary,
                        action: {
                            appCoordinator.startFreeTrial(type: FreeTrialService.TrialType.limited)
                            analyticsService.track(event: "limited_trial_started")
                        }
                    )
                    
                    // Unlimited Trial (3 days full access)
                    TrialOptionCard(
                        title: "Unlimited Trial",
                        subtitle: "Full access, 3 days",
                        description: "Experience everything VividAI offers",
                        icon: "crown.fill",
                        color: DesignSystem.Colors.warning,
                        action: {
                            appCoordinator.startFreeTrial(type: FreeTrialService.TrialType.unlimited)
                            analyticsService.track(event: "unlimited_trial_started")
                        }
                    )
                }
            } else {
                // Current Trial Status
                ModernCard(
                    padding: DesignSystem.Spacing.lg,
                    cornerRadius: DesignSystem.CornerRadius.lg,
                    shadow: DesignSystem.Shadows.medium
                ) {
                    VStack(spacing: DesignSystem.Spacing.md) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(DesignSystem.Colors.warning)
                            
                            Text("Free Trial Active")
                                .font(DesignSystem.Typography.h4)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            
                            Spacer()
                        }
                        
                        HStack {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                Text("\(ServiceContainer.shared.subscriptionStateManager.trialGenerationsUsed)/\(ServiceContainer.shared.subscriptionStateManager.trialMaxGenerations) generations used")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                
                                Text("\(ServiceContainer.shared.subscriptionStateManager.trialDaysRemaining) days remaining")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                            }
                            
                            Spacer()
                            
                            Button("Upgrade Now") {
                                // Handle subscription purchase
                                ServiceContainer.shared.analyticsService.track(event: "upgrade_from_trial_tapped")
                            }
                            .font(DesignSystem.Typography.captionBold)
                            .foregroundColor(.white)
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            .padding(.vertical, DesignSystem.Spacing.sm)
                            .background(DesignSystem.Colors.primary)
                            .cornerRadius(DesignSystem.CornerRadius.sm)
                        }
                    }
                }
                .background(DesignSystem.Colors.warning.opacity(0.1))
            }
        }
    }
    
    private var socialProofSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                ForEach(0..<5) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: DesignSystem.IconSizes.small))
                        .foregroundColor(DesignSystem.Colors.warning)
                }
            }
            
            Text("Join 2.3M+ users")
                .font(DesignSystem.Typography.captionBold)
                .foregroundColor(DesignSystem.Colors.textPrimary)
        }
    }
    
    private var legalSection: some View {
        HStack(spacing: DesignSystem.Spacing.lg) {
            Button("Restore Purchases") {
                appCoordinator.handleSubscriptionAction(.restorePurchases)
            }
            .font(DesignSystem.Typography.caption)
            .foregroundColor(DesignSystem.Colors.primary)
            
            Button("Terms of Service") {
                // Open terms
            }
            .font(DesignSystem.Typography.caption)
            .foregroundColor(DesignSystem.Colors.primary)
        }
    }
    
    private let benefits = [
        Benefit(icon: "checkmark.circle.fill", title: "Unlimited Headshots", description: "Generate as many as you want"),
        Benefit(icon: "checkmark.circle.fill", title: "No Watermarks", description: "Clean, professional results"),
        Benefit(icon: "checkmark.circle.fill", title: "All 20+ Styles", description: "Corporate, creative, and more"),
        Benefit(icon: "checkmark.circle.fill", title: "HD Quality (4K)", description: "Crystal clear results"),
        Benefit(icon: "checkmark.circle.fill", title: "Background Removal", description: "One-tap background removal"),
        Benefit(icon: "checkmark.circle.fill", title: "Old Photo Restore", description: "Bring old photos back to life")
    ]
    
    private func startFreeTrial() {
        // Start free trial logic
        appCoordinator.handleSubscriptionAction(.startFreeTrial(selectedPlan))
        showingTrial = true
    }
}

// MARK: - Supporting Views

struct SubscriptionPlanCard: View {
    let plan: SubscriptionManager.SubscriptionPlan
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
                
                // Plan Details
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    HStack {
                        Text(plan.title)
                            .font(DesignSystem.Typography.bodyBold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        if plan.isRecommended {
                            ModernBadge(
                                text: "MOST POPULAR",
                                color: DesignSystem.Colors.warning,
                                size: .small
                            )
                        }
                        
                        Spacer()
                    }
                    
                    Text(plan.price)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    if let savings = plan.savings {
                        Text(savings)
                            .font(DesignSystem.Typography.small)
                            .foregroundColor(DesignSystem.Colors.success)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(
                ModernVisualEffects.modernCard(
                    cornerRadius: DesignSystem.CornerRadius.md,
                    shadow: DesignSystem.Shadows.small
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                        .stroke(isSelected ? DesignSystem.Colors.primary : Color.clear, lineWidth: 2)
                )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Supporting Views

struct TrialOptionCard: View {
    let title: String
    let subtitle: String
    let description: String
    let icon: String
    let color: Color
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: DesignSystem.IconSizes.large, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(title)
                        .font(DesignSystem.Typography.bodyBold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text(subtitle)
                        .font(DesignSystem.Typography.captionBold)
                        .foregroundColor(color)
                    
                    Text(description)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.system(size: DesignSystem.IconSizes.small, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            .padding(DesignSystem.Spacing.md)
            .background(
                ModernVisualEffects.modernCard(
                    cornerRadius: DesignSystem.CornerRadius.md,
                    shadow: DesignSystem.Shadows.small
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(DesignSystem.Animations.quick, value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onTapGesture {
            withAnimation(DesignSystem.Animations.quick) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(DesignSystem.Animations.quick) {
                    isPressed = false
                }
            }
        }
    }
}

// MARK: - Data Models

struct Benefit {
    let icon: String
    let title: String
    let description: String
}

// SubscriptionPlan enum moved to SubscriptionManager.swift to avoid duplication

#Preview {
    PaywallView()
        .environmentObject(UnifiedAppStateManager.shared)
}
