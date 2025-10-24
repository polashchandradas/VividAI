import Foundation
import UIKit
import CryptoKit
import LocalAuthentication

// MARK: - Security Service

class SecurityService: ObservableObject {
    static let shared = SecurityService()
    
    @Published var isSecureModeEnabled = false
    @Published var biometricAuthEnabled = false
    @Published var dataEncryptionEnabled = true
    
    private let keychain = KeychainService()
    private let biometricContext = LAContext()
    
    private init() {
        checkBiometricAvailability()
        loadSecuritySettings()
    }
    
    // MARK: - Biometric Authentication
    
    func checkBiometricAvailability() {
        var error: NSError?
        biometricAuthEnabled = biometricContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    func authenticateWithBiometrics(completion: @escaping (Bool, Error?) -> Void) {
        guard biometricAuthEnabled else {
            completion(false, SecurityError.biometricNotAvailable)
            return
        }
        
        let reason = "Authenticate to access your AI headshots"
        biometricContext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }
    
    // MARK: - Data Encryption
    
    func encryptData(_ data: Data) -> Data? {
        guard dataEncryptionEnabled else { return data }
        
        do {
            let key = try getOrCreateEncryptionKey()
            let sealedBox = try AES.GCM.seal(data, using: key)
            return sealedBox.combined
        } catch {
            print("Encryption failed: \(error)")
            return nil
        }
    }
    
    func decryptData(_ encryptedData: Data) -> Data? {
        guard dataEncryptionEnabled else { return encryptedData }
        
        do {
            let key = try getOrCreateEncryptionKey()
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
            return try AES.GCM.open(sealedBox, using: key)
        } catch {
            print("Decryption failed: \(error)")
            return nil
        }
    }
    
    private func getOrCreateEncryptionKey() throws -> SymmetricKey {
        if let keyData = keychain.getData(for: "encryption_key") {
            return SymmetricKey(data: keyData)
        } else {
            let newKey = SymmetricKey(size: .bits256)
            try keychain.setData(newKey.data, for: "encryption_key")
            return newKey
        }
    }
    
    // MARK: - Input Validation
    
    func validateImage(_ image: UIImage) -> ValidationResult {
        var issues: [String] = []
        
        // Check image size
        let maxSize: CGFloat = 10 * 1024 * 1024 // 10MB
        if let imageData = image.jpegData(compressionQuality: 1.0),
           imageData.count > Int(maxSize) {
            issues.append("Image too large")
        }
        
        // Check image dimensions
        let maxDimension: CGFloat = 4096
        if image.size.width > maxDimension || image.size.height > maxDimension {
            issues.append("Image dimensions too large")
        }
        
        // Check for minimum dimensions
        let minDimension: CGFloat = 100
        if image.size.width < minDimension || image.size.height < minDimension {
            issues.append("Image too small")
        }
        
        return ValidationResult(
            isValid: issues.isEmpty,
            issues: issues
        )
    }
    
    func validateAPIKey(_ apiKey: String) -> ValidationResult {
        var issues: [String] = []
        
        if apiKey.isEmpty {
            issues.append("API key is empty")
        } else if apiKey.count < 20 {
            issues.append("API key too short")
        } else if apiKey.contains(" ") {
            issues.append("API key contains spaces")
        } else if apiKey.contains("YOUR_") {
            issues.append("API key appears to be a placeholder")
        }
        
        return ValidationResult(
            isValid: issues.isEmpty,
            issues: issues
        )
    }
    
    func validateURL(_ urlString: String) -> ValidationResult {
        var issues: [String] = []
        
        guard let url = URL(string: urlString) else {
            issues.append("Invalid URL format")
            return ValidationResult(isValid: false, issues: issues)
        }
        
        if url.scheme != "https" {
            issues.append("URL must use HTTPS")
        }
        
        if url.host == nil {
            issues.append("URL must have a valid host")
        }
        
        return ValidationResult(
            isValid: issues.isEmpty,
            issues: issues
        )
    }
    
    // MARK: - Data Sanitization
    
    func sanitizeString(_ input: String) -> String {
        // Remove potentially dangerous characters
        let allowedCharacters = CharacterSet.alphanumerics.union(.whitespaces).union(.punctuationCharacters)
        return String(input.unicodeScalars.filter { allowedCharacters.contains($0) })
    }
    
    func sanitizeImageData(_ data: Data) -> Data? {
        // Check for valid image format
        guard let image = UIImage(data: data) else { return nil }
        
        // Re-encode to remove any potential metadata or malicious content
        return image.jpegData(compressionQuality: 0.9)
    }
    
    // MARK: - Security Settings
    
    func enableSecureMode() {
        isSecureModeEnabled = true
        dataEncryptionEnabled = true
        saveSecuritySettings()
    }
    
    func disableSecureMode() {
        isSecureModeEnabled = false
        saveSecuritySettings()
    }
    
    func toggleBiometricAuth() {
        biometricAuthEnabled.toggle()
        saveSecuritySettings()
    }
    
    private func loadSecuritySettings() {
        isSecureModeEnabled = UserDefaults.standard.bool(forKey: "secure_mode_enabled")
        biometricAuthEnabled = UserDefaults.standard.bool(forKey: "biometric_auth_enabled")
        dataEncryptionEnabled = UserDefaults.standard.bool(forKey: "data_encryption_enabled")
    }
    
    private func saveSecuritySettings() {
        UserDefaults.standard.set(isSecureModeEnabled, forKey: "secure_mode_enabled")
        UserDefaults.standard.set(biometricAuthEnabled, forKey: "biometric_auth_enabled")
        UserDefaults.standard.set(dataEncryptionEnabled, forKey: "data_encryption_enabled")
    }
    
    // MARK: - Threat Detection
    
    func detectSuspiciousActivity() -> ThreatLevel {
        // This would implement actual threat detection logic
        // For now, return a safe default
        return .low
    }
    
    func logSecurityEvent(_ event: SecurityEvent) {
        // Log security events for monitoring
        print("🔒 Security Event: \(event.type) - \(event.description)")
        
        // In a real app, this would send to a security monitoring service
    }
}

// MARK: - Data Models

struct ValidationResult {
    let isValid: Bool
    let issues: [String]
    
