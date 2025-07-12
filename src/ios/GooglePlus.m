#import "AppDelegate.h"
#import "objc/runtime.h"
#import "GooglePlus.h"

@implementation GooglePlus

- (void)pluginInitialize
{
    NSLog(@"GooglePlus pluginInitizalize");
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleOpenURL:) name:CDVPluginHandleOpenURLNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleOpenURLWithAppSourceAndAnnotation:) name:CDVPluginHandleOpenURLWithAppSourceAndAnnotationNotification object:nil];
}

- (void)handleOpenURL:(NSNotification*)notification
{
    // GoogleSignIn 6.x já cuida disso pelo SceneDelegate
}

- (void)handleOpenURLWithAppSourceAndAnnotation:(NSNotification*)notification
{
    // GoogleSignIn 6.x já cuida disso pelo SceneDelegate
}

- (void) isAvailable:(CDVInvokedUrlCommand*)command {
  CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:YES];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) login:(CDVInvokedUrlCommand*)command {
    self.callbackId = command.callbackId;
    NSDictionary* options = command.arguments[0];
    NSString* clientId = [self getClientId];
    NSString* serverClientId = options[@"webClientId"];
    NSString* scopesString = options[@"scopes"];
    NSString* loginHint = options[@"loginHint"];
    NSString* hostedDomain = options[@"hostedDomain"];

    // Configuração do GoogleSignIn 6.x+
    GIDConfiguration *config = [[GIDConfiguration alloc] initWithClientID:clientId serverClientID:serverClientId];

    NSArray* scopes = @[@"email", @"profile"];
    if (scopesString != nil) {
        scopes = [scopesString componentsSeparatedByString:@" "];
    }

    [GIDSignIn.sharedInstance signInWithConfiguration:config
                            presentingViewController:self.viewController
                                            hint:loginHint
                                       hostedDomain:hostedDomain
                                             scopes:scopes
                                         completion:^(GIDGoogleUser *user, NSError *error) {
        [self handleSignIn:user error:error];
    }];
}

- (void) trySilentLogin:(CDVInvokedUrlCommand*)command {
    self.callbackId = command.callbackId;
    NSString* clientId = [self getClientId];
    GIDConfiguration *config = [[GIDConfiguration alloc] initWithClientID:clientId];
    [GIDSignIn.sharedInstance restorePreviousSignInWithCompletion:^(GIDGoogleUser *user, NSError *error) {
        [self handleSignIn:user error:error];
    }];
}

- (void) logout:(CDVInvokedUrlCommand*)command {
    [GIDSignIn.sharedInstance signOut];
    CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"logged out"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) disconnect:(CDVInvokedUrlCommand*)command {
    [GIDSignIn.sharedInstance disconnectWithCompletion:^(NSError * _Nullable error) {
        CDVPluginResult * pluginResult;
        if (error) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
        } else {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"disconnected"];
        }
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void) share_unused:(CDVInvokedUrlCommand*)command {
  // Não implementado
}

- (void)handleSignIn:(GIDGoogleUser *)user error:(NSError *)error {
    if (error || !user) {
        CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:(error ? error.localizedDescription : @"Sign-in failed")];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
        return;
    }

    NSString *email = user.profile.email;
    NSString *idToken = user.authentication.idToken;
    NSString *accessToken = user.authentication.accessToken;
    NSString *refreshToken = user.authentication.refreshToken;
    NSString *userId = user.userID;
    NSString *serverAuthCode = user.serverAuthCode != nil ? user.serverAuthCode : @"";
    NSURL *imageUrl = [user.profile imageURLWithDimension:120];
    NSDictionary *result = @{
        @"email"           : email ?: [NSNull null],
        @"idToken"         : idToken ?: [NSNull null],
        @"serverAuthCode"  : serverAuthCode ?: [NSNull null],
        @"accessToken"     : accessToken ?: [NSNull null],
        @"refreshToken"    : refreshToken ?: [NSNull null],
        @"userId"          : userId ?: [NSNull null],
        @"displayName"     : user.profile.name ?: [NSNull null],
        @"givenName"       : user.profile.givenName ?: [NSNull null],
        @"familyName"      : user.profile.familyName ?: [NSNull null],
        @"imageUrl"        : imageUrl ? imageUrl.absoluteString : [NSNull null],
    };

    CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:result];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
}

- (NSString*) getClientId {
    NSArray* URLTypes = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleURLTypes"];
    if (URLTypes != nil) {
        for (NSDictionary* dict in URLTypes) {
            NSString *urlName = dict[@"CFBundleURLName"];
            if ([urlName isEqualToString:@"REVERSED_CLIENT_ID"]) {
                NSArray* URLSchemes = dict[@"CFBundleURLSchemes"];
                if (URLSchemes != nil) {
                    NSString *reversedClientId = URLSchemes[0];
                    return [self reverseUrlScheme:reversedClientId];
                }
            }
        }
    }
    return nil;
}

- (NSString*) reverseUrlScheme:(NSString*)scheme {
    NSArray* originalArray = [scheme componentsSeparatedByString:@"."];
    NSArray* reversedArray = [[originalArray reverseObjectEnumerator] allObjects];
    NSString* reversedString = [reversedArray componentsJoinedByString:@"."];
    return reversedString;
}

@end
