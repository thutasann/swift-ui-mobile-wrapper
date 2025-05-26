//
//  ContentView.swift
//  ios-mobile-wrapper
//
//  Created by Thuta sann on 5/26/25.
//

import SwiftUI
import WebKit

struct ContentView: View {
    @StateObject private var webViewManager = WebViewManager(websiteURL: "https://your-website.com")
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // Loading indicator
                if webViewManager.isLoading {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemBackground))
                } else {
                    // WebView
                    WebViewRepresentable(webViewManager: webViewManager)
                }
            }
            .navigationTitle(webViewManager.title.isEmpty ? "App" : webViewManager.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button(action: {
                        webViewManager.goBack()
                    }) {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(!webViewManager.canGoBack)
                    
                    Button(action: {
                        webViewManager.goForward()
                    }) {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(!webViewManager.canGoForward)
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: {
                        webViewManager.reload()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    
                    Button(action: {
                        webViewManager.loadWebsite()
                    }) {
                        Image(systemName: "house")
                    }
                }
            }
        }
        .onOpenURL { url in
            // Handle OAuth redirects
            print("App opened with URL: \(url.absoluteString)")
            webViewManager.handleOAuthRedirect(url: url)
        }
        .alert("Notice", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
}

struct WebViewRepresentable: UIViewRepresentable {
    let webViewManager: WebViewManager
    
    func makeUIView(context: Context) -> WKWebView {
        return webViewManager.getWebView() ?? WKWebView()
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // No updates needed
    }
}

#Preview {
    ContentView()
}
