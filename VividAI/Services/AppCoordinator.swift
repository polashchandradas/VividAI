import SwiftUI
import Combine
import StoreKit
import UIKit
import os.log
import CoreFoundation
import CoreGraphics
import CoreData

class AppCoordinator: ObservableObject {
    @Published var navigationCoordinator = NavigationCoordinator()
    @Published var subscriptionManager = SubscriptionManager()
    @Published var analyticsService = AnalyticsService()
    @Published var aiHeadshotService = AIHeadshotService.shared
    @Published var backgroundRemovalService = BackgroundRemovalService.shared
    @Published var photoEnhancementService = PhotoEnhancementService.shared
    @Published var videoGenerationService = VideoGenerationService.shared
    @Published var watermarkService = WatermarkService.shared
    @Published var referralService = ReferralService.shared
    @Published var configurationService = ConfigurationService.shared
    @Published var errorHandlingService = ErrorHandlingService.shared
    @Published var securityService = SecurityService.shared
    @Published var loggingService = LoggingService.shared
    
    // Processing state
    @Published var isProcessing = false
    @Published var processingStep: String = ""
    @Published var processingProgress: Double = 0.0
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
        loadInitialData()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // Monitor AI processing
        aiHeadshotService.$isProcessing
            .assign(to: \.isProcessing, on: self)
            .store(in: &cancellables)
        
