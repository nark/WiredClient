//
//  WISheetController.h
//  WiredFrameworks
//
//  Created by Rafaël Warnault on 25/06/13.
//  Copyright (c) 2013 Read-Write. All rights reserved.
//

#import <WiredFoundation/WiredFoundation.h>

@interface WISheetController : WIObject {
    IBOutlet NSWindow       *_sheetWindow;
    
    NSWindow                *_parentWindow;
}

- (void)beginSheetWithParentWindow:(NSWindow *)window;

- (void)reset;

- (IBAction)ok:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)close:(id)sender;

@end
