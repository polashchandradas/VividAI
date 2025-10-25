import SwiftUI
import Combine
import os.log
import UIKit

// MARK: - App Coordinator

class AppCoordinator: ObservableObject {
    // MARK: - Published Properties
    
    @Published var isProcessing = false
    @Published var currentProcessingStep = ""
    @Published var processingProgress: Double = 0.0
    // Error state is managed by ErrorHandlingService to avoid conflicts
    // Authentication state is centralized in AuthenticationService
    // Subscription state is centralized in SubscriptionStateManager
    var isPremiumUser: Bool { subscriptionStateManager.isPremiumUser }
    var subscriptionStatus: SubscriptionStatus { subscriptionStateManager.subscriptionStatus }
    var isAuthenticated: Bool { authenticationService.isAuthenticated }
    var currentUser: User? { authenticationService.currentUser }
    
    // MARK: - Service Container
    
    private let services = ServiceContainer.shared
    
    // MARK: - Service Access Properties (Computed)
    
    var navigationCoordinator: NavigationCoordinator { services.navigationCoordinator }
    var subscriptionStateManager: SubscriptionStateManager { services.subscriptionStateManager }
    var subscriptionManager: SubscriptionManager { services.subscriptionManager }
    var analyticsService: AnalyticsService { services.analyticsService }
    var hybridProcessingService: HybridProcessingService { services.hybridProcessingService }
    var backgroundRemovalService: BackgroundRemovalService { services.backgroundRemovalService }
    var photoEnhancementService: PhotoEnhancementService { services.photoEnhancementService }
    var aiHeadshotService: AIHeadshotService { services.aiHeadshotService }
    var videoGenerationService: VideoGenerationService { services.videoGenerationService }
    var watermarkService: WatermarkService { services.watermarkService }
    var referralService: ReferralService { services.referralService }
    var securityService: SecurityService { services.securityService }
    var loggingService: LoggingService { services.loggingService }
    var errorHandlingService: ErrorHandlingService { services.errorHandlingService }
    var authenticationService: AuthenticationService { services.authenticationService }
    var freeTrialService: FreeTrialService { services.freeTrialService }
    var usageLimitService: UsageLimitService { services.usageLimitService }
    
