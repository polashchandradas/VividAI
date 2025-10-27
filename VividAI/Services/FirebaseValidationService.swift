import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions
import FirebaseAppCheck
import CryptoKit
import os.log
import UIKit

#if targetEnvironment(simulator)
import UIKit.UIGestureRecognizerSubclass
#endif

// MARK: - Firebase Validation Service

class FirebaseValidationService: ObservableObject {
    static let shared = FirebaseValidationService()
    
    private var auth: Auth {
        return ServiceContainer.shared.firebaseConfigurationService.getAuth()
    }
    private var functions: Functions {
        return ServiceContainer.shared.firebaseConfigurationService.getFunctions()
    }
    private var db: Firestore {
        return ServiceContainer.shared.firebaseConfigurationService.getFirestore()
    }
    private var appCheck: AppCheck {
        return ServiceContainer.shared.firebaseConfigurationService.getAppCheck()
    }
    private let logger = Logger(subsystem: "VividAI", category: "FirebaseValidation")
    
    // MARK: - Enhanced Device Fingerprinting
    
    func generateDeviceFingerprint() -> String {
        let deviceInfo = collectDeviceInfo()
        let fingerprint = createFingerprintHash(from: deviceInfo)
        
        logger.info("Generated device fingerprint: \(fingerprint)")
        return fingerprint
    }
    
    private func isRunningOnSimulator() -> Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    private func collectDeviceInfo() -> DeviceInfo {
        let device = UIDevice.current
        let screen = UIScreen.main
        
        return DeviceInfo(
            vendorId: device.identifierForVendor?.uuidString ?? "",
            systemName: device.systemName,
            systemVersion: device.systemVersion,
            model: device.model,
            name: device.name,
            batteryLevel: device.batteryLevel,
            screenWidth: Int(screen.bounds.width),
            screenHeight: Int(screen.bounds.height),
            scale: screen.scale,
            bundleId: Bundle.main.bundleIdentifier ?? "",
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "",
            buildNumber: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "",
            locale: Locale.current.identifier,
            timeZone: TimeZone.current.identifier,
            isSimulator: isRunningOnSimulator(),
            timestamp: Date().timeIntervalSince1970
        )
    }
    
