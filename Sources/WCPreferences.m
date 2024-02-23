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

#import "WCApplicationController.h"
#import "WCChatHistory.h"
#import "WCKeychain.h"
#import "WCPreferences.h"

#define WC_ICON_SIZE 64.0f

#define WCThemePboardType									@"WCThemePboardType"
#define WCBookmarkPboardType								@"WCBookmarkPboardType"
#define WCHighlightPboardType								@"WCHighlightPboardType"
#define WCIgnorePboardType									@"WCIgnorePboardType"
#define WCTrackerBookmarkPboardType							@"WCTrackerBookmarkPboardType"


NSString * const WCPreferencesDidChangeNotification			= @"WCPreferencesDidChangeNotification";
NSString * const WCThemeDidChangeNotification				= @"WCThemeDidChangeNotification";
NSString * const WCSelectedThemeDidChangeNotification		= @"WCSelectedThemeDidChangeNotification";
NSString * const WCChatLogsFolderPathChangedNotification	= @"WCChatLogsFolderPathChangedNotification";
NSString * const WCBookmarksDidChangeNotification			= @"WCBookmarksDidChangeNotification";
NSString * const WCBookmarkDidChangeNotification			= @"WCBookmarkDidChangeNotification";
NSString * const WCIgnoresDidChangeNotification				= @"WCIgnoresDidChangeNotification";
NSString * const WCTrackerBookmarksDidChangeNotification	= @"WCTrackerBookmarksDidChangeNotification";
NSString * const WCTrackerBookmarkDidChangeNotification		= @"WCTrackerBookmarkDidChangeNotification";
NSString * const WCNickDidChangeNotification				= @"WCNickDidChangeNotification";
NSString * const WCStatusDidChangeNotification				= @"WCStatusDidChangeNotification";
NSString * const WCIconDidChangeNotification				= @"WCIconDidChangeNotification";


@interface WCPreferences(Private)

- (void)_validate;

- (void)_bookmarkDidChange:(NSDictionary *)bookmark;

- (void)_reloadTheme;
- (void)_reloadChatLogsFolder;
- (void)_reloadEvents;
- (void)_reloadEvent;
- (void)_updateEventControls;
- (void)_reloadDownloadFolder;

- (void)_savePasswordForBookmark:(NSArray *)arguments;
- (void)_savePasswordForTrackerBookmark:(NSArray *)arguments;

@end


@implementation WCPreferences(Private)

- (void)_validate {
	[_deleteHighlightButton setEnabled:([_highlightsTableView selectedRow] >= 0)];
	[_deleteIgnoreButton setEnabled:([_ignoresTableView selectedRow] >= 0)];
}



#pragma mark -

- (void)_bookmarkDidChange:(NSDictionary *)bookmark {
	[[NSNotificationCenter defaultCenter] postNotificationName:WCBookmarkDidChangeNotification object:bookmark];
	[[NSNotificationCenter defaultCenter] postNotificationName:WCBookmarksDidChangeNotification];
}




#pragma mark -

- (void)_updateTheme:(NSMutableDictionary *)theme {
  [theme setObject:WIStringFromColor([_themesChatEventsColorWell color]) forKey:WCThemesChatEventsColor];
  [theme setObject:WIStringFromColor([_themesChatTimestampEveryLineColorWell color]) forKey:WCThemesChatTimestampEveryLineColor];
  [theme setObject:WIStringFromColor([_themesChatURLsColorWell color]) forKey:WCThemesChatURLsColor];
  [theme setBool:[_themesShowSmileysButton state] forKey:WCThemesShowSmileys];
  [theme setBool:[_themesChatTimestampEveryLineButton state] forKey:WCThemesChatTimestampEveryLine];
  [theme setInteger:[_themesUserListIconSizeMatrix selectedTag] forKey:WCThemesUserListIconSize];
  [theme setBool:[_themesUserListAlternateRowsButton state] forKey:WCThemesUserListAlternateRows];
  
  [theme setInteger:[_themesFileListIconSizeMatrix selectedTag] forKey:WCThemesFileListIconSize];
  [theme setBool:[_themesFileListAlternateRowsButton state] forKey:WCThemesFileListAlternateRows];
  
  [theme setBool:[_themesTransferListShowProgressBarButton state] forKey:WCThemesTransferListShowProgressBar];
  [theme setBool:[_themesTransferListAlternateRowsButton state] forKey:WCThemesTransferListAlternateRows];
  
  [theme setBool:[_themesTrackerListAlternateRowsButton state] forKey:WCThemesTrackerListAlternateRows];

  [theme setInteger:[_themesMonitorIconSizeMatrix selectedTag] forKey:WCThemesMonitorIconSize];
  [theme setBool:[_themesMonitorAlternateRowsButton state] forKey:WCThemesMonitorAlternateRows];
}


- (NSDictionary *)_selectedTheme {
    NSString        *identifier;
    NSDictionary    *theme;
    
    identifier  = [[WCSettings settings] objectForKey:WCTheme];
    theme       = [[WCSettings settings] themeWithIdentifier:identifier];
    
    return theme;
}



- (void)_reloadTheme {
	NSDictionary	*theme;

    theme = [[WCSettings settings] themeWithName:@"Wired"];
		
    [_themesChatFontTextField setStringValue:[WIFontFromString([theme objectForKey:WCThemesChatFont]) displayNameWithSize]];
    [_themesChatTextColorWell setColor:WIColorFromString([theme objectForKey:WCThemesChatTextColor])];
    [_themesChatBackgroundColorWell setColor:WIColorFromString([theme objectForKey:WCThemesChatBackgroundColor])];
    [_themesChatEventsColorWell setColor:WIColorFromString([theme objectForKey:WCThemesChatEventsColor])];
    [_themesChatTimestampEveryLineColorWell setColor:WIColorFromString([theme objectForKey:WCThemesChatTimestampEveryLineColor])];
    [_themesChatURLsColorWell setColor:WIColorFromString([theme objectForKey:WCThemesChatURLsColor])];

    [_themesMessagesFontTextField setStringValue:[WIFontFromString([theme objectForKey:WCThemesMessagesFont]) displayNameWithSize]];
    [_themesMessagesTextColorWell setColor:WIColorFromString([theme objectForKey:WCThemesMessagesTextColor])];
    [_themesMessagesBackgroundColorWell setColor:WIColorFromString([theme objectForKey:WCThemesMessagesBackgroundColor])];

    [_themesBoardsFontTextField setStringValue:[WIFontFromString([theme objectForKey:WCThemesBoardsFont]) displayNameWithSize]];
    [_themesBoardsTextColorWell setColor:WIColorFromString([theme objectForKey:WCThemesBoardsTextColor])];
    [_themesBoardsBackgroundColorWell setColor:WIColorFromString([theme objectForKey:WCThemesBoardsBackgroundColor])];

    [_themesShowSmileysButton setState:[theme boolForKey:WCThemesShowSmileys]];

    [_themesChatTimestampEveryLineButton setState:[theme boolForKey:WCThemesChatTimestampEveryLine]];
    
    [_themesUserListIconSizeMatrix selectCellWithTag:[theme integerForKey:WCThemesUserListIconSize]];
    [_themesUserListAlternateRowsButton setState:[theme boolForKey:WCThemesUserListAlternateRows]];
    
    [_themesFileListIconSizeMatrix selectCellWithTag:[theme integerForKey:WCThemesFileListIconSize]];
    [_themesFileListAlternateRowsButton setState:[theme boolForKey:WCThemesFileListAlternateRows]];
    
    [_themesTransferListShowProgressBarButton setState:[theme boolForKey:WCThemesTransferListShowProgressBar]];
    [_themesTransferListAlternateRowsButton setState:[theme boolForKey:WCThemesTransferListAlternateRows]];
    
    [_themesTrackerListAlternateRowsButton setState:[theme boolForKey:WCThemesTrackerListAlternateRows]];
    
    [_themesMonitorIconSizeMatrix selectCellWithTag:[theme integerForKey:WCThemesMonitorIconSize]];
    [_themesMonitorAlternateRowsButton setState:[theme boolForKey:WCThemesMonitorAlternateRows]];
}







