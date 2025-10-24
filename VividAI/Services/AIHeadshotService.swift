import Foundation
import UIKit
import Combine
import SwiftUI
import os.log
import CoreFoundation
import CoreGraphics
import CoreData

class AIHeadshotService: ObservableObject {
    static let shared = AIHeadshotService()
    
    @Published var isProcessing = false
    @Published var processingProgress: Double = 0.0
    
    private let configuration = ConfigurationService.shared
    private let realTimeService = RealTimeGenerationService.shared
    private var baseURL: String {
        configuration.replicateBaseURL
    }
    
    init() {}
    
    func generateHeadshots(from image: UIImage, completion: @escaping (Result<[HeadshotResult], Error>) -> Void) {
        // Check if API is configured
        guard configuration.isReplicateConfigured else {
            DispatchQueue.main.async {
                self.isProcessing = false
                completion(.failure(AIHeadshotError.apiNotConfigured))
            }
            return
        }
        
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
        // Generate multiple viral styles using different Replicate models
        let styles = [
            // Viral-Proven Styles (Article Recommended)
            ("Professional Headshot", "stability-ai/stable-diffusion:27b93a2413e7f36cd83da926f3656280b2931564ff050bf9575f1fdf9bcd747e", "professional headshot, business portrait, high quality, corporate style", false),
            ("AI Yearbook Photos", "catacolabs/yearbook-pics:556bdffb674f9397e6f70d1607225f1ee2dad99502d15f44ba19d55103e1cba3", "90s yearbook photo, vintage portrait, high school senior photo", false),
            ("Anime/Cartoon Style", "tencentarc/animeganv2:latest", "anime style, cartoon character, stylized portrait, vibrant colors", true),
            ("Renaissance Art", "stability-ai/stable-diffusion:27b93a2413e7f36cd83da926f3656280b2931564ff050bf9575f1fdf9bcd747e", "renaissance painting, classical art, oil painting style, masterpiece", true),
            ("Cyberpunk Future", "stability-ai/stable-diffusion:27b93a2413e7f36cd83da926f3656280b2931564ff050bf9575f1fdf9bcd747e", "cyberpunk style, neon lights, futuristic, sci-fi, high tech", true),
            ("Disney/Pixar Style", "stability-ai/stable-diffusion:27b93a2413e7f36cd83da926f3656280b2931564ff050bf9575f1fdf9bcd747e", "disney pixar style, animated character, 3d rendered, family friendly", true),
            // Age Progression/Regression (Huge Viral Potential - Article Recommended)
            ("Age Progression (Older)", "stability-ai/stable-diffusion:27b93a2413e7f36cd83da926f3656280b2931564ff050bf9575f1fdf9bcd747e", "older person, aged face, senior citizen, wrinkles, gray hair, mature features, realistic aging", true),
            ("Age Regression (Younger)", "stability-ai/stable-diffusion:27b93a2413e7f36cd83da926f3656280b2931564ff050bf9575f1fdf9bcd747e", "young person, youthful face, teenager, smooth skin, young features, baby face, de-aged", true),
            // Additional Professional Styles
            ("Executive Corporate", "stability-ai/stable-diffusion:27b93a2413e7f36cd83da926f3656280b2931564ff050bf9575f1fdf9bcd747e", "executive portrait, corporate headshot, professional business", false),
            ("Creative Director", "stability-ai/stable-diffusion:27b93a2413e7f36cd83da926f3656280b2931564ff050bf9575f1fdf9bcd747e", "creative director, artistic portrait, modern professional", true)
        ]
        
        // Process each style
        processMultipleStyles(styles: styles, imageURL: imageURL, completion: completion)
    }
    
