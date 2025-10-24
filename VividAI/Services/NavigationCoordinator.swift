import SwiftUI
import Combine
import UIKit
import Foundation
import os.log
import CoreFoundation
import CoreGraphics

class NavigationCoordinator: ObservableObject {
    @Published var currentView: AppView = .splash
    @Published var selectedImage: UIImage?
    @Published var processingResults: [HeadshotResult] = []
    @Published var generatedVideoURL: URL?
    @Published var errorMessage: String?
    @Published var showingError = false
    
    // Navigation stack for back navigation
    private var navigationStack: [AppView] = []
    
    enum AppView {
        case splash
        case home
        case photoUpload
        case processing
        case results
        case paywall
        case share
        case settings
    }
    
    // MARK: - Navigation Methods
    
    func navigateTo(_ view: AppView) {
        navigationStack.append(currentView)
        currentView = view
    }
    
    func navigateBack() {
        guard !navigationStack.isEmpty else { return }
        currentView = navigationStack.removeLast()
    }
    
    func navigateToRoot() {
        navigationStack.removeAll()
        currentView = .home
    }
    
    // MARK: - Specific Navigation Flows
    
    func startPhotoUpload() {
        navigateTo(.photoUpload)
    }
    
    func startProcessing(with image: UIImage) {
        selectedImage = image
        navigateTo(.processing)
    }
    
    func showResults(with results: [HeadshotResult]) {
        processingResults = results
        navigateTo(.results)
    }
    
    func showPaywall() {
        navigateTo(.paywall)
    }
    
    func showShare(with videoURL: URL) {
        generatedVideoURL = videoURL
        navigateTo(.share)
    }
    
    func showSettings() {
        navigateTo(.settings)
    }
    
    // MARK: - Error Handling
    
    func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
    
    func clearError() {
        errorMessage = nil
        showingError = false
    }
    
    // MARK: - Data Management
    
    func clearProcessingData() {
        selectedImage = nil
        processingResults = []
        generatedVideoURL = nil
    }
    
    func resetToHome() {
        clearProcessingData()
        navigateToRoot()
    }
}

// MARK: - Navigation Extensions

extension NavigationCoordinator {
    var canGoBack: Bool {
        return !navigationStack.isEmpty
    }
    
    var currentViewTitle: String {
        switch currentView {
        case .splash:
            return "VividAI"
        case .home:
            return "Home"
        case .photoUpload:
            return "Upload Photo"
        case .processing:
            return "Processing"
        case .results:
            return "Your Headshots"
        case .paywall:
            return "Go Pro"
        case .share:
            return "Share"
        case .settings:
            return "Settings"
        }
    }
    
    var shouldShowBackButton: Bool {
        switch currentView {
        case .splash, .home:
            return false
        default:
            return canGoBack
        }
    }
}
