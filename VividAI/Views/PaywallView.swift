import SwiftUI
import StoreKit
import UIKit

struct PaywallView: View {
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    @EnvironmentObject var appCoordinator: AppCoordinator
    @EnvironmentObject var subscriptionManager: SubscriptionManager
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
                        
                        // Free Trial CTA
                        freeTrialSection
                        
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
                    navigationCoordinator.navigateBack()
                }
            } message: {
                Text("Your 3-day free trial has started. You can cancel anytime.")
            }
        }
        .onAppear {
            analyticsService.track(event: "paywall_viewed")
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
    
    private var freeTrialSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Button(action: {
                analyticsService.track(event: "free_trial_started", parameters: [
                    "plan": selectedPlan.rawValue
                ])
                startFreeTrial()
            }) {
                HStack(spacing: DesignSystem.Spacing.md) {
                    Image(systemName: "star.fill")
                        .font(.system(size: DesignSystem.IconSizes.medium, weight: .semibold))
                    
                    Text("START FREE TRIAL")
                        .font(DesignSystem.Typography.buttonLarge)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: DesignSystem.Heights.buttonLarge)
                .background(DesignSystem.Colors.gradientSecondary)
                .cornerRadius(DesignSystem.CornerRadius.lg)
                .overlay(
                    ModernVisualEffects.glowEffect(
                        color: DesignSystem.Colors.primary,
                        intensity: 0.3
                    )
                )
            }
            
            Text("3 days free, then \(selectedPlan.price)")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
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
                subscriptionManager.restorePurchases()
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
        appCoordinator.handleSubscriptionAction(.startFreeTrial(SubscriptionManager.SubscriptionPlan(rawValue: selectedPlan.rawValue) ?? .monthly))
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

// MARK: - Data Models

struct Benefit {
    let icon: String
    let title: String
    let description: String
}

// SubscriptionPlan enum moved to SubscriptionManager.swift to avoid duplication

#Preview {
    PaywallView()
        .environmentObject(SubscriptionManager())
        .environmentObject(AnalyticsService())
}
