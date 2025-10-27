import Foundation
import StoreKit
import SwiftUI

// MARK: - Product Model

struct Product: Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let price: String
    let isPremium: Bool
    let features: [String]
    
    // StoreKit Product
    let storeKitProduct: StoreKit.Product?
    
    init(id: String, name: String, description: String, price: String, isPremium: Bool, features: [String], storeKitProduct: StoreKit.Product? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.price = price
        self.isPremium = isPremium
        self.features = features
        self.storeKitProduct = storeKitProduct
    }
    
    // MARK: - Static Products
    
    static let monthly = Product(
        id: "vividai.monthly",
        name: "Monthly Pro",
        description: "Unlimited AI headshots",
        price: "$9.99/month",
        isPremium: true,
        features: [
            "Unlimited AI headshots",
            "All professional styles",
            "No watermarks",
            "Priority processing",
            "HD downloads"
        ]
    )
    
    static let yearly = Product(
        id: "vividai.yearly",
        name: "Yearly Pro",
        description: "Best value - Save 50%",
        price: "$59.99/year",
        isPremium: true,
        features: [
            "Unlimited AI headshots",
            "All professional styles",
            "No watermarks",
            "Priority processing",
            "HD downloads",
            "Save 50% vs monthly"
        ]
    )
    
    static let lifetime = Product(
        id: "vividai.lifetime",
        name: "Lifetime Pro",
        description: "One-time payment",
        price: "$99.99",
        isPremium: true,
        features: [
            "Unlimited AI headshots",
            "All professional styles",
            "No watermarks",
            "Priority processing",
            "HD downloads",
            "Lifetime access"
        ]
    )
    
    // MARK: - All Products
    
    static let allProducts: [Product] = [monthly, yearly, lifetime]
}
