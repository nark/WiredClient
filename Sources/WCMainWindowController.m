//
//  WCMainWindowController.m
//  WiredClient
//
//  Created by Rafaël Warnault on 23/02/13.
//
//

#import "WCMainWindowController.h"
#import "WCApplicationController.h"
#import "WCServerController.h"
#import "WCPublicChatController.h"
#import "WCPreferences.h"
#import "WCServerItem.h"
#import "WCConnect.h"
#import "WCUser.h"


@interface WCMainWindowController (Private)

- (void)        _removeTabViewItem:(NSTabViewItem *)tabViewItem;
- (void)        _reloadResources;

- (id)          _selectedItem;
- (void)        _selectViewWithToolbarIdentifier:(NSString *)indentifier;

- (void)        _connectToServer:(id)item;

@end






@implementation WCMainWindowController (Private)

#pragma mark -

- (void)_removeTabViewItem:(NSTabViewItem *)tabViewItem {
	NSString				*identifier;
    WIChatHistoryBundle     *historyBundle;
	WCServerController      *serverController;
    WCPublicChatController  *chatController;
	WCUser					*user;
	
	identifier              = [tabViewItem identifier];
	serverController        = [_serverControllers objectForKey:identifier];
    chatController          = [serverController chatController];
    historyBundle           = [[[WCApplicationController sharedController] logController] publicChatHistoryBundle];
	user                    = [chatController userWithUserID:[[chatController connection] userID]];
	
	if([[WCSettings settings] boolForKey:WCChatLogsHistoryEnabled] &&
       ![chatController chatIsEmpty]) {
		[historyBundle addHistoryForWebView:[chatController webView]
                         withConnectionName:[[chatController connection] name]
                                   identity:[user nick]];
    }
		
	[[serverController connection] terminate];
	[_serverControllers removeObjectForKey:identifier];
	
	if([_serverControllers count] == 0) {
		//[self _updateToolbarForConnection:NULL];
		
		//[_noConnectionTextField setHidden:NO];
	}
}





#pragma mark -

- (void)_reloadResources {
	NSEnumerator		*enumerator;
	NSDictionary		*bookmark;
	
    [self.progressIndicator startAnimation:self];
    
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
		
	[self.resourcesOutlineView reloadData];
    [self.progressIndicator stopAnimation:self];
}



- (id)_selectedItem {
	NSInteger		row;
    
    row = [self.resourcesOutlineView clickedRow];
	
	if(row >= 0)
        return [self.resourcesOutlineView itemAtRow:row];
	
	row = [self.resourcesOutlineView selectedRow];
	
	if(row >= 0)
        return [self.resourcesOutlineView itemAtRow:row];
    
    row = [[self.resourcesOutlineView selectedRowIndexes] firstIndex];
	
    if(row >= 0)
        return [self.resourcesOutlineView itemAtRow:row];
    
	return nil;
}


- (void)_selectViewWithToolbarIdentifier:(NSString *)indentifier {
    WCServerController      *serverContoller;
    NSTabViewItem           *tabViewItem;
    NSView                  *view;
    
    
    serverContoller         = [self selectedServerController];
    tabViewItem             = [self.tabView selectedTabViewItem];
    view                    = [serverContoller viewForIdentifier:indentifier];
    
    [tabViewItem setView:view];
}






#pragma mark -

- (void)_connectToServer:(id)item {
    WIURL                       *url;
    WCServerController          *serverController;
    NSDictionary                *bookmark;
	WCConnect                   *connect;
	WCError                     *error;
    
    bookmark = NULL;
    serverController = nil;
	
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
            serverController = [self serverControllerForBookmarkIdentifier:[[item bookmark] objectForKey:WCBookmarksIdentifier]];
        } else {
            serverController = [self serverControllerForURL:url];
        }
        
        if(serverController == nil) {
            
            connect = [WCConnect connectWithURL:url bookmark:bookmark];
            [connect showWindow:self];
            
            [self.progressIndicator startAnimation:self];
            
            if(![[NSApp currentEvent] alternateKeyModifier])
                [connect connect:self];
            
            [self.progressIndicator stopAnimation:self];
            
        } else {
            [self selectServerController:serverController];
        }
	}
}


