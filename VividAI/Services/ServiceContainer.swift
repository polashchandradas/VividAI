import Foundation
import SwiftUI

/// Centralized service container to manage all app services
/// This ensures single instances and proper dependency management
class ServiceContainer: ObservableObject {
    nonisolated static let shared = ServiceContainer()
    
    // MARK: - Core Services
    // Unified State Management (Single Source of Truth)
    lazy var unifiedAppStateManager: UnifiedAppStateManager = {
        return MainActor.assumeIsolated {
            UnifiedAppStateManager.shared
        }
    }()
    
    lazy var navigationCoordinator: NavigationCoordinator = {
        NavigationCoordinator()
    }()
    
    lazy var subscriptionStateManager: SubscriptionStateManager = {
        SubscriptionStateManager.shared
    }()
    
    lazy var subscriptionManager: SubscriptionManager = {
        SubscriptionManager.shared
    }()
    
    lazy var analyticsService: AnalyticsService = {
        AnalyticsService.shared
    }()
    
    lazy var firebaseConfigurationService: FirebaseConfigurationService = {
        FirebaseConfigurationService.shared
    }()
    
    lazy var authenticationService: AuthenticationService = {
        AuthenticationService.shared
    }()
    
    // MARK: - AI Processing Services
    lazy var hybridProcessingService: HybridProcessingService = {
        HybridProcessingService.shared
    }()
    
    lazy var backgroundRemovalService: BackgroundRemovalService = {
        BackgroundRemovalService.shared
    }()
    
    lazy var photoEnhancementService: PhotoEnhancementService = {
        PhotoEnhancementService.shared
    }()
    
    lazy var realTimeGenerationService: RealTimeGenerationService = {
        RealTimeGenerationService.shared
    }()
    
    lazy var aiHeadshotService: AIHeadshotService = {
        AIHeadshotService.shared
    }()
    
    lazy var videoGenerationService: VideoGenerationService = {
        VideoGenerationService.shared
    }()
    
    // MARK: - Utility Services
    lazy var watermarkService: WatermarkService = {
        WatermarkService.shared
    }()
    
    lazy var referralService: ReferralService = {
        ReferralService.shared
    }()
    
    lazy var securityService: SecurityService = {
        SecurityService.shared
    }()
    
    lazy var loggingService: LoggingService = {
        LoggingService.shared
    }()
    
    lazy var errorHandlingService: ErrorHandlingService = {
        ErrorHandlingService.shared
    }()
    
    lazy var freeTrialService: FreeTrialService = {
        FreeTrialService.shared
    }()
    
    lazy var usageLimitService: UsageLimitService = {
        UsageLimitService.shared
    }()
    
    lazy var secureStorageService: SecureStorageService = {
        SecureStorageService.shared
    }()
    
    lazy var serverValidationService: ServerValidationService = {
        ServerValidationService.shared
    }()
    
    lazy var firebaseValidationService: FirebaseValidationService = {
        FirebaseValidationService.shared
    }()
    
    lazy var firebaseAppCheckService: FirebaseAppCheckService = {
        FirebaseAppCheckService.shared
    }()
    
    lazy var configurationService: ConfigurationService = {
        ConfigurationService.shared
    }()
    
    lazy var photoValidationService: PhotoValidationService = {
        PhotoValidationService.shared
    }()
    
    // AppCoordinator must be initialized on MainActor
    lazy var appCoordinator: AppCoordinator = {
        return MainActor.assumeIsolated {
            AppCoordinator()
        }
    }()
    
    // MARK: - Initialization
    private init() {
        // Initialize services in proper order to avoid circular dependencies
        setupServices()
    }
    
    private func setupServices() {
        // Initialize unified state manager first (single source of truth)
        _ = unifiedAppStateManager
        
        // Initialize services in dependency order (no dependencies first)
        _ = configurationService
        _ = loggingService
        _ = analyticsService
        _ = errorHandlingService
        _ = secureStorageService
        _ = securityService
        _ = firebaseAppCheckService
        _ = firebaseValidationService
        _ = serverValidationService
        
        // Initialize services that depend on the above
        _ = freeTrialService
        _ = usageLimitService
        _ = referralService
        _ = subscriptionManager
        _ = subscriptionStateManager
        _ = authenticationService
        
        // Initialize AI processing services
        _ = backgroundRemovalService
        _ = photoEnhancementService
        _ = realTimeGenerationService
        _ = aiHeadshotService
        _ = videoGenerationService
        _ = hybridProcessingService
        _ = watermarkService
        _ = photoValidationService
        
        // Initialize navigation last
        _ = navigationCoordinator
        _ = appCoordinator
        
        // Configure service dependencies after all services are initialized
        configureServiceDependencies()
    }
    
    private func configureServiceDependencies() {
        // Set up service-to-service dependencies here
        // This ensures proper initialization order and avoids circular dependencies
        
        // Configure AuthenticationService to use SubscriptionManager callback
        authenticationService.setupSubscriptionStateListener()
        
        // Configure other service dependencies as needed
        // All services are now initialized, so it's safe to set up dependencies
    }
    
    // MARK: - Service Access Methods
    func getService<T>(_ type: T.Type) -> T? {
        switch type {
        case is UnifiedAppStateManager.Type:
            return unifiedAppStateManager as? T
        case is NavigationCoordinator.Type:
            return navigationCoordinator as? T
        case is SubscriptionStateManager.Type:
            return subscriptionStateManager as? T
        case is SubscriptionManager.Type:
            return subscriptionManager as? T
        case is AnalyticsService.Type:
            return analyticsService as? T
        case is AuthenticationService.Type:
            return authenticationService as? T
        case is HybridProcessingService.Type:
            return hybridProcessingService as? T
        case is BackgroundRemovalService.Type:
            return backgroundRemovalService as? T
        case is PhotoEnhancementService.Type:
            return photoEnhancementService as? T
        case is RealTimeGenerationService.Type:
            return realTimeGenerationService as? T
        case is AIHeadshotService.Type:
            return aiHeadshotService as? T
        case is VideoGenerationService.Type:
            return videoGenerationService as? T
        case is WatermarkService.Type:
            return watermarkService as? T
        case is ReferralService.Type:
            return referralService as? T
        case is SecurityService.Type:
            return securityService as? T
        case is LoggingService.Type:
            return loggingService as? T
        case is ErrorHandlingService.Type:
            return errorHandlingService as? T
        case is FreeTrialService.Type:
            return freeTrialService as? T
        case is UsageLimitService.Type:
            return usageLimitService as? T
        case is SecureStorageService.Type:
            return secureStorageService as? T
        case is ServerValidationService.Type:
            return serverValidationService as? T
        case is FirebaseValidationService.Type:
            return firebaseValidationService as? T
        case is FirebaseAppCheckService.Type:
            return firebaseAppCheckService as? T
        case is ConfigurationService.Type:
            return configurationService as? T
        case is PhotoValidationService.Type:
            return photoValidationService as? T
        case is AppCoordinator.Type:
            // AppCoordinator is @MainActor - access it properly
            return MainActor.assumeIsolated {
                self.appCoordinator as? T
            }
        default:
            return nil
        }
    }
    
    // MARK: - Cleanup
    func cleanup() {
        // Clean up any resources when app is terminated
        loggingService.logInfo("ServiceContainer: Cleaning up services")
    }
}
