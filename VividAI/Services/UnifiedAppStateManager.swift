import Foundation
import SwiftUI
import Combine
import os.log
import FirebaseAuth
import StoreKit

// MARK: - Unified App State Manager
// This replaces all duplicate state management systems with a single source of truth

@MainActor
class UnifiedAppStateManager: ObservableObject {
    static let shared = UnifiedAppStateManager()
    
    // MARK: - Published State Properties (Single Source of Truth)
    
    // Authentication State
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User? = nil
    @Published var authenticationError: String? = nil
    
    // Subscription State
    @Published var isPremiumUser: Bool = false
    @Published var subscriptionStatus: SubscriptionStatus = .none
    @Published var subscriptionExpiryDate: Date? = nil
    @Published var subscriptionError: String? = nil
    
    // Processing State
    @Published var isProcessing: Bool = false
    @Published var processingProgress: Double = 0.0
    @Published var processingError: String? = nil
    @Published var processingResults: [ProcessingResult] = []
    
    // Navigation State
    @Published var currentView: AppView = .splash
    @Published var selectedImage: UIImage? = nil
    @Published var generatedVideoURL: URL? = nil
    
    // App State
    @Published var isLoading: Bool = false
    @Published var appError: String? = nil
    
    // MARK: - Private Properties
    private let logger = Logger(subsystem: "VividAI", category: "UnifiedAppStateManager")
    private var cancellables = Set<AnyCancellable>()
    
    // Service Dependencies
    private var authenticationService: AuthenticationService
    private var subscriptionManager: SubscriptionManager
    private var analyticsService: AnalyticsService
    private var secureStorage: SecureStorageService
    
    // MARK: - Initialization
    
    private init() {
        // Initialize service dependencies
        self.authenticationService = ServiceContainer.shared.authenticationService
        self.subscriptionManager = ServiceContainer.shared.subscriptionManager
        self.analyticsService = ServiceContainer.shared.analyticsService
        self.secureStorage = ServiceContainer.shared.secureStorageService
        
        setupStateObservers()
        loadPersistedState()
        
        logger.info("UnifiedAppStateManager initialized")
    }
    
    // MARK: - State Observers Setup
    
    private func setupStateObservers() {
        // Observe authentication changes
        authenticationService.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAuthenticated in
                self?.isAuthenticated = isAuthenticated
                self?.logger.info("Authentication state updated: \(isAuthenticated)")
            }
            .store(in: &cancellables)
        
