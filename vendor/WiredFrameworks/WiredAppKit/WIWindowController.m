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

#import <WiredFoundation/NSNotificationCenter-WIFoundation.h>
#import <WiredAppKit/WIWindowController.h>

#define WIWindowControllerCascadeOffsetX	20.0
#define WIWindowControllerCascadeOffsetY	20.0


static NSMutableDictionary					*_WIWindowController_frames;
static NSMutableArray						*_WIWindowController_windows;


@interface WIWindowController(Private)

- (void)_initWindowController;

- (void)_saveWindowFrame;
- (void)_loadWindowFrame;

@end


@implementation WIWindowController(Private)

- (void)_initWindowController {
	if(!_WIWindowController_frames)
		_WIWindowController_frames = [[NSMutableDictionary alloc] init];
	 
	if(!_WIWindowController_windows)
		_WIWindowController_windows = [[NSMutableArray alloc] init];
	
	[super setShouldCascadeWindows:NO];
	[super setWindowFrameAutosaveName:@""];
	
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		   selector:@selector(_WI_applicationWillTerminate:)
			   name:NSApplicationWillTerminateNotification];
}



#pragma mark -

- (void)_WI_windowWillClose:(NSNotification *)notification {
	if([_WI_windowFrameAutosaveName length] > 0) {
		[self _saveWindowFrame];
		
		[_WIWindowController_windows removeObject:[self window]];
	}
}



- (void)_WI_windowDidMove:(NSNotification *)notification {
	if([_WI_windowFrameAutosaveName length] > 0) {
		if([self window] == [_WIWindowController_windows lastObject]) {
			[_WIWindowController_frames setObject:NSStringFromRect([[self window] frame])
										   forKey:[NSSWF:@"WIWindowController %@ Frame", _WI_windowFrameAutosaveName]];
		}
	}
}



- (void)_WI_applicationWillTerminate:(NSNotification *)notification {
	[self _saveWindowFrame];
}



#pragma mark -

- (void)_loadWindowFrame {
	NSScreen	*screen;
	NSString	*key, *savedFrameString, *cascadedFrameString;
	NSRect		frame, previousFrame, cascadedFrame, savedFrame;
	
	if([_WI_windowFrameAutosaveName length] > 0) {
		key = [NSSWF:@"WIWindowController %@ Frame", _WI_windowFrameAutosaveName];
		savedFrameString = [[NSUserDefaults standardUserDefaults] objectForKey:key];
		previousFrame = [[self window] frame];
		
		if([savedFrameString length] > 0)
			savedFrame = NSRectFromString(savedFrameString);
		else
			savedFrame = previousFrame;
		
		if([self shouldSaveWindowFrameOriginOnly]) {
			frame.origin.x = savedFrame.origin.x;
			frame.origin.y = savedFrame.origin.y + savedFrame.size.height - previousFrame.size.height;
			frame.size = previousFrame.size;
		} else {
			frame = savedFrame;
			
			if(frame.size.width == 0)
				frame.size.width = previousFrame.size.width;
			
			if(frame.size.height == 0)
				frame.size.height = previousFrame.size.height;
		}
			
		if(_WI_shouldCascadeWindows) {
			cascadedFrameString = [_WIWindowController_frames objectForKey:key];
			
			if([cascadedFrameString length] > 0) {
				cascadedFrame = NSRectFromString(cascadedFrameString);
				
				if([self shouldSaveWindowFrameOriginOnly]) {
					frame.origin.x = cascadedFrame.origin.x;
					frame.origin.y = cascadedFrame.origin.y + cascadedFrame.size.height - previousFrame.size.height;
				} else {
					frame.origin = cascadedFrame.origin;
				}
			}
			
			frame.origin.x += WIWindowControllerCascadeOffsetX;
			frame.origin.y -= WIWindowControllerCascadeOffsetY;
			
			screen = [[self window] screen];

			if(frame.origin.x > [screen frame].size.width - frame.size.width || frame.origin.y < 0.0) {
				frame.origin.x = 0;
				frame.origin.y = [screen frame].size.height;
			}
		}
		
		[[self window] setFrame:frame display:NO];
		
		[_WIWindowController_windows addObject:[self window]];
		[_WIWindowController_frames setObject:NSStringFromRect(frame) forKey:key];
	}
}



- (void)_saveWindowFrame {
	NSString	*key, *value;
	NSRect		frame;
	
	if([_WI_windowFrameAutosaveName length] > 0) {
		frame = [[self window] frame];
		
		if(_WI_shouldCascadeWindows) {
			frame.origin.x -= WIWindowControllerCascadeOffsetY;
			frame.origin.y += WIWindowControllerCascadeOffsetX;
		}
		
		key = [NSSWF:@"WIWindowController %@ Frame", _WI_windowFrameAutosaveName];
		value = NSStringFromRect(frame);

		[[NSUserDefaults standardUserDefaults] setObject:value forKey:key];
		[[NSUserDefaults standardUserDefaults] synchronize];

		[_WIWindowController_frames setObject:value forKey:key];
	}
}

@end



@implementation WIWindowController

- (id)initWithWindow:(NSWindow *)window {
	self = [super initWithWindow:window];

	[self _initWindowController];

	return self;
}



- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super dealloc];
}



#pragma mark -

- (void)setWindow:(NSWindow *)window {
	if(window) {
		[[NSNotificationCenter defaultCenter]
			addObserver:self
			   selector:@selector(_WI_windowWillClose:)
				   name:NSWindowWillCloseNotification
				 object:window];

		[[NSNotificationCenter defaultCenter]
			addObserver:self
			   selector:@selector(_WI_windowDidMove:)
				   name:NSWindowDidMoveNotification
				 object:window];
	}
	
	[super setWindow:window];
}



- (void)setShouldCascadeWindows:(BOOL)value {
	_WI_shouldCascadeWindows = value;
}



- (void)setWindowFrameAutosaveName:(NSString *)value {
	[value retain];
	[_WI_windowFrameAutosaveName release];
	
	_WI_windowFrameAutosaveName = value;
	
	[self _loadWindowFrame];
}



- (void)setShouldSaveWindowFrameOriginOnly:(BOOL)value {
	_shouldSaveWindowFrameOriginOnly = value;
}



- (BOOL)shouldSaveWindowFrameOriginOnly {
       return _shouldSaveWindowFrameOriginOnly;
}

@end
