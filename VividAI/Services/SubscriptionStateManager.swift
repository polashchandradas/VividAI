import Foundation
import SwiftUI
import Combine
import StoreKit
import os.log

// MARK: - Unified Subscription State Manager
// Single source of truth for all subscription and trial state

class SubscriptionStateManager: ObservableObject {
    static let shared = SubscriptionStateManager()
    
    // MARK: - Published Properties (Delegated to Unified State Manager)
    // All core state is now managed by UnifiedAppStateManager to avoid duplication
    
    // Local state for subscription-specific operations
    @Published var isTrialActive = false
    @Published var trialType: TrialType = .none
    @Published var trialDaysRemaining = 0
    @Published var trialGenerationsUsed = 0
    @Published var trialMaxGenerations = 3
    @Published var canGenerate = true
    @Published var remainingGenerations = 0
    
    // MARK: - Unified State Access (Computed Properties)
    
    @MainActor
    var isPremiumUser: Bool { 
        return ServiceContainer.shared.unifiedAppStateManager.isPremiumUser 
    }
    
    @MainActor
    var subscriptionStatus: SubscriptionStatus { 
        return ServiceContainer.shared.unifiedAppStateManager.subscriptionStatus 
    }
    
    // MARK: - Computed Properties
    
    @MainActor
    var userStatus: UserStatus {
        if ServiceContainer.shared.unifiedAppStateManager.isPremiumUser {
            return .premium
        } else if isTrialActive {
            return .trial(trialType)
        } else {
            return .free
        }
    }
    
    @MainActor
    var generationLimits: GenerationLimits {
        if ServiceContainer.shared.unifiedAppStateManager.isPremiumUser {
            return .unlimited
        } else if isTrialActive {
            return .trial(
                used: trialGenerationsUsed,
                max: trialMaxGenerations,
                daysRemaining: trialDaysRemaining
            )
        } else {
            return .free(remaining: remainingGenerations)
        }
    }
    
    // MARK: - Private Properties
    
    private let logger = Logger(subsystem: "VividAI", category: "SubscriptionState")
    private var cancellables = Set<AnyCancellable>()
    
    // Service dependencies
    private var subscriptionManager: SubscriptionManager { ServiceContainer.shared.subscriptionManager }
    private var freeTrialService: FreeTrialService { ServiceContainer.shared.freeTrialService }
    private var usageLimitService: UsageLimitService { ServiceContainer.shared.usageLimitService }
    private var secureStorageService: SecureStorageService { ServiceContainer.shared.secureStorageService }
    private var analyticsService: AnalyticsService { ServiceContainer.shared.analyticsService }
    
    // MARK: - Initialization
    
    private init() {
        setupSubscriptions()
        loadInitialState()
    }
    
    // MARK: - Setup
    
    private func setupSubscriptions() {
        // Monitor subscription manager changes
        subscriptionManager.$availableProducts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateSubscriptionState()
            }
            .store(in: &cancellables)
        
