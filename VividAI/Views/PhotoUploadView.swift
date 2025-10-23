import SwiftUI
import PhotosUI
import AVFoundation

struct PhotoUploadView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var analyticsService: AnalyticsService
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingPermissionAlert = false
    @State private var permissionAlertMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 32) {
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
                .padding(.horizontal, 20)
                .padding(.top, 20)
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
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Text("Upload Photo")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            Spacer()
            
            // Invisible spacer for balance
            Color.clear
                .frame(width: 18, height: 18)
        }
    }
    
    private var imageSelectionSection: some View {
        VStack(spacing: 20) {
            if let selectedImage = selectedImage {
                // Selected Image Preview
                VStack(spacing: 16) {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 300)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.blue, lineWidth: 2)
                        )
                    
                    Text("Great photo!")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.green)
                    
                    Button("Continue to Processing") {
                        proceedToProcessing()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.blue)
                    .cornerRadius(12)
                }
            } else {
                // Camera Preview or Gallery Grid
                VStack(spacing: 20) {
                    // Live Camera Preview (if available)
                    if AVCaptureDevice.authorizationStatus(for: .video) == .authorized {
                        CameraPreviewView()
                            .frame(height: 200)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                    } else {
                        // Placeholder
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemGray6))
                            .frame(height: 200)
                            .overlay(
                                VStack(spacing: 12) {
                                    Image(systemName: "camera")
                                        .font(.system(size: 40))
                                        .foregroundColor(.secondary)
                                    
                                    Text("Camera Preview")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                            )
                    }
                    
                    // Face Detection Indicator
                    if selectedImage != nil {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            
                            Text("Face detected")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.green)
                        }
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                            
                            Text("Face the camera directly")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
        }
    }
    
    private var actionButtonsSection: some View {
        HStack(spacing: 16) {
            // Camera Button
            Button(action: {
                analyticsService.track(event: "camera_button_tapped")
                requestCameraPermission()
            }) {
                VStack(spacing: 8) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                    
                    Text("CAMERA")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 80)
                .background(Color.blue)
                .cornerRadius(12)
            }
            
            // Gallery Button
            Button(action: {
                analyticsService.track(event: "gallery_button_tapped")
                requestPhotoLibraryPermission()
            }) {
                VStack(spacing: 8) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                    
                    Text("GALLERY")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 80)
                .background(Color.purple)
                .cornerRadius(12)
            }
        }
    }
    
    private var tipsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                
                Text("Tips for best results:")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("• Use a clear selfie with good lighting")
                Text("• Face the camera directly")
                Text("• Avoid sunglasses or hats")
                Text("• High resolution photos work best")
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
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
        
        // Navigate to processing screen
        // This would typically be handled by a navigation coordinator
        // For now, we'll dismiss and show a placeholder
        dismiss()
    }
}

// MARK: - Supporting Views

struct CameraPreviewView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        // Camera preview implementation would go here
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
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
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        self.parent.selectedImage = image as? UIImage
                    }
                }
            }
        }
    }
}

struct CameraView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.allowsEditing = true
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
            if let image = info[.editedImage] as? UIImage {
                parent.selectedImage = image
            } else if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
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
        .environmentObject(AnalyticsService())
}
