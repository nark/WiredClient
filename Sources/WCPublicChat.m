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

#import "WCAccount.h"
#import "WCAdministration.h"
#import "WCApplicationController.h"
#import "WCBoards.h"
#import "WCChatHistory.h"
#import "WCFile.h"
#import "WCFiles.h"
#import "WCKeychain.h"
#import "WCMessages.h"
#import "WCPreferences.h"
#import "WCPrivateChat.h"
#import "WCPublicChat.h"
#import "WCPublicChatController.h"
#import "WCServer.h"
#import "WCConnection.h"
#import "WCServerConnection.h"
#import "WCTrackerConnection.h"
#import "WCTrackerServerInfo.h"
#import "WCServerInfo.h"
#import "WCUser.h"
#import "WCServerItem.h"
#import "WCErrorQueue.h"
#import "WCConnect.h"
#import "WCTabBarItem.h"
#import "WCTransfers.h"
#import "WCServerBookmarkController.h"
#import "WCTrackerBookmarkController.h"


#define WCBookmarkPboardType                        @"WCBookmarkPboardType"
#define WCTrackerBookmarkPboardType                 @"WCTrackerBookmarkPboardType"


enum _WCChatActivity {
	WCChatNoActivity						= 0,
	WCChatEventActivity,
	WCChatRegularChatActivity,
	WCChatHighlightedChatActivity,
};
typedef enum _WCChatActivity				WCChatActivity;


@interface WCPublicChat(Private)

- (void)_updateToolbarForConnection:(WCServerConnection *)connection;
- (void)_updateBannerToolbarItem:(NSToolbarItem *)item forConnection:(WCServerConnection *)connection;
- (void)_updateTabViewItemForConnection:(WCServerConnection *)connection;

- (BOOL)_beginConfirmDisconnectSheetModalForWindow:(NSWindow *)window connection:(WCServerConnection *)connection modalDelegate:(id)delegate didEndSelector:(SEL)selector contextInfo:(void *)contextInfo;

- (void)_closeSelectedTabViewItem;
- (void)_removeTabViewItem:(NSTabViewItem *)tabViewItem;

- (id)_selectedItem;

- (void)_reloadServers;
- (void)_sortServers;

- (void)_connectToServer:(id)item;
- (void)_openTracker:(WCServerTracker *)tracker;

- (BOOL)_addBookmarkForConnection:(WCServerConnection *)connection;

@end




 

@implementation WCPublicChat(Private)

- (void)_updateToolbarForConnection:(WCServerConnection *)connection {
	NSToolbarItem       *item;
    
	item = [[[self window] toolbar] itemWithIdentifier:@"Banner"];
	
	[item setEnabled:(connection != NULL)];
    
	if(connection == [[self selectedChatController] connection]) {
		item = [[[self window] toolbar] itemWithIdentifier:@"Banner"];
        
		[self _updateBannerToolbarItem:item forConnection:connection];
	}
	
	item = [[[self window] toolbar] itemWithIdentifier:@"Messages"];
	
	[item setImage:[[NSImage imageNamed:@"Messages"] badgedImageWithInt:[[WCMessages messages] numberOfUnreadMessages]]];
    
	item = [[[self window] toolbar] itemWithIdentifier:@"Boards"];
    
	[item setImage:[[NSImage imageNamed:@"Boards"] badgedImageWithInt:[[WCBoards boards] numberOfUnreadThreads]]];
    
    item = [[[self window] toolbar] itemWithIdentifier:@"Transfers"];
    
    [item setImage:[[NSImage imageNamed:@"Transfers"] badgedImageWithInt:[[WCTransfers transfers] numberOfUncompleteTransfers]]];
}



- (void)_updateBannerToolbarItem:(NSToolbarItem *)item forConnection:(WCServerConnection *)connection {
	NSImage		*image;
    
	if(connection) {
		[item setLabel:[connection name]];
		[item setPaletteLabel:[connection name]];
		[item setToolTip:[connection name]];
	} else {
		[item setLabel:NSLS(@"Banner", @"Banner toolbar item")];
		[item setPaletteLabel:NSLS(@"Banner", @"Banner toolbar item")];
		[item setToolTip:NSLS(@"Banner", @"Banner toolbar item")];
	}
	
	image = [[connection server] banner];
	
	if(image)
		[(NSButton *) [item view] setImage:image];
	else
		[(NSButton *) [item view] setImage:[NSImage imageNamed:@"Banner"]];
}


- (void)_updateTabViewItemForConnection:(WCServerConnection *)connection {
    NSTabViewItem   *item;
    WCTabBarItem    *proxy;
    NSInteger       count;
    
    count   = 0;
    item    = [_tabBarView tabViewItemWithIdentifier:[connection identifier]];
    
    if(!item)
        return;
    
    proxy   = (WCTabBarItem *)[item identifier];
    
    [proxy setObjectCount:[self numberOfUnreadsForConnection:connection]];
}



#pragma mark -

- (BOOL)_beginConfirmDisconnectSheetModalForWindow:(NSWindow *)window connection:(WCServerConnection *)connection modalDelegate:(id)delegate didEndSelector:(SEL)selector contextInfo:(void *)contextInfo {
	NSAlert		*alert;
	
	if([[WCSettings settings] boolForKey:WCConfirmDisconnect] && [connection isConnected]) {
		alert = [[NSAlert alloc] init];
		[alert setMessageText:NSLS(@"Are you sure you want to disconnect?", @"Disconnect dialog title")];
		[alert setInformativeText:NSLS(@"Disconnecting will close any ongoing file transfers.", @"Disconnect dialog description")];
		[alert addButtonWithTitle:NSLS(@"Disconnect", @"Disconnect dialog button")];
		[alert addButtonWithTitle:NSLS(@"Cancel", @"Disconnect dialog button title")];
		[alert beginSheetModalForWindow:window
						  modalDelegate:delegate
						 didEndSelector:selector
							contextInfo:contextInfo];
		[alert release];
		
		return NO;
	}
	
	return YES;
}



#pragma mark -

- (void)_closeSelectedTabViewItem {
	NSTabViewItem			*tabViewItem;
	
	tabViewItem = [_chatTabView selectedTabViewItem];
	
	[self _removeTabViewItem:tabViewItem];
	
	[_chatTabView removeTabViewItem:tabViewItem];
}



- (void)_removeTabViewItem:(NSTabViewItem *)tabViewItem {
	NSString				*identifier;
	WCPublicChatController	*chatController;
	WCUser					*user;
	
	identifier          = [[tabViewItem identifier] valueForKey:@"identifier"];
	chatController	= [_chatControllers objectForKey:identifier];
	user			= [chatController userWithUserID:[[chatController connection] userID]];
	
	if([[WCSettings settings] boolForKey:WCChatLogsHistoryEnabled] && ![chatController chatIsEmpty])
		[[[[WCApplicationController sharedController] logController] publicChatHistoryBundle] addHistoryForWebView:[chatController webView]
                                                                                                withConnectionName:[[chatController connection] name]
                                                                                                          identity:[user nick]];
	
	[chatController saveWindowProperties];
	
	[[chatController connection] terminate];
	
	[_chatControllers removeObjectForKey:identifier];
	[_chatActivity removeObjectForKey:identifier];
	
	if([_chatControllers count] == 0) {
		[self _updateToolbarForConnection:NULL];
		
		[_noConnectionTextField setHidden:NO];
	}
}



- (id)_selectedItem {
	NSInteger		row;
    
    row = [_serversOutlineView clickedRow];
	
	if(row >= 0)
        return [_serversOutlineView itemAtRow:row];
	
	row = [_serversOutlineView selectedRow];
	
	if(row >= 0)
        return [_serversOutlineView itemAtRow:row];
    
    row = [[_serversOutlineView selectedRowIndexes] firstIndex];
	
    if(row >= 0)
        return [_serversOutlineView itemAtRow:row];
    
	return nil;
}





- (void)_reloadServers {
	NSEnumerator		*enumerator;
	NSDictionary		*bookmark;
	
    [_progressIndicator startAnimation:self];
    
	[_bookmarks removeAllItems];
	[_servers removeAllItems];
	[_trackers removeAllItems];
    
	[_servers addItem:_bonjour];
	
	enumerator = [[[WCSettings settings] objectForKey:WCBookmarks] objectEnumerator];
	
	while((bookmark = [enumerator nextObject]))
		[_bookmarks addItem:[WCServerBookmarkServer itemWithBookmark:bookmark]];
	
	[_servers addItem:_bookmarks];
	
	enumerator = [[[WCSettings settings] objectForKey:WCTrackerBookmarks] objectEnumerator];
	
	while((bookmark = [enumerator nextObject]))
		[_trackers addItem:[WCServerTracker itemWithBookmark:bookmark]];
    
    [_servers addItem:_trackers];
	
	[self _sortServers];
	
	[_serversOutlineView reloadData];
    [_progressIndicator stopAnimation:self];
}



