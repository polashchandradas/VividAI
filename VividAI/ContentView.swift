import SwiftUI

struct ContentView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var analyticsService: AnalyticsService
    
    var body: some View {
        NavigationView {
            HomeView()
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

#Preview {
    ContentView()
        .environmentObject(SubscriptionManager())
        .environmentObject(AnalyticsService())
}