@end






@implementation WCMainWindowController

#pragma mark - Singleton

static WCMainWindowController *_mainWindow;

+ (id)mainWindow {
    if(!_mainWindow) {
        _mainWindow = [[WCMainWindowController alloc] init];
    }
    return _mainWindow;
}




#pragma mark - Accessors

@synthesize resourcesOutlineView;
@synthesize mainSplitView;
@synthesize mainSplitViewImageView;
@synthesize progressIndicator;
@synthesize tabBarView;
@synthesize tabView;





#pragma mark - Lifecycle

- (id)init {
    self = [super initWithWindowNibName:@"MainWindow"];
    if (self) {
        _serverControllers  = [[NSMutableDictionary alloc] init];
        
        _bonjour            = [[WCServerBonjour bonjourItem] retain];
        _bookmarks          = [[WCServerBookmarks bookmarksItem] retain];
        
        _servers            = [[WCServerContainer alloc] initWithName:@"<root>"];
        _trackers           = [[WCServerContainer alloc] initWithName:@"TRACKERS"];
        
        _browser            = [[NSNetServiceBrowser alloc] init];
        
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
    }
    return self;
}


- (void)dealloc
{
    [_serverControllers release];
    
    [_servers release];
    [_trackers release];
    [_bonjour release];
    [_bookmarks release];
    
    [_browser release];
    
    [super dealloc];
}




#pragma mark - Window Controller

- (void)windowDidLoad {
    // toolbar setup
    [[[self window] toolbar] setSelectedItemIdentifier:@"Chat"];
    
    // tab view setup
    [self.tabBarView setStyleNamed:@"Safari"];
    [self.tabBarView setDisableTabClose:NO];
    [self.tabBarView setCanCloseOnlyTab:YES];
    [self.tabBarView setOnlyShowCloseOnHover:NO];
    [self.tabBarView setAllowsBackgroundTabClosing:YES];
    [self.tabBarView setShowAddTabButton:YES];
    [self.tabBarView setAllowsScrubbing:YES];
    [self.tabBarView setHideForSingleTab:YES];
    [self.tabBarView setAutomaticallyAnimates:YES];
    
    // outline view setup
    [self.resourcesOutlineView setTarget:self];
	[self.resourcesOutlineView setDoubleAction:@selector(connect:)];
    
    [self _reloadResources];
    
    [self.resourcesOutlineView expandItem:_bonjour];
	[self.resourcesOutlineView expandItem:_bookmarks];
    [self.resourcesOutlineView expandItem:_trackers];
    
    [super windowDidLoad];
}





#pragma mark -

- (IBAction)connect:(id)sender {
    id                          item;
	
	if(sender == self.resourcesOutlineView && [self.resourcesOutlineView clickedHeader])
		return;
    
	item = [self _selectedItem];
    
    [self _connectToServer:item];
}



- (IBAction)selectView:(id)sender {
    [self _selectViewWithToolbarIdentifier:[sender itemIdentifier]];
}





#pragma mark -

- (NSInteger)numberOfUnreadsForConnection:(WCServerConnection *)connection {
    NSInteger result = 0;
    
    if(connection) {
        //result += [[WCBoards boards] numberOfUnreadThreadsForConnection:connection];
        //result += [[WCMessages messages] numberOfUnreadMessagesForConnection:connection];
    }
    
    return result;
}



- (WCBoardsViewController *)boardsViewControllerWithConnection:(WCServerConnection *)connection {
    WCServerController *serverController;
    
    serverController = [self serverControllerForConnectionIdentifier:[connection identifier]];
    
    return [serverController boardsController];
}





#pragma mark - Notifications

- (void)bookmarksDidChange:(NSNotification *)notification {
	[self _reloadResources];
}



