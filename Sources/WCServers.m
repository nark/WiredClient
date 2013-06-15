/* $Id$ */

/*
 *  Copyright (c) 2005-2009 Axel Andersson
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

#import "WCConnect.h"
#import "WCConnection.h"
#import "WCErrorQueue.h"
#import "WCPreferences.h"
#import "WCServerItem.h"
#import "WCServers.h"
#import "WCTrackerConnection.h"

@interface WCServers(Private)

- (id)_itemAtIndex:(NSUInteger)index;
- (id)_selectedItem;
- (NSArray *)_filteredItems:(NSArray *)items;

- (void)_validate;
- (void)_themeDidChange;

- (void)_updateStatus;
- (void)_reloadServers;
- (void)_sortServers;

- (void)_openTracker:(WCServerTracker *)tracker;

@end


@implementation WCServers(Private)

- (id)_itemAtIndex:(NSUInteger)index {
	return [_serversOutlineView itemAtRow:index];
}



- (id)_selectedItem {
	NSInteger		row;
	
	row = [_serversOutlineView selectedRow];
	
	if(row < 0)
		return NULL;
	
	return [self _itemAtIndex:row];
}



- (NSArray *)_filteredItems:(NSArray *)items {
	NSEnumerator		*enumerator;
	NSMutableArray		*array;
	id					item;
	
	if(!_itemFilter)
		return items;
	
    array = [NSMutableArray array];
	enumerator = [items objectEnumerator];
	
	while((item = [enumerator nextObject])) {
		if([item isKindOfClass:[WCServerBonjourServer class]]) {
			if([[item name] containsSubstring:_itemFilter options:NSCaseInsensitiveSearch])
				[array addObject:item];
		}
		else if([item isKindOfClass:[WCServerTrackerServer class]]) {
			if([item isExpandable] ||
			   [[item name] containsSubstring:_itemFilter options:NSCaseInsensitiveSearch] ||
			   [[item description] containsSubstring:_itemFilter options:NSCaseInsensitiveSearch]) {
				[array addObject:item];
			}
		}
		else {
			[array addObject:item];
		}
	}
	
	return array;
}



#pragma mark -

- (void)_validate {
	[[[self window] toolbar] validateVisibleItems];
}



- (void)_themeDidChange {
	NSDictionary		*theme;
	
	theme = [[WCSettings settings] themeWithIdentifier:[[WCSettings settings] objectForKey:WCTheme]];
	
	[_serversOutlineView setUsesAlternatingRowBackgroundColors:[theme boolForKey:WCThemesTrackerListAlternateRows]];
}



#pragma mark -

- (void)_updateStatus {
	id				item;
	NSUInteger		count;

	item = [self _selectedItem];
	
	if(!item) {
		[_statusTextField setStringValue:@""];
		
		return;
	}
	
	if([item isKindOfClass:[WCServerBookmarkServer class]] || [item isKindOfClass:[WCServerTrackerServer class]]) {
		[_statusTextField setStringValue:[NSSWF:
			@"%@ \u2014 %@",
			[item name],
			[[(WCServerTrackerServer *) item URL] humanReadableString]]];
	}
	else if([item isKindOfClass:[WCServerBookmarks class]] ||
			[item isKindOfClass:[WCServerTracker class]] ||
			[item isKindOfClass:[WCServerTrackerCategory class]]) {
		count = [item numberOfServerItems];

		[_statusTextField setStringValue:[NSSWF:
			@"%@ \u2014 %lu %@",
			[item name],
			count,
			count == 1
				? NSLS(@"server", @"Server singular")
				: NSLS(@"servers", @"Server plural")]];
	}
	else if([item isKindOfClass:[WCServerBonjour class]]) {
		count = [item numberOfServerItems];

		[_statusTextField setStringValue:[NSSWF:
			NSLS(@"Bonjour local service discovery \u2014 %lu %@", @"Bonjour tracker (servers, 'server(s)'"),
			count,
			count == 1
				? NSLS(@"server", @"Server singular")
				: NSLS(@"servers", @"Server plural")]];
	}
	else if([item isKindOfClass:[WCServerBonjourServer class]]) {
		[_statusTextField setStringValue:[NSSWF:
			@"%@ \u2014 %@",
			[item name],
			NSLS(@"Local server via Bonjour", @"Server via Bonjour")]];
	}
}



- (void)_reloadServers {
	NSEnumerator		*enumerator;
	NSDictionary		*bookmark;
	
	[_bookmarks removeAllItems];
	[_servers removeAllItems];
	
	[_servers addItem:_bonjour];
	
	enumerator = [[[WCSettings settings] objectForKey:WCBookmarks] objectEnumerator];
	
	while((bookmark = [enumerator nextObject]))
		[_bookmarks addItem:[WCServerBookmarkServer itemWithBookmark:bookmark]];
	
	[_servers addItem:_bookmarks];
	
	enumerator = [[[WCSettings settings] objectForKey:WCTrackerBookmarks] objectEnumerator];
	
	while((bookmark = [enumerator nextObject]))
		[_servers addItem:[WCServerTracker itemWithBookmark:bookmark]];
	
	[self _sortServers];
	
	[_serversOutlineView reloadData];
}



- (void)_sortServers {
	NSTableColumn   *tableColumn;
	SEL				selector;
	
	tableColumn = [_serversOutlineView highlightedTableColumn];
	
	if(tableColumn == _usersTableColumn)
		selector = @selector(compareUsers:);
	else if(tableColumn == _filesCountTableColumn)
		selector = @selector(compareFilesCount:);
	else if(tableColumn == _filesSizeTableColumn)
		selector = @selector(compareFilesSize:);
	else if(tableColumn == _descriptionTableColumn)
		selector = @selector(compareServerDescription:);
	else
		selector = @selector(compareName:);
	
	[_servers sortUsingSelector:selector];
}



#pragma mark -

- (void)_openTracker:(WCServerTracker *)tracker {
	WCTrackerConnection		*connection;

	[tracker removeAllItems];
	
	[_serversOutlineView reloadData];
	
	[tracker setState:WCServerTrackerLoading];
	
	[_progressIndicator startAnimation:self];
	
	connection = [WCTrackerConnection connectionWithTracker:tracker];

	[connection addObserver:self
				   selector:@selector(linkConnectionLoggedIn:)
					   name:WCLinkConnectionLoggedInNotification];

	[connection addObserver:self
				   selector:@selector(linkConnectionDidClose:)
					   name:WCLinkConnectionDidCloseNotification];

	[connection addObserver:self
				   selector:@selector(linkConnectionDidTerminate:)
					   name:WCLinkConnectionDidTerminateNotification];

	[connection connect];
}

@end



@implementation WCServers

+ (id)servers {
	static WCServers	*sharedServers;
	
	if(!sharedServers)
		sharedServers = [[self alloc] init];
	
	return sharedServers;
}



#pragma mark -

- (id)init {
	self = [super initWithWindowNibName:@"Servers"];
	
	_bonjour		= [[WCServerBonjour bonjourItem] retain];
	_bookmarks		= [[WCServerBookmarks bookmarksItem] retain];

	_servers		= [[WCServerContainer alloc] initWithName:@"<root>"];
	
	_browser		= [[NSNetServiceBrowser alloc] init];
	[_browser setDelegate:self];
	[_browser searchForServicesOfType:WCBonjourName inDomain:@""];
	
	_sizeFormatter	= [[WISizeFormatter alloc] init];

	[[NSNotificationCenter defaultCenter]
		addObserver:self
		   selector:@selector(selectedThemeDidChange:)
			   name:WCSelectedThemeDidChangeNotification];

	[[NSNotificationCenter defaultCenter]
		addObserver:self
		   selector:@selector(bookmarksDidChange:)
			   name:WCBookmarksDidChangeNotification];

	[[NSNotificationCenter defaultCenter]
		addObserver:self
		   selector:@selector(trackerBookmarksDidChange:)
			   name:WCTrackerBookmarksDidChangeNotification];

	[self window];
	
	return self;
}



- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[_errorQueue release];
	[_browser release];
	[_itemFilter release];
	[_servers release];
	[_bonjour release];
	[_bookmarks release];
	[_sizeFormatter release];

	[super dealloc];
}



#pragma mark -

- (void)windowDidLoad {
	NSToolbar		*toolbar;
	
	_errorQueue = [[WCErrorQueue alloc] initWithWindow:[self window]];
	
	toolbar = [[NSToolbar alloc] initWithIdentifier:@"Servers"];
	[toolbar setDelegate:self];
	[toolbar setAllowsUserCustomization:YES];
	[toolbar setAutosavesConfiguration:YES];
	[[self window] setToolbar:toolbar];
	[toolbar release];
	
	[self setShouldCascadeWindows:NO];
	[self setWindowFrameAutosaveName:@"Servers"];

	[_serversOutlineView setDefaultHighlightedTableColumnIdentifier:@"Name"];
	[_serversOutlineView setTarget:self];
	[_serversOutlineView setDoubleAction:@selector(open:)];
	[_serversOutlineView setAutoresizesOutlineColumn:NO];
	[_serversOutlineView setAllowsUserCustomization:YES];
	[_serversOutlineView setAutosaveName:@"Servers"];
	[_serversOutlineView setAutosaveTableColumns:YES];
	
	[self _themeDidChange];
	[self _updateStatus];
	[self _reloadServers];
	
	[_serversOutlineView expandItem:_bonjour];
	[_serversOutlineView expandItem:_bookmarks];
	
	[[self window] makeFirstResponder:_serversOutlineView];
}



- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)identifier willBeInsertedIntoToolbar:(BOOL)willBeInsertedIntoToolbar {
	NSSearchField		*searchField;
	
	if([identifier isEqualToString:@"Reload"]) {
		return [NSToolbarItem toolbarItemWithIdentifier:identifier
												   name:NSLS(@"Reload", @"Reload tracker toolbar item")
												content:[NSImage imageNamed:@"ReloadTracker"]
												 target:self
												 action:@selector(reload:)];
	}
	else if([identifier isEqualToString:@"Connect"]) {
		return [NSToolbarItem toolbarItemWithIdentifier:identifier
												   name:NSLS(@"Connect", @"Connect toolbar item")
												content:[NSImage imageNamed:@"Connect"]
												 target:self
												 action:@selector(open:)];
	}
	else if([identifier isEqualToString:@"AddBookmark"]) {
		return [NSToolbarItem toolbarItemWithIdentifier:identifier
												   name:NSLS(@"Add Bookmark", @"Add bookmark toolbar item")
												content:[NSImage imageNamed:@"AddBookmark"]
												 target:self
												 action:@selector(addBookmark:)];
	}
	else if([identifier isEqualToString:@"AddTrackerBookmark"]) {
		return [NSToolbarItem toolbarItemWithIdentifier:identifier
												   name:NSLS(@"Add Tracker Bookmark", @"Add tracker bookmark toolbar item")
												content:[NSImage imageNamed:@"AddTrackerBookmark"]
												 target:self
												 action:@selector(addTrackerBookmark:)];
	}
	else if([identifier isEqualToString:@"DeleteBookmark"]) {
		return [NSToolbarItem toolbarItemWithIdentifier:identifier
												   name:NSLS(@"Delete", @"Delete bookmark toolbar item")
												content:[NSImage imageNamed:@"DeleteBookmark"]
												 target:self
												 action:@selector(deleteBookmark:)];
	}
	else if([identifier isEqualToString:@"Search"]) {
		searchField = [[[NSSearchField alloc] initWithFrame:NSMakeRect(0.0, 0.0, 200.0, 22.0)] autorelease];
		
		return [NSToolbarItem toolbarItemWithIdentifier:identifier
												   name:NSLS(@"Search", @"Search tracker toolbar item")
												content:searchField
												 target:self
												 action:@selector(search:)];
	}
	
	return NULL;
}



- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
	return [NSArray arrayWithObjects:
		@"Reload",
		NSToolbarSpaceItemIdentifier,
		@"Connect",
		@"AddBookmark",
		@"AddTrackerBookmark",
		@"DeleteBookmark",
		NSToolbarFlexibleSpaceItemIdentifier,
		@"Search",
		NULL];
}



- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
	return [NSArray arrayWithObjects:
		@"Reload",
		@"Connect",
		@"AddBookmark",
		@"AddTrackerBookmark",
		@"DeleteBookmark",
		@"Search",
		NSToolbarSeparatorItemIdentifier,
		NSToolbarSpaceItemIdentifier,
		NSToolbarFlexibleSpaceItemIdentifier,
		NSToolbarCustomizeToolbarItemIdentifier,
		NULL];
}


- (void)selectedThemeDidChange:(NSNotification *)notification {
	[self _themeDidChange];
}



- (void)bookmarksDidChange:(NSNotification *)notification {
	[self _reloadServers];
}



- (void)trackerBookmarksDidChange:(NSNotification *)notification {
	[self _reloadServers];
}



- (void)linkConnectionLoggedIn:(NSNotification *)notification {
	WIP7Message		*message;
	
	message = [WIP7Message messageWithName:@"wired.tracker.get_categories" spec:WCP7Spec];
	[[notification object] sendMessage:message fromObserver:self selector:@selector(wiredTrackerGetCategoriesReply:)];

	message = [WIP7Message messageWithName:@"wired.tracker.get_servers" spec:WCP7Spec];
	[[notification object] sendMessage:message fromObserver:self selector:@selector(wiredTrackerGetServersReply:)];
}



- (void)linkConnectionDidClose:(NSNotification *)notification {
	WCTrackerConnection		*connection;

	connection = [notification object];
	
	if(![connection isKindOfClass:[WCTrackerConnection class]])
		return;

	if([connection error])
		[_errorQueue showError:[connection error]];
	
	[_progressIndicator stopAnimation:self];
}



- (void)linkConnectionDidTerminate:(NSNotification *)notification {
	WCTrackerConnection		*connection;
	WCServerTracker			*tracker;
	
	connection = [notification object];
	
	if(![connection isKindOfClass:[WCTrackerConnection class]])
		return;
	
	tracker = [connection tracker];
	
	if([tracker state] != WCServerTrackerLoaded) {
		[_serversOutlineView collapseItem:tracker];
		
		[tracker setState:WCServerTrackerIdle];
	}
	
	[_progressIndicator stopAnimation:self];
}



- (void)wiredTrackerGetCategoriesReply:(WIP7Message *)message {
	NSEnumerator				*enumerator, *pathEnumerator;
	NSArray						*categories;
	NSString					*path, *component, *categoryPath;
	WCServerTracker				*tracker;
	WCServerTrackerCategory		*category;
	WCServerContainer			*item;
	
	tracker = [(id) [message contextInfo] tracker];
	
	if([[message name] isEqualToString:@"wired.tracker.categories"]) {
		categories = [message listForName:@"wired.tracker.categories"];
		enumerator = [categories objectEnumerator];
		
		while((path = [enumerator nextObject])) {
			item			= tracker;
			categoryPath	= @"";
			pathEnumerator	= [[path pathComponents] objectEnumerator];
			
			while((component = [pathEnumerator nextObject])) {
				categoryPath	= [categoryPath stringByAppendingPathComponent:component];
				category		= [tracker categoryForPath:categoryPath];
				
				if(!category) {
					category = [WCServerTrackerCategory itemWithName:component];
					
					[item addItem:category];
				}
					
				item = category;
			}
		}
	}
	else if([[message name] isEqualToString:@"wired.error"]) {
		[_errorQueue showError:[WCError errorWithWiredMessage:message]];
	}
}



- (void)wiredTrackerGetServersReply:(WIP7Message *)message {
	WCServerTracker				*tracker;
	WCServerTrackerCategory		*category;
	WCServerTrackerServer		*server;
	
	tracker = [(id) [message contextInfo] tracker];
	
	if([[message name] isEqualToString:@"wired.tracker.server_list"]) {
		server		= [WCServerTrackerServer itemWithMessage:message];
		category	= [tracker categoryForPath:[server categoryPath]];
		
		if(category)
			[category addItem:server];
		else
			[tracker addItem:server];
	}
	else if([[message name] isEqualToString:@"wired.tracker.server_list.done"]) {
		[tracker setState:WCServerTrackerLoaded];

		[(id) [message contextInfo] terminate];
		
		[self _sortServers];
		
		[_serversOutlineView reloadData];
		
		[self _updateStatus];
	}
	else if([[message name] isEqualToString:@"wired.error"]) {
		[(id) [message contextInfo] terminate];

		[_errorQueue showError:[WCError errorWithWiredMessage:message]];
	}
}



- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didFindService:(NSNetService *)netService moreComing:(BOOL)moreComing {
	[netService setDelegate:self];
	[netService resolveWithTimeout:5.0];

	[_bonjour addItem:[WCServerBonjourServer itemWithNetService:netService]];

	if(!moreComing) {
		[_serversOutlineView reloadData];
		
		[self _updateStatus];
	}
}



- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didRemoveService:(NSNetService *)netService moreComing:(BOOL)moreComing {
	NSEnumerator			*enumerator;
	WCServerBonjourServer	*server;

	enumerator = [[_bonjour items] objectEnumerator];

	while((server = [enumerator nextObject])) {
		if([[server netService] isEqualToNetService:netService]) {
			[_bonjour removeItem:server];

			break;
		}
	}

	if(!moreComing) {
		[_serversOutlineView reloadData];
		
		[self _updateStatus];
	}
}



- (void)netServiceDidResolveAddress:(NSNetService *)netService {
	[netService stop];
}



#pragma mark -

- (BOOL)validateToolbarItem:(NSToolbarItem *)toolbarItem {
	id		item;
	SEL		selector;
	
	selector = [toolbarItem action];
	item = [self _selectedItem];
	
	if(selector == @selector(reload:))
		return [item class] == [WCServerTracker class];
	else if(selector == @selector(open:))
		return ([item class] == [WCServerBonjourServer class] || [item class] == [WCServerTrackerServer class]);
	else if(selector == @selector(addBookmark:))
		return ([item class] == [WCServerBonjourServer class] || [item class] == [WCServerTrackerServer class]);
	else if(selector == @selector(addTrackerBookmark:))
		return ([item class] == [WCServerTrackerServer class] && [item isTracker]);
	else if(selector == @selector(deleteBookmark:))
		return ([item class] == [WCServerBookmarkServer class] || [item class] == [WCServerTracker class]);
	
	return YES;
}



#pragma mark -

- (IBAction)reload:(id)sender {
	id						item;
	WCServerTrackerState	state;
	
	item = [self _selectedItem];
	
	if([item isKindOfClass:[WCServerTracker class]]) {
		state = [item state];
		
		if(state == WCServerTrackerIdle)
			[_serversOutlineView expandItem:item];
		else
			[self _openTracker:item];
	}
}



- (IBAction)open:(id)sender {
	WIURL				*url;
	WCConnect			*connect;
	WCError				*error;
	id					item;
	
	if(sender == _serversOutlineView && [_serversOutlineView clickedHeader])
		return;

	item = [self _selectedItem];
	
	if([item isKindOfClass:[WCServerBookmarkServer class]] ||
	   [item isKindOfClass:[WCServerBonjourServer class]] ||
	   [item isKindOfClass:[WCServerTrackerServer class]]) {
		if([item isKindOfClass:[WCServerBonjourServer class]]) {
			url = [item URLWithError:&error];
			
			if(!url) {
				[[error alert] beginSheetModalForWindow:[self window]];
				
				return;
			}
		} else {
			url = [(WCServerTrackerServer *) item URL];
		}
		
		connect = [WCConnect connectWithURL:url bookmark:NULL];
		[connect showWindow:self];
		
		if(![[NSApp currentEvent] alternateKeyModifier])
			[connect connect:self];
	}
}



- (IBAction)addBookmark:(id)sender {
	NSDictionary	*bookmark;
	WIURL			*url;
	WCError			*error;
	id				item;
	
	item = [self _selectedItem];
	
	if([item class] == [WCServerBonjourServer class] || [item class] == [WCServerTrackerServer class]) {
		if([item class] == [WCServerBonjourServer class]) {
			url = [item URLWithError:&error];
			
			if(!url) {
				[[error alert] beginSheetModalForWindow:[self window]];
				
				return;
			}
		} else {
			url = [(WCServerTrackerServer *) item URL];
		}
		
		bookmark = [NSDictionary dictionaryWithObjectsAndKeys:
			[item name],					WCBookmarksName,
			[url hostpair],					WCBookmarksAddress,
			@"",							WCBookmarksLogin,
			@"",							WCBookmarksNick,
			@"",							WCBookmarksStatus,
			[NSString UUIDString],			WCBookmarksIdentifier,
			NULL];
		
		[[WCSettings settings] addObject:bookmark toArrayForKey:WCBookmarks];
		
		[self _reloadServers];
	}
}



- (IBAction)addTrackerBookmark:(id)sender {
	NSDictionary	*bookmark;
	WIURL			*url;
	id				item;
	
	item = [self _selectedItem];
	
	if([item class] == [WCServerTrackerServer class] && [item isTracker]) {
		url = [(WCServerTrackerServer *) item URL];
		
		bookmark = [NSDictionary dictionaryWithObjectsAndKeys:
			[item name],					WCTrackerBookmarksName,
			[url hostpair],					WCTrackerBookmarksAddress,
			@"",							WCTrackerBookmarksLogin,
			[NSString UUIDString],			WCTrackerBookmarksIdentifier,
			NULL];
		
		[[WCSettings settings] addObject:bookmark toArrayForKey:WCTrackerBookmarks];
		
		[self _reloadServers];
	}
}



- (IBAction)deleteBookmark:(id)sender {
	NSArray			*bookmarks;
	NSString		*identifier;
	id				item;
	NSUInteger		i, count, index;
	
	item = [self _selectedItem];
	
	if([item class] == [WCServerBookmarkServer class]) {
		identifier		= [[item bookmark] objectForKey:WCBookmarksIdentifier];
		bookmarks		= [[WCSettings settings] objectForKey:WCBookmarks];
		count			= [bookmarks count];
		index			= NSNotFound;
		
		for(i = 0; i < count; i++) {
			if([[[bookmarks objectAtIndex:i] objectForKey:WCBookmarksIdentifier] isEqualToString:identifier]) {
				index = i;
				
				break;
			}
		}
		
		if(index != NSNotFound)
			[[WCSettings settings] removeObjectAtIndex:index fromArrayForKey:WCBookmarks];
	}
	else if([item class] == [WCServerTracker class]) {
		identifier		= [[item bookmark] objectForKey:WCTrackerBookmarksIdentifier];
		bookmarks		= [[WCSettings settings] objectForKey:WCTrackerBookmarks];
		count			= [bookmarks count];
		index			= NSNotFound;
		
		for(i = 0; i < count; i++) {
			if([[[bookmarks objectAtIndex:i] objectForKey:WCTrackerBookmarksIdentifier] isEqualToString:identifier]) {
				index = i;
				
				break;
			}
		}
		
		if(index != NSNotFound)
			[[WCSettings settings] removeObjectAtIndex:index fromArrayForKey:WCTrackerBookmarks];
	}

	[self _reloadServers];
}



- (IBAction)search:(id)sender {
	[_itemFilter release];
	
	if([[sender stringValue] length] > 0)
		_itemFilter = [[sender stringValue] retain];
	else
		_itemFilter = NULL;
	
	[_serversOutlineView reloadData];
}



#pragma mark -

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
	if(!item)
		item = _servers;

	if([item isKindOfClass:[WCServerContainer class]])
		return [[self _filteredItems:[item items]] count];
	
	return 0;
}



- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
	NSArray		*items;
	
	if(!item)
		item = _servers;

	if([item isKindOfClass:[WCServerContainer class]]) {
		items = [self _filteredItems:[item items]];

		if([_serversOutlineView sortOrder] == WISortDescending)
			return [items objectAtIndex:[items count] - index - 1];
		else
			return [items objectAtIndex:index];
	}
	
	return NULL;
}



- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
	if(tableColumn == _nameTableColumn)
		return [item name];

	if([item isKindOfClass:[WCServerTrackerServer class]]) {
		if(tableColumn == _usersTableColumn)
			return [NSSWF:@"%u", [item users]];
		else if(tableColumn == _filesCountTableColumn)
			return [NSSWF:@"%u", [item filesCount]];
		else if(tableColumn == _filesSizeTableColumn)
			return [_sizeFormatter stringFromSize:[item filesSize]];
		else if(tableColumn == _descriptionTableColumn)
			return [item serverDescription];
	}
	
	return NULL;
}



- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {
	if(tableColumn == _nameTableColumn)
		[cell setImage:[item icon]];
}



- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
	return ([item isKindOfClass:[WCServerContainer class]] && [item isExpandable]);
}



- (void)outlineViewItemDidExpand:(NSNotification *)notification {
	id		item;
	
	item = [[notification userInfo] objectForKey:@"NSObject"];
	
	if([item isKindOfClass:[WCServerTracker class]] && [item state] == WCServerTrackerIdle)
		[self _openTracker:item];
}



- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectTableColumn:(NSTableColumn *)tableColumn {
	[_serversOutlineView setHighlightedTableColumn:tableColumn];
	[self _sortServers];
	[_serversOutlineView reloadData];
	
	return NO;
}



- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
	[self _validate];
	[self _updateStatus];
}



- (NSString *)outlineView:(NSOutlineView *)outlineView stringValueByItem:(id)item {
	return [item name];
}

@end
