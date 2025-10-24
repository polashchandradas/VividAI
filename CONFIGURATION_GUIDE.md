# VividAI Configuration Guide

## Phase 1: Fix Compilation Issues ✅

### ✅ Completed Tasks:
1. **Removed duplicate app file** - `VividAIApp-NoFirebase.swift` deleted
2. **Updated main app file** - `VividAIApp.swift` now handles Firebase configuration properly
3. **Created ConfigurationService** - Centralized API key management
4. **Updated AIHeadshotService** - Now uses proper configuration instead of hardcoded keys
5. **Enhanced GoogleService-Info.plist** - Added detailed configuration instructions

## Required Configuration Steps

### 1. Firebase Configuration

**Step 1: Create Firebase Project**
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or select existing project
3. Follow the setup wizard

**Step 2: Add iOS App**
1. In Firebase Console, click "Add app" → iOS
2. Enter bundle ID: `com.vividai.app`
3. Download `GoogleService-Info.plist`
4. Replace the existing `VividAI/GoogleService-Info.plist` with downloaded file

**Step 3: Enable Firebase Services**
In Firebase Console, enable these services:
- **Authentication** (Email/Password, Apple Sign-In)
- **Firestore Database** (for user data)
- **Analytics** (for app analytics)
- **Storage** (for image uploads)

### 2. Replicate API Configuration

**Step 1: Create Replicate Account**
1. Go to [Replicate.com](https://replicate.com/)
2. Sign up for an account
3. Get your API token from account settings

**Step 2: Add API Key**
Add your Replicate API key to one of these locations:

**Option A: Info.plist (Recommended for development)**
```xml
<key>REPLICATE_API_KEY</key>
<string>your_actual_api_key_here</string>
```

**Option B: Environment Variables (Recommended for CI/CD)**
```bash
export REPLICATE_API_KEY="your_actual_api_key_here"
```

### 3. Verify Configuration

The app will now:
- ✅ Check Firebase configuration on startup
- ✅ Validate API keys before making requests
- ✅ Show clear error messages if configuration is missing
- ✅ Handle API failures gracefully

## Configuration Status

After setup, the app will show one of these statuses:

- ✅ **Fully Configured** - All APIs working
- ⚠️ **Missing Replicate** - Firebase OK, Replicate needs setup
- ⚠️ **Missing Firebase** - Replicate OK, Firebase needs setup  
- ❌ **Not Configured** - Both APIs need setup

## Next Steps

Once Phase 1 is complete, you can proceed to:
- **Phase 2**: Implement core functionality (real AI processing, navigation)
- **Phase 3**: Add error handling and security measures
- **Phase 4**: Test and optimize performance

## Troubleshooting

### Common Issues:

1. **"Firebase configuration is incomplete"**
   - Solution: Replace GoogleService-Info.plist with actual Firebase file

2. **"Replicate API is not configured"**
   - Solution: Add REPLICATE_API_KEY to Info.plist or environment

3. **Build errors after changes**
   - Solution: Clean build folder (Cmd+Shift+K) and rebuild

4. **App crashes on startup**
   - Solution: Check that all API keys are properly configured

## Security Notes

- Never commit real API keys to version control
- Use environment variables for production
- Keep API keys secure and rotate them regularly
- Monitor API usage to prevent abuse
