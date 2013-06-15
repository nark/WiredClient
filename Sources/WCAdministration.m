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

#import "WCAdministration.h"
#import "WCErrorQueue.h"
#import "WCServerConnection.h"

#define WCAdministrationIdentifierKey		@"WCAdministrationIdentifierKey"
#define WCAdministrationViewKey				@"WCAdministrationViewKey"
#define WCAdministrationNameKey				@"WCAdministrationNameKey"
#define WCAdministrationImageKey			@"WCAdministrationImageKey"
#define WCAdministrationControllerKey		@"WCAdministrationControllerKey"


@interface WCAdministration(Private)

- (id)_initAdministrationWithConnection:(WCServerConnection *)connection;

- (void)_addAdministrationView:(NSView *)view name:(NSString *)name image:(NSImage *)image identifier:(NSString *)identifier controller:(id)controller;
- (void)_selectAdministrationViewWithIdentifier:(NSString *)identifier animate:(BOOL)animate;
- (NSString *)_identifierForController:(id)controller;

@end



@implementation WCAdministration(Private)

- (id)_initAdministrationWithConnection:(WCServerConnection *)connection {
	self = [super initWithWindowNibName:@"Administration"
								   name:NSLS(@"Administration", @"Administration window title")
							 connection:connection
							  singleton:YES];
	
	_identifiers	= [[NSMutableArray alloc] init];
	_views			= [[NSMutableDictionary alloc] init];

	[self window];
	
	return self;
}



#pragma mark -

- (void)_addAdministrationView:(NSView *)view name:(NSString *)name image:(NSImage *)image identifier:(NSString *)identifier controller:(id)controller {
	NSMutableDictionary			*dictionary;
	
	[view setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable | NSViewMaxXMargin | NSViewMaxYMargin];
	
	dictionary = [NSMutableDictionary dictionary];
	[dictionary setObject:identifier forKey:WCAdministrationIdentifierKey];
	[dictionary setObject:view forKey:WCAdministrationViewKey];
	[dictionary setObject:name forKey:WCAdministrationNameKey];
	[dictionary setObject:image forKey:WCAdministrationImageKey];
	[dictionary setObject:controller forKey:WCAdministrationControllerKey];
	
	[_identifiers addObject:identifier];
	[_views setObject:dictionary forKey:identifier];
}



- (void)_selectAdministrationViewWithIdentifier:(NSString *)identifier animate:(BOOL)animate {
	NSViewAnimation		*animation;
	NSDictionary		*dictionary;
	NSArray				*animations;
	NSView				*view;
	id					controller;
	NSRect				frame;
	NSSize				size;
	
	dictionary	= [_views objectForKey:identifier];
	view		= [dictionary objectForKey:WCAdministrationViewKey];
	controller	= [dictionary objectForKey:WCAdministrationControllerKey];
	
	if(view != _shownView) {
		[_shownController controllerDidUnselect];
		[_shownView removeFromSuperview];
		
		[view setHidden:YES];
		
		frame = [[self window] frame];
		frame.size = [[self window] frameRectForContentRect:[view frame]].size;
		
		size = [controller maximumWindowSize];
		
		if(!NSEqualSizes(size, NSZeroSize)) {
			if(frame.size.width > size.width)
				frame.size.width = size.width;
			
			if(frame.size.height > size.height)
				frame.size.height = size.height;
		}
		
		size = [controller minimumWindowSize];
		
		if(!NSEqualSizes(size, NSZeroSize)) {
			if(frame.size.width < size.width)
				frame.size.width = size.width;
			
			if(frame.size.height < size.height)
				frame.size.height = size.height;
		}
		
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

		[[[self window] toolbar] setSelectedItemIdentifier:identifier];

		_shownView = view;
		_shownController = controller;

		[[self window] setTitle:[[self connection] name] withSubtitle:[self name]];

		[controller controllerDidSelect];
	}
}