- (void)_reloadChatLogsFolder {
	NSString		*chatLogsFolder;
	NSImage			*icon;
	
	chatLogsFolder = [[WCApplicationController sharedController] chatLogsPath];
	
	[_chatLogsFolderMenuItem setTitle:[[NSFileManager defaultManager] displayNameAtPath:chatLogsFolder]];
	
	icon = [[NSWorkspace sharedWorkspace] iconForFile:chatLogsFolder];
	[icon setSize:NSMakeSize(12.0, 12.0)];
	
	[_chatLogsFolderMenuItem setImage:icon];
}





- (void)_reloadEvents {
	NSDictionary			*events;
	NSArray					*orderedEvents;
	NSEnumerator			*enumerator;
	NSDictionary			*event;
	NSString				*path;
	NSMenuItem				*item;
	NSNumber				*eventTag;
	
	[_eventsSoundsPopUpButton removeAllItems];

    // TODO: Tried to replace it but didn't worked 
	enumerator = [[WCApplicationController systemSounds] objectEnumerator];

	while((path = [enumerator nextObject]))
		[_eventsSoundsPopUpButton addItemWithTitle:[[path lastPathComponent] stringByDeletingPathExtension]];

	[_eventsEventPopUpButton removeAllItems];
	
	events = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		NSLS(@"Server Connected", @"Event"),
			[NSNumber numberWithInt:WCEventsServerConnected],
		NSLS(@"Server Disconnected", @"Event"),
			[NSNumber numberWithInt:WCEventsServerDisconnected],
		NSLS(@"Error", @"Event"),
			[NSNumber numberWithInt:WCEventsError],
		NSLS(@"User Joined", @"Event"),
			[NSNumber numberWithInt:WCEventsUserJoined],
		NSLS(@"User Changed Nick", @"Event"),
			[NSNumber numberWithInt:WCEventsUserChangedNick],
		NSLS(@"User Changed Status", @"Event"),
			[NSNumber numberWithInt:WCEventsUserChangedStatus],
		NSLS(@"User Left", @"Event"),
			[NSNumber numberWithInt:WCEventsUserLeft],
		NSLS(@"Chat Received", @"Event"),
			[NSNumber numberWithInt:WCEventsChatReceived],
		NSLS(@"Chat Sent", @"Event"),
			[NSNumber numberWithInt:WCEventsChatSent],
		NSLS(@"Highlighted Chat Received", @"Event"),
			[NSNumber numberWithInt:WCEventsHighlightedChatReceived],
		NSLS(@"Private Chat Invitation Received", @"Event"),
			[NSNumber numberWithInt:WCEventsChatInvitationReceived],
		NSLS(@"Message Received", @"Event"),
			[NSNumber numberWithInt:WCEventsMessageReceived],
		NSLS(@"Broadcast Received", @"Event"),
			[NSNumber numberWithInt:WCEventsBroadcastReceived],
		NSLS(@"Board Post Added", @"Event"),
			[NSNumber numberWithInt:WCEventsBoardPostReceived],
		NSLS(@"Transfer Started", @"Event"),
			[NSNumber numberWithInt:WCEventsTransferStarted],
		NSLS(@"Transfer Finished", @"Event"),
			[NSNumber numberWithInt:WCEventsTransferFinished],
		NULL];
	
	orderedEvents = [NSArray arrayWithObjects:
		[NSNumber numberWithInt:WCEventsServerConnected],
		[NSNumber numberWithInt:WCEventsServerDisconnected],
		[NSNumber numberWithInt:WCEventsError],
		[NSNumber numberWithInt:0],
		[NSNumber numberWithInt:WCEventsUserJoined],
		[NSNumber numberWithInt:WCEventsUserChangedNick],
		[NSNumber numberWithInt:WCEventsUserChangedStatus],
		[NSNumber numberWithInt:WCEventsUserLeft],
		[NSNumber numberWithInt:WCEventsChatReceived],
		[NSNumber numberWithInt:WCEventsChatSent],
		[NSNumber numberWithInt:WCEventsHighlightedChatReceived],
		[NSNumber numberWithInt:WCEventsChatInvitationReceived],
		[NSNumber numberWithInt:WCEventsMessageReceived],
		[NSNumber numberWithInt:WCEventsBroadcastReceived],
		[NSNumber numberWithInt:WCEventsBoardPostReceived],
		[NSNumber numberWithInt:0],
		[NSNumber numberWithInt:WCEventsTransferStarted],
		[NSNumber numberWithInt:WCEventsTransferFinished],
		NULL];
	
	enumerator = [orderedEvents objectEnumerator];
	
	while((eventTag = [enumerator nextObject])) {
		if([eventTag intValue] > 0) {
			event = [[WCSettings settings] eventWithTag:[eventTag intValue]];

			item = [NSMenuItem itemWithTitle:[events objectForKey:eventTag]];
			[item setTag:[eventTag intValue]];

			if([event boolForKey:WCEventsPlaySound]  || [event boolForKey:WCEventsBounceInDock] ||
			   [event boolForKey:WCEventsPostInChat] || [event boolForKey:WCEventsShowDialog])
				[item setImage:[NSImage imageNamed:@"EventOn"]];
			else
				[item setImage:[NSImage imageNamed:@"EventOff"]];
			
			[[_eventsEventPopUpButton menu] addItem:item];
		} else {
			[[_eventsEventPopUpButton menu] addItem:[NSMenuItem separatorItem]];
		}
	}
}



