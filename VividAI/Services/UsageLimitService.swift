import Foundation
import SwiftUI
import Combine
import os.log

// MARK: - Usage Limit Service

class UsageLimitService: ObservableObject {
    static let shared = UsageLimitService()
    
    @Published var dailyGenerations = 0
    @Published var weeklyGenerations = 0
    @Published var monthlyGenerations = 0
    @Published var totalGenerations = 0
    @Published var isLimitReached = false
    @Published var limitType: LimitType = .none
    
    private var analyticsService: AnalyticsService {
        return ServiceContainer.shared.analyticsService
    }
    private let logger = Logger(subsystem: "VividAI", category: "UsageLimit")
    
    // MARK: - Limit Types
    
    enum LimitType {
        case none
        case daily
        case weekly
        case monthly
        case total
    }
    
    // MARK: - Limits Configuration
    
    struct Limits {
        static let freeUserDaily = 1
        static let freeUserWeekly = 3
        static let freeUserMonthly = 10
        static let trialUserDaily = 3
        static let trialUserWeekly = 10
        static let premiumUserDaily = 999
        static let premiumUserWeekly = 999
        static let premiumUserMonthly = 999
    }
    
    // MARK: - Initialization
    
    private init() {
        loadUsageData()
    }
    
    // MARK: - Usage Tracking
    
    func recordGeneration() {
        let today = Date()
        let calendar = Calendar.current
        
        // Update counters
        dailyGenerations += 1
        weeklyGenerations += 1
        monthlyGenerations += 1
        totalGenerations += 1
        
        // Update last generation date
        UserDefaults.standard.set(today, forKey: "lastGenerationDate")
        
        // Save usage data
        saveUsageData()
        
        // Check limits
        checkLimits()
        
        logger.info("Generation recorded: Daily(\(dailyGenerations)), Weekly(\(weeklyGenerations)), Monthly(\(monthlyGenerations))")
        
        analyticsService.track(event: "generation_recorded", parameters: [
            "daily_count": dailyGenerations,
            "weekly_count": weeklyGenerations,
            "monthly_count": monthlyGenerations,
            "total_count": totalGenerations
        ])
    }
    
    func canGenerate(isPremium: Bool, isTrialActive: Bool) -> Bool {
        if isPremium {
            return true // Premium users have no limits
        }
        
        if isTrialActive {
            return checkTrialLimits()
        }
        
        return checkFreeUserLimits()
    }
    
    func getRemainingGenerations(isPremium: Bool, isTrialActive: Bool) -> Int {
        if isPremium {
            return 999 // Unlimited
        }
        
        if isTrialActive {
            return getTrialRemainingGenerations()
        }
        
        return getFreeUserRemainingGenerations()
    }
    
    func getLimitMessage(isPremium: Bool, isTrialActive: Bool) -> String {
        if isPremium {
            return "Unlimited generations"
        }
        
        if isTrialActive {
            return getTrialLimitMessage()
        }
        
        return getFreeUserLimitMessage()
    }
    
    // MARK: - Private Methods
    
    private func checkLimits() {
        // Reset daily counter if new day
        if shouldResetDailyCounter() {
            dailyGenerations = 0
        }
        
        // Reset weekly counter if new week
        if shouldResetWeeklyCounter() {
            weeklyGenerations = 0
        }
        
        // Reset monthly counter if new month
        if shouldResetMonthlyCounter() {
            monthlyGenerations = 0
        }
    }
    
    private func checkFreeUserLimits() -> Bool {
        if dailyGenerations >= Limits.freeUserDaily {
            limitType = .daily
            isLimitReached = true
            return false
        }
        
        if weeklyGenerations >= Limits.freeUserWeekly {
            limitType = .weekly
            isLimitReached = true
            return false
        }
        
        if monthlyGenerations >= Limits.freeUserMonthly {
            limitType = .monthly
            isLimitReached = true
            return false
        }
        
        return true
    }
    
    private func checkTrialLimits() -> Bool {
        if dailyGenerations >= Limits.trialUserDaily {
            limitType = .daily
            isLimitReached = true
            return false
        }
        
        if weeklyGenerations >= Limits.trialUserWeekly {
            limitType = .weekly
            isLimitReached = true
            return false
        }
        
        return true
    }
    
    private func getFreeUserRemainingGenerations() -> Int {
        let dailyRemaining = max(0, Limits.freeUserDaily - dailyGenerations)
        let weeklyRemaining = max(0, Limits.freeUserWeekly - weeklyGenerations)
        let monthlyRemaining = max(0, Limits.freeUserMonthly - monthlyGenerations)
        
        return min(dailyRemaining, weeklyRemaining, monthlyRemaining)
    }
    
