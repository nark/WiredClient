//
//  IWBottomExtendView.m
//  iWired
//
//  Created by nark on 21/01/11.
//  Copyright 2011 Read-Write.fr. All rights reserved.
//

#import "WCWindowGradientView.h"


#ifndef NSAppKitVersionNumber10_8
#define NSAppKitVersionNumber10_8 1200
#endif



#define WC_WINDOW_STARTING_KEY_COLOR        [NSColor colorWithCalibratedRed:0.5896 green:0.5897 blue:0.5896 alpha:1.0000]
#define WC_WINDOW_ENDING_KEY_COLOR          [NSColor colorWithCalibratedRed:0.7690 green:0.7646 blue:0.7698 alpha:1.0000]

#define WC_WINDOW_STARTING_KEY_COLOR_108	[NSColor colorWithCalibratedRed:0.6291 green:0.6290 blue:0.6291 alpha:1.0000]
#define WC_WINDOW_ENDING_KEY_COLOR_108      [NSColor colorWithCalibratedRed:0.8494 green:0.8494 blue:0.8494 alpha:1.0000]

#define WC_WINDOW_STARTING_COLOR            [NSColor colorWithCalibratedRed:0.8115 green:0.8116 blue:0.8114 alpha:1.0000]
#define WC_WINDOW_ENDING_COLOR              [NSColor colorWithCalibratedRed:0.9166 green:0.9167 blue:0.9165 alpha:1.0000]



@implementation WCWindowGradientView

- (BOOL)isFlipped {
	return YES;
}

- (BOOL)mouseDownCanMoveWindow {
    return NO;
}


- (void)_drawTopLine {
    NSRect          rect, borderLineRect;
    NSBezierPath    *borderLinePath;
    NSColor         *borderColor;
    BOOL            keyWindow;
    
    keyWindow       = [[self window] isKeyWindow];
    rect            = [self bounds];
    
    borderLineRect  = NSMakeRect(0, 0, NSWidth(rect), 1.0);
    borderLinePath  = [NSBezierPath bezierPathWithRect:borderLineRect];
    borderColor     = (keyWindow ? [NSColor darkGrayColor] : [NSColor disabledControlTextColor]);
    
    [borderColor setFill];
    [borderLinePath fill];
}



- (void)drawRect:(NSRect)dirtyRect {
	NSGradient		*fade;
	NSRect			rect, bottomBarRect;
	
	rect			= [self bounds];
	bottomBarRect	= NSMakeRect(rect.origin.x, rect.size.height-33, rect.size.width, 33);
	
	if ([[self window] isKeyWindow]) {
        
        if ((floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_6) || (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_7)) {
            [WC_WINDOW_ENDING_KEY_COLOR set];
            NSRectFill(rect);
            
            fade = [[NSGradient alloc] initWithStartingColor:WC_WINDOW_STARTING_KEY_COLOR
                                                 endingColor:WC_WINDOW_ENDING_KEY_COLOR];
        } else {
            [WC_WINDOW_ENDING_KEY_COLOR_108 set];
            NSRectFill(rect);
            
            fade = [[NSGradient alloc] initWithStartingColor:WC_WINDOW_STARTING_KEY_COLOR_108
                                                 endingColor:WC_WINDOW_ENDING_KEY_COLOR_108];
        }
        
	} else {

        
        [WC_WINDOW_ENDING_COLOR set];
        NSRectFill(rect);
        
        fade = [[NSGradient alloc] initWithStartingColor:WC_WINDOW_STARTING_COLOR
                                             endingColor:WC_WINDOW_ENDING_COLOR];
	}

	[fade drawInRect:bottomBarRect angle:-90.0];
	[fade release];
    
    [self _drawTopLine];
}


@end