- (void)_sortServers {
    //	NSTableColumn   *tableColumn;
    //	SEL				selector;
    //
    //	tableColumn = [_serversOutlineView highlightedTableColumn];
    //    selector    = @selector(compareName:);
    //
    //	[_servers sortUsingSelector:selector];
}






#pragma mark -

- (void)_connectToServer:(id)item {
    WIURL                       *url;
    WCPublicChatController      *chatController;
    NSDictionary                *bookmark;
	WCConnect                   *connect;
	WCError                     *error;
    
    bookmark        = NULL;
    chatController  = nil;
    
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
        
        if([item isKindOfClass:[WCServerBookmarkServer class]]) {
            bookmark = [item bookmark];
            chatController = [self chatControllerForBookmarkIdentifier:[[item bookmark] objectForKey:WCBookmarksIdentifier]];
        } else {
            chatController = [self chatControllerForURL:url];
        }
        
        if(chatController == nil) {
            
            connect = [WCConnect connectWithURL:url bookmark:bookmark];
            [connect showWindow:self];
            
            [_progressIndicator startAnimation:self];
            
            if(![[NSApp currentEvent] alternateKeyModifier])
                [connect connect:self];
            
            [_progressIndicator stopAnimation:self];
            
        } else {
            //NSLog(@"chatController: %@", chatController);
            [self selectChatController:chatController];
            
            if(![[chatController connection] isConnected]) {
                [[chatController connection] reconnect];
            }
        }
	}
    
}



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




#pragma mark -

- (BOOL)_addBookmarkForConnection:(WCServerConnection *)connection {
    NSDictionary	*bookmark;
	NSString		*login, *password;
	WIURL			*url;
    
	url             = [connection URL];
	
	if(url != nil) {
		login		= [url user] ? [url user] : @"";
		password	= [url password] ? [url password] : @"";
		bookmark	= [NSDictionary dictionaryWithObjectsAndKeys:
                       [connection name],			WCBookmarksName,
                       [url hostpair],				WCBookmarksAddress,
                       login,						WCBookmarksLogin,
                       @"",							WCBookmarksNick,
                       @"",							WCBookmarksStatus,
                       [NSString UUIDString],		WCBookmarksIdentifier,
                       NULL];
		
		[[WCSettings settings] addObject:bookmark toArrayForKey:WCBookmarks];
		[[WCKeychain keychain] setPassword:password forBookmark:bookmark];
		
		[connection setBookmark:bookmark];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:WCBookmarksDidChangeNotification];
        
        return YES;
	}
    return NO;
}


@end






@implementation WCPublicChat


+ (id)publicChat {
	static WCPublicChat			*publicChat;
	
	if(!publicChat)
		publicChat = [[self alloc] init];
	
	return publicChat;
}



