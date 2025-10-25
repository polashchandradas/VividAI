import Foundation
import FirebaseAppCheck
import FirebaseAuth
import os.log

// MARK: - Firebase App Check Service

class FirebaseAppCheckService: ObservableObject {
    static let shared = FirebaseAppCheckService()
    
    private let logger = Logger(subsystem: "VividAI", category: "AppCheck")
    private var appCheck: AppCheck?
    
    // MARK: - Initialization
    
    private init() {
        setupAppCheck()
    }
    
    // MARK: - Setup
    
    private func setupAppCheck() {
        // App Check is now managed by FirebaseConfigurationService
        // This service just provides access to the configured App Check instance
        appCheck = ServiceContainer.shared.firebaseConfigurationService.getAppCheck()
        
        logger.info("Firebase App Check service initialized")
    }
    
    // MARK: - Token Management
    
    func getAppCheckToken(forceRefresh: Bool = false) async throws -> String {
        guard let appCheck = appCheck else {
            throw AppCheckError.notInitialized
        }
        
        do {
            let token = try await appCheck.token(forcingRefresh: forceRefresh)
            logger.info("App Check token obtained successfully")
            return token.token
        } catch {
            logger.error("Failed to get App Check token: \(error.localizedDescription)")
            throw AppCheckError.tokenGenerationFailed
        }
    }
    
    // MARK: - Token Validation
    
    func validateAppCheckToken(_ token: String) async throws -> Bool {
        // This would typically be done on the server side
        // For client-side, we just verify the token exists and is not empty
        return !token.isEmpty && token.count > 10
    }
    
    // MARK: - Debug Methods
    
    #if DEBUG
    func generateDebugToken() -> String {
        // Generate a debug token for testing
        let debugToken = "debug-token-\(UUID().uuidString)"
        logger.info("Generated debug token: \(debugToken)")
        return debugToken
    }
    #endif
}

// MARK: - App Check Error

enum AppCheckError: Error, LocalizedError {
    case notInitialized
    case tokenGenerationFailed
    case validationFailed
    
    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "App Check not initialized"
        case .tokenGenerationFailed:
            return "Failed to generate App Check token"
        case .validationFailed:
            return "App Check token validation failed"
        }
    }
}
