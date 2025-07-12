#import <Cordova/CDVPlugin.h>
@import GoogleSignIn;

@interface GooglePlus : CDVPlugin

@property(nonatomic, copy) NSString *callbackId;

// Métodos expostos ao JS
- (void)isAvailable:(CDVInvokedUrlCommand *)command;
- (void)login:(CDVInvokedUrlCommand *)command;
- (void)trySilentLogin:(CDVInvokedUrlCommand *)command;
- (void)logout:(CDVInvokedUrlCommand *)command;
- (void)disconnect:(CDVInvokedUrlCommand *)command;

@end
