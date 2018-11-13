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
#import "WCEmoticonPreferences.h"
#import "WCThemesPreferences.h"
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
NSString * const WCEmoticonsDidChangeNotification           = @"WCEmoticonsDidChangeNotification";
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

- (void)_reloadThemes;
- (void)_reloadTheme;

- (void)_reloadEmoticons;

- (void)_reloadTemplates;
- (void)_reloadTemplatesForMenu:(NSMenu *)menu;

- (void)_reloadChatLogsFolder;

- (void)_reloadEvents;
- (void)_reloadEvent;
- (void)_updateEventControls;
- (void)_reloadDownloadFolder;

- (NSArray *)_themeNames;
- (void)_changeSelectedThemeToTheme:(NSDictionary *)theme;

- (void)_savePasswordForBookmark:(NSArray *)arguments;
- (void)_savePasswordForTrackerBookmark:(NSArray *)arguments;

@end


@implementation WCPreferences(Private)

- (void)_validate {
	NSDictionary		*theme;
	NSInteger			row;
	
	row = [self _selectedThemeRow];
	
	if(row < 0) {
		[_deleteThemeButton setEnabled:NO];
	} else {
		theme = [[[WCSettings settings] objectForKey:WCThemes] objectAtIndex:row];
		
		[_deleteThemeButton setEnabled:![theme objectForKey:WCThemesBuiltinName]];
	}
	[_deleteHighlightButton setEnabled:([_highlightsTableView selectedRow] >= 0)];
	[_deleteIgnoreButton setEnabled:([_ignoresTableView selectedRow] >= 0)];
}



#pragma mark -

- (void)_bookmarkDidChange:(NSDictionary *)bookmark {
	[[NSNotificationCenter defaultCenter] postNotificationName:WCBookmarkDidChangeNotification object:bookmark];
	[[NSNotificationCenter defaultCenter] postNotificationName:WCBookmarksDidChangeNotification];
}



#pragma mark -

- (void)_reloadEmoticons {
    NSMenuItem          *item;
    NSArray             *packs, *enabledPacks;
    WIEmoticonPack      *selectedPack;
    NSInteger           index;
    
    [_emoticonPacksPopUpButton setAutoenablesItems:NO];
    
    while((index = [_emoticonPacksPopUpButton indexOfItemWithTag:0]) != -1)
        [_emoticonPacksPopUpButton removeItemAtIndex:index];
    
    packs           = [self.emoticonPreferences availableEmoticonPacks];
    enabledPacks    = [self.emoticonPreferences enabledEmoticonPacks];
    selectedPack    = nil;
    
    if([enabledPacks count] > 1) {
        item    = [NSMenuItem itemWithTitle:@"Multiple Selection"
                                     action:@selector(customizeEmoticons:)];
        
        [item setRepresentedObject:enabledPacks];
        [_emoticonPacksPopUpButton addItem:item];
        [_emoticonPacksPopUpButton selectItem:item];
    }
    else if([enabledPacks count] == 1) {
        selectedPack = [enabledPacks objectAtIndex:0];
    }
    else if([enabledPacks count] == 0) {
        [_emoticonPacksPopUpButton selectItemAtIndex:0];
    }
    
    [_emoticonPacksPopUpButton addItem:[NSMenuItem separatorItem]];
    
    for(WIEmoticonPack *pack in packs) {
        item    = [NSMenuItem itemWithTitle:[pack name]
                                     action:nil];
        
        [item setImage:[pack previewImage]];
        [item setRepresentedObject:pack];
        
        [_emoticonPacksPopUpButton addItem:item];
    }
    
    if(selectedPack)
        [_emoticonPacksPopUpButton selectItemWithTitle:[selectedPack name]];
}





#pragma mark -

- (NSInteger)_selectedThemeRow {
    return [_themesPopUpButton indexOfItem:[_themesPopUpButton selectedItem]];
}

- (NSDictionary *)_selectedTheme {
    NSString        *identifier;
    NSDictionary    *theme;
    
    identifier  = [[WCSettings settings] objectForKey:WCTheme];
    theme       = [[WCSettings settings] themeWithIdentifier:identifier];
    
    return theme;
}


