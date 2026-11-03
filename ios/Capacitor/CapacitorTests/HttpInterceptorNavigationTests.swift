import XCTest

@testable import Capacitor

class HttpInterceptorNavigationTests: XCTestCase {
    private let serverURL = URL(string: "capacitor://localhost")!
    private let localURL = URL(string: "capacitor://localhost")!

    func testDoesNotBlockDifferentPortWithInterceptorPathPrefix() {
        let serverURL = URL(string: "https://localhost:8100")!
        let localURL = URL(string: "https://localhost:8100")!
        let differentPortURL = URL(string: "https://localhost:3000\(CapacitorBridge.httpInterceptorStartIdentifier)/page")!
        XCTAssertFalse(
            WebViewDelegationHandler.shouldBlockHttpInterceptorNavigation(
                for: differentPortURL,
                serverURL: serverURL,
                localURL: localURL
            )
        )
    }

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
