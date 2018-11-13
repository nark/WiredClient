//
//  WCChatTextFieldCell.m
//  WiredClient
//
//  Created by Rafaël Warnault on 06/10/13.
//
//

#import "WCChatTextFieldCell.h"

#define WC_CHATTEXTFIELD_CORNER_RADIUS 3.0

@implementation WCChatTextFieldCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    NSBezierPath *betterBounds = [NSBezierPath bezierPathWithRoundedRect:cellFrame xRadius:WC_CHATTEXTFIELD_CORNER_RADIUS
            yRadius:WC_CHATTEXTFIELD_CORNER_RADIUS];
    
    [betterBounds addClip];
    
    [super drawWithFrame:cellFrame inView:controlView];
    
    if (self.isBezeled) {
        [betterBounds setLineWidth:2];
        [[NSColor lightGrayColor] setStroke];
        [betterBounds stroke];
    }
}

@end
