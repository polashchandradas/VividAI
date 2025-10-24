import Foundation

class ConfigurationService: ObservableObject {
    static let shared = ConfigurationService()
    
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
    
    func validateConfiguration() -> ValidationResult {
        var issues: [String] = []
        
        // Validate Replicate API key
        let replicateValidation = SecurityService.shared.validateAPIKey(replicateAPIKey)
        if !replicateValidation.isValid {
            issues.append(contentsOf: replicateValidation.issues.map { "Replicate API: \($0)" })
        }
        
        // Validate Firebase API key
        let firebaseValidation = SecurityService.shared.validateAPIKey(firebaseAPIKey)
        if !firebaseValidation.isValid {
            issues.append(contentsOf: firebaseValidation.issues.map { "Firebase API: \($0)" })
        }
        
        // Validate URLs
        let replicateURLValidation = SecurityService.shared.validateURL(replicateBaseURL)
        if !replicateURLValidation.isValid {
            issues.append(contentsOf: replicateURLValidation.issues.map { "Replicate URL: \($0)" })
        }
        
        return ValidationResult(
            isValid: issues.isEmpty,
            issues: issues
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
