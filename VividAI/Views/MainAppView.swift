import SwiftUI
import UIKit

struct MainAppView: View {
    @EnvironmentObject var unifiedState: UnifiedAppStateManager
    
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
                QualitySelectionView(selectedImage: $navigationCoordinator.selectedImage)
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
}