import SwiftUI
import UIKit

struct MainAppView: View {
    @EnvironmentObject var unifiedState: UnifiedAppStateManager
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    
    var body: some View {
        Group {
            switch unifiedState.currentView {
            case .splash:
                SplashScreenView()
            case .authentication:
                AuthenticationView()
            case .home:
                HomeView()
            case .photoUpload:
                PhotoUploadView()
            case .qualitySelection:
                QualitySelectionView(selectedImage: Binding(
                    get: { navigationCoordinator.selectedImage },
                    set: { navigationCoordinator.selectedImage = $0 }
                ))
            case .realTimePreview:
                RealTimePreviewView()
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
        .environmentObject(unifiedState)
    }
}

#Preview {
    MainAppView()
        .environmentObject(UnifiedAppStateManager.shared)
        .environmentObject(NavigationCoordinator())
}