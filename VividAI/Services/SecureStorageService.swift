import Foundation
import Security
import UIKit
import os.log
import CryptoKit
import CommonCrypto

// MARK: - Secure Storage Service

class SecureStorageService: ObservableObject {
    static let shared = SecureStorageService()
    
    private let keychain = Keychain(service: "com.vividai.app")
    private let logger = Logger(subsystem: "VividAI", category: "SecureStorage")
    
    // MARK: - Encryption Keys
    private let trialDataKey = "trial_data"
    private let referralDataKey = "referral_data"
    private let deviceIdKey = "device_id"
    
    init() {}
    
    // MARK: - Trial Data Storage
    
    func storeTrialData(_ trialData: TrialData) {
        do {
            let encryptedData = try encryptTrialData(trialData)
            try keychain.set(encryptedData, key: trialDataKey)
            logger.info("Trial data stored securely")
        } catch {
            logger.error("Failed to store trial data: \(error.localizedDescription)")
        }
    }
    
    func getTrialData() -> TrialData? {
        do {
            guard let encryptedData = try keychain.getData(trialDataKey) else {
                return nil
            }
            return try decryptTrialData(encryptedData)
        } catch {
            logger.error("Failed to retrieve trial data: \(error.localizedDescription)")
            return nil
        }
    }
    
