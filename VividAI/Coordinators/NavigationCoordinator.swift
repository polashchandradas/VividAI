import SwiftUI
import Combine
import os.log

// MARK: - Navigation Coordinator

class NavigationCoordinator: ObservableObject {
    @Published var currentView: AppView = .splash
    @Published var navigationStack: [AppView] = []
    
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
}

// MARK: - App View Enum

enum AppView: String, CaseIterable {
    case splash = "splash"
    case home = "home"
    case photoUpload = "photoUpload"
    case processing = "processing"
    case results = "results"
    case paywall = "paywall"
    case share = "share"
    case settings = "settings"
    
    var title: String {
        switch self {
        case .splash:
            return "Welcome"
        case .home:
            return "Home"
        case .photoUpload:
            return "Upload Photo"
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
