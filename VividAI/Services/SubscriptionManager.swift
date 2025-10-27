import Foundation
import StoreKit
import Combine
import SwiftUI
import UIKit
import os.log
import CoreFoundation
import CoreGraphics
import CoreData

class SubscriptionManager: NSObject, ObservableObject {
    static let shared = SubscriptionManager()
    
    // MARK: - Published State (Only for StoreKit-specific data)
    @Published var availableProducts: [StoreKit.Product] = []
    @Published var isLoading = false
    
    // MARK: - Private State (Delegated to Unified State Manager)
    // All core state is now managed by UnifiedAppStateManager to avoid duplication
    // These are kept for backward compatibility but delegate to unified state
    @MainActor
    private var _isPremiumUser: Bool { 
        return ServiceContainer.shared.unifiedAppStateManager.isPremiumUser 
    }
    @MainActor
    private var _subscriptionStatus: SubscriptionStatus { 
        return ServiceContainer.shared.unifiedAppStateManager.subscriptionStatus 
    }
    
    // MARK: - Callback for state changes
    var onSubscriptionStateChanged: ((Bool, SubscriptionStatus) -> Void)?
    
    private var productRequest: Task<Void, Error>?
    private var updateListenerTask: Task<Void, Error>?
    
    // Product IDs
    private let productIDs = [
        "com.vividai.annual": "Annual Subscription",
        "com.vividai.weekly": "Weekly Subscription",
        "com.vividai.lifetime": "Lifetime Access"
    ]
    
    override init() {
        super.init()
        
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()
        
        // Load products
        loadProducts()
        
        // Check current subscription status
        checkSubscriptionStatus()
    }
    
    deinit {
        productRequest?.cancel()
        updateListenerTask?.cancel()
    }
    
    // MARK: - Product Loading
    
    private func loadProducts() {
        isLoading = true
        
        productRequest = Task {
            do {
                let products = try await StoreKit.Product.products(for: Array(productIDs.keys))
                
                await MainActor.run {
                    self.availableProducts = products
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    print("Failed to load products: \(error)")
                }
            }
        }
    }
    
    // MARK: - Purchase Methods
    
