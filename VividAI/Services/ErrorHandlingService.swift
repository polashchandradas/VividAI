import Foundation
import SwiftUI
import Combine

// MARK: - Error Types

enum AppError: Error, LocalizedError, Identifiable {
    case networkError(String)
    case apiError(String)
    case imageProcessingError(String)
    case cameraError(String)
    case permissionError(String)
    case subscriptionError(String)
    case configurationError(String)
    case unknownError(String)
    
    var id: String {
        return "\(self)"
    }
    
    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Network Error: \(message)"
        case .apiError(let message):
            return "API Error: \(message)"
        case .imageProcessingError(let message):
            return "Image Processing Error: \(message)"
        case .cameraError(let message):
            return "Camera Error: \(message)"
        case .permissionError(let message):
            return "Permission Error: \(message)"
        case .subscriptionError(let message):
            return "Subscription Error: \(message)"
        case .configurationError(let message):
            return "Configuration Error: \(message)"
        case .unknownError(let message):
            return "Unknown Error: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return "Please check your internet connection and try again."
        case .apiError:
            return "There was an issue with the AI service. Please try again later."
        case .imageProcessingError:
            return "There was an issue processing your image. Please try a different photo."
        case .cameraError:
            return "There was an issue with the camera. Please try again or use a photo from your gallery."
        case .permissionError:
            return "Please grant the required permissions in Settings."
        case .subscriptionError:
            return "There was an issue with your subscription. Please try again or contact support."
        case .configurationError:
            return "Please check your app configuration and try again."
        case .unknownError:
            return "An unexpected error occurred. Please try again."
        }
    }
    
    var severity: ErrorSeverity {
        switch self {
        case .networkError, .apiError:
            return .medium
        case .imageProcessingError, .cameraError:
            return .low
        case .permissionError, .subscriptionError, .configurationError:
            return .high
        case .unknownError:
            return .critical
        }
    }
}

enum ErrorSeverity {
    case low
    case medium
    case high
    case critical
    
    var color: Color {
        switch self {
        case .low:
            return .blue
        case .medium:
            return .orange
        case .high:
            return .red
        case .critical:
            return .purple
        }
    }
}

// MARK: - Error Handling Service

class ErrorHandlingService: ObservableObject {
    static let shared = ErrorHandlingService()
    
    @Published var currentError: AppError?
    @Published var errorHistory: [ErrorLogEntry] = []
    @Published var isShowingError = false
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupErrorLogging()
    }
    
    // MARK: - Error Handling Methods
    
    func handleError(_ error: Error, context: String = "", severity: ErrorSeverity? = nil) {
        let appError: AppError
        
        if let appErrorType = error as? AppError {
            appError = appErrorType
        } else {
            appError = .unknownError(error.localizedDescription)
        }
        
        // Log the error
        logError(appError, context: context, severity: severity ?? appError.severity)
        
        // Show error to user if it's significant
        if shouldShowErrorToUser(appError) {
            DispatchQueue.main.async {
                self.currentError = appError
                self.isShowingError = true
            }
        }
    }
    
    func handleNetworkError(_ error: Error, context: String = "") {
        let networkError = AppError.networkError(error.localizedDescription)
        handleError(networkError, context: context, severity: .medium)
    }
    
    func handleAPIError(_ error: Error, context: String = "") {
        let apiError = AppError.apiError(error.localizedDescription)
        handleError(apiError, context: context, severity: .medium)
    }
    
    func handleImageProcessingError(_ error: Error, context: String = "") {
        let imageError = AppError.imageProcessingError(error.localizedDescription)
        handleError(imageError, context: context, severity: .low)
    }
    
    func handleCameraError(_ error: Error, context: String = "") {
        let cameraError = AppError.cameraError(error.localizedDescription)
        handleError(cameraError, context: context, severity: .low)
    }
    
    func handlePermissionError(_ error: Error, context: String = "") {
        let permissionError = AppError.permissionError(error.localizedDescription)
        handleError(permissionError, context: context, severity: .high)
    }
    
    func handleSubscriptionError(_ error: Error, context: String = "") {
        let subscriptionError = AppError.subscriptionError(error.localizedDescription)
        handleError(subscriptionError, context: context, severity: .high)
    }
    
    func handleConfigurationError(_ error: Error, context: String = "") {
        let configError = AppError.configurationError(error.localizedDescription)
        handleError(configError, context: context, severity: .critical)
    }
    
    // MARK: - Error Recovery
    
    func dismissError() {
        DispatchQueue.main.async {
            self.currentError = nil
            self.isShowingError = false
        }
    }
    
    func retryLastOperation() {
        // This would be implemented based on the last failed operation
        // For now, just dismiss the error
        dismissError()
    }
    
    func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    // MARK: - Error Logging
    
    private func logError(_ error: AppError, context: String, severity: ErrorSeverity) {
        let logEntry = ErrorLogEntry(
            error: error,
            context: context,
            severity: severity,
            timestamp: Date()
        )
        
        DispatchQueue.main.async {
            self.errorHistory.append(logEntry)
            
            // Keep only last 100 errors
            if self.errorHistory.count > 100 {
                self.errorHistory.removeFirst()
            }
        }
        
        // Log to console for debugging
        print("🚨 Error: \(error.localizedDescription)")
        print("📍 Context: \(context)")
        print("⚠️ Severity: \(severity)")
    }
    
    private func setupErrorLogging() {
        // Set up any additional error logging mechanisms
        // This could include crash reporting, analytics, etc.
    }
    
    private func shouldShowErrorToUser(_ error: AppError) -> Bool {
        // Only show errors to user if they're significant
        switch error.severity {
        case .low:
            return false // Don't show low severity errors
        case .medium, .high, .critical:
            return true
        }
    }
    
    // MARK: - Error Analytics
    
    func getErrorStatistics() -> ErrorStatistics {
        let totalErrors = errorHistory.count
        let criticalErrors = errorHistory.filter { $0.severity == .critical }.count
        let highErrors = errorHistory.filter { $0.severity == .high }.count
        let mediumErrors = errorHistory.filter { $0.severity == .medium }.count
        let lowErrors = errorHistory.filter { $0.severity == .low }.count
        
        return ErrorStatistics(
            totalErrors: totalErrors,
            criticalErrors: criticalErrors,
            highErrors: highErrors,
            mediumErrors: mediumErrors,
            lowErrors: lowErrors
        )
    }
}

