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
    let backgroundRemovalService = BackgroundRemovalService()
    let photoEnhancementService = PhotoEnhancementService()
    let aiHeadshotService = AIHeadshotService()
    let videoGenerationService = VideoGenerationService()
    let watermarkService = WatermarkService()
    let referralService = ReferralService()
    let securityService = SecurityService()
    let loggingService = LoggingService()
    let errorHandlingService = ErrorHandlingService()
    
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
        logger.info("Processing image")
        
        startProcessing()
        
        // Process image through pipeline
        Task {
            do {
                // Step 1: Background removal
                updateProcessingStep("Removing background...", progress: 0.2)
                let processedImage = try await backgroundRemovalService.removeBackground(from: image)
                
                // Step 2: Photo enhancement
                updateProcessingStep("Enhancing photo...", progress: 0.6)
                let enhancedImage = try await photoEnhancementService.enhancePhoto(processedImage)
                
                // Step 3: AI headshot generation
                updateProcessingStep("Generating AI headshot...", progress: 0.8)
                let headshotResult = try await aiHeadshotService.generateHeadshot(from: enhancedImage)
                
                // Step 4: Final processing
                updateProcessingStep("Finalizing...", progress: 1.0)
                
                DispatchQueue.main.async {
                    self.completeProcessing()
                }
                
            } catch {
                DispatchQueue.main.async {
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

