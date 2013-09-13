//
//  WCSecretKeyAccessoryViewController.m
//  WiredClient
//
//  Created by Rafaël Warnault on 13/09/13.
//
//

#import "WCSecretKeyAccessoryViewController.h"

@interface WCSecretKeyAccessoryViewController ()

@end

@implementation WCSecretKeyAccessoryViewController



#pragma mark -

+ (NSString *)nibName {
    return @"SecretKeyAccessoryView";
}

+ (id)viewController {
    return [[[[self class] alloc] init] autorelease];
}




#pragma mark -

- (id)init
{
    self = [super initWithNibName:[[self class] nibName] bundle:nil];
    if (self) {

    }
    
    return self;
}



#pragma mark -

- (NSString *)secretKey {
    [secretKeyTextField validateEditing];
     
    return [secretKeyTextField stringValue];
}

- (NSString *)verifyKey {
    [verifyTextField validateEditing];
    
    return [verifyTextField stringValue];    
}

@end
