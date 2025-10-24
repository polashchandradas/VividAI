import Foundation
import SwiftUI
import os.log
import UIKit
import Combine
import CoreFoundation
import CoreGraphics
import CoreData
import CoreImage

// MARK: - Logging Service

class LoggingService: ObservableObject {
    static let shared = LoggingService()
    
    @Published var logEntries: [LogEntry] = []
    @Published var isLoggingEnabled = true
    @Published var logLevel: LogLevel = .info
    
    private let logger = Logger(subsystem: "com.vividai.app", category: "general")
    private let maxLogEntries = 1000
    
    private init() {
        loadLoggingSettings()
    }
    
    // MARK: - Logging Methods
    
    func log(_ message: String, level: LogLevel = .info, category: LogCategory = .general, context: [String: Any] = [:]) {
        guard isLoggingEnabled && level.rawValue >= logLevel.rawValue else { return }
        
        let entry = LogEntry(
            message: message,
            level: level,
            category: category,
            context: context,
            timestamp: Date()
        )
        
        DispatchQueue.main.async {
            self.logEntries.append(entry)
            
            // Keep only the most recent entries
            if self.logEntries.count > self.maxLogEntries {
                self.logEntries.removeFirst(self.logEntries.count - self.maxLogEntries)
            }
        }
        
        // Log to system logger
        logToSystemLogger(entry)
        
        // Log to console for debugging
        print("📝 [\(level.rawValue.uppercased())] [\(category.rawValue)] \(message)")
    }
    
    func logError(_ error: Error, context: [String: Any] = [:]) {
        log("Error: \(error.localizedDescription)", level: .error, category: .error, context: context)
    }
    
    func logWarning(_ message: String, context: [String: Any] = [:]) {
        log(message, level: .warning, category: .warning, context: context)
    }
    
    func logInfo(_ message: String, context: [String: Any] = [:]) {
        log(message, level: .info, category: .info, context: context)
    }
    
    func logDebug(_ message: String, context: [String: Any] = [:]) {
        log(message, level: .debug, category: .debug, context: context)
    }
    
    func logPerformance(_ operation: String, duration: TimeInterval, context: [String: Any] = [:]) {
        var performanceContext = context
        performanceContext["duration"] = duration
        performanceContext["operation"] = operation
        
        log("Performance: \(operation) took \(String(format: "%.2f", duration))s", 
            level: .info, 
            category: .performance, 
            context: performanceContext)
    }
    
    func logUserAction(_ action: String, context: [String: Any] = [:]) {
        var userContext = context
        userContext["action"] = action
        
        log("User Action: \(action)", level: .info, category: .userAction, context: userContext)
    }
    
    func logAPIRequest(_ endpoint: String, method: String, context: [String: Any] = [:]) {
        var apiContext = context
        apiContext["endpoint"] = endpoint
        apiContext["method"] = method
        
        log("API Request: \(method) \(endpoint)", level: .info, category: .api, context: apiContext)
    }
    
    func logAPIResponse(_ endpoint: String, statusCode: Int, duration: TimeInterval, context: [String: Any] = [:]) {
        var apiContext = context
        apiContext["endpoint"] = endpoint
        apiContext["status_code"] = statusCode
        apiContext["duration"] = duration
        
        log("API Response: \(endpoint) - \(statusCode) (\(String(format: "%.2f", duration))s)", 
            level: .info, 
            category: .api, 
            context: apiContext)
    }
    
    // MARK: - System Logger Integration
    
    private func logToSystemLogger(_ entry: LogEntry) {
        let message = "\(entry.category.rawValue): \(entry.message)"
        
        switch entry.level {
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
    }
    
    // MARK: - Log Management
    
    func clearLogs() {
        DispatchQueue.main.async {
            self.logEntries.removeAll()
        }
    }
    
    func exportLogs() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        
        return logEntries.map { entry in
            let timestamp = formatter.string(from: entry.timestamp)
            let contextString = entry.context.isEmpty ? "" : " | Context: \(entry.context)"
            return "[\(timestamp)] [\(entry.level.rawValue.uppercased())] [\(entry.category.rawValue)] \(entry.message)\(contextString)"
        }.joined(separator: "\n")
    }
    
    func getLogStatistics() -> LogStatistics {
        let totalLogs = logEntries.count
        let errorLogs = logEntries.filter { $0.level == .error || $0.level == .critical }.count
        let warningLogs = logEntries.filter { $0.level == .warning }.count
        let infoLogs = logEntries.filter { $0.level == .info }.count
        let debugLogs = logEntries.filter { $0.level == .debug }.count
        
        return LogStatistics(
            totalLogs: totalLogs,
            errorLogs: errorLogs,
            warningLogs: warningLogs,
            infoLogs: infoLogs,
            debugLogs: debugLogs
        )
    }
    
    // MARK: - Settings
    
    func setLogLevel(_ level: LogLevel) {
        logLevel = level
        saveLoggingSettings()
    }
    
