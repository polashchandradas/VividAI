import SwiftUI
import Combine
import os.log

// MARK: - Navigation Coordinator

class NavigationCoordinator: ObservableObject {
    @Published var currentView: AppView = .splash
    @Published var navigationStack: [AppView] = []
    
    // Data storage for navigation flow
    @Published var selectedImage: UIImage?
    @Published var processingResults: [HeadshotResult] = []
    @Published var generatedVideoURL: URL?
    
    private let logger = Logger(subsystem: "VividAI", category: "Navigation")
    private let analyticsService: AnalyticsService
    private let services = ServiceContainer.shared
    
    init() {
        self.analyticsService = services.analyticsService
    }
    
    // MARK: - Navigation Methods
    
    func navigateTo(_ view: AppView) {
        logger.info("Navigating to: \(view.rawValue)")
        
        DispatchQueue.main.async {
            self.currentView = view
            self.navigationStack.append(view)
        }
    }
    
    func navigateBack() {
        guard !navigationStack.isEmpty else { return }
        
        let _ = navigationStack.popLast()
        currentView = navigationStack.last ?? .home
        
        logger.info("Navigated back to: \(currentView.rawValue)")
    }
    
    func navigateToRoot() {
        logger.info("Navigating to root")
        
        DispatchQueue.main.async {
            self.currentView = .home
            self.navigationStack = [.home]
        }
    }
    
    func resetToSplash() {
        logger.info("Resetting to splash screen")
        
        DispatchQueue.main.async {
            self.currentView = .splash
            self.navigationStack = []
        }
    }
    
    // MARK: - Specific Navigation Methods
    
    func startPhotoUpload() {
        selectedImage = nil
        processingResults = []
        generatedVideoURL = nil
        navigateTo(.photoUpload)
        analyticsService.track(event: "photo_upload_started")
    }
    
    func startProcessing() {
        navigateTo(.processing)
        analyticsService.track(event: "processing_started")
    }
    
    func showResults() {
        navigateTo(.results)
        analyticsService.track(event: "results_shown")
    }
    
    func showPaywall() {
        navigateTo(.paywall)
        analyticsService.track(event: "paywall_shown")
    }
    
    func showShare() {
        navigateTo(.share)
        analyticsService.track(event: "share_shown")
    }
    
    func showSettings() {
        navigateTo(.settings)
        analyticsService.track(event: "settings_shown")
    }
    
    func goHome() {
        navigateToRoot()
        analyticsService.track(event: "home_navigated")
    }
    
    func showRealTimePreview() {
        navigateTo(.realTimePreview)
        analyticsService.track(event: "realtime_preview_shown")
    }
    
    func showQualitySelection() {
        navigateTo(.qualitySelection)
        analyticsService.track(event: "quality_selection_shown")
    }
    
    // MARK: - Data Flow Methods
    
    func startProcessing(with image: UIImage) {
        selectedImage = image
        navigateTo(.processing)
        analyticsService.track(event: "processing_started_with_image", parameters: [
            "image_width": image.size.width,
            "image_height": image.size.height
        ])
    }
    
    func showResults(with results: [HeadshotResult]) {
        processingResults = results
        navigateTo(.results)
        analyticsService.track(event: "results_shown_with_data", parameters: [
            "result_count": results.count
        ])
    }
    
    func showShare(with videoURL: URL) {
        generatedVideoURL = videoURL
        navigateTo(.share)
        analyticsService.track(event: "share_shown_with_video")
    }
    
    func showError(_ message: String) {
        // Handle error display
        logger.error("Navigation error: \(message)")
        analyticsService.track(event: "navigation_error", parameters: [
            "error_message": message
        ])
        navigateBack()
    }
}

// MARK: - App View Enum

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
    
    var title: String {
        switch self {
        case .splash:
            return "Welcome"
        case .authentication:
            return "Sign In"
        case .home:
            return "Home"
        case .photoUpload:
            return "Upload Photo"
        case .qualitySelection:
            return "Choose Quality"
        case .realTimePreview:
            return "Real-Time Preview"
        case .processing:
            return "Processing"
        case .results:
            return "Results"
        case .paywall:
            return "Upgrade"
        case .share:
            return "Share"
        case .settings:
            return "Settings"
        }
    }
}

