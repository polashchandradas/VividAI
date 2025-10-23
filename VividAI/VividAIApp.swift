import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseAnalytics

@main
struct VividAIApp: App {
    @StateObject private var subscriptionManager = SubscriptionManager()
    @StateObject private var analyticsService = AnalyticsService()
    
    init() {
        // Configure Firebase
        FirebaseApp.configure()
        
        // Initialize analytics
        AnalyticsService.shared = analyticsService
    }
    
    var body: some Scene {
        WindowGroup {
            SplashScreenView()
                .environmentObject(subscriptionManager)
                .environmentObject(analyticsService)
                .onAppear {
                    analyticsService.track(event: "app_launched")
                }
        }
    }
}
