//
//  WCThreadTableCellView.h
//  WiredClient
//
//  Created by nark on 21/10/13.
//
//

#import <Cocoa/Cocoa.h>
#import "WCBadgedTableCellView.h"


@interface WCThreadTableCellView : WCBadgedTableCellView {
    IBOutlet NSTextField    *_nickTextField;
    IBOutlet NSTextField    *_timeTextField;
    IBOutlet NSTextField    *_repliesTextField;
    IBOutlet NSTextField    *_serverTextField;
    IBOutlet NSImageView    *_unreadImageView;
}

@property (assign) IBOutlet NSTextField    *nickTextField;
@property (assign) IBOutlet NSTextField    *timeTextField;
@property (assign) IBOutlet NSTextField    *repliesTextField;
@property (assign) IBOutlet NSTextField    *serverTextField;
@property (assign) IBOutlet NSImageView    *unreadImageView;

@end