- (void)trackerBookmarksDidChange:(NSNotification *)notification {
	[self _reloadResources];
}





#pragma mark -

- (void)addServerController:(WCServerController *)serverController {
    NSTabViewItem		*tabViewItem;
	NSString			*identifier;
	
	identifier = [[serverController connection] identifier];
    	
	if([_serverControllers objectForKey:identifier] != NULL)
		return;
	
	[[serverController connection] setIdentifier:identifier];
	
	[_serverControllers setObject:serverController forKey:identifier];
    	
	tabViewItem = [[[NSTabViewItem alloc] initWithIdentifier:identifier] autorelease];
	[tabViewItem setLabel:[[serverController connection] name]];
    
	[tabViewItem setView:[serverController viewForIdentifier:[[[self window] toolbar] selectedItemIdentifier]]];
	
	[self.tabView addTabViewItem:tabViewItem];
	[self.tabView selectTabViewItem:tabViewItem];
	
	[[serverController chatController] awakeInWindow:[self window]];
	[[serverController chatController] loadWindowProperties];
}


- (void)selectServerController:(WCServerController *)serverController {
    [self selectServerController:serverController firstResponder:YES];
}


- (void)selectServerController:(WCServerController *)serverController firstResponder:(BOOL)firstResponder {
    NSTabViewItem *selectedItem;
    
    [self.tabView selectTabViewItemWithIdentifier:[[serverController connection] identifier]];
    
    // set the subview (chat, boards, message, etc.) here...
    selectedItem = [self.tabView selectedTabViewItem];
	[selectedItem setView:[serverController viewForIdentifier:[[[self window] toolbar] selectedItemIdentifier]]];
    
    if([[WCSettings settings] boolForKey:WCHideUserList])
        [[[self selectedServerController] chatController] hideUserList:self];
    else
        [[[self selectedServerController] chatController] showUserList:self];
    
    if(firstResponder)
        [[self window] makeFirstResponder:[[[self selectedServerController] chatController] insertionTextView]];
}


- (WCServerController *)selectedServerController {
	NSString			*identifier;
	
	identifier = [[self.tabView selectedTabViewItem] identifier];
    
	return [_serverControllers objectForKey:identifier];
}


- (WCServerController *)serverControllerForConnectionIdentifier:(NSString *)identifier {
    return [_serverControllers objectForKey:identifier]; 
}


- (WCServerController *)serverControllerForBookmarkIdentifier:(NSString *)identifier {
    WCServerController *result = nil;
    NSArray *serverControllers = [self serverControllers];
    
    for(WCServerController *sc in serverControllers)
        if([[[[sc connection] bookmark] objectForKey:WCBookmarksIdentifier] isEqualToString:identifier])
            result = sc;
    
    return result;
}


- (WCServerController *)serverControllerForURL:(WIURL *)url {
    WCServerController *result = nil;
    NSArray *serverControllers = [self serverControllers];
    
    for(WCServerController *sc in serverControllers)
        if([[[[sc connection] URL] string] isEqualToString:[url string]])
            result = sc;
    
    return result;
}


- (NSArray *)serverControllers {
    return [_serverControllers allValues];
}





#pragma mark -







#pragma mark - Split View

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex {
    if(splitView == self.mainSplitView) {
        if(dividerIndex == 0) {
            return 150.0f;
        }
    }
    
    return proposedMinimumPosition;
}


- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMaximumPosition ofSubviewAt:(NSInteger)dividerIndex{
    if(splitView == self.mainSplitView) {
        if(dividerIndex == 0) {
            return 250.0f;
        }
    }
    
    return proposedMaximumPosition;
}


- (BOOL)splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)view {
    if(splitView == self.mainSplitView) {
        if(view == [[splitView subviews] objectAtIndex:0]) {
            return NO;
        }
    }
    
    return YES;
}