- (void)_reloadEvent {
	NSDictionary	*event;
	NSString		*sound;
	NSInteger		tag;
	
	tag		= [_eventsEventPopUpButton tagOfSelectedItem];
	event	= [[WCSettings settings] eventWithTag:tag];
	
	[_eventsPlaySoundButton setState:[event boolForKey:WCEventsPlaySound]];
	
	sound = [event objectForKey:WCEventsSound];
	
	if(sound && [_eventsSoundsPopUpButton indexOfItemWithTitle:sound] != -1)
		[_eventsSoundsPopUpButton selectItemWithTitle:sound];
	else if ([_eventsSoundsPopUpButton numberOfItems] > 0)
		[_eventsSoundsPopUpButton selectItemAtIndex:0];

	[_eventsBounceInDockButton setState:[event boolForKey:WCEventsBounceInDock]];
	[_eventsPostInChatButton setState:[event boolForKey:WCEventsPostInChat]];
	[_eventsShowDialogButton setState:[event boolForKey:WCEventsShowDialog]];
	[_eventsNotificationCenterButton setState:[event boolForKey:WCEventsNotificationCenter]];
    
	if(tag == WCEventsUserJoined || tag == WCEventsUserChangedNick ||
	   tag == WCEventsUserLeft || tag == WCEventsUserChangedStatus)
		[_eventsPostInChatButton setEnabled:YES];
	else
		[_eventsPostInChatButton setEnabled:NO];

	if(tag == WCEventsMessageReceived || tag == WCEventsBroadcastReceived)
		[_eventsShowDialogButton setEnabled:YES];
	else
		[_eventsShowDialogButton setEnabled:NO];

	[self _updateEventControls];
}



- (void)_updateEventControls {
	if([_eventsPlaySoundButton state] == NSOnState || [_eventsBounceInDockButton state] == NSOnState ||
	   [_eventsPostInChatButton state] == NSOnState || [_eventsShowDialogButton state] == NSOnState)
		[[_eventsEventPopUpButton selectedItem] setImage:[NSImage imageNamed:@"EventOn"]];
	else
		[[_eventsEventPopUpButton selectedItem] setImage:[NSImage imageNamed:@"EventOff"]];
	
	[_eventsSoundsPopUpButton setEnabled:[_eventsPlaySoundButton state]];
}



- (void)_reloadDownloadFolder {
	NSString		*downloadFolder;
	NSImage			*icon;
	
	downloadFolder = [[[WCSettings settings] objectForKey:WCDownloadFolder] stringByStandardizingPath];
	
	[_filesDownloadFolderMenuItem setTitle:[[NSFileManager defaultManager] displayNameAtPath:downloadFolder]];
	
	icon = [[NSWorkspace sharedWorkspace] iconForFile:downloadFolder];
	[icon setSize:NSMakeSize(16.0, 16.0)];
	
	[_filesDownloadFolderMenuItem setImage:icon];
}



#pragma mark -

- (void)_savePasswordForBookmark:(NSArray *)arguments {
	NSDictionary		*oldBookmark = [arguments objectAtIndex:0];
	NSDictionary		*bookmark = [arguments objectAtIndex:1];
	NSString			*password = [arguments objectAtIndex:2];

	if(![oldBookmark isEqual:bookmark])
		[[WCKeychain keychain] deletePasswordForBookmark:oldBookmark];
	
	if([_bookmarksPassword length] > 0)
		[[WCKeychain keychain] setPassword:password forBookmark:bookmark];
	else
		[[WCKeychain keychain] deletePasswordForBookmark:bookmark];
}



- (void)_savePasswordForTrackerBookmark:(NSArray *)arguments {
	NSDictionary		*oldBookmark = [arguments objectAtIndex:0];
	NSDictionary		*bookmark = [arguments objectAtIndex:1];
	NSString			*password = [arguments objectAtIndex:2];
	
	if(![oldBookmark isEqual:bookmark])
		[[WCKeychain keychain] deletePasswordForTrackerBookmark:oldBookmark];
	
	if([password length] > 0)
		[[WCKeychain keychain] setPassword:password forTrackerBookmark:bookmark];
	else
		[[WCKeychain keychain] deletePasswordForTrackerBookmark:bookmark];
}

@end


@implementation WCPreferences

#pragma mark -

+ (WCPreferences *)preferences {
	static id	sharedPreferences;

	if(!sharedPreferences)
		sharedPreferences = [[self alloc] init];

	return sharedPreferences;
}




#pragma mark -


- (id)init {
	self = [super initWithWindowNibName:@"Preferences"];
	
	_privateTemplateManager	= [[WITemplateBundleManager templateManagerForPath:[[NSBundle mainBundle] resourcePath]] retain];
	_publicTemplateManager	= [[WITemplateBundleManager templateManagerForPath:[WCApplicationSupportPath stringByStandardizingPath] isPrivate:NO] retain];
	
	[self window];
    
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		   selector:@selector(themeDidChange:)
			   name:WCThemeDidChangeNotification];

	[[NSNotificationCenter defaultCenter]
		addObserver:self
		   selector:@selector(bookmarksDidChange:)
			   name:WCBookmarksDidChangeNotification];

	[[NSNotificationCenter defaultCenter]
		addObserver:self
		   selector:@selector(ignoresDidChange:)
			   name:WCIgnoresDidChangeNotification];

	[[NSNotificationCenter defaultCenter]
		addObserver:self
		   selector:@selector(trackerBookmarksDidChange:)
			   name:WCTrackerBookmarksDidChangeNotification];

	return self;
}



- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[_privateTemplateManager release];
	[_publicTemplateManager release];
	
	[super dealloc];
}



#pragma mark -

