/* $Id$ */

/*
 *  Copyright (c) 2008-2009 Axel Andersson
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

#import <WiredAppKit/NSToolbarItem-WIAppKit.h>
#import <WiredAppKit/WIPreferencesController.h>

#define _WIPreferencesControllerView			@"_WIPreferencesControllerView"
#define _WIPreferencesControllerName			@"_WIPreferencesControllerName"
#define _WIPreferencesControllerImage			@"_WIPreferencesControllerImage"


@interface WIPreferencesController(Private)

- (void)_selectPreferenceViewWithIdentifier:(NSString *)identifier animate:(BOOL)animate;

@end


@implementation WIPreferencesController(Private)

- (void)_selectPreferenceViewWithIdentifier:(NSString *)identifier animate:(BOOL)animate {
	NSViewAnimation		*animation;
	NSDictionary		*dictionary;
	NSArray				*animations;
	NSView				*view;
	NSRect				frame;
	
	dictionary	= [_views objectForKey:identifier];
	view		= [dictionary objectForKey:_WIPreferencesControllerView];
	
	if(view != _shownView) {
		[_shownView removeFromSuperview];
		
		[view setHidden:YES];
		
		frame = [[self window] frame];
		frame.size = [[self window] frameRectForContentRect:[view frame]].size;
		frame.origin.y -= frame.size.height - [[self window] frame].size.height;
		[[self window] setFrame:frame display:YES animate:animate];
		
		[[[self window] contentView] addSubview:view];
		
		if(animate) {
			animations = [NSArray arrayWithObject:[NSDictionary dictionaryWithObjectsAndKeys:
				view,
					NSViewAnimationTargetKey,
				NSViewAnimationFadeInEffect,
					NSViewAnimationEffectKey,
				NULL]];

			animation = [[NSViewAnimation alloc] initWithViewAnimations:animations];
			[animation setAnimationBlockingMode:NSAnimationNonblocking];
			[animation setDuration:0.25];
			[animation startAnimation];
			[animation release];
		} else {
			[view setHidden:NO];
		}

		[[self window] setTitle:[dictionary objectForKey:_WIPreferencesControllerName]];
		
		[[[self window] toolbar] setSelectedItemIdentifier:identifier];

		_shownView = view;
	}
}

@end



@implementation WIPreferencesController

- (id)initWithWindowNibName:(NSString *)nibName {
	self = [super initWithWindowNibName:nibName];
	
	_identifiers	= [[NSMutableArray alloc] init];
	_views			= [[NSMutableDictionary alloc] init];
	
	return self;
}



- (void)dealloc {
	[_identifiers release];
	[_views release];
	
	[super dealloc];
}



#pragma mark -

- (void)windowDidLoad {
	NSWindow	*window;
	NSToolbar	*toolbar;
	
	window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0.0, 0.0, 100.0, 100.0)
										 styleMask:NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask
										   backing:NSBackingStoreBuffered
											 defer:YES];
	[window setShowsToolbarButton:NO];
	[window setDelegate:self];
	[self setWindow:window];
	[window release];
	
	toolbar = [[NSToolbar alloc] initWithIdentifier:@"WIPreferencesController"];
	[toolbar setDelegate:self];
	[toolbar setAllowsUserCustomization:NO];
	[toolbar setAutosavesConfiguration:NO];
	[[self window] setToolbar:toolbar];
	[toolbar release];
	
	[self _selectPreferenceViewWithIdentifier:[_identifiers objectAtIndex:0] animate:NO];
	
	[[self window] center];
}



- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)identifier willBeInsertedIntoToolbar:(BOOL)willBeInsertedIntoToolbar {
	NSDictionary		*dictionary;
	
	dictionary = [_views objectForKey:identifier];
	
	return [NSToolbarItem toolbarItemWithIdentifier:identifier
											   name:[dictionary objectForKey:_WIPreferencesControllerName]
											content:[dictionary objectForKey:_WIPreferencesControllerImage]
											 target:self
											 action:@selector(toolbarItem:)];
}



- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
	return _identifiers;
}



- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
	return [self toolbarDefaultItemIdentifiers:toolbar];
}



- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar {
	return [self toolbarDefaultItemIdentifiers:toolbar];
}



#pragma mark -

- (void)toolbarItem:(id)sender {
	[self _selectPreferenceViewWithIdentifier:[sender itemIdentifier] animate:YES];
}



#pragma mark -

- (void)addPreferenceView:(NSView *)view name:(NSString *)name image:(NSImage *)image {
	NSMutableDictionary			*dictionary;
	NSString					*identifier;
	
	[view setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable | NSViewMaxXMargin | NSViewMaxYMargin];
	
	dictionary = [NSMutableDictionary dictionary];
	[dictionary setObject:view forKey:_WIPreferencesControllerView];
	[dictionary setObject:name forKey:_WIPreferencesControllerName];
	[dictionary setObject:image forKey:_WIPreferencesControllerImage];
	
	identifier = [NSString UUIDString];
	
	[_identifiers addObject:identifier];
	[_views setObject:dictionary forKey:identifier];
}



- (void)selectPreferenceView:(NSView *)view {
	NSEnumerator		*enumerator;
	NSString			*identifier;
	NSDictionary		*dictionary;
	
	enumerator = [_views keyEnumerator];
	
	while((identifier = [enumerator nextObject])) {
		dictionary = [_views objectForKey:identifier];
		
		if([dictionary objectForKey:_WIPreferencesControllerView] == view) {
			[self _selectPreferenceViewWithIdentifier:identifier animate:YES];
			
			break;
		}
	}
}




#pragma mark -

- (void)selectViewWithName:(NSString *)name {
    NSEnumerator		*enumerator;
	NSString			*identifier;
	NSDictionary		*dictionary;
	
	enumerator = [_views keyEnumerator];
	
	while((identifier = [enumerator nextObject])) {
		dictionary = [_views objectForKey:identifier];
        
        if([[dictionary objectForKey:_WIPreferencesControllerName] isEqualToString:name]) {
            [self _selectPreferenceViewWithIdentifier:identifier animate:NO];
            
            break;
        }
    }
}


@end
