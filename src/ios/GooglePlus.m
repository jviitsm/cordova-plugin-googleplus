#import "GooglePlus.h"
@import GoogleSignIn;

@implementation GooglePlus

- (void)pluginInitialize {
    NSLog(@"GooglePlus pluginInitialize");
}

- (void)isAvailable:(CDVInvokedUrlCommand*)command {
    CDVPluginResult* res = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:YES];
    [self.commandDelegate sendPluginResult:res callbackId:command.callbackId];
}

- (void)login:(CDVInvokedUrlCommand*)command {
    self.callbackId = command.callbackId;
    NSDictionary* options = command.arguments[0];

    NSString* clientId       = [self getClientId];
    NSString* serverClientId = options[@"webClientId"];

    GIDConfiguration* config = serverClientId.length > 0
      ? [[GIDConfiguration alloc] initWithClientID:clientId serverClientID:serverClientId]
      : [[GIDConfiguration alloc] initWithClientID:clientId];

    [GIDSignIn.sharedInstance signInWithConfiguration:config
                              presentingViewController:self.viewController
                                              completion:^(GIDGoogleUser * _Nullable user, NSError * _Nullable error) {
        [self handleSignIn:user error:error];
    }];
}

- (void)trySilentLogin:(CDVInvokedUrlCommand*)command {
    self.callbackId = command.callbackId;
    NSString* clientId = [self getClientId];
    GIDConfiguration* config = [[GIDConfiguration alloc] initWithClientID:clientId];

    [GIDSignIn.sharedInstance restorePreviousSignInWithConfiguration:config
                                                       completion:^(GIDGoogleUser * _Nullable user, NSError * _Nullable error) {
        [self handleSignIn:user error:error];
    }];
}

- (void)logout:(CDVInvokedUrlCommand*)command {
    [GIDSignIn.sharedInstance signOut];
    CDVPluginResult* res = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                             messageAsString:@"logged out"];
    [self.commandDelegate sendPluginResult:res callbackId:command.callbackId];
}

- (void)disconnect:(CDVInvokedUrlCommand*)command {
    [GIDSignIn.sharedInstance disconnectWithCompletion:^(NSError * _Nullable error) {
        CDVPluginResult* res = error
          ? [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription]
          : [CDVPluginResult resultWithStatus:CDVCommandStatus_OK   messageAsString:@"disconnected"];
        [self.commandDelegate sendPluginResult:res callbackId:command.callbackId];
    }];
}

- (void)handleSignIn:(GIDGoogleUser*)user error:(NSError*)error {
    if (error || !user) {
        CDVPluginResult* res = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                  messageAsString:(error.localizedDescription ?: @"Sign-in failed")];
        [self.commandDelegate sendPluginResult:res callbackId:self.callbackId];
        return;
    }

    NSDictionary* result = @{
        @"email"          : user.profile.email           ?: [NSNull null],
        @"idToken"        : user.authentication.idToken   ?: [NSNull null],
        @"accessToken"    : user.authentication.accessToken ?: [NSNull null],
        @"refreshToken"   : user.authentication.refreshToken?: [NSNull null],
        @"serverAuthCode": user.serverAuthCode           ?: [NSNull null],
        @"userId"         : user.userID                   ?: [NSNull null],
        @"displayName"    : user.profile.name             ?: [NSNull null],
        @"givenName"      : user.profile.givenName        ?: [NSNull null],
        @"familyName"     : user.profile.familyName       ?: [NSNull null],
        @"imageUrl"       : ([user.profile imageURLWithDimension:120].absoluteString ?: [NSNull null])
    };

    CDVPluginResult* res = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                           messageAsDictionary:result];
    [self.commandDelegate sendPluginResult:res callbackId:self.callbackId];
}

- (NSString*)getClientId {
    NSArray* URLTypes = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleURLTypes"];
    for (NSDictionary* dict in URLTypes) {
        if ([dict[@"CFBundleURLName"] isEqualToString:@"REVERSED_CLIENT_ID"]) {
            NSString* reversed = [(NSArray*)dict[@"CFBundleURLSchemes"] firstObject];
            NSArray* parts = [reversed componentsSeparatedByString:@"."];
            NSArray* rev = [[parts reverseObjectEnumerator] allObjects];
            return [rev componentsJoinedByString:@"."];
        }
    }
    return nil;
}

@end