    func purchase(product: StoreKit.Product) async throws -> StoreKit.Transaction? {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            
            await MainActor.run {
                self.updateSubscriptionStatus()
            }
            
            return transaction
        case .userCancelled:
            throw SubscriptionError.userCancelled
        case .pending:
            throw SubscriptionError.pending
        @unknown default:
            throw SubscriptionError.unknown
        }
    }
    
    func startFreeTrial(plan: SubscriptionPlan) {
        Task {
            do {
                // Use Firebase validation for trial start
                let trialType: TrialType = plan == .annual ? .unlimited : .limited
                let result = try await ServiceContainer.shared.firebaseValidationService.startTrialWithFirebase(type: trialType)
                
                if result.isValid && !result.abuseDetected {
                    // Store trial data locally
                    let deviceId = ServiceContainer.shared.secureStorageService.getDeviceId()
                    let trialData = TrialData(
                        startDate: Date(),
                        isActive: true,
                        deviceId: deviceId
                    )
                    
                    ServiceContainer.shared.secureStorageService.storeTrialData(trialData)
                    
                    // Update unified state manager
                    await MainActor.run {
                        ServiceContainer.shared.unifiedAppStateManager.isPremiumUser = true
                        ServiceContainer.shared.unifiedAppStateManager.subscriptionStatus = .trial
                        self.onSubscriptionStateChanged?(true, .trial)
                    }
                    
                    // Track analytics
                    ServiceContainer.shared.analyticsService.track(event: "free_trial_started", parameters: [
                        "plan": plan.rawValue,
                        "device_id": deviceId,
                        "server_validated": result.serverValidated
                    ])
                } else {
                    // Handle abuse or validation failure
                    await MainActor.run {
                        ServiceContainer.shared.unifiedAppStateManager.isPremiumUser = false
                        ServiceContainer.shared.unifiedAppStateManager.subscriptionStatus = .none
                        self.onSubscriptionStateChanged?(false, .none)
                    }
                    
                    ServiceContainer.shared.analyticsService.track(event: "trial_start_blocked", parameters: [
                        "reason": result.reason ?? "unknown",
                        "abuse_detected": result.abuseDetected
                    ])
                }
            } catch {
                // Fallback to local trial start
                let deviceId = ServiceContainer.shared.secureStorageService.getDeviceId()
                let trialData = TrialData(
                    startDate: Date(),
                    isActive: true,
                    deviceId: deviceId
                )
                
                ServiceContainer.shared.secureStorageService.storeTrialData(trialData)
                
                await MainActor.run {
                    ServiceContainer.shared.unifiedAppStateManager.isPremiumUser = true
                    ServiceContainer.shared.unifiedAppStateManager.subscriptionStatus = .trial
                    self.onSubscriptionStateChanged?(true, .trial)
                }
                
                ServiceContainer.shared.analyticsService.track(event: "free_trial_started_local", parameters: [
                    "plan": plan.rawValue,
                    "device_id": deviceId,
                    "fallback": true
                ])
            }
        }
    }
    
    func restorePurchases() {
        Task {
            do {
                try await AppStore.sync()
                await MainActor.run {
                    self.updateSubscriptionStatus()
                }
            } catch {
                print("Failed to restore purchases: \(error)")
            }
        }
    }
    
    // MARK: - Subscription Status
    
    func checkSubscriptionStatus() {
        // Check for active subscription
        Task {
            for await result in StoreKit.Transaction.currentEntitlements {
                if case .verified(let transaction) = result {
                    if transaction.productType == .autoRenewable {
                        await MainActor.run {
                            ServiceContainer.shared.unifiedAppStateManager.isPremiumUser = true
                            ServiceContainer.shared.unifiedAppStateManager.subscriptionStatus = .active
                            self.onSubscriptionStateChanged?(true, .active)
                        }
                        return
                    }
                }
            }
            
            // Check for free trial
            if isFreeTrialActive() {
                await MainActor.run {
                    ServiceContainer.shared.unifiedAppStateManager.isPremiumUser = true
                    ServiceContainer.shared.unifiedAppStateManager.subscriptionStatus = .trial
                    self.onSubscriptionStateChanged?(true, .trial)
                }
            }
        }
    }
    
    private func updateSubscriptionStatus() {
        Task {
            var hasActiveSubscription = false
            
            for await result in StoreKit.Transaction.currentEntitlements {
                if case .verified(let transaction) = result {
                    if transaction.productType == .autoRenewable {
                        hasActiveSubscription = true
                        break
                    }
                }
            }
            
            await MainActor.run {
                ServiceContainer.shared.unifiedAppStateManager.isPremiumUser = hasActiveSubscription || self.isFreeTrialActive()
                ServiceContainer.shared.unifiedAppStateManager.subscriptionStatus = hasActiveSubscription ? .active : (self.isFreeTrialActive() ? .trial : .none)
                self.onSubscriptionStateChanged?(ServiceContainer.shared.unifiedAppStateManager.isPremiumUser, ServiceContainer.shared.unifiedAppStateManager.subscriptionStatus)
            }
        }
    }
    
    private func isFreeTrialActive() -> Bool {
        guard let trialData = ServiceContainer.shared.secureStorageService.getTrialData() else { return false }
        
        // CRITICAL: Always validate with server for security
        Task {
            let serverValidation = await ServiceContainer.shared.serverValidationService.validateTrialStatus()
            
            // Update local status based on server validation
            if !serverValidation.isValid || !serverValidation.serverValidated {
                // Server says trial is invalid - update local state
                await MainActor.run {
                    ServiceContainer.shared.unifiedAppStateManager.isPremiumUser = false
                    ServiceContainer.shared.unifiedAppStateManager.subscriptionStatus = .none
                    self.onSubscriptionStateChanged?(false, .none)
                }
                
                // Clear invalid trial data
                ServiceContainer.shared.secureStorageService.clearTrialData()
            }
        }
        
        // Basic local check (but server validation takes precedence)
        let trialEndDate = trialData.startDate.addingTimeInterval(3 * 24 * 60 * 60) // 3 days
        let isLocallyValid = Date() < trialEndDate && trialData.isActive
        
        // Only trust local validation if server validation is not available
        return isLocallyValid && trialData.serverValidated
    }
    
    // MARK: - Transaction Listening
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in StoreKit.Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await transaction.finish()
                    
                    await MainActor.run {
                        self.updateSubscriptionStatus()
                    }
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.unverified
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Helper Methods
    
    func getProduct(for plan: SubscriptionPlan) -> StoreKit.Product? {
        let productID = plan.productID
        return availableProducts.first { $0.id == productID }
    }
    
    // MARK: - Current State Access (Delegated to Unified State Manager)
    
    @MainActor
    var currentIsPremiumUser: Bool {
        return ServiceContainer.shared.unifiedAppStateManager.isPremiumUser
    }
    
    @MainActor
    var currentSubscriptionStatus: SubscriptionStatus {
        return ServiceContainer.shared.unifiedAppStateManager.subscriptionStatus
    }
    
    @MainActor
    func getSubscriptionInfo() -> SubscriptionInfo {
        return SubscriptionInfo(
            isPremium: ServiceContainer.shared.unifiedAppStateManager.isPremiumUser,
            status: ServiceContainer.shared.unifiedAppStateManager.subscriptionStatus,
            trialDaysRemaining: getTrialDaysRemaining()
        )
    }
    
    private func getTrialDaysRemaining() -> Int {
        guard let trialData = ServiceContainer.shared.secureStorageService.getTrialData() else { return 0 }
        
        let trialEndDate = trialData.startDate.addingTimeInterval(3 * 24 * 60 * 60)
        let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: trialEndDate).day ?? 0
        return max(0, daysRemaining)
    }
    
    // MARK: - SubscriptionPlan Enum
    
    enum SubscriptionPlan: String, CaseIterable {
        case annual = "annual"
        case weekly = "weekly"
        case lifetime = "lifetime"
        
        var productID: String {
            switch self {
            case .annual: return "com.vividai.annual"
            case .weekly: return "com.vividai.weekly"
            case .lifetime: return "com.vividai.lifetime"
            }
        }
        
        var price: String {
            switch self {
            case .annual: return "$39.99"
            case .weekly: return "$4.99"
            case .lifetime: return "$99.99"
            }
        }
        
        var title: String {
            switch self {
            case .annual: return "ANNUAL PLAN"
            case .weekly: return "WEEKLY PLAN"
            case .lifetime: return "LIFETIME ACCESS"
            }
        }
        
        var savings: String? {
            switch self {
            case .annual: return "Save 67% ($3.33/mo)"
            case .weekly: return "Cancel anytime"
            case .lifetime: return "Pay once, use forever"
            }
        }
        
        var isRecommended: Bool {
            return self == .annual
        }
        
        var period: String {
            switch self {
            case .annual: return "year"
            case .weekly: return "week"
            case .lifetime: return "one-time"
            }
        }
    }
}

