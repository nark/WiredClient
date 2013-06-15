//
//  WCChatTopicView.m
//  WiredClient
//
//  Created by Rafaël Warnault on 17/05/12.
//  Copyright (c) 2012 Read-Write.fr. All rights reserved.
//

#import "WCChatTopicView.h"

@implementation WCChatTopicView

- (BOOL) isOpaque { 
	return YES; 
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent {
	return YES;
}

- (BOOL)mouseDownCanMoveWindow {
	return YES;
}

- (void)drawRect:(NSRect)dirtyRect
{
	NSGradient		*fade;
	NSRect			rect;
	
	rect			= [self bounds];

	[[NSGraphicsContext currentContext] saveGraphicsState];
	
	fade = [[NSGradient alloc] initWithColorsAndLocations:
			[NSColor colorWithCalibratedWhite:0.3 alpha:0.75], 0.0,
			[NSColor colorWithCalibratedWhite:0.85 alpha:1.0], 0.1,
			[NSColor colorWithCalibratedWhite:0.65 alpha:1.0], 0.8,
			nil];
	
	[fade drawInRect:rect angle:-90.0];
	[fade release];
	
	
	[[NSGraphicsContext currentContext] restoreGraphicsState];
	
	// Now draw the parent
    [super drawRect:dirtyRect];
}

@end
