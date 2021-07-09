#import "FlutterZVoipKitPlugin.h"
#if __has_include(<flutter_zvoip_kit/flutter_zvoip_kit-Swift.h>)
#import <flutter_zvoip_kit/flutter_zvoip_kit-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_zvoip_kit-Swift.h"
#endif

@implementation FlutterZVoipKitPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterZVoipKitPlugin registerWithRegistrar:registrar];
}
@end
