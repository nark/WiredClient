//
//  WCBadgedTableCellView.m
//  WiredClient
//
//  Created by nark on 21/10/13.
//
//

#import "WCBadgedTableCellView.h"

@implementation WCBadgedTableCellView


@synthesize button = _button;


#pragma mark -

- (void)awakeFromNib {
    // We want it to appear "inline"
    [[self.button cell] setBezelStyle:NSInlineBezelStyle];
}

- (void)dealloc {
    self.button = nil;
    [super dealloc];
}


#pragma mark -

// The standard rowSizeStyle does some specific layout for us. To customize layout for our button, we first call super and then modify things
- (void)viewWillDraw {
    [super viewWillDraw];
    if (![self.button isHidden]) {
        [self.button sizeToFit];
        
        NSRect textFrame = self.textField.frame;
        NSRect buttonFrame = self.button.frame;
        buttonFrame.origin.x = NSWidth(self.frame) - NSWidth(buttonFrame);
        self.button.frame = buttonFrame;
        textFrame.size.width = NSMinX(buttonFrame) - NSMinX(textFrame);
        self.textField.frame = textFrame;
    }
}


@end
