//
//  IWBottomExtendView.m
//  iWired
//
//  Created by nark on 21/01/11.
//  Copyright 2011 Read-Write.fr. All rights reserved.
//

#import "WCWindowGradientView.h"    // mausi


#ifndef NSAppKitVersionNumber10_8
#define NSAppKitVersionNumber10_8 1200
#endif


#define WC_WINDOW_STARTING_KEY_COLOR        [NSColor colorWithCalibratedRed:0.8684 green:0.8685 blue:0.8683 alpha:1.0000]
#define WC_WINDOW_ENDING_KEY_COLOR          [NSColor colorWithCalibratedRed:0.8684 green:0.8685 blue:0.8683 alpha:1.0000]

#define WC_WINDOW_STARTING_KEY_COLOR_DM     [NSColor colorWithCalibratedRed:0.0862 green:0.0862 blue:0.0901 alpha:1.0000]
#define WC_WINDOW_ENDING_KEY_COLOR_DM       [NSColor colorWithCalibratedRed:0.0862 green:0.0862 blue:0.0901 alpha:1.0000]

#define WC_WINDOW_STARTING_COLOR            [NSColor colorWithCalibratedRed:0.9555 green:0.9557 blue:0.9555 alpha:1.0000]
#define WC_WINDOW_ENDING_COLOR              [NSColor colorWithCalibratedRed:0.9555 green:0.9557 blue:0.9555 alpha:1.0000]



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
    borderColor     = (keyWindow ? [NSColor lightGrayColor] : [NSColor lightGrayColor]);
    
    [borderColor setFill];
    [borderLinePath fill];
}



- (void)drawRect:(NSRect)dirtyRect {
    NSGradient        *fade;
    NSRect            rect, bottomBarRect;

    rect            = [self bounds];
    bottomBarRect    = NSMakeRect(rect.origin.x, rect.size.height-33, rect.size.width, 33);
    
    if ([[self window] isKeyWindow]) {
        
        if (@available(macOS 10.14, *)) {
            if ([[[NSAppearance currentAppearance] name] containsString:NSAppearanceNameDarkAqua]) {
                [WC_WINDOW_ENDING_KEY_COLOR_DM set];
                NSRectFill(rect);
                fade = [[NSGradient alloc] initWithStartingColor:WC_WINDOW_ENDING_KEY_COLOR_DM
                                                     endingColor:WC_WINDOW_STARTING_KEY_COLOR_DM];
            } else {
                [WC_WINDOW_ENDING_KEY_COLOR set];
                NSRectFill(rect);
                fade = [[NSGradient alloc] initWithStartingColor:WC_WINDOW_ENDING_KEY_COLOR
                                                     endingColor:WC_WINDOW_STARTING_KEY_COLOR];
            }
        }else {
            [WC_WINDOW_ENDING_KEY_COLOR set];
            NSRectFill(rect);
            fade = [[NSGradient alloc] initWithStartingColor:WC_WINDOW_ENDING_KEY_COLOR
                                                 endingColor:WC_WINDOW_STARTING_KEY_COLOR];
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
