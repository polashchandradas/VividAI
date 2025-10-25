import Foundation
import UIKit
import SwiftUI
import Combine
import os.log
import CoreFoundation
import CoreGraphics
import CoreData

class ReferralService: ObservableObject {
    static let shared = ReferralService()
    
    @Published var referralCode: String = ""
    @Published var referralCount: Int = 0
    @Published var availableRewards: Int = 0
    
    private var secureStorage: SecureStorageService {
        return ServiceContainer.shared.secureStorageService
    }
    private var analyticsService: AnalyticsService {
        return ServiceContainer.shared.analyticsService
    }
    
    init() {
        loadReferralData()
    }
    
    // MARK: - Referral Code Generation
    
    func generateReferralCode() -> String {
        let code = generateRandomCode()
        let deviceId = secureStorage.getDeviceId()
        
        let referralData = ReferralData(
            referralCode: code,
            referralCount: 0,
            availableRewards: 0,
            deviceId: deviceId
        )
        
        secureStorage.storeReferralData(referralData)
        referralCode = code
        return code
    }
    
    private func generateRandomCode() -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let codeLength = 6
        var result = ""
        
        for _ in 0..<codeLength {
            let randomIndex = Int.random(in: 0..<characters.count)
            let character = characters[characters.index(characters.startIndex, offsetBy: randomIndex)]
            result.append(character)
        }
        
        return result
    }
    
    // MARK: - Referral Tracking
    
    func trackReferral(referrerCode: String) {
        // Increment referrer's count
        let referrerKey = "referrals_\(referrerCode)"
        let currentCount = UserDefaults.standard.integer(forKey: referrerKey)
        UserDefaults.standard.set(currentCount + 1, forKey: referrerKey)
        
        // Track analytics
        analyticsService.track(event: "referral_tracked", parameters: [
            "referrer_code": referrerCode
        ])
    }
    
    func processReferralReward() {
        // Give reward to referrer with secure storage
        guard let referralData = secureStorage.getReferralData() else { return }
        
        let newRewardCount = referralData.availableRewards + 3 // 3 watermark-free exports
        secureStorage.updateReferralRewards(newRewardCount)
        
        // Update published property
        availableRewards = newRewardCount
        
        // Track analytics
        analyticsService.track(event: "referral_reward_earned", parameters: [
            "reward_count": 3,
            "device_id": referralData.deviceId
        ])
    }
    
    // MARK: - Reward Management
    
    func useReward() -> Bool {
        guard availableRewards > 0 else { return false }
        
        let newCount = availableRewards - 1
        secureStorage.updateReferralRewards(newCount)
        availableRewards = newCount
        
        analyticsService.track(event: "reward_used", parameters: [
            "remaining_rewards": newCount
        ])
        
        return true
    }
    
    func getReferralLink() -> String {
        let code = referralCode.isEmpty ? generateReferralCode() : referralCode
        return "https://vividai.app/referral/\(code)"
    }
    
    func shareReferralLink() {
        let link = getReferralLink()
        let text = "Check out VividAI - the best AI photo enhancement app! Use my referral link: \(link)"
        
        let activityViewController = UIActivityViewController(
            activityItems: [text, URL(string: link)!],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityViewController, animated: true)
        }
    }
    
    // MARK: - Data Loading
    
    private func loadReferralData() {
        guard let referralData = secureStorage.getReferralData() else {
            referralCode = ""
            referralCount = 0
            availableRewards = 0
            return
        }
        
        referralCode = referralData.referralCode
        referralCount = referralData.referralCount
        availableRewards = referralData.availableRewards
    }
    
    // MARK: - Referral Validation
    
    func validateReferralCode(_ code: String) -> Bool {
        // Check if code exists in the system
        // In production, this would check against a database
        return code.count == 6 && code.allSatisfy { $0.isLetter || $0.isNumber }
    }
    
    func applyReferralCode(_ code: String) -> Bool {
        guard validateReferralCode(code) else { return false }
        
        // Track the referral
        trackReferral(referrerCode: code)
        
        // Give reward to referrer
        processReferralReward()
        
        analyticsService.track(event: "referral_code_applied", parameters: [
            "referral_code": code
        ])
        
        return true
    }
    
    // MARK: - Referral Statistics
    
    func getReferralStats() -> ReferralStats {
        return ReferralStats(
            totalReferrals: referralCount,
            availableRewards: availableRewards,
            referralCode: referralCode
        )
    }
    
    func getReferralLeaderboard() -> [ReferralUser] {
        // Mock leaderboard data
        return [
            ReferralUser(name: "You", referrals: referralCount, rank: 1),
            ReferralUser(name: "Sarah M.", referrals: 12, rank: 2),
            ReferralUser(name: "Mike R.", referrals: 8, rank: 3),
            ReferralUser(name: "Lisa K.", referrals: 5, rank: 4)
        ]
    }
}

// MARK: - Data Models

struct ReferralStats {
    let totalReferrals: Int
    let availableRewards: Int
    let referralCode: String
}

struct ReferralUser {
    let name: String
    let referrals: Int
    let rank: Int
}

struct ReferralReward {
    let type: RewardType
    let count: Int
    let description: String
    
    enum RewardType {
        case watermarkFreeExports
        case premiumDays
        case credits
    }
}
