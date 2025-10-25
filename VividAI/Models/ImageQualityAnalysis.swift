import Foundation
import UIKit

// MARK: - Image Quality Analysis

struct ImageQualityAnalysis {
    let quality: ImageQuality
    let issues: [String]
    let recommendations: [String]
    let isGood: Bool
    
    init(quality: ImageQuality, issues: [String] = [], recommendations: [String] = []) {
        self.quality = quality
        self.issues = issues
        self.recommendations = recommendations
        self.isGood = quality.isGood
    }
    
    // MARK: - Static Analysis Methods
    
    static func analyze(_ image: UIImage) -> ImageQualityAnalysis {
        var issues: [String] = []
        var recommendations: [String] = []
        
        // Check image size
        let size = image.size
        let megapixels = (size.width * size.height) / 1_000_000
        
        if megapixels < 0.5 {
            issues.append("Image resolution is very low")
            recommendations.append("Use a higher resolution image")
        } else if megapixels < 1.0 {
            issues.append("Image resolution is low")
            recommendations.append("Consider using a higher resolution image for better results")
        }
        
        // Check aspect ratio
        let aspectRatio = size.width / size.height
        if aspectRatio < 0.5 || aspectRatio > 2.0 {
            issues.append("Unusual aspect ratio")
            recommendations.append("Use a more standard aspect ratio")
        }
        
        // Determine quality
        let quality: ImageQuality
        if megapixels >= 2.0 && issues.isEmpty {
            quality = .high
        } else if megapixels >= 1.0 && issues.count <= 1 {
            quality = .good
        } else if megapixels >= 0.5 {
            quality = .fair
        } else {
            quality = .poor
        }
        
        return ImageQualityAnalysis(
            quality: quality,
            issues: issues,
            recommendations: recommendations
        )
    }
}

