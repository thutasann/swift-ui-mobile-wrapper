# iOS Mobile Wrapper App

This iOS app wraps your website in a native mobile app with proper OAuth authentication support for Google and Apple Sign-In.

## Features

- ✅ WebView wrapper for your website
- ✅ Apple Sign-In OAuth support
- ✅ Google OAuth support with proper redirect handling
- ✅ Navigation controls (back, forward, reload, home)
- ✅ Loading indicators
- ✅ URL scheme handling for OAuth callbacks

## Setup Instructions

### 1. Update Website URL

In `ContentView.swift` and `WebViewManager.swift`, replace `"https://your-website.com"` with your actual website URL:

```swift
@StateObject private var webViewManager = WebViewManager(websiteURL: "https://yourdomain.com")
```

### 2. Configure URL Schemes

In `Info.plist`, update the URL schemes:

#### For Google OAuth:
1. Replace `YOUR_GOOGLE_CLIENT_ID` with your actual Google OAuth client ID
2. The scheme should be: `com.googleusercontent.apps.YOUR_GOOGLE_CLIENT_ID`

#### For Custom App Scheme:
1. Replace `your-app-scheme` with your preferred custom scheme
2. Replace `com.yourcompany.ios-mobile-wrapper` with your app's bundle identifier

### 3. Bundle Identifier

Update your app's bundle identifier in Xcode:
1. Select your project in Xcode
2. Go to "Signing & Capabilities"
3. Update the Bundle Identifier to match your domain (e.g., `com.yourdomain.mobile-app`)

### 4. Website OAuth Configuration

Configure your website's OAuth settings to include the iOS app redirect URIs:

#### Google OAuth Console:
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Navigate to "APIs & Services" > "Credentials"
3. Edit your OAuth 2.0 Client ID
4. Add these redirect URIs:
   - `com.googleusercontent.apps.YOUR_GOOGLE_CLIENT_ID://oauth/callback`
   - `your-app-scheme://oauth/google`

#### Apple Developer Console:
1. Go to [Apple Developer](https://developer.apple.com/)
2. Navigate to "Certificates, Identifiers & Profiles"
3. Configure your App ID with "Sign In with Apple" capability
4. Add redirect URI: `com.yourcompany.ios-mobile-wrapper.apple://oauth/callback`

### 5. Website Integration

Update your website's OAuth implementation to handle mobile app redirects:

```javascript
// Detect if running in iOS app
const isIOSApp = window.navigator.userAgent.includes('Mobile Safari') && 
                 window.webkit && window.webkit.messageHandlers;

// Configure OAuth redirect URIs based on platform
const getRedirectURI = (provider) => {
  if (isIOSApp) {
    switch(provider) {
      case 'google':
        return 'com.googleusercontent.apps.YOUR_GOOGLE_CLIENT_ID://oauth/callback';
      case 'apple':
        return 'com.yourcompany.ios-mobile-wrapper.apple://oauth/callback';
      default:
        return 'your-app-scheme://oauth/callback';
    }
  } else {
    // Web redirect URIs
    return `${window.location.origin}/auth/callback/${provider}`;
  }
};
```

### 6. Testing OAuth Flow

1. Build and run the app on a device or simulator
2. Navigate to your website's login page
3. Click on Google or Apple Sign-In
4. Complete the OAuth flow
5. The app should automatically redirect back to your website

## Troubleshooting

### Google OAuth Not Redirecting Back

1. **Check URL Schemes**: Ensure the Google OAuth client ID in `Info.plist` matches exactly
2. **Verify Redirect URIs**: Make sure your Google OAuth console has the correct redirect URIs
3. **Check Website Configuration**: Ensure your website is using the correct redirect URI for mobile

### Apple Sign-In Issues

1. **App ID Configuration**: Ensure "Sign In with Apple" is enabled in your App ID
2. **Bundle Identifier**: Make sure it matches between Xcode and Apple Developer console
3. **Redirect URI**: Verify the redirect URI in your Apple Developer configuration

### General WebView Issues

1. **HTTPS Required**: Ensure your website uses HTTPS
2. **CORS Settings**: Check your website's CORS configuration
3. **JavaScript**: Ensure JavaScript is enabled (it is by default in this implementation)

## File Structure

```
ios-mobile-wrapper/
├── ContentView.swift          # Main UI with WebView
├── WebViewManager.swift       # WebView management and OAuth handling
├── ios_mobile_wrapperApp.swift # App entry point
├── Info.plist                # App configuration and URL schemes
└── README.md                 # This file
```

## Customization

### Changing App Appearance

Modify the toolbar buttons and navigation in `ContentView.swift`:

```swift
.toolbar {
    // Add or remove toolbar buttons here
}
```

### Adding Custom JavaScript

Inject custom JavaScript in `WebViewManager.swift`:

```swift
private func injectCustomScript() {
    let script = """
        // Your custom JavaScript here
    """
    webView?.evaluateJavaScript(script)
}
```

### Handling Additional URL Schemes

Add more URL scheme handling in `WebViewManager.swift`:

```swift
// In decidePolicyFor navigationAction
if url.scheme == "your-custom-scheme" {
    // Handle custom scheme
    decisionHandler(.cancel)
    return
}
```

## Security Considerations

1. **Remove NSAllowsArbitraryLoads**: In production, remove this from `Info.plist` and use proper HTTPS
2. **Validate Redirects**: Always validate OAuth redirect parameters
3. **Secure Storage**: Use Keychain for storing sensitive data if needed

## Support

For issues related to:
- **OAuth Configuration**: Check your OAuth provider's documentation
- **iOS Development**: Refer to Apple's documentation
- **WebView Issues**: Check WKWebView documentation

## License

This project is provided as-is for educational and development purposes. 