- (NSRect)splitView:(NSSplitView *)splitView additionalEffectiveRectOfDividerAtIndex:(NSInteger)dividerIndex {
    if(splitView == self.mainSplitView) {
        return [self.mainSplitViewImageView convertRect:[self.mainSplitViewImageView bounds] toView:splitView];
    }
    return NSZeroRect;
}





#pragma mark - Outline View

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
    
//    else if([[tableColumn identifier] isEqualToString:@"badge"]) {
//        WCPublicChatController  *chatController = nil;
//        
//        if([item isKindOfClass:[WCServerBookmarkServer class]]) {
//            chatController = [self chatControllerForBookmarkIdentifier:[[item bookmark] objectForKey:WCBookmarksIdentifier]];
//            
//        }
//        
//        if(chatController)
//            return [NSImage imageWithPillForCount:[self numberOfUnreadsForConnection:[chatController connection]]
//                                   inActiveWindow:([NSApp keyWindow] == [self window])
//                                    onSelectedRow:([_serversOutlineView rowForItem:item] == [_serversOutlineView selectedRow])];
//        
//    }
    
    return nil;
}


- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    WCServerController  *serverController = nil;
    
    if(![item isKindOfClass:[WCServerContainer class]] || [item isKindOfClass:[WCServerTracker class]]) {
        if([item isKindOfClass:[WCServerBookmarkServer class]]) {
            serverController = [self serverControllerForBookmarkIdentifier:[[item bookmark] objectForKey:WCBookmarksIdentifier]];
            
            if(serverController) {
                if([[tableColumn identifier] isEqualToString:@"name"]) {
                    [cell setImage:[NSImage imageNamed:@"BookmarksSmallConnected"]];
                    
                } else if([[tableColumn identifier] isEqualToString:@"badge"]) {
                    if([self numberOfUnreadsForConnection:[serverController connection]] > 0)
                        [cell setFont:[[cell font] fontByAddingTrait:NSBoldFontMask]];
                    else
                        [cell setFont:[[cell font] fontByAddingTrait:NSUnboldFontMask]];
                }
            } else
                if([[tableColumn identifier] isEqualToString:@"name"])
                    [cell setImage:[NSImage imageNamed:@"BookmarksSmall"]];
            
            
        } else if([item isKindOfClass:[WCServerBonjourServer class]]) {
            serverController = [self serverControllerForURL:[item URL]];
            
            if(serverController) {
                if([[tableColumn identifier] isEqualToString:@"name"]) {
                    [cell setImage:[NSImage imageNamed:@"BonjourConnected"]];
                    
                } else if([[tableColumn identifier] isEqualToString:@"badge"]) {
                    if([self numberOfUnreadsForConnection:[serverController connection]] > 0)
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
    id		item;
    
	item = [self _selectedItem];
    
    if(!item)
        return;
    
    if([item isKindOfClass:[WCServerBookmarkServer class]]) {
        WCServerController *serverController = [self serverControllerForBookmarkIdentifier:[[item bookmark] objectForKey:WCBookmarksIdentifier]];
        if(serverController) [self selectServerController:serverController firstResponder:NO];
        
    } else {
        WCServerController *serverController = [self serverControllerForURL:[item URL]];
        if(serverController) [self selectServerController:serverController firstResponder:NO];
        
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
//	id		item;
//	
//	item = [[notification userInfo] objectForKey:@"NSObject"];
//	
//	if([item isKindOfClass:[WCServerTracker class]] && [item state] == WCServerTrackerIdle)
//		[self _openTracker:item];
}


//- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pasteboard {
//    int             row;
//    id              item;
//    
//    if([items count] < 1)
//        return NO;
//    
//    item        = [items objectAtIndex:0];
//    row         = [outlineView rowForItem:item];
//    
//    if(row != -1) {
//        if([item isKindOfClass:[WCServerBookmarkServer class]]) {
//            row         = [[_bookmarks items] indexOfObject:item];
//            
//            if([pasteboard setString:[NSSWF:@"%d", row] forType:WCBookmarkPboardType])
//                return YES;
//            
//        } else if([item isKindOfClass:[WCServerTracker class]] && ![item isKindOfClass:[WCServerTrackerServer class]]) {
//            row         = [[_trackers items] indexOfObject:item];
//            
//            if([pasteboard setString:[NSSWF:@"%d", row] forType:WCTrackerBookmarkPboardType])
//                return YES;
//        }
//    }
//    
//    return NO;
//}
//
//
//- (NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id<NSDraggingInfo>)info proposedItem:(id)proposedItem proposedChildIndex:(NSInteger)index {
//    
//    NSPasteboard        *pasteboard;
//    NSArray             *types;
//    int                 row;
//    
//    pasteboard  = [info draggingPasteboard];
//    types       = [pasteboard types];
//    
//    if(index < 0)
//        return NSDragOperationNone;
//    
//    if([types containsObject:WCBookmarkPboardType]) {
//        row     = [[pasteboard stringForType:WCBookmarkPboardType] integerValue];
//        
//        if(proposedItem == _bookmarks)
//            return NSDragOperationMove;
//        
//    } else if ([types containsObject:WCTrackerBookmarkPboardType]) {
//        row     = [[pasteboard stringForType:WCTrackerBookmarkPboardType] integerValue];
//        
//        if(proposedItem == _trackers)
//            return NSDragOperationMove;
//    }
//    
//    return NSDragOperationNone;
//}
//
//
//- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id<NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)row {
//    
//	NSMutableArray		*array;
//	NSPasteboard		*pasteboard;
//	NSArray				*types;
//	NSUInteger			index, bookmarkIndex;
//	
//	pasteboard      = [info draggingPasteboard];
//	types           = [pasteboard types];
//    
//	if([types containsObject:WCBookmarkPboardType]) {
//        bookmarkIndex   = [[pasteboard stringForType:WCBookmarkPboardType] integerValue];
//        array           = [[[[WCSettings settings] objectForKey:WCBookmarks] mutableCopy] autorelease];
//        index           = [array moveObjectAtIndex:bookmarkIndex toIndex:row];
//        
//        [[WCSettings settings] setObject:array forKey:WCBookmarks];
//        
//        [[NSNotificationCenter defaultCenter] postNotificationName:WCBookmarksDidChangeNotification];
//        
//        return YES;
//        
//    } else if([types containsObject:WCTrackerBookmarkPboardType]) {
//        bookmarkIndex   = [[pasteboard stringForType:WCTrackerBookmarkPboardType] integerValue];
//        array           = [[[[WCSettings settings] objectForKey:WCTrackerBookmarks] mutableCopy] autorelease];
//        index           = [array moveObjectAtIndex:bookmarkIndex toIndex:row];
//        
//        [[WCSettings settings] setObject:array forKey:WCTrackerBookmarks];
//        
//        [[NSNotificationCenter defaultCenter] postNotificationName:WCTrackerBookmarksDidChangeNotification];
//        
//        return YES;
//        
//	}
//    
//    
//    return NO;
//}



#pragma mark -

- (void)menuWillOpen:(NSMenu *)menu {
    NSInteger       clickedRow;
    id              server;
    
    if(menu == self.resourcesOutlineMenu) {
        [menu removeAllItems];
        
        clickedRow = [self.resourcesOutlineView clickedRow];
        
        if(clickedRow == -1)
            return;
        
        server = [self.resourcesOutlineView itemAtRow:clickedRow];
        
        if(!server)
            return;
        
        if([server isKindOfClass:[WCServerBonjourServer class]]) {
            [menu addItemWithTitle:@"Connect" action:@selector(openServer:) keyEquivalent:@""];
            [menu addItem:[NSMenuItem separatorItem]];
            [menu addItemWithTitle:@"Add To Bookmarks" action:@selector(addToBookmarks:) keyEquivalent:@""];
            
        } else if([server isKindOfClass:[WCServerBookmarkServer class]]) {
            [menu addItemWithTitle:@"Connect" action:@selector(openServer:) keyEquivalent:@""];
            [menu addItem:[NSMenuItem separatorItem]];
            [menu addItemWithTitle:@"Delete" action:@selector(deleteServerOrTrackerBookmark:) keyEquivalent:@""];
            
        } else if([server isKindOfClass:[WCServerTrackerServer class]]) {
            [menu addItemWithTitle:@"Connect" action:@selector(openServer:) keyEquivalent:@""];
            [menu addItemWithTitle:@"Get Info" action:@selector(getTrackerServerInfo:) keyEquivalent:@""];
            
            if([server isTracker]) {
                [menu addItem:[NSMenuItem separatorItem]];
                [menu addItemWithTitle:@"Reload" action:@selector(reloadTracker:) keyEquivalent:@""];
            }
            
            [menu addItem:[NSMenuItem separatorItem]];
            [menu addItemWithTitle:@"Add To Bookmarks" action:@selector(addToBookmarks:) keyEquivalent:@""];
            
        } else if([server isKindOfClass:[WCServerTracker class]]) {
            [menu addItemWithTitle:@"Reload" action:@selector(reloadTracker:) keyEquivalent:@""];
            [menu addItem:[NSMenuItem separatorItem]];
            [menu addItemWithTitle:@"Delete" action:@selector(deleteServerOrTrackerBookmark:) keyEquivalent:@""];
        }
    }
}





#pragma mark -

- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem {
    NSString        *name;
    NSDictionary    *bookmark;
    NSInteger       toSelectRow;
    
    [self _selectViewWithToolbarIdentifier:[[[self window] toolbar] selectedItemIdentifier]];
    
    name        = [[[self serverControllerForConnectionIdentifier:[tabViewItem identifier]] connection] name];
    bookmark    = [[[self serverControllerForConnectionIdentifier:[tabViewItem identifier]] connection] bookmark];
    
    if(bookmark) {
        for(WCServerBookmarkServer *bs in [_bookmarks items]) {
            if([bookmark isEqualToDictionary:[bs bookmark]]) {
                toSelectRow = [self.resourcesOutlineView rowForItem:bs];
                
                if(toSelectRow != -1) {
                    [self.resourcesOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:toSelectRow] byExtendingSelection:NO];
                    return;
                }
            }
        }
    }
    
    for(WCServerBonjourServer *bs in [_bonjour items]) {
        if([name isEqualToString:[bs name]]) {
            toSelectRow = [self.resourcesOutlineView rowForItem:bs];
            
            if(toSelectRow != -1) {
                [self.resourcesOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:toSelectRow] byExtendingSelection:NO];
                return;
            }
        }
    }
}


- (void)tabView:(NSTabView *)aTabView tabBarViewDidHide:(MMTabBarView *)tabBarView {
    [[[self window] toolbar] setShowsBaselineSeparator:YES];
}


- (void)tabView:(NSTabView *)aTabView tabBarViewDidUnhide:(MMTabBarView *)tabBarView {
    [[[self window] toolbar] setShowsBaselineSeparator:NO];
}


- (void)tabView:(NSTabView *)aTabView didCloseTabViewItem:(NSTabViewItem *)tabViewItem; {
    [self _removeTabViewItem:tabViewItem];
}


- (BOOL)tabView:(NSTabView *)aTabView shouldCloseTabViewItem:(NSTabViewItem *)tabViewItem {
	return YES;
}





#pragma mark -

- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didFindService:(NSNetService *)netService moreComing:(BOOL)moreComing {
	[netService setDelegate:self];
	[netService resolveWithTimeout:5.0];
    
	[_bonjour addItem:[WCServerBonjourServer itemWithNetService:netService]];
    
	if(!moreComing) {
		[self.resourcesOutlineView reloadData];		
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
		[self.resourcesOutlineView reloadData];
	}
}



- (void)netServiceDidResolveAddress:(NSNetService *)netService {
	[netService stop];
}


@end
