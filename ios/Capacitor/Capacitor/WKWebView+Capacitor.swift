import Foundation
import WebKit

extension WKWebView: CapacitorExtension {}
public extension CapacitorExtensionTypeWrapper where T == WKWebView {
    var keyboardShouldRequireUserInteraction: Bool? {
        return (self.baseType.associatedKeyboardFlagValue as? NSNumber)?.boolValue
    }

    // the readonly nature of the wrapper extension means we can't use a computed property with a setter
    func setKeyboardShouldRequireUserInteraction(_ flag: Bool? = nil) {
        if let flag = flag {
            self.baseType.associatedKeyboardFlagValue = NSNumber(value: flag)
        } else {
            self.baseType.associatedKeyboardFlagValue = nil
        }
    }
}

private var associatedKeyboardFlagHandle: UInt8 = 0

internal extension WKWebView {
    /**
     * Previously implemented via private WebKit swizzling. iOS does not expose a public API to force
     * programmatic focus without user interaction; this flag is retained for API compatibility but
     * has no effect on WKWebView keyboard behavior.
     */
    var associatedKeyboardFlagValue: Any? {
        get {
            return objc_getAssociatedObject(self, &associatedKeyboardFlagHandle)
        }
        set {
            objc_setAssociatedObject(self, &associatedKeyboardFlagHandle, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
