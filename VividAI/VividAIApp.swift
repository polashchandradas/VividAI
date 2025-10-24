import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseAnalytics

@main
struct VividAIApp: App {
    @StateObject private var appCoordinator = AppCoordinator()
    @State private var isFirebaseConfigured = false
    @State private var configurationError: String?
    
    init() {
        configureFirebase()
    }
    
    var body: some Scene {
        WindowGroup {
            if let error = configurationError {
                ErrorView(error: error)
            } else {
                   MainAppView()
                       .environmentObject(appCoordinator)
                       .environmentObject(appCoordinator.navigationCoordinator)
                       .environmentObject(appCoordinator.subscriptionManager)
                       .environmentObject(appCoordinator.analyticsService)
                       .environmentObject(appCoordinator.errorHandlingService)
                       .errorHandling()
                    .onAppear {
                        appCoordinator.handleAppBecameActive()
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                        appCoordinator.handleAppWillResignActive()
                    }
            }
        }
    }
    
    private func configureFirebase() {
        // Check if Firebase is properly configured
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let apiKey = plist["API_KEY"] as? String,
              let googleAppId = plist["GOOGLE_APP_ID"] as? String,
              apiKey != "YOUR_FIREBASE_API_KEY",
              googleAppId != "YOUR_GOOGLE_APP_ID" else {
            configurationError = "Firebase configuration is incomplete. Please update GoogleService-Info.plist with your actual Firebase credentials."
            return
        }
        
        // Configure Firebase
        FirebaseApp.configure()
        
        // Initialize Firebase services
        _ = Auth.auth()
        _ = Firestore.firestore()
        _ = Analytics.self
        
        isFirebaseConfigured = true
    }
}

// MARK: - Error View
struct ErrorView: View {
    let error: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("Configuration Error")
                .font(.title)
                .fontWeight(.bold)
            
            Text(error)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Retry") {
                // Restart app to retry configuration
                exit(0)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
