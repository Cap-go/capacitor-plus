import Foundation

/// Compile-time names for private WebKit / plugin integration points (App Store 2.5.2 static dispatch).
enum CAPAppStorePrivateAPI {
    static let wkContentViewClassName = "WKContentView"
    static let wkElementDidFocusSelector = Selector("_elementDidFocus:userIsInteracting:blurPreviousNode:activityStateChanges:userObject:")
    static let sslPinningHttpRequestHandlerClassName = "SSLPinningHttpRequestHandlerClass"
    static let shouldOverrideLoadSelector = #selector(CAPPlugin.shouldOverrideLoad(_:))
    static let handleWKWebViewURLAuthenticationChallengeSelector = #selector(CAPPlugin.handleWKWebViewURLAuthenticationChallenge(_:completionHandler:))
}