        authenticationService.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.currentUser = user
                self?.logger.info("Current user updated: \(user?.email ?? "nil")")
            }
            .store(in: &cancellables)
        
        // Observe subscription changes
        subscriptionManager.$isPremiumUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isPremium in
                self?.isPremiumUser = isPremium
                self?.logger.info("Premium status updated: \(isPremium)")
            }
            .store(in: &cancellables)
        
        subscriptionManager.$subscriptionStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.subscriptionStatus = status
                self?.logger.info("Subscription status updated: \(status)")
            }
            .store(in: &cancellables)
    }
    
    // MARK: - State Persistence
    
    private func loadPersistedState() {
        // Load authentication state
        isAuthenticated = authenticationService.isAuthenticated
        currentUser = authenticationService.currentUser
        
        // Load subscription state
        isPremiumUser = subscriptionManager.isPremiumUser
        subscriptionStatus = subscriptionManager.subscriptionStatus
        
        logger.info("Persisted state loaded")
    }
    
    // MARK: - Authentication Actions
    
    func signIn(email: String, password: String) async {
        isLoading = true
        authenticationError = nil
        
        do {
            let user = try await authenticationService.signIn(email: email, password: password)
            currentUser = user
            isAuthenticated = true
            
            analyticsService.track(event: "user_signed_in", parameters: [
                "user_id": user.uid,
                "email": user.email
            ])
            
            logger.info("User signed in successfully: \(user.email)")
        } catch {
            authenticationError = error.localizedDescription
            logger.error("Sign in failed: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func signUp(email: String, password: String) async {
        isLoading = true
        authenticationError = nil
        
        do {
            let user = try await authenticationService.signUp(email: email, password: password)
            currentUser = user
            isAuthenticated = true
            
            analyticsService.track(event: "user_signed_up", parameters: [
                "user_id": user.uid,
                "email": user.email
            ])
            
            logger.info("User signed up successfully: \(user.email)")
        } catch {
            authenticationError = error.localizedDescription
            logger.error("Sign up failed: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func signOut() {
        authenticationService.signOut()
        currentUser = nil
        isAuthenticated = false
        isPremiumUser = false
        subscriptionStatus = .none
        subscriptionExpiryDate = nil
        
        analyticsService.track(event: "user_signed_out")
        logger.info("User signed out")
    }
    
    // MARK: - Subscription Actions
    
    func purchaseSubscription(_ product: Product) async {
        isLoading = true
        subscriptionError = nil
        
        do {
            try await subscriptionManager.purchaseSubscription(product)
            isPremiumUser = true
            subscriptionStatus = .active
            subscriptionExpiryDate = Date().addingTimeInterval(365 * 24 * 60 * 60) // 1 year
            
            analyticsService.track(event: "subscription_purchased", parameters: [
                "product_id": product.id,
                "price": product.price
            ])
            
            logger.info("Subscription purchased: \(product.id)")
        } catch {
            subscriptionError = error.localizedDescription
            logger.error("Subscription purchase failed: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func restorePurchases() async {
        isLoading = true
        subscriptionError = nil
        
        do {
            try await subscriptionManager.restorePurchases()
            isPremiumUser = subscriptionManager.isPremiumUser
            subscriptionStatus = subscriptionManager.subscriptionStatus
            
            analyticsService.track(event: "purchases_restored")
            logger.info("Purchases restored")
        } catch {
            subscriptionError = error.localizedDescription
            logger.error("Restore purchases failed: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    // MARK: - Processing Actions
    
    func startProcessing(image: UIImage, quality: HybridProcessingService.QualityLevel) {
        isProcessing = true
        processingProgress = 0.0
        processingError = nil
        processingResults = []
        
        analyticsService.track(event: "processing_started", parameters: [
            "quality": "\(quality)",
            "image_size": "\(image.size.width)x\(image.size.height)"
        ])
        
        logger.info("Processing started with quality: \(quality)")
    }
    
    func updateProcessingProgress(_ progress: Double) {
        processingProgress = progress
        logger.debug("Processing progress: \(Int(progress * 100))%")
    }
    
    func completeProcessing(results: [ProcessingResult]) {
        isProcessing = false
        processingProgress = 1.0
        processingResults = results
        
        analyticsService.track(event: "processing_completed", parameters: [
            "result_count": results.count
        ])
        
        logger.info("Processing completed with \(results.count) results")
    }
    
    func failProcessing(error: Error) {
        isProcessing = false
        processingProgress = 0.0
        processingError = error.localizedDescription
        
        analyticsService.track(event: "processing_failed", parameters: [
            "error": error.localizedDescription
        ])
        
        logger.error("Processing failed: \(error.localizedDescription)")
    }
    
    // MARK: - Navigation Actions
    
    func navigateTo(_ view: AppView) {
        currentView = view
        
        analyticsService.track(event: "navigation", parameters: [
            "destination": "\(view)"
        ])
        
        logger.info("Navigated to: \(view)")
    }
    
    func setSelectedImage(_ image: UIImage?) {
        selectedImage = image
        logger.info("Selected image updated")
    }
    
    func setGeneratedVideoURL(_ url: URL?) {
        generatedVideoURL = url
        logger.info("Generated video URL updated")
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        authenticationError = nil
        subscriptionError = nil
        processingError = nil
        appError = nil
    }
    
    func setAppError(_ error: String) {
        appError = error
        logger.error("App error set: \(error)")
    }
    
    // MARK: - State Queries
    
    var canProcessImage: Bool {
        return isAuthenticated && !isProcessing
    }
    
    var canAccessPremiumFeatures: Bool {
        return isAuthenticated && isPremiumUser
    }
    
    var shouldShowPaywall: Bool {
        return isAuthenticated && !isPremiumUser
    }
    
    var isInProcessingFlow: Bool {
        return currentView == .photoUpload || 
               currentView == .qualitySelection || 
               currentView == .processing || 
               currentView == .results
    }
    
    // MARK: - State Reset
    
    func resetProcessingState() {
        isProcessing = false
        processingProgress = 0.0
        processingError = nil
        processingResults = []
        selectedImage = nil
        generatedVideoURL = nil
        
        logger.info("Processing state reset")
    }
    
    func resetAppState() {
        isAuthenticated = false
        currentUser = nil
        isPremiumUser = false
        subscriptionStatus = .none
        subscriptionExpiryDate = nil
        currentView = .splash
        resetProcessingState()
        clearError()
        
        logger.info("App state reset")
    }
}

// MARK: - Supporting Types

enum AppView: String, CaseIterable {
    case splash = "splash"
    case authentication = "authentication"
    case home = "home"
    case photoUpload = "photoUpload"
    case qualitySelection = "qualitySelection"
    case realTimePreview = "realTimePreview"
    case processing = "processing"
    case results = "results"
    case paywall = "paywall"
    case share = "share"
    case settings = "settings"
}

enum SubscriptionStatus: String, CaseIterable {
    case none = "none"
    case active = "active"
    case expired = "expired"
    case cancelled = "cancelled"
    case pending = "pending"
}

struct ProcessingResult: Identifiable {
    let id = UUID()
    let image: UIImage
    let style: String
    let isPremium: Bool
    let processingTime: TimeInterval
    let quality: ImageQuality
}

// MARK: - State Manager Extensions

extension UnifiedAppStateManager {
    
    // MARK: - Subscription Helpers
    
    func isSubscriptionActive() -> Bool {
        guard let expiryDate = subscriptionExpiryDate else { return false }
        return Date() < expiryDate && subscriptionStatus == .active
    }
    
    func getSubscriptionDaysRemaining() -> Int {
        guard let expiryDate = subscriptionExpiryDate else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: expiryDate).day ?? 0
        return max(0, days)
    }
    
    // MARK: - Processing Helpers
    
    func getProcessingTimeEstimate(for quality: HybridProcessingService.QualityLevel) -> TimeInterval {
        switch quality {
        case .preview: return 2.0
        case .standard: return 5.0
        case .premium: return 15.0
        case .ultra: return 30.0
        }
    }
    
    // MARK: - Analytics Helpers
    
    func trackUserJourney() {
        let journey = [
            "is_authenticated": isAuthenticated,
            "is_premium": isPremiumUser,
            "current_view": currentView.rawValue,
            "has_selected_image": selectedImage != nil,
            "is_processing": isProcessing
        ]
        
        analyticsService.track(event: "user_journey_snapshot", parameters: journey)
    }
}