- (void)windowDidLoad {
    
	[self addPreferenceView:_generalView
					   name:NSLS(@"General", @"General preferences")
					  image:[NSImage imageNamed:@"General"]];

	[self addPreferenceView:_appearanceView
					   name:NSLS(@"Appearance", @"Appearance preferences")
					  image:[NSImage imageNamed:@"Appearance"]];
	
	[self addPreferenceView:_chatView
					   name:NSLS(@"Chat", @"Chat preferences")
					  image:[NSImage imageNamed:@"Chat"]];
	
	[self addPreferenceView:_eventsView
					   name:NSLS(@"Events", @"Events preferences")
					  image:[NSImage imageNamed:@"Events"]];
	
	[self addPreferenceView:_filesView
					   name:NSLS(@"Files", @"Files preferences")
					  image:[NSImage imageNamed:@"Folder"]];
	
    [self addPreferenceView:_advancedView
					   name:NSLS(@"Advanced", @"Advanced preferences")
					  image:[NSImage imageNamed:@"NSAdvanced"]];
    
	[_iconImageView setMaxImageSize:NSMakeSize(WC_ICON_SIZE, WC_ICON_SIZE)];
	[_iconImageView setDefaultImage:[NSImage imageNamed:@"DefaultIcon"]];
	
	[_chatTabView selectFirstTabViewItem:self];
	
	[_highlightsTableView setTarget:self];
	[_highlightsTableView setDoubleAction:@selector(changeHighlightColor:)];
	
	[_highlightsTableView registerForDraggedTypes:[NSArray arrayWithObject:WCIgnorePboardType]];
	[_ignoresTableView registerForDraggedTypes:[NSArray arrayWithObject:WCIgnorePboardType]];
	
	//[self _reloadThemes];
	[self _reloadTheme];
	//[self _reloadTemplates];
	[self _reloadChatLogsFolder];
	[self _reloadEvents];
	[self _reloadEvent];
	[self _reloadDownloadFolder];
	
	[_nickTextField setStringValue:[[WCSettings settings] objectForKey:WCNick]];
	[_statusTextField setStringValue:[[WCSettings settings] objectForKey:WCStatus]];
	[_iconImageView setImage:[NSImage imageWithData:
		[NSData dataWithBase64EncodedString:[[WCSettings settings] objectForKey:WCIcon]]]];
	
	[_checkForUpdateButton setState:[[WCSettings settings] boolForKey:WCCheckForUpdate]];
	[_showConnectAtStartupButton setState:[[WCSettings settings] boolForKey:WCShowConnectAtStartup]];
	[_showServersAtStartupButton setState:[[WCSettings settings] boolForKey:WCShowServersAtStartup]];
	[_confirmDisconnectButton setState:[[WCSettings settings] boolForKey:WCConfirmDisconnect]];
	[_autoReconnectButton setState:[[WCSettings settings] boolForKey:WCAutoReconnect]];
    [_orderFrontOnDisconnectButton setState:[[WCSettings settings] boolForKey:WCOrderFrontWhenDisconnected]];
    
    [_threadsSplitViewMatrix selectCellWithTag:[[WCSettings settings] intForKey:WCThreadsSplitViewOrientation]];
	
	[_chatHistoryScrollbackButton setState:[[WCSettings settings] boolForKey:WCChatHistoryScrollback]];
	[_chatHistoryScrollbackModifierPopUpButton selectItemWithTag:[[WCSettings settings] integerForKey:WCChatHistoryScrollbackModifier]];
	[_chatTabCompleteNicksButton setState:[[WCSettings settings] boolForKey:WCChatTabCompleteNicks]];
	[_chatTabCompleteNicksTextField setStringValue:[[WCSettings settings] objectForKey:WCChatTabCompleteNicksString]];
	[_chatTimestampChatButton setState:[[WCSettings settings] boolForKey:WCChatTimestampChat]];
	[_chatTimestampChatIntervalTextField setStringValue:[NSSWF:@"%.0f", [[WCSettings settings] doubleForKey:WCChatTimestampChatInterval] / 60.0]];
	[_chatHistoryButton setState:[[WCSettings settings] boolForKey:WCChatLogsHistoryEnabled]];
	[_chatLogsButton setState:[[WCSettings settings] boolForKey:WCChatLogsPlainTextEnabled]];
	[_chatAllowEmbedHTMLButton setState:[[WCSettings settings] boolForKey:WCChatEmbedHTMLInChatEnabled]];
	[_chatAnimatedImagesButton setState:[[WCSettings settings] boolForKey:WCChatAnimatedImagesEnabled]];
	
	[_eventsVolumeSlider setFloatValue:[[WCSettings settings] floatForKey:WCEventsVolume]];

	[_filesOpenFoldersInNewWindowsButton setState:[[WCSettings settings] boolForKey:WCOpenFoldersInNewWindows]];
	[_filesQueueTransfersButton setState:[[WCSettings settings] boolForKey:WCQueueTransfers]];
	[_filesRemoveTransfersButton setState:[[WCSettings settings] boolForKey:WCRemoveTransfers]];
    
    [_networkConnectionTimeoutTextField setStringValue:[NSSWF:@"%d", [[WCSettings settings] intForKey:WCNetworkConnectionTimeout]]];
    [_networkReadTimeoutTextField setStringValue:[NSSWF:@"%d", [[WCSettings settings] intForKey:WCNetworkReadTimeout]]];
    [_networkCompressionButton setState:[[WCSettings settings] boolForKey:WCNetworkCompressionEnabled]];
    
	[self _validate];
	
	[super windowDidLoad];
}



- (void)themeDidChange:(NSNotification *)notification {
	NSDictionary	*theme;
	
	theme = [notification object];
    
	if([[theme objectForKey:WCThemesIdentifier] isEqualToString:[[WCSettings settings] objectForKey:WCTheme]])
		[[NSNotificationCenter defaultCenter] postNotificationName:WCSelectedThemeDidChangeNotification object:theme];
    
    [self _reloadTheme];
}



- (void)bookmarksDidChange:(NSNotification *)notification {

}



- (void)ignoresDidChange:(NSNotification *)notification {
	[_ignoresTableView reloadData];
}



- (void)trackerBookmarksDidChange:(NSNotification *)notification {

}



- (void)controlTextDidChange:(NSNotification *)notification {

}


- (void)controlTextDidEndEditing:(NSNotification *)notification {
    id			object;
	
	object = [notification object];
    
    if(object == _networkConnectionTimeoutTextField || object == _networkReadTimeoutTextField) {
        [self changeNetwork:object];
    }
}




#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem *)item {
	SEL		selector;
	
	selector = [item action];
	
	if(selector == @selector(exportBookmarks:))
		return ([[[WCSettings settings] objectForKey:WCBookmarks] count] > 0);
    
	else if(selector == @selector(exportTrackerBookmarks:))
		return ([[[WCSettings settings] objectForKey:WCTrackerBookmarks] count] > 0);
	
	return YES;
}




#pragma mark -

- (BOOL)importBookmarksFromFile:(NSString *)path {
	NSEnumerator			*enumerator;
	NSArray					*array;
	NSMutableDictionary		*bookmark;
	NSDictionary			*dictionary;
	NSString				*password;
	NSUInteger				firstIndex;
	
	array = [NSArray arrayWithContentsOfFile:path];
	
	if(!array || [array count] == 0)
		return NO;
	
	firstIndex = NSNotFound;
	enumerator = [array objectEnumerator];
	
	while((dictionary = [enumerator nextObject])) {
		bookmark = [[dictionary mutableCopy] autorelease];
		
		if(![bookmark objectForKey:WCBookmarksName])
			continue;
		
		[bookmark setObject:[NSString UUIDString] forKey:WCBookmarksIdentifier];
		
		password = [bookmark objectForKey:WCBookmarksPassword];
		
		if(password) {
			[[WCKeychain keychain] setPassword:password forBookmark:bookmark];
			
			[bookmark removeObjectForKey:WCBookmarksPassword];
		}
		
		[[WCSettings settings] addObject:bookmark toArrayForKey:WCBookmarks];
		
		if(firstIndex == NSNotFound)
			firstIndex = [[[WCSettings settings] objectForKey:WCBookmarks] count] - 1;
	}
    
    [[NSNotificationCenter defaultCenter] postNotificationName:WCBookmarksDidChangeNotification];
	
	return YES;
}