- (id)init {
	self = [super initWithWindowNibName:@"PublicChatWindow"];
    
	_chatControllers	= [[NSMutableDictionary alloc] init];
	_chatActivity		= [[NSMutableDictionary alloc] init];
    
    _bonjour		= [[WCServerBonjour bonjourItem] retain];
	_bookmarks		= [[WCServerBookmarks bookmarksItem] retain];
    
	_servers		= [[WCServerContainer alloc] initWithName:@"<root>"];
	_trackers       = [[WCServerContainer alloc] initWithName:NSLS(@"TRACKERS",  @"Trackers server")];
    
	_browser		= [[NSNetServiceBrowser alloc] init];
    
	[_browser setDelegate:self];
	[_browser searchForServicesOfType:WCBonjourName inDomain:@""];
    
	[[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(bookmarksDidChange:)
     name:WCBookmarksDidChangeNotification];
    
	[[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(trackerBookmarksDidChange:)
     name:WCTrackerBookmarksDidChangeNotification];
    
	
	[[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(serverConnectionServerInfoDidChange:)
     name:WCServerConnectionServerInfoDidChangeNotification];
	
	[[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(chatRegularChatDidAppear:)
     name:WCChatRegularChatDidAppearNotification];
	
	[[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(chatHighlightedChatDidAppear:)
     name:WCChatHighlightedChatDidAppearNotification];
	
	[[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(chatEventDidAppear:)
     name:WCChatEventDidAppearNotification];
	
	[[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(boardsDidChangeUnreadCount:)
     name:WCBoardsDidChangeUnreadCountNotification];
	
	[[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(messagesDidChangeUnreadCount:)
     name:WCMessagesDidChangeUnreadCountNotification];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(transfersQueueUpdated:)
     name:WCTransfersQueueUpdatedNotification];
	
	[self window];
	
	return self;
}



- (void)dealloc {
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	//[_tabBarControl release];
	
	[_chatControllers release];
	[_chatActivity release];
    
    [_browser release];
	[_servers release];
	[_bonjour release];
	[_bookmarks release];
    [_trackers release];
    
    [_errorQueue release];
	
	[super dealloc];
}



#pragma mark -

- (void)windowDidLoad {
	NSToolbar			*toolbar;
	
    _errorQueue = [[WCErrorQueue alloc] initWithWindow:[self window]];
    
	toolbar = [[NSToolbar alloc] initWithIdentifier:@"PublicChat"];
	[toolbar setDelegate:self];
	[toolbar setAllowsUserCustomization:YES];
	[toolbar setAutosavesConfiguration:YES];
	[toolbar setShowsBaselineSeparator:NO];

	[[self window] setToolbar:toolbar];
	[toolbar release];
	
	[self setShouldCascadeWindows:NO];
	[self setWindowFrameAutosaveName:@"PublicChat"];
    
	[_serversOutlineView setTarget:self];
	[_serversOutlineView setDoubleAction:@selector(openServer:)];
	[_serversOutlineView setAutoresizesOutlineColumn:NO];
	[_serversOutlineView setAutosaveName:@"Resources"];
	[_serversOutlineView setAutosaveTableColumns:YES];
    [_serversOutlineView registerForDraggedTypes:[NSArray arrayWithObjects:WCBookmarkPboardType, WCTrackerBookmarkPboardType, nil]];
	
	[self _reloadServers];
	
	[_serversOutlineView expandItem:_bonjour];
	[_serversOutlineView expandItem:_bookmarks];
    [_serversOutlineView expandItem:_trackers];
    
    [_tabBarView setTabView:_chatTabView];
	[_tabBarView setStyleNamed:@"Yosemite"];
	[_tabBarView setDelegate:self];
	[_tabBarView setCanCloseOnlyTab:YES];
    [_tabBarView setShowAddTabButton:YES];
    [_tabBarView setAllowsBackgroundTabClosing:YES];
    [_tabBarView setAutomaticallyAnimates:YES];
    [_tabBarView setHideForSingleTab:NO];
    [_tabBarView setOnlyShowCloseOnHover:YES];
    [_tabBarView setAllowsScrubbing:YES];
    [_tabBarView setAllowsResizing:YES];
    
	[_tabBarView setPartnerView:_resourcesSplitView];
	[_chatTabView setDelegate:(id)_tabBarView];
    
    [_viewsSegmentedControl setSelected:![[WCSettings settings] boolForKey:WCHideServerList] forSegment:0];
    [_viewsSegmentedControl setSelected:![[WCSettings settings] boolForKey:WCHideUserList] forSegment:1];
    
    if([[WCSettings settings] boolForKey:WCHideServerList])
        [self hideServerList:self];
    
    if([[WCSettings settings] boolForKey:WCHideUserList])
        [self hideUserList:self];
    
    [[_noConnectionTextField cell] setBackgroundStyle:NSBackgroundStyleRaised];
	
	[self _updateToolbarForConnection:NULL];
    
	[super windowDidLoad];
}



- (void)windowWillClose:(NSNotification *)notification {
	[[self selectedChatController] saveWindowProperties];
}




#pragma mark - Toolbar

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)identifier willBeInsertedIntoToolbar:(BOOL)willBeInsertedIntoToolbar {
	NSButton		*button;
	
	if([identifier isEqualToString:@"Banner"]) {
		button = [[[NSButton alloc] initWithFrame:NSMakeRect(0.0, 0.0, 200.0, 32.0)] autorelease];
		[button setBordered:NO];
		[button setImage:[NSImage imageNamed:@"Banner"]];
        [[button cell] setImageScaling:NSImageScaleProportionallyUpOrDown];
		[button setButtonType:NSMomentaryChangeButton];
		
		return [NSToolbarItem toolbarItemWithIdentifier:identifier
												   name:NSLS(@"Banner", @"Banner toolbar item")
												content:button
												 target:self
												 action:@selector(serverInfo:)];
	}
	else if([identifier isEqualToString:@"Boards"]) {
		return [NSToolbarItem toolbarItemWithIdentifier:identifier
												   name:NSLS(@"Boards", @"Boards toolbar item")
												content:[NSImage imageNamed:@"Boards"]
												 target:[WCApplicationController sharedController]
												 action:@selector(boards:)];
	}
	else if([identifier isEqualToString:@"Messages"]) {
		return [NSToolbarItem toolbarItemWithIdentifier:identifier
												   name:NSLS(@"Messages", @"Messages toolbar item")
												content:[NSImage imageNamed:@"Messages"]
												 target:[WCApplicationController sharedController]
												 action:@selector(messages:)];
	}
	else if([identifier isEqualToString:@"Files"]) {
		return [NSToolbarItem toolbarItemWithIdentifier:identifier
												   name:NSLS(@"Files", @"Files toolbar item")
												content:[NSImage imageNamed:@"Folder"]
												 target:self
												 action:@selector(files:)];
	}
	else if([identifier isEqualToString:@"Transfers"]) {
		return [NSToolbarItem toolbarItemWithIdentifier:identifier
												   name:NSLS(@"Transfers", @"Transfers toolbar item")
												content:[NSImage imageNamed:@"Transfers"]
												 target:[WCApplicationController sharedController]
												 action:@selector(transfers:)];
	}
	else if([identifier isEqualToString:@"Settings"]) {
		return [NSToolbarItem toolbarItemWithIdentifier:identifier
												   name:NSLS(@"Settings", @"Settings toolbar item")
												content:[NSImage imageNamed:@"Settings"]
												 target:self
												 action:@selector(settings:)];
	}
	else if([identifier isEqualToString:@"Monitor"]) {
		return [NSToolbarItem toolbarItemWithIdentifier:identifier
												   name:NSLS(@"Monitor", @"Monitor toolbar item")
												content:[NSImage imageNamed:@"Monitor"]
												 target:self
												 action:@selector(monitor:)];
	}
	else if([identifier isEqualToString:@"Events"]) {
		return [NSToolbarItem toolbarItemWithIdentifier:identifier
												   name:NSLS(@"Events", @"Events toolbar item")
												content:[NSImage imageNamed:@"Events"]
												 target:self
												 action:@selector(events:)];
	}
	else if([identifier isEqualToString:@"Log"]) {
		return [NSToolbarItem toolbarItemWithIdentifier:identifier
												   name:NSLS(@"Log", @"Log toolbar item")
												content:[NSImage imageNamed:@"Log"]
												 target:self
												 action:@selector(log:)];
	}
    else if([identifier isEqualToString:@"Clear"]) {
		return [NSToolbarItem toolbarItemWithIdentifier:identifier
												   name:NSLS(@"Clear", @"Clear public chat")
												content:[NSImage imageNamed:@"ClearChat"]
												 target:self
												 action:@selector(clear:)];
	}
	else if([identifier isEqualToString:@"Now Playing"]) {
		return [NSToolbarItem toolbarItemWithIdentifier:identifier
												   name:NSLS(@"Now Playing", @"Now Playing public chat")
												content:[NSImage imageNamed:@"NowPlaying"]
												 target:self
												 action:@selector(nowPlaying:)];
	}
	else if([identifier isEqualToString:@"Chat History"]) {
		return [NSToolbarItem toolbarItemWithIdentifier:identifier
												   name:NSLS(@"Chat History", @"Chat History public chat")
												content:[NSImage imageNamed:@"Chat History"]
												 target:self
												 action:@selector(chatHistory:)];
	}
	else if([identifier isEqualToString:@"Accounts"]) {
		return [NSToolbarItem toolbarItemWithIdentifier:identifier
												   name:NSLS(@"Accounts", @"Accounts toolbar item")
												content:[NSImage imageNamed:@"Accounts"]
												 target:self
												 action:@selector(accounts:)];
	}
	else if([identifier isEqualToString:@"Banlist"]) {
		return [NSToolbarItem toolbarItemWithIdentifier:identifier
												   name:NSLS(@"Banlist", @"Banlist toolbar item")
												content:[NSImage imageNamed:@"Banlist"]
												 target:self
												 action:@selector(banlist:)];
	}
	else if([identifier isEqualToString:@"Reconnect"]) {
		return [NSToolbarItem toolbarItemWithIdentifier:identifier
												   name:NSLS(@"Reconnect", @"Disconnect toolbar item")
												content:[NSImage imageNamed:@"Reconnect"]
												 target:self
												 action:@selector(reconnect:)];
	}
	else if([identifier isEqualToString:@"Disconnect"]) {
		return [NSToolbarItem toolbarItemWithIdentifier:identifier
												   name:NSLS(@"Disconnect", @"Disconnect toolbar item")
												content:[NSImage imageNamed:@"Disconnect"]
												 target:self
												 action:@selector(disconnect:)];
	}
    else if([identifier isEqualToString:@"Views"]) {
		return [NSToolbarItem toolbarItemWithIdentifier:identifier
												   name:NSLS(@"Views", @"Views toolbar item")
												content:_viewsSegmentedControl
												 target:self
												 action:@selector(switchViews:)];
	}
	
	return NULL;
}



- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
	return [NSArray arrayWithObjects:
            @"Views",
            NSToolbarFlexibleSpaceItemIdentifier,
            @"Banner",
            NSToolbarSpaceItemIdentifier,
            @"Boards",
            @"Messages",
            @"Files",
            @"Transfers",
            @"Settings",
            NSToolbarFlexibleSpaceItemIdentifier,
            @"Reconnect",
            @"Disconnect",
            NULL];
}



- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
	return [NSArray arrayWithObjects:
            @"Banner",
            @"Boards",
            @"Messages",
            @"Files",
            @"Transfers",
            @"Settings",
            @"Monitor",
            @"Events",
            @"Log",
            @"Accounts",
            @"Banlist",
            @"Clear",
            @"Now Playing",
            @"Chat History",
            @"Views",
            @"Reconnect",
            @"Disconnect",
            NSToolbarSeparatorItemIdentifier,
            NSToolbarSpaceItemIdentifier,
            NSToolbarFlexibleSpaceItemIdentifier,
            NSToolbarCustomizeToolbarItemIdentifier,
            NULL];
}



//- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar {
//    return [NSArray arrayWithObjects:
//            @"Chat",
//            @"Boards",
//            @"Messages",
//            @"Files",
//            @"Transfers",
//            NULL];
//}



- (void)toolbarWillAddItem:(NSNotification *)notification {
	NSToolbarItem		*item;
	
	item = [[notification userInfo] objectForKey:@"item"];
	
	if([[item itemIdentifier] isEqualToString:@"Banner"])
		[self _updateBannerToolbarItem:item forConnection:[[self selectedChatController] connection]];
}





#pragma mark -

- (void)serverConnectionServerInfoDidChange:(NSNotification *)notification {
	WCServerConnection		*connection;
	
	connection = [notification object];
    
	[[_chatTabView tabViewItemWithIdentifier:[connection identifier]] setLabel:[connection name]];
	[self _updateToolbarForConnection:connection];
}



- (void)chatRegularChatDidAppear:(NSNotification *)notification {
	NSTabViewItem			*tabViewItem;
	NSColor					*color;
    WCTabBarItem            *tabViewItemModel;
	WCServerConnection		*connection;
	WCChatActivity			activity;
    
	connection          = [notification object];
	activity            = [[_chatActivity objectForKey:[connection identifier]] integerValue];
	tabViewItem         = [_tabBarView tabViewItemWithIdentifier:[connection identifier]];
	tabViewItemModel    = [tabViewItem identifier];
    
	if(tabViewItem != [_chatTabView selectedTabViewItem] && activity < WCChatRegularChatActivity) {
		color = [WIColorFromString([[connection theme] objectForKey:WCThemesChatTextColor]) colorWithAlphaComponent:0.5];
        
        [tabViewItemModel setIcon:[[NSImage imageNamed:@"GrayDrop"] tintedImageWithColor:color]];
        
		[_chatActivity setObject:[NSNumber numberWithInteger:WCChatRegularChatActivity] forKey:[connection identifier]];
	}
}



- (void)chatHighlightedChatDidAppear:(NSNotification *)notification {
	NSTabViewItem			*tabViewItem;
	NSColor					*color;
    WCTabBarItem            *tabViewItemModel;
	WCServerConnection		*connection;
	WCChatActivity			activity;
	
	connection          = [notification object];
	activity            = [[_chatActivity objectForKey:[connection identifier]] integerValue];
	tabViewItem         = [_tabBarView tabViewItemWithIdentifier:[connection identifier]];
	tabViewItemModel    = [tabViewItem identifier];
    
	if(tabViewItem != [_chatTabView selectedTabViewItem] && activity < WCChatHighlightedChatActivity) {
		color = [[[notification userInfo] objectForKey:WCChatHighlightColorKey] colorWithAlphaComponent:0.5];
        
		[tabViewItemModel setIcon:[[NSImage imageNamed:@"GrayDrop"] tintedImageWithColor:color]];
        
		[_chatActivity setObject:[NSNumber numberWithInteger:WCChatHighlightedChatActivity] forKey:[connection identifier]];
	}
}



- (void)chatEventDidAppear:(NSNotification *)notification {
	NSTabViewItem			*tabViewItem;
	NSColor					*color;
    WCTabBarItem            *tabViewItemModel;
	WCServerConnection		*connection;
	WCChatActivity			activity;
	
	connection          = [notification object];
	activity            = [[_chatActivity objectForKey:[connection identifier]] integerValue];
	tabViewItem         = [_tabBarView tabViewItemWithIdentifier:[connection identifier]];
	tabViewItemModel    = [tabViewItem identifier];
    
	if(tabViewItem != [_chatTabView selectedTabViewItem] && activity < WCChatEventActivity) {
		color = [WIColorFromString([[connection theme] objectForKey:WCThemesChatEventsColor]) colorWithAlphaComponent:0.5];
        
        [tabViewItemModel setIcon:[[NSImage imageNamed:@"GrayDrop"] tintedImageWithColor:color]];
		
		[_chatActivity setObject:[NSNumber numberWithInteger:WCChatEventActivity] forKey:[connection identifier]];
	}
}



- (void)boardsDidChangeUnreadCount:(NSNotification *)notification {
    for(WCChatController *cc in [self chatControllers]) {
        [self _updateToolbarForConnection:[cc connection]];
        [self _updateTabViewItemForConnection:[cc connection]];
    }
    
    [_serversOutlineView reloadData];
}



- (void)messagesDidChangeUnreadCount:(NSNotification *)notification {
    [self _updateToolbarForConnection:NULL];
    
    for(WCChatController *cc in [self chatControllers]) {
        [self _updateToolbarForConnection:[cc connection]];
        [self _updateTabViewItemForConnection:[cc connection]];
    }
    
    [_serversOutlineView reloadData];
}

- (void)transfersQueueUpdated:(NSNotification *)notification {
	[self _updateToolbarForConnection:[[self selectedChatController] connection]];
}







#pragma mark -

- (void)tabView:(NSTabView *)tabView willSelectTabViewItem:(NSTabViewItem *)tabViewItem {
	WCPublicChatController		*chatController;
	
	chatController = [_chatControllers objectForKey:[[tabViewItem identifier] valueForKey:@"identifier"]];
	
	[_chatActivity removeObjectForKey:[[chatController connection] identifier]];
    
	[(WCTabBarItem *)[tabViewItem identifier] setIcon:nil];
}



- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem {
    WCChatController    *chatController;
    NSString            *name;
    NSDictionary        *bookmark;
    NSInteger           toSelectRow;
    
    chatController  = [self selectedChatController];
    
	[self _updateToolbarForConnection:[chatController connection]];
    [self _updateTabViewItemForConnection:[chatController connection]];
    
    chatController  = [self chatControllerForConnectionIdentifier:[[tabViewItem identifier] valueForKey:@"identifier"]];
        
    name            = [[chatController connection] name];
    bookmark        = [[chatController connection] bookmark];
    
    if(bookmark) {
        for(WCServerBookmarkServer *bs in [_bookmarks items]) {
            if([bookmark isEqualToDictionary:[bs bookmark]]) {
                toSelectRow = [_serversOutlineView rowForItem:bs];
                
                if(toSelectRow != -1) {
                    [_serversOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:toSelectRow] byExtendingSelection:NO];
                    return;
                }
            }
        }
    }
    
    for(WCServerBonjourServer *bs in [_bonjour items]) {
        if([name isEqualToString:[bs name]]) {
            toSelectRow = [_serversOutlineView rowForItem:bs];
            
            if(toSelectRow != -1) {
                [_serversOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:toSelectRow] byExtendingSelection:NO];
                return;
            }
        }
    }
}



- (BOOL)tabView:(NSTabView *)tabView shouldCloseTabViewItem:(NSTabViewItem *)tabViewItem {
	WCPublicChatController		*chatController;
    
	chatController = [_chatControllers objectForKey:[[tabViewItem identifier] valueForKey:@"identifier"]];
    
	return [self _beginConfirmDisconnectSheetModalForWindow:[self window]
                                                 connection:[chatController connection]
                                              modalDelegate:self
                                             didEndSelector:@selector(closeTabSheetDidEnd:returnCode:contextInfo:)
                                                contextInfo:[tabViewItem retain]];
}


- (NSMenu *)tabView:(NSTabView *)aTabView menuForTabViewItem:(NSTabViewItem *)tabViewItem {
    WCChatController        *chatController;
    NSMenu                  *menu;
    NSMenuItem              *item;
    
    menu            = [[[NSMenu alloc] init] autorelease];
    chatController  = [_chatControllers objectForKey:[[tabViewItem identifier] valueForKey:@"identifier"]];
    
    if([[chatController connection] isConnected]) {
        if(![[chatController connection] bookmark]) {
            item = [menu addItemWithTitle:NSLS(@"Add Bookmark", @"Sidebar menu item title") action:nil keyEquivalent:@""];
            [item setTarget:self];
            [item setAction:@selector(addBookmark:)];
            
            [menu addItem:[NSMenuItem separatorItem]];
        }
        
        item = [menu addItemWithTitle:NSLS(@"Get Info", @"TabView menu item title") action:nil keyEquivalent:@""];
        [item setTarget:[[chatController connection] serverInfo]];
        [item setAction:@selector(showWindow:)];
        
        [menu addItem:[NSMenuItem separatorItem]];
        
        item = [menu addItemWithTitle:NSLS(@"Disconnect", @"TabView menu item title") action:nil keyEquivalent:@""];
        [item setTarget:[chatController connection]];
        [item setAction:@selector(disconnect)];
    }
    else {
        item = [menu addItemWithTitle:NSLS(@"Reconnect", @"TabView menu item title") action:nil keyEquivalent:@""];
        [item setTarget:[chatController connection]];
        [item setAction:@selector(reconnect)];
    }
    
    return menu;
}


- (void)tabView:(NSTabView *)tabView willCloseTabViewItem:(NSTabViewItem *)tabViewItem {
	[self _removeTabViewItem:tabViewItem];
}


- (void)tabView:(NSTabView *)aTabView tabBarViewDidHide:(MMTabBarView *)tabBarView {
    [[[self window] toolbar] setShowsBaselineSeparator:YES];
}


- (void)tabView:(NSTabView *)aTabView tabBarViewDidUnhide:(MMTabBarView *)tabBarView {
    [[[self window] toolbar] setShowsBaselineSeparator:NO];
}

- (BOOL)tabView:(NSTabView *)aTabView disableTabCloseForTabViewItem:(NSTabViewItem *)tabViewItem {
    return NO;
}

- (void)addNewTabToTabView:(NSTabView *)aTabView {
    [self connect:self];
}





#pragma mark -

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)offset {
	if(splitView == _resourcesSplitView)
		return proposedMin + 170.0;
    
	return proposedMin;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)offset {
	if(splitView == _resourcesSplitView)
		return 250.0;
    
	return proposedMax;
}



- (BOOL)splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)view {
    if(splitView == _resourcesSplitView) {
        if(view == [[_resourcesSplitView subviews] objectAtIndex:1])
            return YES;
        
    }
    return NO;
}



- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview {
    if(splitView == _resourcesSplitView)
        if(subview == [[_resourcesSplitView subviews] objectAtIndex:0])
            return YES;
    
    return NO;
}

- (BOOL)splitView:(NSSplitView *)splitView shouldHideDividerAtIndex:(NSInteger)dividerIndex {
    if(splitView == _resourcesSplitView)
        return YES;
	
    return NO;
}


- (NSRect)splitView:(NSSplitView *)splitView additionalEffectiveRectOfDividerAtIndex:(NSInteger)dividerIndex {
    if(splitView == _resourcesSplitView)
        return [_splitResizeView convertRect:[_splitResizeView bounds] toView:splitView];
    
    return NSZeroRect;
}


- (void)splitViewDidResizeSubviews:(NSNotification *)notification {
    if([[_resourcesSplitView subviews] objectAtIndex:0].isHidden == YES) {
        [[WCSettings settings] setBool:YES forKey:WCHideServerList];
        [_viewsSegmentedControl setSelected:NO forSegment:0];
    }
    else {
        [[WCSettings settings] setBool:NO forKey:WCHideServerList];
        [_viewsSegmentedControl setSelected:YES forSegment:0];
    }
}



#pragma mark -

- (NSRect)window:(NSWindow *)window willPositionSheet:(NSWindow *)sheet
       usingRect:(NSRect)rect {
    
    if(![_tabBarView isTabBarHidden]) {
        rect.size.height = 47;
    }
    return rect;
}


- (void)windowDidBecomeKey:(NSNotification *)notification {
    [_tabBarView update:NO];
}