- (void)_reloadThemes {
	NSEnumerator	*enumerator;
	NSDictionary	*theme;
	NSMenuItem		*item;
    
    [_themesPopUpButton removeAllItems];
	
	enumerator = [[[WCSettings settings] objectForKey:WCThemes] objectEnumerator];
	
	while((theme = [enumerator nextObject])) {
		item = [NSMenuItem itemWithTitle:[theme objectForKey:WCThemesName]];
		[item setRepresentedObject:[theme objectForKey:WCThemesIdentifier]];
		[item setImage:[self imageForTheme:theme size:NSMakeSize(16.0, 12.0)]];
		[item setAction:@selector(selectTheme:)];
        [item setTarget:self];
        
        [_themesPopUpButton addItem:item];
    }
    
    [_themesPopUpButton selectItemWithRepresentedObject:[[WCSettings settings] objectForKey:WCTheme]];
    [_themesPopUpButton addItem:[NSMenuItem separatorItem]];
    
    [[_themesPopUpButton menu] addItemWithTitle:NSLS(@"Add New Theme...", @"Add Theme Menu Item Title")
                                         action:@selector(addTheme:)
                                  keyEquivalent:@""];
    
    [[_themesPopUpButton menu] addItemWithTitle:NSLS(@"Edit Themes...", @"Edit Themes Menu Item Title")
                                         action:@selector(editTheme:)
                                  keyEquivalent:@""];
    
    [_themesTableView reloadData];
}


- (void)_reloadTheme {
	NSDictionary	*theme;
	NSInteger		row;
	
	row = [[_themesPopUpButton menu] indexOfItem:[_themesPopUpButton selectedItem]];
	
	if(row >= 0 && (NSUInteger) row < [[[WCSettings settings] objectForKey:WCThemes] count]) {
		theme = [[[WCSettings settings] objectForKey:WCThemes] objectAtIndex:row];
		
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
		
		[self _reloadTemplates];
	}
}





- (void)_reloadTemplates {	
	[self _reloadTemplatesForMenu:[_themesTemplatesPopUpButton menu]];
}



- (void)_reloadTemplatesForMenu:(NSMenu *)menu {
	NSMutableArray				*templates;
	NSMenuItem					*newItem;
	NSString					*bundleName;
	NSDictionary				*theme;
	
	if([self _selectedThemeRow] == -1)
		return;
	
	theme			= [[[WCSettings settings] objectForKey:WCThemes] objectAtIndex:[self _selectedThemeRow]];
	templates		= [NSMutableArray arrayWithArray:[_privateTemplateManager templates]];
	
	[templates addObjectsFromArray:[_publicTemplateManager templates]];
	[menu removeAllItems];
	
	for(WITemplateBundle *template in templates) {
		
		bundleName	= [template templateName];
		newItem		= [menu addItemWithTitle:bundleName
								   action:@selector(selectThemeTemplate:) 
							keyEquivalent:@""];
		
		[newItem setTarget:self];
		[newItem setRepresentedObject:template];
		
		if([[theme objectForKey:WCThemesTemplate] isEqualTo:[template bundleIdentifier]]) {
			[newItem setState:NSOnState];
			[_themesTemplatesPopUpButton selectItemWithRepresentedObject:template];
		} else
			[newItem setState:NSOffState];
	}
	
	[menu addItem:[NSMenuItem separatorItem]];
    
    // NSLS(@"Add New Theme...", @"Add Theme Menu Item Title")
    
	[menu addItemWithTitle:NSLS(@"Add New Template...", @"Add Template Menu Item Title") action:@selector(addThemeTemplate:) keyEquivalent:@""];
	[menu addItemWithTitle:NSLS(@"Manage Templates...", @"Add Templates Menu Item Title") action:@selector(manageThemeTemplates:) keyEquivalent:@""];
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

- (NSArray *)_themeNames {
	NSEnumerator		*enumerator;
	NSDictionary		*theme;
	NSMutableArray		*array;
	
	array			= [NSMutableArray array];
	enumerator		= [[[WCSettings settings] objectForKey:WCThemes] objectEnumerator];
	
	while((theme = [enumerator nextObject]))
		[array addObject:[theme objectForKey:WCThemesName]];
	
	return array;
}



- (void)_changeSelectedThemeToTheme:(NSDictionary *)theme {
    NSMutableDictionary		*newTheme;
	
	if([theme objectForKey:WCThemesBuiltinName]) {
        newTheme = [[theme mutableCopy] autorelease];
        [newTheme setObject:[WCApplicationController copiedNameForName:[theme objectForKey:WCThemesName] existingNames:[self _themeNames]]
                     forKey:WCThemesName];
        [newTheme setObject:[NSString UUIDString] forKey:WCThemesIdentifier];
        [newTheme removeObjectForKey:WCThemesBuiltinName];
        
        [[WCSettings settings] addObject:newTheme toArrayForKey:WCThemes];
        [[WCSettings settings] setObject:[newTheme objectForKey:WCThemesIdentifier] forKey:WCTheme];
        [self _reloadThemes];
        
        [_themesPopUpButton selectItemAtIndex:[[[WCSettings settings] objectForKey:WCThemes] count]-1];
        
        [self _reloadTheme];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:WCThemeDidChangeNotification object:newTheme];
        
	} else {
		[[WCSettings settings] replaceObjectAtIndex:[self _selectedThemeRow] withObject:theme inArrayForKey:WCThemes];
        
		[self _reloadTheme];
		[self _reloadThemes];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:WCThemeDidChangeNotification object:theme];

	}
}



- (void)_changeBuiltinThemePanelDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	NSMutableDictionary		*newTheme;
	NSDictionary			*theme = contextInfo;
	
	if(returnCode == NSAlertDefaultReturn) {
		newTheme = [[theme mutableCopy] autorelease];
		[newTheme setObject:[WCApplicationController copiedNameForName:[theme objectForKey:WCThemesName] existingNames:[self _themeNames]]
					 forKey:WCThemesName];
		[newTheme setObject:[NSString UUIDString] forKey:WCThemesIdentifier];
		[newTheme removeObjectForKey:WCThemesBuiltinName];
		
		[[WCSettings settings] addObject:newTheme toArrayForKey:WCThemes];
		
		[self _reloadThemes];
	}
	
	[theme release];
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

@synthesize emoticonPreferences = _emoticonPreferences;



- (id)init {
	self = [super initWithWindowNibName:@"Preferences"];
	
	_privateTemplateManager	= [[WITemplateBundleManager templateManagerForPath:[[NSBundle mainBundle] resourcePath]] retain];
	_publicTemplateManager	= [[WITemplateBundleManager templateManagerForPath:[WCApplicationSupportPath stringByStandardizingPath] isPrivate:NO] retain];
	
	[self window];
    
    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(emoticonsDidChange:)
               name:WCEmoticonsDidChangeNotification];

    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(themesDidChange:)
               name:WCThemesDidChangeNotification];
    
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
	
    [self _reloadEmoticons];
	[self _reloadThemes];
	[self _reloadTheme];
	[self _reloadTemplates];
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
    [_networkCipherPopUpButton selectItemWithTag:[[WCSettings settings] integerForKey:WCNetworkEncryptionCipher]];
    [_networkCompressionButton setState:[[WCSettings settings] boolForKey:WCNetworkCompressionEnabled]];
    
	[self _validate];
	
	[super windowDidLoad];
}



- (void)emoticonsDidChange:(NSNotification *)notification {
    NSLog(@"emoticonsDidChange");
    [self _reloadEmoticons];
}



