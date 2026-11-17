#import <Capacitor/Capacitor-Swift.h>
#import <objc/message.h>
#import <objc/runtime.h>

// appstore-2.5.2-allow: forward declare private UIStatusBarManager API for compile-time @selector
@interface UIStatusBarManager (CAPPrivateStatusBarTap)
- (void)handleTapAction:(id)arg1;
@end

@implementation UIStatusBarManager (CAPHandleTapAction)

+ (void)load {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    Class class = [self class];
    // appstore-2.5.2-allow: status bar tap notification for CapacitorStatusBarTapped
    SEL originalSelector = @selector(handleTapAction:);
    SEL swizzledSelector = @selector(nofity_handleTapAction:);

    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);

    BOOL didAddMethod = class_addMethod(class,
                                        originalSelector,
                                        method_getImplementation(swizzledMethod),
                                        method_getTypeEncoding(swizzledMethod));
    if (didAddMethod) {
      // appstore-2.5.2-allow: install status bar tap swizzle when method was not present
      class_replaceMethod(class,
                          swizzledSelector,
                          method_getImplementation(originalMethod),
                          method_getTypeEncoding(originalMethod));
    } else {
      // appstore-2.5.2-allow: exchange status bar tap implementation
      method_exchangeImplementations(originalMethod, swizzledMethod);
    }
  });
}

-(void)nofity_handleTapAction:(id)arg1 {
  [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:NSNotification.capacitorStatusBarTapped object:nil]];
  [self nofity_handleTapAction:arg1];
}

@end
