import Foundation
import SwiftUI
import UIKit
import os.log
import CoreFoundation
import CoreGraphics
import CoreData

class ConfigurationService: ObservableObject {
    static let shared = ConfigurationService()
    
    // MARK: - Centralized Configuration State
    @Published var isConfigurationLoaded = false
    @Published var configurationStatus: ConfigurationStatus = .notConfigured
    @Published var lastConfigurationError: String?
    
    // MARK: - API Keys
    let replicateAPIKey: String
    let firebaseAPIKey: String
    let googleAppID: String
    
    // MARK: - API Endpoints
    let replicateBaseURL = "https://api.replicate.com/v1"
    let firebaseProjectID: String
    let firebaseStorageBucket: String
    
    // MARK: - App Configuration
    let appVersion = "1.0.0"
    let bundleIdentifier = "com.vividai.app"
    
    private init() {
        // Load configuration from Info.plist or environment
        self.replicateAPIKey = Self.loadAPIKey(for: "REPLICATE_API_KEY")
        self.firebaseAPIKey = Self.loadAPIKey(for: "FIREBASE_API_KEY")
        self.googleAppID = Self.loadAPIKey(for: "GOOGLE_APP_ID")
        self.firebaseProjectID = Self.loadAPIKey(for: "FIREBASE_PROJECT_ID")
        self.firebaseStorageBucket = Self.loadAPIKey(for: "FIREBASE_STORAGE_BUCKET")
        
        // Set centralized configuration state
        self.configurationStatus = getConfigurationStatus()
        self.isConfigurationLoaded = true
        
        // Log configuration status
        if !isFullyConfigured {
            self.lastConfigurationError = getConfigurationErrorMessage()
        }
    }
    
    private static func loadAPIKey(for key: String) -> String {
        // First try to load from environment variables (for CI/CD)
        if let envValue = ProcessInfo.processInfo.environment[key], !envValue.isEmpty {
            return envValue
        }
        
        // Then try to load from Info.plist
        if let plistValue = Bundle.main.object(forInfoDictionaryKey: key) as? String, !plistValue.isEmpty {
            return plistValue
        }
        
        // Finally, try to load from GoogleService-Info.plist
        if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path),
           let value = plist[key] as? String, !value.isEmpty {
            return value
        }
        
        // Return placeholder if not found
        return "YOUR_\(key)"
    }
    
    // MARK: - Validation
    var isReplicateConfigured: Bool {
        return !replicateAPIKey.isEmpty && replicateAPIKey != "YOUR_REPLICATE_API_KEY"
    }
    
    var isFirebaseConfigured: Bool {
        return !firebaseAPIKey.isEmpty && 
               firebaseAPIKey != "YOUR_FIREBASE_API_KEY" &&
               !googleAppID.isEmpty &&
               googleAppID != "YOUR_GOOGLE_APP_ID"
    }
    
    var isFullyConfigured: Bool {
        return isReplicateConfigured && isFirebaseConfigured
    }
    
    // MARK: - Configuration Status
    func getConfigurationStatus() -> ConfigurationStatus {
        if isFullyConfigured {
            return .fullyConfigured
        } else if isFirebaseConfigured && !isReplicateConfigured {
            return .missingReplicate
        } else if isReplicateConfigured && !isFirebaseConfigured {
            return .missingFirebase
        } else {
            return .notConfigured
        }
    }
    
    // MARK: - Security Validation
    
    private var securityService: SecurityService {
        return ServiceContainer.shared.securityService
    }
    
    func validateConfiguration() -> ValidationResult {
        var issues: [String] = []
        
        // Validate Replicate API key
        let replicateValidation = securityService.validateAPIKey(replicateAPIKey)
        if !replicateValidation.isValid {
            issues.append(contentsOf: replicateValidation.issues.map { "Replicate API: \($0)" })
        }
        
        // Validate Firebase API key
        let firebaseValidation = securityService.validateAPIKey(firebaseAPIKey)
        if !firebaseValidation.isValid {
            issues.append(contentsOf: firebaseValidation.issues.map { "Firebase API: \($0)" })
        }
        
        // Validate URLs
        let replicateURLValidation = securityService.validateURL(replicateBaseURL)
        if !replicateURLValidation.isValid {
            issues.append(contentsOf: replicateURLValidation.issues.map { "Replicate URL: \($0)" })
        }
        
        return ValidationResult(
            isValid: issues.isEmpty,
            issues: issues
        )
    }
    
    // MARK: - Centralized Configuration Management
    
    func refreshConfiguration() {
        // Refresh configuration state
        self.configurationStatus = getConfigurationStatus()
        self.lastConfigurationError = getConfigurationErrorMessage()
        
        // Notify observers of configuration changes
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    func getConfigurationSummary() -> ConfigurationSummary {
        return ConfigurationSummary(
            status: configurationStatus,
            isLoaded: isConfigurationLoaded,
            lastError: lastConfigurationError,
            replicateConfigured: isReplicateConfigured,
            firebaseConfigured: isFirebaseConfigured,
            fullyConfigured: isFullyConfigured
        )
    }
    
    // MARK: - Error Messages
    func getConfigurationErrorMessage() -> String? {
        switch getConfigurationStatus() {
        case .fullyConfigured:
            return nil
        case .missingReplicate:
            return "Replicate API key is not configured. Please add REPLICATE_API_KEY to your configuration."
        case .missingFirebase:
            return "Firebase configuration is incomplete. Please update GoogleService-Info.plist with your actual Firebase credentials."
        case .notConfigured:
            return "API configuration is incomplete. Please configure both Firebase and Replicate API keys."
        }
    }
}

// MARK: - Configuration Status Enum
enum ConfigurationStatus {
    case fullyConfigured
    case missingReplicate
    case missingFirebase
    case notConfigured
    
    var description: String {
        switch self {
        case .fullyConfigured:
            return "All APIs configured"
        case .missingReplicate:
            return "Missing Replicate API key"
        case .missingFirebase:
            return "Missing Firebase configuration"
        case .notConfigured:
            return "No APIs configured"
        }
    }
}

// MARK: - Configuration Summary
struct ConfigurationSummary {
    let status: ConfigurationStatus
    let isLoaded: Bool
    let lastError: String?
    let replicateConfigured: Bool
    let firebaseConfigured: Bool
    let fullyConfigured: Bool
    
    var hasErrors: Bool {
        return lastError != nil
    }
    
    var isReady: Bool {
        return isLoaded && fullyConfigured && !hasErrors
    }
}