#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem *)item {
	WCPublicChatController	*chatController;
	WCServerConnection		*connection;
	SEL						selector;
	
	chatController	= [self selectedChatController];
	connection		= [[self selectedChatController] connection];
	selector		= [item action];
	
	if(selector == @selector(disconnect:))
		return (connection != NULL && [connection isConnected]);
    
	else if(selector == @selector(reconnect:))
		return (connection != NULL && ![connection isConnected] && ![connection isManuallyReconnecting]);
    
	else if(selector == @selector(files:))
		return (connection != NULL && [connection isConnected] && [[connection account] fileListFiles]);
    
	else if(selector == @selector(broadcast:))
		return (connection != NULL && [connection isConnected]);
    
	else if(selector == @selector(changePassword:))
		return (connection != NULL && [connection isConnected] && [[connection account] accountChangePassword]);
    
	else if(selector == @selector(serverInfo:) || selector == @selector(administration:) ||
			selector == @selector(console:))
		return (connection != NULL);
    
    else if(selector == @selector(toggleUserList:))
        return [self selectedChatController] ? YES : NO;
    
	else if(selector == @selector(nextConnection:) || selector == @selector(previousConnection:))
		return ([_chatControllers count] > 1);
    
    else if(selector == @selector(editBookmark:))
		return ([[self _selectedItem] isKindOfClass:[WCServerBookmarkServer class]] ||
                [[self _selectedItem] isKindOfClass:[WCServerTracker class]]);
    
    else if(selector == @selector(duplicateBookmark:))
		return ([[self _selectedItem] isKindOfClass:[WCServerBookmarkServer class]] ||
                [[self _selectedItem] isKindOfClass:[WCServerTracker class]]);
    
    else if(selector == @selector(openServer:))
		return ([[self _selectedItem] isKindOfClass:[WCServerBookmarkServer class]] ||
                [[self _selectedItem] isKindOfClass:[WCServerBonjourServer class]] ||
                [[self _selectedItem] isKindOfClass:[WCServerTrackerServer class]]);
	
    else if(selector == @selector(addToBookmarks:))
		return ([[self _selectedItem] isKindOfClass:[WCServerBonjourServer class]] ||
                [[self _selectedItem] isKindOfClass:[WCServerTrackerServer class]]);
    
    else if(selector == @selector(deleteServerOrTrackerBookmark:))
		return ([[self _selectedItem] isKindOfClass:[WCServerBookmarkServer class]] ||
                [[self _selectedItem] isKindOfClass:[WCServerTracker class]]);
    
    else if(selector == @selector(reloadTracker:))
        return ([[self _selectedItem] isKindOfClass:[WCServerTracker class]]);
    
    else if(selector == @selector(getTrackerServerInfo:))
        return ([[self _selectedItem] isKindOfClass:[WCServerTrackerServer class]]);
    
    else if(selector == @selector(connect:))
        return YES;
    
    else if(selector == @selector(addServerBookmark:))
        return YES;
    
    else if(selector == @selector(addTrackerBookmark:))
        return YES;
    
	return [chatController validateMenuItem:item];
}



- (BOOL)validateToolbarItem:(NSToolbarItem *)item {
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    
	WCServerConnection		*connection;
	SEL						selector;
	
	connection		= [[self selectedChatController] connection];
	selector		= [item action];
	
	if(selector == @selector(banner:))
		return (connection != NULL);
	else if(selector == @selector(disconnect:))
		return (connection != NULL && [connection isConnected] && ![connection isDisconnecting]);
	else if(selector == @selector(reconnect:))
		return (connection != NULL && ![connection isConnected] && ![connection isManuallyReconnecting]);
	else if(selector == @selector(files:))
		return (connection != NULL && [connection isConnected] && [[connection account] fileListFiles]);
	else if(selector == @selector(serverInfo:) || selector == @selector(administration:) ||
			selector == @selector(settings:) || selector == @selector(monitor:) ||
			selector == @selector(events:) || selector == @selector(log:) ||
			selector == @selector(accounts:) || selector == @selector(banlist:))
		return (connection != NULL);
    else if(selector == @selector(clear:))
        return ![[self selectedChatController] chatIsEmpty];
	else if(selector == @selector(nowPlaying:))
        return (connection != NULL && [connection isConnected]);
	
    else if(selector == @selector(switchViews:))
        [[_viewsSegmentedControl cell] setEnabled:([self selectedChatController] != nil)];
#pragma clang diagnostic pop
    
	return YES;
}




#pragma mark -

- (NSString *)saveDocumentMenuItemTitle {
	return [[self selectedChatController] saveDocumentMenuItemTitle];
}





#pragma mark -

- (NSInteger)numberOfUnreads {
    NSInteger       result = 0;
    
    for(WCChatController *controller in [self chatControllers]) {
        if([controller connection]) {
            result += [self numberOfUnreadsForConnection:[controller connection]];
        }
    }
    
    return result;
}


- (NSInteger)numberOfUnreadsForConnection:(WCServerConnection *)connection {
    NSInteger result = 0;
    
    if(connection) {
        result += [[WCBoards boards] numberOfUnreadThreadsForConnection:connection];
        result += [[WCMessages messages] numberOfUnreadMessagesForConnection:connection];
    }
    
    return result;
}





#pragma mark -

- (IBAction)saveDocument:(id)sender {
	[self saveChat:sender];
}



- (IBAction)disconnect:(id)sender {
	WCServerConnection		*connection;
	
	connection = [[self selectedChatController] connection];
    
	if([self _beginConfirmDisconnectSheetModalForWindow:[self window]
											 connection:connection
										  modalDelegate:self
										 didEndSelector:@selector(disconnectSheetDidEnd:returnCode:contextInfo:)
											contextInfo:[connection retain]]) {
		[connection disconnect];
		[connection release];
	}
}



- (void)disconnectSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	WCServerConnection		*connection = contextInfo;
	
	if(returnCode == NSAlertFirstButtonReturn)
		[connection disconnect];
	
	[connection release];
}



- (IBAction)reconnect:(id)sender {
	WCServerConnection		*connection;
	
	connection = [[self selectedChatController] connection];
	
	[connection reconnect];
}



- (IBAction)serverInfo:(id)sender {
	WCServerConnection		*connection;
	
	connection = [[self selectedChatController] connection];
	
	[[connection serverInfo] showWindow:self];
}



- (IBAction)files:(id)sender {
	WCServerConnection		*connection;
	
	connection = [[self selectedChatController] connection];
	
	[WCFiles filesWithConnection:connection file:[WCFile fileWithRootDirectoryForConnection:connection]];
}



- (IBAction)administration:(id)sender {
	WCServerConnection		*connection;
	
	connection = [[self selectedChatController] connection];
	
	[[connection administration] showWindow:self];
}



- (IBAction)settings:(id)sender {
	WCServerConnection		*connection;
	
	connection = [[self selectedChatController] connection];
	
	[[connection administration] selectController:[[connection administration] settingsController]];
	[[connection administration] showWindow:self];
}



- (IBAction)monitor:(id)sender {
	WCServerConnection		*connection;
	
	connection = [[self selectedChatController] connection];
	
	[[connection administration] selectController:[[connection administration] monitorController]];
	[[connection administration] showWindow:self];
}



- (IBAction)events:(id)sender {
	WCServerConnection		*connection;
	
	connection = [[self selectedChatController] connection];
	
	[[connection administration] selectController:[[connection administration] eventsController]];
	[[connection administration] showWindow:self];
}



- (IBAction)log:(id)sender {
	WCServerConnection		*connection;
	
	connection = [[self selectedChatController] connection];
	
	[[connection administration] selectController:[[connection administration] logController]];
	[[connection administration] showWindow:self];
}


- (IBAction)clear:(id)sender {
    [[self selectedChatController] clearChat];
}


- (IBAction)nowPlaying:(id)sender {
	[[self selectedChatController] printChatNowPlaying];
}


- (IBAction)chatHistory:(id)sender {
	[[WCChatHistory chatHistory] showWindow:sender];
}


- (IBAction)accounts:(id)sender {
	WCServerConnection		*connection;
	
	connection = [[self selectedChatController] connection];
	
	[[connection administration] selectController:[[connection administration] accountsController]];
	[[connection administration] showWindow:self];
}



- (IBAction)banlist:(id)sender {
	WCServerConnection		*connection;
	
	connection = [[self selectedChatController] connection];
	
	[[connection administration] selectController:[[connection administration] banlistController]];
	[[connection administration] showWindow:self];
}



- (IBAction)console:(id)sender {
	WCServerConnection		*connection;
	
	connection = [[self selectedChatController] connection];
	
	[[connection console] showWindow:self];
}



- (IBAction)getInfo:(id)sender {
	[[self selectedChatController] getInfo:sender];
}



- (IBAction)saveChat:(id)sender {
	[[self selectedChatController] saveChat:sender];
}



- (IBAction)setTopic:(id)sender {
	[[self selectedChatController] setTopic:sender];
}



- (IBAction)broadcast:(id)sender {
	WCServerConnection		*connection;
	
	connection = [[self selectedChatController] connection];
	
	[[WCMessages messages] showBroadcastForConnection:connection];
}



- (IBAction)changePassword:(id)sender {
	[[self selectedChatController] changePassword:sender];
}




#pragma mark -

- (IBAction)switchViews:(id)sender {
    NSInteger selectedSegment   = [_viewsSegmentedControl selectedSegment];
    NSInteger clickedSegmentTag = [[_viewsSegmentedControl cell] tagForSegment:selectedSegment];
    
    if(clickedSegmentTag == 0) {
        [[WCSettings settings] setBool:![_viewsSegmentedControl isSelectedForSegment:clickedSegmentTag] forKey:WCHideServerList];
        
        if([[WCSettings settings] boolForKey:WCHideServerList])
            [self hideServerList:sender];
        else
            [self showServerList:sender];
        
    } else if(clickedSegmentTag == 1) {
        
        [[WCSettings settings] setBool:![_viewsSegmentedControl isSelectedForSegment:clickedSegmentTag] forKey:WCHideUserList];
        
        if([[WCSettings settings] boolForKey:WCHideUserList])
            [self hideUserList:sender];
        else
            [self showUserList:sender];
    }
    
}


