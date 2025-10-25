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
    @Published var hasError = false
    @Published var errorMessage = ""
    @Published var isPremiumUser = false
    @Published var subscriptionStatus: SubscriptionStatus = .none
    
    // MARK: - Services
    
    let navigationCoordinator = NavigationCoordinator()
    let subscriptionManager = SubscriptionManager()
    let analyticsService = AnalyticsService()
    let hybridProcessingService = HybridProcessingService.shared
    let backgroundRemovalService = BackgroundRemovalService()
    let photoEnhancementService = PhotoEnhancementService()
    let aiHeadshotService = AIHeadshotService()
    let videoGenerationService = VideoGenerationService()
    let watermarkService = WatermarkService()
    let referralService = ReferralService()
    let securityService = SecurityService()
    let loggingService = LoggingService()
    let errorHandlingService = ErrorHandlingService()
    let authenticationService = AuthenticationService.shared
    let freeTrialService = FreeTrialService.shared
    let usageLimitService = UsageLimitService.shared
    
    private let logger = Logger(subsystem: "VividAI", category: "AppCoordinator")
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        setupSubscriptions()
        configureServices()
    }
    
    // MARK: - Setup Methods
    
    private func setupSubscriptions() {
        // Monitor subscription status
        subscriptionManager.$isPremiumUser
            .receive(on: DispatchQueue.main)
            .assign(to: \.isPremiumUser, on: self)
            .store(in: &cancellables)
        
        subscriptionManager.$subscriptionStatus
            .receive(on: DispatchQueue.main)
            .assign(to: \.subscriptionStatus, on: self)
            .store(in: &cancellables)
        
        // Monitor authentication status
        authenticationService.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAuthenticated in
                self?.handleAuthenticationStateChange(isAuthenticated)
            }
            .store(in: &cancellables)
    }
    
    private func configureServices() {
        // Configure services with coordinator references
        backgroundRemovalService.coordinator = self
        photoEnhancementService.coordinator = self
        aiHeadshotService.coordinator = self
        videoGenerationService.coordinator = self
        watermarkService.coordinator = self
        referralService.coordinator = self
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
    
    // MARK: - Navigation Methods
    
    func startPhotoUpload() {
        logger.info("Starting photo upload flow")
        navigationCoordinator.startPhotoUpload()
        analyticsService.track(event: "photo_upload_started")
    }
    
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
    
    func showPaywall() {
        logger.info("Showing paywall")
        navigationCoordinator.showPaywall()
        analyticsService.track(event: "paywall_shown")
    }
    
    func showShare() {
        logger.info("Showing share screen")
        navigationCoordinator.showShare()
        analyticsService.track(event: "share_shown")
    }
    
    func showSettings() {
        logger.info("Showing settings")
        navigationCoordinator.showSettings()
        analyticsService.track(event: "settings_shown")
    }
    
    func goHome() {
        logger.info("Going home")
        navigationCoordinator.goHome()
        resetProcessingState()
    }
    
    private func resetProcessingState() {
        isProcessing = false
        currentProcessingStep = ""
        processingProgress = 0.0
        hasError = false
        errorMessage = ""
    }
    
    // MARK: - Subscription Methods
    
    func handleSubscriptionAction(_ action: SubscriptionAction) {
        logger.info("Handling subscription action: \(action)")
        
        switch action {
        case .startFreeTrial(let plan):
            subscriptionManager.startFreeTrial(plan: plan)
        case .purchase(let product):
            subscriptionManager.purchase(product: product)
        case .restorePurchases:
            subscriptionManager.restorePurchases()
        case .cancelSubscription:
            subscriptionManager.cancelSubscription()
        }
    }
    
    // MARK: - Error Handling
    
    func handleError(_ error: Error) {
        logger.error("Handling error: \(error.localizedDescription)")
        
        DispatchQueue.main.async {
            self.hasError = true
            self.errorMessage = error.localizedDescription
            self.isProcessing = false
        }
        
        errorHandlingService.handleError(error)
        analyticsService.track(event: "error_occurred", parameters: [
            "error_description": error.localizedDescription
        ])
    }
    
    func clearError() {
        hasError = false
        errorMessage = ""
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
                    self.navigationCoordinator.navigateTo(.authentication)
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
            self.hasError = false
            self.errorMessage = ""
            self.isPremiumUser = false
            self.subscriptionStatus = .none
            
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
        // Premium users can always generate
        if isPremiumUser {
            return true
        }
        
        // Check free trial limits
        if freeTrialService.isTrialActive {
            return freeTrialService.canUserGenerate()
        }
        
        // Check usage limits for free users
        return usageLimitService.canGenerate(
            isPremium: isPremiumUser,
            isTrialActive: freeTrialService.isTrialActive
        )
    }
    
    private func recordGeneration() {
        // Record in usage limit service
        usageLimitService.recordGeneration()
        
        // Record in free trial service if active
        if freeTrialService.isTrialActive {
            freeTrialService.recordGeneration()
        }
        
        analyticsService.track(event: "generation_completed", parameters: [
            "is_premium": isPremiumUser,
            "is_trial_active": freeTrialService.isTrialActive,
            "trial_type": "\(freeTrialService.trialType)"
        ])
    }
    
    private func showGenerationLimitReached() {
        let message = getLimitMessage()
        
        DispatchQueue.main.async {
            self.hasError = true
            self.errorMessage = message
        }
        
        analyticsService.track(event: "generation_limit_reached", parameters: [
            "is_premium": self.isPremiumUser,
            "is_trial_active": self.freeTrialService.isTrialActive,
            "trial_type": "\(self.freeTrialService.trialType)"
        ])
    }
    
    private func getLimitMessage() -> String {
        if isPremiumUser {
            return "You have unlimited generations with Pro"
        }
        
        if freeTrialService.isTrialActive {
            return getTrialLimitMessage()
        }
        
        return getFreeUserLimitMessage()
    }
    
    private func getTrialLimitMessage() -> String {
        switch freeTrialService.trialType {
        case .limited:
            return "Trial limit reached (\(freeTrialService.generationsUsed)/\(freeTrialService.maxGenerations) generations used)"
        case .unlimited:
            return "Trial expired (\(freeTrialService.trialDaysRemaining) days remaining)"
        case .freemium:
            return "Daily limit reached (1 generation per day)"
        case .none:
            return "No active trial"
        }
    }
    
    private func getFreeUserLimitMessage() -> String {
        return usageLimitService.getLimitMessage(
            isPremium: isPremiumUser,
            isTrialActive: freeTrialService.isTrialActive
        )
    }
    
    func startFreeTrial(type: FreeTrialService.TrialType = .limited) {
        freeTrialService.startFreeTrial(type: type)
        
        analyticsService.track(event: "free_trial_started", parameters: [
            "trial_type": "\(type)",
            "max_generations": freeTrialService.maxGenerations
        ])
    }
    
    func getRemainingGenerations() -> Int {
        if isPremiumUser {
            return 999 // Unlimited
        }
        
        if freeTrialService.isTrialActive {
            return freeTrialService.maxGenerations - freeTrialService.generationsUsed
        }
        
        return usageLimitService.getRemainingGenerations(
            isPremium: isPremiumUser,
            isTrialActive: freeTrialService.isTrialActive
        )
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

