import SwiftUI
import PhotosUI
import AVFoundation
import Vision
import CoreML

struct PhotoUploadView: View {
    @EnvironmentObject var unifiedState: UnifiedAppStateManager
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingPermissionAlert = false
    @State private var permissionAlertMessage = ""
    @State private var isDetectingFaces = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: DesignSystem.Spacing.xl) {
                    // Header
                    headerSection
                    
                    // Camera Preview or Gallery
                    imageSelectionSection
                    
                    // Action Buttons
                    actionButtonsSection
                    
                    // Tips
                    tipsSection
                    
                    Spacer()
                }
                .padding(.horizontal, DesignSystem.Spacing.card)
                .padding(.top, DesignSystem.Spacing.card)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $selectedImage)
            }
            .sheet(isPresented: $showingCamera) {
                CameraView(selectedImage: $selectedImage)
            }
            .alert("Permission Required", isPresented: $showingPermissionAlert) {
                Button("Settings") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text(permissionAlertMessage)
            }
        }
        .onAppear {
            analyticsService.track(event: "photo_upload_screen_viewed")
        }
    }
    
    private var headerSection: some View {
        HStack {
            Button(action: { 
                navigationCoordinator.navigateBack()
            }) {
                Image(systemName: "arrow.left")
                    .font(.system(size: DesignSystem.IconSizes.medium, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
            
            Spacer()
            
            Text("Upload Photo")
                .font(DesignSystem.Typography.h4)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Spacer()
            
            // Invisible spacer for balance
            Color.clear
                .frame(width: DesignSystem.IconSizes.medium, height: DesignSystem.IconSizes.medium)
        }
    }
    
    private var imageSelectionSection: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            if let selectedImage = selectedImage {
                // Selected Image Preview
                VStack(spacing: DesignSystem.Spacing.md) {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 300)
                        .cornerRadius(DesignSystem.CornerRadius.lg)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                                .stroke(DesignSystem.Colors.primary, lineWidth: 2)
                        )
                    
                    Text("Great photo!")
                        .font(DesignSystem.Typography.bodyBold)
                        .foregroundColor(DesignSystem.Colors.success)
                    
                    Button("Continue to Processing") {
                        proceedToProcessing()
                    }
                    .disabled(isDetectingFaces)
                    .font(DesignSystem.Typography.button)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: DesignSystem.Heights.button)
                    .background(DesignSystem.Colors.primary)
                    .cornerRadius(DesignSystem.CornerRadius.md)
                }
            } else {
                // Camera Preview or Gallery Grid
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Live Camera Preview (if available)
                    if AVCaptureDevice.authorizationStatus(for: .video) == .authorized {
                        CameraPreviewView(selectedImage: $selectedImage)
                            .frame(height: 200)
                            .cornerRadius(DesignSystem.CornerRadius.lg)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                                    .stroke(DesignSystem.Colors.neutralDark, lineWidth: 1)
                            )
                    } else {
                        // Placeholder
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                            .fill(DesignSystem.Colors.neutral)
                            .frame(height: 200)
                            .overlay(
                                VStack(spacing: DesignSystem.Spacing.md) {
                                    Image(systemName: "camera")
                                        .font(.system(size: DesignSystem.IconSizes.xxlarge))
                                        .foregroundColor(DesignSystem.Colors.textSecondary)
                                    
                                    Text("Camera Preview")
                                        .font(DesignSystem.Typography.body)
                                        .foregroundColor(DesignSystem.Colors.textSecondary)
                                }
                            )
                    }
                    
                    // Face Detection Indicator
                    if isDetectingFaces {
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            ModernLoadingIndicator(size: 20, color: DesignSystem.Colors.primary)
                            
                            Text("Detecting faces...")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.primary)
                        }
                    } else if selectedImage != nil {
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(DesignSystem.Colors.success)
                            
                            Text("Face detected")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.success)
                        }
                    } else {
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(DesignSystem.Colors.warning)
                            
                            Text("Face the camera directly")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.warning)
                        }
                    }
                }
            }
        }
    }
    
    private var actionButtonsSection: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // Camera Button
            Button(action: {
                analyticsService.track(event: "camera_button_tapped")
                requestCameraPermission()
            }) {
                VStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: DesignSystem.IconSizes.large))
                        .foregroundColor(.white)
                    
                    Text("CAMERA")
                        .font(DesignSystem.Typography.captionBold)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: DesignSystem.Heights.card)
                .background(DesignSystem.Colors.primary)
                .cornerRadius(DesignSystem.CornerRadius.md)
            }
            
            // Gallery Button
            Button(action: {
                analyticsService.track(event: "gallery_button_tapped")
                requestPhotoLibraryPermission()
            }) {
                VStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: DesignSystem.IconSizes.large))
                        .foregroundColor(.white)
                    
                    Text("GALLERY")
                        .font(DesignSystem.Typography.captionBold)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: DesignSystem.Heights.card)
                .background(DesignSystem.Colors.secondary)
                .cornerRadius(DesignSystem.CornerRadius.md)
            }
        }
    }
    
    private var tipsSection: some View {
        ModernCard(
            padding: DesignSystem.Spacing.md,
            cornerRadius: DesignSystem.CornerRadius.md,
            shadow: DesignSystem.Shadows.small
        ) {
            VStack(spacing: DesignSystem.Spacing.md) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(DesignSystem.Colors.warning)
                    
                    Text("Tips for best results:")
                        .font(DesignSystem.Typography.captionBold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("• Use a clear selfie with good lighting")
                    Text("• Face the camera directly")
                    Text("• Avoid sunglasses or hats")
                    Text("• High resolution photos work best")
                }
                .font(DesignSystem.Typography.small)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
    }
    
    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                if granted {
                    showingCamera = true
                } else {
                    permissionAlertMessage = "Camera access is required to take photos. Please enable it in Settings."
                    showingPermissionAlert = true
                }
            }
        }
    }
    
    private func requestPhotoLibraryPermission() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized, .limited:
                    showingImagePicker = true
                default:
                    permissionAlertMessage = "Photo library access is required to select photos. Please enable it in Settings."
                    showingPermissionAlert = true
                }
            }
        }
    }
    
    private func proceedToProcessing() {
        guard let image = selectedImage else { return }
        
        analyticsService.track(event: "photo_selected", parameters: [
            "image_width": image.size.width,
            "image_height": image.size.height
        ])
        
        // Navigate to quality selection
        navigationCoordinator.selectedImage = image
        navigationCoordinator.showQualitySelection()
    }
    
    private func detectFacesInImage(_ image: UIImage) {
        isDetectingFaces = true
        
        // First analyze image quality
        serviceContainer.backgroundRemovalService.analyzeImageQuality(image) { [weak self] (qualityAnalysis: ImageQualityAnalysis) in
            DispatchQueue.main.async {
                if !qualityAnalysis.isGood {
                    self?.isDetectingFaces = false
                    self?.permissionAlertMessage = "Image quality issues detected: \(qualityAnalysis.issues.joined(separator: ", ")). \(qualityAnalysis.recommendations.joined(separator: " "))"
                    self?.showingPermissionAlert = true
                    return
                }
                
                // If quality is good, proceed with face detection
                self?.serviceContainer.backgroundRemovalService.detectFaces(in: image) { [weak self] (observations: [VNFaceObservation]) in
                    DispatchQueue.main.async {
                        self?.isDetectingFaces = false
                        
                        if observations.isEmpty {
                            // No faces detected - show warning
                            self?.permissionAlertMessage = "No faces detected in the image. Please try a photo with a clear face."
                            self?.showingPermissionAlert = true
                        } else {
                            // Faces detected - proceed
                            analyticsService.track(event: "faces_detected", parameters: [
                                "face_count": observations.count,
                                "image_quality": qualityAnalysis.quality.description
                            ])
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct CameraPreviewView: UIViewRepresentable {
    @Binding var selectedImage: UIImage?
    @State private var isCapturing = false
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let captureSession = AVCaptureSession()
        
        // Configure capture session
        captureSession.sessionPreset = .photo
        
        // Add video input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              captureSession.canAddInput(videoInput) else {
            return view
        }
        
        captureSession.addInput(videoInput)
        
        // Add photo output
        let photoOutput = AVCapturePhotoOutput()
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }
        
        // Create preview layer
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        
        view.layer.addSublayer(previewLayer)
        
        // Start session
        DispatchQueue.global(qos: .background).async {
            captureSession.startRunning()
        }
        
        // Store references in coordinator
        context.coordinator.captureSession = captureSession
        context.coordinator.photoOutput = photoOutput
        context.coordinator.previewLayer = previewLayer
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update preview layer frame when view bounds change
        if let previewLayer = context.coordinator.previewLayer {
            previewLayer.frame = uiView.bounds
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, AVCapturePhotoCaptureDelegate {
        let parent: CameraPreviewView
        var captureSession: AVCaptureSession?
        var photoOutput: AVCapturePhotoOutput?
        var previewLayer: AVCaptureVideoPreviewLayer?
        
        init(_ parent: CameraPreviewView) {
            self.parent = parent
        }
        
        func capturePhoto() {
            guard let photoOutput = photoOutput else { return }
            
            let settings = AVCapturePhotoSettings()
            photoOutput.capturePhoto(with: settings, delegate: self)
        }
        
        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            guard let imageData = photo.fileDataRepresentation(),
                  let image = UIImage(data: imageData) else { return }
            
            DispatchQueue.main.async {
                self.parent.selectedImage = image
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func detectFacesInImage(_ image: UIImage) {
        // This method is called from the coordinator
        // The actual face detection is handled by the parent view
    }
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let result = results.first else { return }
            let provider = result.itemProvider
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            print("Error loading image: \(error.localizedDescription)")
                            return
                        }
                        
                        guard let selectedImage = image as? UIImage else {
                            print("Failed to load image")
                            return
                        }
                        
                        self?.parent.selectedImage = selectedImage
                        self?.parent.detectFacesInImage(selectedImage)
                    }
                }
            }
        }
    }
}

struct CameraView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func detectFacesInImage(_ image: UIImage) {
        // This method is called from the coordinator
        // The actual face detection is handled by the parent view
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.allowsEditing = true
        picker.cameraDevice = .front // Use front camera for selfies
        picker.cameraFlashMode = .auto
        picker.cameraCaptureMode = .photo
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            var selectedImage: UIImage?
            
            if let editedImage = info[.editedImage] as? UIImage {
                selectedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                selectedImage = originalImage
            }
            
            if let image = selectedImage {
                parent.selectedImage = image
                parent.detectFacesInImage(image)
            } else {
                print("Failed to capture image from camera")
            }
            
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    PhotoUploadView()
        .environmentObject(UnifiedAppStateManager.shared)
}
