import SwiftUI

struct MainAppView: View {
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    @EnvironmentObject var appCoordinator: AppCoordinator
    
    var body: some View {
        ZStack {
            // Main content based on current view
            currentView
            
            // Error overlay
            if navigationCoordinator.showingError {
                ErrorOverlay(
                    message: navigationCoordinator.errorMessage ?? "An error occurred",
                    onDismiss: {
                        navigationCoordinator.clearError()
                    }
                )
            }
        }
        .animation(.easeInOut(duration: 0.3), value: navigationCoordinator.currentView)
    }
    
    @ViewBuilder
    private var currentView: some View {
        switch navigationCoordinator.currentView {
        case .splash:
            SplashScreenView()
                .transition(.opacity)
                
        case .home:
            HomeView()
                .transition(.slide)
                
        case .photoUpload:
            PhotoUploadView()
                .transition(.slide)
                
        case .processing:
            ProcessingView()
                .transition(.slide)
                
        case .results:
            ResultsView()
                .transition(.slide)
                
        case .paywall:
            PaywallView()
                .transition(.slide)
                
        case .share:
            ShareView()
                .transition(.slide)
                
        case .settings:
            SettingsView()
                .transition(.slide)
        }
    }
}

// MARK: - Error Overlay

struct ErrorOverlay: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.red)
                
                Text("Error")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(message)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button("OK") {
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(30)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 10)
            .padding(.horizontal, 40)
        }
    }
}

#Preview {
    MainAppView()
        .environmentObject(NavigationCoordinator())
        .environmentObject(AppCoordinator())
}
