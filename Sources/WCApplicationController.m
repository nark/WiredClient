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

#import <Sparkle/SUStandardVersionComparator.h>
#import <Sparkle/SUHost.h>

#import "WCAboutWindow.h"
#import "WCAccountsController.h"
#import "WCAdministration.h"
#import "WCApplicationController.h"
#import "WCBanlistController.h"
#import "WCDatabaseController.h"
#import "WCBoards.h"
#import "WCConnect.h"
#import "WCConsole.h"
#import "WCFiles.h"
#import "WCFile.h"
#import "WCKeychain.h"
#import "WCMessage.h"
#import "WCMessages.h"
#import "WCPreferences.h"
#import "WCPublicChat.h"
#import "WCPublicChatController.h"
#import "WCServerConnection.h"
#import "WCServers.h"
#import "WCStats.h"
#import "WCTransfers.h"
#import "WCChatHistory.h"
#import "WCUser.h"


#define WCGrowlServerConnected										@"Connected to server"
#define WCGrowlServerDisconnected									@"Disconnected from server"
#define WCGrowlError												@"Error"
#define WCGrowlUserJoined											@"User joined"
#define WCGrowlUserChangedNick										@"User changed nick"
#define WCGrowlUserChangedStatus									@"User changed status"
#define WCGrowlUserLeft												@"User left"
#define WCGrowlChatReceived											@"Chat received"
#define WCGrowlHighlightedChatReceived								@"Highlighted chat received"
#define WCGrowlChatInvitationReceived								@"Private chat invitation received"
#define WCGrowlMessageReceived										@"Message received"
#define WCGrowlBoardPostReceived									@"Board post added"
#define WCGrowlBroadcastReceived									@"Broadcast received"
#define WCGrowlTransferStarted										@"Transfer started"
#define WCGrowlTransferFinished										@"Transfer finished"


NSString * const WCDateDidChangeNotification						= @"WCDateDidChangeNotification";
NSString * const WCExceptionHandlerReceivedBacktraceNotification	= @"WCExceptionHandlerReceivedBacktraceNotification";
NSString * const WCExceptionHandlerReceivedExceptionNotification	= @"WCExceptionHandlerReceivedExceptionNotification";


static NSInteger _WCCompareSmileyLength(id, id, void *);

static NSInteger _WCCompareSmileyLength(id object1, id object2, void *context) {
	NSUInteger	length1 = [(NSString *) object1 length];
	NSUInteger	length2 = [(NSString *) object2 length];
	
	if(length1 > length2)
		return -1;
	else if(length1 < length2)
		return 1;
	
	return 0;
}


@interface WCApplicationController(Private)

- (void)_loadSmileys;

- (void)_update;
- (void)_updateApplicationIcon;
- (void)_updateBookmarksMenu;

- (void)_reloadChatLogsControllerWithPath:(NSString *)path;

- (void)_connectWithBookmark:(NSDictionary *)bookmark;
- (BOOL)_openConnectionWithURL:(WIURL *)url;

@end


@implementation WCApplicationController(Private)

- (void)_loadSmileys {
	NSBundle			*bundle;
	NSMenuItem			*item;
	NSMutableArray		*array;
	NSDictionary		*dictionary, *list, *map, *names;
	NSEnumerator		*enumerator;
	NSString			*path, *file, *name, *smiley, *title;
	
	bundle			= [self bundle];
	path			= [bundle pathForResource:@"Smileys" ofType:@"plist"];
	dictionary		= [NSDictionary dictionaryWithContentsOfFile:path];
	list			= [dictionary objectForKey:@"List"];
	map				= [dictionary objectForKey:@"Map"];
	enumerator		= [map keyEnumerator];
	_smileys		= [[NSMutableDictionary alloc] initWithCapacity:[map count]];

	while((smiley = [enumerator nextObject])) {
		file = [map objectForKey:smiley];
		path = [bundle pathForResource:file ofType:NULL];
		
		if(path)
			[_smileys setObject:path forKey:[smiley lowercaseString]];
		else
			NSLog(@"*** %@: Could not find image \"%@\"", [self class], file);
	}
	
	array = [NSMutableArray arrayWithObjects:
		@"Smile.tiff",
		@"Wink.tiff",
		@"Frown.tiff",
		@"Slant.tiff",
		@"Gasp.tiff",
		@"Laugh.tiff",
		@"Kiss.tiff",
		@"Yuck.tiff",
		@"Embarrassed.tiff",
		@"Footinmouth.tiff",
		@"Cool.tiff",
		@"Angry.tiff",
		@"Innocent.tiff",
		@"Cry.tiff",
		@"Sealed.tiff",
		@"Moneymouth.tiff",
		NULL];
	
	names = [NSDictionary dictionaryWithObjectsAndKeys:
		NSLS(@"Smile", @"Smiley"),					@"Smile.tiff",
		NSLS(@"Wink", @"Smiley"),					@"Wink.tiff",
		NSLS(@"Frown", @"Smiley"),					@"Frown.tiff",
		NSLS(@"Undecided", @"Smiley"),				@"Slant.tiff",
		NSLS(@"Gasp", @"Smiley"),					@"Gasp.tiff",
		NSLS(@"Laugh", @"Smiley"),					@"Laugh.tiff",
		NSLS(@"Kiss", @"Smiley"),					@"Kiss.tiff",
		NSLS(@"Sticking out tongue", @"Smiley"),	@"Yuck.tiff",
		NSLS(@"Embarrassed", @"Smiley"),			@"Embarrassed.tiff",
		NSLS(@"Foot in mouth", @"Smiley"),			@"Footinmouth.tiff",
		NSLS(@"Cool", @"Smiley"),					@"Cool.tiff",
		NSLS(@"Angry", @"Smiley"),					@"Angry.tiff",
		NSLS(@"Innocent", @"Smiley"),				@"Innocent.tiff",
		NSLS(@"Cry", @"Smiley"),					@"Cry.tiff",
		NSLS(@"Lips are sealed", @"Smiley"),		@"Sealed.tiff",
		NSLS(@"Money-mouth", @"Smiley"),			@"Moneymouth.tiff",
		NULL];

	[array addObjectsFromArray:[[[[NSSet setWithArray:[list allKeys]] setByMinusingSet:[NSSet setWithArray:array]] allObjects] 
		sortedArrayUsingSelector:@selector(compare:)]];
	
	enumerator = [array objectEnumerator];
	
	while((name = [enumerator nextObject])) {
		smiley	= [list objectForKey:name];
		path	= [_smileys objectForKey:[smiley lowercaseString]];
		title	= [names objectForKey:name];
		
		if(!title)
			title = [name stringByDeletingPathExtension];
		
		item = [NSMenuItem itemWithTitle:title];
		[item setRepresentedObject:path];
		[item setImage:[[[NSImage alloc] initWithContentsOfFile:path] autorelease]];
		[item setAction:@selector(insertSmiley:)];
		[item setToolTip:smiley];
		[_insertSmileyMenu addItem:item];
	}
	
	_sortedSmileys = [[[_smileys allKeys] sortedArrayUsingFunction:_WCCompareSmileyLength context:NULL] retain];
}