// MARK: - Data Models

// SubscriptionPlan enum moved inside SubscriptionManager class

struct SubscriptionInfo {
    let isPremium: Bool
    let status: SubscriptionStatus
    let trialDaysRemaining: Int
}

enum SubscriptionError: Error, LocalizedError {
    case userCancelled
    case pending
    case unverified
    case unknown
    case productNotFound
    case purchaseFailed
    
    var errorDescription: String? {
        switch self {
        case .userCancelled:
            return "Purchase was cancelled"
        case .pending:
            return "Purchase is pending approval"
        case .unverified:
            return "Purchase could not be verified"
        case .unknown:
            return "An unknown error occurred"
        case .productNotFound:
            return "Product not found"
        case .purchaseFailed:
            return "Purchase failed"
        }
    }
    
    // MARK: - Subscription Cancellation
    
    func cancelSubscription(for productID: String? = nil) {
        Task {
            // In a real implementation, this would handle cancellation through StoreKit
            // For now, we'll just update the state
            await MainActor.run {
                ServiceContainer.shared.unifiedAppStateManager.isPremiumUser = false
                ServiceContainer.shared.unifiedAppStateManager.subscriptionStatus = .cancelled
                self.onSubscriptionStateChanged?(false, .cancelled)
            }
            
            analyticsService.track(event: "subscription_cancelled", parameters: [
                "product_id": productID ?? "unknown"
            ])
        }
    }
}