- (BOOL)importTrackerBookmarksFromFile:(NSString *)path {
	NSEnumerator			*enumerator;
	NSArray					*array;
	NSMutableDictionary		*bookmark;
	NSDictionary			*dictionary;
	NSString				*password;
	NSUInteger				firstIndex;

	array = [NSArray arrayWithContentsOfFile:path];

	if(!array || [array count] == 0)
		return NO;

	firstIndex = NSNotFound;
	enumerator = [array objectEnumerator];

	while((dictionary = [enumerator nextObject])) {
		bookmark = [[dictionary mutableCopy] autorelease];
		
		if(![bookmark objectForKey:WCTrackerBookmarksName])
			continue;
		
		[bookmark setObject:[NSString UUIDString] forKey:WCTrackerBookmarksIdentifier];
		
		password = [bookmark objectForKey:WCTrackerBookmarksPassword];
		
		if(password) {
			[[WCKeychain keychain] setPassword:password forTrackerBookmark:bookmark];
			
			[bookmark removeObjectForKey:WCTrackerBookmarksPassword];
		}
		
		[[WCSettings settings] addObject:bookmark toArrayForKey:WCTrackerBookmarks];
		
		if(firstIndex == NSNotFound)
			firstIndex = [[[WCSettings settings] objectForKey:WCBookmarks] count] - 1;
	}
    
    [[NSNotificationCenter defaultCenter] postNotificationName:WCBookmarksDidChangeNotification];
	
	return YES;
}


#pragma mark -

- (IBAction)changePreferences:(id)sender {
	NSImage		*image;
	NSString	*string;
	
	if(![[_nickTextField stringValue] isEqualToString:[[WCSettings settings] objectForKey:WCNick]]) {
		[[WCSettings settings] setObject:[_nickTextField stringValue] forKey:WCNick];
        
		[[NSNotificationCenter defaultCenter] postNotificationName:WCNickDidChangeNotification];
	}
	
	if(![[_statusTextField stringValue] isEqualToString:[[WCSettings settings] objectForKey:WCStatus]]) {
		[[WCSettings settings] setObject:[_statusTextField stringValue] forKey:WCStatus];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:WCStatusDidChangeNotification];
	}
	
	image = [_iconImageView image];
	
	if(image) {
		string = [[[NSBitmapImageRep imageRepWithData:[image TIFFRepresentation]] representationUsingType:NSPNGFileType properties:@{}]
			base64EncodedString];
		
		if(!string)
			string = @"";
	} else {
		string	= @"";
	}

	if(![string isEqualToString:[[WCSettings settings] objectForKey:WCIcon]]) {
		[[WCSettings settings] setObject:string forKey:WCIcon];
		[[NSNotificationCenter defaultCenter] postNotificationName:WCIconDidChangeNotification];
	}

	[[WCSettings settings] setBool:[_checkForUpdateButton state] forKey:WCCheckForUpdate];
	[[WCSettings settings] setBool:[_showConnectAtStartupButton state] forKey:WCShowConnectAtStartup];
	[[WCSettings settings] setBool:[_showServersAtStartupButton state] forKey:WCShowServersAtStartup];
	[[WCSettings settings] setBool:[_confirmDisconnectButton state] forKey:WCConfirmDisconnect];
	[[WCSettings settings] setBool:[_autoReconnectButton state] forKey:WCAutoReconnect];
    [[WCSettings settings] setBool:[_orderFrontOnDisconnectButton state] forKey:WCOrderFrontWhenDisconnected];
    
    [[WCSettings settings] setInt:[_threadsSplitViewMatrix selectedTag] forKey:WCThreadsSplitViewOrientation];
    
	[[WCSettings settings] setBool:[_chatHistoryScrollbackButton state] forKey:WCChatHistoryScrollback];
	[[WCSettings settings] setInt:[_chatHistoryScrollbackModifierPopUpButton tagOfSelectedItem] forKey:WCChatHistoryScrollbackModifier];
    
	[[WCSettings settings] setBool:[_chatTabCompleteNicksButton state] forKey:WCChatTabCompleteNicks];
	[[WCSettings settings] setObject:[_chatTabCompleteNicksTextField stringValue] forKey:WCChatTabCompleteNicksString];
	[[WCSettings settings] setBool:[_chatTimestampChatButton state] forKey:WCChatTimestampChat];
	[[WCSettings settings] setInt:[_chatTimestampChatIntervalTextField intValue] * 60 forKey:WCChatTimestampChatInterval];
	[[WCSettings settings] setBool:[_chatHistoryButton state] forKey:WCChatLogsHistoryEnabled];
	[[WCSettings settings] setBool:[_chatLogsButton state] forKey:WCChatLogsPlainTextEnabled];
	[[WCSettings settings] setBool:[_chatAllowEmbedHTMLButton state] forKey:WCChatEmbedHTMLInChatEnabled];
	[[WCSettings settings] setBool:[_chatAnimatedImagesButton state] forKey:WCChatAnimatedImagesEnabled];
		
	[[WCSettings settings] setBool:[_filesOpenFoldersInNewWindowsButton state] forKey:WCOpenFoldersInNewWindows];
	[[WCSettings settings] setBool:[_filesQueueTransfersButton state] forKey:WCQueueTransfers];
	[[WCSettings settings] setBool:[_filesRemoveTransfersButton state] forKey:WCRemoveTransfers];
	
	[[WCSettings settings] setFloat:[_eventsVolumeSlider floatValue] forKey:WCEventsVolume];

	[[NSNotificationCenter defaultCenter] postNotificationName:WCPreferencesDidChangeNotification];
}

- (IBAction)changeNetwork:(id)sender {
    [[WCSettings settings] setInteger:[_networkConnectionTimeoutTextField integerValue] forKey:WCNetworkConnectionTimeout];
    [[WCSettings settings] setInteger:[_networkReadTimeoutTextField integerValue] forKey:WCNetworkReadTimeout];
    [[WCSettings settings] setBool:[_networkCompressionButton state] forKey:WCNetworkCompressionEnabled];
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:NSLS(@"Network Settings Changed", @"")];
    [alert addButtonWithTitle:@"OK"];
    [alert setInformativeText:NSLS(@"This change cannot be applied to already active connections. Change will only take effect for newly initiated connections.", @"")];
    [alert runModal];
                                   
                                   
    [[NSNotificationCenter defaultCenter] postNotificationName:WCPreferencesDidChangeNotification];
}