#pragma mark -

- (void)_update {
	if([[WCSettings settings] boolForKey:WCConfirmDisconnect])
		[_disconnectMenuItem setTitle:NSLS(@"Disconnect\u2026", @"Disconnect menu item")];
	else
		[_disconnectMenuItem setTitle:NSLS(@"Disconnect", @"Disconnect menu item")];
	
	[_updater setAutomaticallyChecksForUpdates:[[WCSettings settings] boolForKey:WCCheckForUpdate]];
}



- (void)_updateApplicationIcon {
    if(_unread > 0)
        [[NSApp dockTile] setBadgeLabel:[NSSWF:@"%ld", _unread]];
    else
        [[NSApp dockTile] setBadgeLabel:nil];
}



- (void)_updateBookmarksMenu {
	NSEnumerator	*enumerator;
	NSArray			*bookmarks;
	NSDictionary	*bookmark;
	NSMenuItem		*item;
	NSUInteger		i = 1;
        
	while((item = (NSMenuItem *) [_bookmarksMenu itemWithTag:0]))
		[_bookmarksMenu removeItem:item];

	bookmarks = [[WCSettings settings] objectForKey:WCBookmarks];

	if([bookmarks count] > 0)
		[_bookmarksMenu addItem:[NSMenuItem separatorItem]];

	enumerator = [bookmarks objectEnumerator];

	while((bookmark = [enumerator nextObject])) {
		item = [NSMenuItem itemWithTitle:[bookmark objectForKey:WCBookmarksName] action:@selector(bookmark:)];
		[item setTarget:self];
		[item setRepresentedObject:bookmark];
		
		if(i <= 10) {
			[item setKeyEquivalent:[NSSWF:@"%u", (i == 10) ? 0 : i]];
			[item setKeyEquivalentModifierMask:NSCommandKeyMask];
		}
		else if(i <= 20) {
			[item setKeyEquivalent:[NSSWF:@"%u", (i == 20) ? 0 : i - 10]];
			[item setKeyEquivalentModifierMask:NSCommandKeyMask | NSAlternateKeyMask];
		}
		else if(i <= 30) {
			[item setKeyEquivalent:[NSSWF:@"%u", (i == 30) ? 0 : i - 20]];
			[item setKeyEquivalentModifierMask:NSCommandKeyMask | NSShiftKeyMask];
		}

		[_bookmarksMenu addItem:item];

		i++;
	}
    
    [_bookmarksMenu addItem:[NSMenuItem separatorItem]];
    
    [_bookmarksMenu addItem:[NSMenuItem itemWithTitle:NSLS(@"Export Server Bookmarks...", @"Bookmarks menu item title")
                                               action:@selector(exportBookmarks:)
                                        keyEquivalent:@""]];

    [_bookmarksMenu addItem:[NSMenuItem itemWithTitle:NSLS(@"Export Tracker Bookmarks...", @"Bookmarks menu item title")
                                               action:@selector(exportTrackerBookmarks:)
                                        keyEquivalent:@""]];
    
    [_bookmarksMenu addItem:[NSMenuItem itemWithTitle:NSLS(@"Import Bookmarks...", @"Bookmarks menu item title")
                                               action:@selector(importBookmarks:)
                                        keyEquivalent:@""]];
}



#pragma mark -

- (void)_connectWithBookmark:(NSDictionary *)bookmark {
	NSString			*address, *login, *password;
	WCConnect			*connect;
	WIURL				*url;

	address		= [bookmark objectForKey:WCBookmarksAddress];
	login		= [bookmark objectForKey:WCBookmarksLogin];
	password	= [[WCKeychain keychain] passwordForBookmark:bookmark];

	url = [WIURL URLWithString:address scheme:@"wiredp7"];
	[url setUser:login];
	[url setPassword:password ? password : @""];
	
	if(![self _openConnectionWithURL:url]) {
		connect = [WCConnect connectWithURL:url bookmark:bookmark];
		[connect showWindow:self];
		[connect connect:self];
	}
}


- (void)_connectWithURL:(WIURL *)url bookmark:(NSDictionary *)bookmark {
	NSString			*login, *password;
	WCConnect			*connect;
    
	login		= [bookmark objectForKey:WCBookmarksLogin];
	password	= [[WCKeychain keychain] passwordForBookmark:bookmark];

    [url setUser:login];
	[url setPassword:password ? password : @""];
	
	if(![self _openConnectionWithURL:url]) {
		connect = [WCConnect connectWithURL:url bookmark:bookmark];
		[connect showWindow:self];
		[connect connect:self];
	}
}


- (BOOL)_openConnectionWithURL:(WIURL *)url {
	NSEnumerator            *enumerator;
	WCPublicChatController	*chatController;
    WIURL                   *connectionURL;
    
	enumerator  = [[[WCPublicChat publicChat] chatControllers] objectEnumerator];
	    
	while((chatController = [enumerator nextObject])) {
        connectionURL = [[chatController connection] URL];
        
		if([[url host] isEqual:[connectionURL host]] &&
           [[url user] isEqual:[connectionURL user]] &&
           [url port] == [connectionURL port]) {
            
			[[WCPublicChat publicChat] selectChatController:chatController];
			[[WCPublicChat publicChat] showWindow:self];
            
            // try to download the file if Wired URL has a path extention
            if([url pathExtension]) {
                [WCTransfers downloadFileAtPath:[url path] forConnection:[chatController connection]];
            }
			
			return YES;
		}
	}
	
	return NO;
}



#pragma mark -

