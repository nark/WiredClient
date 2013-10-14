//
//  WCEmoticonPackTableCellView.h
//  WiredClient
//
//  Created by Rafaël Warnault on 30/09/13.
//
//

#import <Cocoa/Cocoa.h>

@interface WCEmoticonPackTableCellView : NSTableCellView {
    IBOutlet NSButton *enabledButton;
    IBOutlet NSImageView *emoticonImage1;
    IBOutlet NSImageView *emoticonImage2;
    IBOutlet NSImageView *emoticonImage3;
    IBOutlet NSImageView *emoticonImage4;
    IBOutlet NSImageView *emoticonImage5;
}

@property (assign) IBOutlet NSButton *enabledButton;
@property (assign) IBOutlet NSImageView *emoticonImage1;
@property (assign) IBOutlet NSImageView *emoticonImage2;
@property (assign) IBOutlet NSImageView *emoticonImage3;
@property (assign) IBOutlet NSImageView *emoticonImage4;
@property (assign) IBOutlet NSImageView *emoticonImage5;

@end