- (void)themesDidChange:(NSNotification *)notification {
    [self _reloadThemes];
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

- (BOOL)importThemeFromFile:(NSString *)path {
	NSMutableDictionary		*theme;
	
	[self showWindow:self];
	[self selectPreferenceView:_themesView];
	
	theme = [NSMutableDictionary dictionaryWithContentsOfFile:path];
	
	if(!theme || ![theme objectForKey:WCThemesName])
		return NO;
	
	[theme setObject:[NSString UUIDString] forKey:WCThemesIdentifier];
	
	[[WCSettings settings] addObject:theme toArrayForKey:WCThemes];
	
	[self _reloadThemes];
	
	return YES;
}



- (BOOL)importTemplateFromFile:(NSString *)path {
    BOOL result;
        
    result = [_publicTemplateManager addTemplateAtPath:path];
    
    if(result) [self _reloadTheme];
    
    return result;
}



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

- (NSImage *)imageForTheme:(NSDictionary *)theme size:(NSSize)size {
	NSMutableDictionary		*attributes;
	NSBezierPath			*path;
	NSImage					*image;
	NSSize					largeSize;
	
	largeSize	= NSMakeSize(64.0, 48.0);
	image		= [[NSImage alloc] initWithSize:largeSize];
	
	[image lockFocus];
	
	path = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(1.0, 1.0, largeSize.width - 2.0, largeSize.height - 2.0) cornerRadius:4.0];
	
	[WIColorFromString([theme objectForKey:WCThemesChatBackgroundColor]) set];
	[path fill];
    
	[[NSColor lightGrayColor] set];
	[path setLineWidth:2.0];
	[path stroke];
	
	attributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                  [NSFont fontWithName:[WIFontFromString([theme objectForKey:WCThemesChatFont]) fontName] size:12.0],
                  NSFontAttributeName,
                  WIColorFromString([theme objectForKey:WCThemesChatTextColor]),
                  NSForegroundColorAttributeName,
                  NULL];
    
	[@"hello," drawAtPoint:NSMakePoint(8.0, largeSize.height - 19.0) withAttributes:attributes];
	[@"world!" drawAtPoint:NSMakePoint(8.0, largeSize.height - 31.0) withAttributes:attributes];
	
	[attributes setObject:WIColorFromString([theme objectForKey:WCThemesChatEventsColor]) forKey:NSForegroundColorAttributeName];
	
	[@"<< ! >>" drawAtPoint:NSMakePoint(8.0, largeSize.height - 43.0) withAttributes:attributes];
    
	[image unlockFocus];
	
	[image setScalesWhenResized:YES];
	[image setSize:size];
	
	return [image autorelease];
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
    [[WCSettings settings] setInteger:[_networkCipherPopUpButton selectedTag] forKey:WCNetworkEncryptionCipher];
    [[WCSettings settings] setBool:[_networkCompressionButton state] forKey:WCNetworkCompressionEnabled];
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Network Settings Changed"];
    [alert addButtonWithTitle:@"OK"];
    [alert setInformativeText:@"This change cannot be applied to already active connections. Change will only take effect for newly initiated connections."];
                                   
     [alert runModal];
                                   
                                   
    [[NSNotificationCenter defaultCenter] postNotificationName:WCPreferencesDidChangeNotification];
}




#pragma mark -

- (IBAction)customizeEmoticons:(id)sender {
    [_emoticonPreferences open:sender];
}


- (IBAction)selectEmoticonPack:(id)sender {
    WIEmoticonPack *pack;
    id              object;
    
    if([_emoticonPacksPopUpButton selectedTag] == 1) {
        [[WCSettings settings] setObject:[NSArray array] forKey:WCEnabledEmoticonPacks];
    }
    else {
        object = [[_emoticonPacksPopUpButton selectedItem] representedObject];
        
        if([object isKindOfClass:[WIEmoticonPack class]]) {
            pack = (WIEmoticonPack *)object;
        
            [[WCSettings settings] setObject:[NSArray arrayWithObject:[pack packKey]]
                                      forKey:WCEnabledEmoticonPacks];
        }
    }
    
    [[self emoticonPreferences] reloadEmoticons];
    [[NSNotificationCenter defaultCenter] postNotificationName:WCEmoticonsDidChangeNotification];
}



#pragma mark -

- (IBAction)customizeTheme:(id)sender {
    [NSApp beginSheet:_themesWindow
       modalForWindow:[self window]
        modalDelegate:self
       didEndSelector:nil
          contextInfo:nil];
    
//    NSDictionary            *theme;
//    NSAlert                 *alert;
//    
//    theme   = [self _selectedTheme];
//    
//    if([theme objectForKey:WCThemesBuiltinName]) {
//		alert = [[NSAlert alloc] init];
//		[alert setMessageText:[NSSWF:
//                               NSLS(@"You cannot edit the built-in theme \u201c%@\u201d", @"Duplicate builtin theme dialog title (theme)"),
//                               [theme objectForKey:WCThemesName]]];
//		[alert setInformativeText:NSLS(@"Make a copy of it to edit it.", @"Duplicate builtin theme dialog description")];
//		[alert addButtonWithTitle:NSLS(@"Duplicate", @"Duplicate builtin theme dialog button title")];
//		[alert addButtonWithTitle:NSLS(@"Cancel", @"Duplicate builtin theme button title")];
//        
//        [alert beginSheetModalForWindow:[self window]
//                          modalDelegate:self
//                         didEndSelector:@selector(customizeBuiltInAlertDidEnd:returnCode:contextInfo:)
//                            contextInfo:theme];
//
//        
//        [alert release];
//	} else {
//        [NSApp beginSheet:_themesWindow
//           modalForWindow:[self window]
//            modalDelegate:self
//           didEndSelector:nil
//              contextInfo:nil];
//    }
}