- (void)_reloadChatLogsControllerWithPath:(NSString *)path {
	NSString		*newPath;
	NSFileManager	*fileManager;
	NSError			*error;
	
	/* We are in a background thread */
	
	fileManager = [NSFileManager defaultManager];
	
	// move old chat history if needed
	if([fileManager fileExistsAtPath:[_logController publicHistoryBundlePath]]) {
		newPath	= [path stringByAppendingPathComponent:[[_logController publicHistoryBundlePath] lastPathComponent]];
		[fileManager copyItemAtPath:[_logController publicHistoryBundlePath] 
							 toPath:newPath 
							  error:&error];
	}
	
	if([fileManager fileExistsAtPath:[_logController privateHistoryBundlePath]]) {
		newPath	= [path stringByAppendingPathComponent:[[_logController privateHistoryBundlePath] lastPathComponent]];
		[fileManager copyItemAtPath:[_logController privateHistoryBundlePath] 
							 toPath:newPath 
							  error:&error];
	}
	
	// move old chat logs if needed
	if([fileManager fileExistsAtPath:[_logController chatLogsPath]]) {
		newPath	= [path stringByAppendingPathComponent:[[_logController chatLogsPath] lastPathComponent]];
		[fileManager copyItemAtPath:[_logController chatLogsPath] 
							 toPath:newPath 
							  error:&error];
	}
	

    if(_logController) {
        [_logController release];
        _logController = nil;
    }
    
    _logController = [[WIChatLogController alloc] initWithPath:path];
}


@end





@implementation WCApplicationController

static WCApplicationController		*sharedController;


+ (WCApplicationController *)sharedController {
	return sharedController;
}



#pragma mark -

+ (NSString *)copiedNameForName:(NSString *)name existingNames:(NSArray *)names {
	NSMutableString		*copiedName;
	NSString			*string, *copy;
	NSUInteger			number;
	
	copy = NSLS(@"Copy", @"Account copy");
	
	if([name containsSubstring:[NSSWF:@" %@", copy]]) {
		string			= [name stringByMatching:[NSSWF:@"(\\d+)$", copy] capture:1];
		number			= string ? [string unsignedIntegerValue] + 1 : 2;
		copiedName		= [[name mutableCopy] autorelease];
	} else {
		number			= 2;
		copiedName		= [NSMutableString stringWithFormat:@"%@ %@", name, copy];
	}
	
	while([names containsObject:copiedName]) {
		if([copiedName replaceOccurrencesOfRegex:@"(\\d+)$" withString:[NSSWF:@"%u", number]] == 0)
			[copiedName appendFormat:[NSSWF:@" %u", number]];
		
		number++;
	}
	
	return copiedName;
}



#pragma mark -

- (id)init {
	NSTimer		*timer;
	NSDate		*date;
	
	sharedController = self = [super init];
	
#ifndef WCConfigurationRelease
	[[WIExceptionHandler sharedExceptionHandler] enable];
	[[WIExceptionHandler sharedExceptionHandler] setDelegate:self];
#endif
	
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		   selector:@selector(preferencesDidChange:)
			   name:WCPreferencesDidChangeNotification];

	[[NSNotificationCenter defaultCenter]
		addObserver:self
		   selector:@selector(bookmarksDidChange:)
			   name:WCBookmarksDidChangeNotification];
	
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		   selector:@selector(linkConnectionWillConnect:)
			   name:WCLinkConnectionWillConnectNotification];
	
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
		   selector:@selector(serverConnectionTriggeredEvent:)
			   name:WCServerConnectionTriggeredEventNotification];
	
	[[NSAppleEventManager sharedAppleEventManager]
		setEventHandler:self
			andSelector:@selector(handleAppleEvent:withReplyEvent:)
		  forEventClass:kInternetEventClass
			 andEventID:kAEGetURL];
	
	[[NSFileManager defaultManager] createDirectoryAtPath:[WCApplicationSupportPath stringByStandardizingPath]];
	
	date = [[NSDate dateAtStartOfCurrentDay] dateByAddingDays:1];
	timer = [[NSTimer alloc] initWithFireDate:date
									 interval:86400.0
									   target:self
									 selector:@selector(dailyTimer:)
									 userInfo:NULL
									  repeats:YES];
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
	[timer release];
	
	signal(SIGPIPE, SIG_IGN);

	return self;
}



- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[_clientVersion release];
	[_smileys release];
	[_sortedSmileys release];
	
	[_logController release];

	[super dealloc];
}



#pragma mark -

- (void)awakeFromNib {
	NSEnumerator		*enumerator;
	NSDictionary		*bookmark;
	NSString			*path;
	WIError				*error;
	
    // remove the Console menu in Release mode
#ifdef WCConfigurationRelease
	if(![[WCSettings settings] boolForKey:WCDebug])
		[[NSApp mainMenu] removeItemAtIndex:[[NSApp mainMenu] indexOfItemWithSubmenu:_debugMenu]];
#endif
    
    [[WCDatabaseController sharedController] secretKey];
	
	[WIDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehavior10_4];
	[NSNumberFormatter setDefaultFormatterBehavior:NSNumberFormatterBehavior10_4];
	
	[GrowlApplicationBridge setGrowlDelegate:self];
    [GrowlApplicationBridge setShouldUseBuiltInNotifications:NO];
    
    // set the auto-update feed URL regarding to the selected configuration (Debug or Release)
#ifdef WCConfigurationRelease
    [_updater setFeedURL:[NSURL URLWithString:@"http://wired.read-write.fr/xml/wiredclientcast.xml"]];
#else
    [_updater setFeedURL:[NSURL URLWithString:@"http://wired.read-write.fr/xml/wiredclient_debugcast.xml"]];
#endif
    
	[_updater setSendsSystemProfile:YES];
    [_updater performSelector:@selector(checkForUpdatesInBackground) afterDelay:5.0f];
	
	path = [[NSBundle mainBundle] pathForResource:@"wired" ofType:@"xml"];
	
    // verify the P7 specification in debug mode
#ifdef WCConfigurationDebug
//	if([[NSFileManager defaultManager] fileExistsAtPath:@"p7-specification.xsd"]) {
//		if(![[[NSXMLDocument alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path] options:NSXMLDocumentValidate error:(NSError **) &error] autorelease]) {
//			[[error alert] runModal];
//			
//			[NSApp terminate:self];
//		}
//	}
#endif
	
    // init and load the Wired 2.0 P7 Specification
	WCP7Spec = [[WIP7Spec alloc] initWithPath:path originator:WIP7Client error:&error];
	if(!WCP7Spec) {
		[[error alert] runModal];
		
		[NSApp terminate:self];
	}


	[self _update];
	[self _updateBookmarksMenu];
	[self _reloadChatLogsControllerWithPath:[self chatLogsPath]];

    if([[WCSettings settings] boolForKey:WCShowChatWindowAtStartup])
		[[WCPublicChat publicChat] showWindow:self];

	if([[WCSettings settings] boolForKey:WCShowConnectAtStartup])
		[[WCConnect connect] showWindow:self];
	
	if((GetCurrentKeyModifiers() & optionKey) == 0) {
		enumerator = [[[WCSettings settings] objectForKey:WCBookmarks] objectEnumerator];

		while((bookmark = [enumerator nextObject])) {
			if([[bookmark objectForKey:WCBookmarksAutoConnect] boolValue])
				[self _connectWithBookmark:bookmark];
		}
	}
}