        aiHeadshotService.$processingProgress
            .assign(to: \.processingProgress, on: self)
            .store(in: &cancellables)
    }
    
    private func loadInitialData() {
        // Load CoreML models
        backgroundRemovalService.loadModel()
        photoEnhancementService.loadModel()
        
        // Track app launch
        analyticsService.track(event: "app_launched")
    }
    
    // MARK: - Photo Processing Flow
    
    func processPhoto(_ image: UIImage) {
        guard !isProcessing else { return }
        
        loggingService.logInfo("Photo processing started", context: [
            "image_width": image.size.width,
            "image_height": image.size.height
        ])
        
        // Security validation
        let validationResult = securityService.validateImage(image)
        if !validationResult.isValid {
            loggingService.logError(AppError.imageProcessingError("Image validation failed: \(validationResult.issues.joined(separator: ", "))"), context: [
                "validation_issues": validationResult.issues
            ])
            errorHandlingService.handleError(
                AppError.imageProcessingError("Image validation failed: \(validationResult.issues.joined(separator: ", "))"),
                context: "Image validation"
            )
            return
        }
        
        analyticsService.track(event: "photo_processing_started", parameters: [
            "image_width": image.size.width,
            "image_height": image.size.height
        ])
        
        // Start processing flow
        navigationCoordinator.startProcessing(with: image)
        
        // Process the image
        processImageWithAI(image)
    }
    
    private func processImageWithAI(_ image: UIImage) {
        isProcessing = true
        processingStep = "Analyzing your photo..."
        processingProgress = 0.0
        
        // Step 1: Face Detection
        detectFaces(in: image) { [weak self] faceCount in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.processingStep = "Face detected: \(faceCount) faces found"
                self.processingProgress = 0.2
            }
            
            // Step 2: Generate AI Headshots
            self.generateAIHeadshots(from: image)
        }
    }
    
    private func detectFaces(in image: UIImage, completion: @escaping (Int) -> Void) {
        backgroundRemovalService.detectFaces(in: image) { observations in
            completion(observations.count)
        }
    }
    
    private func generateAIHeadshots(from image: UIImage) {
        DispatchQueue.main.async {
            self.processingStep = "Generating AI headshots..."
            self.processingProgress = 0.4
        }
        
        aiHeadshotService.generateHeadshots(from: image) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let headshots):
                    self.processingStep = "Processing complete!"
                    self.processingProgress = 1.0
                    
                    // Show results
                    self.navigationCoordinator.showResults(with: headshots)
                    
                    self.analyticsService.track(event: "headshots_generated", parameters: [
                        "count": headshots.count,
                        "premium_count": headshots.filter { $0.isPremium }.count
                    ])
                    
                case .failure(let error):
                    self.handleProcessingError(error)
                }
            }
        }
    }
    
    // MARK: - Video Generation
    
    func generateTransformationVideo(from originalImage: UIImage, to enhancedImage: UIImage) {
        analyticsService.track(event: "video_generation_started")
        
        videoGenerationService.generateTransformationVideo(
            from: originalImage,
            to: enhancedImage
        ) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let videoURL):
                    self.navigationCoordinator.showShare(with: videoURL)
                    self.analyticsService.track(event: "video_generated")
                    
                case .failure(let error):
                    self.handleProcessingError(error)
                }
            }
        }
    }
    
    // MARK: - Background Removal
    
    func removeBackground(from image: UIImage, completion: @escaping (Result<UIImage, Error>) -> Void) {
        analyticsService.track(event: "background_removal_started")
        
        backgroundRemovalService.removeBackground(from: image) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.analyticsService.track(event: "background_removed")
                case .failure(let error):
                    self.analyticsService.trackError(error, context: "background_removal")
                }
                
                completion(result)
            }
        }
    }
    
    // MARK: - Photo Enhancement
    
    func enhancePhoto(_ image: UIImage, completion: @escaping (Result<UIImage, Error>) -> Void) {
        analyticsService.track(event: "photo_enhancement_started")
        
        photoEnhancementService.enhancePhoto(image) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.analyticsService.track(event: "photo_enhanced")
                case .failure(let error):
                    self.analyticsService.trackError(error, context: "photo_enhancement")
                }
                
                completion(result)
            }
        }
    }
    
    // MARK: - Error Handling
    
    private func handleProcessingError(_ error: Error) {
        isProcessing = false
        processingStep = "Processing failed"
        
        let errorMessage = error.localizedDescription
        navigationCoordinator.showError(errorMessage)
        
        analyticsService.trackError(error, context: "photo_processing")
    }
    
    // MARK: - Subscription Management
    
    func handleSubscriptionAction(_ action: SubscriptionAction) {
        switch action {
        case .startFreeTrial(let plan):
            subscriptionManager.startFreeTrial(plan: plan)
            analyticsService.track(event: "free_trial_started", parameters: ["plan": plan.rawValue])
            
        case .purchaseSubscription(let product):
            Task {
                do {
                    _ = try await subscriptionManager.purchase(product: product)
                    analyticsService.track(event: "subscription_purchased", parameters: ["product_id": product.id])
                } catch {
                    handleProcessingError(error)
                }
            }
            
        case .restorePurchases:
            subscriptionManager.restorePurchases()
            analyticsService.track(event: "purchases_restored")
        }
    }
    
    // MARK: - Error Handling
    
    private func handleProcessingError(_ error: Error) {
        isProcessing = false
        processingStep = "Processing failed"
        processingProgress = 0.0
        
        // Log the error
        loggingService.logError(error, context: [
            "processing_step": processingStep,
            "processing_progress": processingProgress
        ])
        
        // Handle different types of errors
        if let appError = error as? AppError {
            errorHandlingService.handleError(appError, context: "Photo processing")
        } else {
            errorHandlingService.handleImageProcessingError(error, context: "Photo processing")
        }
        
        // Navigate back to upload screen
        navigationCoordinator.navigateBack()
        
        analyticsService.track(event: "processing_error", parameters: [
            "error": error.localizedDescription
        ])
    }
    
    // MARK: - App Lifecycle
    
    func handleAppBecameActive() {
        loggingService.logAppLaunch()
        analyticsService.track(event: "app_became_active")
    }
    
    func handleAppWillResignActive() {
        loggingService.logAppTermination()
        analyticsService.track(event: "app_will_resign_active")
    }
}

// MARK: - Subscription Actions

enum SubscriptionAction {
    case startFreeTrial(SubscriptionManager.SubscriptionPlan)
    case purchaseSubscription(Product)
    case restorePurchases
}
