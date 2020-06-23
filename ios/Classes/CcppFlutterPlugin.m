#import "CcppFlutterPlugin.h"
#if __has_include(<ccppflutterplugin/ccppflutterplugin-Swift.h>)
#import <ccppflutterplugin/ccppflutterplugin-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "ccppflutterplugin-Swift.h"
#endif

@implementation CcppFlutterPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftCcppFlutterPlugin registerWithRegistrar:registrar];
}
@end
