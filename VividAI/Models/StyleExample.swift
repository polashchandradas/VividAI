import Foundation
import SwiftUI
import UIKit

// MARK: - Style Example Model

struct StyleExample: Identifiable, Hashable {
    let id = UUID()
    let styleId: String
    let styleName: String
    let description: String
    let sampleImageName: String
    let isPremium: Bool
    let category: StyleCategory
    let tags: [String]
    let processingTime: TimeInterval
    let popularity: Int // 1-5 stars
    
    init(styleId: String, styleName: String, description: String, sampleImageName: String, isPremium: Bool = false, category: StyleCategory, tags: [String] = [], processingTime: TimeInterval = 5.0, popularity: Int = 3) {
        self.styleId = styleId
        self.styleName = styleName
        self.description = description
        self.sampleImageName = sampleImageName
        self.isPremium = isPremium
        self.category = category
        self.tags = tags
        self.processingTime = processingTime
        self.popularity = popularity
    }
    
    // MARK: - Computed Properties
    
    var sampleImage: Image {
        Image(sampleImageName)
    }
    
    var uiImage: UIImage? {
        UIImage(named: sampleImageName)
    }
    
    var popularityStars: String {
        String(repeating: "⭐", count: popularity)
    }
    
    var processingTimeText: String {
        if processingTime < 60 {
            return "\(Int(processingTime))s"
        } else {
            let minutes = Int(processingTime / 60)
            return "\(minutes)m"
        }
    }
}

// MARK: - Style Category

enum StyleCategory: String, CaseIterable {
    case professional = "Professional"
    case artistic = "Artistic"
    case cartoon = "Cartoon"
    case fantasy = "Fantasy"
    case vintage = "Vintage"
    case modern = "Modern"
    case creative = "Creative"
    
    var icon: String {
        switch self {
        case .professional:
            return "person.crop.circle"
        case .artistic:
            return "paintbrush"
        case .cartoon:
            return "face.smiling"
        case .fantasy:
            return "wand.and.stars"
        case .vintage:
            return "clock"
        case .modern:
            return "sparkles"
        case .creative:
            return "lightbulb"
        }
    }
    
    var color: Color {
        switch self {
        case .professional:
            return .blue
        case .artistic:
            return .purple
        case .cartoon:
            return .orange
        case .fantasy:
            return .pink
        case .vintage:
            return .brown
        case .modern:
            return .cyan
        case .creative:
            return .yellow
        }
    }
}

// MARK: - Style Example Manager

class StyleExampleManager: ObservableObject {
    static let shared = StyleExampleManager()
    
    @Published var allExamples: [StyleExample] = []
    @Published var filteredExamples: [StyleExample] = []
    @Published var selectedCategory: StyleCategory? = nil
    @Published var searchText: String = ""
    
    private init() {
        loadStyleExamples()
        updateFilteredExamples()
    }
    
    // MARK: - Style Examples Data
    
