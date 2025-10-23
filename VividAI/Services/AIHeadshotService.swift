import Foundation
import UIKit
import Combine

class AIHeadshotService: ObservableObject {
    static let shared = AIHeadshotService()
    
    @Published var isProcessing = false
    @Published var processingProgress: Double = 0.0
    
    private let replicateAPIKey = "YOUR_REPLICATE_API_KEY" // Replace with actual API key
    private let baseURL = "https://api.replicate.com/v1"
    
    private init() {}
    
    func generateHeadshots(from image: UIImage, completion: @escaping (Result<[HeadshotResult], Error>) -> Void) {
        isProcessing = true
        processingProgress = 0.0
        
        // Upload image to get URL
        uploadImage(image) { [weak self] result in
            switch result {
            case .success(let imageURL):
                self?.processHeadshots(imageURL: imageURL, completion: completion)
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.isProcessing = false
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func uploadImage(_ image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        // Convert image to base64
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(AIHeadshotError.imageConversionFailed))
            return
        }
        
        let base64String = imageData.base64EncodedString()
        
        // For demo purposes, return a mock URL
        // In production, you would upload to a cloud storage service
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            completion(.success("https://example.com/uploaded-image.jpg"))
        }
    }
    
    private func processHeadshots(imageURL: String, completion: @escaping (Result<[HeadshotResult], Error>) -> Void) {
        // Simulate API call to Replicate
        let requestBody: [String: Any] = [
            "version": "stability-ai/stable-diffusion:27b93a2413e7f36cd83da926f3656280b2931564ff050bf9575f1fdf9bcd747e",
            "input": [
                "prompt": "professional headshot, business portrait, high quality, corporate style",
                "image": imageURL,
                "num_outputs": 8,
                "guidance_scale": 7.5,
                "num_inference_steps": 20
            ]
        ]
        
        // Simulate processing with progress updates
        simulateProcessing { [weak self] in
            DispatchQueue.main.async {
                self?.isProcessing = false
                self?.processingProgress = 1.0
                
                // Return mock results
                let mockResults = self?.createMockHeadshots() ?? []
                completion(.success(mockResults))
            }
        }
    }
    
    private func simulateProcessing(completion: @escaping () -> Void) {
        let totalSteps = 8
        let stepDuration: TimeInterval = 0.5
        
        for step in 0..<totalSteps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(step) * stepDuration) {
                self.processingProgress = Double(step + 1) / Double(totalSteps)
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(totalSteps) * stepDuration) {
            completion()
        }
    }
    
    private func createMockHeadshots() -> [HeadshotResult] {
        return [
            HeadshotResult(
                id: 1,
                style: "Corporate Professional",
                imageURL: "https://example.com/headshot1.jpg",
                isPremium: false
            ),
            HeadshotResult(
                id: 2,
                style: "Creative Director",
                imageURL: "https://example.com/headshot2.jpg",
                isPremium: true
            ),
            HeadshotResult(
                id: 3,
                style: "Casual Business",
                imageURL: "https://example.com/headshot3.jpg",
                isPremium: false
            ),
            HeadshotResult(
                id: 4,
                style: "Executive",
                imageURL: "https://example.com/headshot4.jpg",
                isPremium: true
            ),
            HeadshotResult(
                id: 5,
                style: "Tech Professional",
                imageURL: "https://example.com/headshot5.jpg",
                isPremium: true
            ),
            HeadshotResult(
                id: 6,
                style: "Consultant",
                imageURL: "https://example.com/headshot6.jpg",
                isPremium: true
            ),
            HeadshotResult(
                id: 7,
                style: "Entrepreneur",
                imageURL: "https://example.com/headshot7.jpg",
                isPremium: true
            ),
            HeadshotResult(
                id: 8,
                style: "LinkedIn Ready",
                imageURL: "https://example.com/headshot8.jpg",
                isPremium: true
            )
        ]
    }
    
    func getCostEstimate() -> Double {
        // Cost per headshot generation via Replicate API
        return 0.008 // $0.008 per generation
    }
}

// MARK: - Data Models

struct HeadshotResult: Identifiable {
    let id: Int
    let style: String
    let imageURL: String
    let isPremium: Bool
}

enum AIHeadshotError: Error, LocalizedError {
    case imageConversionFailed
    case apiError(String)
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Failed to convert image"
        case .apiError(let message):
            return "API Error: \(message)"
        case .networkError:
            return "Network connection failed"
        }
    }
}