#pragma mark -

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)application {
	NSEnumerator			*enumerator;
	WCPublicChatController	*chatController;
	NSUInteger				count;
	
	enumerator = [[[WCPublicChat publicChat] chatControllers] objectEnumerator];
	count = 0;
	
	while((chatController = [enumerator nextObject])) {
		if([[chatController connection] isConnected])
			count++;
	}
	
	if([[WCSettings settings] boolForKey:WCConfirmDisconnect] && count > 0)
		return [(WIApplication *) NSApp runTerminationDelayPanelWithTimeInterval:30.0];

	return NSTerminateNow;
}



- (void)applicationWillTerminate:(NSNotification *)notification {
	_unread = 0;
	
	[[WCPublicChat publicChat] saveAllChatControllerHistory];

	[self _updateApplicationIcon];
}



- (BOOL)application:(NSApplication *)application openFile:(NSString *)filename {
	NSString		*extension;
	
	extension = [filename pathExtension];
	
	if([extension isEqualToString:@"WiredTheme"])
		return [[WCPreferences preferences] importThemeFromFile:filename];
    else if([extension isEqualToString:@"WiredTemplate"])
		return [[WCPreferences preferences] importTemplateFromFile:filename];
	else if([extension isEqualToString:@"WiredBookmarks"])
		return [[WCPreferences preferences] importBookmarksFromFile:filename];
	else if([extension isEqualToString:@"WiredTrackerBookmarks"])
		return [[WCPreferences preferences] importTrackerBookmarksFromFile:filename];
	else if([extension isEqualToString:@"WiredTransfer"])
		return [[WCTransfers transfers] addTransferAtPath:filename];
	
	return NO;
}


- (BOOL)applicationOpenUntitledFile:(NSApplication *)sender {
    [[WCPublicChat publicChat] showWindow:self];
    return NO;
}



- (void)menuNeedsUpdate:(NSMenu *)menu {
	NSString		*newString, *deleteString, *reloadString, *quickLookString, *saveString;
	id				delegate;
	
	if(menu == _connectionMenu) {
		delegate = [[NSApp keyWindow] delegate];
		
		if([delegate respondsToSelector:@selector(newDocumentMenuItemTitle)])
			newString = [delegate newDocumentMenuItemTitle];
		else
			newString = NULL;
		
		if([delegate respondsToSelector:@selector(deleteDocumentMenuItemTitle)])
			deleteString = [delegate deleteDocumentMenuItemTitle];
		else
			deleteString = NULL;
		
		if([delegate respondsToSelector:@selector(reloadDocumentMenuItemTitle)])
			reloadString = [delegate reloadDocumentMenuItemTitle];
		else
			reloadString = NULL;
		
		if([delegate respondsToSelector:@selector(quickLookMenuItemTitle)])
			quickLookString = [delegate quickLookMenuItemTitle];
		else
			quickLookString = NULL;
		
		if([delegate respondsToSelector:@selector(saveDocumentMenuItemTitle)])
			saveString = [delegate saveDocumentMenuItemTitle];
		else
			saveString = NULL;
		
		[_newDocumentMenuItem setTitle:newString ? newString : NSLS(@"New Thread", @"New menu item")];
		[_deleteDocumentMenuItem setTitle:deleteString ? deleteString : NSLS(@"Delete", @"Delete menu item")];
		[_reloadDocumentMenuItem setTitle:reloadString ? reloadString : NSLS(@"Reload", @"Reload menu item")];
		[_quickLookMenuItem setTitle:quickLookString ? quickLookString : NSLS(@"Quick Look", @"Quick Look menu item")];
		[_saveDocumentMenuItem setTitle:saveString ? saveString : NSLS(@"Save", @"Save menu item")];
	}
	else if(menu == _windowMenu) {
		if([NSApp keyWindow] == [[WCPublicChat publicChat] window] && [[WCPublicChat publicChat] selectedChatController] != NULL) {
			[_closeWindowMenuItem setAction:@selector(closeTab:)];
			[_closeWindowMenuItem setTitle:NSLS(@"Close Tab", @"Close tab menu item")];
		} else {
			[_closeWindowMenuItem setAction:@selector(performClose:)];
			[_closeWindowMenuItem setTitle:NSLS(@"Close Window", @"Close window menu item")];
		}
	}
	else if(menu == _insertSmileyMenu) {
		if(!_sortedSmileys)
			[self _loadSmileys];
	}
}



- (void)preferencesDidChange:(NSNotification *)notification {
	[self _update];
}



- (void)bookmarksDidChange:(NSNotification *)notification {
	[self _updateBookmarksMenu];
}



- (void)linkConnectionWillConnect:(NSNotification *)notification {
	[WCStats stats];
	[WCTransfers transfers];
	[WCMessages messages];
	[WCBoards boards];
}



- (void)messagesDidChangeUnreadCount:(NSNotification *)notification {
	_unread = [[WCMessages messages] numberOfUnreadMessages] + [[WCBoards boards] numberOfUnreadThreads];
	
	[self performSelector:@selector(_updateApplicationIcon) withObject:NULL afterDelay:0.0];
}



- (void)boardsDidChangeUnreadCount:(NSNotification *)notification {
	_unread = [[WCMessages messages] numberOfUnreadMessages] + [[WCBoards boards] numberOfUnreadThreads];
	
	[self performSelector:@selector(_updateApplicationIcon) withObject:NULL afterDelay:0.0];
}



