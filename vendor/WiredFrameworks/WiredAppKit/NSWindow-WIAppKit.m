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

#import <WiredFoundation/NSDictionary-WIFoundation.h>
#import <WiredAppKit/NSEvent-WIAppKit.h>
#import <WiredAppKit/NSToolbar-WIAppKit.h>
#import <WiredAppKit/NSWindow-WIAppKit.h>

@implementation NSWindow(WIAppKit)

- (void)setTitle:(NSString *)title withSubtitle:(NSString *)subtitle {
	if(subtitle)
		[self setTitle:[NSSWF:@"%@ \u2014 %@", title, subtitle]];
	else
		[self setTitle:title];
}



#pragma mark -

- (BOOL)isOnScreen {
	return ([self isVisible] || [self isMiniaturized]);
}



- (CGFloat)toolbarHeight {
	NSToolbar	*toolbar;
	
	toolbar = [self toolbar];
	
	if(!toolbar)
		return 0.0;
	
	return [self contentRectForFrameRect:[self frame]].size.height - [[self contentView] frame].size.height;
}



#pragma mark -

- (void)setPropertiesFromDictionary:(NSDictionary *)dictionary {
	[self setPropertiesFromDictionary:dictionary restoreSize:YES visibility:YES];
}



- (void)setPropertiesFromDictionary:(NSDictionary *)dictionary restoreSize:(BOOL)size visibility:(BOOL)visibility {
	NSRect		rect;
	NSSize		minSize;
	id			object;
	
	if([self toolbar]) {
		object = [dictionary objectForKey:@"_WIWindow_toolbar"];
		
		if(object)
			[[self toolbar] setPropertiesFromDictionary:object];
	}

	object = [dictionary objectForKey:@"_WIWindow_frame"];
	
	if(object) {
		rect = NSRectFromString(object);
		minSize = [self minSize];
		
		if(rect.size.width < minSize.width)
			rect.size.width = minSize.width;

		if(rect.size.height < minSize.height)
			rect.size.height = minSize.height;
		
		if(size)
			[self setFrame:rect display:NO];
		else
			[self setFrameOrigin:rect.origin];
	}

	if(visibility) {
		object = [dictionary objectForKey:@"_WIWindow_isOnScreen"];
		
		if(object) {
			if([object boolValue])
				[self performSelector:@selector(orderFront:) withObject:self afterDelay:0.0];
			else
				[self performSelector:@selector(orderOut:) withObject:self afterDelay:0.0];
		}
		
		object = [dictionary objectForKey:@"_WIWindow_isMiniaturized"];
		
		if(object && [object boolValue])
			[self performSelector:@selector(miniaturize:) withObject:self afterDelay:0.0];
	}
}



- (NSDictionary *)propertiesDictionary {
	NSMutableDictionary		*dictionary;
	
	dictionary = [NSMutableDictionary dictionary];
	
	[dictionary setObject:NSStringFromRect([self frame]) forKey:@"_WIWindow_frame"];
	[dictionary setBool:[self isOnScreen] forKey:@"_WIWindow_isOnScreen"];
	[dictionary setBool:[self isMiniaturized] forKey:@"_WIWindow_isMiniaturized"];
	
	if([self toolbar])
		[dictionary setObject:[[self toolbar] propertiesDictionary] forKey:@"_WIWindow_toolbar"];
	
	return dictionary;
}



#pragma mark -

- (void)snapToScreenEdgeAndDisplay:(BOOL)display animate:(BOOL)animate {
    NSRect			frame, screenFrame, visibleFrame;
    CGFloat			gravity = 20.0;
    
    frame			= [self frame];
	screenFrame		= [[self screen] frame];
	visibleFrame	= [[self screen] visibleFrame];
	
	if(screenFrame.size.width - visibleFrame.size.width <= 10.0)
		visibleFrame.size.width = screenFrame.size.width;
	
	if(fabs(visibleFrame.origin.x - frame.origin.x) <= gravity)
		frame.origin.x = visibleFrame.origin.x;
	if(fabs(visibleFrame.origin.x - (frame.origin.x + frame.size.width)) <= gravity)
		frame.origin.x += visibleFrame.origin.x - (frame.origin.x + frame.size.width);
	if(fabs((visibleFrame.origin.x + visibleFrame.size.width) - frame.origin.x) <= gravity)
		frame.origin.x = visibleFrame.origin.x + visibleFrame.size.width;
	if(fabs((visibleFrame.origin.x + visibleFrame.size.width) - (frame.origin.x + frame.size.width)) <= gravity)
		frame.origin.x += (visibleFrame.origin.x + visibleFrame.size.width) - (frame.origin.x + frame.size.width);
	
	if(fabs(visibleFrame.origin.y - frame.origin.y) <= gravity)
		frame.origin.y = visibleFrame.origin.y;
	if(fabs(visibleFrame.origin.y - (frame.origin.y + frame.size.height)) <= gravity)
		frame.origin.y += visibleFrame.origin.y - (frame.origin.y + frame.size.height);
	if(fabs((visibleFrame.origin.y + visibleFrame.size.height) - frame.origin.y) <= gravity)
		frame.origin.y = visibleFrame.origin.y + visibleFrame.size.height;
	if(fabs((visibleFrame.origin.y + visibleFrame.size.height) - (frame.origin.y + frame.size.height)) <= gravity)
		frame.origin.y += (visibleFrame.origin.y + visibleFrame.size.height) - (frame.origin.y + frame.size.height);
		
	[self setFrame:frame display:display animate:animate];
}



#pragma mark -

- (void)_animateOrderFront:(id)sender {
	float		alpha;
	
	alpha = [self alphaValue] + 0.1;
	
	[self setAlphaValue:alpha];
	
	if(alpha < 1.0)
		[self performSelector:@selector(_animateOrderFront:) withObject:sender afterDelay:0.03];
}



- (void)_animateOrderOut:(id)sender {
	float		alpha;
	
	alpha = [self alphaValue] - 0.05;
	
	[self setAlphaValue:alpha];
	
	if(alpha > 0.0)
		[self performSelector:@selector(_animateOrderOut:) withObject:sender afterDelay:0.03];
	else
		[self orderOut:sender];
}



- (void)orderFront:(id)sender animate:(BOOL)animate {
	if(!animate) {
		[self orderFront:sender];
		
		return;
	}
	
	[self setAlphaValue:0.0];
	[self orderFront:sender];
	
	[self performSelector:@selector(_animateOrderFront:) withObject:sender afterDelay:0.03];
}



- (void)orderOut:(id)sender animate:(BOOL)animate {
	if(!animate) {
		[self orderOut:sender];
		
		return;
	}
	
	[self performSelector:@selector(_animateOrderOut:) withObject:sender afterDelay:0.03];
}



#pragma mark -

- (NSSize)contentSizeForFrameSize:(NSSize)size {
	return [self contentRectForFrameRect:NSMakeRect(0.0, 0.0, size.width, size.height)].size;
}



- (NSSize)frameSizeForContentSize:(NSSize)size {
	return [self frameRectForContentRect:NSMakeRect(0.0, 0.0, size.width, size.height)].size;
}



#pragma mark -

- (void)beginSheetModalForWindow:(NSWindow *)window {
    [NSApp beginSheet:window
       modalForWindow:self
        modalDelegate:self
       didEndSelector:nil
          contextInfo:nil];
}

- (void)endSheet1:(NSWindow *)window {
    [NSApp endSheet:window];
    [window orderOut:self];
}

@end
