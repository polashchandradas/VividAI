import SwiftUI
import AuthenticationServices
import FirebaseAuth

struct AuthenticationView: View {
    @EnvironmentObject var serviceContainer: ServiceContainer
    @State private var selectedTab: AuthTab = .signIn
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.xl) {
                        // Header
                        headerSection
                        
                        // Tab Selector
                        tabSelectorSection
                        
                        // Content
                        contentSection
                        
                        // Social Sign In
                        socialSignInSection
                        
                        // Footer
                        footerSection
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.top, DesignSystem.Spacing.xl)
                }
            }
            .navigationBarHidden(true)
        }
        .alert("Authentication Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .onReceive(serviceContainer.authenticationService.$errorMessage) { errorMessage in
            if let error = errorMessage {
                alertMessage = error
                showingAlert = true
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Logo
            Image(systemName: "camera.aperture")
                .font(.system(size: 60, weight: .light))
                .foregroundColor(DesignSystem.Colors.primary)
            
            // Title
            Text("Welcome to VividAI")
                .font(DesignSystem.Typography.h2)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .multilineTextAlignment(.center)
            
            // Subtitle
            Text("Create professional AI headshots in seconds")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var tabSelectorSection: some View {
        HStack(spacing: 0) {
            Button(action: { selectedTab = .signIn }) {
                Text("Sign In")
                    .font(DesignSystem.Typography.button)
                    .foregroundColor(selectedTab == .signIn ? DesignSystem.Colors.primary : DesignSystem.Colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: DesignSystem.Heights.button)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                            .fill(selectedTab == .signIn ? DesignSystem.Colors.primary.opacity(0.1) : Color.clear)
                    )
            }
            
            Button(action: { selectedTab = .signUp }) {
                Text("Sign Up")
                    .font(DesignSystem.Typography.button)
                    .foregroundColor(selectedTab == .signUp ? DesignSystem.Colors.primary : DesignSystem.Colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: DesignSystem.Heights.button)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                            .fill(selectedTab == .signUp ? DesignSystem.Colors.primary.opacity(0.1) : Color.clear)
                    )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .fill(DesignSystem.Colors.neutral)
        )
    }
    
    private var contentSection: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            if selectedTab == .signIn {
                SignInForm()
            } else {
                SignUpForm()
            }
        }
    }
    
    private var socialSignInSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Divider
            HStack {
                Rectangle()
                    .fill(DesignSystem.Colors.neutralDark)
                    .frame(height: 1)
                
                Text("or continue with")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                
                Rectangle()
                    .fill(DesignSystem.Colors.neutralDark)
                    .frame(height: 1)
            }
            
            // Social Buttons
            VStack(spacing: DesignSystem.Spacing.md) {
                // Apple Sign In
                SignInWithAppleButton(
                    onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                        request.nonce = serviceContainer.authenticationService.generateNonce()
                    },
                    onCompletion: { result in
                        handleAppleSignIn(result)
                    }
                )
                .signInWithAppleButtonStyle(.black)
                .frame(height: DesignSystem.Heights.button)
                .cornerRadius(DesignSystem.CornerRadius.md)
                
                // Google Sign In
                Button(action: {
                    handleGoogleSignIn()
                }) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "globe")
                            .font(.system(size: DesignSystem.IconSizes.small, weight: .semibold))
                        
                        Text("Continue with Google")
                            .font(DesignSystem.Typography.button)
                    }
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: DesignSystem.Heights.button)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                            .stroke(DesignSystem.Colors.neutralDark, lineWidth: 1)
                    )
                    .cornerRadius(DesignSystem.CornerRadius.md)
                }
            }
        }
    }
    
    private var footerSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Text("By continuing, you agree to our")
                .font(DesignSystem.Typography.small)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            HStack(spacing: DesignSystem.Spacing.sm) {
                Button("Terms of Service") {
                    // Open terms
                }
                .font(DesignSystem.Typography.small)
                .foregroundColor(DesignSystem.Colors.primary)
                
                Text("and")
                    .font(DesignSystem.Typography.small)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Button("Privacy Policy") {
                    // Open privacy policy
                }
                .font(DesignSystem.Typography.small)
                .foregroundColor(DesignSystem.Colors.primary)
            }
        }
    }
    
    // MARK: - Authentication Handlers
    
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                Task {
                    do {
                        _ = try await serviceContainer.authenticationService.signInWithApple(credential: appleIDCredential)
                        serviceContainer.navigationCoordinator.navigateTo(.home)
                    } catch {
                        // Error is handled by the service
                    }
                }
            }
        case .failure(let error):
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }
    
    private func handleGoogleSignIn() {
        // This would integrate with Google Sign-In SDK
        // For now, we'll show a placeholder
        alertMessage = "Google Sign-In integration coming soon"
        showingAlert = true
    }
}

