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
        
        startProcessing()
        
        // Use hybrid processing service for intelligent routing
        hybridProcessingService.processImage(image, quality: .standard) { [weak self] result in
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