- (void)customizeBuiltInAlertDidEnd:(NSAlert *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	NSMutableDictionary		*newTheme;
    NSString                *newName;
	NSDictionary			*theme = contextInfo;
    
    [NSApp endSheet:[sheet window]];
	[[sheet window] orderOut:self];
    
	if(returnCode == NSAlertDefaultReturn) {
        newName = [WCApplicationController copiedNameForName:[theme objectForKey:WCThemesName]
                                               existingNames:[self _themeNames]];
        
        newTheme = [[theme mutableCopy] autorelease];
        [newTheme setObject:newName forKey:WCThemesName];
        [newTheme setObject:[NSString UUIDString] forKey:WCThemesIdentifier];
        [newTheme removeObjectForKey:WCThemesBuiltinName];
        
        [[WCSettings settings] addObject:newTheme toArrayForKey:WCThemes];
        [self _reloadThemes];
        
        [_themesPopUpButton selectItemWithTitle:newName];
        [[WCSettings settings] setObject:[newTheme objectForKey:WCThemesIdentifier] forKey:WCTheme];
        
        [self _reloadTheme];
        
        [NSApp beginSheet:_themesWindow
           modalForWindow:[self window]
            modalDelegate:self
           didEndSelector:nil
              contextInfo:nil];

    }
}


- (IBAction)closeTheme:(id)sender {
    if([_themesWindow isVisible]) {
        [NSApp endSheet:_themesWindow];
        [_themesWindow orderOut:self];
    }
}


- (IBAction)addTheme:(id)sender {
    NSDictionary            *theme;
    NSString                *name;
    
    [self _reloadThemes];
    
    theme   = [self _selectedTheme];
    
    if(!theme)
        return;
    
    name    = [WCApplicationController copiedNameForName:[theme objectForKey:WCThemesName]
                                           existingNames:[self _themeNames]];
    
    [_addThemeNameTextField setStringValue:name];
    
    [NSApp beginSheet:_addThemeWindow
       modalForWindow:self.window
        modalDelegate:self
       didEndSelector:nil
          contextInfo:nil];
}


- (IBAction)cancelAddTheme:(id)sender {
    [NSApp endSheet:_addThemeWindow];
    [_addThemeWindow orderOut:sender];
    
    [_addThemeNameTextField setStringValue:@""];
}


- (IBAction)okAddTheme:(id)sender {
    NSMutableDictionary		*theme;
    NSString                *name;
    NSInteger				row;
    
    name = [_addThemeNameTextField stringValue];
    
    if([name length] > 0 && ![[self _themeNames] containsObject:name]) {
        [NSApp endSheet:_addThemeWindow];
        [_addThemeWindow orderOut:sender];
        
        row = [self _selectedThemeRow];
        
        if(row < 0)
            return;
        
        theme   = [[[[[WCSettings settings] objectForKey:WCThemes] objectAtIndex:row] mutableCopy] autorelease];
        [theme setObject:[NSString UUIDString] forKey:WCThemesIdentifier];
        [theme removeObjectForKey:WCThemesBuiltinName];
        [theme setObject:name forKey:WCThemesName];
        
        [[WCSettings settings] addObject:theme toArrayForKey:WCThemes];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:WCThemesDidChangeNotification
                                                            object:theme];
    }
}


- (IBAction)editTheme:(id)sender {
    [self _reloadThemes];
    
    [_themesPreferences open:sender];
}


