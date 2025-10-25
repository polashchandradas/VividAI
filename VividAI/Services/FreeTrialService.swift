import Foundation
import SwiftUI
import Combine
import os.log

// MARK: - Free Trial Service

class FreeTrialService: ObservableObject {
    static let shared = FreeTrialService()
    
    @Published var isTrialActive = false
    @Published var trialDaysRemaining = 0
    @Published var generationsUsed = 0
    @Published var maxGenerations = 3
    @Published var canGenerate = true
    @Published var trialType: TrialType = .none
    
    private var secureStorage: SecureStorageService {
        return ServiceContainer.shared.secureStorageService
    }
    private var analyticsService: AnalyticsService {
        return ServiceContainer.shared.analyticsService
    }
    private let logger = Logger(subsystem: "VividAI", category: "FreeTrial")
    
    // MARK: - Trial Types
    
    enum TrialType {
        case none
        case limited      // 3 generations, 7 days
        case unlimited    // Full access, 3 days
        case freemium     // 1 generation per day
    }
    
    // MARK: - Initialization
    
    private init() {
        checkTrialStatus()
    }
    
    // MARK: - Trial Management
    
    func startFreeTrial(type: TrialType = .limited) {
        let trialData = TrialData(
            startDate: Date(),
            isActive: true,
            deviceId: secureStorage.getDeviceId()
        )
        
        secureStorage.storeTrialData(trialData)
        
        trialType = type
        isTrialActive = true
        generationsUsed = 0
        maxGenerations = getMaxGenerations(for: type)
        canGenerate = true
        
        logger.info("Free trial started: \(type)")
        analyticsService.track(event: "free_trial_started", parameters: [
            "trial_type": "\(type)",
            "max_generations": maxGenerations
        ])
    }
    
    func recordGeneration() {
        generationsUsed += 1
        
        // Check if user has reached limit
        if generationsUsed >= maxGenerations {
            canGenerate = false
            logger.info("Generation limit reached: \(generationsUsed)/\(maxGenerations)")
            
            analyticsService.track(event: "trial_limit_reached", parameters: [
                "generations_used": generationsUsed,
                "trial_type": "\(trialType)"
            ])
        }
        
        analyticsService.track(event: "trial_generation_used", parameters: [
            "generations_used": generationsUsed,
            "max_generations": maxGenerations,
            "trial_type": "\(trialType)"
        ])
    }
    
    func canUserGenerate() -> Bool {
        guard isTrialActive else { return false }
        
        switch trialType {
        case .none:
            return false
        case .limited:
            return generationsUsed < maxGenerations
        case .unlimited:
            return true
        case .freemium:
            return canGenerateToday()
        }
    }
    
    func getTrialStatus() -> TrialStatus {
        if !isTrialActive {
            return .inactive
        }
        
        if trialDaysRemaining <= 0 {
            return .expired
        }
        
        if !canGenerate {
            return .limitReached
        }
        
        return .active
    }
    
    // MARK: - Private Methods
    
    private func checkTrialStatus() {
        guard let trialData = secureStorage.getTrialData() else {
            isTrialActive = false
            return
        }
        
        let daysSinceStart = Calendar.current.dateComponents([.day], from: trialData.startDate, to: Date()).day ?? 0
        let maxDays = getMaxDays(for: trialType)
        
        if daysSinceStart >= maxDays {
            // Trial expired
            isTrialActive = false
            trialDaysRemaining = 0
            secureStorage.clearTrialData()
            
            logger.info("Trial expired after \(daysSinceStart) days")
            analyticsService.track(event: "trial_expired", parameters: [
                "days_used": daysSinceStart,
                "trial_type": "\(trialType)"
            ])
        } else {
            isTrialActive = true
            trialDaysRemaining = maxDays - daysSinceStart
        }
    }
    
    private func getMaxGenerations(for type: TrialType) -> Int {
        switch type {
        case .none: return 0
        case .limited: return 3
        case .unlimited: return 999
        case .freemium: return 1
        }
    }
    
    private func getMaxDays(for type: TrialType) -> Int {
        switch type {
        case .none: return 0
        case .limited: return 7
        case .unlimited: return 3
        case .freemium: return 999 // Ongoing
        }
    }
    
    private func canGenerateToday() -> Bool {
        // For freemium, check if user has generated today
        let today = Calendar.current.startOfDay(for: Date())
        let lastGenerationDate = UserDefaults.standard.object(forKey: "lastGenerationDate") as? Date
        
        if let lastDate = lastGenerationDate {
            let lastGenerationDay = Calendar.current.startOfDay(for: lastDate)
            return today > lastGenerationDay
        }
        
        return true
    }
    
    func resetDailyLimit() {
        UserDefaults.standard.set(Date(), forKey: "lastGenerationDate")
        canGenerate = true
    }
}

// MARK: - Trial Status

enum TrialStatus {
    case inactive
    case active
    case limitReached
    case expired
    
    var description: String {
        switch self {
        case .inactive:
            return "No active trial"
        case .active:
            return "Trial active"
        case .limitReached:
            return "Generation limit reached"
        case .expired:
            return "Trial expired"
        }
    }
}

// MARK: - Trial Data Extension

extension TrialData {
    var isExpired: Bool {
        let daysSinceStart = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        return daysSinceStart >= 7 // 7 days max
    }
    
    var daysRemaining: Int {
        let daysSinceStart = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        return max(0, 7 - daysSinceStart)
    }
}