    private func createFingerprintHash(from deviceInfo: DeviceInfo) -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        
        do {
            let data = try encoder.encode(deviceInfo)
            let hash = SHA256.hash(data: data)
            return hash.compactMap { String(format: "%02x", $0) }.joined()
        } catch {
            logger.error("Failed to create fingerprint hash: \(error.localizedDescription)")
            return UUID().uuidString
        }
    }
    
    // MARK: - Trial Validation with Firebase Functions
    
    func validateTrialWithFirebase(_ trialData: TrialData) async throws -> TrialValidationResult {
        logger.info("Validating trial with Firebase for device: \(trialData.deviceId)")
        
        // Get Firebase ID token
        guard let user = auth.currentUser else {
            throw ValidationError.notAuthenticated
        }
        
        let idToken = try await user.getIDToken()
        
        // Get App Check token
        let appCheckToken = try await appCheck.token(forcingRefresh: false)
        
        // Prepare request data
        let requestData: [String: Any] = [
            "deviceId": trialData.deviceId,
            "trialId": trialData.trialId,
            "startDate": trialData.startDate.timeIntervalSince1970,
            "isActive": trialData.isActive,
            "deviceFingerprint": generateDeviceFingerprint(),
            "userId": user.uid
        ]
        
        // Call Firebase Function
        let result = try await functions.httpsCallable("validateTrial").call(requestData)
        
        guard let data = result.data as? [String: Any] else {
            throw ValidationError.invalidResponse
        }
        
        return TrialValidationResult(
            isValid: data["isValid"] as? Bool ?? false,
            isActive: data["isActive"] as? Bool ?? false,
            daysRemaining: data["daysRemaining"] as? Int ?? 0,
            serverValidated: data["serverValidated"] as? Bool ?? false,
            abuseDetected: data["abuseDetected"] as? Bool ?? false,
            reason: data["reason"] as? String
        )
    }
    
    // MARK: - Start Trial with Server Validation
    
    func startTrialWithFirebase(type: TrialType) async throws -> TrialValidationResult {
        logger.info("Starting trial with Firebase validation: \(type)")
        
        guard let user = auth.currentUser else {
            throw ValidationError.notAuthenticated
        }
        
        let idToken = try await user.getIDToken()
        let appCheckToken = try await appCheck.token(forcingRefresh: false)
        
        let requestData: [String: Any] = [
            "trialType": type.rawValue,
            "deviceFingerprint": generateDeviceFingerprint(),
            "userId": user.uid,
            "deviceInfo": collectDeviceInfo().toDictionary()
        ]
        
        let result = try await functions.httpsCallable("startTrial").call(requestData)
        
        guard let data = result.data as? [String: Any] else {
            throw ValidationError.invalidResponse
        }
        
        return TrialValidationResult(
            isValid: data["isValid"] as? Bool ?? false,
            isActive: data["isActive"] as? Bool ?? false,
            daysRemaining: data["daysRemaining"] as? Int ?? 0,
            serverValidated: data["serverValidated"] as? Bool ?? false,
            abuseDetected: data["abuseDetected"] as? Bool ?? false,
            reason: data["reason"] as? String
        )
    }
    
    // MARK: - Abuse Detection
    
    func detectAbuseWithFirebase() async throws -> AbuseDetectionResult {
        logger.info("Detecting abuse with Firebase")
        
        guard let user = auth.currentUser else {
            throw ValidationError.notAuthenticated
        }
        
        let requestData: [String: Any] = [
            "userId": user.uid,
            "deviceFingerprint": generateDeviceFingerprint(),
            "deviceInfo": collectDeviceInfo().toDictionary()
        ]
        
        let result = try await functions.httpsCallable("detectAbuse").call(requestData)
        
        guard let data = result.data as? [String: Any] else {
            throw ValidationError.invalidResponse
        }
        
        return AbuseDetectionResult(
            isAbuse: data["isAbuse"] as? Bool ?? false,
            reason: data["reason"] as? String,
            confidence: data["confidence"] as? Double ?? 0.0,
            detectedPatterns: data["detectedPatterns"] as? [String] ?? []
        )
    }
    
    // MARK: - Store Trial Data in Firestore
    
    func storeTrialDataInFirestore(_ trialData: TrialData) async throws {
        logger.info("Storing trial data in Firestore")
        
        guard let user = auth.currentUser else {
            throw ValidationError.notAuthenticated
        }
        
        let trialRef = db.collection("trials").document(trialData.trialId)
        
        let trialDocument: [String: Any] = [
            "userId": user.uid,
            "deviceId": trialData.deviceId,
            "trialId": trialData.trialId,
            "startDate": Timestamp(date: trialData.startDate),
            "isActive": trialData.isActive,
            "deviceFingerprint": generateDeviceFingerprint(),
            "deviceInfo": collectDeviceInfo().toDictionary(),
            "serverValidated": trialData.serverValidated,
            "createdAt": Timestamp(date: Date()),
            "updatedAt": Timestamp(date: Date())
        ]
        
        try await trialRef.setData(trialDocument)
        logger.info("Trial data stored successfully in Firestore")
    }
    
    // MARK: - Get Trial History from Firestore
    
    func getTrialHistoryFromFirestore() async throws -> [TrialData] {
        logger.info("Fetching trial history from Firestore")
        
        guard let user = auth.currentUser else {
            throw ValidationError.notAuthenticated
        }
        
        let query = db.collection("trials")
            .whereField("userId", isEqualTo: user.uid)
            .order(by: "createdAt", descending: true)
        
        let snapshot = try await query.getDocuments()
        
        return snapshot.documents.compactMap { document in
            let data = document.data()
            
            guard let startDate = (data["startDate"] as? Timestamp)?.dateValue(),
                  let isActive = data["isActive"] as? Bool,
                  let deviceId = data["deviceId"] as? String,
                  let trialId = data["trialId"] as? String,
                  let serverValidated = data["serverValidated"] as? Bool else {
                return nil
            }
            
            var trialData = TrialData(
                startDate: startDate,
                isActive: isActive,
                deviceId: deviceId
            )
            trialData.trialId = trialId
            trialData.serverValidated = serverValidated
            return trialData
        }
    }
    
    // MARK: - Update Trial Status
    
    func updateTrialStatusInFirestore(_ trialId: String, isActive: Bool) async throws {
        logger.info("Updating trial status in Firestore: \(trialId)")
        
        let trialRef = db.collection("trials").document(trialId)
        
        try await trialRef.updateData([
            "isActive": isActive,
            "updatedAt": Timestamp(date: Date())
        ])
        
        logger.info("Trial status updated successfully")
    }
    
    // MARK: - Referral Validation with Firebase Functions
    
    func validateReferralWithFirebase(_ referralData: ReferralData) async throws -> ReferralValidationResult {
        logger.info("Validating referral with Firebase for device: \(referralData.deviceId)")
        
        guard let user = auth.currentUser else {
            throw ValidationError.notAuthenticated
        }
        
        let idToken = try await user.getIDToken()
        let appCheckToken = try await appCheck.token(forcingRefresh: false)
        
        let requestData: [String: Any] = [
            "deviceId": referralData.deviceId,
            "referralCode": referralData.referralCode,
            "referralCount": referralData.referralCount,
            "availableRewards": referralData.availableRewards,
            "deviceFingerprint": generateDeviceFingerprint(),
            "userId": user.uid
        ]
        
        let result = try await functions.httpsCallable("validateReferral").call(requestData)
        
        guard let data = result.data as? [String: Any] else {
            throw ValidationError.invalidResponse
        }
        
        return ReferralValidationResult(
            isValid: data["isValid"] as? Bool ?? false,
            availableRewards: data["availableRewards"] as? Int ?? 0,
            serverValidated: data["serverValidated"] as? Bool ?? false
        )
    }
    
    // MARK: - Analytics Integration
    
    func trackTrialEvent(_ event: String, parameters: [String: Any] = [:]) {
        var eventParams = parameters
        eventParams["deviceFingerprint"] = generateDeviceFingerprint()
        eventParams["timestamp"] = Date().timeIntervalSince1970
        
        ServiceContainer.shared.firebaseConfigurationService.getAnalytics().logEvent(event, parameters: eventParams)
        logger.info("Tracked trial event: \(event)")
    }
}

