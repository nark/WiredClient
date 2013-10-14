//
//  WCConversationCellView.h
//  WiredClient
//
//  Created by Rafaël Warnault on 16/09/13.
//
//

#import <Cocoa/Cocoa.h>

@interface WCConversationCellView : NSTableCellView {
@private
    NSButton *_button;
}

@property(retain) IBOutlet NSButton *button;


@end
