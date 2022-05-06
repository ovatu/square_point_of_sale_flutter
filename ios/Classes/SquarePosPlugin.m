#import "SquarePosPlugin.h"
#if __has_include(<square_pos/square_pos-Swift.h>)
#import <square_pos/square_pos-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "square_pos-Swift.h"
#endif

@implementation SquarePosPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftSquarePosPlugin registerWithRegistrar:registrar];
}
@end