- (void)serverConnectionTriggeredEvent:(NSNotification *)notification {
        
	NSDictionary			*event;
	NSString				*sound;
	WCServerConnection		*connection;
	id						info1, info2;
	
	event		= [notification object];
	connection	= [[notification userInfo] objectForKey:WCServerConnectionEventConnectionKey];
	info1		= [[notification userInfo] objectForKey:WCServerConnectionEventInfo1Key];
	info2		= [[notification userInfo] objectForKey:WCServerConnectionEventInfo2Key];
	
	if([event boolForKey:WCEventsPlaySound]) {
		sound = [event objectForKey:WCEventsSound];
		
		if(sound)
			[NSSound playSoundNamed:sound atVolume:[[WCSettings settings] floatForKey:WCEventsVolume]];
	}
	
	if([event boolForKey:WCEventsBounceInDock])
		[NSApp requestUserAttention:NSInformationalRequest];
	
	switch([event intForKey:WCEventsEvent]) {
		case WCEventsServerConnected:
			[GrowlApplicationBridge notifyWithTitle:NSLS(@"Connected", @"Growl event connected title")
										description:[NSSWF:NSLS(@"Connected to %@", @"Growl event connected description (server)"),
											[connection name]]
								   notificationName:WCGrowlServerConnected
										   iconData:NULL
										   priority:0.0
										   isSticky:NO
									   clickContext:[connection identifier]];
			break;

		case WCEventsServerDisconnected:
			[GrowlApplicationBridge notifyWithTitle:NSLS(@"Disconnected", @"Growl event disconnected title")
										description:[NSSWF:NSLS(@"Disconnected from %@", @"Growl event disconnected description (server)"),
											[connection name]]
								   notificationName:WCGrowlServerDisconnected
										   iconData:NULL
										   priority:0.0
										   isSticky:NO
									   clickContext:[connection identifier]];
			break;
		
		case WCEventsError:
			[GrowlApplicationBridge notifyWithTitle:[info1 localizedDescription]
										description:[info1 localizedFailureReason]
								   notificationName:WCGrowlError
										   iconData:NULL
										   priority:0.0
										   isSticky:NO
									   clickContext:[connection identifier]];
			break;
		
		case WCEventsUserJoined:
			[GrowlApplicationBridge notifyWithTitle:NSLS(@"User joined", @"Growl event user joined title")
										description:[info1 nick]
								   notificationName:WCGrowlUserJoined
										   iconData:[[info1 icon] TIFFRepresentation]
										   priority:0.0
										   isSticky:NO
									   clickContext:[connection identifier]];
			break;
		
		case WCEventsUserChangedNick:
			[GrowlApplicationBridge notifyWithTitle:NSLS(@"User changed nick", @"Growl event user changed nick title")
										description:[NSSWF:NSLS(@"%@ is now known as %@", @"Growl event user changed nick description (oldnick, newnick)"),
											[info1 nick], info2]
								   notificationName:WCGrowlUserChangedNick
										   iconData:[[info1 icon] TIFFRepresentation]
										   priority:0.0
										   isSticky:NO
									   clickContext:[connection identifier]];
			break;
		
		case WCEventsUserChangedStatus:
			[GrowlApplicationBridge notifyWithTitle:NSLS(@"User changed status", @"Growl event user changed status title")
										description:[NSSWF:NSLS(@"%@ changed status to %@", @"Growl event user changed status description (nick, status)"),
											[info1 nick], info2]
								   notificationName:WCGrowlUserChangedStatus
										   iconData:[[info1 icon] TIFFRepresentation]
										   priority:0.0
										   isSticky:NO
									   clickContext:[connection identifier]];
			break;
		
		case WCEventsUserLeft:
			[GrowlApplicationBridge notifyWithTitle:NSLS(@"User left", @"Growl event user left title")
										description:[info1 nick]
								   notificationName:WCGrowlUserLeft
										   iconData:[[info1 icon] TIFFRepresentation]
										   priority:0.0
										   isSticky:NO
									   clickContext:[connection identifier]];
			break;
		
		case WCEventsChatReceived:
			[GrowlApplicationBridge notifyWithTitle:NSLS(@"Chat received", @"Growl event chat received title")
										description:[NSSWF:@"%@: %@", [info1 nick], info2]
								   notificationName:WCGrowlChatReceived
										   iconData:[[info1 icon] TIFFRepresentation]
										   priority:0.0
										   isSticky:NO
									   clickContext:[connection identifier]];
			break;
			
		
		
		case WCEventsHighlightedChatReceived:
			[GrowlApplicationBridge notifyWithTitle:NSLS(@"Chat received", @"Growl event chat received title")
										description:[NSSWF:@"%@: %@", [info1 nick], info2]
								   notificationName:WCGrowlHighlightedChatReceived
										   iconData:[[info1 icon] TIFFRepresentation]
										   priority:0.0
										   isSticky:NO
									   clickContext:[connection identifier]];
			break;
		
		case WCEventsChatInvitationReceived:
			[GrowlApplicationBridge notifyWithTitle:NSLS(@"Private chat invitation received", @"Growl event private chat invitation received title")
										description:[info1 nick]
								   notificationName:WCGrowlChatInvitationReceived
										   iconData:[[info1 icon] TIFFRepresentation]
										   priority:0.0
										   isSticky:NO
									   clickContext:[connection identifier]];
			break;
			
		case WCEventsMessageReceived:
			[GrowlApplicationBridge notifyWithTitle:NSLS(@"Message received", @"Growl event message received title")
										description:[NSSWF:@"%@: %@", [info1 nick], [info1 valueForKey:@"messageString"]]
								   notificationName:WCGrowlMessageReceived
										   iconData:[[(WCUser *) [info1 user] icon] TIFFRepresentation]
										   priority:0.0
										   isSticky:NO
									   clickContext:[connection identifier]];
			break;
		
		case WCEventsBoardPostReceived:
			[GrowlApplicationBridge notifyWithTitle:NSLS(@"Board post received", @"Growl event news posted title")
										description:[NSSWF:@"%@: %@", info1, info2]
								   notificationName:WCGrowlBoardPostReceived
										   iconData:NULL
										   priority:0.0
										   isSticky:NO
									   clickContext:[connection identifier]];
			break;
		
		case WCEventsBroadcastReceived:
			[GrowlApplicationBridge notifyWithTitle:NSLS(@"Broadcast received", @"Growl event broadcast received title")
										description:[NSSWF:@"%@: %@", [info1 nick], [info1 message]]
								   notificationName:WCGrowlBroadcastReceived
										   iconData:[[(WCUser *) [info1 user] icon] TIFFRepresentation]
										   priority:0.0
										   isSticky:NO
									   clickContext:[connection identifier]];
			break;
		
		case WCEventsTransferStarted:
			[GrowlApplicationBridge notifyWithTitle:NSLS(@"Transfer started", @"Growl event transfer started title")
										description:[info1 name]
								   notificationName:WCGrowlTransferStarted
										   iconData:[[info1 icon] TIFFRepresentation]
										   priority:0.0
										   isSticky:NO
									   clickContext:[connection identifier]];
			break;
		
		case WCEventsTransferFinished:
			[GrowlApplicationBridge notifyWithTitle:NSLS(@"Transfer finished", @"Growl event transfer started title")
										description:[info1 name]
								   notificationName:WCGrowlTransferFinished
										   iconData:[[info1 icon] TIFFRepresentation]
										   priority:0.0
										   isSticky:NO
									   clickContext:[connection identifier]];
			break;
	}
}



