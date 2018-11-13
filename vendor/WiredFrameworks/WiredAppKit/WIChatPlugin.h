//
//  WIChatPlugin.h
//  wired
//
//  Created by Rafaël Warnault on 16/06/12.
//  Copyright (c) 2012 Read-Write.fr. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WIChatPlugin : NSBundle {
    NSString			*_command;
    BOOL				_hasArguments;
}
- (void)initPlugin;

- (NSString *)command;
- (NSString *)commandOutput;

/*
    + help string
    + icon
    + common name
    + identifier
*/

@end