    var hasIssues: Bool {
        return !issues.isEmpty
    }
}

struct SecurityEvent {
    let type: SecurityEventType
    let description: String
    let timestamp: Date
    let severity: SecuritySeverity
}

enum SecurityEventType {
    case authenticationAttempt
    case authenticationSuccess
    case authenticationFailure
    case dataAccess
    case dataModification
    case suspiciousActivity
    case configurationChange
}

enum SecuritySeverity {
    case low
    case medium
    case high
    case critical
}

enum ThreatLevel {
    case low
    case medium
    case high
    case critical
}

enum SecurityError: Error, LocalizedError {
    case biometricNotAvailable
    case biometricAuthenticationFailed
    case encryptionFailed
    case decryptionFailed
    case validationFailed
    case keychainError
    
    var errorDescription: String? {
        switch self {
        case .biometricNotAvailable:
            return "Biometric authentication is not available on this device"
        case .biometricAuthenticationFailed:
            return "Biometric authentication failed"
        case .encryptionFailed:
            return "Data encryption failed"
        case .decryptionFailed:
            return "Data decryption failed"
        case .validationFailed:
            return "Input validation failed"
        case .keychainError:
            return "Keychain operation failed"
        }
    }
}

// MARK: - Keychain Service

class KeychainService {
    private let service = "VividAI"
    
    func setData(_ data: Data, for key: String) throws {
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
            throw SecurityError.keychainError
        }
    }
    
    func getData(for key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }
    
    func deleteData(for key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Security Extensions

extension SecurityService {
    func generateSecureToken() -> String {
        let data = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        return data.base64EncodedString()
    }
    
    func hashData(_ data: Data) -> String {
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    func verifyDataIntegrity(_ data: Data, expectedHash: String) -> Bool {
        let actualHash = hashData(data)
        return actualHash == expectedHash
    }
}
