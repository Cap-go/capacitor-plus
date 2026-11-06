import WebKit
import XCTest

@testable import Capacitor

private class StubNavigationAction: WKNavigationAction {
    private let stubbedRequest: URLRequest
    init(url: String) {
        self.stubbedRequest = URLRequest(url: URL(string: url)!)
        super.init()
    }
    override var request: URLRequest { stubbedRequest }
}

// The proxy path shares the app's origin, so the origin guard alone would allow it.
class HttpInterceptorNavigationTests: XCTestCase {
    private var bridge: MockBridge!
    private var handler: WebViewDelegationHandler!
    private let webView = WKWebView()

    override func setUp() {
        super.setUp()
        let descriptor = InstanceDescriptor()
        handler = WebViewDelegationHandler()
        bridge = MockBridge(
            with: InstanceConfiguration(with: descriptor, isDebug: true),
            delegate: MockBridgeViewController(),
            cordovaConfiguration: descriptor.cordovaConfiguration,
            assetHandler: MockAssetHandler(router: CapacitorRouter()),
            delegationHandler: handler
        )
    }

    private func policy(for url: String) -> WKNavigationActionPolicy {
        var decision: WKNavigationActionPolicy?
        handler.webView(webView, decidePolicyFor: StubNavigationAction(url: url)) { decision = $0 }
        return decision!
    }

    func testBlocksNavigationToInterceptorPath() {
        let interceptorURL = "capacitor://localhost\(CapacitorBridge.httpInterceptorStartIdentifier)?u=https://example.com/payload.html"
        XCTAssertEqual(policy(for: interceptorURL), .cancel)
    }

    /// Same origin rule as main frame; exercise the static helper (subframe paths also hit this before plugin hooks).
    func testBlocksHttpInterceptorNavigationWhenMatchingAppOrigin() throws {
        let interceptorURL = "capacitor://localhost\(CapacitorBridge.httpInterceptorStartIdentifier)?u=https://example.com/payload.html"
        let url = try XCTUnwrap(URL(string: interceptorURL))
        XCTAssertTrue(
            WebViewDelegationHandler.shouldBlockHttpInterceptorNavigation(
                for: url,
                serverURL: bridge.config.serverURL,
                localURL: bridge.config.localURL
            )
        )
    }

    func testAllowsInAppNavigation() {
        XCTAssertEqual(policy(for: "capacitor://localhost/index.html"), .allow)
    }
}
