import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var analyticsService: AnalyticsService
    @State private var selectedPlan: SubscriptionPlan = .annual
    @State private var showingTrial = false
    
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
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationBarHidden(true)
            .alert("Free Trial Started", isPresented: $showingTrial) {
                Button("OK") {
                    dismiss()
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
        VStack(spacing: 16) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                Spacer()
            }
            
            VStack(spacing: 8) {
                Text("⭐ Go Pro & Unlock All")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("Transform your photos with professional AI")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var benefitsSection: some View {
        VStack(spacing: 16) {
            ForEach(benefits, id: \.title) { benefit in
                HStack(spacing: 16) {
                    Image(systemName: benefit.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.green)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(benefit.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text(benefit.description)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
    }
    
    private var subscriptionPlansSection: some View {
        VStack(spacing: 16) {
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
        VStack(spacing: 16) {
            Button(action: {
                analyticsService.track(event: "free_trial_started", parameters: [
                    "plan": selectedPlan.rawValue
                ])
                startFreeTrial()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Text("START FREE TRIAL")
                        .font(.system(size: 18, weight: .bold))
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
            
            Text("3 days free, then \(selectedPlan.priceText)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var socialProofSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 4) {
                ForEach(0..<5) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.yellow)
                }
            }
            
            Text("Join 2.3M+ users")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
        }
    }
    
    private var legalSection: some View {
        HStack(spacing: 20) {
            Button("Restore Purchases") {
                subscriptionManager.restorePurchases()
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.blue)
            
            Button("Terms of Service") {
                // Open terms
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.blue)
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
        subscriptionManager.startFreeTrial(plan: selectedPlan)
        showingTrial = true
    }
}

// MARK: - Supporting Views

struct SubscriptionPlanCard: View {
    let plan: SubscriptionPlan
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
                
                // Plan Details
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(plan.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        if plan.isRecommended {
                            Text("★ MOST POPULAR ★")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .cornerRadius(4)
                        }
                        
                        Spacer()
                    }
                    
                    Text(plan.priceText)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    if let savings = plan.savings {
                        Text(savings)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.green)
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