- (void)handleAppleEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
	NSDictionary	*bookmark;
	NSString		*string;
	WIURL			*url;
	WCConnect		*connect;
	
	string = [[event descriptorForKeyword:keyDirectObject] stringValue];
    
    while([string characterAtIndex:[string length] - 1] == '/')
        string = [string stringByReplacingCharactersInRange:NSMakeRange([string length] - 1, 1)
                                                 withString:@""];
    
	url = [WIURL URLWithString:string];
	
	if([[url scheme] isEqualToString:@"wired"]) {
		if([[url host] length] > 0) {
			[[NSWorkspace sharedWorkspace] openURL:[url URL]];
		}
	}
    else if([[url scheme] isEqualToString:@"wiredp7"]) {
		if([[url host] length] > 0) {
			if(![self _openConnectionWithURL:url]) {
                bookmark    = [[WCSettings settings] bookmarkForURL:url];
                
                if(bookmark) {
                    [self _connectWithURL:url bookmark:bookmark];
                    
                } else {
                    connect     = [WCConnect connectWithURL:url bookmark:bookmark];
                    [connect showWindow:self];
                    [connect connect:self];
                }
			}
		}
	}
	else if([[url scheme] isEqualToString:@"wiredtracker"]) {
		bookmark = [NSDictionary dictionaryWithObjectsAndKeys:
					[url host],					WCTrackerBookmarksName,
					[url hostpair],				WCTrackerBookmarksAddress,
					@"",						WCTrackerBookmarksLogin,
					[NSString UUIDString],		WCTrackerBookmarksIdentifier,
					NULL];
		
		[[WCSettings settings] addObject:bookmark toArrayForKey:WCTrackerBookmarks];
		
        [[NSNotificationCenter defaultCenter] postNotificationName:WCBookmarksDidChangeNotification
                                                            object:bookmark
                                                          userInfo:bookmark];
	}
}



- (void)exceptionHandler:(WIExceptionHandler *)exceptionHandler receivedException:(NSException *)exception withBacktrace:(NSString *)backtrace {
	NSAlert		*alert;
	
	if(backtrace)
		[[NSNotificationCenter defaultCenter] postNotificationName:WCExceptionHandlerReceivedBacktraceNotification object:backtrace];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:WCExceptionHandlerReceivedExceptionNotification object:exception];
	
	alert = [[NSAlert alloc] init];
	[alert setMessageText:NSLS(@"Internal Client Error", @"Internal error dialog title")];
	[alert setInformativeText:NSLS(@"Wired Client has encountered an exception. More information has been logged to the console.", @"Internal error dialog description")];
	[alert runModal];
	[alert release];
}



- (NSDictionary *)registrationDictionaryForGrowl {
	return [NSDictionary dictionaryWithObjectsAndKeys:
		[NSArray arrayWithObjects:
			WCGrowlServerConnected,
			WCGrowlServerDisconnected,
			WCGrowlError,
			WCGrowlUserJoined,
			WCGrowlUserChangedNick,
			WCGrowlUserChangedStatus,
			WCGrowlUserLeft,
			WCGrowlChatReceived,
			WCGrowlHighlightedChatReceived,
			WCGrowlChatInvitationReceived,
			WCGrowlMessageReceived,
			WCGrowlBroadcastReceived,
			WCGrowlBoardPostReceived,
			WCGrowlTransferStarted,
			WCGrowlTransferFinished,
			NULL],
			GROWL_NOTIFICATIONS_ALL,
		[NSArray arrayWithObjects:
			WCGrowlServerDisconnected,
			WCGrowlHighlightedChatReceived,
			WCGrowlMessageReceived,
			WCGrowlBroadcastReceived,
			WCGrowlBoardPostReceived,
			WCGrowlTransferFinished,
			NULL],
			GROWL_NOTIFICATIONS_DEFAULT,
		NULL];
}



- (void)growlNotificationWasClicked:(id)clickContext {
	NSEnumerator			*enumerator;
	WCPublicChatController	*chatController;
	
	[NSApp activateIgnoringOtherApps:YES];
	
	enumerator = [[[WCPublicChat publicChat] chatControllers] objectEnumerator];
	
	while((chatController = [enumerator nextObject])) {
		if([clickContext isEqualToString:[[chatController connection] identifier]]) {
			[[WCPublicChat publicChat] selectChatController:chatController];
			[[WCPublicChat publicChat] showWindow:self];
		}
	}
}



- (BOOL)updaterShouldPromptForPermissionToCheckForUpdates:(SUUpdater *)updater {
	return NO;
}

//- (SUAppcastItem *)bestValidUpdateInAppcast:(SUAppcast *)appcast
//                                 forUpdater:(SUUpdater *)bundle {
//    
//    NSString        *appVersion, *appBuild;
//    SUAppcastItem   *latest = nil;
//    BOOL            new = NO;
//    
//    appVersion  = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
//    appBuild    = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
//    
//    NSLog(@"appVersion: %@", appVersion);
//    NSLog(@"appBuild: %@", appBuild);
//    
//    if([[appcast items] count] > 0) {
//        latest  = [[appcast items] objectAtIndex:0];
//        
//        NSLog(@"[host displayVersion]: %@", appVersion);
//        NSLog(@"[latest displayVersionString]: %@", [latest displayVersionString]);
//        
//        new = ([[SUStandardVersionComparator defaultComparator] compareVersion:appVersion
//                                                                    toVersion:[latest displayVersionString]] == NSOrderedAscending);
//        
//        NSLog(@"isNew : %@", new ? @"YES" : @"NO");
//        
//        if(new == YES) {
//            NSLog(@"latest : %@", latest);
//            return latest;
//            
//        } else {
//            NSLog(@"[host version]: %@", appBuild);
//            NSLog(@"[latest versionString]: %@", [latest versionString]);
//            
//            new = [[SUStandardVersionComparator defaultComparator] compareVersion:appBuild
//                                                                        toVersion:[latest versionString]] == NSOrderedAscending;
//            NSLog(@"isNew : %@", new ? @"YES" : @"NO");
//            if(new) {
//                return latest;
//            }
//        }
//    }
//    return nil;
//}
//
//- (void)updater:(SUUpdater *)updater didFindValidUpdate:(SUAppcastItem *)update {
//    NSLog(@"didFindValidUpdate");
//}
//
//- (void)updaterDidNotFindUpdate:(SUUpdater *)update {
//    NSLog(@"updaterDidNotFindUpdate");
//}


