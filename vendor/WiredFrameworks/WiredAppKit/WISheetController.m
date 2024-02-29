//
//  WISheetController.m
//  WiredFrameworks
//
//  Created by Rafaël Warnault on 25/06/13.
//  Copyright (c) 2013 Read-Write. All rights reserved.
//

#import "WISheetController.h"

@implementation WISheetController


#pragma mark -

- (void)dealloc {
    [_parentWindow release];
    [super dealloc];
}



#pragma mark -

- (void)beginSheetWithParentWindow:(NSWindow *)window {
    if(_parentWindow)
        [_parentWindow release]; _parentWindow = nil;
    
    _parentWindow = [window retain];
    
    [self load];
    
    [NSApp beginSheet:_sheetWindow
       modalForWindow:_parentWindow
        modalDelegate:nil
       didEndSelector:nil
          contextInfo:nil];
}



#pragma mark -

/* Implemented by subclasses */
- (void)load {
    
}

/* Implemented by subclasses */
- (void)save {
    
}

/* Implemented by subclasses */
- (void)reset {
    
}



#pragma mark -

- (IBAction)ok:(id)sender {
    [self save];
    
    [self close:sender];
}

- (IBAction)cancel:(id)sender {
    [self close:sender];
}

- (IBAction)close:(id)sender {
    [_sheetWindow orderOut:nil];
	[NSApp endSheet:_sheetWindow];
    
    [self reset];
}

@end
