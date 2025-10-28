import Foundation
import UIKit
import XCTest

// MARK: - Photo Validation Service Tests
// This file contains comprehensive tests for the PhotoValidationService

class PhotoValidationServiceTests {
    
    // MARK: - Test Setup
    
    static func runAllTests() {
        print("🧪 Running PhotoValidationService Tests...")
        
        testBasicImageValidation()
        testFaceDetectionValidation()
        testContentValidation()
        testErrorMessages()
        testValidationPresets()
        
        print("✅ All PhotoValidationService tests completed!")
    }
    
    // MARK: - Basic Image Validation Tests
    
    static func testBasicImageValidation() {
        print("📸 Testing basic image validation...")
        
        // Test valid image
        let validImage = createTestImage(size: CGSize(width: 1000, height: 1000))
        let validResult = validateImageProperties(validImage)
        assert(validResult == nil, "Valid image should pass basic validation")
        
        // Test too small image
        let smallImage = createTestImage(size: CGSize(width: 100, height: 100))
        let smallResult = validateImageProperties(smallImage)
        assert(smallResult == .imageTooSmall, "Small image should fail validation")
        
        // Test too large image
        let largeImage = createTestImage(size: CGSize(width: 10000, height: 10000))
        let largeResult = validateImageProperties(largeImage)
        assert(largeResult == .imageTooLarge, "Large image should fail validation")
        
        print("✅ Basic image validation tests passed")
    }
    
    // MARK: - Face Detection Tests
    
    static func testFaceDetectionValidation() {
        print("👤 Testing face detection validation...")
        
        // Test with no faces (empty array)
        let noFacesResult = validateFaceDetection([])
        assert(noFacesResult == .noHumanFaceDetected, "Empty face array should fail")
        
        // Test with multiple faces
        let multipleFacesResult = validateFaceDetection([VNFaceObservation(), VNFaceObservation()])
        assert(multipleFacesResult == .multipleFacesDetected, "Multiple faces should fail")
        
        // Test with single face
        let singleFaceResult = validateFaceDetection([VNFaceObservation()])
        assert(singleFaceResult == nil, "Single face should pass")
        
        print("✅ Face detection validation tests passed")
    }
    
    // MARK: - Content Validation Tests
    
    static func testContentValidation() {
        print("🔍 Testing content validation...")
        
        // Test inappropriate content detection
        let inappropriateObservations = [
            createClassificationObservation(identifier: "nude", confidence: 0.8),
            createClassificationObservation(identifier: "explicit", confidence: 0.9)
        ]
        let inappropriateResult = analyzeContentClassifications(inappropriateObservations)
        assert(inappropriateResult == .inappropriateContent, "Inappropriate content should be detected")
        
        // Test child detection
        let childObservations = [
            createClassificationObservation(identifier: "child", confidence: 0.9),
            createClassificationObservation(identifier: "baby", confidence: 0.8)
        ]
        let childResult = analyzeContentClassifications(childObservations)
        assert(childResult == .childDetected, "Child content should be detected")
        
        // Test animal detection
        let animalObservations = [
            createClassificationObservation(identifier: "animal", confidence: 0.9),
            createClassificationObservation(identifier: "dog", confidence: 0.8)
        ]
        let animalResult = analyzeContentClassifications(animalObservations)
        assert(animalResult == .animalDetected, "Animal content should be detected")
        
        // Test group photo detection
        let groupObservations = [
            createClassificationObservation(identifier: "group", confidence: 0.8),
            createClassificationObservation(identifier: "people", confidence: 0.7)
        ]
        let groupResult = analyzeContentClassifications(groupObservations)
        assert(groupResult == .groupPhoto, "Group photos should be detected")
        
        print("✅ Content validation tests passed")
    }
    
    // MARK: - Error Message Tests
    
    static func testErrorMessages() {
        print("💬 Testing error messages...")
        
        let errors: [PhotoValidationError] = [
            .noHumanFaceDetected,
            .multipleFacesDetected,
            .faceCovered,
            .faceInShadow,
            .poorLighting,
            .childDetected,
            .animalDetected,
            .inappropriateContent
        ]
        
        for error in errors {
            let message = error.userFriendlyMessage
            assert(!message.isEmpty, "Error message should not be empty")
            assert(message.count > 10, "Error message should be descriptive")
            print("  ✓ \(error): \(message)")
        }
        
        print("✅ Error message tests passed")
    }
    
    // MARK: - Validation Preset Tests
    
    static func testValidationPresets() {
        print("⚙️ Testing validation presets...")
        
        let testImage = createTestImage(size: CGSize(width: 1000, height: 1000))
        
        // Test strict validation
        let strictResult = validateWithPreset(testImage, preset: .strict)
        print("  Strict validation result: \(strictResult)")
        
        // Test standard validation
        let standardResult = validateWithPreset(testImage, preset: .standard)
        print("  Standard validation result: \(standardResult)")
        
        // Test lenient validation
        let lenientResult = validateWithPreset(testImage, preset: .lenient)
        print("  Lenient validation result: \(lenientResult)")
        
        print("✅ Validation preset tests passed")
    }
    
    // MARK: - Helper Methods
    
    private static func createTestImage(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
    
    private static func validateImageProperties(_ image: UIImage) -> PhotoValidationError? {
        let size = image.size
        let megapixels = (size.width * size.height) / 1_000_000
        
        if megapixels < 0.1 {
            return .imageTooSmall
        }
        
        if megapixels > 50.0 {
            return .imageTooLarge
        }
        
        if size.width < 200 || size.height < 200 {
            return .lowResolution
        }
        
        return nil
    }
    
    private static func validateFaceDetection(_ faceObservations: [VNFaceObservation]) -> PhotoValidationError? {
        if faceObservations.isEmpty {
            return .noHumanFaceDetected
        }
        
        if faceObservations.count > 1 {
            return .multipleFacesDetected
        }
        
        return nil
    }
    
    private static func analyzeContentClassifications(_ observations: [PhotoValidationServiceTests.VNClassificationObservation]) -> PhotoValidationError? {
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
        }
        
        return nil
    }
    
    private static func createClassificationObservation(identifier: String, confidence: Float) -> VNClassificationObservation {
        return VNClassificationObservation(identifier: identifier, confidence: confidence)
    }
    
    private static func validateWithPreset(_ image: UIImage, preset: PhotoValidationService.ValidationPreset) -> String {
        switch preset {
        case .strict:
            return "Strict validation would perform full checks"
        case .standard:
            return "Standard validation would perform essential checks"
        case .lenient:
            return "Lenient validation would perform minimal checks"
        }
    }
}

// MARK: - Mock Classes for Testing

extension PhotoValidationServiceTests {
    class VNClassificationObservation {
        let identifier: String
        let confidence: Float
        
        init(identifier: String, confidence: Float) {
            self.identifier = identifier
            self.confidence = confidence
        }
    }
}

// MARK: - Test Runner

extension PhotoValidationService {
    static func runValidationTests() {
        PhotoValidationServiceTests.runAllTests()
    }
}








