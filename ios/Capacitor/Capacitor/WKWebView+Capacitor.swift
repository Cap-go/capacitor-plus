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
        self.baseType.applyKeyboardInteractionPolicy()
    }
}

private var associatedKeyboardFlagHandle: UInt8 = 0

internal extension WKWebView {
    /**
     * Applies `keyboardShouldRequireUserInteraction` using KVC on the embedded WK content view.
     * This mirrors UIWebView's documented `keyboardDisplayRequiresUserAction` behavior without
     * swizzling private WebKit methods (App Store guideline 2.5.2).
     */
    func applyKeyboardInteractionPolicy() {
        guard let requiresUserAction = capacitor.keyboardShouldRequireUserInteraction else {
            return
        }
        guard let contentView = scrollView.subviews.first(where: { String(describing: type(of: $0)).hasPrefix("WK") }) else {
            return
        }
        let selector = Selector(("setKeyboardDisplayRequiresUserAction:"))
        guard contentView.responds(to: selector) else {
            return
        }
        contentView.setValue(requiresUserAction, forKey: "keyboardDisplayRequiresUserAction")
    }

    var associatedKeyboardFlagValue: Any? {
        get {
            return objc_getAssociatedObject(self, &associatedKeyboardFlagHandle)
        }
        set {
            objc_setAssociatedObject(self, &associatedKeyboardFlagHandle, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
