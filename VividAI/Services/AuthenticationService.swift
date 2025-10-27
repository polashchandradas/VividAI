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
    
    // MARK: - Centralized Authentication State (Delegated to Unified State Manager)
    // State is now managed by UnifiedAppStateManager to avoid duplication
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var authState: AuthState = .unknown
    
    // MARK: - User Profile (Local to Authentication Service)
    @Published var userProfile: UserProfile?
    
    // MARK: - Service Dependencies
    @MainActor
    private var unifiedAppStateManager: UnifiedAppStateManager {
        return ServiceContainer.shared.unifiedAppStateManager
    }
    
    private var auth: Auth {
        return ServiceContainer.shared.firebaseConfigurationService.getAuth()
    }
    private var db: Firestore {
        return ServiceContainer.shared.firebaseConfigurationService.getFirestore()
    }
    private let logger = Logger(subsystem: "VividAI", category: "Authentication")
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Auth State
    
    enum AuthState {
        case unknown
        case authenticated(User)
        case unauthenticated
    }
    
    // MARK: - User Profile
    
    struct UserProfile {
        let uid: String
        let email: String
        let displayName: String
        let photoURL: String?
        let isPremium: Bool
        let subscriptionStatus: SubscriptionStatus
        let trialUsed: Bool
        let createdAt: Date
        let lastSignIn: Date
    }
    
    // MARK: - Initialization
    
    private init() {
        setupAuthStateListener()
        // setupSubscriptionStateListener() will be called by ServiceContainer after all services are initialized
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
            
            // Load user profile and subscription status
            Task {
                await loadUserProfileAndSubscriptionStatus(user: user)
            }
            
            logger.info("User authenticated: \(user.uid)")
            ServiceContainer.shared.analyticsService.track(event: "user_authenticated", parameters: [
                "user_id": user.uid,
                "email": user.email ?? "unknown"
            ])
        } else {
            self.currentUser = nil
            self.isAuthenticated = false
            self.authState = .unauthenticated
            self.userProfile = nil
            
            logger.info("User signed out")
            ServiceContainer.shared.analyticsService.track(event: "user_signed_out")
        }
    }
    
    func setupSubscriptionStateListener() {
        // Set up callback-based communication with SubscriptionManager
        ServiceContainer.shared.subscriptionManager.onSubscriptionStateChanged = { [weak self] isPremium, status in
            DispatchQueue.main.async {
                // Update unified state manager instead
                ServiceContainer.shared.unifiedAppStateManager.isPremiumUser = isPremium
                ServiceContainer.shared.unifiedAppStateManager.subscriptionStatus = status
            }
        }
    }
    
    private func loadUserProfileAndSubscriptionStatus(user: User) async {
        do {
            let docRef = db.collection("users").document(user.uid)
            let document = try await docRef.getDocument()
            
            if let data = document.data() {
                let userProfile = UserProfile(
                    uid: user.uid,
                    email: data["email"] as? String ?? user.email ?? "",
                    displayName: data["displayName"] as? String ?? user.displayName ?? "",
                    photoURL: data["photoURL"] as? String,
                    isPremium: data["isPremium"] as? Bool ?? false,
                    subscriptionStatus: SubscriptionStatus(rawValue: data["subscriptionStatus"] as? String ?? "none") ?? .none,
                    trialUsed: data["trialUsed"] as? Bool ?? false,
                    createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                    lastSignIn: (data["lastSignIn"] as? Timestamp)?.dateValue() ?? Date()
                )
                
                await MainActor.run {
                    self.userProfile = userProfile
                    // Update unified state manager
                    ServiceContainer.shared.unifiedAppStateManager.isPremiumUser = userProfile.isPremium
                    ServiceContainer.shared.unifiedAppStateManager.subscriptionStatus = userProfile.subscriptionStatus
                }
            }
        } catch {
            logger.error("Failed to load user profile: \(error.localizedDescription)")
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
            ServiceContainer.shared.analyticsService.track(event: "user_signed_up", parameters: [
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
            
            // Update unified state manager
            await unifiedAppStateManager.signIn(email: email, password: password)
            
            await MainActor.run {
                self.isLoading = false
            }
            
            logger.info("User signed in successfully: \(user.uid)")
            ServiceContainer.shared.analyticsService.track(event: "user_signed_in", parameters: [
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
            
            // 2. Update unified state manager
            await unifiedAppStateManager.signOut()
            
            // 3. Clear all user data and reset app state
            await performLogoutCleanup()
            
            logger.info("User signed out successfully with full cleanup")
            ServiceContainer.shared.analyticsService.track(event: "user_signed_out")
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
        let secureStorage = ServiceContainer.shared.secureStorageService
        
        // Clear trial data
        secureStorage.clearTrialData()
        
        // Clear referral data - updateReferralRewards sets to 0
        if var referralData = secureStorage.getReferralData() {
            referralData = ReferralData(
                referralCode: referralData.referralCode,
                referralCount: 0,
                availableRewards: 0,
                deviceId: referralData.deviceId
            )
            secureStorage.storeReferralData(referralData)
        }
        
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
        ServiceContainer.shared.analyticsService.setUserProperty(nil, forName: "user_id")
        ServiceContainer.shared.analyticsService.setUserProperty(nil, forName: "subscription_status")
        ServiceContainer.shared.analyticsService.setUserProperty(nil, forName: "is_premium")
        
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
            ServiceContainer.shared.analyticsService.track(event: "password_reset_requested", parameters: [
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
            
            // Firebase OAuth credential API for Apple Sign In
            // Use OAuthProvider.credential static method with correct parameters
            let firebaseCredential = OAuthProvider.credential(
                withProviderID: "apple.com",
                idToken: idTokenString,
                rawNonce: nonce
            )
            
            let authResult = try await auth.signIn(with: firebaseCredential)
            let user = authResult.user
            
            // Create user document if it doesn't exist
            try await createUserDocumentIfNeeded(user: user, fullName: credential.fullName?.formatted())
            
            await MainActor.run {
                self.isLoading = false
            }
            
            logger.info("Apple Sign In successful: \(user.uid)")
            ServiceContainer.shared.analyticsService.track(event: "user_signed_in", parameters: [
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
            ServiceContainer.shared.analyticsService.track(event: "user_signed_in", parameters: [
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
        ServiceContainer.shared.analyticsService.track(event: "user_profile_updated", parameters: [
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
        ServiceContainer.shared.analyticsService.track(event: "user_account_deleted", parameters: [
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
