//
//  WCSecretKeyAccessoryViewController.h
//  WiredClient
//
//  Created by Rafaël Warnault on 13/09/13.
//
//

#import <Cocoa/Cocoa.h>

@interface WCSecretKeyAccessoryViewController : NSViewController {
    IBOutlet NSSecureTextField *secretKeyTextField;
    IBOutlet NSSecureTextField *verifyTextField;
}

+ (NSString *)nibName;
+ (id)viewController;

- (NSString *)secretKey;
- (NSString *)verifyKey;

- (BOOL)verifyKeys;

@end