#pragma mark -

- (IBAction)changeTheme:(id)sender {
    NSMutableDictionary     *theme;
    
    theme = [[[[WCSettings settings] themeWithName:@"Wired"] mutableCopy] autorelease];
    
    [self _updateTheme:theme];
    
    [[WCSettings settings] setObject:[NSArray arrayWithObject:theme] forKey:WCThemes];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:WCThemeDidChangeNotification object:theme];
}



- (NSUInteger)_selectedThemeRow {
    // Implementierung der Methode hier
    return 0; // Beispielrückgabewert, passen Sie ihn entsprechend an
}

- (IBAction)changeThemeFont:(id)sender {
    NSDictionary *theme;
    NSFontManager *fontManager;
    
    // Konvertierung des Rückgabewerts von [self _selectedThemeRow] in NSUInteger
    NSUInteger selectedThemeRow = (NSUInteger)[self _selectedThemeRow];
    
    theme = [[[WCSettings settings] objectForKey:WCThemes] objectAtIndex:selectedThemeRow];
    fontManager = [NSFontManager sharedFontManager];
    
    [fontManager setTarget:self];
    
    if(sender == _themesChatFontButton) {
        [fontManager setSelectedFont:WIFontFromString([theme objectForKey:WCThemesChatFont]) isMultiple:NO];
        [fontManager setAction:@selector(setChatFont:)];
    }
    else if(sender == _themesMessagesFontButton) {
        [fontManager setSelectedFont:WIFontFromString([theme objectForKey:WCThemesMessagesFont]) isMultiple:NO];
        [fontManager setAction:@selector(setMessagesFont:)];
    }
    else if(sender == _themesBoardsFontButton) {
        [fontManager setSelectedFont:WIFontFromString([theme objectForKey:WCThemesBoardsFont]) isMultiple:NO];
        [fontManager setAction:@selector(setBoardsFont:)];
    }
    
    [fontManager orderFrontFontPanel:self];
}



- (void)setChatFont:(id)sender {
	NSMutableDictionary		*theme;
	NSFont					*font, *newFont;
	    
    theme = [[[[WCSettings settings] themeWithName:@"Wired"] mutableCopy] autorelease];
    font        = WIFontFromString([theme objectForKey:WCThemesChatFont]);
    newFont     = [sender convertFont:font];
    
    [theme setObject:WIStringFromFont(newFont) forKey:WCThemesChatFont];
    
    [[WCSettings settings] setObject:[NSArray arrayWithObject:theme] forKey:WCThemes];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:WCThemeDidChangeNotification object:theme];
}



- (void)setMessagesFont:(id)sender {
    NSMutableDictionary        *theme;
    NSFont                    *font, *newFont;
        
    theme = [[[[WCSettings settings] themeWithName:@"Wired"] mutableCopy] autorelease];
    font        = WIFontFromString([theme objectForKey:WCThemesMessagesFont]);
    newFont     = [sender convertFont:font];
    
    [theme setObject:WIStringFromFont(newFont) forKey:WCThemesMessagesFont];
    
    [[WCSettings settings] setObject:[NSArray arrayWithObject:theme] forKey:WCThemes];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:WCThemeDidChangeNotification object:theme];
}



- (void)setBoardsFont:(id)sender {
    NSMutableDictionary        *theme;
    NSFont                    *font, *newFont;
        
    theme = [[[[WCSettings settings] themeWithName:@"Wired"] mutableCopy] autorelease];
    font        = WIFontFromString([theme objectForKey:WCThemesBoardsFont]);
    newFont     = [sender convertFont:font];
    
    [theme setObject:WIStringFromFont(newFont) forKey:WCThemesBoardsFont];
    
    [[WCSettings settings] setObject:[NSArray arrayWithObject:theme] forKey:WCThemes];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:WCThemeDidChangeNotification object:theme];
}




#pragma mark -

- (IBAction)exportBookmarks:(id)sender {
	__block NSSavePanel     *savePanel;
	
	savePanel = [NSSavePanel savePanel];
	[savePanel setAllowedFileTypes:[NSArray arrayWithObject:@"WiredBookmarks"]];
	[savePanel setCanSelectHiddenExtension:YES];
	[savePanel setAccessoryView:_bookmarksExportView];
    [savePanel setNameFieldStringValue:[NSLS(@"Bookmarks", @"Default export bookmarks name")
										stringByAppendingPathExtension:@"WiredBookmarks"]];
    
    [savePanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result) {
        NSEnumerator			*enumerator;
        NSMutableArray			*bookmarks;
        NSMutableDictionary		*bookmark;
        NSDictionary			*dictionary;
        NSString				*password;
        
        if(result == NSModalResponseOK) {
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







- (IBAction)importBookmarks:(id)sender {
	__block NSOpenPanel     *openPanel;
	
	openPanel = [NSOpenPanel openPanel];
    
	[openPanel setCanChooseFiles:YES];
	[openPanel setCanChooseDirectories:NO];
    [openPanel setAllowedFileTypes:[NSArray arrayWithObject:@"WiredBookmarks"]];
    
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result) {
        if(result == NSModalResponseOK)
            [self importBookmarksFromFile:[[openPanel URL] path]];
    }];
}






- (IBAction)chatRevealChatHistory:(id)sender {
	[[WCChatHistory chatHistory] showWindow:sender];
}


- (IBAction)chatRevealChatLogs:(id)sender {
	NSString *chatLogsPath = [[WCApplicationController sharedController] chatLogsPath];
	[[NSWorkspace sharedWorkspace] openFile:chatLogsPath 
							withApplication:@"Finder"];
}


- (IBAction)otherChatLogsFolder:(id)sender {
	__block NSOpenPanel		*openPanel;
	
	openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseFiles:NO];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setCanCreateDirectories:YES];
	[openPanel setTitle:NSLS(@"Select Chat Logs Folder", @"Select chatlogs folder dialog title")];
	[openPanel setPrompt:NSLS(@"Select", @"Select chatlogs folder dialog button title")];
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:[[WCApplicationController sharedController] chatLogsPath]]];
    
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result) {
        if(result == NSModalResponseOK) {
            [[WCSettings settings] setObject:[[openPanel URL] path] forKey:WCChatLogsPath];
            
            [[WCApplicationController sharedController] performSelectorInBackground:@selector(reloadChatLogsWithPath:)
                                                                         withObject:[[openPanel URL] path]];
            
            [self _reloadChatLogsFolder];
        }
        
        [_chatLogsFolderPopUpButton selectItem:_chatLogsFolderMenuItem];
    }];
}


#pragma mark -

