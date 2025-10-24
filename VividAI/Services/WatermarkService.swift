import Foundation
import UIKit
import SwiftUI
import Combine
import os.log
import CoreFoundation
import CoreGraphics
import CoreData

class WatermarkService: ObservableObject {
    static let shared = WatermarkService()
    
    private init() {}
    
    func addWatermark(to image: UIImage, text: String = "VividAI.app", position: WatermarkPosition = .bottomRight) -> UIImage {
        let size = image.size
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Draw the original image
            image.draw(in: CGRect(origin: .zero, size: size))
            
            // Calculate watermark position
            let watermarkRect = calculateWatermarkRect(
                imageSize: size,
                position: position,
                text: text
            )
            
            // Draw watermark background
            drawWatermarkBackground(context: context, rect: watermarkRect)
            
            // Draw watermark text
            drawWatermarkText(context: context, rect: watermarkRect, text: text)
        }
    }
    
    func addWatermarkToVideo(_ videoURL: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        // This would add watermark to video frames
        // For now, return the original URL
        completion(.success(videoURL))
    }
    
    func removeWatermark(from image: UIImage) -> UIImage {
        // This would use AI to detect and remove watermark
        // For now, return the original image
        return image
    }
    
    private func calculateWatermarkRect(imageSize: CGSize, position: WatermarkPosition, text: String) -> CGRect {
        let textSize = calculateTextSize(text: text)
        let padding: CGFloat = 8
        let margin: CGFloat = 16
        
        let width = textSize.width + padding * 2
        let height = textSize.height + padding * 2
        
        let x: CGFloat
        let y: CGFloat
        
        switch position {
        case .topLeft:
            x = margin
            y = margin
        case .topRight:
            x = imageSize.width - width - margin
            y = margin
        case .bottomLeft:
            x = margin
            y = imageSize.height - height - margin
        case .bottomRight:
            x = imageSize.width - width - margin
            y = imageSize.height - height - margin
        case .center:
            x = (imageSize.width - width) / 2
            y = (imageSize.height - height) / 2
        }
        
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    private func calculateTextSize(text: String) -> CGSize {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .medium)
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        return attributedString.size()
    }
    
    private func drawWatermarkBackground(context: UIGraphicsRendererContext, rect: CGRect) {
        // Semi-transparent black background
        UIColor.black.withAlphaComponent(0.6).setFill()
        context.cgContext.fill(rect)
        
        // Rounded corners
        let path = UIBezierPath(roundedRect: rect, cornerRadius: 4)
        path.fill()
    }
    
    private func drawWatermarkText(context: UIGraphicsRendererContext, rect: CGRect, text: String) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .medium),
            .foregroundColor: UIColor.white
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributedString.size()
        
        let textRect = CGRect(
            x: rect.midX - textSize.width / 2,
            y: rect.midY - textSize.height / 2,
            width: textSize.width,
            height: textSize.height
        )
        
        attributedString.draw(in: textRect)
    }
    
    func createWatermarkPreview(size: CGSize, text: String = "VividAI.app") -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Transparent background
            UIColor.clear.setFill()
            context.cgContext.fill(CGRect(origin: .zero, size: size))
            
            // Draw watermark
            let watermarkRect = calculateWatermarkRect(
                imageSize: size,
                position: .bottomRight,
                text: text
            )
            
            drawWatermarkBackground(context: context, rect: watermarkRect)
            drawWatermarkText(context: context, rect: watermarkRect, text: text)
        }
    }
    
    func getWatermarkOpacity() -> Float {
        return 0.6 // 60% opacity
    }
    
    func getWatermarkColor() -> UIColor {
        return .white
    }
    
    func getWatermarkFont() -> UIFont {
        return UIFont.systemFont(ofSize: 12, weight: .medium)
    }
}

// MARK: - Data Models

enum WatermarkPosition {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
    case center
}

struct WatermarkSettings {
    let text: String
    let position: WatermarkPosition
    let opacity: Float
    let color: UIColor
    let font: UIFont
    let size: CGFloat
    
    static let `default` = WatermarkSettings(
        text: "VividAI.app",
        position: .bottomRight,
        opacity: 0.6,
        color: .white,
        font: UIFont.systemFont(ofSize: 12, weight: .medium),
        size: 12
    )
}
