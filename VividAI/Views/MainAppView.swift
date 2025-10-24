import SwiftUI
import UIKit

struct MainAppView: View {
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    @EnvironmentObject var appCoordinator: AppCoordinator
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemBackground)
                .ignoresSafeArea()
            
            // Main Content
            Group {
                switch navigationCoordinator.currentView {
                case .splash:
                    SplashScreenView()
                case .home:
                    HomeView()
                case .photoUpload:
                    PhotoUploadView()
                case .processing:
                    ProcessingView()
                case .results:
                    ResultsView()
                case .paywall:
                    PaywallView()
                case .share:
                    ShareView()
                case .settings:
                    SettingsView()
                }
            }
            .animation(.easeInOut(duration: 0.3), value: navigationCoordinator.currentView)
        }
        .onAppear {
            // Initialize app state
            appCoordinator.handleAppBecameActive()
        }
    }
}

#Preview {
    MainAppView()
        .environmentObject(NavigationCoordinator())
        .environmentObject(AppCoordinator())
}