- (NSString *)_identifierForController:(id)controller {
	NSEnumerator	*enumerator;
	NSString		*identifier;
	
	enumerator = [_views keyEnumerator];
	
	while((identifier = [enumerator nextObject])) {
		if([[_views objectForKey:identifier] objectForKey:WCAdministrationControllerKey] == controller)
			return identifier;
	}
	
	return NULL;
}

@end



@implementation WCAdministration

+ (id)administrationWithConnection:(WCServerConnection *)connection {
	return [[[self alloc] _initAdministrationWithConnection:connection] autorelease];
}



- (void)dealloc {
	[_monitorController setAdministration:NULL];
	[_logController setAdministration:NULL];
	[_settingsController setAdministration:NULL];
	[_banlistController setAdministration:NULL];
	
	[_errorQueue release];
	
	[_identifiers release];
	[_views release];

	[super dealloc];
}



#pragma mark -

- (void)themeDidChange:(NSDictionary *)theme {
	NSEnumerator		*enumerator;
	NSDictionary		*dictionary;
	
	enumerator = [_views objectEnumerator];
	
	while((dictionary = [enumerator nextObject]))
		[[dictionary objectForKey:WCAdministrationControllerKey] themeDidChange:theme];
}



- (void)windowDidLoad {
	NSEnumerator	*enumerator;
	NSWindow		*window;
	NSToolbar		*toolbar;
	NSDictionary	*dictionary;
	NSString		*key, *string;
	
	[self _addAdministrationView:_settingsView
							name:NSLS(@"Settings", @"Settings toolbar item")
						   image:[NSImage imageNamed:@"Settings"]
					  identifier:@"Settings"
					  controller:_settingsController];
	
	[self _addAdministrationView:_monitorView
							name:NSLS(@"Monitor", @"Monitor toolbar item")
						   image:[NSImage imageNamed:@"Monitor"]
					  identifier:@"Monitor"
					  controller:_monitorController];
	
	[self _addAdministrationView:_eventsView
							name:NSLS(@"Events", @"Events toolbar item")
						   image:[NSImage imageNamed:@"Events"]
					  identifier:@"Events"
					  controller:_eventsController];
	
	[self _addAdministrationView:_logView
							name:NSLS(@"Log", @"Log toolbar item")
						   image:[NSImage imageNamed:@"Log"]
					  identifier:@"Log"
					  controller:_logController];
	
	[self _addAdministrationView:_accountsView
							name:NSLS(@"Accounts", @"Accounts toolbar item")
						   image:[NSImage imageNamed:@"Accounts"]
					  identifier:@"Accounts"
					  controller:_accountsController];
	
	[self _addAdministrationView:_banlistView
							name:NSLS(@"Banlist", @"Banlist toolbar item")
						   image:[NSImage imageNamed:@"Banlist"]
					  identifier:@"Banlist"
					  controller:_banlistController];
	
	window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0.0, 0.0, 100.0, 100.0)
										 styleMask:NSTitledWindowMask |
												   NSClosableWindowMask |
												   NSMiniaturizableWindowMask |
												   NSResizableWindowMask
										   backing:NSBackingStoreBuffered
											 defer:YES];
	[window setDelegate:self];
	[self setWindow:window];
	[window release];
	
	_errorQueue = [[WCErrorQueue alloc] initWithWindow:[self window]];

	toolbar = [[NSToolbar alloc] initWithIdentifier:@"Administration"];
	[toolbar setDelegate:self];
	[toolbar setAllowsUserCustomization:YES];
	[toolbar setAutosavesConfiguration:YES];
	[[self window] setToolbar:toolbar];
	[toolbar release];
	
	[[self window] center];
	
	[self setShouldCascadeWindows:NO];
	[self setShouldSaveWindowFrameOriginOnly:YES];
	[self setWindowFrameAutosaveName:@"Administration"];

	enumerator = [_views objectEnumerator];
	
	while((dictionary = [enumerator nextObject])) {
		key		= [NSSWF:@"%@ %@ Frame", [self class], [dictionary objectForKey:WCAdministrationIdentifierKey]];
		string	= [[WCSettings settings] objectForKey:key];
		
		if(string)
			[[dictionary objectForKey:WCAdministrationViewKey] setFrame:NSRectFromString(string)];
		
		[[dictionary objectForKey:WCAdministrationControllerKey] windowDidLoad];
	}
	
	[self _selectAdministrationViewWithIdentifier:[_identifiers objectAtIndex:0] animate:NO];

	[super windowDidLoad];
}



