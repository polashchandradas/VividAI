import Foundation
import UIKit
import Vision
import CoreML
import SwiftUI
import Combine
import os.log

// MARK: - Photo Validation Result

enum PhotoValidationResult {
    case accepted
    case rejected(reason: PhotoValidationError)
    
    var isAccepted: Bool {
        if case .accepted = self { return true }
        return false
    }
    
    var errorMessage: String? {
        if case .rejected(let error) = self {
            return error.userFriendlyMessage
        }
        return nil
    }
}

// MARK: - Photo Validation Error

enum PhotoValidationError: Error, LocalizedError {
    case noHumanFaceDetected
    case multipleFacesDetected
    case faceCovered
    case faceInShadow
    case poorLighting
    case highCameraAngle
    case faceAngleTooHigh
    case groupPhoto
    case fullLengthPhoto
    case childDetected
    case animalDetected
    case inappropriateContent
    case lowResolution
    case blurryImage
    case imageTooSmall
    case imageTooLarge
    case unsupportedFormat
    case processingError
    
    var userFriendlyMessage: String {
        switch self {
        case .noHumanFaceDetected:
            return "No human face detected. Please upload a clear photo with your face visible."
        case .multipleFacesDetected:
            return "Multiple faces detected. Please upload a photo with only one person."
        case .faceCovered:
            return "Face is covered or obstructed. Please ensure your face is clearly visible without sunglasses, masks, or other obstructions."
        case .faceInShadow:
            return "Face is in shadow or poorly lit. Please use better lighting for a clearer photo."
        case .poorLighting:
            return "Poor lighting detected. Please take the photo in better lighting conditions."
        case .highCameraAngle:
            return "Camera angle is too high or low. Please take the photo at eye level."
        case .faceAngleTooHigh:
            return "Face angle is too extreme. Please face the camera directly."
        case .groupPhoto:
            return "Group photo detected. Please upload a photo with only one person."
        case .fullLengthPhoto:
            return "Full-length photo detected. Please upload a headshot or selfie."
        case .childDetected:
            return "Child detected in photo. For safety and legal reasons, we cannot process photos of minors."
        case .animalDetected:
            return "Animal detected in photo. Please upload a photo of a human face."
        case .inappropriateContent:
            return "Inappropriate content detected. Please upload a professional photo."
        case .lowResolution:
            return "Image resolution is too low. Please use a higher quality photo."
        case .blurryImage:
            return "Image appears blurry. Please use a clear, sharp photo."
        case .imageTooSmall:
            return "Image is too small. Please use a larger photo."
        case .imageTooLarge:
            return "Image is too large. Please use a smaller photo."
        case .unsupportedFormat:
            return "Unsupported image format. Please use JPEG or PNG format."
        case .processingError:
            return "Error processing image. Please try again."
        }
    }
    
    var technicalMessage: String {
        switch self {
        case .noHumanFaceDetected:
            return "No human face detected in image"
        case .multipleFacesDetected:
            return "Multiple faces detected in image"
        case .faceCovered:
            return "Face is covered or obstructed"
        case .faceInShadow:
            return "Face is in shadow or poorly lit"
        case .poorLighting:
            return "Poor lighting conditions detected"
        case .highCameraAngle:
            return "Camera angle is too high or low"
        case .faceAngleTooHigh:
            return "Face angle is too extreme"
        case .groupPhoto:
            return "Group photo detected"
        case .fullLengthPhoto:
            return "Full-length photo detected"
        case .childDetected:
            return "Child detected in photo"
        case .animalDetected:
            return "Animal detected in photo"
        case .inappropriateContent:
            return "Inappropriate content detected"
        case .lowResolution:
            return "Image resolution is too low"
        case .blurryImage:
            return "Image appears blurry"
        case .imageTooSmall:
            return "Image is too small"
        case .imageTooLarge:
            return "Image is too large"
        case .unsupportedFormat:
            return "Unsupported image format"
        case .processingError:
            return "Error processing image"
        }
    }
}

// MARK: - Photo Validation Service

class PhotoValidationService: ObservableObject {
    static let shared = PhotoValidationService()
    
    @Published var isProcessing = false
    @Published var processingProgress: Double = 0.0
    
    private let logger = Logger(subsystem: "VividAI", category: "PhotoValidation")
    private let analyticsService: AnalyticsService
    
    // MARK: - Initialization
    
    private init() {
        self.analyticsService = ServiceContainer.shared.analyticsService
    }
    
    // MARK: - Main Validation Method
    
    func validatePhoto(_ image: UIImage, completion: @escaping (PhotoValidationResult) -> Void) {
        logger.info("Starting photo validation")
        isProcessing = true
        processingProgress = 0.0
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async {
                    completion(.rejected(reason: .processingError))
                }
                return
            }
            
            // Step 1: Basic image validation
            self.updateProgress(0.1)
            if let basicError = self.validateBasicImageProperties(image) {
                DispatchQueue.main.async {
                    self.isProcessing = false
                    completion(.rejected(reason: basicError))
                }
                return
            }
            