    private func processMultipleStyles(styles: [(String, String, String, Bool)], imageURL: String, completion: @escaping (Result<[HeadshotResult], Error>) -> Void) {
        let dispatchGroup = DispatchGroup()
        var results: [HeadshotResult] = []
        var errors: [Error] = []
        
        for (index, style) in styles.enumerated() {
            dispatchGroup.enter()
            
            let requestBody: [String: Any] = [
                "version": style.1,
                "input": [
                    "prompt": style.2,
                    "image": imageURL,
                    "num_outputs": 1,
                    "guidance_scale": 7.5,
                    "num_inference_steps": 20
                ]
            ]
            
            makeReplicateAPIRequest(requestBody: requestBody) { result in
                switch result {
                case .success(let headshots):
                    // Add style-specific results
                    for headshot in headshots {
                        let styledResult = HeadshotResult(
                            id: index + 1,
                            style: style.0,
                            imageURL: headshot.imageURL,
                            isPremium: style.3
                        )
                        results.append(styledResult)
                    }
                case .failure(let error):
                    errors.append(error)
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            if errors.isEmpty {
                completion(.success(results))
            } else {
                completion(.failure(errors.first ?? AIHeadshotError.apiError("Multiple style processing failed")))
            }
        }
    }
    
    private func makeReplicateAPIRequest(requestBody: [String: Any], completion: @escaping (Result<[HeadshotResult], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/predictions") else {
            completion(.failure(AIHeadshotError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Token \(configuration.replicateAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(AIHeadshotError.jsonSerializationFailed))
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.isProcessing = false
                    completion(.failure(AIHeadshotError.networkError(error.localizedDescription)))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self?.isProcessing = false
                    completion(.failure(AIHeadshotError.invalidResponse))
                    return
                }
                
                guard httpResponse.statusCode == 201 else {
                    self?.isProcessing = false
                    completion(.failure(AIHeadshotError.apiError("HTTP \(httpResponse.statusCode)")))
                    return
                }
                
                guard let data = data else {
                    self?.isProcessing = false
                    completion(.failure(AIHeadshotError.noData))
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let id = json["id"] as? String {
                        // Start polling for results
                        self?.pollForResults(predictionId: id, completion: completion)
                    } else {
                        self?.isProcessing = false
                        completion(.failure(AIHeadshotError.invalidResponse))
                    }
                } catch {
                    self?.isProcessing = false
                    completion(.failure(AIHeadshotError.jsonParsingFailed))
                }
            }
        }.resume()
    }
    
    private func pollForResults(predictionId: String, completion: @escaping (Result<[HeadshotResult], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/predictions/\(predictionId)") else {
            isProcessing = false
            completion(.failure(AIHeadshotError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Token \(configuration.replicateAPIKey)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.isProcessing = false
                    completion(.failure(AIHeadshotError.networkError(error.localizedDescription)))
                    return
                }
                
                guard let data = data else {
                    self?.isProcessing = false
                    completion(.failure(AIHeadshotError.noData))
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let status = json["status"] as? String {
                        
                        switch status {
                        case "succeeded":
                            if let output = json["output"] as? [String] {
                                let results = output.enumerated().map { index, url in
                                    HeadshotResult(
                                        id: index + 1,
                                        style: "Generated Style \(index + 1)",
                                        imageURL: url,
                                        isPremium: index >= 4 // First 4 are free, rest are premium
                                    )
                                }
                                self?.isProcessing = false
                                self?.processingProgress = 1.0
                                completion(.success(results))
                            } else {
                                self?.isProcessing = false
                                completion(.failure(AIHeadshotError.invalidResponse))
                            }
                        case "failed":
                            self?.isProcessing = false
                            completion(.failure(AIHeadshotError.apiError("Prediction failed")))
                        case "starting", "processing":
                            // Update progress and continue polling
                            self?.processingProgress = 0.5
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                self?.pollForResults(predictionId: predictionId, completion: completion)
                            }
                        default:
                            self?.isProcessing = false
                            completion(.failure(AIHeadshotError.apiError("Unknown status: \(status)")))
                        }
                    } else {
                        self?.isProcessing = false
                        completion(.failure(AIHeadshotError.invalidResponse))
                    }
                } catch {
                    self?.isProcessing = false
                    completion(.failure(AIHeadshotError.jsonParsingFailed))
                }
            }
        }.resume()
    }
    
    private func createMockHeadshots() -> [HeadshotResult] {
        return [
            // Viral-Proven Styles (Article Recommended)
            HeadshotResult(
                id: 1,
                style: "Professional Headshot",
                imageURL: "https://example.com/headshot1.jpg",
                isPremium: false
            ),
            HeadshotResult(
                id: 2,
                style: "AI Yearbook Photos",
                imageURL: "https://example.com/headshot2.jpg",
                isPremium: false
            ),
            HeadshotResult(
                id: 3,
                style: "Anime/Cartoon Style",
                imageURL: "https://example.com/headshot3.jpg",
                isPremium: true
            ),
            HeadshotResult(
                id: 4,
                style: "Renaissance Art",
                imageURL: "https://example.com/headshot4.jpg",
                isPremium: true
            ),
            HeadshotResult(
                id: 5,
                style: "Cyberpunk Future",
                imageURL: "https://example.com/headshot5.jpg",
                isPremium: true
            ),
            HeadshotResult(
                id: 6,
                style: "Disney/Pixar Style",
                imageURL: "https://example.com/headshot6.jpg",
                isPremium: true
            ),
            // Age Progression/Regression (Huge Viral Potential - Article Recommended)
            HeadshotResult(
                id: 7,
                style: "Age Progression (Older)",
                imageURL: "https://example.com/headshot7.jpg",
                isPremium: true
            ),
            HeadshotResult(
                id: 8,
                style: "Age Regression (Younger)",
                imageURL: "https://example.com/headshot8.jpg",
                isPremium: true
            ),
            // Additional Professional Styles
            HeadshotResult(
                id: 9,
                style: "Executive Corporate",
                imageURL: "https://example.com/headshot9.jpg",
                isPremium: false
            ),
            HeadshotResult(
                id: 10,
                style: "Creative Director",
                imageURL: "https://example.com/headshot10.jpg",
                isPremium: true
            )
        ]
    }
    
    func getCostEstimate() -> Double {
        // Cost per headshot generation via Replicate API
        return 0.008 // $0.008 per generation
    }
    
    // MARK: - Real-Time Generation Methods
    
    func generateRealTimePreview(from image: UIImage, style: AvatarStyle) async throws -> UIImage {
        return try await realTimeService.generateInstantPreview(from: image, style: style)
    }
    
    func generateMultiplePreviews(from image: UIImage, styles: [AvatarStyle]) async throws -> [StylePreview] {
        return try await realTimeService.generateMultiplePreviews(from: image, styles: styles)
    }
    
    func switchStyleInstantly(from currentImage: UIImage, to newStyle: AvatarStyle) async throws -> UIImage {
        return try await realTimeService.switchStyleInstantly(from: currentImage, to: newStyle)
    }
    
    func getAvailableStyles() -> [AvatarStyle] {
        return AvatarStyle.allStyles
    }
    
    func getRealTimeGenerationTime() -> TimeInterval {
        return realTimeService.getAverageGenerationTime()
    }
    
    func clearRealTimeCache() {
        realTimeService.clearPreviewCache()
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
    case networkError(String)
    case apiNotConfigured
    case invalidURL
    case jsonSerializationFailed
    case invalidResponse
    case noData
    case jsonParsingFailed
    
    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Failed to convert image"
        case .apiError(let message):
            return "API Error: \(message)"
        case .networkError(let message):
            return "Network Error: \(message)"
        case .apiNotConfigured:
            return "Replicate API is not configured. Please add your API key."
        case .invalidURL:
            return "Invalid API URL"
        case .jsonSerializationFailed:
            return "Failed to serialize request data"
        case .invalidResponse:
            return "Invalid response from server"
        case .noData:
            return "No data received from server"
        case .jsonParsingFailed:
            return "Failed to parse server response"
        }
    }
}