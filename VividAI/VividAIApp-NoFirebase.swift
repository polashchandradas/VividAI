import SwiftUI

@main
struct VividAIApp: App {
    @StateObject private var subscriptionManager = SubscriptionManager()
    @StateObject private var analyticsService = AnalyticsService()
    
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
