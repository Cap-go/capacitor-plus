import XCTest
@testable import Capacitor

class WebViewDelegationHandlerTests: XCTestCase {
    func testScrollViewShouldScrollToTopPostsStatusBarNotification() {
        let handler = WebViewDelegationHandler()
        let expectation = expectation(forNotification: .capacitorStatusBarTapped, object: nil)

        let shouldScroll = handler.scrollViewShouldScrollToTop(UIScrollView())

        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(shouldScroll)
    }
}
