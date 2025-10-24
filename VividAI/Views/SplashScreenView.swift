import SwiftUI
import UIKit

struct SplashScreenView: View {
    @State private var size = 0.8
    @State private var opacity = 0.5
    @EnvironmentObject var analyticsService: AnalyticsService
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.42, green: 0.36, blue: 0.91), // #6C5CE7
                    Color(red: 0.04, green: 0.52, blue: 0.89)  // #0984E3
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // App Logo
                Image(systemName: "camera.aperture")
                    .font(.system(size: 80, weight: .light))
                    .foregroundColor(.white)
                    .scaleEffect(size)
                    .opacity(opacity)
                
                // App Name
                Text("VividAI")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .scaleEffect(size)
                    .opacity(opacity)
                
                // Tagline
                Text("Transform Your Photos with AI")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .scaleEffect(size)
                    .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 1.2)) {
                self.size = 0.9
                self.opacity = 1.0
            }
        }
        .onAppear {
            // Load CoreML models during splash
            loadCoreMLModels()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    self.navigationCoordinator.navigateTo(.home)
                }
            }
        }
    }
    
    private func loadCoreMLModels() {
        // Initialize CoreML models in background
        DispatchQueue.global(qos: .background).async {
            // Load background removal model
            BackgroundRemovalService.shared.loadModel()
            
            // Load photo enhancement model
            PhotoEnhancementService.shared.loadModel()
            
            analyticsService.track(event: "splash_screen_displayed")
        }
    }
}

#Preview {
    SplashScreenView()
        .environmentObject(AnalyticsService())
}