#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem *)item {
	SEL		selector;

	selector = [item action];
	
	if(selector == @selector(disconnect:) || selector == @selector(reconnect:) ||
	   selector == @selector(serverInfo:) || selector == @selector(files:) ||
	   selector == @selector(administration:) || selector == @selector(broadcast:) ||
	   selector == @selector(changePassword:) || selector == @selector(addBookmark:) ||
	   selector == @selector(console:) || selector == @selector(nextConnection:) ||
	   selector == @selector(previousConnection:) || selector == @selector(toggleUserList:)) {
		return [[WCPublicChat publicChat] validateMenuItem:item];
	}
	else if(selector == @selector(newDocument:) || selector == @selector(deleteDocument:)) {
		return [[WCBoards boards] validateMenuItem:item];
	}
	else if(selector == @selector(insertSmiley:)) {
		return ([[[NSApp keyWindow] firstResponder] respondsToSelector:@selector(insertText:)]);
	}
    else if(selector == @selector(exportBookmarks:)) {
        return ([[[WCSettings settings] objectForKey:WCBookmarks] count] > 0);
    }

	return YES;
}



#pragma mark -

- (void)dailyTimer:(NSTimer *)timer {
	[[NSNotificationCenter defaultCenter] postNotificationName:WCDateDidChangeNotification];
}



#pragma mark -

- (NSArray *)allSmileys {
	if(!_sortedSmileys)
		[self _loadSmileys];
	
	return _sortedSmileys;
}



- (NSString *)pathForSmiley:(NSString *)smiley {
	if(!_smileys)
		[self _loadSmileys];
	
	return [_smileys objectForKey:[smiley lowercaseString]];
}


- (NSMenu *)insertSmileyMenu {
	if(!_smileys)
		[self _loadSmileys];
	
	return _insertSmileyMenu;
}




#pragma mark -

- (NSString *)chatLogsPath {
	NSString *path;
	
	path = [[WCSettings settings] stringForKey:WCChatLogsPath];
	
	if(!path)
		path = WCApplicationSupportPath;
		
	return [path stringByStandardizingPath];
}


- (void)reloadChatLogsWithPath:(NSString *)path {
	[self _reloadChatLogsControllerWithPath:path];
}


- (WIChatLogController *)logController {
	return _logController;
}






#pragma mark -

- (void)checkForUpdate {
	[_updater checkForUpdates:self];
}





#pragma mark -


- (void)connectWithBookmark:(NSDictionary *)bookmark {
    [self _connectWithBookmark:bookmark];
}





#pragma mark -

- (NSURL *)applicationFilesDirectory
{
    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *appSupportURL = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *url = [appSupportURL URLByAppendingPathComponent:@"Wired Client"];
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:[url path]])
        [[NSFileManager defaultManager] createDirectoryAtURL:url withIntermediateDirectories:YES attributes:nil error:&error];
    
    if(error)
        NSLog(@"ERROR: Application Support Directory: %@", error);
    
    return url;
}





#pragma mark -

- (IBAction)about:(id)sender {
	NSMutableParagraphStyle		*style;
	NSMutableAttributedString	*credits;
	NSDictionary				*attributes;
	NSAttributedString			*header, *stats;
	NSData						*rtf;
	NSString					*string;
	
	if([[NSApp currentEvent] alternateKeyModifier]) {
		[[WCAboutWindow aboutWindow] makeKeyAndOrderFront:self];
	} else {
		rtf = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Credits" ofType:@"rtf"]];
		credits = [[[NSMutableAttributedString alloc] initWithRTF:rtf documentAttributes:NULL] autorelease];

		style = [[[NSMutableParagraphStyle alloc] init] autorelease];
		[style setAlignment:NSCenterTextAlignment];
		attributes = [NSDictionary dictionaryWithObjectsAndKeys:
			[NSFont boldSystemFontOfSize:11.0],	NSFontAttributeName,
			[NSColor grayColor],					NSForegroundColorAttributeName,
			style,									NSParagraphStyleAttributeName,
			NULL];
		string = [NSSWF:@"%@\n", NSLS(@"Stats", @"About box title")];
		header = [NSAttributedString attributedStringWithString:string attributes:attributes];

		attributes = [NSDictionary dictionaryWithObjectsAndKeys:
			[NSFont systemFontOfSize:11.0],			NSFontAttributeName,
			style,									NSParagraphStyleAttributeName,
			NULL];
		string = [NSSWF:@"%@\n\n", [[WCStats stats] stringValue]];
		stats = [NSAttributedString attributedStringWithString:string attributes:attributes];

		[credits insertAttributedString:stats atIndex:0];
		[credits insertAttributedString:header atIndex:0];

		[NSApp orderFrontStandardAboutPanelWithOptions:
			[NSDictionary dictionaryWithObject:credits forKey:@"Credits"]];
	}
}



- (IBAction)preferences:(id)sender {
	[[WCPreferences preferences] showWindow:self];
}



#pragma mark -

- (IBAction)connect:(id)sender {
	[[WCConnect connect] showWindow:sender];
}



- (IBAction)disconnect:(id)sender {
	[[WCPublicChat publicChat] disconnect:sender];
}



- (IBAction)reconnect:(id)sender {
	[[WCPublicChat publicChat] reconnect:sender];
}



- (IBAction)serverInfo:(id)sender {
	[[WCPublicChat publicChat] serverInfo:sender];
}



- (IBAction)files:(id)sender {
	[[WCPublicChat publicChat] files:sender];
}



- (IBAction)administration:(id)sender {
	[[WCPublicChat publicChat] administration:sender];
}



- (IBAction)broadcast:(id)sender {
	[[WCPublicChat publicChat] broadcast:sender];
}



- (IBAction)newDocument:(id)sender {
	[[WCBoards boards] showWindow:sender];
	[[WCBoards boards] newDocument:sender];
}



- (IBAction)deleteDocument:(id)sender {
	[[WCBoards boards] showWindow:sender];
	[[WCBoards boards] deleteDocument:sender];
}



- (IBAction)changePassword:(id)sender {
	[[WCPublicChat publicChat] changePassword:sender];
}



#pragma mark -

- (IBAction)insertSmiley:(id)sender {
	NSFileWrapper		*wrapper;
	NSTextAttachment	*attachment;
	NSAttributedString	*attributedString;
	
	wrapper				= [[NSFileWrapper alloc] initWithPath:[sender representedObject]];
	attachment			= [[WITextAttachment alloc] initWithFileWrapper:wrapper string:[sender toolTip]];
	attributedString	= [NSAttributedString attributedStringWithAttachment:attachment];
	
	[[[NSApp keyWindow] firstResponder] tryToPerform:@selector(insertText:) with:attributedString];
	
	[attachment release];
	[wrapper release];
}



#pragma mark -

- (IBAction)addBookmark:(id)sender {
	[[WCPublicChat publicChat] addBookmark:sender];
}



