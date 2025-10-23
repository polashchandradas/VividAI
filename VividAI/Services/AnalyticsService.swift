import Foundation

class AnalyticsService: ObservableObject {
    static var shared = AnalyticsService()
    
    private init() {}
    
    // MARK: - Event Tracking
    
    func track(event: String, parameters: [String: Any] = [:]) {
        // Mock analytics for testing - in production, this would connect to Firebase
        print("📊 Analytics: \(event) - \(parameters)")
    }
    
    // MARK: - Screen Tracking
    
    func trackScreenView(_ screenName: String) {
        track(event: "screen_view", parameters: ["screen_name": screenName])
    }
    
    // MARK: - User Properties
    
    func setUserProperty(_ value: String?, forName name: String) {
        // Mock user property setting
        print("📊 User Property: \(name) = \(value ?? "nil")")
    }
    
    func setUserId(_ userId: String) {
        // Mock user ID setting
        print("📊 User ID: \(userId)")
    }
    
    // MARK: - Conversion Tracking
    
    func trackConversion(event: String, value: Double, currency: String = "USD") {
        track(event: event, parameters: [
            "value": value,
            "currency": currency
        ])
    }
    
    // MARK: - App-Specific Events
    
    func trackAppLaunch() {
        track(event: "app_launched")
    }
    
    func trackPhotoUploaded(source: String) {
        track(event: "photo_uploaded", parameters: [
            "source": source
        ])
    }
    
    func trackHeadshotGenerated(style: String, isPremium: Bool) {
        track(event: "headshot_generated", parameters: [
            "style": style,
            "is_premium": isPremium
        ])
    }
    
    func trackBackgroundRemoved() {
        track(event: "background_removed")
    }
    
    func trackPhotoEnhanced(type: String) {
        track(event: "photo_enhanced", parameters: [
            "enhancement_type": type
        ])
    }
    
    func trackVideoGenerated() {
        track(event: "video_generated")
    }
    
    func trackShare(platform: String, contentType: String) {
        track(event: "content_shared", parameters: [
            "platform": platform,
            "content_type": contentType
        ])
    }
    
    func trackSubscriptionStarted(plan: String, price: Double) {
        track(event: "subscription_started", parameters: [
            "plan": plan,
            "price": price
        ])
    }
    
    func trackSubscriptionCancelled(plan: String) {
        track(event: "subscription_cancelled", parameters: [
            "plan": plan
        ])
    }
    
    func trackReferralCodeUsed(code: String) {
        track(event: "referral_code_used", parameters: [
            "referral_code": code
        ])
    }
    
    func trackWatermarkRemoved() {
        track(event: "watermark_removed")
    }
    
    // MARK: - Error Tracking
    
    func trackError(_ error: Error, context: String) {
        track(event: "error_occurred", parameters: [
            "error_description": error.localizedDescription,
            "context": context
        ])
    }
    
    func trackAPIError(endpoint: String, statusCode: Int) {
        track(event: "api_error", parameters: [
            "endpoint": endpoint,
            "status_code": statusCode
        ])
    }
    
    // MARK: - Performance Tracking
    
    func trackProcessingTime(feature: String, duration: TimeInterval) {
        track(event: "processing_time", parameters: [
            "feature": feature,
            "duration_seconds": duration
        ])
    }
    
    func trackAppPerformance(metric: String, value: Double) {
        track(event: "app_performance", parameters: [
            "metric": metric,
            "value": value
        ])
    }
    
    // MARK: - User Journey Tracking
    
    func trackUserJourney(step: String, stepNumber: Int) {
        track(event: "user_journey", parameters: [
            "step": step,
            "step_number": stepNumber
        ])
    }
    
    func trackFunnelStep(step: String, conversion: Bool) {
        track(event: "funnel_step", parameters: [
            "step": step,
            "converted": conversion
        ])
    }
    
    // MARK: - A/B Testing
    
    func trackABTest(testName: String, variant: String) {
        track(event: "ab_test", parameters: [
            "test_name": testName,
            "variant": variant
        ])
    }
    
    // MARK: - Retention Tracking
    
    func trackRetention(day: Int) {
        track(event: "retention", parameters: [
            "day": day
        ])
    }
    
    func trackChurn(reason: String) {
        track(event: "churn", parameters: [
            "reason": reason
        ])
    }
    
    // MARK: - Revenue Tracking
    
    func trackRevenue(amount: Double, currency: String = "USD", product: String) {
        track(event: "revenue", parameters: [
            "amount": amount,
            "currency": currency,
            "product": product
        ])
    }
    
    func trackLTV(customerLifetimeValue: Double) {
        track(event: "ltv", parameters: [
            "customer_lifetime_value": customerLifetimeValue
        ])
    }
}

// MARK: - Analytics Constants

extension AnalyticsService {
    struct Events {
        static let appLaunched = "app_launched"
        static let photoUploaded = "photo_uploaded"
        static let headshotGenerated = "headshot_generated"
        static let backgroundRemoved = "background_removed"
        static let photoEnhanced = "photo_enhanced"
        static let videoGenerated = "video_generated"
        static let contentShared = "content_shared"
        static let subscriptionStarted = "subscription_started"
        static let subscriptionCancelled = "subscription_cancelled"
        static let referralCodeUsed = "referral_code_used"
        static let watermarkRemoved = "watermark_removed"
        static let errorOccurred = "error_occurred"
        static let processingTime = "processing_time"
        static let userJourney = "user_journey"
        static let funnelStep = "funnel_step"
        static let abTest = "ab_test"
        static let retention = "retention"
        static let churn = "churn"
        static let revenue = "revenue"
        static let ltv = "ltv"
    }
    
    struct Parameters {
        static let source = "source"
        static let style = "style"
        static let isPremium = "is_premium"
        static let enhancementType = "enhancement_type"
        static let platform = "platform"
        static let contentType = "content_type"
        static let plan = "plan"
        static let price = "price"
        static let referralCode = "referral_code"
        static let errorDescription = "error_description"
        static let context = "context"
        static let endpoint = "endpoint"
        static let statusCode = "status_code"
        static let feature = "feature"
        static let durationSeconds = "duration_seconds"
        static let metric = "metric"
        static let value = "value"
        static let step = "step"
        static let stepNumber = "step_number"
        static let converted = "converted"
        static let testName = "test_name"
        static let variant = "variant"
        static let day = "day"
        static let reason = "reason"
        static let amount = "amount"
        static let currency = "currency"
        static let product = "product"
        static let customerLifetimeValue = "customer_lifetime_value"
    }
}
