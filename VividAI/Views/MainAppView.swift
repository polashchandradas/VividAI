import SwiftUI
import UIKit

struct MainAppView: View {
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    @EnvironmentObject var appCoordinator: AppCoordinator
    
    var body: some View {
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
        .environmentObject(navigationCoordinator)
        .environmentObject(appCoordinator)
    }
}

#Preview {
    MainAppView()
        .environmentObject(NavigationCoordinator())
        .environmentObject(AppCoordinator())
}