//
//  WCToolbarGradientView.m
//  WiredClient
//
//  Created by Rafaël Warnault on 02/03/13.
//
//


#define WC_VIEW_STARTING_KEY_COLOR        [NSColor colorWithCalibratedWhite:0.8068 alpha:1.0000]
#define WC_VIEW_STARTING_COLOR            [NSColor colorWithCalibratedWhite:0.8068 alpha:0.9]
#define WC_VIEW_ENDING_KEY_COLOR          [NSColor colorWithCalibratedWhite:0.8068 alpha:1.0000]
#define WC_VIEW_ENDING_COLOR              [NSColor colorWithCalibratedWhite:0.8068 alpha:0.9]

#define WC_VIEW_STARTING_KEY_COLOR_DM     [NSColor colorWithCalibratedWhite:0.1932 alpha:1.0000]
#define WC_VIEW_STARTING_COLOR_DM         [NSColor colorWithCalibratedWhite:0.1932 alpha:0.9]
#define WC_VIEW_ENDING_KEY_COLOR_DM       [NSColor colorWithCalibratedWhite:0.1932 alpha:1.0000]
#define WC_VIEW_ENDING_COLOR_DM           [NSColor colorWithCalibratedWhite:0.1932 alpha:0.9]


#define WC_VIEW_BORDER_KEY_COLOR          [NSColor colorWithCalibratedRed:0.4347 green:0.4347 blue:0.4347 alpha:1.0000]
#define WC_VIEW_BORDER_COLOR              [NSColor colorWithCalibratedRed:0.5000 green:0.5000 blue:0.5000 alpha:1.0000]


#import "WCToolbarGradientView.h"




@interface WCToolbarGradientView (Private)

- (void)_drawGradientBackground;
- (void)_drawTopLine;
- (void)_drawBottomLine;

@end





@implementation WCToolbarGradientView (Private)

- (void)_drawGradientBackground {
    NSGradient		*gradient;
    NSColor         *startColor, *endColor;
	NSRect			rect;
    BOOL            keyWindow;
    
    keyWindow       = [[self window] isKeyWindow];
	rect            = [self bounds];
    
    if (@available(macOS 10.14, *)) {
        if ([[[NSAppearance currentAppearance] name] containsString:NSAppearanceNameDarkAqua]) {
            startColor      = (keyWindow) ? WC_VIEW_STARTING_KEY_COLOR_DM  : WC_VIEW_STARTING_COLOR_DM;
            endColor        = (keyWindow) ? WC_VIEW_ENDING_KEY_COLOR_DM    : WC_VIEW_ENDING_COLOR_DM;
            
        } else {
            startColor      = (keyWindow) ? WC_VIEW_STARTING_KEY_COLOR  : WC_VIEW_STARTING_COLOR;
            endColor        = (keyWindow) ? WC_VIEW_ENDING_KEY_COLOR    : WC_VIEW_ENDING_COLOR;
        }
    }else {
        startColor      = (keyWindow) ? WC_VIEW_STARTING_KEY_COLOR  : WC_VIEW_STARTING_COLOR;
        endColor        = (keyWindow) ? WC_VIEW_ENDING_KEY_COLOR    : WC_VIEW_ENDING_COLOR;
    }
    
    
    
    
    [endColor set];
    //NSRectFill([self bounds]);
    
    gradient = [[NSGradient alloc] initWithStartingColor:startColor endingColor:endColor];
    [gradient drawInRect:rect angle:-90.0];
	[gradient release];
}


- (void)_drawTopLine {
    NSRect          rect, borderLineRect;
    NSBezierPath    *borderLinePath;
    NSColor         *borderColor;
    BOOL            keyWindow;

    keyWindow       = [[self window] isKeyWindow];
    rect            = [self bounds];

    borderLineRect  = NSMakeRect(0, NSHeight(rect), NSWidth(rect), 1.0);
    borderLinePath  = [NSBezierPath bezierPathWithRect:borderLineRect];
    borderColor     = (keyWindow ? WC_VIEW_BORDER_KEY_COLOR : WC_VIEW_BORDER_COLOR);

    [borderColor setFill];
    [borderLinePath fill];
}


- (void)_drawBottomLine {
    NSRect          rect, borderLineRect;
    NSBezierPath    *borderLinePath;
    NSColor         *borderColor;
    BOOL            keyWindow;
    
    keyWindow       = [[self window] isKeyWindow];
    rect            = [self bounds];
    
    borderLineRect  = NSMakeRect(0, 0, NSWidth(rect), 1.0);
    borderLinePath  = [NSBezierPath bezierPathWithRect:borderLineRect];
    borderColor     = [NSColor lightGrayColor];
    
    [borderColor setFill];
    [borderLinePath fill];
}


@end






@implementation WCToolbarGradientView

- (BOOL)isFlipped {
	return NO;
}


- (BOOL)mouseDownCanMoveWindow {
    return NO;
}


- (BOOL) isOpaque { return YES; }

- (void)drawRect:(NSRect)dirtyRect {
    [[NSGraphicsContext currentContext] saveGraphicsState];
    
    [self _drawGradientBackground];
    //[self _drawTopLine];
    [self _drawBottomLine];
    
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    
    [super drawRect:dirtyRect];
}

@end