    private func loadStyleExamples() {
        allExamples = [
            // Professional Styles
            StyleExample(
                styleId: "professional_headshot",
                styleName: "Professional Headshot",
                description: "Clean, corporate-style headshots perfect for LinkedIn and business profiles",
                sampleImageName: "sample_professional_headshot",
                isPremium: false,
                category: .professional,
                tags: ["business", "corporate", "linkedin", "professional"],
                processingTime: 8.0,
                popularity: 5
            ),
            
            StyleExample(
                styleId: "executive_portrait",
                styleName: "Executive Portrait",
                description: "High-end executive portraits with premium lighting and composition",
                sampleImageName: "sample_executive_portrait",
                isPremium: true,
                category: .professional,
                tags: ["executive", "premium", "business", "corporate"],
                processingTime: 12.0,
                popularity: 4
            ),
            
            // Artistic Styles
            StyleExample(
                styleId: "renaissance_art",
                styleName: "Renaissance Art",
                description: "Classical Renaissance painting style with rich colors and dramatic lighting",
                sampleImageName: "sample_renaissance_art",
                isPremium: false,
                category: .artistic,
                tags: ["classical", "renaissance", "art", "painting"],
                processingTime: 15.0,
                popularity: 4
            ),
            
            StyleExample(
                styleId: "oil_painting",
                styleName: "Oil Painting",
                description: "Traditional oil painting style with brushstrokes and artistic texture",
                sampleImageName: "sample_oil_painting",
                isPremium: true,
                category: .artistic,
                tags: ["oil", "painting", "artistic", "traditional"],
                processingTime: 18.0,
                popularity: 3
            ),
            
            // Cartoon Styles
            StyleExample(
                styleId: "anime_cartoon",
                styleName: "Anime/Cartoon Style",
                description: "Japanese anime-inspired cartoon style with large eyes and vibrant colors",
                sampleImageName: "sample_anime_cartoon",
                isPremium: false,
                category: .cartoon,
                tags: ["anime", "cartoon", "japanese", "cute"],
                processingTime: 6.0,
                popularity: 5
            ),
            
            StyleExample(
                styleId: "disney_pixar",
                styleName: "Disney/Pixar Style",
                description: "Beloved Disney and Pixar animation style with warm, friendly characters",
                sampleImageName: "sample_disney_pixar",
                isPremium: true,
                category: .cartoon,
                tags: ["disney", "pixar", "animation", "family"],
                processingTime: 10.0,
                popularity: 5
            ),
            
            StyleExample(
                styleId: "comic_book",
                styleName: "Comic Book Style",
                description: "Bold comic book style with strong lines and vibrant colors",
                sampleImageName: "sample_comic_book",
                isPremium: false,
                category: .cartoon,
                tags: ["comic", "superhero", "bold", "vibrant"],
                processingTime: 7.0,
                popularity: 4
            ),
            
            // Fantasy Styles
            StyleExample(
                styleId: "cyberpunk_future",
                styleName: "Cyberpunk Future",
                description: "Futuristic cyberpunk style with neon lights and sci-fi elements",
                sampleImageName: "sample_cyberpunk_future",
                isPremium: true,
                category: .fantasy,
                tags: ["cyberpunk", "future", "sci-fi", "neon"],
                processingTime: 12.0,
                popularity: 4
            ),
            
            StyleExample(
                styleId: "fantasy_warrior",
                styleName: "Fantasy Warrior",
                description: "Epic fantasy warrior style with armor and mystical elements",
                sampleImageName: "sample_fantasy_warrior",
                isPremium: true,
                category: .fantasy,
                tags: ["fantasy", "warrior", "epic", "mystical"],
                processingTime: 14.0,
                popularity: 3
            ),
            
            // Vintage Styles
            StyleExample(
                styleId: "vintage_portrait",
                styleName: "Vintage Portrait",
                description: "Classic vintage photography style with sepia tones and retro aesthetics",
                sampleImageName: "sample_vintage_portrait",
                isPremium: false,
                category: .vintage,
                tags: ["vintage", "retro", "classic", "sepia"],
                processingTime: 9.0,
                popularity: 3
            ),
            
            StyleExample(
                styleId: "film_noir",
                styleName: "Film Noir",
                description: "Dramatic film noir style with high contrast and moody lighting",
                sampleImageName: "sample_film_noir",
                isPremium: true,
                category: .vintage,
                tags: ["film", "noir", "dramatic", "moody"],
                processingTime: 11.0,
                popularity: 2
            ),
            
            // Modern Styles
            StyleExample(
                styleId: "minimalist",
                styleName: "Minimalist",
                description: "Clean, minimalist style with simple lines and modern aesthetics",
                sampleImageName: "sample_minimalist",
                isPremium: false,
                category: .modern,
                tags: ["minimalist", "clean", "modern", "simple"],
                processingTime: 5.0,
                popularity: 4
            ),
            
            StyleExample(
                styleId: "abstract_art",
                styleName: "Abstract Art",
                description: "Modern abstract art style with bold colors and geometric shapes",
                sampleImageName: "sample_abstract_art",
                isPremium: true,
                category: .modern,
                tags: ["abstract", "geometric", "modern", "bold"],
                processingTime: 13.0,
                popularity: 3
            ),
            
            // Creative Styles
            StyleExample(
                styleId: "watercolor",
                styleName: "Watercolor",
                description: "Soft watercolor painting style with flowing colors and artistic texture",
                sampleImageName: "sample_watercolor",
                isPremium: false,
                category: .creative,
                tags: ["watercolor", "soft", "artistic", "flowing"],
                processingTime: 10.0,
                popularity: 4
            ),
            
            StyleExample(
                styleId: "sketch_drawing",
                styleName: "Sketch Drawing",
                description: "Hand-drawn sketch style with pencil lines and artistic shading",
                sampleImageName: "sample_sketch_drawing",
                isPremium: true,
                category: .creative,
                tags: ["sketch", "drawing", "pencil", "artistic"],
                processingTime: 8.0,
                popularity: 3
            ),
            
            StyleExample(
                styleId: "pop_art",
                styleName: "Pop Art",
                description: "Vibrant pop art style inspired by Andy Warhol with bold colors and patterns",
                sampleImageName: "sample_pop_art",
                isPremium: true,
                category: .creative,
                tags: ["pop", "art", "warhol", "vibrant"],
                processingTime: 9.0,
                popularity: 4
            )
        ]
    }
    
