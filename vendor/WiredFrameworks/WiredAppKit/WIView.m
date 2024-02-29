//
//  WIView.m
//  WiredFrameworks
//
//  Created by Rafaël Warnault on 11/03/13.
//  Copyright (c) 2013 Read-Write. All rights reserved.
//

#import "WIView.h"

NSString * const WIViewWillBecomeFirstResponderNotification = @"WIViewWillBecomeFirstResponderNotification";

@implementation WIView

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (BOOL)becomeFirstResponder {
    [[NSNotificationCenter defaultCenter]
     postNotificationName:WIViewWillBecomeFirstResponderNotification
                   object:self
                 userInfo:nil];
    return YES;
}

@end
