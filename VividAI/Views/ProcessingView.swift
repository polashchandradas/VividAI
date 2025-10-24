import SwiftUI
import UIKit

struct ProcessingView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator
    @EnvironmentObject var analyticsService: AnalyticsService
    @State private var progress: Double = 0.0
    @State private var currentStep = 0
    @State private var processingComplete = false
    
    private let processingSteps = [
        "Analyzing your photo...",
        "Applying AI enhancement...",
        "Generating professional styles...",
        "Almost ready..."
    ]
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Processing Animation
                processingAnimationSection
                
                // Progress Section
                progressSection
                
                // Status Text
                statusTextSection
                
                Spacer()
            }
            .padding(.horizontal, 40)
        }
        .onAppear {
            startProcessing()
        }
        .onReceive(appCoordinator.$processingProgress) { newProgress in
            withAnimation(.easeInOut(duration: 0.5)) {
                self.progress = newProgress
            }
        }
        .onReceive(appCoordinator.$processingStep) { newStep in
            withAnimation(.easeInOut(duration: 0.3)) {
                if let stepIndex = processingSteps.firstIndex(of: newStep) {
                    self.currentStep = stepIndex
                }
            }
        }
    }
    
    private var processingAnimationSection: some View {
        VStack(spacing: 24) {
            // Photo Preview (blurred)
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
                .frame(width: 200, height: 200)
                .overlay(
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("Your Photo")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                )
                .blur(radius: 2)
            
            // AI Processing Animation
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 4)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blue,
                                Color.purple
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: progress)
                
                // Center Icon
                Image(systemName: "sparkles")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.blue)
                    .scaleEffect(1.0 + sin(Date().timeIntervalSince1970 * 3) * 0.1)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: progress)
            }
        }
    }
    
    private var progressSection: some View {
        VStack(spacing: 16) {
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.blue,
                                    Color.purple
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 8)
                        .animation(.easeInOut(duration: 0.5), value: progress)
                }
            }
            .frame(height: 8)
            
            // Progress Percentage
            Text("\(Int(progress * 100))% Complete")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
        }
    }
    
    private var statusTextSection: some View {
        VStack(spacing: 16) {
            // Current Step
            Text(processingSteps[currentStep])
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .animation(.easeInOut(duration: 0.3), value: currentStep)
            
            // Processing Details
            VStack(spacing: 8) {
                processingDetailRow(icon: "paintbrush.fill", text: "AI enhancement", isActive: currentStep >= 1)
                processingDetailRow(icon: "person.2.fill", text: "Generating 8 styles", isActive: currentStep >= 2)
                processingDetailRow(icon: "sparkles", text: "Almost ready...", isActive: currentStep >= 3)
            }
            
            // Estimated Time
            Text("This usually takes 10-15 seconds")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
    
    private func processingDetailRow(icon: String, text: String, isActive: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isActive ? .blue : .secondary)
                .scaleEffect(isActive ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: isActive)
            
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isActive ? .primary : .secondary)
            
            Spacer()
            
            if isActive {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.green)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isActive ? Color.blue.opacity(0.1) : Color(.systemGray6))
        )
    }
    
    private func startProcessing() {
        analyticsService.track(event: "processing_started")
        
        // The actual processing is handled by the app coordinator
        // This view just displays the progress
    }
}

#Preview {
    ProcessingView()
        .environmentObject(AnalyticsService())
}