- (IBAction)deleteTheme:(id)sender {
	NSAlert			*alert;
	NSString		*name;
	NSInteger		row;
	
	row = [self _selectedThemeRow];
	
	if(row < 0)
		return;
	
	name = [[[[WCSettings settings] objectForKey:WCThemes] objectAtIndex:row] objectForKey:WCThemesName];
	
	alert = [[NSAlert alloc] init];
	[alert setMessageText:[NSSWF:NSLS(@"Are you sure you want to delete \u201c%@\u201d?", @"Delete theme dialog title (theme)"), name]];
	[alert setInformativeText:NSLS(@"This cannot be undone.", @"Delete theme dialog description")];
	[alert addButtonWithTitle:NSLS(@"Delete", @"Delete theme dialog button title")];
	[alert addButtonWithTitle:NSLS(@"Cancel", @"Delete theme button title")];
	[alert beginSheetModalForWindow:[self window]
					  modalDelegate:self
					 didEndSelector:@selector(deleteThemeSheetDidEnd:returnCode:contextInfo:)
						contextInfo:[[NSNumber alloc] initWithInteger:row]];
	[alert release];
}



- (void)deleteThemeSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	NSNumber		*row = contextInfo;
	NSString		*identifier;

	if(returnCode == NSAlertDefaultReturn) {
		identifier = [[[[WCSettings settings] objectForKey:WCThemes] objectAtIndex:[row unsignedIntegerValue]]
			objectForKey:WCThemesIdentifier];
		
		if([[[WCSettings settings] objectForKey:WCTheme] isEqualToString:identifier]) {
			identifier = [[[[WCSettings settings] objectForKey:WCThemes] objectAtIndex:0] objectForKey:WCThemesIdentifier];
			
			[[WCSettings settings] setObject:identifier forKey:WCTheme];
		}
		
		[[WCSettings settings] removeObjectAtIndex:[row unsignedIntegerValue] fromArrayForKey:WCThemes];

		[self _reloadThemes];
		[self _reloadTheme];
	}
	
	[row release];
}



- (IBAction)duplicateTheme:(id)sender {
	NSMutableDictionary		*theme;
	NSInteger				row;
	
	row = [self _selectedThemeRow];
	
	if(row < 0)
		return;
	
	theme = [[[[[WCSettings settings] objectForKey:WCThemes] objectAtIndex:row] mutableCopy] autorelease];
	
	[theme setObject:[NSString UUIDString] forKey:WCThemesIdentifier];
	[theme removeObjectForKey:WCThemesBuiltinName];
	[theme setObject:[WCApplicationController copiedNameForName:[theme objectForKey:WCThemesName] existingNames:[self _themeNames]]
			  forKey:WCThemesName];
	
	[[WCSettings settings] addObject:theme toArrayForKey:WCThemes];
	
	[self _reloadThemes];
}



- (IBAction)exportTheme:(id)sender {
	__block NSSavePanel				*savePanel;
	__block NSMutableDictionary		*theme;
	NSInteger                       row;
	
	row = [self _selectedThemeRow];
	
	if(row < 0)
		return;
	
	theme = [[[[WCSettings settings] objectForKey:WCThemes] objectAtIndex:row] mutableCopy];
	[theme removeObjectForKey:WCThemesIdentifier];
	[theme removeObjectForKey:WCThemesBuiltinName];

	savePanel = [NSSavePanel savePanel];
	[savePanel setAllowedFileTypes:[NSArray arrayWithObject:@"WiredTheme"]];
	[savePanel setCanSelectHiddenExtension:YES];
    [savePanel setNameFieldStringValue:[[theme objectForKey:WCThemesName] stringByAppendingPathExtension:@"WiredTheme"]];
    
    [savePanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result) {        
        if(result == NSModalResponseOK)
            [theme writeToURL:[savePanel URL] atomically:YES];
        
        [theme release];
    }];
}



- (IBAction)importTheme:(id)sender {
	__block NSOpenPanel     *openPanel;
	
	openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseFiles:YES];
	[openPanel setCanChooseDirectories:NO];
    [openPanel setAllowedFileTypes:[NSArray arrayWithObject:@"WiredTheme"]];
    
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result) {
        if(result == NSModalResponseOK)
            [self importThemeFromFile:[[openPanel URL] path]];
    }];
}





- (IBAction)selectTheme:(id)sender {
	NSDictionary		*theme;
	NSInteger			row;
	
	row = [[_themesPopUpButton menu] indexOfItem:[_themesPopUpButton selectedItem]];
	   
	if(row < 0 || [[[WCSettings settings] objectForKey:WCThemes] count] < (NSUInteger)row)
		return;
	
	theme = [[[WCSettings settings] objectForKey:WCThemes] objectAtIndex:row];
	
	[[WCSettings settings] setObject:[theme objectForKey:WCThemesIdentifier] forKey:WCTheme];
	
    [self _reloadTemplates];
    
	[[NSNotificationCenter defaultCenter] postNotificationName:WCThemeDidChangeNotification object:theme];
}



