import Foundation
import SwiftUI
import StoreKit

// MARK: - Shared Type Definitions
// Centralized types to avoid duplicate declarations across the codebase

// MARK: - Subscription Status
enum SubscriptionStatus: String, CaseIterable {
    case none = "none"
    case trial = "trial"
    case active = "active"
    case expired = "expired"
    case cancelled = "cancelled"
    case pending = "pending"
}

// MARK: - Trial Type
enum TrialType: String, CaseIterable {
    case none = "none"
    case limited = "limited"
    case unlimited = "unlimited"
    case freemium = "freemium"
}

// MARK: - User Status
enum UserStatus {
    case free
    case trial(TrialType)
    case premium
    
    var isPremium: Bool {
        if case .premium = self { return true }
        return false
    }
    
    var isTrialActive: Bool {
        if case .trial = self { return true }
        return false
    }
}

// MARK: - Generation Limits
enum GenerationLimits {
    case unlimited
    case trial(used: Int, max: Int, daysRemaining: Int)
    case free(remaining: Int)
    
    var canGenerate: Bool {
        switch self {
        case .unlimited:
            return true
        case .trial(let used, let max, _):
            return used < max
        case .free(let remaining):
            return remaining > 0
        }
    }
    
    var remainingGenerations: Int {
        switch self {
        case .unlimited:
            return 999
        case .trial(let used, let maxValue, _):
            return Swift.max(0, maxValue - used)
        case .free(let remaining):
            return remaining
        }
    }
}

// MARK: - Subscription Action
enum SubscriptionAction: CustomStringConvertible {
    case startFreeTrial(SubscriptionManager.SubscriptionPlan)
    case purchase(Product)
    case restorePurchases
    case cancelSubscription
    
    var description: String {
        switch self {
        case .startFreeTrial(let plan):
            return "startFreeTrial(\(plan))"
        case .purchase(let product):
            return "purchase(\(product.id))"
        case .restorePurchases:
            return "restorePurchases"
        case .cancelSubscription:
            return "cancelSubscription"
        }
    }
}

// MARK: - App View
enum AppView: String, CaseIterable {
    case splash = "splash"
    case authentication = "authentication"
    case home = "home"
    case photoUpload = "photoUpload"
    case qualitySelection = "qualitySelection"
    case realTimePreview = "realTimePreview"
    case processing = "processing"
    case results = "results"
    case paywall = "paywall"
    case share = "share"
    case settings = "settings"
}

// MARK: - Trial Validation Result
struct TrialValidationResult {
    let isValid: Bool
    let isActive: Bool
    let daysRemaining: Int
    let serverValidated: Bool
    let abuseDetected: Bool
    let reason: String?
}

// MARK: - Abuse Detection Result
struct AbuseDetectionResult {
    let isAbuse: Bool
    let reason: String?
    let confidence: Double
    let detectedPatterns: [String]
}

// MARK: - Processing Result
struct ProcessingResult: Identifiable {
    let id = UUID()
    let image: UIImage
    let style: String
    let isPremium: Bool
    let processingTime: TimeInterval
    let quality: ImageQuality
}

// MARK: - Headshot Result Extension
extension HeadshotResult {
    var image: UIImage? {
        // Extract image from imageURL string
        if let url = URL(string: imageURL),
           let data = try? Data(contentsOf: url),
           let uiImage = UIImage(data: data) {
            return uiImage
        }
        return nil
    }
}