- (IBAction)addHighlight:(id)sender {
	NSDictionary	*highlight;
	NSColor			*color;
	NSInteger		row;
	
	row = [[[WCSettings settings] objectForKey:WCHighlights] count] - 1;
	
	if(row >= 0)
		color = WIColorFromString([[[[WCSettings settings] objectForKey:WCHighlights] objectAtIndex:row] objectForKey:WCHighlightsColor]);
	else
		color = [NSColor yellowColor];
	
	highlight = [NSDictionary dictionaryWithObjectsAndKeys:
		@"",						WCHighlightsPattern,
		WIStringFromColor(color),	WCHighlightsColor,
		NULL];
	
	[[WCSettings settings] addObject:highlight toArrayForKey:WCHighlights];

	row = [[[WCSettings settings] objectForKey:WCHighlights] count] - 1;
	
	[_highlightsTableView reloadData];
	[_highlightsTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
	[_highlightsTableView editColumn:0 row:row withEvent:NULL select:YES];
}



- (IBAction)deleteHighlight:(id)sender {
	NSAlert		*alert;
	NSInteger	row;
	
	row = [_highlightsTableView selectedRow];
    [_highlightsTableView deselectAll:nil];

	if(row < 0)
		return;

	alert = [[NSAlert alloc] init];
	[alert setMessageText:NSLS(@"Are you sure you want to delete the selected highlight?", @"Delete highlight dialog title (bookmark)")];
	[alert setInformativeText:NSLS(@"This cannot be undone.", @"Delete highlight dialog description")];
	[alert addButtonWithTitle:NSLS(@"Delete", @"Delete highlight dialog button title")];
	[alert addButtonWithTitle:NSLS(@"Cancel", @"Delete highlight button title")];
	[alert beginSheetModalForWindow:[self window]
					  modalDelegate:self
					 didEndSelector:@selector(deleteHighlightSheetDidEnd:returnCode:contextInfo:)
						contextInfo:[[NSNumber alloc] initWithInteger:row]];
	[alert release];
}



- (void)deleteHighlightSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	NSNumber	*row = contextInfo;

	if(returnCode == NSAlertFirstButtonReturn) {
		[[WCSettings settings] removeObjectAtIndex:[row integerValue] fromArrayForKey:WCHighlights];
		
		[_highlightsTableView reloadData];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:WCPreferencesDidChangeNotification];
	}
	
	[row release];
}



- (void)changeHighlightColor:(id)sender {
	NSColorPanel	*colorPanel;
	NSDictionary	*highlight;
	NSInteger		row;
	
	row = [_highlightsTableView selectedRow];
	
	if(row < 0)
		return;
	
	highlight = [[[WCSettings settings] objectForKey:WCHighlights] objectAtIndex:row];
	
	colorPanel = [NSColorPanel sharedColorPanel];
	[colorPanel setTarget:self];
	[colorPanel setAction:@selector(setHighlightColor:)];
	[colorPanel setColor:WIColorFromString([highlight objectForKey:WCHighlightsColor])];
	[colorPanel makeKeyAndOrderFront:self];
}



- (void)setHighlightColor:(id)sender {
	NSMutableDictionary		*highlight;
	NSInteger				row;
	
	if(_highlightsTableView == [[self window] firstResponder]) {
		row = [_highlightsTableView selectedRow];
		
		if(row < 0)
			return;
		
		highlight = [[[[[WCSettings settings] objectForKey:WCHighlights] objectAtIndex:row] mutableCopy] autorelease];
		[highlight setObject:WIStringFromColor([sender color]) forKey:WCHighlightsColor];

		[[WCSettings settings] replaceObjectAtIndex:row withObject:highlight inArrayForKey:WCHighlights];
		
		[_highlightsTableView reloadData];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:WCPreferencesDidChangeNotification];
	}
}



#pragma mark -

- (IBAction)addIgnore:(id)sender {
	NSDictionary	*ignore;
	NSInteger		row;
	
	ignore = [NSDictionary dictionaryWithObjectsAndKeys:
		NSLS(@"Untitled", @"Untitled ignore"),		WCIgnoresNick,
		NULL];
	
	[[WCSettings settings] addObject:ignore toArrayForKey:WCIgnores];
	
	row = [[[WCSettings settings] objectForKey:WCIgnores] count] - 1;

	[_ignoresTableView reloadData];
	[_ignoresTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
	[_ignoresTableView editColumn:0 row:row withEvent:NULL select:YES];
}



- (IBAction)deleteIgnore:(id)sender {
	NSAlert		*alert;
	NSInteger	row;

	row = [_ignoresTableView selectedRow];
    [_ignoresTableView deselectAll:nil];
    
	if(row < 0)
		return;

	alert = [[NSAlert alloc] init];
	[alert setMessageText:NSLS(@"Are you sure you want to delete the selected ignore?", @"Delete ignore dialog title (bookmark)")];
	[alert setInformativeText:NSLS(@"This cannot be undone.", @"Delete ignore dialog description")];
	[alert addButtonWithTitle:NSLS(@"Delete", @"Delete ignore dialog button title")];
	[alert addButtonWithTitle:NSLS(@"Cancel", @"Delete ignore button title")];
	[alert beginSheetModalForWindow:[self window]
					  modalDelegate:self
					 didEndSelector:@selector(deleteIgnoreSheetDidEnd:returnCode:contextInfo:)
						contextInfo:[[NSNumber alloc] initWithInteger:row]];
	[alert release];
}



- (void)deleteIgnoreSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	NSNumber	*row = contextInfo;
	
	if(returnCode == NSAlertFirstButtonReturn) {
		[[WCSettings settings] removeObjectAtIndex:[row integerValue] fromArrayForKey:WCIgnores];
		
		[_ignoresTableView reloadData];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:WCPreferencesDidChangeNotification];
	}
	
	[row release];
}



#pragma mark -

- (IBAction)selectEvent:(id)sender {
	[self _reloadEvent];
}



- (IBAction)changeEvent:(id)sender {
	NSMutableArray			*events;
	NSMutableDictionary		*event;
	NSUInteger				i, count;
	NSInteger				tag;
	
	events	= [[[[WCSettings settings] objectForKey:WCEvents] mutableCopy] autorelease];
	tag		= [_eventsEventPopUpButton tagOfSelectedItem];
	count	= [events count];
	
	for(i = 0; i < count; i++) {
		if([[events objectAtIndex:i] integerForKey:WCEventsEvent] == tag) {
			event = [[[events objectAtIndex:i] mutableCopy] autorelease];

			[event setBool:[_eventsPlaySoundButton state] forKey:WCEventsPlaySound];
			[event setObject:[_eventsSoundsPopUpButton titleOfSelectedItem] forKey:WCEventsSound];
			[event setBool:[_eventsBounceInDockButton state] forKey:WCEventsBounceInDock];
			[event setBool:[_eventsPostInChatButton state] forKey:WCEventsPostInChat];
			[event setBool:[_eventsShowDialogButton state] forKey:WCEventsShowDialog];
            [event setBool:[_eventsNotificationCenterButton state] forKey:WCEventsNotificationCenter];
			
			[events replaceObjectAtIndex:i withObject:event];
			
			break;
		}
	}
	
	[[WCSettings settings] setObject:events forKey:WCEvents];
	
	[self _updateEventControls];
    	
	if(sender == _eventsSoundsPopUpButton || (sender == _eventsPlaySoundButton && [sender state] == NSOnState))
		[NSSound playSoundNamed:[_eventsSoundsPopUpButton titleOfSelectedItem]];
}