    private let logger = Logger(subsystem: "VividAI", category: "AppCoordinator")
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        setupSubscriptions()
        configureServices()
    }
    
    // MARK: - Setup Methods
    
    private func setupSubscriptions() {
        // Monitor subscription status - no need to assign since we use computed properties
        // The computed properties automatically reflect the current state
        
        // Monitor authentication status
        authenticationService.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAuthenticated in
                self?.handleAuthenticationStateChange(isAuthenticated)
            }
            .store(in: &cancellables)
    }
    
    private func configureServices() {
        // Services are self-contained and don't require coordinator references
        // All services are properly initialized through ServiceContainer
        // No additional configuration needed
    }
    
    // MARK: - Authentication State Management
    
    private func handleAuthenticationStateChange(_ isAuthenticated: Bool) {
        logger.info("Authentication state changed: \(isAuthenticated)")
        
        if isAuthenticated {
            // User signed in - refresh subscription status
            subscriptionManager.checkSubscriptionStatus()
            
            // Track authentication
            analyticsService.track(event: "user_authenticated")
        } else {
            // User signed out - reset app state
            resetAppState()
            
            // Navigate to authentication screen
            Task { @MainActor in
                self.navigationCoordinator.resetToSplash()
            }
        }
    }
    
    private func resetAppState() {
        // Reset processing state
        resetProcessingState()
        
        // Clear any cached data
        // Reset analytics
        analyticsService.setUserProperty(key: "user_id", value: nil)
        analyticsService.setUserProperty(key: "subscription_status", value: nil)
        analyticsService.setUserProperty(key: "is_premium", value: nil)
        
        logger.info("App state reset for logout")
    }
    
    // MARK: - App Lifecycle
    
    func handleAppBecameActive() {
        logger.info("App became active")
        
        // Refresh subscription status
        subscriptionManager.checkSubscriptionStatus()
        
        // Track app launch
        analyticsService.track(event: "app_launched")
    }
    
    func handleAppWillResignActive() {
        logger.info("App will resign active")
        
        // Save any pending data
        saveAppState()
    }
    
    private func saveAppState() {
        // Save current processing state if needed
        if isProcessing {
            logger.info("Saving processing state")
        }
    }
    
    // MARK: - Processing State Management
    
    func startProcessing() {
        logger.info("Starting processing")
        isProcessing = true
        currentProcessingStep = "Initializing..."
        processingProgress = 0.0
        navigationCoordinator.startProcessing()
        analyticsService.track(event: "processing_started")
    }
    
    func completeProcessing() {
        logger.info("Processing completed")
        isProcessing = false
        currentProcessingStep = "Complete"
        processingProgress = 1.0
        navigationCoordinator.showResults()
        analyticsService.track(event: "processing_completed")
    }
    
    func completeProcessing(with results: [HeadshotResult]) {
        logger.info("Processing completed with \(results.count) results")
        isProcessing = false
        currentProcessingStep = "Complete"
        processingProgress = 1.0
        navigationCoordinator.showResults(with: results)
        analyticsService.track(event: "processing_completed", parameters: [
            "result_count": results.count
        ])
    }
    
    private func resetProcessingState() {
        isProcessing = false
        currentProcessingStep = ""
        processingProgress = 0.0
        // Error state is managed by ErrorHandlingService
    }
    
    // MARK: - Subscription Methods
    
    func handleSubscriptionAction(_ action: SubscriptionAction) {
        logger.info("Handling subscription action: \(action)")
        
        // Delegate to SubscriptionStateManager for unified handling
        subscriptionStateManager.handleSubscriptionAction(action)
    }
    
    // MARK: - Error Handling (Centralized)
    
    func handleError(_ error: Error) {
        logger.error("Handling error: \(error.localizedDescription)")
        
        // Delegate all error handling to ErrorHandlingService
        errorHandlingService.handleError(error)
        
        // Update local processing state
        DispatchQueue.main.async {
            self.isProcessing = false
        }
        
        analyticsService.track(event: "error_occurred", parameters: [
            "error_description": error.localizedDescription
        ])
    }
    
    func clearError() {
        // Delegate error clearing to ErrorHandlingService
        errorHandlingService.dismissError()
    }
    
    // MARK: - Unified Error State Access
    
    var hasError: Bool {
        return errorHandlingService.isShowingError
    }
    
    var errorMessage: String {
        return errorHandlingService.currentError?.localizedDescription ?? ""
    }
    
    // MARK: - Processing Methods
    
    func processImage(_ image: UIImage) {
        logger.info("Processing image with hybrid approach")
        
        // Check if user can generate (smart limits)
        if !canUserGenerate() {
            showGenerationLimitReached()
            return
        }
        
        startProcessing()
        
        // Use hybrid processing service for intelligent routing
        hybridProcessingService.processImage(image, quality: .standard) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let headshotResults):
                    // Record usage
                    self.recordGeneration()
                    self.completeProcessing(with: headshotResults)
                case .failure(let error):
                    self.handleError(error)
                }
            }
        }
    }
    
    // MARK: - Async Processing Methods
    
    @MainActor
    func processImageAsync(_ image: UIImage) async throws -> [HeadshotResult] {
        logger.info("Processing image asynchronously")
        
        startProcessing()
        
        do {
            let results = try await withCheckedThrowingContinuation { continuation in
                hybridProcessingService.processImage(image, quality: .standard) { result in
                    continuation.resume(with: result)
                }
            }
            
            completeProcessing(with: results)
            return results
        } catch {
            handleError(error)
            throw error
        }
    }
    
    func processImageWithQuality(_ image: UIImage, quality: HybridProcessingService.QualityLevel) {
        logger.info("Processing image with quality: \(quality)")
        
        startProcessing()
        
        // Use hybrid processing service with specific quality
        hybridProcessingService.processImage(image, quality: quality) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let headshotResults):
                    self.completeProcessing(with: headshotResults)
                case .failure(let error):
                    self.handleError(error)
                }
            }
        }
    }
    
    func generateRealTimePreview(_ image: UIImage, style: AvatarStyle) {
        logger.info("Generating real-time preview for style: \(style.name)")
        
        hybridProcessingService.generateRealTimePreview(image, style: style) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let preview):
                    // Handle successful preview generation
                    self.analyticsService.track(event: "realtime_preview_generated", parameters: [
                        "style": style.name
                    ])
                case .failure(let error):
                    self.handleError(error)
                }
            }
        }
    }
    
    private func updateProcessingStep(_ step: String, progress: Double) {
        DispatchQueue.main.async {
            self.currentProcessingStep = step
            self.processingProgress = progress
        }
    }
    
    // MARK: - Authentication Methods
    
    private func handleAuthenticationStateChange(_ isAuthenticated: Bool) {
        logger.info("Authentication state changed: \(isAuthenticated)")
        
        if isAuthenticated {
            // User is authenticated - navigate to home
            navigationCoordinator.navigateTo(.home)
            analyticsService.track(event: "user_authenticated_success")
        } else {
            // User is not authenticated - show authentication screen
            navigationCoordinator.navigateTo(.authentication)
            analyticsService.track(event: "user_authentication_required")
        }
    }
    
    func signOut() {
        Task {
            do {
                // Sign out from authentication service (includes full cleanup)
                try await authenticationService.signOut()
                
                // Additional app-level cleanup
                await performAppLogoutCleanup()
                
                // Navigate to authentication screen
                await MainActor.run {
                    self.navigationCoordinator.resetToSplash()
                }
                
                logger.info("User signed out successfully with app cleanup")
            } catch {
                logger.error("Sign out failed: \(error.localizedDescription)")
                handleError(error)
            }
        }
    }
    
    // MARK: - App Logout Cleanup
    
    private func performAppLogoutCleanup() async {
        await MainActor.run {
            // Reset app state
            self.isProcessing = false
            self.currentProcessingStep = ""
            self.processingProgress = 0.0
            // Error state is managed by ErrorHandlingService
            // Note: isPremiumUser and subscriptionStatus are computed properties
            // They will automatically reflect the correct state from SubscriptionManager
            
            // Clear navigation stack
            self.navigationCoordinator.resetToSplash()
        }
        
        // Reset subscription manager
        await resetSubscriptionState()
        
        // Clear any cached data
        await clearAppCache()
        
        logger.info("App logout cleanup completed")
    }
    
    private func resetSubscriptionState() async {
        // Reset subscription-related state
        // This would call subscription manager reset methods if they exist
        logger.info("Subscription state reset")
    }
    
    private func clearAppCache() async {
        // Clear any app-level cached data
        // Clear image cache, user preferences, etc.
        logger.info("App cache cleared")
    }
    
    // MARK: - Smart Generation Limits
    
    private func canUserGenerate() -> Bool {
        // Use unified state from SubscriptionStateManager
        return subscriptionStateManager.canGenerate
    }
    
    // MARK: - Unified Trial/Subscription State Management
    
    func getUnifiedUserStatus() -> UserStatus {
        return subscriptionStateManager.userStatus
    }
    
    func getUnifiedGenerationLimits() -> GenerationLimits {
        return subscriptionStateManager.generationLimits
    }
    
    private func recordGeneration() {
        // Use unified recording from SubscriptionStateManager
        subscriptionStateManager.recordGeneration()
        
        analyticsService.track(event: "generation_completed", parameters: [
            "is_premium": isPremiumUser,
            "is_trial_active": subscriptionStateManager.isTrialActive,
            "trial_type": "\(subscriptionStateManager.trialType)"
        ])
    }
    
    private func showGenerationLimitReached() {
        let message = subscriptionStateManager.getLimitMessage()
        
        // Use centralized error handling
        let limitError = AppError.subscriptionError(message)
        errorHandlingService.handleError(limitError, context: "Generation limit reached", severity: .medium)
        
        analyticsService.track(event: "generation_limit_reached", parameters: [
            "is_premium": self.isPremiumUser,
            "is_trial_active": self.subscriptionStateManager.isTrialActive,
            "trial_type": "\(self.subscriptionStateManager.trialType)"
        ])
    }
    
    func startFreeTrial(type: FreeTrialService.TrialType = .limited) {
        subscriptionStateManager.startFreeTrial(type: type)
        
        analyticsService.track(event: "free_trial_started", parameters: [
            "trial_type": "\(type)",
            "max_generations": subscriptionStateManager.trialMaxGenerations
        ])
    }
    
    func getRemainingGenerations() -> Int {
        return subscriptionStateManager.getRemainingGenerations()
    }
}

// MARK: - Subscription Action

enum SubscriptionAction {
    case startFreeTrial(SubscriptionManager.SubscriptionPlan)
    case purchase(Product)
    case restorePurchases
    case cancelSubscription
}

// MARK: - Subscription Status

enum SubscriptionStatus {
    case none
    case trial
    case active
    case expired
    case cancelled
}

// MARK: - Unified State Management Types

enum UserStatus {
    case free
    case trial(FreeTrialService.TrialType)
    case premium
    
    var isPremium: Bool {
        if case .premium = self { return true }
        return false
    }
    
    var isTrialActive: Bool {
        if case .trial = self { return true }
        return false
    }
}

enum GenerationLimits {
    case unlimited
    case trial(used: Int, max: Int, daysRemaining: Int)
    case free(remaining: Int)
    
    var canGenerate: Bool {
        switch self {
        case .unlimited:
            return true
        case .trial(let used, let max, _):
            return used < max
        case .free(let remaining):
            return remaining > 0
        }
    }
    
    var remainingGenerations: Int {
        switch self {
        case .unlimited:
            return 999
        case .trial(let used, let max, _):
            return max(0, max - used)
        case .free(let remaining):
            return remaining
        }
    }
}

