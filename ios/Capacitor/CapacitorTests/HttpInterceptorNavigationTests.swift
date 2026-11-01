import XCTest

@testable import Capacitor

class HttpInterceptorNavigationTests: XCTestCase {
    private let serverURL = URL(string: "capacitor://localhost")!
    private let localURL = URL(string: "capacitor://localhost")!

    func testBlocksNavigationToInterceptorPathOnAppOrigin() {
        let interceptorURL = URL(
            string: "capacitor://localhost\(CapacitorBridge.httpInterceptorStartIdentifier)?u=https://example.com/payload.html"
        )!
        XCTAssertTrue(
            WebViewDelegationHandler.shouldBlockHttpInterceptorNavigation(
                for: interceptorURL,
                serverURL: serverURL,
                localURL: localURL
            )
        )
    }

    func testDoesNotBlockExternalOriginWithInterceptorPathPrefix() {
        let externalURL = URL(string: "https://example.com\(CapacitorBridge.httpInterceptorStartIdentifier)/page")!
        XCTAssertFalse(
            WebViewDelegationHandler.shouldBlockHttpInterceptorNavigation(
                for: externalURL,
                serverURL: serverURL,
                localURL: localURL
            )
        )
    }

    func testAllowsInAppNavigation() {
        let inAppURL = URL(string: "capacitor://localhost/index.html")!
        XCTAssertFalse(
            WebViewDelegationHandler.shouldBlockHttpInterceptorNavigation(
                for: inAppURL,
                serverURL: serverURL,
                localURL: localURL
            )
        )
    }
}