- (IBAction)showServerList:(id)sender {
    if ([_resourcesSplitView isSubviewCollapsed:[[_resourcesSplitView subviews] objectAtIndex:0]])
        [_resourcesSplitView setPosition:170.0
                        ofDividerAtIndex:0];
}


- (IBAction)hideServerList:(id)sender {
    if(![_resourcesSplitView isSubviewCollapsed:[[_resourcesSplitView subviews] objectAtIndex:0]])
        [_resourcesSplitView setPosition:0
                        ofDividerAtIndex:0];
}




- (IBAction)toggleServersList:(id)sender {
    if ([_resourcesSplitView isSubviewCollapsed:[[_resourcesSplitView subviews] objectAtIndex:0]]) {
        [_resourcesSplitView setPosition:170.0
                        ofDividerAtIndex:0];
    } else {
        [_resourcesSplitView setPosition:0
                        ofDividerAtIndex:0];
    }
}


- (IBAction)toggleUserList:(id)sender {
    [[self selectedChatController] toggleUserList:sender];
}


- (IBAction)showUserList:(id)sender {
    [[self selectedChatController] showUserList:sender];
}


- (IBAction)hideUserList:(id)sender {
    [[self selectedChatController] hideUserList:sender];
}


- (IBAction)toggleTabBar:(id)sender {
    //    if(![_tabBarControl isHidden])
    //        [_tabBarControl hideTabBar:YES animate:NO];
    //    else
    //        [_tabBarControl hideTabBar:NO animate:NO];
}





#pragma mark -

- (IBAction)connect:(id)sender {
    [[WCConnect connect] showWindow:sender];
}


- (IBAction)addServerBookmark:(id)sender {
    [_serverBookmarkController beginSheetWithParentWindow:[self window]];
}


- (IBAction)addTrackerBookmark:(id)sender {
    [_trackerBookmarkController beginSheetWithParentWindow:[self window]];
}


- (IBAction)editBookmark:(id)sender {
    NSMutableDictionary     *bookmark;
    id                      item;
    
    item = [self _selectedItem];
    
    if(!item)
        return;
    
    if([item class] == [WCServerBookmarkServer class]) {
        bookmark = [[[item valueForKey:@"bookmark"] mutableCopy] autorelease];
        
        [_serverBookmarkController setBookmark:bookmark];
        [_serverBookmarkController beginSheetWithParentWindow:[self window]];
        
    }
    else if([item class] == [WCServerTracker class]) {
        bookmark = [[[item valueForKey:@"bookmark"] mutableCopy] autorelease];
        
        [_trackerBookmarkController setBookmark:bookmark];
        [_trackerBookmarkController beginSheetWithParentWindow:[self window]];
    }
}


- (IBAction)duplicateBookmark:(id)sender {
    NSMutableDictionary		*bookmark;
	NSString				*password;
    id                      item;
    
    item = [self _selectedItem];
    
    if(!item)
        return;
	
    if([item class] == [WCServerBookmarkServer class]) {
        bookmark = [[[item valueForKey:@"bookmark"] mutableCopy] autorelease];
        password = [[WCKeychain keychain] passwordForBookmark:bookmark];
        
        [bookmark setObject:[NSString UUIDString] forKey:WCBookmarksIdentifier];
        
        [[WCKeychain keychain] setPassword:password forBookmark:bookmark];
        
        [[WCSettings settings] addObject:bookmark toArrayForKey:WCBookmarks];
    }
    else if([item class] == [WCServerTracker class]) {
        bookmark = [[[item valueForKey:@"bookmark"] mutableCopy] autorelease];
        password = [[WCKeychain keychain] passwordForTrackerBookmark:bookmark];
        
        [bookmark setObject:[NSString UUIDString] forKey:WCTrackerBookmarksIdentifier];
        
        [[WCKeychain keychain] setPassword:password forTrackerBookmark:bookmark];
        
        [[WCSettings settings] addObject:bookmark toArrayForKey:WCTrackerBookmarks];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:WCBookmarksDidChangeNotification];
}


- (IBAction)deleteServerOrTrackerBookmark:(id)sender {
	id				item;
    NSAlert			*alert;
	NSString		*name;
    
    item = [self _selectedItem];
    
    if(!item)
        return;
    
    if([item class] == [WCServerBookmarkServer class]) {
        name = [[item bookmark] objectForKey:WCBookmarksName];
        
    } else if([item class] == [WCServerTracker class]) {
        name = [[item bookmark] objectForKey:WCTrackerBookmarksName];
    }
	
	alert = [[NSAlert alloc] init];
	[alert setMessageText:[NSSWF:NSLS(@"Are you sure you want to delete \u201c%@\u201d?", @"Delete bookmark dialog title (bookmark)"), name]];
	[alert setInformativeText:NSLS(@"This cannot be undone.", @"Delete bookmark dialog description")];
	[alert addButtonWithTitle:NSLS(@"Delete", @"Delete bookmark dialog button title")];
	[alert addButtonWithTitle:NSLS(@"Cancel", @"Delete bookmark button title")];
	[alert beginSheetModalForWindow:[self window]
					  modalDelegate:self
					 didEndSelector:@selector(deleteServerSheetDidEnd:returnCode:contextInfo:)
						contextInfo:[item retain]];
	[alert release];
}


- (void)deleteServerSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    NSArray			*bookmarks;
	NSString		*identifier;
	id              item;
    NSInteger       index, count, i;
    
    item = contextInfo;
    
	if(returnCode == NSAlertFirstButtonReturn) {
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
        
        [[NSNotificationCenter defaultCenter] postNotificationName:WCBookmarksDidChangeNotification];
        [self _reloadServers];
	}
	
	[item release];
}





#pragma mark -

- (IBAction)openServer:(id)sender {
	id                          item;
	
	if(sender == _serversOutlineView && [_serversOutlineView clickedHeader])
		return;
    
	item = [self _selectedItem];
    
    [self _connectToServer:item];
}


- (IBAction)reloadTracker:(id)sender {
    id						item;
	WCServerTrackerState	state;
	
	item = [self _selectedItem];
	
	if([item isKindOfClass:[WCServerTracker class]]) {
		state = (WCServerTrackerState)[item state];
		
		if(state == WCServerTrackerIdle)
			[_serversOutlineView expandItem:item];
		else
			[self _openTracker:item];
	}
}




- (IBAction)addToBookmarks:(id)sender {
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
		
        [[NSNotificationCenter defaultCenter] postNotificationName:WCBookmarksDidChangeNotification];
		[self _reloadServers];
	}
}



- (IBAction)getTrackerServerInfo:(id)sender {
    id      item;
    
    item    = [self _selectedItem];
    
    [WCTrackerServerInfo trackerServerInfoWithTrackerServer:item];
}






#pragma mark -

- (IBAction)addBookmark:(id)sender {
	WCServerConnection	*connection;
	
	connection	= [[self selectedChatController] connection];
	
    [self _addBookmarkForConnection:connection];
}



#pragma mark -

- (IBAction)nextConnection:(id)sender {
	NSArray				*items;
	NSUInteger			index, newIndex;
	
	items = [_chatTabView tabViewItems];
	index = [items indexOfObject:[_chatTabView selectedTabViewItem]];
	
	if([items count] > 0) {
		if(index == [items count] - 1)
			newIndex = 0;
		else
			newIndex = index + 1;
		
		[_chatTabView selectTabViewItemAtIndex:newIndex];
        
		[[self window] makeFirstResponder:[[self selectedChatController] insertionTextField]];
	}
}



- (IBAction)previousConnection:(id)sender {
	NSArray				*items;
	NSUInteger			index, newIndex;
	
	items = [_chatTabView tabViewItems];
	index = [items indexOfObject:[_chatTabView selectedTabViewItem]];
	
	if([items count] > 0) {
		if(index == 0)
			newIndex = [items count] - 1;
		else
			newIndex = index - 1;
		
		[_chatTabView selectTabViewItemAtIndex:newIndex];
        
		[[self window] makeFirstResponder:[[self selectedChatController] insertionTextField]];
	}
}

- (IBAction)closeTab:(id)sender {
    
    NSTabViewItem            *tabViewItem;
    WCServerConnection        *connection;
    
    tabViewItem        = [_chatTabView selectedTabViewItem];
    connection        = [[self selectedChatController] connection];
    
    if([self _beginConfirmDisconnectSheetModalForWindow:[self window]
                                             connection:connection
                                          modalDelegate:self
                                         didEndSelector:@selector(closeTabSheetDidEnd:returnCode:contextInfo:)
                                            contextInfo:[tabViewItem retain]]) {
        
        [self _removeTabViewItem:tabViewItem];
        
        [_chatTabView removeTabViewItem:tabViewItem];
        
        [tabViewItem release];
    }
}

