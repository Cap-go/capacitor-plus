import XCTest

@testable import Capacitor

class HttpInterceptorNavigationTests: XCTestCase {
    func testBlocksNavigationToInterceptorPath() {
        let interceptorURL = URL(string: "capacitor://localhost\(CapacitorBridge.httpInterceptorStartIdentifier)?u=https://example.com/payload.html")!
        XCTAssertTrue(WebViewDelegationHandler.shouldBlockHttpInterceptorNavigation(for: interceptorURL))
    }

    func testAllowsInAppNavigation() {
        let inAppURL = URL(string: "capacitor://localhost/index.html")!
        XCTAssertFalse(WebViewDelegationHandler.shouldBlockHttpInterceptorNavigation(for: inAppURL))
    }
}
