//
//  WCUserTableCellView.h
//  WiredClient
//
//  Created by Rafaël Warnault on 29/09/13.
//
//

#import <Cocoa/Cocoa.h>

@interface WCUserTableCellView : NSTableCellView {
    IBOutlet NSTextField *nickTextField;
    IBOutlet NSTextField *statusTextField;
}

@property (assign) IBOutlet NSTextField *nickTextField;
@property (assign) IBOutlet NSTextField *statusTextField;

@end
