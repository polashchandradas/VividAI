import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseAnalytics
import FirebaseAppCheck
import FirebaseFunctions
import os.log

// MARK: - Firebase Configuration Service

class FirebaseConfigurationService: ObservableObject {
    static let shared = FirebaseConfigurationService()
    
    // MARK: - Published State
    @Published var isFirebaseConfigured = false
    @Published var configurationError: String?
    @Published var isInitialized = false
    
    // MARK: - Firebase Services (Centralized Access)
    private(set) var auth: Auth!
    private(set) var firestore: Firestore!
    private(set) var analytics: Analytics.Type!
    private(set) var appCheck: AppCheck!
    private(set) var functions: Functions!
    
    private let logger = Logger(subsystem: "VividAI", category: "FirebaseConfiguration")
    
    // MARK: - Initialization
    
    private init() {
        // Firebase configuration is handled in VividAIApp.swift
        // This service provides centralized access to Firebase services
    }
    
    // MARK: - Configuration
    
    func configureFirebase() async throws {
        logger.info("Configuring Firebase services")
        
        do {
            // Verify Firebase is configured
            guard FirebaseApp.app() != nil else {
                throw FirebaseConfigurationError.notConfigured
            }
            
            // Initialize Firebase services
            auth = Auth.auth()
            firestore = Firestore.firestore()
            analytics = Analytics.self
            appCheck = AppCheck.appCheck()
            functions = Functions.functions()
            
            // Configure Firestore settings
            configureFirestore()
            
            // Configure Analytics
            configureAnalytics()
            
            await MainActor.run {
                self.isFirebaseConfigured = true
                self.isInitialized = true
                self.configurationError = nil
            }
            
            logger.info("Firebase services configured successfully")
            
        } catch {
            await MainActor.run {
                self.isFirebaseConfigured = false
                self.isInitialized = false
                self.configurationError = error.localizedDescription
            }
            
            logger.error("Firebase configuration failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    private func configureFirestore() {
        // Configure Firestore settings with new cacheSettings API
        let settings = FirestoreSettings()
        // Convert Int64 to NSNumber as required by PersistentCacheSettings API
        let cacheSize = NSNumber(value: FirestoreCacheSizeUnlimited)
        settings.cacheSettings = PersistentCacheSettings(sizeBytes: cacheSize)
        firestore.settings = settings
        
        logger.info("Firestore configured with persistence enabled")
    }
    
    private func configureAnalytics() {
        // Configure Analytics
        analytics.setAnalyticsCollectionEnabled(true)
        
        logger.info("Analytics configured and enabled")
    }
    
    // MARK: - Service Access
    
    func getAuth() -> Auth {
        guard let auth = auth else {
            fatalError("Firebase Auth not configured. Call configureFirebase() first.")
        }
        return auth
    }
    
    func getFirestore() -> Firestore {
        guard let firestore = firestore else {
            fatalError("Firebase Firestore not configured. Call configureFirebase() first.")
        }
        return firestore
    }
    
    func getAnalytics() -> Analytics.Type {
        guard let analytics = analytics else {
            fatalError("Firebase Analytics not configured. Call configureFirebase() first.")
        }
        return analytics
    }
    
    func getAppCheck() -> AppCheck {
        guard let appCheck = appCheck else {
            fatalError("Firebase App Check not configured. Call configureFirebase() first.")
        }
        return appCheck
    }
    
    func getFunctions() -> Functions {
        guard let functions = functions else {
            fatalError("Firebase Functions not configured. Call configureFirebase() first.")
        }
        return functions
    }
    
    // MARK: - Validation
    
    func validateFirebaseConfiguration() -> Bool {
        return isFirebaseConfigured && 
               auth != nil && 
               firestore != nil && 
               analytics != nil && 
               appCheck != nil && 
               functions != nil
    }
    
    // MARK: - Error Handling
    
    func handleFirebaseError(_ error: Error) {
        logger.error("Firebase error: \(error.localizedDescription)")
        
        DispatchQueue.main.async {
            self.configurationError = error.localizedDescription
        }
    }
}

// MARK: - Firebase Configuration Error

enum FirebaseConfigurationError: Error, LocalizedError {
    case notConfigured
    case initializationFailed
    case serviceNotAvailable
    case configurationInvalid
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Firebase is not configured. Please ensure FirebaseApp.configure() is called."
        case .initializationFailed:
            return "Failed to initialize Firebase services."
        case .serviceNotAvailable:
            return "Firebase service is not available."
        case .configurationInvalid:
            return "Firebase configuration is invalid."
        }
    }
}



