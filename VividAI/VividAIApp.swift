import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseAnalytics
import FirebaseAppCheck
import FirebaseFunctions
import UIKit
import Combine
import os.log
import StoreKit
import CoreFoundation
import CoreGraphics
import CoreData
import GoogleSignIn

// MARK: - Navigation Coordinator (moved to Coordinators/NavigationCoordinator.swift)

// MARK: - App View Enum

// AppView enum moved to Coordinators/NavigationCoordinator.swift

// MARK: - App Coordinator (moved to Coordinators/AppCoordinator.swift)

// MARK: - Supporting Types

// SubscriptionAction and SubscriptionStatus enums moved to Coordinators/AppCoordinator.swift

// MARK: - Product Model (moved to Models/Product.swift)

// MARK: - Main App View

struct MainAppView: View {
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    @EnvironmentObject var appCoordinator: AppCoordinator
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            Group {
                switch navigationCoordinator.currentView {
                case .splash:
                    SplashScreenView()
                case .authentication:
                    AuthenticationView()
                case .home:
                    HomeView()
                case .photoUpload:
                    PhotoUploadView()
                case .realTimePreview:
                    RealTimePreviewView()
                case .processing:
                    ProcessingView()
                case .results:
                    ResultsView()
                case .paywall:
                    PaywallView()
                case .share:
                    ShareView()
                case .settings:
                    SettingsView()
                }
            }
            .animation(.easeInOut(duration: 0.3), value: navigationCoordinator.currentView)
        }
        .onAppear {
            appCoordinator.handleAppBecameActive()
        }
    }
}

@main
struct VividAIApp: App {
    @StateObject private var serviceContainer = ServiceContainer.shared
    @StateObject private var appCoordinator = AppCoordinator()
    @State private var isFirebaseConfigured = false
    @State private var configurationError: String?
    
    init() {
        configureFirebase()
    }
    
    var body: some Scene {
        WindowGroup {
            if let error = configurationError {
                ConfigurationErrorView(error: error)
            } else {
                          MainAppView()
                              .environmentObject(appCoordinator)
                              .environmentObject(serviceContainer.navigationCoordinator)
                              .environmentObject(serviceContainer.subscriptionStateManager)
                              .environmentObject(serviceContainer.analyticsService)
                              .environmentObject(serviceContainer.authenticationService)
                       .environmentObject(serviceContainer.realTimeGenerationService)
                       .environmentObject(serviceContainer.hybridProcessingService)
                       .environmentObject(serviceContainer.backgroundRemovalService)
                       .environmentObject(serviceContainer.photoEnhancementService)
                       .environmentObject(serviceContainer.aiHeadshotService)
                       .environmentObject(serviceContainer.videoGenerationService)
                       .environmentObject(serviceContainer.watermarkService)
                       .environmentObject(serviceContainer.referralService)
                       .environmentObject(serviceContainer.securityService)
                       .environmentObject(serviceContainer.loggingService)
                       .environmentObject(serviceContainer.errorHandlingService)
                       .environmentObject(serviceContainer.secureStorageService)
                       .environmentObject(serviceContainer.serverValidationService)
                       .environmentObject(serviceContainer.firebaseValidationService)
                       .environmentObject(serviceContainer.firebaseAppCheckService)
                       .environmentObject(serviceContainer.firebaseConfigurationService)
                       .environmentObject(serviceContainer.configurationService)
                       .errorHandling()
                    .onAppear {
                        appCoordinator.handleAppBecameActive()
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                        appCoordinator.handleAppWillResignActive()
                    }
            }
        }
    }
    
    private func configureFirebase() {
        // Use centralized configuration service
        let configService = ServiceContainer.shared.configurationService
        
        // Check if Firebase is properly configured using centralized service
        guard configService.isFirebaseConfigured else {
            configurationError = configService.getConfigurationErrorMessage()
            return
        }
        
        // Configure Firebase using centralized configuration
        FirebaseApp.configure()
        
        // Configure Google Sign-In using centralized configuration
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: configService.googleAppID)
        
        // Initialize Firebase App Check
        initializeAppCheck()
        
        // Configure Firebase services using centralized service
        Task {
            do {
                try await ServiceContainer.shared.firebaseConfigurationService.configureFirebase()
                await MainActor.run {
                    isFirebaseConfigured = true
                }
            } catch {
                await MainActor.run {
                    configurationError = error.localizedDescription
                }
            }
        }
    }
    
    private func initializeAppCheck() {
        // Configure App Check with DeviceCheck for iOS
        #if DEBUG
        // Use debug provider for development
        let debugProvider = AppCheckDebugProvider()
        AppCheck.setAppCheckProviderFactory(debugProvider)
        #else
        // Use DeviceCheck for production
        let deviceCheckProvider = DeviceCheckProvider()
        AppCheck.setAppCheckProviderFactory(deviceCheckProvider)
        #endif
        
        // App Check is now initialized by FirebaseConfigurationService
    }
}

// MARK: - Configuration Error View
struct ConfigurationErrorView: View {
    let error: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("Configuration Error")
                .font(.title)
                .fontWeight(.bold)
            
            Text(error)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Retry") {
                // Restart app to retry configuration
                exit(0)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