- (void)closeTabSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	NSTabViewItem		*tabViewItem = contextInfo;
	
	if(returnCode == NSAlertFirstButtonReturn) {
		
        [self _removeTabViewItem:tabViewItem];
        [_chatTabView removeTabViewItem:tabViewItem];
	}
	
	[tabViewItem release];
}



#pragma mark -

- (NSTextField *)insertionTextField {
	return [[self selectedChatController] insertionTextField];
}




#pragma mark -

- (void)saveAllChatControllerHistory {
	for(NSString *identifier in [_chatControllers allKeys]) {
        WIChatHistoryBundle     *bundle;
		WCChatController        *chatController;
		WCUser                  *user;
		
		chatController	= [_chatControllers objectForKey:identifier];
		user			= [chatController userWithUserID:[[chatController connection] userID]];
		
		if([[WCSettings settings] boolForKey:WCChatLogsHistoryEnabled] && ![chatController chatIsEmpty]) {
            bundle      = [[[WCApplicationController sharedController] logController] publicChatHistoryBundle];
            
            [bundle addHistoryForWebView:[chatController webView]
                      withConnectionName:[[chatController connection] name]
                                identity:[user nick]];
        }
	}
}





#pragma mark -

- (void)addChatController:(WCPublicChatController *)chatController {
	NSTabViewItem		*tabViewItem;
    WCTabBarItem        *newModelItem;
	NSString			*identifier;
	
	identifier = [[chatController connection] identifier];
	
	if([_chatControllers objectForKey:identifier] != NULL)
		return;
	
	[[chatController connection] setIdentifier:identifier];
	
	[_chatControllers setObject:chatController forKey:identifier];
	
	if([_chatControllers count] == 1)
		[_noConnectionTextField setHidden:YES];
	
    newModelItem = [[WCTabBarItem alloc] init];
    [newModelItem setTitle:[[chatController connection] name]];
	[newModelItem setIdentifier:identifier];
    
	tabViewItem = [[[NSTabViewItem alloc] initWithIdentifier:newModelItem] autorelease];
	
	[tabViewItem setView:[chatController view]];
	[_chatTabView addTabViewItem:tabViewItem];
	[_chatTabView selectTabViewItem:tabViewItem];
    
	[chatController awakeInWindow:[self window]];
	[chatController loadWindowProperties];
}



- (void)selectChatController:(WCPublicChatController *)chatController {
    [self selectChatController:chatController firstResponder:YES];
}

- (void)selectChatController:(WCPublicChatController *)chatController firstResponder:(BOOL)firstResponder {
    
    for(NSTabViewItem *item in [_chatTabView tabViewItems]) {
        if([[[item identifier] valueForKey:@"identifier"] isEqualToString:[[chatController connection] identifier]])
            [_chatTabView selectTabViewItem:item];
    }
    
    if([[WCSettings settings] boolForKey:WCHideUserList])
        [[self selectedChatController] hideUserList:self];
    else
        [[self selectedChatController] showUserList:self];
    
    if(firstResponder)
        [[self window] makeFirstResponder:[[self selectedChatController] insertionTextField]];
}




- (WCPublicChatController *)selectedChatController {
	NSString			*identifier;
	
	identifier = [[[_chatTabView selectedTabViewItem] identifier] valueForKey:@"identifier"];
	
	return [_chatControllers objectForKey:identifier];
}



- (WCPublicChatController *)chatControllerForConnectionIdentifier:(NSString *)identifier {
	return [_chatControllers objectForKey:identifier];
}


- (WCPublicChatController *)chatControllerForBookmarkIdentifier:(NSString *)identifier {
    WCPublicChatController *result = nil;
    NSArray *chatControllers = [self chatControllers];
    
    for(WCPublicChatController *cc in chatControllers)
        if([[[[cc connection] bookmark] objectForKey:WCBookmarksIdentifier] isEqualToString:identifier])
            result = cc;
    
    return result;
}


- (WCPublicChatController *)chatControllerForURL:(WIURL *)url {
    WCPublicChatController *result = nil;
    NSArray *chatControllers = [self chatControllers];
    
    for(WCPublicChatController *cc in chatControllers)
        if([[[[cc connection] URL] string] isEqualToString:[url string]])
            result = cc;
    
    return result;
}


- (NSArray *)chatControllers {
	return [_chatControllers allValues];
}






#pragma mark -

- (void)bookmarksDidChange:(NSNotification *)notification {
    [[WCSettings settings] synchronize];
	[self _reloadServers];
}



- (void)trackerBookmarksDidChange:(NSNotification *)notification {
    [[WCSettings settings] synchronize];
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
	
	tracker = [(id)[message contextInfo] tracker];
	
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
        
		[(WCServerConnection *)[message contextInfo] terminate];
		
		[self _sortServers];
		
		[_serversOutlineView reloadData];
		
		//[self _updateStatus];
	}
	else if([[message name] isEqualToString:@"wired.error"]) {
		[(WCServerConnection *)[message contextInfo] terminate];
        
		[_errorQueue showError:[WCError errorWithWiredMessage:message]];
	}
}







#pragma mark -

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
	if(!item)
		item = _servers;
    
	if([item isKindOfClass:[WCServerContainer class]])
		return [[item items] count];
	
	return 0;
}



- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
	if(!item)
		item = _servers;
    
	if([item isKindOfClass:[WCServerContainer class]]) {
		return [[item items] objectAtIndex:index];
	}
	
	return NULL;
}


- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    if([[tableColumn identifier] isEqualToString:@"name"])
        return [item name];
    
    else if([[tableColumn identifier] isEqualToString:@"badge"]) {
        WCPublicChatController  *chatController = nil;
        
        if([item isKindOfClass:[WCServerBookmarkServer class]]) {
            chatController = [self chatControllerForBookmarkIdentifier:[[item bookmark] objectForKey:WCBookmarksIdentifier]];
            
        }
        
        if(chatController)
            return [NSImage imageWithPillForCount:[self numberOfUnreadsForConnection:[chatController connection]]
                                   inActiveWindow:([NSApp keyWindow] == [self window])
                                    onSelectedRow:([_serversOutlineView rowForItem:item] == [_serversOutlineView selectedRow])];
        
    }
    
    return nil;
}


- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    WCPublicChatController  *chatController = nil;
    
    if(![item isKindOfClass:[WCServerContainer class]] || [item isKindOfClass:[WCServerTracker class]]) {
        if([item isKindOfClass:[WCServerBookmarkServer class]]) {
            chatController = [self chatControllerForBookmarkIdentifier:[[item bookmark] objectForKey:WCBookmarksIdentifier]];
            
            if(chatController) {
                if([[tableColumn identifier] isEqualToString:@"name"]) {
                    if([[chatController connection] isConnected]) {
                        [cell setImage:[NSImage imageNamed:@"BookmarksSmallConnected"]];
                    } else {
                        [cell setImage:[NSImage imageNamed:@"BookmarksSmallDisconnected"]];
                    }
                } else if([[tableColumn identifier] isEqualToString:@"badge"]) {
                    if([self numberOfUnreadsForConnection:[chatController connection]] > 0)
                        [cell setFont:[[cell font] fontByAddingTrait:NSBoldFontMask]];
                    else
                        [cell setFont:[[cell font] fontByAddingTrait:NSUnboldFontMask]];
                }
            } else
                if([[tableColumn identifier] isEqualToString:@"name"])
                    [cell setImage:[NSImage imageNamed:@"BookmarksSmall"]];
            
            
        } else if([item isKindOfClass:[WCServerBonjourServer class]]) {
            chatController = [self chatControllerForURL:(WIURL *)[item URL]];
            
            if(chatController) {
                if([[tableColumn identifier] isEqualToString:@"name"]) {
                    if([[chatController connection] isConnected]) {
                        [cell setImage:[NSImage imageNamed:@"BonjourConnected"]];
                    } else {
                        [cell setImage:[NSImage imageNamed:@"BonjourDisconnected"]];
                    }
                    
                } else if([[tableColumn identifier] isEqualToString:@"badge"]) {
                    if([self numberOfUnreadsForConnection:[chatController connection]] > 0)
                        [cell setFont:[[cell font] fontByAddingTrait:NSBoldFontMask]];
                    else
                        [cell setFont:[[cell font] fontByAddingTrait:NSUnboldFontMask]];
                }
                
            } else
                if([[tableColumn identifier] isEqualToString:@"name"])
                    [cell setImage:[NSImage imageNamed:@"Bonjour"]];
            
        } else if([item isKindOfClass:[WCServerTracker class]]) {
            if([[tableColumn identifier] isEqualToString:@"name"]) {
                NSImage *image = [NSImage imageNamed:@"WiredServer"];
                
                // works slow..
                [image setSize:NSMakeSize(16, 16)];
                [cell setImage:image];
            }
            
        }
    }  else {
        // force no-image for group items
        if([[tableColumn identifier] isEqualToString:@"name"])
            [cell setImage:nil];
    }
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
    WCPublicChatController      *chatController;
    id                          item;
    
	item = [self _selectedItem];
    
    if(!item)
        return;
    
    if([item isKindOfClass:[WCServerBookmarkServer class]]) {
        chatController   = [self chatControllerForBookmarkIdentifier:[[item bookmark] objectForKey:WCBookmarksIdentifier]];
        if(chatController) [self selectChatController:chatController firstResponder:NO];
        
    } else if(![item isKindOfClass:[WCServerContainer class]]) {
        chatController   = [self chatControllerForURL:(WIURL *)[item URL]];
        if(chatController) [self selectChatController:chatController firstResponder:NO];
        
    }
}


- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
	return ([item isKindOfClass:[WCServerContainer class]] && [item isExpandable]);
}


- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item {
    return ([item isKindOfClass:[WCServerContainer class]] && ![item isKindOfClass:[WCServerTracker class]]);
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item {
    return (![item isKindOfClass:[WCServerContainer class]] || [item isKindOfClass:[WCServerTracker class]]);
}


- (void)outlineViewItemDidExpand:(NSNotification *)notification {
	id		item;
	
	item = [[notification userInfo] objectForKey:@"NSObject"];
	
	if([item isKindOfClass:[WCServerTracker class]] && [item state] == WCServerTrackerIdle)
		[self _openTracker:item];
}


- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pasteboard {
    int             row;
    id              item;
    
    if([items count] < 1)
        return NO;
    
    item        = [items objectAtIndex:0];
    row         = [outlineView rowForItem:item];
    
    if(row != -1) {
        if([item isKindOfClass:[WCServerBookmarkServer class]]) {
            row         = [[_bookmarks items] indexOfObject:item];
            
            if([pasteboard setString:[NSSWF:@"%d", row] forType:WCBookmarkPboardType])
                return YES;
            
        } else if([item isKindOfClass:[WCServerTracker class]] && ![item isKindOfClass:[WCServerTrackerServer class]]) {
            row         = [[_trackers items] indexOfObject:item];
            
            if([pasteboard setString:[NSSWF:@"%d", row] forType:WCTrackerBookmarkPboardType])
                return YES;
        }
    }
    
    return NO;
}


- (NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id<NSDraggingInfo>)info proposedItem:(id)proposedItem proposedChildIndex:(NSInteger)index {
    
    NSPasteboard        *pasteboard;
    NSArray             *types;
    int                 row;
    
    pasteboard  = [info draggingPasteboard];
    types       = [pasteboard types];
    
    if(index < 0)
        return NSDragOperationNone;
    
    if([types containsObject:WCBookmarkPboardType]) {
        row     = [[pasteboard stringForType:WCBookmarkPboardType] integerValue];
        
        if(proposedItem == _bookmarks)
            return NSDragOperationMove;
        
    } else if ([types containsObject:WCTrackerBookmarkPboardType]) {
        row     = [[pasteboard stringForType:WCTrackerBookmarkPboardType] integerValue];
        
        if(proposedItem == _trackers)
            return NSDragOperationMove;
    }
    
    return NSDragOperationNone;
}


- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id<NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)row {
    
	NSMutableArray		*array;
	NSPasteboard		*pasteboard;
	NSArray				*types;
	NSUInteger			index, bookmarkIndex;
	
	pasteboard      = [info draggingPasteboard];
	types           = [pasteboard types];
    
	if([types containsObject:WCBookmarkPboardType]) {
        bookmarkIndex   = [[pasteboard stringForType:WCBookmarkPboardType] integerValue];
        array           = [[[[WCSettings settings] objectForKey:WCBookmarks] mutableCopy] autorelease];
        index           = [array moveObjectAtIndex:bookmarkIndex toIndex:row];
        
        [[WCSettings settings] setObject:array forKey:WCBookmarks];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:WCBookmarksDidChangeNotification];
        
        return YES;
        
    } else if([types containsObject:WCTrackerBookmarkPboardType]) {
        bookmarkIndex   = [[pasteboard stringForType:WCTrackerBookmarkPboardType] integerValue];
        array           = [[[[WCSettings settings] objectForKey:WCTrackerBookmarks] mutableCopy] autorelease];
        index           = [array moveObjectAtIndex:bookmarkIndex toIndex:row];
        
        [[WCSettings settings] setObject:array forKey:WCTrackerBookmarks];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:WCTrackerBookmarksDidChangeNotification];
        
        return YES;
        
	}
    
    
    return NO;
}




#pragma mark -

- (void)menuNeedsUpdate:(NSMenu *)menu {
    WCPublicChatController      *chatController = nil;
    id                          item;
    
    if(menu == _serversOutlineMenu) {
        [menu removeAllItems];
        
        item = [self _selectedItem];
        
        if(!item || [item isMemberOfClass:[WCServerContainer class]])
            return;
        
        if([item isKindOfClass:[WCServerBonjourServer class]]) {
            [menu addItemWithTitle:NSLS(@"Connect", @"Sidebar menu item title") action:@selector(openServer:) keyEquivalent:@""];
            [menu addItem:[NSMenuItem separatorItem]];
            [menu addItemWithTitle:NSLS(@"Add Bookmark", @"Sidebar menu item title") action:@selector(addToBookmarks:) keyEquivalent:@""];
        }
        else if([item isKindOfClass:[WCServerBookmarkServer class]]) {
            chatController = [self chatControllerForBookmarkIdentifier:[[item bookmark] objectForKey:WCBookmarksIdentifier]];
            
            if(chatController) {
                if([[chatController connection] isConnected]) {
                    [menu addItemWithTitle:NSLS(@"Disconnect", @"Sidebar menu item title") action:@selector(disconnect:) keyEquivalent:@""];
                }
                else {
                    [menu addItemWithTitle:NSLS(@"Reconnect", @"Sidebar menu item title") action:@selector(reconnect:) keyEquivalent:@""];
                }
            }
            else {
                [menu addItemWithTitle:NSLS(@"Connect", @"Sidebar menu item title") action:@selector(openServer:) keyEquivalent:@""];
            }
            
            [menu addItem:[NSMenuItem separatorItem]];
            [menu addItemWithTitle:NSLS(@"Edit", @"Sidebar menu item title") action:@selector(editBookmark:) keyEquivalent:@""];
            [menu addItemWithTitle:NSLS(@"Duplicate", @"Sidebar menu item title") action:@selector(duplicateBookmark:) keyEquivalent:@""];
            [menu addItem:[NSMenuItem separatorItem]];
            [menu addItemWithTitle:NSLS(@"Delete", @"Sidebar menu item title") action:@selector(deleteServerOrTrackerBookmark:) keyEquivalent:@""];
        }
        else if([item isKindOfClass:[WCServerTrackerServer class]]) {
            [menu addItemWithTitle:NSLS(@"Connect", @"Sidebar menu item title") action:@selector(openServer:) keyEquivalent:@""];
            [menu addItemWithTitle:NSLS(@"Get Info", @"Sidebar menu item title") action:@selector(getTrackerServerInfo:) keyEquivalent:@""];
            
            if([item isTracker]) {
                [menu addItem:[NSMenuItem separatorItem]];
                [menu addItemWithTitle:NSLS(@"Reload", @"Sidebar menu item title") action:@selector(reloadTracker:) keyEquivalent:@""];
            }
            
            [menu addItem:[NSMenuItem separatorItem]];
            [menu addItemWithTitle:NSLS(@"Add Bookmark", @"Sidebar menu item title") action:@selector(addToBookmarks:) keyEquivalent:@""];
        }
        else if([item isKindOfClass:[WCServerTracker class]]) {
            [menu addItemWithTitle:NSLS(@"Reload", @"Sidebar menu item title") action:@selector(reloadTracker:) keyEquivalent:@""];
            [menu addItem:[NSMenuItem separatorItem]];
            [menu addItemWithTitle:NSLS(@"Edit", @"Sidebar menu item title") action:@selector(editBookmark:) keyEquivalent:@""];
            [menu addItemWithTitle:NSLS(@"Duplicate", @"Sidebar menu item title") action:@selector(duplicateBookmark:) keyEquivalent:@""];
            [menu addItem:[NSMenuItem separatorItem]];
            [menu addItemWithTitle:NSLS(@"Delete", @"Sidebar menu item title") action:@selector(deleteServerOrTrackerBookmark:) keyEquivalent:@""];
        }
    }
}




#pragma mark -

- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didFindService:(NSNetService *)netService moreComing:(BOOL)moreComing {
	[netService setDelegate:self];
	[netService resolveWithTimeout:5.0];
    
	[_bonjour addItem:[WCServerBonjourServer itemWithNetService:netService]];
    
	if(!moreComing) {
		[_serversOutlineView reloadData];
		
		//[self _updateStatus];
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
		
		//[self _updateStatus];
	}
}



- (void)netServiceDidResolveAddress:(NSNetService *)netService {
	[netService stop];
}



@end