    func toggleLogging() {
        isLoggingEnabled.toggle()
        saveLoggingSettings()
    }
    
    private func loadLoggingSettings() {
        isLoggingEnabled = UserDefaults.standard.bool(forKey: "logging_enabled")
        if let levelString = UserDefaults.standard.string(forKey: "log_level"),
           let level = LogLevel(rawValue: levelString) {
            logLevel = level
        }
    }
    
    private func saveLoggingSettings() {
        UserDefaults.standard.set(isLoggingEnabled, forKey: "logging_enabled")
        UserDefaults.standard.set(logLevel.rawValue, forKey: "log_level")
    }
}

// MARK: - Data Models

struct LogEntry: Identifiable {
    let id = UUID()
    let message: String
    let level: LogLevel
    let category: LogCategory
    let context: [String: Any]
    let timestamp: Date
    
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter.string(from: timestamp)
    }
}

enum LogLevel: String, CaseIterable {
    case debug = "debug"
    case info = "info"
    case warning = "warning"
    case error = "error"
    case critical = "critical"
    
    var rawValue: Int {
        switch self {
        case .debug: return 0
        case .info: return 1
        case .warning: return 2
        case .error: return 3
        case .critical: return 4
        }
    }
    
    var color: Color {
        switch self {
        case .debug: return .blue
        case .info: return .green
        case .warning: return .orange
        case .error: return .red
        case .critical: return .red
        }
    }
}

enum LogCategory: String, CaseIterable {
    case general = "general"
    case error = "error"
    case warning = "warning"
    case info = "info"
    case debug = "debug"
    case performance = "performance"
    case userAction = "user_action"
    case api = "api"
    case security = "security"
    case analytics = "analytics"
}

struct LogStatistics {
    let totalLogs: Int
    let errorLogs: Int
    let warningLogs: Int
    let infoLogs: Int
    let debugLogs: Int
    
    var errorRate: Double {
        guard totalLogs > 0 else { return 0 }
        return Double(errorLogs) / Double(totalLogs)
    }
    
    var warningRate: Double {
        guard totalLogs > 0 else { return 0 }
        return Double(warningLogs) / Double(totalLogs)
    }
}

// MARK: - Logging Extensions

extension LoggingService {
    func logAppLaunch() {
        logInfo("App launched", context: [
            "version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            "build": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
        ])
    }
    
    func logAppTermination() {
        logInfo("App terminated")
    }
    
    func logScreenView(_ screenName: String) {
        logUserAction("Screen viewed", context: ["screen": screenName])
    }
    
    func logButtonTap(_ buttonName: String, screen: String) {
        logUserAction("Button tapped", context: [
            "button": buttonName,
            "screen": screen
        ])
    }
    
    func logFeatureUsage(_ feature: String, context: [String: Any] = [:]) {
        logUserAction("Feature used", context: [
            "feature": feature,
            "context": context
        ])
    }
}

// MARK: - Logging View

struct LoggingView: View {
    @ObservedObject var loggingService = LoggingService.shared
    @State private var selectedLevel: LogLevel = .info
    @State private var selectedCategory: LogCategory = .general
    @State private var showingExportSheet = false
    
    var filteredLogs: [LogEntry] {
        loggingService.logEntries.filter { entry in
            entry.level.rawValue >= selectedLevel.rawValue &&
            (selectedCategory == .general || entry.category == selectedCategory)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Filters
                filterSection
                
                // Logs List
                logsList
            }
            .navigationTitle("Logs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Export Logs") {
                            showingExportSheet = true
                        }
                        Button("Clear Logs") {
                            loggingService.clearLogs()
                        }
                        Button(loggingService.isLoggingEnabled ? "Disable Logging" : "Enable Logging") {
                            loggingService.toggleLogging()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingExportSheet) {
            LogExportView(logs: loggingService.exportLogs())
        }
    }
    
    private var filterSection: some View {
        VStack {
            HStack {
                Text("Level:")
                Picker("Level", selection: $selectedLevel) {
                    ForEach(LogLevel.allCases, id: \.self) { level in
                        Text(level.rawValue.capitalized).tag(level)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                Spacer()
            }
            
            HStack {
                Text("Category:")
                Picker("Category", selection: $selectedCategory) {
                    ForEach(LogCategory.allCases, id: \.self) { category in
                        Text(category.rawValue.capitalized).tag(category)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    private var logsList: some View {
        List(filteredLogs.reversed()) { entry in
            LogEntryView(entry: entry)
        }
    }
}

struct LogEntryView: View {
    let entry: LogEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entry.formattedTimestamp)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(entry.level.rawValue.uppercased())
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(entry.level.color)
            }
            
            Text(entry.message)
                .font(.body)
            
            if !entry.context.isEmpty {
                Text("Context: \(entry.context.description)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

struct LogExportView: View {
    let logs: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                Text(logs)
                    .font(.system(.caption, design: .monospaced))
                    .padding()
            }
            .navigationTitle("Exported Logs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
