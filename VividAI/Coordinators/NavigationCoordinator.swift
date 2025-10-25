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
    }
    
    func startProcessing() {
        navigateTo(.processing)
    }
    
    func showResults() {
        navigateTo(.results)
    }
    
    func showPaywall() {
        navigateTo(.paywall)
    }
    
    func showShare() {
        navigateTo(.share)
    }
    
    func showSettings() {
        navigateTo(.settings)
    }
    
    func goHome() {
        navigateToRoot()
    }
    
    func showRealTimePreview() {
        navigateTo(.realTimePreview)
    }
    
    func showQualitySelection() {
        navigateTo(.qualitySelection)
    }
    
    // MARK: - Data Flow Methods
    
    func startProcessing(with image: UIImage) {
        selectedImage = image
        navigateTo(.processing)
    }
    
    func showResults(with results: [HeadshotResult]) {
        processingResults = results
        navigateTo(.results)
    }
    
    func showShare(with videoURL: URL) {
        generatedVideoURL = videoURL
        navigateTo(.share)
    }
    
    func showError(_ message: String) {
        // Handle error display
        logger.error("Navigation error: \(message)")
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

