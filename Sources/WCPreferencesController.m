//
//  WCPreferencesController.m
//  WiredClient
//
//  Created by nark on 14/10/13.
//
//

#import "WCPreferencesController.h"
#import "WCPreferences.h"



@implementation WCPreferencesController

- (IBAction)open:(id)sender {
    [NSApp beginSheet:self.window
       modalForWindow:[[WCPreferences preferences] window]
        modalDelegate:self
       didEndSelector:nil
          contextInfo:nil];
}


- (IBAction)close:(id)sender {
    if ([[self window] isSheet]) {
        [NSApp endSheet:[self window]];
    }
    [[self window] orderOut:nil];
}

@end
