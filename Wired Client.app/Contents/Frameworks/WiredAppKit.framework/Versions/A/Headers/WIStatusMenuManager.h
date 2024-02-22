//
//  WSStatusManager.h
//  Wired Server
//
//  Created by Rafaël Warnault on 26/03/12.
//  Copyright (c) 2012 Read-Write. All rights reserved.
//

#import <Foundation/Foundation.h>

//@class WPError;
 
@interface WIStatusMenuManager : NSObject

+ (BOOL) willStartAtLogin:(NSURL *)itemURL;
+ (void) setStartAtLogin:(NSURL *)itemURL enabled:(BOOL)enabled;

+ (void)startHelper:(NSURL *)itemURL;
+ (void)stopHelper:(NSURL *)itemURL;

@end