- (void)windowDidBecomeKey:(NSNotification *)notification {
	[_shownController controllerWindowDidBecomeKey];
}



- (BOOL)windowShouldClose:(id)window {
	return [_shownController controllerWindowShouldClose];
}



- (void)windowWillClose:(NSNotification *)notification {
	NSEnumerator		*enumerator;
	NSDictionary		*dictionary;
	NSView				*view;
	NSString			*key;
	
	enumerator = [_views objectEnumerator];
	
	while((dictionary = [enumerator nextObject])) {
		key		= [NSSWF:@"%@ %@ Frame", [self class], [dictionary objectForKey:WCAdministrationIdentifierKey]];
		view	= [dictionary objectForKey:WCAdministrationViewKey];
		
		[[WCSettings settings] setObject:NSStringFromRect([view frame]) forKey:key];
	}
	
	[_shownController controllerWindowWillClose];
}



- (NSSize)windowWillResize:(NSWindow *)window toSize:(NSSize)proposedSize {
	NSSize		size;
	
	size = [_shownController maximumWindowSize];
	
	if(!NSEqualSizes(size, NSZeroSize)) {
		if(proposedSize.width > size.width)
			proposedSize.width = size.width;
		
		if(proposedSize.height > size.height)
			proposedSize.height = size.height;
	}
	
	size = [_shownController minimumWindowSize];
	
	if(!NSEqualSizes(size, NSZeroSize)) {
		if(proposedSize.width < size.width)
			proposedSize.width = size.width;
		
		if(proposedSize.height < size.height)
			proposedSize.height = size.height;
	}
		
	return proposedSize;
}



- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)identifier willBeInsertedIntoToolbar:(BOOL)willBeInsertedIntoToolbar {
	NSDictionary		*dictionary;
	
	dictionary = [_views objectForKey:identifier];
	
	return [NSToolbarItem toolbarItemWithIdentifier:identifier
											   name:[dictionary objectForKey:WCAdministrationNameKey]
											content:[dictionary objectForKey:WCAdministrationImageKey]
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



- (void)linkConnectionLoggedIn:(NSNotification *)notification {
	NSEnumerator		*enumerator;
	NSDictionary		*dictionary;
	
	enumerator = [_views objectEnumerator];
	
	while((dictionary = [enumerator nextObject]))
		[[dictionary objectForKey:WCAdministrationControllerKey] linkConnectionLoggedIn:notification];
	
	[super linkConnectionLoggedIn:notification];
}



- (void)linkConnectionDidClose:(NSNotification *)notification {
	NSEnumerator		*enumerator;
	NSDictionary		*dictionary;
	
	enumerator = [_views objectEnumerator];
	
	while((dictionary = [enumerator nextObject]))
		[[dictionary objectForKey:WCAdministrationControllerKey] linkConnectionDidClose:notification];

	[super linkConnectionDidClose:notification];
}



- (void)serverConnectionPrivilegesDidChange:(NSNotification *)notification {
	NSEnumerator		*enumerator;
	NSDictionary		*dictionary;
	
	enumerator = [_views objectEnumerator];
	
	while((dictionary = [enumerator nextObject]))
		[[dictionary objectForKey:WCAdministrationControllerKey] serverConnectionPrivilegesDidChange:notification];

	[super serverConnectionPrivilegesDidChange:notification];
}



#pragma mark -

- (void)validate {
	[[[self window] toolbar] validateVisibleItems];

	[super validate];
}



- (BOOL)validateMenuItem:(NSMenuItem *)item {
	return [[self selectedController] validateMenuItem:item];
}



#pragma mark -

- (NSString *)newDocumentMenuItemTitle {
	return [[self selectedController] newDocumentMenuItemTitle];
}



- (NSString *)deleteDocumentMenuItemTitle {
	return [[self selectedController] deleteDocumentMenuItemTitle];
}



#pragma mark -

- (void)selectController:(id)controller {
	NSString		*identifier;
	
	if([_shownController controllerShouldUnselectForNewController:controller]) {
		identifier = [self _identifierForController:controller];
		
		[self _selectAdministrationViewWithIdentifier:identifier animate:YES];
	} else {
		identifier = [self _identifierForController:_shownController];

		[[[self window] toolbar] setSelectedItemIdentifier:identifier];
	}
}



- (id)selectedController {
	return _shownController;
}



#pragma mark -

- (WCSettingsController *)settingsController {
	return _settingsController;
}



- (WCMonitorController *)monitorController {
	return _monitorController;
}



- (WCEventsController *)eventsController {
	return _eventsController;
}



- (WCLogController *)logController {
	return _logController;
}



- (WCAccountsController *)accountsController {
	return _accountsController;
}



- (WCBanlistController *)banlistController {
	return _banlistController;
}



#pragma mark -

- (void)showError:(WCError *)error {
	[_errorQueue showError:error];
}



#pragma mark -

- (NSString *)name {
	NSString		*identifier;
	
	identifier = [self _identifierForController:_shownController];
	
	return [[_views objectForKey:identifier] objectForKey:WCAdministrationNameKey];
}


#pragma mark -

- (IBAction)newDocument:(id)sender {
	[[self selectedController] newDocument:self];
}



- (IBAction)deleteDocument:(id)sender {
	[[self selectedController] deleteDocument:self];
}



- (IBAction)toolbarItem:(id)sender {
	NSString		*identifier;
	id				controller;
	
	controller = [[_views objectForKey:[sender itemIdentifier]] objectForKey:WCAdministrationControllerKey];
	
	if([_shownController controllerShouldUnselectForNewController:controller]) {
		[self _selectAdministrationViewWithIdentifier:[sender itemIdentifier] animate:YES];
	} else {
		identifier = [self _identifierForController:_shownController];

		[[[self window] toolbar] setSelectedItemIdentifier:identifier];
	}
}



- (IBAction)submitSheet:(id)sender {
	[_shownController submitSheet:sender];
}

@end



@implementation WCAdministrationController

- (void)themeDidChange:(NSDictionary *)theme {
}



- (void)windowDidLoad {
}



- (void)linkConnectionLoggedIn:(NSNotification *)notification {
}



- (void)linkConnectionDidClose:(NSNotification *)notification {
}



- (void)serverConnectionPrivilegesDidChange:(NSNotification *)notification {
}



#pragma mark -

- (void)controllerWindowDidBecomeKey {
}



- (void)controllerWindowWillClose {
}



- (BOOL)controllerWindowShouldClose {
	return YES;
}



- (void)controllerDidSelect {
}



- (BOOL)controllerShouldUnselectForNewController:(id)controller {
	return YES;
}



- (void)controllerDidUnselect {
}



#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem *)item {
	return YES;
}



#pragma mark -

- (NSSize)maximumWindowSize {
	return NSZeroSize;
}



- (NSSize)minimumWindowSize {
	return NSZeroSize;
}



#pragma mark -

- (NSString *)newDocumentMenuItemTitle {
	return NULL;
}



- (NSString *)deleteDocumentMenuItemTitle {
	return NULL;
}



#pragma mark -

- (IBAction)newDocument:(id)sender {
}



- (IBAction)deleteDocument:(id)sender {
}



#pragma mark -

- (void)setAdministration:(WCAdministration *)administration {
	_administration = administration;
}

@end