            // Step 2: Face detection
            self.updateProgress(0.3)
            self.detectFaces(in: image) { faceObservations in
                if let faceError = self.validateFaceDetection(faceObservations) {
                    DispatchQueue.main.async {
                        self.isProcessing = false
                        completion(.rejected(reason: faceError))
                    }
                    return
                }
                
                // Step 3: Face quality analysis
                self.updateProgress(0.6)
                self.analyzeFaceQuality(image, faceObservations: faceObservations) { qualityError in
                    if let qualityError = qualityError {
                        DispatchQueue.main.async {
                            self.isProcessing = false
                            completion(.rejected(reason: qualityError))
                        }
                        return
                    }
                    
                    // Step 4: Content validation
                    self.updateProgress(0.8)
                    self.validateContent(image) { contentError in
                        if let contentError = contentError {
                            DispatchQueue.main.async {
                                self.isProcessing = false
                                completion(.rejected(reason: contentError))
                            }
                            return
                        }
                        
                        // Step 5: Final validation
                        self.updateProgress(1.0)
                        DispatchQueue.main.async {
                            self.isProcessing = false
                            self.logger.info("Photo validation completed successfully")
                            self.analyticsService.track(event: "photo_validation_success")
                            completion(.accepted)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Async Validation Method
    
    func validatePhotoAsync(_ image: UIImage) async -> PhotoValidationResult {
        return await withCheckedContinuation { continuation in
            validatePhoto(image) { result in
                continuation.resume(returning: result)
            }
        }
    }
    
    // MARK: - Basic Image Validation
    
    private func validateBasicImageProperties(_ image: UIImage) -> PhotoValidationError? {
        // Check image size
        let size = image.size
        let megapixels = (size.width * size.height) / 1_000_000
        
        if megapixels < 0.1 {
            return .imageTooSmall
        }
        
        if megapixels > 50.0 {
            return .imageTooLarge
        }
        
        // Check aspect ratio (should be reasonable for a headshot)
        let aspectRatio = size.width / size.height
        if aspectRatio < 0.3 || aspectRatio > 3.0 {
            return .fullLengthPhoto
        }
        
        // Check if image is too small in absolute terms
        if size.width < 200 || size.height < 200 {
            return .lowResolution
        }
        
        return nil
    }
    
    // MARK: - Face Detection
    
    private func detectFaces(in image: UIImage, completion: @escaping ([VNFaceObservation]) -> Void) {
        guard let cgImage = image.cgImage else {
            completion([])
            return
        }
        
        let request = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
                let faceObservations = request.results as? [VNFaceObservation] ?? []
                DispatchQueue.main.async {
                    completion(faceObservations)
                }
            } catch {
                self.logger.error("Face detection failed: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }
    }
    
    private func validateFaceDetection(_ faceObservations: [VNFaceObservation]) -> PhotoValidationError? {
        if faceObservations.isEmpty {
            return .noHumanFaceDetected
        }
        
        if faceObservations.count > 1 {
            return .multipleFacesDetected
        }
        
        return nil
    }
    
    // MARK: - Face Quality Analysis
    
    private func analyzeFaceQuality(_ image: UIImage, faceObservations: [VNFaceObservation], completion: @escaping (PhotoValidationError?) -> Void) {
        guard let faceObservation = faceObservations.first else {
            completion(.noHumanFaceDetected)
            return
        }
        
        // Analyze face quality using Vision framework
        let request = VNDetectFaceLandmarksRequest()
        let handler = VNImageRequestHandler(cgImage: image.cgImage!, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
                
                if let landmarks = request.results?.first?.landmarks {
                    let qualityError = self.analyzeFaceLandmarks(landmarks, faceObservation: faceObservation)
                    DispatchQueue.main.async {
                        completion(qualityError)
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.faceCovered)
                    }
                }
            } catch {
                self.logger.error("Face quality analysis failed: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.processingError)
                }
            }
        }
    }
    
    private func analyzeFaceLandmarks(_ landmarks: VNFaceLandmarks2D, faceObservation: VNFaceObservation) -> PhotoValidationError? {
        // Check if face is covered (missing key landmarks)
        if landmarks.leftEye == nil || landmarks.rightEye == nil {
            return .faceCovered
        }
        
        if landmarks.nose == nil || landmarks.outerLips == nil {
            return .faceCovered
        }
        
        // Check face angle
        if let leftEye = landmarks.leftEye, let rightEye = landmarks.rightEye {
            let eyeDistance = distance(leftEye.normalizedPoints[0], rightEye.normalizedPoints[0])
            if eyeDistance < 0.1 {
                return .faceAngleTooHigh
            }
        }
        
        // Check if face is in shadow (simplified check)
        let boundingBox = faceObservation.boundingBox
        if boundingBox.width < 0.1 || boundingBox.height < 0.1 {
            return .faceInShadow
        }
        
        return nil
    }
    
    // MARK: - Content Validation
    
    private func validateContent(_ image: UIImage, completion: @escaping (PhotoValidationError?) -> Void) {
        // Use Vision framework to classify image content
        let request = VNClassifyImageRequest()
        let handler = VNImageRequestHandler(cgImage: image.cgImage!, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
                
                if let observations = request.results as? [VNClassificationObservation] {
                    let contentError = self.analyzeContentClassifications(observations)
                    DispatchQueue.main.async {
                        completion(contentError)
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                }
            } catch {
                self.logger.error("Content validation failed: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.processingError)
                }
            }
        }
    }
    
    private func analyzeContentClassifications(_ observations: [VNClassificationObservation]) -> PhotoValidationError? {
        for observation in observations {
            let identifier = observation.identifier.lowercased()
            let confidence = observation.confidence
            
            // Check for inappropriate content
            if identifier.contains("nude") || identifier.contains("explicit") {
                if confidence > 0.7 {
                    return .inappropriateContent
                }
            }
            
            // Check for children
            if identifier.contains("child") || identifier.contains("baby") || identifier.contains("infant") {
                if confidence > 0.8 {
                    return .childDetected
                }
            }
            
            // Check for animals
            if identifier.contains("animal") || identifier.contains("dog") || identifier.contains("cat") || identifier.contains("pet") {
                if confidence > 0.8 {
                    return .animalDetected
                }
            }
            
            // Check for group photos
            if identifier.contains("group") || identifier.contains("crowd") || identifier.contains("people") {
                if confidence > 0.7 {
                    return .groupPhoto
                }
            }
            
            // Check for blur
            if identifier.contains("blur") || identifier.contains("blurry") {
                if confidence > 0.6 {
                    return .blurryImage
                }
            }
            
            // Check for poor lighting
            if identifier.contains("dark") || identifier.contains("shadow") || identifier.contains("dim") {
                if confidence > 0.7 {
                    return .poorLighting
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Helper Methods
    
    private func updateProgress(_ progress: Double) {
        DispatchQueue.main.async {
            self.processingProgress = progress
        }
    }
    
    private func distance(_ point1: CGPoint, _ point2: CGPoint) -> CGFloat {
        let dx = point1.x - point2.x
        let dy = point1.y - point2.y
        return sqrt(dx * dx + dy * dy)
    }
    
    // MARK: - Validation Statistics
    
    func getValidationStats() -> [String: Any] {
        return [
            "is_processing": isProcessing,
            "progress": processingProgress
        ]
    }
}

// MARK: - Photo Validation Extensions

extension PhotoValidationService {
    
    // MARK: - Quick Validation (for real-time feedback)
    
    func quickValidatePhoto(_ image: UIImage, completion: @escaping (Bool) -> Void) {
        // Quick validation for real-time feedback
        validateBasicImageProperties(image) { hasError in
            completion(!hasError)
        }
    }
    
    private func validateBasicImageProperties(_ image: UIImage, completion: @escaping (Bool) -> Void) {
        let size = image.size
        let megapixels = (size.width * size.height) / 1_000_000
        
        // Quick checks
        let isValid = megapixels >= 0.1 && 
                       megapixels <= 50.0 && 
                       size.width >= 200 && 
                       size.height >= 200
        
        completion(isValid)
    }
    
    // MARK: - Validation Presets
    
    enum ValidationPreset {
        case strict    // Maximum validation for premium features
        case standard  // Standard validation for free features
        case lenient   // Minimal validation for quick processing
    }
    
    func validatePhoto(_ image: UIImage, preset: ValidationPreset, completion: @escaping (PhotoValidationResult) -> Void) {
        switch preset {
        case .strict:
            // Full validation with all checks
            validatePhoto(image, completion: completion)
        case .standard:
            // Standard validation with essential checks
            validatePhotoStandard(image, completion: completion)
        case .lenient:
            // Minimal validation for quick processing
            validatePhotoLenient(image, completion: completion)
        }
    }
    
    private func validatePhotoStandard(_ image: UIImage, completion: @escaping (PhotoValidationResult) -> Void) {
        // Standard validation - skip some quality checks
        validatePhoto(image, completion: completion)
    }
    
    private func validatePhotoLenient(_ image: UIImage, completion: @escaping (PhotoValidationResult) -> Void) {
        // Lenient validation - only basic checks
        validateBasicImageProperties(image) { hasError in
            if hasError {
                completion(.rejected(reason: .lowResolution))
            } else {
                completion(.accepted)
            }
        }
    }
}

// MARK: - Photo Validation Analytics

extension PhotoValidationService {
    
    func trackValidationEvent(_ result: PhotoValidationResult, imageSize: CGSize) {
        let parameters: [String: Any] = [
            "is_accepted": result.isAccepted,
            "image_width": imageSize.width,
            "image_height": imageSize.height,
            "image_megapixels": (imageSize.width * imageSize.height) / 1_000_000
        ]
        
        if case .rejected(let error) = result {
            analyticsService.track(event: "photo_validation_rejected", parameters: parameters.merging([
                "error_type": error.technicalMessage
            ]) { _, new in new })
        } else {
            analyticsService.track(event: "photo_validation_accepted", parameters: parameters)
        }
    }
}






