import Foundation
import UIKit
import AVFoundation
import CoreAnimation

class VideoGenerationService: ObservableObject {
    static let shared = VideoGenerationService()
    
    @Published var isGenerating = false
    @Published var generationProgress: Double = 0.0
    
    private init() {}
    
    func generateTransformationVideo(
        from originalImage: UIImage,
        to enhancedImage: UIImage,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        isGenerating = true
        generationProgress = 0.0
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                let videoURL = try self?.createTransformationVideo(
                    original: originalImage,
                    enhanced: enhancedImage
                )
                
                DispatchQueue.main.async {
                    self?.isGenerating = false
                    self?.generationProgress = 1.0
                    completion(.success(videoURL!))
                }
            } catch {
                DispatchQueue.main.async {
                    self?.isGenerating = false
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func createTransformationVideo(original: UIImage, enhanced: UIImage) throws -> URL {
        let videoURL = getVideoOutputURL()
        
        // Video settings
        let videoSize = CGSize(width: 1080, height: 1920) // 9:16 aspect ratio
        let duration: TimeInterval = 5.0
        let frameRate: Int32 = 30
        
        // Create video writer
        let videoWriter = try AVAssetWriter(outputURL: videoURL, fileType: .mp4)
        
        // Video settings
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: videoSize.width,
            AVVideoHeightKey: videoSize.height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 5_000_000, // 5 Mbps
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
            ]
        ]
        
        let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        videoInput.expectsMediaDataInRealTime = false
        
        guard videoWriter.canAdd(videoInput) else {
            throw VideoGenerationError.cannotAddVideoInput
        }
        videoWriter.add(videoInput)
        
        // Start writing
        guard videoWriter.startWriting() else {
            throw VideoGenerationError.cannotStartWriting
        }
        
        videoWriter.startSession(atSourceTime: .zero)
        
        // Generate frames
        let totalFrames = Int(duration * Double(frameRate))
        let frameDuration = CMTime(value: 1, timescale: frameRate)
        
        for frameIndex in 0..<totalFrames {
            let currentTime = CMTime(value: Int64(frameIndex), timescale: frameRate)
            let progress = Double(frameIndex) / Double(totalFrames)
            
            DispatchQueue.main.async {
                self.generationProgress = progress
            }
            
            // Create frame
            let frame = createFrame(
                original: original,
                enhanced: enhanced,
                progress: progress,
                size: videoSize
            )
            
            // Convert frame to pixel buffer
            guard let pixelBuffer = createPixelBuffer(from: frame, size: videoSize) else {
                continue
            }
            
            // Append frame
            if videoInput.isReadyForMoreMediaData {
                let presentationTime = currentTime
                videoInput.append(AVAssetWriterInputPixelBufferAdaptor(
                    assetWriterInput: videoInput,
                    sourcePixelBufferAttributes: nil
                ).pixelBufferPool?.makePixelBuffer() ?? pixelBuffer, withPresentationTime: presentationTime)
            }
        }
        
        // Finish writing
        videoInput.markAsFinished()
        
        let semaphore = DispatchSemaphore(value: 0)
        videoWriter.finishWriting {
            semaphore.signal()
        }
        semaphore.wait()
        
        return videoURL
    }
    
