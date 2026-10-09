#import <Foundation/Foundation.h>

/**
 * Optional SSL pinning integration. When the `@capacitor-community/ssl-pinning` (or compatible)
 * handler is linked, its `SSLPinningHttpRequestHandlerClass` should conform to this protocol.
 */
@protocol CAPSSLPinningHttpRequestHandler <NSObject>

+ (void)request:(NSDictionary<NSString *, id> *)info;

@end