- (IBAction)changeTheme:(id)sender {
	NSMutableDictionary		*theme;
	NSDictionary			*oldTheme;
	NSInteger				row;
	
	row = [self _selectedThemeRow];
	   
	if(row < 0 || [[[WCSettings settings] objectForKey:WCThemes] count] < (NSUInteger)row)
		return;

	oldTheme		= [[[[[WCSettings settings] objectForKey:WCThemes] objectAtIndex:row] retain] autorelease];
	theme			= [[oldTheme mutableCopy] autorelease];
	
	[theme setObject:WIStringFromColor([_themesChatTextColorWell color]) forKey:WCThemesChatTextColor];
	[theme setObject:WIStringFromColor([_themesChatBackgroundColorWell color]) forKey:WCThemesChatBackgroundColor];
	[theme setObject:WIStringFromColor([_themesChatEventsColorWell color]) forKey:WCThemesChatEventsColor];
	[theme setObject:WIStringFromColor([_themesChatTimestampEveryLineColorWell color]) forKey:WCThemesChatTimestampEveryLineColor];
	[theme setObject:WIStringFromColor([_themesChatURLsColorWell color]) forKey:WCThemesChatURLsColor];
	
	[theme setObject:WIStringFromColor([_themesMessagesTextColorWell color]) forKey:WCThemesMessagesTextColor];
	[theme setObject:WIStringFromColor([_themesMessagesBackgroundColorWell color]) forKey:WCThemesMessagesBackgroundColor];
	[theme setObject:WIStringFromColor([_themesBoardsTextColorWell color]) forKey:WCThemesBoardsTextColor];
	[theme setObject:WIStringFromColor([_themesBoardsBackgroundColorWell color]) forKey:WCThemesBoardsBackgroundColor];
	
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
	
	if(![oldTheme isEqualToDictionary:theme])
		[self _changeSelectedThemeToTheme:theme];
}



- (IBAction)changeThemeFont:(id)sender {
	NSDictionary		*theme;
	NSFontManager		*fontManager;
	
	theme			= [[[WCSettings settings] objectForKey:WCThemes] objectAtIndex:[self _selectedThemeRow]];
	fontManager		= [NSFontManager sharedFontManager];
    
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
	
	theme		= [[[[[WCSettings settings] objectForKey:WCThemes] objectAtIndex:[self _selectedThemeRow]] mutableCopy] autorelease];
	font		= WIFontFromString([theme objectForKey:WCThemesChatFont]);
	newFont		= [sender convertFont:font];
	
	[theme setObject:WIStringFromFont(newFont) forKey:WCThemesChatFont];
	
	[self _changeSelectedThemeToTheme:theme];
}



- (void)setMessagesFont:(id)sender {
	NSMutableDictionary		*theme;
	NSFont					*font, *newFont;
	
	theme		= [[[[[WCSettings settings] objectForKey:WCThemes] objectAtIndex:[self _selectedThemeRow]] mutableCopy] autorelease];
	font		= WIFontFromString([theme objectForKey:WCThemesMessagesFont]);
	newFont		= [sender convertFont:font];
	
	[theme setObject:WIStringFromFont(newFont) forKey:WCThemesMessagesFont];
	
	[self _changeSelectedThemeToTheme:theme];
}



- (void)setBoardsFont:(id)sender {
	NSMutableDictionary		*theme;
	NSFont					*font, *newFont;
	
	theme		= [[[[[WCSettings settings] objectForKey:WCThemes] objectAtIndex:[self _selectedThemeRow]] mutableCopy] autorelease];
	font		= WIFontFromString([theme objectForKey:WCThemesBoardsFont]);
	newFont		= [sender convertFont:font];
	
	[theme setObject:WIStringFromFont(newFont) forKey:WCThemesBoardsFont];
	
	[self _changeSelectedThemeToTheme:theme];
}





#pragma mark - 