    private func createFrame(original: UIImage, enhanced: UIImage, progress: Double, size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Background
            UIColor.black.setFill()
            context.cgContext.fill(CGRect(origin: .zero, size: size))
            
            // Calculate image size and position (centered)
            let imageSize = CGSize(width: size.width * 0.8, height: size.width * 0.8)
            let imageRect = CGRect(
                x: (size.width - imageSize.width) / 2,
                y: (size.height - imageSize.height) / 2,
                width: imageSize.width,
                height: imageSize.height
            )
            
            // Interpolate between original and enhanced
            let currentImage = progress < 0.5 ? original : enhanced
            currentImage.draw(in: imageRect)
            
            // Add transition effects
            if progress < 0.3 {
                // Fade in original
                context.cgContext.setAlpha(progress / 0.3)
                original.draw(in: imageRect)
            } else if progress < 0.7 {
                // Transition effect
                let transitionProgress = (progress - 0.3) / 0.4
                context.cgContext.setAlpha(1.0 - transitionProgress)
                original.draw(in: imageRect)
                
                context.cgContext.setAlpha(transitionProgress)
                enhanced.draw(in: imageRect)
            } else {
                // Show enhanced with effects
                enhanced.draw(in: imageRect)
                
                // Add shimmer effect
                if progress > 0.8 {
                    let shimmerProgress = (progress - 0.8) / 0.2
                    addShimmerEffect(context: context, rect: imageRect, progress: shimmerProgress)
                }
            }
            
            // Add text overlay
            addTextOverlay(context: context, size: size, progress: progress)
            
            // Add watermark
            addWatermark(context: context, size: size)
        }
    }
    
    private func addShimmerEffect(context: UIGraphicsRendererContext, rect: CGRect, progress: Double) {
        let shimmerWidth: CGFloat = 50
        let shimmerX = rect.minX + (rect.width - shimmerWidth) * progress
        
        context.cgContext.setBlendMode(.overlay)
        context.cgContext.setAlpha(0.6)
        
        let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [UIColor.clear.cgColor, UIColor.white.cgColor, UIColor.clear.cgColor] as CFArray,
            locations: [0, 0.5, 1]
        )
        
        context.cgContext.drawLinearGradient(
            gradient!,
            start: CGPoint(x: shimmerX, y: rect.minY),
            end: CGPoint(x: shimmerX + shimmerWidth, y: rect.maxY),
            options: []
        )
    }
    
    private func addTextOverlay(context: UIGraphicsRendererContext, size: CGSize, progress: Double) {
        let textY = size.height * 0.15
        
        if progress < 0.2 {
            // "Original"
            addText("Original", at: CGPoint(x: size.width / 2, y: textY), context: context)
        } else if progress < 0.6 {
            // "AI Enhancing..."
            addText("AI Enhancing...", at: CGPoint(x: size.width / 2, y: textY), context: context)
        } else {
            // "Enhanced"
            addText("Enhanced", at: CGPoint(x: size.width / 2, y: textY), context: context)
        }
    }
    
    private func addText(_ text: String, at point: CGPoint, context: UIGraphicsRendererContext) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .bold),
            .foregroundColor: UIColor.white,
            .strokeColor: UIColor.black,
            .strokeWidth: -2
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributedString.size()
        let textRect = CGRect(
            x: point.x - textSize.width / 2,
            y: point.y - textSize.height / 2,
            width: textSize.width,
            height: textSize.height
        )
        
        attributedString.draw(in: textRect)
    }
    
    private func addWatermark(context: UIGraphicsRendererContext, size: CGSize) {
        let watermarkText = "VividAI.app"
        let watermarkRect = CGRect(
            x: size.width - 120,
            y: size.height - 40,
            width: 100,
            height: 20
        )
        
        // Background
        UIColor.black.withAlphaComponent(0.6).setFill()
        context.cgContext.fill(watermarkRect)
        
        // Text
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .medium),
            .foregroundColor: UIColor.white
        ]
        
        let attributedString = NSAttributedString(string: watermarkText, attributes: attributes)
        attributedString.draw(in: watermarkRect)
    }
    
    private func createPixelBuffer(from image: UIImage, size: CGSize) -> CVPixelBuffer? {
        let attributes: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]
        
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(size.width),
            Int(size.height),
            kCVPixelFormatType_32ARGB,
            attributes as CFDictionary,
            &pixelBuffer
        )
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        
        let pixelData = CVPixelBufferGetBaseAddress(buffer)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        
        let context = CGContext(
            data: pixelData,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: rgbColorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        )
        
        context?.draw(image.cgImage!, in: CGRect(origin: .zero, size: size))
        
        return buffer
    }
    
    private func getVideoOutputURL() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("transformation_video.mp4")
    }
    
    func getVideoSpecifications() -> VideoSpecs {
        return VideoSpecs(
            resolution: CGSize(width: 1080, height: 1920),
            duration: 5.0,
            frameRate: 30,
            format: .mp4,
            estimatedSize: "2-3 MB"
        )
    }
}

// MARK: - Data Models

struct VideoSpecs {
    let resolution: CGSize
    let duration: TimeInterval
    let frameRate: Int32
    let format: VideoFormat
    let estimatedSize: String
}

enum VideoFormat {
    case mp4
    case mov
    
    var fileExtension: String {
        switch self {
        case .mp4: return "mp4"
        case .mov: return "mov"
        }
    }
}

enum VideoGenerationError: Error, LocalizedError {
    case cannotAddVideoInput
    case cannotStartWriting
    case cannotCreatePixelBuffer
    case cannotCreateVideoWriter
    
    var errorDescription: String? {
        switch self {
        case .cannotAddVideoInput:
            return "Cannot add video input to writer"
        case .cannotStartWriting:
            return "Cannot start video writing"
        case .cannotCreatePixelBuffer:
            return "Cannot create pixel buffer"
        case .cannotCreateVideoWriter:
            return "Cannot create video writer"
        }
    }
}
