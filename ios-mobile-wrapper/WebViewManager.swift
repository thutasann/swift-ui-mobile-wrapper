import Foundation
import WebKit
import SwiftUI

class WebViewManager: NSObject, ObservableObject {
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var isLoading = false
    @Published var title = ""
    
    private var webView: WKWebView?
    private let websiteURL: String
    
    init(websiteURL: String = "https://your-website.com") {
        self.websiteURL = websiteURL
        super.init()
        setupWebView()
    }
    
    private func setupWebView() {
        let configuration = WKWebViewConfiguration()
        
        // Enable JavaScript
        configuration.preferences.javaScriptEnabled = true
        
        // Allow inline media playback
        configuration.allowsInlineMediaPlayback = true
        
        // Configure user agent to appear as mobile Safari
        configuration.applicationNameForUserAgent = "Mobile Safari"
        
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView?.navigationDelegate = self
        webView?.uiDelegate = self
        
        loadWebsite()
    }
    
    func getWebView() -> WKWebView? {
        return webView
    }
    
    func loadWebsite() {
        guard let url = URL(string: websiteURL) else { return }
        let request = URLRequest(url: url)
        webView?.load(request)
    }
    
    func goBack() {
        webView?.goBack()
    }
    
    func goForward() {
        webView?.goForward()
    }
    
    func reload() {
        webView?.reload()
    }
    
    func handleOAuthRedirect(url: URL) {
        print("Handling OAuth redirect: \(url.absoluteString)")
        
        // Extract parameters from the URL
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems
        
        // Build the redirect URL for your website
        var redirectURL = websiteURL
        
        // If there are OAuth parameters, append them
        if let items = queryItems, !items.isEmpty {
            let paramString = items.map { "\($0.name)=\($0.value ?? "")" }.joined(separator: "&")
            redirectURL += "?oauth_callback=true&\(paramString)"
        }
        
        // Navigate to the website with OAuth parameters
        if let url = URL(string: redirectURL) {
            webView?.load(URLRequest(url: url))
        }
    }
}

extension WebViewManager: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.async {
            self.canGoBack = webView.canGoBack
            self.canGoForward = webView.canGoForward
            self.isLoading = false
            self.title = webView.title ?? ""
        }
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        DispatchQueue.main.async {
            self.isLoading = true
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        DispatchQueue.main.async {
            self.isLoading = false
        }
        print("Navigation failed: \(error.localizedDescription)")
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }
        
        let urlString = url.absoluteString
        print("Navigation to: \(urlString)")
        
        // Handle OAuth URLs
        if urlString.contains("accounts.google.com") || 
           urlString.contains("appleid.apple.com") ||
           urlString.contains("oauth") {
            
            // For OAuth URLs, we want to allow navigation but monitor for completion
            decisionHandler(.allow)
            
            // Set up a timer to check if the OAuth flow is complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.checkOAuthCompletion()
            }
            return
        }
        
        // Handle custom URL schemes (OAuth callbacks)
        if url.scheme == "your-app-scheme" ||
           url.scheme?.contains("com.googleusercontent.apps") == true ||
           url.scheme?.contains("com.yourcompany.ios-mobile-wrapper") == true {
            
            handleOAuthRedirect(url: url)
            decisionHandler(.cancel)
            return
        }
        
        // Allow all other navigation
        decisionHandler(.allow)
    }
    
    private func checkOAuthCompletion() {
        // Check if we're still on an OAuth page
        guard let webView = webView,
              let currentURL = webView.url?.absoluteString else { return }
        
        // If we're still on Google or Apple OAuth pages, check for completion indicators
        if currentURL.contains("accounts.google.com") || currentURL.contains("appleid.apple.com") {
            
            // Inject JavaScript to check for completion
            let script = """
                (function() {
                    // Check for common OAuth completion indicators
                    var doneButton = document.querySelector('button[type="submit"]');
                    var continueButton = document.querySelector('button[data-continue="true"]');
                    var closeButton = document.querySelector('button[aria-label="Close"]');
                    
                    // Check if the page indicates completion
                    var bodyText = document.body.innerText.toLowerCase();
                    var isComplete = bodyText.includes('success') || 
                                   bodyText.includes('authorized') || 
                                   bodyText.includes('complete') ||
                                   bodyText.includes('done');
                    
                    return {
                        hasButtons: !!(doneButton || continueButton || closeButton),
                        isComplete: isComplete,
                        url: window.location.href
                    };
                })();
            """
            
            webView.evaluateJavaScript(script) { [weak self] result, error in
                if let result = result as? [String: Any],
                   let isComplete = result["isComplete"] as? Bool,
                   isComplete {
                    
                    // OAuth appears to be complete, redirect back to website
                    DispatchQueue.main.async {
                        self?.loadWebsite()
                    }
                }
            }
        }
    }
}

extension WebViewManager: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        
        // Handle popup windows (common in OAuth flows)
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        
        return nil
    }
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        
        // Handle JavaScript alerts
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completionHandler()
        })
        
        // Present the alert
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(alert, animated: true)
        }
    }
} 