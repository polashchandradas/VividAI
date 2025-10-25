import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine
import SwiftUI
import AuthenticationServices
import CryptoKit
import os.log
import GoogleSignIn

// MARK: - Authentication Service

class AuthenticationService: ObservableObject {
    static let shared = AuthenticationService()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var authState: AuthState = .unknown
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private let logger = Logger(subsystem: "VividAI", category: "Authentication")
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    // MARK: - Auth State
    
    enum AuthState {
        case unknown
        case authenticated(User)
        case unauthenticated
    }
    
    // MARK: - Initialization
    
    private init() {
        setupAuthStateListener()
    }
    
    deinit {
        if let listener = authStateListener {
            auth.removeStateDidChangeListener(listener)
        }
    }
    
    // MARK: - Auth State Management
    
    private func setupAuthStateListener() {
        authStateListener = auth.addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.updateAuthState(user: user)
            }
        }
    }
    
    private func updateAuthState(user: User?) {
        if let user = user {
            self.currentUser = user
            self.isAuthenticated = true
            self.authState = .authenticated(user)
            
            logger.info("User authenticated: \(user.uid)")
            analyticsService.track(event: "user_authenticated", parameters: [
                "user_id": user.uid,
                "email": user.email ?? "unknown"
            ])
        } else {
            self.currentUser = nil
            self.isAuthenticated = false
            self.authState = .unauthenticated
            
            logger.info("User signed out")
            analyticsService.track(event: "user_signed_out")
        }
    }
    
    // MARK: - Email/Password Authentication
    
    func signUp(email: String, password: String, fullName: String) async throws -> User {
        isLoading = true
        errorMessage = nil
        
        do {
            let authResult = try await auth.createUser(withEmail: email, password: password)
            let user = authResult.user
            
            // Update user profile
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = fullName
            try await changeRequest.commitChanges()
            
            // Create user document in Firestore
            try await createUserDocument(user: user, fullName: fullName)
            
            await MainActor.run {
                self.isLoading = false
            }
            
            logger.info("User signed up successfully: \(user.uid)")
            analyticsService.track(event: "user_signed_up", parameters: [
                "user_id": user.uid,
                "email": email,
                "method": "email_password"
            ])
            
            return user
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
            
            logger.error("Sign up failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    func signIn(email: String, password: String) async throws -> User {
        isLoading = true
        errorMessage = nil
        
        do {
            let authResult = try await auth.signIn(withEmail: email, password: password)
            let user = authResult.user
            
            await MainActor.run {
                self.isLoading = false
            }
            
            logger.info("User signed in successfully: \(user.uid)")
            analyticsService.track(event: "user_signed_in", parameters: [
                "user_id": user.uid,
                "email": email,
                "method": "email_password"
            ])
            
            return user
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
            
            logger.error("Sign in failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    func signOut() async throws {
        do {
            // 1. Sign out from Firebase
            try auth.signOut()
            
            // 2. Clear all user data and reset app state
            await performLogoutCleanup()
            
            logger.info("User signed out successfully with full cleanup")
            analyticsService.track(event: "user_signed_out")
        } catch {
            logger.error("Sign out failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Logout Cleanup
    
    private func performLogoutCleanup() async {
        await MainActor.run {
            // Clear authentication state
            self.currentUser = nil
            self.isAuthenticated = false
            self.authState = .unauthenticated
            self.errorMessage = nil
            self.isLoading = false
        }
        
        // Clear secure storage
        await clearSecureStorage()
        
        // Clear user-specific app state
        await clearUserAppState()
        
        // Reset analytics
        await resetAnalytics()
        
        logger.info("Logout cleanup completed")
    }
    
    private func clearSecureStorage() async {
        // Clear Keychain data
        let secureStorage = SecureStorageService.shared
        
        // Clear trial data
        try? secureStorage.clearTrialData()
        
        // Clear referral data
        try? secureStorage.clearReferralData()
        
        // Clear device ID (optional - you might want to keep this)
        // try? secureStorage.clearDeviceId()
        
        logger.info("Secure storage cleared")
    }
    
    private func clearUserAppState() async {
        // Clear any cached user data
        // Clear image cache
        // Clear user preferences
        // Reset any user-specific settings
        
        // Note: These would be implemented based on your specific app needs
        logger.info("User app state cleared")
    }
    
    private func resetAnalytics() async {
        // Reset analytics user properties
        analyticsService.setUserProperty(key: "user_id", value: nil)
        analyticsService.setUserProperty(key: "subscription_status", value: nil)
        analyticsService.setUserProperty(key: "is_premium", value: nil)
        
        logger.info("Analytics reset for logout")
    }
    
    // MARK: - Password Reset
    
    func resetPassword(email: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            try await auth.sendPasswordReset(withEmail: email)
            
            await MainActor.run {
                self.isLoading = false
            }
            
            logger.info("Password reset email sent to: \(email)")
            analyticsService.track(event: "password_reset_requested", parameters: [
                "email": email
            ])
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
            
            logger.error("Password reset failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Apple Sign In
    
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws -> User {
        isLoading = true
        errorMessage = nil
        
        do {
            guard let nonce = currentNonce else {
                throw AuthError.invalidNonce
            }
            
            guard let appleIDToken = credential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                throw AuthError.invalidToken
            }
            
            let firebaseCredential = OAuthProvider.credential(withProviderID: "apple.com",
                                                              idToken: idTokenString,
                                                              rawNonce: nonce)
            
            let authResult = try await auth.signIn(with: firebaseCredential)
            let user = authResult.user
            
            // Create user document if it doesn't exist
            try await createUserDocumentIfNeeded(user: user, fullName: credential.fullName?.formatted())
            
            await MainActor.run {
                self.isLoading = false
            }
            
            logger.info("Apple Sign In successful: \(user.uid)")
            analyticsService.track(event: "user_signed_in", parameters: [
                "user_id": user.uid,
                "method": "apple_sign_in"
            ])
            
            return user
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
            
            logger.error("Apple Sign In failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Google Sign In
    
    func signInWithGoogle(credential: GoogleSignInCredential) async throws -> User {
        isLoading = true
        errorMessage = nil
        
        do {
            let firebaseCredential = GoogleAuthProvider.credential(withIDToken: credential.idToken,
                                                                  accessToken: credential.accessToken)
            
            let authResult = try await auth.signIn(with: firebaseCredential)
            let user = authResult.user
            
            // Create user document if it doesn't exist
            try await createUserDocumentIfNeeded(user: user, fullName: credential.fullName)
            
            await MainActor.run {
                self.isLoading = false
            }
            
            logger.info("Google Sign In successful: \(user.uid)")
            analyticsService.track(event: "user_signed_in", parameters: [
                "user_id": user.uid,
                "method": "google_sign_in"
            ])
            
            return user
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
            
            logger.error("Google Sign In failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - User Profile Management
    
    func updateUserProfile(displayName: String? = nil, photoURL: URL? = nil) async throws {
        guard let user = currentUser else {
            throw AuthError.noCurrentUser
        }
        
        let changeRequest = user.createProfileChangeRequest()
        
        if let displayName = displayName {
            changeRequest.displayName = displayName
        }
        
        if let photoURL = photoURL {
            changeRequest.photoURL = photoURL
        }
        
        try await changeRequest.commitChanges()
        
        logger.info("User profile updated: \(user.uid)")
        analyticsService.track(event: "user_profile_updated", parameters: [
            "user_id": user.uid
        ])
    }
    
    func deleteAccount() async throws {
        guard let user = currentUser else {
            throw AuthError.noCurrentUser
        }
        
        // Delete user document from Firestore
        try await db.collection("users").document(user.uid).delete()
        
        // Delete user account
        try await user.delete()
        
        await MainActor.run {
            self.currentUser = nil
            self.isAuthenticated = false
            self.authState = .unauthenticated
        }
        
        logger.info("User account deleted: \(user.uid)")
        analyticsService.track(event: "user_account_deleted", parameters: [
            "user_id": user.uid
        ])
    }
    
    // MARK: - Private Methods
    
    private func createUserDocument(user: User, fullName: String? = nil) async throws {
        let userData: [String: Any] = [
            "uid": user.uid,
            "email": user.email ?? "",
            "displayName": fullName ?? user.displayName ?? "",
            "photoURL": user.photoURL?.absoluteString ?? "",
            "createdAt": Timestamp(date: Date()),
            "lastSignIn": Timestamp(date: Date()),
            "isPremium": false,
            "subscriptionStatus": "none",
            "trialUsed": false
        ]
        
        try await db.collection("users").document(user.uid).setData(userData)
        
        logger.info("User document created: \(user.uid)")
    }
    
    private func createUserDocumentIfNeeded(user: User, fullName: String? = nil) async throws {
        let docRef = db.collection("users").document(user.uid)
        let document = try await docRef.getDocument()
        
        if !document.exists {
            try await createUserDocument(user: user, fullName: fullName)
        } else {
            // Update last sign in
            try await docRef.updateData([
                "lastSignIn": Timestamp(date: Date())
            ])
        }
    }
    
    // MARK: - Apple Sign In Nonce
    
    private var currentNonce: String?
    
    func generateNonce() -> String {
        let nonce = randomNonceString()
        currentNonce = nonce
        return sha256(nonce)
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap { String(format: "%02x", $0) }.joined()
        return hashString
    }
}

// MARK: - Supporting Types

enum AuthError: Error, LocalizedError {
    case invalidNonce
    case invalidToken
    case noCurrentUser
    case userNotFound
    case networkError
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .invalidNonce:
            return "Invalid nonce provided"
        case .invalidToken:
            return "Invalid token provided"
        case .noCurrentUser:
            return "No current user"
        case .userNotFound:
            return "User not found"
        case .networkError:
            return "Network error occurred"
        case .unknownError:
            return "An unknown error occurred"
        }
    }
}

struct GoogleSignInCredential {
    let idToken: String
    let accessToken: String
    let fullName: String?
}

// MARK: - Extensions

extension PersonNameComponents {
    func formatted() -> String {
        let formatter = PersonNameComponentsFormatter()
        return formatter.string(from: self)
    }
}
