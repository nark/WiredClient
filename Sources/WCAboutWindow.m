/* $Id$ */

/*
 *  Copyright (c) 2003-2009 Axel Andersson
 *  All rights reserved.
 *
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions
 *  are met:
 *  1. Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *  2. Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
 * ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#import "WCAboutWindow.h"

@implementation WCAboutWindow

+ (WCAboutWindow *)aboutWindow {
	static WCAboutWindow	*sharedAboutWindow;
	
	if(!sharedAboutWindow)
		sharedAboutWindow = [[self alloc] init];

	return sharedAboutWindow;
}



- (id)init {
	NSMutableAttributedString	*leftString, *rightString;
	NSDictionary				*attributes;
	NSView						*view;
	NSImage						*leftImage, *rightImage;
	NSEnumerator				*enumerator;
	NSScreen					*screen, *last = NULL;
	NSRect						viewRect, leftRect, rightRect;
	CGFloat						width = 0, height;

	enumerator = [[NSScreen screens] objectEnumerator];

	while((screen = [enumerator nextObject])) {
		if(!last) {
		    width += [screen frame].size.width;
		} else {
		    if(NSEqualSizes([screen frame].size, [last frame].size) &&
		       [screen frame].origin.y == [last frame].origin.y) {
		        width += [screen frame].size.width;
		    }
		}

		last = screen;
	}

	height = width / 11.0;
	viewRect = [[NSScreen mainScreen] frame];
	viewRect.origin.x = 0;
	viewRect.origin.y = (viewRect.size.height - height) / 2;
	viewRect.size.height = height;
	viewRect.size.width = width;

	self = [super initWithContentRect:viewRect
		                    styleMask:NSBorderlessWindowMask
		                      backing:NSBackingStoreBuffered
		                        defer:NO];

	viewRect.origin.x = viewRect.origin.y = 0;
	view = [[NSView alloc] initWithFrame:viewRect];

	[self setDelegate:self];
	[self setReleasedWhenClosed:NO];
	[self setBackgroundColor:[NSColor clearColor]];
	[self setOpaque:NO];
	[self setLevel:NSScreenSaverWindowLevel];
	[self setContentView:view];

	attributes = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSFont fontWithName:@"Helvetica-Bold" size:width / 14.60],
			NSFontAttributeName,
		[NSColor blackColor],
			NSForegroundColorAttributeName,
		NULL];

	leftString = [NSMutableAttributedString attributedStringWithString:@"Close the world," attributes:attributes];
	rightString = [NSMutableAttributedString attributedStringWithString:@"Open the nExt" attributes:attributes];

	[rightString addAttribute:NSForegroundColorAttributeName
		                value:[[NSColor redColor] shadowWithLevel:0.5]
		                range:[[rightString string] rangeOfString:@"E"]];

	leftRect = NSMakeRect(0, 0, viewRect.size.width * 0.53, viewRect.size.height);
	leftImage = [[[NSImage alloc] initWithSize:leftRect.size] autorelease];
	rightRect = NSMakeRect(leftRect.size.width, 0, viewRect.size.width - leftRect.size.width, viewRect.size.height);
	rightImage = [[[NSImage alloc] initWithSize:rightRect.size] autorelease];

	[leftImage lockFocus];
	[leftString drawInRect:leftRect];
	[leftImage unlockFocus];

	[rightImage lockFocus];
	[rightString drawInRect:leftRect];
	[rightImage unlockFocus];

	[self display];

	[view lockFocus];
	[leftImage compositeToPoint:leftRect.origin operation:NSCompositeSourceOver];
	[[rightImage mirroredImage] compositeToPoint:rightRect.origin operation:NSCompositeSourceOver];
	[view unlockFocus];

	[view release];

	[[NSNotificationCenter defaultCenter]
		addObserver:self
		   selector:@selector(applicationDidChangeActive:)
			   name:WIApplicationDidChangeActiveNotification];

	return self;
}



- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super dealloc];
}



#pragma mark -

- (void)applicationDidChangeActive:(NSNotification *)notification {
	[self close];
}



- (void)windowDidResignKey:(NSNotification *)notification {
	[self close];
}



#pragma mark -

- (void)keyDown:(NSEvent *)event {
	[self close];
}



- (void)mouseDown:(NSEvent *)event {
	[self close];
}



- (BOOL)canBecomeKeyWindow {
	return YES;
}

@end