        // Monitor free trial service changes
        freeTrialService.$isTrialActive
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateTrialState()
            }
            .store(in: &cancellables)
        
        freeTrialService.$trialDaysRemaining
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateTrialState()
            }
            .store(in: &cancellables)
        
        freeTrialService.$generationsUsed
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateTrialState()
            }
            .store(in: &cancellables)
        
        // Monitor usage limit service changes
        usageLimitService.$dailyGenerations
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateUsageLimits()
            }
            .store(in: &cancellables)
    }
    
    private func loadInitialState() {
        logger.info("Loading initial subscription state")
        
        // Load subscription state from SubscriptionManager
        updateSubscriptionState()
        
        // Load trial state from FreeTrialService
        updateTrialState()
        
        // Load usage limits from UsageLimitService
        updateUsageLimits()
        
        // Calculate unified state
        calculateUnifiedState()
        
        // Sync with unified state manager
        Task { @MainActor in
            ServiceContainer.shared.unifiedAppStateManager.isPremiumUser = await subscriptionManager.currentIsPremiumUser
            ServiceContainer.shared.unifiedAppStateManager.subscriptionStatus = await subscriptionManager.currentSubscriptionStatus
        }
    }
    
    // MARK: - State Updates
    
    private func updateSubscriptionState() {
        Task { @MainActor in
            // Get subscription state from SubscriptionManager
            let isPremium = await subscriptionManager.currentIsPremiumUser
            let status = await subscriptionManager.currentSubscriptionStatus
            
            // Update unified state manager
            ServiceContainer.shared.unifiedAppStateManager.isPremiumUser = isPremium
            ServiceContainer.shared.unifiedAppStateManager.subscriptionStatus = status
            self.calculateUnifiedState()
            
            logger.info("Subscription state updated: isPremium=\(isPremium), status=\(status)")
        }
    }
    
    private func updateTrialState() {
        DispatchQueue.main.async {
            self.isTrialActive = self.freeTrialService.isTrialActive
            self.trialType = self.freeTrialService.trialType
            self.trialDaysRemaining = self.freeTrialService.trialDaysRemaining
            self.trialGenerationsUsed = self.freeTrialService.generationsUsed
            self.trialMaxGenerations = self.freeTrialService.maxGenerations
            self.calculateUnifiedState()
        }
        
        logger.info("Trial state updated: isActive=\(self.freeTrialService.isTrialActive), type=\(self.freeTrialService.trialType)")
    }
    
    private func updateUsageLimits() {
        DispatchQueue.main.async {
            self.remainingGenerations = self.usageLimitService.getRemainingGenerations(
                isPremium: ServiceContainer.shared.unifiedAppStateManager.isPremiumUser,
                isTrialActive: self.isTrialActive
            )
            self.calculateUnifiedState()
        }
        
        logger.info("Usage limits updated: remaining=\(self.remainingGenerations)")
    }
    
    private func calculateUnifiedState() {
        // Calculate if user can generate
        Task { @MainActor in
            let canGenerate = calculateCanGenerate()
            
            // Update published properties
            self.canGenerate = canGenerate
            
            // Log state change
            logger.info("Unified state calculated: canGenerate=\(canGenerate), userStatus=\(self.userStatus)")
            
            // Track analytics
            analyticsService.track(event: "subscription_state_updated", parameters: [
                "is_premium": ServiceContainer.shared.unifiedAppStateManager.isPremiumUser,
                "is_trial_active": isTrialActive,
                "trial_type": "\(trialType)",
                "can_generate": canGenerate,
                "remaining_generations": remainingGenerations
            ])
        }
    }
    
    private func calculateCanGenerate() -> Bool {
        // Premium users can always generate
        // Note: This function runs on main actor due to being called from calculateUnifiedState
        // which is called from DispatchQueue.main.async blocks
        let isPremium = ServiceContainer.shared.unifiedAppStateManager.isPremiumUser
        if isPremium {
            return true
        }
        
        // Check trial limits if trial is active
        if isTrialActive {
            return freeTrialService.canUserGenerate()
        }
        
        // Check usage limits for free users
        return usageLimitService.canGenerate(
            isPremium: isPremium,
            isTrialActive: isTrialActive
        )
    }
    
    // MARK: - Public Methods
    
    func refreshState() {
        logger.info("Refreshing subscription state")
        
        // Refresh subscription status
        subscriptionManager.checkSubscriptionStatus()
        
        // Refresh trial status
        freeTrialService.checkTrialStatus()
        
        // Refresh usage limits
        usageLimitService.refreshLimits()
    }
    
    func startFreeTrial(type: TrialType) {
        logger.info("Starting free trial: \(type)")
        
        // Convert TrialType to FreeTrialService's expected type
        // Note: FreeTrialService now uses SharedTypes.TrialType
        freeTrialService.startFreeTrial(type: type)
        
        // State will be updated through subscriptions
        analyticsService.track(event: "free_trial_started", parameters: [
            "trial_type": "\(type)"
        ])
    }
    
    func recordGeneration() {
        logger.info("Recording generation")
        
        // Record in usage limit service
        usageLimitService.recordGeneration()
        
        // Record in trial service if trial is active
        if isTrialActive {
            freeTrialService.recordGeneration()
        }
        
        // Update state
        updateUsageLimits()
        updateTrialState()
        
        Task { @MainActor in
            let isPremium = ServiceContainer.shared.unifiedAppStateManager.isPremiumUser
            analyticsService.track(event: "generation_recorded", parameters: [
                "is_premium": isPremium,
                "is_trial_active": isTrialActive,
                "trial_type": "\(trialType)"
            ])
        }
    }
    
    @MainActor
    func getRemainingGenerations() -> Int {
        if ServiceContainer.shared.unifiedAppStateManager.isPremiumUser {
            return 999 // Unlimited
        }
        
        if isTrialActive {
            return max(0, trialMaxGenerations - trialGenerationsUsed)
        }
        
        return remainingGenerations
    }
    
    @MainActor
    func getLimitMessage() -> String {
        if ServiceContainer.shared.unifiedAppStateManager.isPremiumUser {
            return "You have unlimited generations with Pro"
        }
        
        if isTrialActive {
            return getTrialLimitMessage()
        }
        
        return getFreeUserLimitMessage()
    }
    
    @MainActor
    private func getTrialLimitMessage() -> String {
        switch trialType {
        case .limited:
            return "Trial limit reached (\(trialGenerationsUsed)/\(trialMaxGenerations) generations used)"
        case .unlimited:
            return "Trial expired (\(trialDaysRemaining) days remaining)"
        case .freemium:
            return "Daily limit reached (1 generation per day)"
        case .none:
            return "No active trial"
        }
    }
    
    @MainActor
    private func getFreeUserLimitMessage() -> String {
        return usageLimitService.getLimitMessage(
            isPremium: ServiceContainer.shared.unifiedAppStateManager.isPremiumUser,
            isTrialActive: isTrialActive
        )
    }
    
    // MARK: - Subscription Actions
    
    func handleSubscriptionAction(_ action: SubscriptionAction) {
        logger.info("Handling subscription action: \(action)")
        
        switch action {
        case .startFreeTrial(let plan):
            let trialType: TrialType = plan == .annual ? .unlimited : .limited
            startFreeTrial(type: trialType)
            
        case .purchase(let product):
            guard let storeKitProduct = product.storeKitProduct else {
                logger.error("Product not available for purchase")
                return
            }
            Task {
                do {
                    _ = try await subscriptionManager.purchase(product: storeKitProduct)
                } catch {
                    logger.error("Purchase failed: \(error.localizedDescription)")
                }
            }
            
        case .restorePurchases:
            subscriptionManager.restorePurchases()
            
        case .cancelSubscription:
            subscriptionManager.cancelSubscription(for: nil)
        }
    }
}

// MARK: - Supporting Types
// Note: UserStatus, GenerationLimits, SubscriptionAction, and TrialType are now defined in SharedTypes.swift