// MARK: - Data Models

struct ErrorLogEntry: Identifiable {
    let id = UUID()
    let error: AppError
    let context: String
    let severity: ErrorSeverity
    let timestamp: Date
    
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter.string(from: timestamp)
    }
}

struct ErrorStatistics {
    let totalErrors: Int
    let criticalErrors: Int
    let highErrors: Int
    let mediumErrors: Int
    let lowErrors: Int
    
    var hasErrors: Bool {
        return totalErrors > 0
    }
    
    var criticalErrorRate: Double {
        guard totalErrors > 0 else { return 0 }
        return Double(criticalErrors) / Double(totalErrors)
    }
}

// MARK: - Error View

struct ErrorView: View {
    let error: AppError
    let onRetry: (() -> Void)?
    let onDismiss: (() -> Void)?
    
    init(error: AppError, onRetry: (() -> Void)? = nil, onDismiss: (() -> Void)? = nil) {
        self.error = error
        self.onRetry = onRetry
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Error Icon
            Image(systemName: errorIcon)
                .font(.system(size: 50))
                .foregroundColor(error.severity.color)
            
            // Error Title
            Text("Something went wrong")
                .font(.title2)
                .fontWeight(.semibold)
            
            // Error Description
            Text(error.localizedDescription)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            // Recovery Suggestion
            if let suggestion = error.recoverySuggestion {
                Text(suggestion)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            
            // Action Buttons
            HStack(spacing: 16) {
                if let onRetry = onRetry {
                    Button("Try Again") {
                        onRetry()
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                Button("Dismiss") {
                    onDismiss?()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 10)
    }
    
    private var errorIcon: String {
        switch error.severity {
        case .low:
            return "exclamationmark.triangle"
        case .medium:
            return "exclamationmark.triangle.fill"
        case .high:
            return "xmark.circle.fill"
        case .critical:
            return "xmark.octagon.fill"
        }
    }
}

// MARK: - Error Alert Modifier

struct ErrorAlertModifier: ViewModifier {
    @ObservedObject var errorHandler: ErrorHandlingService
    
    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: $errorHandler.isShowingError) {
                Button("OK") {
                    errorHandler.dismissError()
                }
                if errorHandler.currentError?.severity == .high || errorHandler.currentError?.severity == .critical {
                    Button("Settings") {
                        errorHandler.openSettings()
                    }
                }
            } message: {
                if let error = errorHandler.currentError {
                    Text(error.localizedDescription)
                }
            }
    }
}

extension View {
    func errorHandling() -> some View {
        self.modifier(ErrorAlertModifier(errorHandler: ErrorHandlingService.shared))
    }
}
