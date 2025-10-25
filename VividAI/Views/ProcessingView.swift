import SwiftUI
import UIKit

struct ProcessingView: View {
    @EnvironmentObject var unifiedState: UnifiedAppStateManager
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
            // Modern background
            DesignSystem.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: DesignSystem.Spacing.xl) {
                Spacer()
                
                // Processing Animation
                processingAnimationSection
                
                // Progress Section
                progressSection
                
                // Status Text
                statusTextSection
                
                Spacer()
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
        }
        .onAppear {
            startProcessing()
        }
        .onReceive(unifiedState.$processingProgress) { newProgress in
            withAnimation(DesignSystem.Animations.standard) {
                self.progress = newProgress
            }
        }
        .onReceive(unifiedState.$processingStep) { newStep in
            withAnimation(DesignSystem.Animations.standard) {
                if let stepIndex = processingSteps.firstIndex(of: newStep) {
                    self.currentStep = stepIndex
                }
            }
        }
    }
    
    private var processingAnimationSection: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            // Photo Preview (blurred)
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .fill(DesignSystem.Colors.neutral)
                .frame(width: 200, height: 200)
                .overlay(
                    VStack(spacing: DesignSystem.Spacing.md) {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 60))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        Text("Your Photo")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                )
                .blur(radius: 2)
            
            // AI Processing Animation
            ZStack {
                Circle()
                    .stroke(DesignSystem.Colors.neutralDark, lineWidth: 4)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        DesignSystem.Colors.gradientSecondary,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(DesignSystem.Animations.standard, value: progress)
                
                // Center Icon
                Image(systemName: "sparkles")
                    .font(.system(size: DesignSystem.IconSizes.large, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.primary)
                    .scaleEffect(1.0 + sin(Date().timeIntervalSince1970 * 3) * 0.1)
                    .animation(DesignSystem.Animations.standard.repeatForever(autoreverses: true), value: progress)
            }
        }
    }
    
    private var progressSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                        .fill(DesignSystem.Colors.neutralDark)
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                        .fill(DesignSystem.Colors.gradientSecondary)
                        .frame(width: geometry.size.width * progress, height: 8)
                        .animation(DesignSystem.Animations.standard, value: progress)
                }
            }
            .frame(height: 8)
            
            // Progress Percentage
            Text("\(Int(progress * 100))% Complete")
                .font(DesignSystem.Typography.captionBold)
                .foregroundColor(DesignSystem.Colors.textPrimary)
        }
    }
    
    private var statusTextSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Current Step
            Text(processingSteps[currentStep])
                .font(DesignSystem.Typography.h4)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .multilineTextAlignment(.center)
                .animation(DesignSystem.Animations.standard, value: currentStep)
            
            // Processing Details
            VStack(spacing: DesignSystem.Spacing.sm) {
                processingDetailRow(icon: "paintbrush.fill", text: "AI enhancement", isActive: currentStep >= 1)
                processingDetailRow(icon: "person.2.fill", text: "Generating 8 styles", isActive: currentStep >= 2)
                processingDetailRow(icon: "sparkles", text: "Almost ready...", isActive: currentStep >= 3)
            }
            
            // Estimated Time
            Text("This usually takes 10-15 seconds")
                .font(DesignSystem.Typography.small)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
    }
    
    private func processingDetailRow(icon: String, text: String, isActive: Bool) -> some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: DesignSystem.IconSizes.small, weight: .medium))
                .foregroundColor(isActive ? DesignSystem.Colors.primary : DesignSystem.Colors.textSecondary)
                .scaleEffect(isActive ? 1.1 : 1.0)
                .animation(DesignSystem.Animations.standard, value: isActive)
            
            Text(text)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(isActive ? DesignSystem.Colors.textPrimary : DesignSystem.Colors.textSecondary)
            
            Spacer()
            
            if isActive {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: DesignSystem.IconSizes.small))
                    .foregroundColor(DesignSystem.Colors.success)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                .fill(isActive ? DesignSystem.Colors.primary.opacity(0.1) : DesignSystem.Colors.neutral)
        )
    }
    
    private func startProcessing() {
        ServiceContainer.shared.analyticsService.track(event: "processing_started")
        
        // The actual processing is handled by the app coordinator
        // This view just displays the progress
    }
}

#Preview {
    ProcessingView()
        .environmentObject(UnifiedAppStateManager.shared)
}
