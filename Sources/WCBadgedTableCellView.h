//
//  WCBadgedTableCellView.h
//  WiredClient
//
//  Created by nark on 21/10/13.
//
//

#import <Cocoa/Cocoa.h>

@interface WCBadgedTableCellView : NSTableCellView {
@private
    NSButton *_button;
}

@property(retain) IBOutlet NSButton *button;

@end
