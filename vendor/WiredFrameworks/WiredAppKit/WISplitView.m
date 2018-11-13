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

#import <WiredAppKit/NSSplitView-WIAppKit.h>
#import <WiredAppKit/WISplitView.h>

@interface WISplitView(Private)

- (void)_initSplitView;

- (void)_saveSplitViewPosition;
- (void)_loadSplitViewPosition;

@end


@implementation WISplitView(Private)

- (void)_initSplitView {
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		   selector:@selector(_WI_applicationWillTerminate:)
			   name:NSApplicationWillTerminateNotification
			 object:NULL];
    
    _dividerThickness = 1.0f;
}



#pragma mark -

- (void)_saveSplitViewPosition {
	if([[self autosaveName] length] > 0) {
		[[NSUserDefaults standardUserDefaults] setObject:[self propertiesDictionary]
												  forKey:[NSSWF:@"WISplitView %@ Properties", [self autosaveName]]];

		[[NSUserDefaults standardUserDefaults] synchronize];
	}
}



- (void)_loadSplitViewPosition {
	NSDictionary	*dictionary;
	
	if([[self autosaveName] length] > 0) {
		dictionary = [[NSUserDefaults standardUserDefaults] dictionaryForKey:
			[NSSWF:@"WISplitView %@ Properties", [self autosaveName]]];
		
		[self setPropertiesFromDictionary:dictionary];
	}
}

@end



@implementation WISplitView

- (id)initWithFrame:(NSRect)rect {
	self = [super initWithFrame:rect];

	[self _initSplitView];
    
	return self;
}



- (id)initWithCoder:(NSCoder *)coder {
	self = [super initWithCoder:coder];
	
	[self _initSplitView];
    
	return self;
}



- (void)dealloc; {
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[_autosaveName release];

	[super dealloc];
}



#pragma mark -

- (void)_WI_windowWillClose:(NSNotification *)notification {
	[self _saveSplitViewPosition];
}



- (void)_WI_applicationWillTerminate:(NSNotification *)notification {
	[self _saveSplitViewPosition];
}



#pragma mark

- (void)viewDidMoveToWindow {
	NSWindow	*window;
	
	window = [self window];
	
	if(window) {
		[[NSNotificationCenter defaultCenter]
			addObserver:self
			   selector:@selector(_WI_windowWillClose:)
				   name:NSWindowWillCloseNotification
				 object:window];
	}
}

- (NSColor *)dividerColor {
	if(![[self window] isKeyWindow])
		return [NSColor colorWithCalibratedRed:0.6246 green:0.6247 blue:0.6245 alpha:1.0000];
	
    return [NSColor darkGrayColor];
}

- (BOOL)mouseDownCanMoveWindow {
    return YES;
}



#pragma mark -

//- (void)setAutosaveName:(NSString *)value {
//	[value retain];
//	[_autosaveName release];
//	_autosaveName = value;
//	
//	//[self _loadSplitViewPosition];
//}
//
//
//
//- (NSString *)autosaveName {
//	return _autosaveName;
//}



#pragma mark -

- (void)setDividerThickness:(CGFloat)thickness {
    _dividerThickness = thickness;
    
    [self setNeedsDisplay:YES];
}

- (CGFloat)dividerThickness {
    return _dividerThickness;
}

@end