    private func getTrialRemainingGenerations() -> Int {
        let dailyRemaining = max(0, Limits.trialUserDaily - dailyGenerations)
        let weeklyRemaining = max(0, Limits.trialUserWeekly - weeklyGenerations)
        
        return min(dailyRemaining, weeklyRemaining)
    }
    
    private func getFreeUserLimitMessage() -> String {
        if dailyGenerations >= Limits.freeUserDaily {
            return "Daily limit reached (1 generation per day)"
        }
        
        if weeklyGenerations >= Limits.freeUserWeekly {
            return "Weekly limit reached (3 generations per week)"
        }
        
        if monthlyGenerations >= Limits.freeUserMonthly {
            return "Monthly limit reached (10 generations per month)"
        }
        
        return "Free user: \(getRemainingGenerations(isPremium: false, isTrialActive: false)) generations remaining"
    }
    
    private func getTrialLimitMessage() -> String {
        if dailyGenerations >= Limits.trialUserDaily {
            return "Daily trial limit reached (3 generations per day)"
        }
        
        if weeklyGenerations >= Limits.trialUserWeekly {
            return "Weekly trial limit reached (10 generations per week)"
        }
        
        return "Trial: \(getRemainingGenerations(isPremium: false, isTrialActive: true)) generations remaining"
    }
    
    // MARK: - Reset Logic
    
    private func shouldResetDailyCounter() -> Bool {
        guard let lastDate = UserDefaults.standard.object(forKey: "lastGenerationDate") as? Date else {
            return false
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastGenerationDay = calendar.startOfDay(for: lastDate)
        
        return today > lastGenerationDay
    }
    
    private func shouldResetWeeklyCounter() -> Bool {
        guard let lastDate = UserDefaults.standard.object(forKey: "lastGenerationDate") as? Date else {
            return false
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastGenerationWeek = calendar.dateInterval(of: .weekOfYear, for: lastDate)?.start ?? lastDate
        
        return today > lastGenerationWeek
    }
    
    private func shouldResetMonthlyCounter() -> Bool {
        guard let lastDate = UserDefaults.standard.object(forKey: "lastGenerationDate") as? Date else {
            return false
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastGenerationMonth = calendar.dateInterval(of: .month, for: lastDate)?.start ?? lastDate
        
        return today > lastGenerationMonth
    }
    
    // MARK: - Data Persistence
    
    private func loadUsageData() {
        dailyGenerations = UserDefaults.standard.integer(forKey: "dailyGenerations")
        weeklyGenerations = UserDefaults.standard.integer(forKey: "weeklyGenerations")
        monthlyGenerations = UserDefaults.standard.integer(forKey: "monthlyGenerations")
        totalGenerations = UserDefaults.standard.integer(forKey: "totalGenerations")
        
        // Reset counters if needed
        checkLimits()
    }
    
    private func saveUsageData() {
        UserDefaults.standard.set(dailyGenerations, forKey: "dailyGenerations")
        UserDefaults.standard.set(weeklyGenerations, forKey: "weeklyGenerations")
        UserDefaults.standard.set(monthlyGenerations, forKey: "monthlyGenerations")
        UserDefaults.standard.set(totalGenerations, forKey: "totalGenerations")
    }
    
    // MARK: - Reset Methods
    
    func resetDailyUsage() {
        dailyGenerations = 0
        saveUsageData()
        isLimitReached = false
        limitType = .none
        
        logger.info("Daily usage reset")
        analyticsService.track(event: "daily_usage_reset")
    }
    
    func resetWeeklyUsage() {
        weeklyGenerations = 0
        saveUsageData()
        isLimitReached = false
        limitType = .none
        
        logger.info("Weekly usage reset")
        analyticsService.track(event: "weekly_usage_reset")
    }
    
    func resetMonthlyUsage() {
        monthlyGenerations = 0
        saveUsageData()
        isLimitReached = false
        limitType = .none
        
        logger.info("Monthly usage reset")
        analyticsService.track(event: "monthly_usage_reset")
    }
    
    func resetAllUsage() {
        dailyGenerations = 0
        weeklyGenerations = 0
        monthlyGenerations = 0
        totalGenerations = 0
        saveUsageData()
        isLimitReached = false
        limitType = .none
        
        logger.info("All usage reset")
        analyticsService.track(event: "all_usage_reset")
    }
}
