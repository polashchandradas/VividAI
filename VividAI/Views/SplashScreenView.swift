import SwiftUI
import UIKit

struct SplashScreenView: View {
    @State private var size = 0.8
    @State private var opacity = 0.5
    @EnvironmentObject var serviceContainer: ServiceContainer
    
    var body: some View {
        ZStack {
            // Modern gradient background
            DesignSystem.Colors.gradientPrimary
                .ignoresSafeArea()
            
            // Subtle overlay for depth
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.clear,
                    Color.black.opacity(0.1)
                ]),
                center: .center,
                startRadius: 100,
                endRadius: 300
            )
            .ignoresSafeArea()
            
            VStack(spacing: DesignSystem.Spacing.lg) {
                // App Logo with modern styling
                Image(systemName: "camera.aperture")
                    .font(.system(size: 80, weight: .light))
                    .foregroundColor(.white)
                    .scaleEffect(size)
                    .opacity(opacity)
                    .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
                
                // App Name with modern typography
                Text("VividAI")
                    .font(DesignSystem.Typography.h1)
                    .foregroundColor(.white)
                    .scaleEffect(size)
                    .opacity(opacity)
                    .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                
                // Tagline with modern styling
                Text("Transform Your Photos with AI")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(.white.opacity(0.9))
                    .scaleEffect(size)
                    .opacity(opacity)
                    .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 1)
            }
        }
        .onAppear {
            withAnimation(DesignSystem.Animations.slow) {
                self.size = 0.9
                self.opacity = 1.0
            }
        }
        .onAppear {
            // Load CoreML models during splash
            loadCoreMLModels()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(DesignSystem.Animations.standard) {
                    // Check centralized authentication status and navigate accordingly
                    if serviceContainer.authenticationService.isAuthenticated {
                        serviceContainer.navigationCoordinator.navigateTo(.home)
                    } else {
                        serviceContainer.navigationCoordinator.navigateTo(.authentication)
                    }
                }
            }
        }
    }
    
    private func loadCoreMLModels() {
        // Initialize CoreML models in background
        DispatchQueue.global(qos: .background).async {
            // Load background removal model
            serviceContainer.backgroundRemovalService.loadModel()
            
            // Load photo enhancement model
            serviceContainer.photoEnhancementService.loadModel()
            
            serviceContainer.analyticsService.track(event: "splash_screen_displayed")
        }
    }
}

#Preview {
    SplashScreenView()
        .environmentObject(ServiceContainer.shared)
}