- (IBAction)selectThemeTemplate:(id)sender {	
	id						value;
	NSMutableDictionary		*theme;
	
	value = [[sender representedObject] bundleIdentifier];
	
	if(value && [value isKindOfClass:[NSString class]]) {
		theme = [[[[[WCSettings settings] objectForKey:WCThemes] objectAtIndex:[self _selectedThemeRow]] mutableCopy] autorelease];

		[theme setValue:value forKey:WCThemesTemplate];
		
		[self _changeSelectedThemeToTheme:theme];
	}
}



- (IBAction)addThemeTemplate:(id)sender {
	__block NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setAllowsMultipleSelection:NO];
    [openPanel setAllowedFileTypes:[NSArray arrayWithObject:@"WiredTemplate"]];
	
	if([_themesTemplatesWindow isVisible])
		[self closeManageThemeTemplates:sender];
    
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result) {
        if(result == NSModalResponseOK) {
            [_publicTemplateManager addTemplateAtPath:[[openPanel URL] path]];
        }
        
        [self _reloadTheme];
    }];
}






- (IBAction)manageThemeTemplates:(id)sender {
	[_themesTemplatesTableView reloadData];
	
	[NSApp beginSheet:_themesTemplatesWindow
	   modalForWindow:[self window]
		modalDelegate:self
	   didEndSelector:nil
		  contextInfo:nil];
}



- (IBAction)closeManageThemeTemplates:(id)sender {
	[NSApp endSheet:_themesTemplatesWindow];
	[_themesTemplatesWindow orderOut:sender];
	
	[self _reloadTheme];
}



- (IBAction)deleteThemeTemplate:(id)sender {
	WITemplateBundle		*selectedTemplate;
	NSAlert					*alert;
	BOOL					inUse;
	
	if([_themesTemplatesTableView selectedRow] != -1) {
		
		inUse				= NO;
		selectedTemplate	= [[_publicTemplateManager templates] objectAtIndex:[_themesTemplatesTableView selectedRow]];
		
		for(NSDictionary *theme in [[WCSettings settings] objectForKey:WCThemes]) {			
			if([[selectedTemplate bundleIdentifier] isEqualToString:[theme objectForKey:WCThemesTemplate]]) {
				inUse = YES;
				continue;
			}
		}

		if(!inUse) {
			alert	 = [NSAlert alertWithMessageText:@"Deleting Template"
									 defaultButton:@"Delete"
								   alternateButton:@"Cancel"
									   otherButton:nil
						 informativeTextWithFormat:@"You will delete %@ template. This operation is not cancelable. Press Delete button to continue or Cancel to abort.", [selectedTemplate templateName]];
			
			if([alert runModal] == NSAlertDefaultReturn)
				if([_publicTemplateManager removeTemplate:selectedTemplate]) {
					[_themesTemplatesTableView reloadData];
					[self _reloadTheme];
				}
			
			
		} else {
			alert	 = [NSAlert alertWithMessageText:@"Cannot Delete Used Template"
									 defaultButton:@"OK"
								   alternateButton:nil
									   otherButton:nil
						 informativeTextWithFormat:@"The template %@ you want to delete is currently used by some themes. You must be sure that this template is not used before deleting it.", [selectedTemplate templateName]];
		
			[alert runModal];
		}
	}
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
	
	if(returnCode == NSAlertDefaultReturn) {
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

- (void)menuNeedsUpdate:(NSMenu *)menu {
    if(menu == [_emoticonPacksPopUpButton menu]) {
        [self _reloadEmoticons];
    }
}
	




#pragma mark -

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	if(tableView == _highlightsTableView)
		return [[[WCSettings settings] objectForKey:WCHighlights] count];
	else if(tableView == _ignoresTableView)
		return [[[WCSettings settings] objectForKey:WCIgnores] count];
	else if (tableView == _themesTemplatesTableView)
		return [[_publicTemplateManager templates] count];

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
	else if (tableView == _themesTemplatesTableView) {
		if([[column identifier] isEqualToString:@"Name"])
			return [[[_publicTemplateManager templates] objectAtIndex:row] templateName];
		else if([[column identifier] isEqualToString:@"Version"])
			return [[[_publicTemplateManager templates] objectAtIndex:row] templateVersion];
	}

	return NULL;
}



- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	if(tableView == _themesTemplatesTableView)
		return NO;
	
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
