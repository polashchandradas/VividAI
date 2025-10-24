import Foundation
import UIKit
import SwiftUI
import Combine
import os.log
import CoreFoundation
import CoreGraphics
import CoreData

class LoggingService: ObservableObject {
    static let shared = LoggingService()
    
    @Published var logLevel: LogLevel = .info
    @Published var isLoggingEnabled = true
    
    private let logger = Logger(subsystem: "VividAI", category: "LoggingService")
    private var logEntries: [LogEntry] = []
    
    private init() {
        setupLogging()
    }
    
    // MARK: - Setup
    
    private func setupLogging() {
        // Configure logging based on build configuration
        #if DEBUG
        logLevel = .debug
        #else
        logLevel = .info
        #endif
    }
    
    // MARK: - Logging Methods
    
    func logDebug(_ message: String, context: [String: Any] = [:]) {
        log(message: message, level: .debug, context: context)
    }
    
    func logInfo(_ message: String, context: [String: Any] = [:]) {
        log(message: message, level: .info, context: context)
    }
    
    func logWarning(_ message: String, context: [String: Any] = [:]) {
        log(message: message, level: .warning, context: context)
    }
    
    func logError(_ error: Error, context: [String: Any] = [:]) {
        log(message: error.localizedDescription, level: .error, context: context)
    }
    
    func logCritical(_ message: String, context: [String: Any] = [:]) {
        log(message: message, level: .critical, context: context)
    }
    
    private func log(message: String, level: LogLevel, context: [String: Any]) {
        guard isLoggingEnabled && level.rawValue >= logLevel.rawValue else { return }
        
        let logEntry = LogEntry(
            message: message,
            level: level,
            context: context,
            timestamp: Date()
        )
        
        logEntries.append(logEntry)
        
        // Keep only last 1000 entries
        if logEntries.count > 1000 {
            logEntries.removeFirst()
        }
        
        // Log to system logger
        switch level {
        case .debug:
            logger.debug("\(message)")
        case .info:
            logger.info("\(message)")
        case .warning:
            logger.warning("\(message)")
        case .error:
            logger.error("\(message)")
        case .critical:
            logger.critical("\(message)")
        }
        
        // Log to console for debugging
        print("📱 [\(level.rawValue.uppercased())] \(message)")
        if !context.isEmpty {
            print("📋 Context: \(context)")
        }
    }
    
    // MARK: - App Lifecycle Logging
    
    func logAppLaunch() {
        logInfo("App launched", context: [
            "timestamp": Date().timeIntervalSince1970,
            "version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        ])
    }
    
    func logAppTermination() {
        logInfo("App terminated", context: [
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    func logAppBecameActive() {
        logInfo("App became active")
    }
    
    func logAppWillResignActive() {
        logInfo("App will resign active")
    }
    
    // MARK: - Feature Logging
    
    func logFeatureUsage(_ feature: String, context: [String: Any] = [:]) {
        logInfo("Feature used: \(feature)", context: context)
    }
    
    func logUserAction(_ action: String, context: [String: Any] = [:]) {
        logInfo("User action: \(action)", context: context)
    }
    
    func logPerformanceMetric(_ metric: String, value: Double, context: [String: Any] = [:]) {
        logInfo("Performance metric: \(metric) = \(value)", context: context)
    }
    
    // MARK: - Error Logging
    
    func logError(_ error: Error, context: [String: Any] = [:]) {
        logError(error, context: context)
    }
    
    func logNetworkError(_ error: Error, url: String, context: [String: Any] = [:]) {
        logError("Network error: \(error.localizedDescription)", context: [
            "url": url,
            "error": error.localizedDescription
        ] + context)
    }
    
    func logAPIError(_ error: Error, endpoint: String, context: [String: Any] = [:]) {
        logError("API error: \(error.localizedDescription)", context: [
            "endpoint": endpoint,
            "error": error.localizedDescription
        ] + context)
    }
    
    // MARK: - Log Management
    
    func getLogEntries(level: LogLevel? = nil, limit: Int = 100) -> [LogEntry] {
        let filteredEntries = level != nil ? logEntries.filter { $0.level == level } : logEntries
        return Array(filteredEntries.suffix(limit))
    }
    
    func clearLogs() {
        logEntries.removeAll()
        logInfo("Logs cleared")
    }
    
    func exportLogs() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        
        let logText = logEntries.map { entry in
            let timestamp = formatter.string(from: entry.timestamp)
            let contextString = entry.context.isEmpty ? "" : " | Context: \(entry.context)"
            return "[\(timestamp)] [\(entry.level.rawValue.uppercased())] \(entry.message)\(contextString)"
        }.joined(separator: "\n")
        
        return logText
    }
    
    // MARK: - Log Analysis
    
    func getLogStatistics() -> LogStatistics {
        let totalLogs = logEntries.count
        let debugLogs = logEntries.filter { $0.level == .debug }.count
        let infoLogs = logEntries.filter { $0.level == .info }.count
        let warningLogs = logEntries.filter { $0.level == .warning }.count
        let errorLogs = logEntries.filter { $0.level == .error }.count
        let criticalLogs = logEntries.filter { $0.level == .critical }.count
        
        return LogStatistics(
            totalLogs: totalLogs,
            debugLogs: debugLogs,
            infoLogs: infoLogs,
            warningLogs: warningLogs,
            errorLogs: errorLogs,
            criticalLogs: criticalLogs
        )
    }
    
    func getErrorRate() -> Double {
        let totalLogs = logEntries.count
        guard totalLogs > 0 else { return 0 }
        
        let errorLogs = logEntries.filter { $0.level == .error || $0.level == .critical }.count
        return Double(errorLogs) / Double(totalLogs)
    }
    
    func getMostCommonErrors() -> [String: Int] {
        let errorEntries = logEntries.filter { $0.level == .error || $0.level == .critical }
        var errorCounts: [String: Int] = [:]
        
        for entry in errorEntries {
            errorCounts[entry.message, default: 0] += 1
        }
        
        return errorCounts
    }
}

// MARK: - Data Models

struct LogEntry: Identifiable {
    let id = UUID()
    let message: String
    let level: LogLevel
    let context: [String: Any]
    let timestamp: Date
}

enum LogLevel: Int, CaseIterable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3
    case critical = 4
    
    var rawValue: String {
        switch self {
        case .debug: return "debug"
        case .info: return "info"
        case .warning: return "warning"
        case .error: return "error"
        case .critical: return "critical"
        }
    }
}

struct LogStatistics {
    let totalLogs: Int
    let debugLogs: Int
    let infoLogs: Int
    let warningLogs: Int
    let errorLogs: Int
    let criticalLogs: Int
    
    var hasErrors: Bool {
        return errorLogs > 0 || criticalLogs > 0
    }
    
    var errorRate: Double {
        guard totalLogs > 0 else { return 0 }
        return Double(errorLogs + criticalLogs) / Double(totalLogs)
    }
}