// MARK: - Sign In Form

struct SignInForm: View {
    @EnvironmentObject var serviceContainer: ServiceContainer
    @State private var email = ""
    @State private var password = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Email Field
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text("Email")
                    .font(DesignSystem.Typography.captionBold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                TextField("Enter your email", text: $email)
                    .textFieldStyle(ModernTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            
            // Password Field
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text("Password")
                    .font(DesignSystem.Typography.captionBold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                SecureField("Enter your password", text: $password)
                    .textFieldStyle(ModernTextFieldStyle())
            }
            
            // Forgot Password
            HStack {
                Spacer()
                Button("Forgot Password?") {
                    handleForgotPassword()
                }
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.primary)
            }
            
            // Sign In Button
            Button(action: {
                handleSignIn()
            }) {
                HStack {
                    if serviceContainer.authenticationService.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text("Sign In")
                            .font(DesignSystem.Typography.button)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: DesignSystem.Heights.button)
                .background(DesignSystem.Colors.primary)
                .cornerRadius(DesignSystem.CornerRadius.md)
            }
            .disabled(serviceContainer.authenticationService.isLoading || email.isEmpty || password.isEmpty)
        }
        .alert("Authentication Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func handleSignIn() {
        Task {
            do {
                _ = try await serviceContainer.authenticationService.signIn(email: email, password: password)
                serviceContainer.navigationCoordinator.navigateTo(.home)
            } catch {
                alertMessage = error.localizedDescription
                showingAlert = true
            }
        }
    }
    
    private func handleForgotPassword() {
        Task {
            do {
                try await serviceContainer.authenticationService.resetPassword(email: email)
                alertMessage = "Password reset email sent to \(email)"
                showingAlert = true
            } catch {
                alertMessage = error.localizedDescription
                showingAlert = true
            }
        }
    }
}

// MARK: - Sign Up Form

struct SignUpForm: View {
    @EnvironmentObject var serviceContainer: ServiceContainer
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Full Name Field
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text("Full Name")
                    .font(DesignSystem.Typography.captionBold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                TextField("Enter your full name", text: $fullName)
                    .textFieldStyle(ModernTextFieldStyle())
                    .autocapitalization(.words)
            }
            
            // Email Field
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text("Email")
                    .font(DesignSystem.Typography.captionBold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                TextField("Enter your email", text: $email)
                    .textFieldStyle(ModernTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            
            // Password Field
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text("Password")
                    .font(DesignSystem.Typography.captionBold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                SecureField("Enter your password", text: $password)
                    .textFieldStyle(ModernTextFieldStyle())
            }
            
            // Confirm Password Field
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text("Confirm Password")
                    .font(DesignSystem.Typography.captionBold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                SecureField("Confirm your password", text: $confirmPassword)
                    .textFieldStyle(ModernTextFieldStyle())
            }
            
            // Sign Up Button
            Button(action: {
                handleSignUp()
            }) {
                HStack {
                    if serviceContainer.authenticationService.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text("Create Account")
                            .font(DesignSystem.Typography.button)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: DesignSystem.Heights.button)
                .background(DesignSystem.Colors.primary)
                .cornerRadius(DesignSystem.CornerRadius.md)
            }
            .disabled(serviceContainer.authenticationService.isLoading || !isFormValid)
        }
        .alert("Authentication Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var isFormValid: Bool {
        return !fullName.isEmpty &&
               !email.isEmpty &&
               !password.isEmpty &&
               !confirmPassword.isEmpty &&
               password == confirmPassword &&
               password.count >= 6
    }
    
    private func handleSignUp() {
        guard password == confirmPassword else {
            alertMessage = "Passwords do not match"
            showingAlert = true
            return
        }
        
        guard password.count >= 6 else {
            alertMessage = "Password must be at least 6 characters"
            showingAlert = true
            return
        }
        
        Task {
            do {
                _ = try await serviceContainer.authenticationService.signUp(email: email, password: password, fullName: fullName)
                serviceContainer.navigationCoordinator.navigateTo(.home)
            } catch {
                alertMessage = error.localizedDescription
                showingAlert = true
            }
        }
    }
}

// MARK: - Supporting Types

enum AuthTab {
    case signIn
    case signUp
}

struct ModernTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(DesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .fill(DesignSystem.Colors.neutral)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                            .stroke(DesignSystem.Colors.neutralDark, lineWidth: 1)
                    )
            )
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(ServiceContainer.shared)
}
