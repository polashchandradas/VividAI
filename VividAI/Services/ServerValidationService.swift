import Foundation
import UIKit
import os.log
import CryptoKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions

// MARK: - Server Validation Service

class ServerValidationService: ObservableObject {
    static let shared = ServerValidationService()
    
    private let logger = Logger(subsystem: "VividAI", category: "ServerValidation")
    private let secureStorage = SecureStorageService.shared
    private let firebaseValidation = FirebaseValidationService.shared
    private var functions: Functions {
        return ServiceContainer.shared.firebaseConfigurationService.getFunctions()
    }
    private var db: Firestore {
        return ServiceContainer.shared.firebaseConfigurationService.getFirestore()
    }
    
    // MARK: - Trial Validation
    
    func validateTrialStatus() async -> TrialValidationResult {
        guard let trialData = secureStorage.getTrialData() else {
            return TrialValidationResult(isValid: false, isActive: false, daysRemaining: 0, serverValidated: false)
        }
        
        // Check if trial is expired locally
        let trialEndDate = trialData.startDate.addingTimeInterval(3 * 24 * 60 * 60)
        let isExpired = Date() > trialEndDate
        
        if isExpired {
            // Clear expired trial data
            secureStorage.clearTrialData()
            return TrialValidationResult(isValid: false, isActive: false, daysRemaining: 0, serverValidated: true)
        }
        
        // Validate with server
        do {
            let serverResult = try await validateTrialWithServer(trialData)
            return serverResult
        } catch {
            logger.error("Server validation failed: \(error.localizedDescription)")
            // Fallback to local validation
            let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: trialEndDate).day ?? 0
            return TrialValidationResult(
                isValid: true,
                isActive: trialData.isActive,
                daysRemaining: max(0, daysRemaining),
                serverValidated: false
            )
        }
    }
    
    private func validateTrialWithServer(_ trialData: TrialData) async throws -> TrialValidationResult {
        // Use Firebase Functions for real server validation
        do {
            let result = try await firebaseValidation.validateTrialWithFirebase(trialData)
            
            // Update local data with server validation
            if result.serverValidated {
                var updatedTrialData = trialData
                updatedTrialData.serverValidated = true
                secureStorage.storeTrialData(updatedTrialData)
            }
            
            return TrialValidationResult(
                isValid: result.isValid,
                isActive: result.isActive,
                daysRemaining: result.daysRemaining,
                serverValidated: result.serverValidated
            )
        } catch {
            logger.error("Firebase validation failed: \(error.localizedDescription)")
            
            // Fallback to local validation
            let daysRemaining = calculateDaysRemaining(from: trialData.startDate)
            return TrialValidationResult(
                isValid: daysRemaining > 0,
                isActive: trialData.isActive && daysRemaining > 0,
                daysRemaining: daysRemaining,
                serverValidated: false
            )
        }
    }
    
    // MARK: - Referral Validation
    
    func validateReferralRewards() async -> ReferralValidationResult {
        guard let referralData = secureStorage.getReferralData() else {
            return ReferralValidationResult(isValid: false, availableRewards: 0, serverValidated: false)
        }
        
        // Validate with server
        do {
            let serverResult = try await validateReferralWithServer(referralData)
            return serverResult
        } catch {
            logger.error("Referral validation failed: \(error.localizedDescription)")
            // Fallback to local validation
            return ReferralValidationResult(
                isValid: true,
                availableRewards: referralData.availableRewards,
                serverValidated: false
            )
        }
    }
    
    private func validateReferralWithServer(_ referralData: ReferralData) async throws -> ReferralValidationResult {
        // Real server validation using Firebase Functions
        do {
            let result = try await firebaseValidation.validateReferralWithFirebase(referralData)
            
            return ReferralValidationResult(
                isValid: result.isValid,
                availableRewards: result.availableRewards,
                serverValidated: result.serverValidated
            )
        } catch {
            logger.error("Firebase referral validation failed: \(error.localizedDescription)")
            
            // Fallback to local validation with reduced trust
            return ReferralValidationResult(
                isValid: true,
                availableRewards: min(referralData.availableRewards, 5), // Limit rewards without server validation
                serverValidated: false
            )
        }
    }
    
    // MARK: - Abuse Detection
    
    func detectTrialAbuse() async -> AbuseDetectionResult {
        guard let trialData = secureStorage.getTrialData() else {
            return AbuseDetectionResult(isAbuse: false, reason: nil)
        }
        
        // Check for multiple trial attempts
        let trialHistory = await getTrialHistory(deviceId: trialData.deviceId)
        if trialHistory.count > 1 {
            return AbuseDetectionResult(
                isAbuse: true,
                reason: "Multiple trial attempts detected"
            )
        }
        
        // Check for suspicious patterns
        if await isSuspiciousTrialPattern(trialData) {
            return AbuseDetectionResult(
                isAbuse: true,
                reason: "Suspicious trial pattern detected"
            )
        }
        
        return AbuseDetectionResult(isAbuse: false, reason: nil)
    }
    
    func detectReferralAbuse() async -> AbuseDetectionResult {
        guard let referralData = secureStorage.getReferralData() else {
            return AbuseDetectionResult(isAbuse: false, reason: nil)
        }
        
        // Check for excessive rewards
        if referralData.availableRewards > 100 {
            return AbuseDetectionResult(
                isAbuse: true,
                reason: "Excessive rewards detected"
            )
        }
        
        // Check for suspicious referral patterns
        if await isSuspiciousReferralPattern(referralData) {
            return AbuseDetectionResult(
                isAbuse: true,
                reason: "Suspicious referral pattern detected"
            )
        }
        
        return AbuseDetectionResult(isAbuse: false, reason: nil)
    }
    
    // MARK: - Helper Methods
    
    private func calculateDaysRemaining(from startDate: Date) -> Int {
        let trialEndDate = startDate.addingTimeInterval(3 * 24 * 60 * 60)
        let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: trialEndDate).day ?? 0
        return max(0, daysRemaining)
    }
    
    private func getTrialHistory(deviceId: String) async -> [TrialData] {
        // In production, this would query your server for trial history
        // For now, return empty array
        return []
    }
    
    private func isSuspiciousTrialPattern(_ trialData: TrialData) async -> Bool {
        // Check for suspicious patterns like:
        // - Multiple trials from same device
        // - Trials started at suspicious times
        // - Unusual device characteristics
        
        let currentHour = Calendar.current.component(.hour, from: Date())
        let trialHour = Calendar.current.component(.hour, from: trialData.startDate)
        
        // Check if trial was started at suspicious time (e.g., 3 AM)
        if trialHour < 6 || trialHour > 22 {
            return true
        }
        
        return false
    }
    
    private func isSuspiciousReferralPattern(_ referralData: ReferralData) async -> Bool {
        // Check for suspicious patterns like:
        // - Excessive referral counts
        // - Unusual referral timing
        // - Suspicious referral codes
        
        if referralData.referralCount > 50 {
            return true
        }
        
        // Check for suspicious referral codes
        if referralData.referralCode.contains("TEST") || referralData.referralCode.contains("FAKE") {
            return true
        }
        
        return false
    }
}

// MARK: - Data Models

struct TrialValidationResult {
    let isValid: Bool
    let isActive: Bool
    let daysRemaining: Int
    let serverValidated: Bool
}

struct ReferralValidationResult {
    let isValid: Bool
    let availableRewards: Int
    let serverValidated: Bool
}

struct AbuseDetectionResult {
    let isAbuse: Bool
    let reason: String?
}

struct TrialValidationRequest: Codable {
    let deviceId: String
    let trialId: String
    let startDate: Date
    let isActive: Bool
}

struct TrialValidationResponse: Codable {
    let isValid: Bool
    let isActive: Bool
    let daysRemaining: Int
    let serverValidated: Bool
    let abuseDetected: Bool
}

struct ReferralValidationRequest: Codable {
    let deviceId: String
    let referralCode: String
    let referralCount: Int
    let availableRewards: Int
}

struct ReferralValidationResponse: Codable {
    let isValid: Bool
    let availableRewards: Int
    let serverValidated: Bool
    let abuseDetected: Bool
}

