# VividAI - AI Photo/Video Enhancement App

A comprehensive iOS app for AI-powered photo and video enhancement, built with SwiftUI and CoreML.

## Features

### Core Features
- **AI Professional Headshot Generator** - Generate 8+ professional headshot styles
- **Background Removal** - One-tap background removal using CoreML
- **Photo Enhancement** - AI-powered photo enhancement and old photo restoration
- **Video Generation** - Auto-generate 5-second transformation videos for social sharing
- **Freemium Subscription** - Watermarked free tier with premium unlock

### Technical Architecture
- **On-Device Processing** - 90% of operations use CoreML (zero server cost)
- **Cloud API Integration** - Replicate API for AI headshot generation ($0.008 per generation)
- **Hybrid Approach** - Optimal balance of performance and cost
- **StoreKit 2** - Modern subscription management
- **Firebase Integration** - Authentication, analytics, and cloud storage

## Project Structure

```
VividAI/
├── Views/                    # SwiftUI Views
│   ├── SplashScreenView.swift
│   ├── HomeView.swift
│   ├── PhotoUploadView.swift
│   ├── ProcessingView.swift
│   ├── ResultsView.swift
│   ├── PaywallView.swift
│   ├── ShareView.swift
│   └── SettingsView.swift
├── Services/                 # Core Services
│   ├── AIHeadshotService.swift
│   ├── BackgroundRemovalService.swift
│   ├── PhotoEnhancementService.swift
│   ├── VideoGenerationService.swift
│   ├── SubscriptionManager.swift
│   ├── WatermarkService.swift
│   ├── ReferralService.swift
│   └── AnalyticsService.swift
├── Assets.xcassets/         # App Assets
└── VividAI.entitlements     # App Entitlements
```

## Setup Instructions

### 1. Prerequisites
- Xcode 15.0+
- iOS 17.0+
- Firebase project
- Replicate API account

### 2. Firebase Setup
1. Create a Firebase project
2. Add iOS app with bundle ID: `com.vividai.app`
3. Download `GoogleService-Info.plist` and add to project
4. Enable Authentication, Firestore, and Analytics

### 3. API Keys
1. **Replicate API**: Get API key from [Replicate](https://replicate.com)
2. **Firebase**: Configure in `GoogleService-Info.plist`

### 4. App Store Connect
1. Create app in App Store Connect
2. Configure in-app purchases:
   - Annual: `com.vividai.annual` ($39.99/year)
   - Weekly: `com.vividai.weekly` ($4.99/week)
   - Lifetime: `com.vividai.lifetime` ($99.99 one-time)

## Key Features Implementation

### AI Headshot Generation
- Uses Replicate API with Stable Diffusion
- Cost: $0.008 per generation
- 8 different professional styles
- Premium-only feature

### Background Removal
- CoreML Vision framework
- On-device processing (zero cost)
- Real-time face detection
- High-quality segmentation

### Video Generation
- 5-second transformation videos
- 9:16 aspect ratio (TikTok/Instagram optimized)
- Auto-generated with watermarks
- AVFoundation + CoreAnimation

### Subscription Model
- Free: Unlimited with watermarks
- Premium: Remove watermarks + AI headshots
- 3-day free trial
- Annual subscription focus (67% savings)

## Monetization Strategy

### Revenue Streams
1. **Annual Subscriptions** - $39.99/year (primary)
2. **Weekly Subscriptions** - $4.99/week
3. **Lifetime Access** - $99.99 one-time

### Conversion Strategy
- Watermark drives upgrades (60%+ conversion rate)
- AI headshots justify subscription cost
- Free trial reduces friction
- Social sharing drives viral growth

## Analytics & Tracking

### Key Metrics
- **Viral Growth**: K-Factor >1.2, Share Rate >15%
- **Retention**: D1 >45%, D7 >25%, D30 >15%
- **Monetization**: Free-to-Paid >4%, Churn <12%

### Events Tracked
- User journey and funnel steps
- Feature usage and conversion
- Subscription lifecycle
- Referral and sharing behavior

## Development Roadmap

### Phase 1 (MVP - 4 weeks)
- [x] Core UI screens
- [x] AI headshot generation
- [x] Background removal
- [x] Photo enhancement
- [x] Video generation
- [x] Subscription system
- [x] Analytics integration

### Phase 2 (Growth - 8 weeks)
- [ ] Advanced AI models
- [ ] More headshot styles
- [ ] Batch processing
- [ ] Social features
- [ ] Referral system

### Phase 3 (Scale - 12 weeks)
- [ ] Video editing features
- [ ] Advanced filters
- [ ] Team collaboration
- [ ] API for developers

## Technical Specifications

### Performance
- **Processing Time**: 5-10 seconds for headshots
- **On-Device**: 90% of operations (zero server cost)
- **Cloud API**: 10% (premium features only)
- **Monthly Cost**: <$50 for 10,000 MAU

### Architecture
- **SwiftUI** - Modern declarative UI
- **CoreML** - On-device AI processing
- **Firebase** - Backend services
- **StoreKit 2** - Subscription management
- **AVFoundation** - Video processing

## Success Metrics

### Target Goals (12 months)
- **Users**: 500,000 total users
- **Revenue**: $83,250/month
- **Conversion**: 5% free-to-paid
- **Retention**: 15% D30 retention

### Validation Criteria
- K-Factor >1.2 (viral growth)
- Share rate >15% (content creation)
- LTV:CAC >3:1 (unit economics)
- Processing time <10s (user experience)

## Contributing

1. Fork the repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Create Pull Request

## License

Copyright © 2025 VividAI. All rights reserved.

## Support

For support, email support@vividai.app or visit our website at https://vividai.app