#pragma mark -

- (IBAction)otherDownloadFolder:(id)sender {
	NSOpenPanel		*openPanel;
	openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseFiles:NO];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setCanCreateDirectories:YES];
	[openPanel setTitle:NSLS(@"Select Download Folder", @"Select download folder dialog title")];
	[openPanel setPrompt:NSLS(@"Select", @"Select download folder dialog button title")];
    
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result) {
        if(result == NSModalResponseOK) {
            [[WCSettings settings] setObject:[[openPanel URL] path] forKey:WCDownloadFolder];
            
            [self _reloadDownloadFolder];
        }
        
        [_filesDownloadFolderPopUpButton selectItem:_filesDownloadFolderMenuItem];
    }];
}






#pragma mark -

- (IBAction)exportTrackerBookmarks:(id)sender {
	__block NSSavePanel     *savePanel;
	
	savePanel = [NSSavePanel savePanel];
	[savePanel setAllowedFileTypes:[NSArray arrayWithObject:@"WiredTrackerBookmarks"]];
	[savePanel setCanSelectHiddenExtension:YES];
	[savePanel setAccessoryView:_bookmarksExportView];
    [savePanel setNameFieldStringValue:[NSLS(@"Bookmarks", @"Default export bookmarks name")
										stringByAppendingPathExtension:@"WiredTrackerBookmarks"]];
    
    [savePanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result) {
        NSEnumerator			*enumerator;
        NSMutableArray			*bookmarks;
        NSMutableDictionary		*bookmark;
        NSDictionary			*dictionary;
        NSString				*password;
        
        if(result == NSModalResponseOK) {
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





- (IBAction)importTrackerBookmarks:(id)sender {
	NSOpenPanel			*openPanel;
	
	openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseFiles:YES];
	[openPanel setCanChooseDirectories:NO];
    [openPanel setAllowedFileTypes:[NSArray arrayWithObject:@"WiredTrackerBookmarks"]];
    
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result) {
        if(result == NSModalResponseOK)
            [self importTrackerBookmarksFromFile:[[openPanel URL] path]];
    }];
}





#pragma mark -

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	if(tableView == _highlightsTableView)
		return [[[WCSettings settings] objectForKey:WCHighlights] count];
	else if(tableView == _ignoresTableView)
		return [[[WCSettings settings] objectForKey:WCIgnores] count];

	return 0;
}



- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)row {
	NSDictionary	*dictionary;
		
	if(tableView == _highlightsTableView) {
		dictionary = [[[WCSettings settings] objectForKey:WCHighlights] objectAtIndex:row];
		
		if(column == _highlightsPatternTableColumn)
			return [dictionary objectForKey:WCHighlightsPattern];
		else if(column == _highlightsColorTableColumn)
			return WIColorFromString([dictionary objectForKey:WCHighlightsColor]);
	}
	else if(tableView == _ignoresTableView) {
		dictionary = [[[WCSettings settings] objectForKey:WCIgnores] objectAtIndex:row];
		
		if(column == _ignoresNickTableColumn)
			return [dictionary objectForKey:WCIgnoresNick];
	}

	return NULL;
}



- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	return YES;
}



- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	NSMutableDictionary		*dictionary;
    
	if(tableView == _highlightsTableView) {
		dictionary = [[[[[WCSettings settings] objectForKey:WCHighlights] objectAtIndex:row] mutableCopy] autorelease];
		
		if(tableColumn == _highlightsPatternTableColumn)
			[dictionary setObject:object forKey:WCHighlightsPattern];
		
		[[WCSettings settings] replaceObjectAtIndex:row withObject:dictionary inArrayForKey:WCHighlights];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:WCPreferencesDidChangeNotification];
	}
	else if(tableView == _ignoresTableView) {
		dictionary = [[[[[WCSettings settings] objectForKey:WCIgnores] objectAtIndex:row] mutableCopy] autorelease];
		
		if(tableColumn == _ignoresNickTableColumn)
			[dictionary setObject:object forKey:WCIgnoresNick];
	
		[[WCSettings settings] replaceObjectAtIndex:row withObject:dictionary inArrayForKey:WCIgnores];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:WCPreferencesDidChangeNotification];
	}
}




- (void)tableViewSelectionDidChange:(NSNotification *)notification {
	[self _validate];
}



- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)indexes toPasteboard:(NSPasteboard *)pasteboard {
	NSUInteger		index;
	
	index = [indexes firstIndex];
	
	if(tableView == _highlightsTableView) {
		[pasteboard declareTypes:[NSArray arrayWithObject:WCHighlightPboardType] owner:NULL];
		[pasteboard setString:[NSSWF:@"%d", (int)index] forType:WCHighlightPboardType];
		
		return YES;
	}
	else if(tableView == _ignoresTableView) {
		[pasteboard declareTypes:[NSArray arrayWithObject:WCIgnorePboardType] owner:NULL];
		[pasteboard setString:[NSSWF:@"%d", (int)index] forType:WCIgnorePboardType];
		
		return YES;
	}

	return NO;
}



- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation {
	if(operation != NSTableViewDropAbove)
		return NSDragOperationNone;

	return NSDragOperationGeneric;
}



- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation {
	NSMutableArray		*array;
	NSPasteboard		*pasteboard;
	NSArray				*types;
	
	pasteboard = [info draggingPasteboard];
	types = [pasteboard types];
	
	if([types containsObject:WCHighlightPboardType]) {
		array = [[[[WCSettings settings] objectForKey:WCHighlights] mutableCopy] autorelease];
		[array moveObjectAtIndex:[[pasteboard stringForType:WCHighlightPboardType] integerValue] toIndex:row];

		[[WCSettings settings] setObject:array forKey:WCHighlights];
		
		return YES;
	}
	else if([types containsObject:WCIgnorePboardType]) {
		array = [[[[WCSettings settings] objectForKey:WCIgnores] mutableCopy] autorelease];
		[array moveObjectAtIndex:[[pasteboard stringForType:WCIgnorePboardType] integerValue] toIndex:row];

		[[WCSettings settings] setObject:array forKey:WCIgnores];
		
		return YES;
	}
	
	return NO;
}

@end