    func clearTrialData() {
        do {
            try keychain.delete(trialDataKey)
            logger.info("Trial data cleared")
        } catch {
            logger.error("Failed to clear trial data: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Referral Data Storage
    
    func storeReferralData(_ referralData: ReferralData) {
        do {
            let encryptedData = try encryptReferralData(referralData)
            try keychain.set(encryptedData, key: referralDataKey)
            logger.info("Referral data stored securely")
        } catch {
            logger.error("Failed to store referral data: \(error.localizedDescription)")
        }
    }
    
    func getReferralData() -> ReferralData? {
        do {
            guard let encryptedData = try keychain.getData(referralDataKey) else {
                return nil
            }
            return try decryptReferralData(encryptedData)
        } catch {
            logger.error("Failed to retrieve referral data: \(error.localizedDescription)")
            return nil
        }
    }
    
    func updateReferralRewards(_ newCount: Int) {
        guard var referralData = getReferralData() else { return }
        referralData.availableRewards = newCount
        storeReferralData(referralData)
    }
    
    // MARK: - Device Fingerprinting
    
    func getDeviceId() -> String {
        if let existingId = try? keychain.getString(deviceIdKey) {
            return existingId
        }
        
        let deviceId = generateDeviceId()
        do {
            try keychain.set(deviceId, key: deviceIdKey)
        } catch {
            logger.error("Failed to store device ID: \(error.localizedDescription)")
        }
        
        return deviceId
    }
    
    // MARK: - Encryption Methods
    
    private func encryptTrialData(_ trialData: TrialData) throws -> Data {
        let jsonData = try JSONEncoder().encode(trialData)
        return try encryptData(jsonData)
    }
    
    private func decryptTrialData(_ encryptedData: Data) throws -> TrialData {
        let decryptedData = try decryptData(encryptedData)
        return try JSONDecoder().decode(TrialData.self, from: decryptedData)
    }
    
    private func encryptReferralData(_ referralData: ReferralData) throws -> Data {
        let jsonData = try JSONEncoder().encode(referralData)
        return try encryptData(jsonData)
    }
    
    private func decryptReferralData(_ encryptedData: Data) throws -> ReferralData {
        let decryptedData = try decryptData(encryptedData)
        return try JSONDecoder().decode(ReferralData.self, from: decryptedData)
    }
    
    private func encryptData(_ data: Data) throws -> Data {
        let key = getEncryptionKey()
        let sealedBox = try AES.GCM.seal(data, using: key)
        return sealedBox.combined!
    }
    
    private func decryptData(_ encryptedData: Data) throws -> Data {
        let key = getEncryptionKey()
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        return try AES.GCM.open(sealedBox, using: key)
    }
    
    private func getEncryptionKey() -> SymmetricKey {
        // Generate a secure, unpredictable encryption key
        // Use multiple entropy sources for maximum security
        let deviceId = getDeviceId()
        let bundleId = Bundle.main.bundleIdentifier ?? "com.vividai.app"
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        let systemVersion = UIDevice.current.systemVersion
        let model = UIDevice.current.model
        
        // Combine multiple entropy sources
        let entropyString = "\(deviceId)_\(bundleId)_\(appVersion)_\(buildNumber)_\(systemVersion)_\(model)_VIVIDAI_SECURE_KEY_2024"
        
        // Use PBKDF2 for key derivation with high iteration count
        let salt = "VividAI_Salt_2024".data(using: .utf8)!
        let keyData = PBKDF2.deriveKey(
            password: entropyString,
            salt: salt,
            keyLength: 32, // 256 bits
            rounds: 100000 // High iteration count for security
        )
        
        return SymmetricKey(data: keyData)
    }
    
    private func generateDeviceId() -> String {
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        let timestamp = String(Int(Date().timeIntervalSince1970))
        let combined = "\(deviceId)_\(timestamp)"
        return SHA256.hash(data: combined.data(using: .utf8)!).compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - PBKDF2 Implementation

struct PBKDF2 {
    static func deriveKey(password: String, salt: Data, keyLength: Int, rounds: Int) -> Data {
        let passwordData = password.data(using: .utf8)!
        var derivedKey = Data(count: keyLength)
        
        let result = derivedKey.withUnsafeMutableBytes { derivedKeyBytes in
            salt.withUnsafeBytes { saltBytes in
                passwordData.withUnsafeBytes { passwordBytes in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passwordBytes.bindMemory(to: Int8.self).baseAddress,
                        passwordData.count,
                        saltBytes.bindMemory(to: UInt8.self).baseAddress,
                        salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        UInt32(rounds),
                        derivedKeyBytes.bindMemory(to: UInt8.self).baseAddress,
                        keyLength
                    )
                }
            }
        }
        
        guard result == kCCSuccess else {
            fatalError("PBKDF2 key derivation failed")
        }
        
        return derivedKey
    }
}

// MARK: - Data Models

struct TrialData: Codable {
    let startDate: Date
    let isActive: Bool
    let deviceId: String
    var trialId: String
    var serverValidated: Bool
    
    init(startDate: Date, isActive: Bool, deviceId: String) {
        self.startDate = startDate
        self.isActive = isActive
        self.deviceId = deviceId
        self.trialId = UUID().uuidString
        self.serverValidated = false
    }
}

struct ReferralData: Codable {
    let referralCode: String
    let referralCount: Int
    var availableRewards: Int
    let deviceId: String
    let serverValidated: Bool
    
    init(referralCode: String, referralCount: Int, availableRewards: Int, deviceId: String) {
        self.referralCode = referralCode
        self.referralCount = referralCount
        self.availableRewards = availableRewards
        self.deviceId = deviceId
        self.serverValidated = false
    }
}

// MARK: - Keychain Wrapper

struct Keychain {
    private let service: String
    
    init(service: String) {
        self.service = service
    }
    
    func set(_ data: Data, key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // Delete existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.addFailed
        }
    }
    
    func set(_ string: String, key: String) throws {
        guard let data = string.data(using: .utf8) else {
            throw KeychainError.invalidData
        }
        try set(data, key: key)
    }
    
    func getData(_ key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return nil
            }
            throw KeychainError.copyFailed
        }
        
        return result as? Data
    }
    
    func getString(_ key: String) throws -> String? {
        guard let data = try getData(key) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    func delete(_ key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed
        }
    }
}

enum KeychainError: Error {
    case addFailed
    case copyFailed
    case deleteFailed
    case invalidData
    
    var localizedDescription: String {
        switch self {
        case .addFailed:
            return "Failed to add item to keychain"
        case .copyFailed:
            return "Failed to copy item from keychain"
        case .deleteFailed:
            return "Failed to delete item from keychain"
        case .invalidData:
            return "Invalid data for keychain"
        }
    }
}