    // MARK: - Filtering and Search
    
    func updateFilteredExamples() {
        var filtered = allExamples
        
        // Filter by category
        if let selectedCategory = selectedCategory {
            filtered = filtered.filter { $0.category == selectedCategory }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { example in
                example.styleName.localizedCaseInsensitiveContains(searchText) ||
                example.description.localizedCaseInsensitiveContains(searchText) ||
                example.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Sort by popularity (descending)
        filtered = filtered.sorted { $0.popularity > $1.popularity }
        
        DispatchQueue.main.async {
            self.filteredExamples = filtered
        }
    }
    
    func setCategory(_ category: StyleCategory?) {
        selectedCategory = category
        updateFilteredExamples()
    }
    
    func setSearchText(_ text: String) {
        searchText = text
        updateFilteredExamples()
    }
    
    // MARK: - Helper Methods
    
    func getExamplesForCategory(_ category: StyleCategory) -> [StyleExample] {
        return allExamples.filter { $0.category == category }
    }
    
    func getPopularExamples(limit: Int = 6) -> [StyleExample] {
        return Array(allExamples.sorted { $0.popularity > $1.popularity }.prefix(limit))
    }
    
    func getPremiumExamples() -> [StyleExample] {
        return allExamples.filter { $0.isPremium }
    }
    
    func getFreeExamples() -> [StyleExample] {
        return allExamples.filter { !$0.isPremium }
    }
    
    func getExampleById(_ id: String) -> StyleExample? {
        return allExamples.first { $0.styleId == id }
    }
    
    // MARK: - Analytics
    
    func trackStyleExampleViewed(_ example: StyleExample) {
        ServiceContainer.shared.analyticsService.track(event: "style_example_viewed", parameters: [
            "style_id": example.styleId,
            "style_name": example.styleName,
            "category": example.category.rawValue,
            "is_premium": example.isPremium
        ])
    }
    
    func trackStyleExampleSelected(_ example: StyleExample) {
        ServiceContainer.shared.analyticsService.track(event: "style_example_selected", parameters: [
            "style_id": example.styleId,
            "style_name": example.styleName,
            "category": example.category.rawValue,
            "is_premium": example.isPremium
        ])
    }
}

// MARK: - Style Example Extensions

extension StyleExample {
    static let mockExamples: [StyleExample] = [
        StyleExample(
            styleId: "professional_headshot",
            styleName: "Professional Headshot",
            description: "Clean, corporate-style headshots perfect for LinkedIn and business profiles",
            sampleImageName: "sample_professional_headshot",
            isPremium: false,
            category: .professional,
            tags: ["business", "corporate", "linkedin"],
            processingTime: 8.0,
            popularity: 5
        ),
        StyleExample(
            styleId: "anime_cartoon",
            styleName: "Anime/Cartoon Style",
            description: "Japanese anime-inspired cartoon style with large eyes and vibrant colors",
            sampleImageName: "sample_anime_cartoon",
            isPremium: false,
            category: .cartoon,
            tags: ["anime", "cartoon", "japanese"],
            processingTime: 6.0,
            popularity: 5
        )
    ]
}