- (void)bookmark:(id)sender {
	[self _connectWithBookmark:[sender representedObject]];
}


- (IBAction)exportBookmarks:(id)sender {
	__block NSSavePanel     *savePanel;
    
    [[WCPublicChat publicChat] showWindow:self];
	
	savePanel = [NSSavePanel savePanel];
	[savePanel setAllowedFileTypes:[NSArray arrayWithObject:@"WiredBookmarks"]];
	[savePanel setCanSelectHiddenExtension:YES];
	[savePanel setAccessoryView:_bookmarksExportView];
    [savePanel setNameFieldStringValue:[NSLS(@"Bookmarks", @"Default export bookmarks name")
										stringByAppendingPathExtension:@"WiredBookmarks"]];
    
    [savePanel beginSheetModalForWindow:[[WCPublicChat publicChat] window] completionHandler:^(NSInteger result) {
        NSEnumerator			*enumerator;
        NSMutableArray			*bookmarks;
        NSMutableDictionary		*bookmark;
        NSDictionary			*dictionary;
        NSString				*password;
        
        if(result == NSOKButton) {
            bookmarks	= [NSMutableArray array];
            enumerator	= [[[WCSettings settings] objectForKey:WCBookmarks] objectEnumerator];
            
            while((dictionary = [enumerator nextObject])) {
                bookmark = [[dictionary mutableCopy] autorelease];
                password = [[WCKeychain keychain] passwordForBookmark:bookmark];
                
                if(password)
                    [bookmark setObject:password forKey:WCBookmarksPassword];
                
                [bookmark removeObjectForKey:WCBookmarksIdentifier];
                
                [bookmarks addObject:bookmark];
            }
            
            [bookmarks writeToURL:[savePanel URL] atomically:YES];
        }
    }];
}


- (IBAction)exportTrackerBookmarks:(id)sender {
    __block NSSavePanel     *savePanel;
	
	savePanel = [NSSavePanel savePanel];
	[savePanel setAllowedFileTypes:[NSArray arrayWithObject:@"WiredTrackerBookmarks"]];
	[savePanel setCanSelectHiddenExtension:YES];
	[savePanel setAccessoryView:_bookmarksExportView];
    [savePanel setNameFieldStringValue:[NSLS(@"Bookmarks", @"Default export bookmarks name")
										stringByAppendingPathExtension:@"WiredTrackerBookmarks"]];
    
    [savePanel beginSheetModalForWindow:[[WCPublicChat publicChat] window] completionHandler:^(NSInteger result) {
        NSEnumerator			*enumerator;
        NSMutableArray			*bookmarks;
        NSMutableDictionary		*bookmark;
        NSDictionary			*dictionary;
        NSString				*password;
        
        if(result == NSOKButton) {
            bookmarks	= [NSMutableArray array];
            enumerator	= [[[WCSettings settings] objectForKey:WCTrackerBookmarks] objectEnumerator];
            
            while((dictionary = [enumerator nextObject])) {
                bookmark = [[dictionary mutableCopy] autorelease];
                password = [[WCKeychain keychain] passwordForTrackerBookmark:bookmark];
                
                if(password)
                    [bookmark setObject:password forKey:WCTrackerBookmarksPassword];
                
                [bookmark removeObjectForKey:WCTrackerBookmarksIdentifier];
                
                [bookmarks addObject:bookmark];
            }
            
            [bookmarks writeToURL:[savePanel URL] atomically:YES];
        }
    }];
}



- (IBAction)importBookmarks:(id)sender {
	__block NSOpenPanel     *openPanel;
	
	openPanel = [NSOpenPanel openPanel];
    
	[openPanel setCanChooseFiles:YES];
	[openPanel setCanChooseDirectories:NO];
    [openPanel setAllowedFileTypes:[NSArray arrayWithObjects:@"WiredBookmarks", @"WiredTrackerBookmarks", nil]];
    
    [openPanel beginSheetModalForWindow:[[WCPublicChat publicChat] window] completionHandler:^(NSInteger result) {
        if(result == NSOKButton) {
            if([[[openPanel URL] pathExtension] isEqualToString:@"WiredBookmarks"]) {
                [[WCPreferences preferences] importBookmarksFromFile:[[openPanel URL] path]];
            }
            else if([[[openPanel URL] pathExtension] isEqualToString:@"WiredTrackerBookmarks"]) {
                [[WCPreferences preferences] importTrackerBookmarksFromFile:[[openPanel URL] path]];
            }
        }
    }];
}





#pragma mark -

- (IBAction)console:(id)sender {
	[[WCPublicChat publicChat] console:sender];
}



#pragma mark -

- (IBAction)chat:(id)sender {
	[[WCPublicChat publicChat] showWindow:sender];
}



- (IBAction)servers:(id)sender {
	[[WCServers servers] showWindow:sender];
}



- (IBAction)boards:(id)sender {
	[[WCBoards boards] showWindow:sender];
}



- (IBAction)messages:(id)sender {
	[[WCMessages messages] showWindow:sender];
}



- (IBAction)transfers:(id)sender {
	[[WCTransfers transfers] showWindow:sender];
}



- (IBAction)chatHistory:(id)sender {
	[[WCChatHistory chatHistory] showWindow:sender];
}


- (IBAction)nextConnection:(id)sender {
	[[WCPublicChat publicChat] nextConnection:sender];
}



- (IBAction)previousConnection:(id)sender {
	[[WCPublicChat publicChat] previousConnection:sender];
}



#pragma mark -

- (IBAction)toggleUserList:(id)sender {
    [[WCPublicChat publicChat] toggleUserList:sender];
}

- (IBAction)toggleServersList:(id)sender {
    [[WCPublicChat publicChat] toggleServersList:sender];
}

- (IBAction)toggleTabBar:(id)sender {
    [[WCPublicChat publicChat] toggleTabBar:sender];
}




#pragma mark -

- (IBAction)releaseNotes:(id)sender {
	NSString		*path;
	
	path = [[self bundle] pathForResource:@"wiredclientrnote" ofType:@"html"];
	
	[[WIReleaseNotesController releaseNotesController]
		setReleaseNotesWithHTML:[NSData dataWithContentsOfFile:path]];
	[[WIReleaseNotesController releaseNotesController] showWindow:self];
}



- (IBAction)crashReports:(id)sender {
	[[WICrashReportsController crashReportsController] setApplicationName:[NSApp name]];
	[[WICrashReportsController crashReportsController] showWindow:self];
}



- (IBAction)manual:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://wired.read-write.fr/wiki/"]];
}


- (IBAction)support:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/nark/WiredClient/issues?milestone=1&state=open"]];
}

@end
