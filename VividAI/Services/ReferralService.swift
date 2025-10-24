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
    
    init() {
        loadReferralData()
    }
    
    // MARK: - Referral Code Generation
    
    func generateReferralCode() -> String {
        let code = generateRandomCode()
        UserDefaults.standard.set(code, forKey: "referral_code")
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
        AnalyticsService.shared.track(event: "referral_tracked", parameters: [
            "referrer_code": referrerCode
        ])
    }
    
    func processReferralReward() {
        // Give reward to referrer
        let currentRewards = UserDefaults.standard.integer(forKey: "available_rewards")
        UserDefaults.standard.set(currentRewards + 3, forKey: "available_rewards") // 3 watermark-free exports
        
        // Update published property
        availableRewards = currentRewards + 3
        
        // Track analytics
        AnalyticsService.shared.track(event: "referral_reward_earned", parameters: [
            "reward_count": 3
        ])
    }
    
    // MARK: - Reward Management
    
    func useReward() -> Bool {
        guard availableRewards > 0 else { return false }
        
        let newCount = availableRewards - 1
        UserDefaults.standard.set(newCount, forKey: "available_rewards")
        availableRewards = newCount
        
        AnalyticsService.shared.track(event: "reward_used", parameters: [
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
        referralCode = UserDefaults.standard.string(forKey: "referral_code") ?? ""
        referralCount = UserDefaults.standard.integer(forKey: "referral_count")
        availableRewards = UserDefaults.standard.integer(forKey: "available_rewards")
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
        
        AnalyticsService.shared.track(event: "referral_code_applied", parameters: [
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