// MARK: - Data Models

struct DeviceInfo: Codable {
    let vendorId: String
    let systemName: String
    let systemVersion: String
    let model: String
    let name: String
    let batteryLevel: Float
    let screenWidth: Int
    let screenHeight: Int
    let scale: CGFloat
    let bundleId: String
    let appVersion: String
    let buildNumber: String
    let locale: String
    let timeZone: String
    let isSimulator: Bool
    let timestamp: TimeInterval
    
    func toDictionary() -> [String: Any] {
        return [
            "vendorId": vendorId,
            "systemName": systemName,
            "systemVersion": systemVersion,
            "model": model,
            "name": name,
            "batteryLevel": batteryLevel,
            "screenWidth": screenWidth,
            "screenHeight": screenHeight,
            "scale": scale,
            "bundleId": bundleId,
            "appVersion": appVersion,
            "buildNumber": buildNumber,
            "locale": locale,
            "timeZone": timeZone,
            "isSimulator": isSimulator,
            "timestamp": timestamp
        ]
    }
}

// Note: TrialValidationResult, AbuseDetectionResult, and TrialType are now defined in SharedTypes.swift

enum ValidationError: Error, LocalizedError {
    case notAuthenticated
    case invalidResponse
    case networkError
    case serverError
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User not authenticated"
        case .invalidResponse:
            return "Invalid server response"
        case .networkError:
            return "Network error occurred"
        case .serverError:
            return "Server error occurred"
        }
    }
}
