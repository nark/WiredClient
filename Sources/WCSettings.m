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
#import "WCKeychain.h"
#import "WCPreferences.h"

#define _WCAutoHideOnSwitch								@"WCAutoHideOnSwitch"
#define _WCPreventMultipleConnections					@"WCPreventMultipleConnections"

#define _WCChatTextColor								@"WCChatTextColor"
#define _WCChatBackgroundColor							@"WCChatBackgroundColor"
#define _WCChatEventsColor								@"WCChatEventsColor"
#define _WCChatURLsColor								@"WCChatURLsColor"
#define _WCChatFont										@"WCChatFont"
#define _WCChatUserListAlternateRows					@"WCChatUserListAlternateRows"
#define _WCChatUserListIconSize							@"WCChatUserListIconSize"

#define _WCShowSmileys									@"WCShowSmileys"
#define _WCTimestampEveryLine							@"WCTimestampEveryLine"
#define _WCTimestampEveryLineColor						@"WCTimestampEveryLineColor"

#define _WCMessagesTextColor							@"WCMessagesTextColor"
#define _WCMessagesBackgroundColor						@"WCMessagesBackgroundColor"
#define _WCMessagesFont									@"WCMessagesFont"
#define _WCMessagesListAlternateRows					@"WCMessagesListAlternateRows"

#define _WCNewsTextColor								@"WCNewsTextColor"
#define _WCNewsBackgroundColor							@"WCNewsBackgroundColor"
#define _WCNewsFont										@"WCNewsFont"

#define _WCFilesAlternateRows							@"WCFilesAlternateRows"

#define _WCTransfersShowProgressBar						@"WCTransfersShowProgressBar"
#define _WCTransfersAlternateRows						@"WCTransfersAlternateRows"

#define _WCTrackersAlternateRows						@"WCTrackersAlternateRows"

#define _WCWindowTemplates								@"WCWindowTemplates"
#define _WCWindowTemplatesDefault						@"WCWindowTemplatesDefault"


NSString * const WCNick									= @"WCNick";
NSString * const WCStatus								= @"WCStatus";
NSString * const WCIcon									= @"WCCustomIcon";

NSString * const WCCheckForUpdate						= @"WCCheckForUpdate";

NSString * const WCShowChatWindowAtStartup				= @"WCShowChatWindowAtStartup";
NSString * const WCShowConnectAtStartup					= @"WCShowConnectAtStartup";
NSString * const WCShowServersAtStartup					= @"WCShowTrackersAtStartup";

NSString * const WCApplicationMenuEnabled               = @"WCApplicationMenuEnabled";

NSString * const WCHideUserList                         = @"WCHideUserList";
NSString * const WCHideServerList                       = @"WCHideServerList";


NSString * const WCConfirmDisconnect					= @"WCConfirmDisconnect";
NSString * const WCAutoReconnect						= @"WCAutoReconnect";
NSString * const WCOrderFrontWhenDisconnected           = @"WCOrderFrontWhenDisconnected";

NSString * const WCEnabledEmoticonPacks                 = @"WCEnabledEmoticonPacks";
NSString * const WCEmoticonPacksOrdering                = @"WCEmoticonPacksOrdering";
NSString * const WCDisabledEmoticons                    = @"WCDisabledEmoticons";

NSString * const WCTheme								= @"WCTheme";

NSString * const WCThemes								= @"WCThemes";
NSString * const WCThemesName							= @"WCThemesName";
NSString * const WCThemesBuiltinName					= @"WCThemesBuiltinName";
NSString * const WCThemesIdentifier						= @"WCThemesIdentifier";
NSString * const WCThemesTemplate						= @"WCThemesTemplate";
NSString * const WCThemesShowSmileys					= @"WCThemesShowSmileys";
NSString * const WCThemesChatFont						= @"WCThemesChatFont";
NSString * const WCThemesChatTextColor					= @"WCThemesChatTextColor";
NSString * const WCThemesChatBackgroundColor			= @"WCThemesChatBackgroundColor";
NSString * const WCThemesChatEventsColor				= @"WCThemesChatEventsColor";
NSString * const WCThemesChatURLsColor					= @"WCThemesChatURLsColor";
NSString * const WCThemesChatTimestampEveryLineColor	= @"WCThemesChatTimestampEveryLineColor";
NSString * const WCThemesChatTimestampEveryLine			= @"WCThemesChatTimestampEveryLine";
NSString * const WCThemesMessagesFont					= @"WCThemesMessagesFont";
NSString * const WCThemesMessagesTextColor				= @"WCThemesMessagesTextColor";
NSString * const WCThemesMessagesBackgroundColor		= @"WCThemesMessagesBackgroundColor";
NSString * const WCThemesBoardsFont						= @"WCThemesBoardsFont";
NSString * const WCThemesBoardsTextColor				= @"WCThemesBoardsTextColor";
NSString * const WCThemesBoardsBackgroundColor			= @"WCThemesBoardsBackgroundColor";
NSString * const WCThemesUserListIconSize				= @"WCThemesUserListIconSize";
NSString * const WCThemesUserListAlternateRows			= @"WCThemesUserListAlternateRows";
NSString * const WCThemesFileListAlternateRows			= @"WCThemesFileListAlternateRows";
NSString * const WCThemesFileListIconSize				= @"WCThemesFileListIconSize";
NSString * const WCThemesTransferListShowProgressBar	= @"WCThemesTransferListShowProgressBar";
NSString * const WCThemesTransferListAlternateRows		= @"WCThemesTransferListAlternateRows";
NSString * const WCThemesTrackerListAlternateRows		= @"WCThemesTrackerListAlternateRows";
NSString * const WCThemesMonitorIconSize				= @"WCThemesMonitorIconSize";
NSString * const WCThemesMonitorAlternateRows			= @"WCThemesMonitorAlternateRows";

NSString * const WCThreadsSplitViewOrientation			= @"WCThreadsSplitViewOrientation";

NSString * const WCMessageConversations					= @"WCMessageConversations";
NSString * const WCBroadcastConversations				= @"WCBroadcastConversations";

NSString * const WCBookmarks							= @"WCBookmarks";
NSString * const WCBookmarksName						= @"Name";
NSString * const WCBookmarksAddress						= @"Address";
NSString * const WCBookmarksLogin						= @"Login";
NSString * const WCBookmarksPassword					= @"Password";
NSString * const WCBookmarksIdentifier					= @"Identifier";
NSString * const WCBookmarksNick						= @"Nick";
NSString * const WCBookmarksStatus						= @"Status";
NSString * const WCBookmarksAutoConnect					= @"AutoJoin";
NSString * const WCBookmarksAutoReconnect				= @"AutoReconnect";
NSString * const WCBookmarksTheme						= @"Theme";

NSString * const WCChatHistoryScrollback				= @"WCHistoryScrollback";
NSString * const WCChatHistoryScrollbackModifier		= @"WCHistoryScrollbackModifier";
NSString * const WCChatTabCompleteNicks					= @"WCTabCompleteNicks";
NSString * const WCChatTabCompleteNicksString			= @"WCTabCompleteNicksString";
NSString * const WCChatTimestampChat					= @"WCTimestampChat";
NSString * const WCChatTimestampChatInterval			= @"WCTimestampChatInterval";
NSString * const WCChatLogsHistoryEnabled				= @"WCChatLogsHistoryEnabled";
NSString * const WCChatLogsPlainTextEnabled				= @"WCChatLogsPlainTextEnabled";
NSString * const WCChatLogsPath							= @"WCChatLogsPath";
NSString * const WCChatEmbedHTMLInChatEnabled			= @"WCChatEmbedHTMLInChatEnabled";
NSString * const WCChatAnimatedImagesEnabled			= @"WCChatAnimatedImagesEnabled";

NSString * const WCHighlights							= @"WCHighlights";
NSString * const WCHighlightsPattern					= @"WCHighlightsPattern";
NSString * const WCHighlightsColor						= @"WCHighlightsColor";

NSString * const WCIgnores								= @"WCIgnores";
NSString * const WCIgnoresNick							= @"Nick";

NSString * const WCEvents								= @"WCEvents";
NSString * const WCEventsEvent							= @"WCEventsEvent";
NSString * const WCEventsPlaySound						= @"WCEventsPlaySound";
NSString * const WCEventsSound							= @"WCEventsSound";
NSString * const WCEventsBounceInDock					= @"WCEventsBounceInDock";
NSString * const WCEventsPostInChat						= @"WCEventsPostInChat";
NSString * const WCEventsShowDialog						= @"WCEventsShowDialog";
NSString * const WCEventsNotificationCenter             = @"WCEventsNotificationCenter";

NSString * const WCEventsVolume							= @"WCEventsVolume";

NSString * const WCTransferList							= @"WCTransferList";
NSString * const WCDownloadFolder						= @"WCDownloadFolder";
NSString * const WCOpenFoldersInNewWindows				= @"WCOpenFoldersInNewWindows";
NSString * const WCQueueTransfers						= @"WCQueueTransfers";
NSString * const WCCheckForResourceForks				= @"WCCheckForResourceForks";
NSString * const WCRemoveTransfers						= @"WCRemoveTransfers";
NSString * const WCFilesStyle							= @"WCFilesStyle";

NSString * const WCTrackerBookmarks						= @"WCTrackerBookmarks";
NSString * const WCTrackerBookmarksName					= @"Name";
NSString * const WCTrackerBookmarksAddress				= @"Address";
NSString * const WCTrackerBookmarksLogin				= @"Login";
NSString * const WCTrackerBookmarksPassword				= @"Password";
NSString * const WCTrackerBookmarksIdentifier			= @"Identifier";

NSString * const WCWindowProperties						= @"WCWindowProperties";

NSString * const WCCollapsedBoards						= @"WCCollapsedBoards";
NSString * const WCReadBoardPosts						= @"WCReadBoardPosts";
NSString * const WCBoardFilters							= @"WCBoardFilters";
NSString * const WCBoardPostContinuousSpellChecking		= @"WCBoardPostContinuousSpellChecking";

NSString * const WCPlaces								= @"WCPlaces";

NSString * const WCNetworkConnectionTimeout             = @"WCNetworkConnectionTimeout";
NSString * const WCNetworkReadTimeout                   = @"WCNetworkReadTimeout";
NSString * const WCNetworkEncryptionCipher              = @"WCNetworkEncryptionCipher";
NSString * const WCNetworkCompressionEnabled            = @"WCNetworkCompressionEnabled";

NSString * const WCDebug								= @"WCDebug";
NSString * const WCMigrated20B                          = @"WCMigrated20B";




@interface WCSettings(Private)

- (void)_upgrade;

- (NSDictionary *)_themeWithBuiltinName:(NSString *)builtinName;

- (NSDictionary *)_defaultBasicTheme;
- (NSDictionary *)_defaultHackerTheme;
- (NSDictionary *)_defaultNeoTheme;

@end


@implementation WCSettings(Private)

static NSString         *basicThemeIdentifier;

- (void)_upgrade {
    
	NSEnumerator			*enumerator, *keyEnumerator;
	NSDictionary			*defaults, *defaultTheme;
	NSArray					*themes, *bookmarks;
	NSMutableArray			*newThemes, *newBookmarks;
	NSDictionary			*theme, *builtinTheme, *bookmark;
	NSMutableDictionary		*newTheme, *newBookmark;
	NSString				*key, *password, *identifier, *builtinName;
	
	defaults		= [self defaults];
	defaultTheme	= [[defaults objectForKey:WCThemes] objectAtIndex:0];
	
	/* Convert old font/color settings to theme */
	if([[self objectForKey:WCThemes] isEqualToArray:[NSArray arrayWithObject:defaultTheme]]) {
		newTheme = [[defaultTheme mutableCopy] autorelease];
		
		if([self objectForKey:_WCChatURLsColor]) {
			[newTheme setObject:WIStringFromColor([NSUnarchiver unarchiveObjectWithData:[self objectForKey:_WCChatURLsColor]])
						 forKey:WCThemesChatURLsColor];
		}
		
		if([self objectForKey:_WCChatTextColor]) {
			[newTheme setObject:WIStringFromColor([NSUnarchiver unarchiveObjectWithData:[self objectForKey:_WCChatTextColor]])
						 forKey:WCThemesChatTextColor];
		}
		
		if([self objectForKey:_WCChatBackgroundColor]) {
			[newTheme setObject:WIStringFromColor([NSUnarchiver unarchiveObjectWithData:[self objectForKey:_WCChatBackgroundColor]])
						 forKey:WCThemesChatBackgroundColor];
		}
		
		if([self objectForKey:_WCChatEventsColor]) {
			[newTheme setObject:WIStringFromColor([NSUnarchiver unarchiveObjectWithData:[self objectForKey:_WCChatEventsColor]])
						 forKey:WCThemesChatEventsColor];
		}
		
		if([self objectForKey:_WCChatFont]) {
			[newTheme setObject:WIStringFromFont([NSUnarchiver unarchiveObjectWithData:[self objectForKey:_WCChatFont]])
						 forKey:WCThemesChatFont];
		}
		
		if([self objectForKey:_WCTimestampEveryLine]) {
			[newTheme setObject:[self objectForKey:_WCTimestampEveryLine]
						 forKey:WCThemesChatTimestampEveryLine];
		}
		
		if([self objectForKey:_WCTimestampEveryLineColor]) {
			[newTheme setObject:WIStringFromColor([NSUnarchiver unarchiveObjectWithData:[self objectForKey:_WCTimestampEveryLineColor]])
						 forKey:WCThemesChatTimestampEveryLineColor];
		}
		
		if([self objectForKey:_WCMessagesTextColor]) {
			[newTheme setObject:WIStringFromColor([NSUnarchiver unarchiveObjectWithData:[self objectForKey:_WCMessagesTextColor]])
						 forKey:WCThemesMessagesTextColor];
		}
		
		if([self objectForKey:_WCMessagesBackgroundColor]) {
			[newTheme setObject:WIStringFromColor([NSUnarchiver unarchiveObjectWithData:[self objectForKey:_WCMessagesBackgroundColor]])
						 forKey:WCThemesMessagesBackgroundColor];
		}
		
		if([self objectForKey:_WCMessagesFont]) {
			[newTheme setObject:WIStringFromFont([NSUnarchiver unarchiveObjectWithData:[self objectForKey:_WCMessagesFont]])
						 forKey:WCThemesMessagesFont];
		}
		
		if([self objectForKey:_WCNewsTextColor]) {
			[newTheme setObject:WIStringFromColor([NSUnarchiver unarchiveObjectWithData:[self objectForKey:_WCNewsTextColor]])
						 forKey:WCThemesBoardsTextColor];
		}
		
		if([self objectForKey:_WCNewsBackgroundColor]) {
			[newTheme setObject:WIStringFromColor([NSUnarchiver unarchiveObjectWithData:[self objectForKey:_WCNewsBackgroundColor]])
						 forKey:WCThemesBoardsBackgroundColor];
		}
		
		if([self objectForKey:_WCNewsFont]) {
			[newTheme setObject:WIStringFromFont([NSUnarchiver unarchiveObjectWithData:[self objectForKey:_WCNewsFont]])
						 forKey:WCThemesBoardsFont];
		}
		
		if([self objectForKey:_WCFilesAlternateRows]) {
			[newTheme setObject:[self objectForKey:_WCFilesAlternateRows]
						 forKey:WCThemesFileListAlternateRows];
		}
		
		if([self objectForKey:_WCTransfersShowProgressBar]) {
			[newTheme setObject:[self objectForKey:_WCTransfersShowProgressBar]
						 forKey:WCThemesTransferListShowProgressBar];
		}
		
		if([self objectForKey:_WCTransfersAlternateRows]) {
			[newTheme setObject:[self objectForKey:_WCTransfersAlternateRows]
						 forKey:WCThemesTransferListAlternateRows];
		}
		
		if([self objectForKey:_WCTrackersAlternateRows]) {
			[newTheme setObject:[self objectForKey:_WCTrackersAlternateRows]
						 forKey:WCThemesTrackerListAlternateRows];
		}
		
		if([self objectForKey:_WCShowSmileys]) {
			[newTheme setObject:[self objectForKey:_WCShowSmileys]
						 forKey:WCThemesShowSmileys];
		}
		
		if(![newTheme isEqualToDictionary:defaultTheme]) {
			[newTheme setObject:@"Wired Client 1.x" forKey:WCThemesName];
			[newTheme setObject:[NSString UUIDString] forKey:WCThemesIdentifier];
			
			[self addObject:newTheme toArrayForKey:WCThemes];
		}

		/*		
		[self removeObjectForKey:_WCChatTextColor];
		[self removeObjectForKey:_WCChatBackgroundColor];
		[self removeObjectForKey:_WCChatEventsColor];
		[self removeObjectForKey:_WCChatURLsColor];
		[self removeObjectForKey:_WCChatFont];
		[self removeObjectForKey:_WCChatUserListAlternateRows];
		[self removeObjectForKey:_WCChatUserListIconSize];
		[self removeObjectForKey:_WCTimestampEveryLineColor];
		[self removeObjectForKey:_WCMessagesTextColor];
		[self removeObjectForKey:_WCMessagesBackgroundColor];
		[self removeObjectForKey:_WCMessagesFont];
		[self removeObjectForKey:_WCMessagesListAlternateRows];
		[self removeObjectForKey:_WCNewsTextColor];
		[self removeObjectForKey:_WCNewsBackgroundColor];
		[self removeObjectForKey:_WCNewsFont];
		[self removeObjectForKey:_WCFilesAlternateRows];
		[self removeObjectForKey:_WCTransfersShowProgressBar];
		[self removeObjectForKey:_WCTransfersAlternateRows];
		[self removeObjectForKey:_WCTrackersAlternateRows];
		[self removeObjectForKey:_WCShowSmileys];
		*/
	}
	
	/* Convert themes */
	builtinName		= NULL;
	identifier		= [self objectForKey:WCTheme];
	themes			= [self objectForKey:WCThemes];
	newThemes		= [NSMutableArray array];
	enumerator		= [themes objectEnumerator];
	
	while((theme = [enumerator nextObject])) {
		if([theme objectForKey:WCThemesBuiltinName]) {
			if([[theme objectForKey:WCThemesIdentifier] isEqualToString:identifier])
				builtinName = [theme objectForKey:WCThemesBuiltinName];
		} else {
			newTheme		= [[theme mutableCopy] autorelease];
			keyEnumerator	= [defaultTheme keyEnumerator];
			
			while((key = [keyEnumerator nextObject])) {
				if(![key isEqualToString:WCThemesBuiltinName]) {
					if(![newTheme objectForKey:key])
						[newTheme setObject:[defaultTheme objectForKey:key] forKey:key];
				}
			}
			
			[newThemes addObject:newTheme];
		}
	}
	
	/* Add all default themes */
	enumerator = [[defaults objectForKey:WCThemes] reverseObjectEnumerator];
	
	while((builtinTheme = [enumerator nextObject])) {
		if([newThemes count] > 0)
			[newThemes insertObject:builtinTheme atIndex:0];
		else
			[newThemes addObject:builtinTheme];
		
		if(builtinName && [[builtinTheme objectForKey:WCThemesBuiltinName] isEqualToString:builtinName])
			[self setObject:[builtinTheme objectForKey:WCThemesIdentifier] forKey:WCTheme];
	}
	
	[self setObject:newThemes forKey:WCThemes];

	/* Convert bookmarks */
	bookmarks		= [self objectForKey:WCBookmarks];
	newBookmarks	= [NSMutableArray array];
	enumerator		= [bookmarks objectEnumerator];
	
	while((bookmark = [enumerator nextObject])) {
		newBookmark = [[bookmark mutableCopy] autorelease];
		
		if(![newBookmark objectForKey:WCBookmarksIdentifier])
			[newBookmark setObject:[NSString UUIDString] forKey:WCBookmarksIdentifier];

		if(![newBookmark objectForKey:WCBookmarksNick])
			[newBookmark setObject:@"" forKey:WCBookmarksNick];

		if(![newBookmark objectForKey:WCBookmarksStatus])
			[newBookmark setObject:@"" forKey:WCBookmarksStatus];
		
		password = [newBookmark objectForKey:WCBookmarksPassword];

		if(password) {
			if([password length] > 0)
				[[WCKeychain keychain] setPassword:password forBookmark:newBookmark];
			
			[newBookmark removeObjectForKey:WCBookmarksPassword];
		}
	
		[newBookmarks addObject:newBookmark];
	}
	
	[self setObject:newBookmarks forKey:WCBookmarks];

	/* Convert tracker bookmarks */
	bookmarks		= [self objectForKey:WCTrackerBookmarks];
	newBookmarks	= [NSMutableArray array];
	enumerator		= [bookmarks objectEnumerator];
	
	while((bookmark = [enumerator nextObject])) {
		newBookmark = [[bookmark mutableCopy] autorelease];
		
		if(![newBookmark objectForKey:WCTrackerBookmarksIdentifier])
			[newBookmark setObject:[NSString UUIDString] forKey:WCTrackerBookmarksIdentifier];

		if(![newBookmark objectForKey:WCTrackerBookmarksLogin])
			[newBookmark setObject:@"" forKey:WCTrackerBookmarksLogin];
		
		[newBookmarks addObject:newBookmark];
	}
	
	/* Check download folder */
	if(![[NSFileManager defaultManager] directoryExistsAtPath:[self objectForKey:WCDownloadFolder]])
		[self setObject:[@"~/Desktop" stringByExpandingTildeInPath] forKey:WCDownloadFolder];
	
	[self setObject:newBookmarks forKey:WCTrackerBookmarks];
    
    
    /* Upgrade to 2.0b54+ */
    if(![self objectForKey:WCNetworkConnectionTimeout]) 
        [self setObject:[NSNumber numberWithInteger:30] forKey:WCNetworkConnectionTimeout];
    
    if(![self objectForKey:WCNetworkReadTimeout]) 
        [self setObject:[NSNumber numberWithInteger:10] forKey:WCNetworkReadTimeout];
    
    if(![self objectForKey:WCNetworkEncryptionCipher]) 
        [self setObject:[NSNumber numberWithInteger:2] forKey:WCNetworkEncryptionCipher];
    
    if(![self objectForKey:WCNetworkCompressionEnabled]) 
        [self setObject:[NSNumber numberWithBool:YES] forKey:WCNetworkCompressionEnabled];
	
	
	/* Update from 2.0 (243) to 2.0 (244): add WCEventsChatSent */
	BOOL chatSentEventFound = NO;
	NSArray *events = [self objectForKey:WCEvents];
	
	for(NSDictionary *event in events) {
		if([[event objectForKey:@"WCEventsEvent"] integerValue] == WCEventsChatSent) {
			chatSentEventFound = YES;
			continue;
		}
	}
	if(!chatSentEventFound) {
		id event = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:WCEventsChatSent], WCEventsEvent, NULL];
		[self addObject:event toArrayForKey:@"WCEvents"];			
	}
	
	
	/* Update from 2.0 (244) to 2.0 (245 - webkit): add template in theme */
	NSArray *allThemes  = [self objectForKey:WCThemes];
	NSInteger index     = 0;
	BOOL neoThemeFound  = NO;
    
    // add the neo theme if needed
	for(NSDictionary *theme in allThemes) {
        if([[theme objectForKey:WCThemesName] isEqualToString:@"Neo"]) {
            neoThemeFound = YES;
            continue;
        }
    }
    
    if(!neoThemeFound) {
        NSDictionary *neoTheme;
        
        neoTheme = [self _defaultNeoTheme];
        
        [self addObject:neoTheme toArrayForKey:WCThemes];
        [self setString:[neoTheme objectForKey:WCThemesIdentifier] forKey:WCTheme];
    }

    // add templates if needed
    allThemes = [self objectForKey:WCThemes];
    
    for(NSDictionary *theme in allThemes) {
		if(![theme objectForKey:WCThemesTemplate]) {
			NSDictionary *newTheme = [theme mutableCopy];
			
			if([[newTheme objectForKey:WCThemesName] isEqualToString:@"Basic"])
				[newTheme setValue:@"fr.read-write.Basic" forKey:WCThemesTemplate];
			
			else if([[newTheme objectForKey:WCThemesName] isEqualToString:@"Hacker"])
				[newTheme setValue:@"fr.read-write.Hacker" forKey:WCThemesTemplate];
			
			else if([[newTheme objectForKey:WCThemesName] isEqualToString:@"Neo"])
				[newTheme setValue:@"fr.read-write.Neo" forKey:WCThemesTemplate];
			
			[self replaceObjectAtIndex:index withObject:newTheme inArrayForKey:WCThemes];
			
			[newTheme release];
		}
		index++;
	}
    
    /* Update from 2.0 (259) to 2.0 (260 - servers sidebar) */
    if(![self objectForKey:WCHideServerList])
        [self setObject:[NSNumber numberWithBool:NO] forKey:WCHideServerList];
    
    if(![self objectForKey:WCHideUserList])
        [self setObject:[NSNumber numberWithBool:NO] forKey:WCHideUserList];
    
    /* Update from 2.0 (263) to 2.0 (264 - application menu) */
    if(![self objectForKey:WCApplicationMenuEnabled])
        [self setObject:[NSNumber numberWithBool:NO] forKey:WCApplicationMenuEnabled];

}



#pragma mark -

- (NSDictionary *)_themeWithBuiltinName:(NSString *)builtinName {
	NSEnumerator	*enumerator;
	NSDictionary	*theme;
	
	enumerator = [[self objectForKey:WCThemes] objectEnumerator];
	
	while((theme = [enumerator nextObject])) {
		if([[theme objectForKey:WCThemesBuiltinName] isEqualToString:builtinName])
			return theme;
	}
	
	return NULL;
}



#pragma mark -

- (NSDictionary *)_defaultBasicTheme {
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
     NSLS(@"Basic", @"Theme"),										WCThemesName,
     @"Basic",														WCThemesBuiltinName,
     [NSString UUIDString],											WCThemesIdentifier,
     @"fr.read-write.Basic",										WCThemesTemplate,
     WIStringFromFont([NSFont userFixedPitchFontOfSize:11.0]),		WCThemesChatFont,
     WIStringFromColor([NSColor blackColor]),						WCThemesChatTextColor,
     WIStringFromColor([NSColor whiteColor]),						WCThemesChatBackgroundColor,
     WIStringFromColor([NSColor redColor]),							WCThemesChatEventsColor,
     WIStringFromColor([NSColor redColor]),							WCThemesChatTimestampEveryLineColor,
     WIStringFromColor([NSColor blueColor]),						WCThemesChatURLsColor,
     WIStringFromFont([NSFont fontWithName:@"Helvetica" size:13.0]),    WCThemesMessagesFont,
     WIStringFromColor([NSColor blackColor]),						WCThemesMessagesTextColor,
     WIStringFromColor([NSColor whiteColor]),						WCThemesMessagesBackgroundColor,
     WIStringFromFont([NSFont fontWithName:@"Helvetica" size:13.0]),	WCThemesBoardsFont,
     WIStringFromColor([NSColor blackColor]),						WCThemesBoardsTextColor,
     WIStringFromColor([NSColor whiteColor]),						WCThemesBoardsBackgroundColor,
     [NSNumber numberWithBool:YES],									WCThemesShowSmileys,
     [NSNumber numberWithBool:YES],									WCThemesChatTimestampEveryLine,
     [NSNumber numberWithInteger:WCThemesUserListIconSizeLarge],	WCThemesUserListIconSize,
     [NSNumber numberWithBool:NO],									WCThemesUserListAlternateRows,
     [NSNumber numberWithBool:YES],									WCThemesFileListAlternateRows,
     [NSNumber numberWithInteger:WCThemesFileListIconSizeLarge],	WCThemesFileListIconSize,
     [NSNumber numberWithBool:YES],									WCThemesTransferListShowProgressBar,
     [NSNumber numberWithBool:YES],									WCThemesTransferListAlternateRows,
     [NSNumber numberWithBool:YES],									WCThemesTrackerListAlternateRows,
     [NSNumber numberWithInteger:WCThemesMonitorIconSizeLarge],		WCThemesMonitorIconSize,
     [NSNumber numberWithBool:YES],									WCThemesMonitorAlternateRows,
    NULL];
    
    return dictionary;
}

- (NSDictionary *)_defaultHackerTheme {
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
     NSLS(@"Hacker", @"Theme"),										WCThemesName,
     @"Hacker",														WCThemesBuiltinName,
     [NSString UUIDString],											WCThemesIdentifier,
     @"fr.read-write.Vintage",										WCThemesTemplate,
     WIStringFromFont([NSFont fontWithName:@"Monaco" size:11.0]),	WCThemesChatFont,
     WIStringFromColor([NSColor colorWithCalibratedRed:0.3680 green:0.7385 blue:0.2999 alpha:1.0000]), WCThemesChatTextColor,
     WIStringFromColor([NSColor colorWithCalibratedRed:0.0642 green:0.1134 blue:0.0069 alpha:1.0000]), WCThemesChatBackgroundColor,
     WIStringFromColor([NSColor colorWithCalibratedRed:0.7136 green:1.0000 blue:0.9645 alpha:1.0000]), WCThemesChatEventsColor,
     WIStringFromColor([NSColor colorWithCalibratedRed:0.7315 green:0.7472 blue:0.4047 alpha:1.0000]), WCThemesChatTimestampEveryLineColor,
     WIStringFromColor([NSColor colorWithCalibratedRed:0.8344 green:0.8901 blue:0.0000 alpha:1.0000]), WCThemesChatURLsColor,
     WIStringFromFont([NSFont fontWithName:@"Monaco" size:11.0]),	WCThemesMessagesFont,
     WIStringFromColor([NSColor colorWithCalibratedRed:0.3680 green:0.7385 blue:0.2999 alpha:1.0000]), WCThemesMessagesTextColor,
     WIStringFromColor([NSColor colorWithCalibratedRed:0.0642 green:0.1134 blue:0.0069 alpha:1.0000]), WCThemesMessagesBackgroundColor,
     WIStringFromFont([NSFont fontWithName:@"Monaco" size:11.0]),	WCThemesBoardsFont,
     WIStringFromColor([NSColor colorWithCalibratedRed:0.3680 green:0.7385 blue:0.2999 alpha:1.0000]), WCThemesBoardsTextColor,
     WIStringFromColor([NSColor colorWithCalibratedRed:0.0642 green:0.1134 blue:0.0069 alpha:1.0000]), WCThemesBoardsBackgroundColor,
     [NSNumber numberWithBool:YES],									WCThemesShowSmileys,
     [NSNumber numberWithBool:NO],									WCThemesChatTimestampEveryLine,
     [NSNumber numberWithInteger:WCThemesUserListIconSizeLarge],		WCThemesUserListIconSize,
     [NSNumber numberWithBool:NO],									WCThemesUserListAlternateRows,
     [NSNumber numberWithInteger:WCThemesFileListIconSizeLarge],		WCThemesFileListIconSize,
     [NSNumber numberWithBool:YES],									WCThemesFileListAlternateRows,
     [NSNumber numberWithBool:YES],									WCThemesTransferListShowProgressBar,
     [NSNumber numberWithBool:YES],									WCThemesTransferListAlternateRows,
     [NSNumber numberWithBool:YES],									WCThemesTrackerListAlternateRows,
     [NSNumber numberWithInteger:WCThemesMonitorIconSizeLarge],		WCThemesMonitorIconSize,
     [NSNumber numberWithBool:YES],									WCThemesMonitorAlternateRows,
     NULL];
    
    return dictionary;
}

- (NSDictionary *)_defaultNeoTheme {
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
     NSLS(@"Neo", @"Theme"),                                                         WCThemesName,
     @"Neo",                                                                         WCThemesBuiltinName,
     basicThemeIdentifier,                                                           WCThemesIdentifier,
     @"fr.read-write.Neo",                                                           WCThemesTemplate,
     WIStringFromFont([NSFont fontWithName:@"Lucida Grande" size:11.0]),             WCThemesChatFont,
     WIStringFromColor([NSColor colorWithCalibratedWhite:0.3333 alpha:1.0000]),      WCThemesChatTextColor,
     WIStringFromColor([NSColor whiteColor]),                                        WCThemesChatBackgroundColor,
     WIStringFromColor([NSColor whiteColor]),                                        WCThemesChatEventsColor,
     WIStringFromColor([NSColor colorWithCalibratedWhite:0.8000 alpha:1.0000]),      WCThemesChatTimestampEveryLineColor,
     WIStringFromColor([NSColor colorWithCalibratedRed:0.2000 green:0.6000 blue:0.8000 alpha:1.0000]), WCThemesChatURLsColor,
     WIStringFromFont([NSFont fontWithName:@"Lucida Grande" size:11.0]),             WCThemesMessagesFont,
     WIStringFromColor([NSColor colorWithCalibratedWhite:0.3333 alpha:1.0000]),      WCThemesMessagesTextColor,
     WIStringFromColor([NSColor whiteColor]),                                        WCThemesMessagesBackgroundColor,
     WIStringFromFont([NSFont fontWithName:@"Lucida Grande" size:11.0]),             WCThemesBoardsFont,
     WIStringFromColor([NSColor colorWithCalibratedWhite:0.3333 alpha:1.0000]),      WCThemesBoardsTextColor,
     WIStringFromColor([NSColor whiteColor]),                                       WCThemesBoardsBackgroundColor,
     [NSNumber numberWithBool:YES],									WCThemesShowSmileys,
     [NSNumber numberWithBool:YES],									WCThemesChatTimestampEveryLine,
     [NSNumber numberWithInteger:WCThemesUserListIconSizeLarge],		WCThemesUserListIconSize,
     [NSNumber numberWithBool:NO],									WCThemesUserListAlternateRows,
     [NSNumber numberWithInteger:WCThemesFileListIconSizeLarge],		WCThemesFileListIconSize,
     [NSNumber numberWithBool:YES],									WCThemesFileListAlternateRows,
     [NSNumber numberWithBool:YES],									WCThemesTransferListShowProgressBar,
     [NSNumber numberWithBool:YES],									WCThemesTransferListAlternateRows,
     [NSNumber numberWithBool:YES],									WCThemesTrackerListAlternateRows,
     [NSNumber numberWithInteger:WCThemesMonitorIconSizeLarge],		WCThemesMonitorIconSize,
     [NSNumber numberWithBool:YES],									WCThemesMonitorAlternateRows,
     NULL];
    
    return dictionary;
}



@end


@implementation WCSettings

+ (id)settings {
	static BOOL			upgraded;
	static BOOL			migrated;
//	NSString			*domain;
//	NSDictionary		*dictionary;
	id					settings;
	
    
    if(!basicThemeIdentifier)
        basicThemeIdentifier = [[NSString UUIDString] retain];
    
//#ifdef WCConfigurationDebug
//	domain = @"fr.read-write.WiredClientDebug";
//#endif
//	
//#ifdef WCConfigurationRelease
//	domain = @"fr.read-write.WiredClient";	
//#endif
//	
//	NSLog(@"domain: %@", domain);
//	
//	if(!domain)
//		domain = @"fr.read-write.WiredClientDebug";
//	
//	dictionary = [[NSUserDefaults standardUserDefaults] persistentDomainForName:domain];
//	[[NSUserDefaults standardUserDefaults] setPersistentDomain:dictionary forName:domain];
	
	
//	if(!migrated) {
//        dictionary = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"fr.read-write.WiredClient"];
//        
//        // check if already migrated
//        if(!dictionary || ![dictionary boolForKey:WCMigrated20B]) {
//			
//			// for beta migration from 2.0 (243) to 2.0 (244)
//			dictionary = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.zanka.WiredClientP7"];
//			if(dictionary) {
//				[[NSUserDefaults standardUserDefaults] setPersistentDomain:dictionary forName:@"fr.read-write.WiredClient"];
//				
//				if ([[NSUserDefaults standardUserDefaults] objectForKey:@"SUFeedURL"])
//					[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"SUFeedURL"];
//
//				migrated = YES;
//			}
//			
//			// for beta migration from 2.0 zanka to 2.0 rw
//            dictionary = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.zanka.WiredClientDebugP7"];
//			
//            if(dictionary && !migrated) {
//                NSAlert *alert = [NSAlert alertWithMessageText:@"Wired Client Migration"
//                                                 defaultButton:@"Migrate"
//                                               alternateButton:@"Cancel"
//                                                   otherButton:nil
//                                     informativeTextWithFormat:@"Wired Client found an old preferences file (~/Library/Preferences/com.zanka.WiredClientDebugP7). Do you want to migrate it ?"];
//                
//                if([alert runModal] == NSModalResponseOK) {
//                    [[NSUserDefaults standardUserDefaults] setPersistentDomain:dictionary forName:@"fr.read-write.WiredClient"];
//
//					if ([[NSUserDefaults standardUserDefaults] objectForKey:@"SUFeedURL"])
//						[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"SUFeedURL"];
//					
//                    migrated = YES;
//                    
//                } else {
//                    migrated = YES;
//                }
//            } else {
//                migrated = NO;
//            }
//            
//            [[NSUserDefaults standardUserDefaults] synchronize];
//        } else {
//            migrated = YES;
//        }
//	}
	
	settings = [super settings];
    
    if(migrated)
        [settings setBool:YES forKey:WCMigrated20B];
	
	if(!upgraded) {
		[settings _upgrade];
		
		upgraded = YES;
	}
    
    [settings synchronize];
    
    /* Update to 2.0.1 */
    if(![settings objectForKey:WCOrderFrontWhenDisconnected])
        [settings setObject:[NSNumber numberWithBool:NO] forKey:WCOrderFrontWhenDisconnected];
	
	return settings;
}



#pragma mark -

- (NSDictionary *)defaults {
	static NSDictionary		*defaults;
    
	if(!defaults) {
		
		defaults = [NSDictionary dictionaryWithObjectsAndKeys:
			NSUserName(),
				WCNick,
			@"",
				WCStatus,
                    @"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",
				WCIcon,
			
            [NSNumber numberWithBool:YES],
                WCShowChatWindowAtStartup,
			[NSNumber numberWithBool:NO],
				WCShowConnectAtStartup,
			[NSNumber numberWithBool:NO],
				WCShowServersAtStartup,
                    
            [NSNumber numberWithBool:NO],
                WCApplicationMenuEnabled,
			
			[NSNumber numberWithBool:YES],
				WCConfirmDisconnect,
			[NSNumber numberWithBool:NO],
				WCAutoReconnect,
            [NSNumber numberWithBool:NO],
                WCOrderFrontWhenDisconnected,
			
            [NSNumber numberWithBool:NO],
                WCHideServerList,
            [NSNumber numberWithBool:NO],
                WCHideUserList,
                    
			[NSNumber numberWithBool:YES],
				WCCheckForUpdate,
			
            [NSArray arrayWithObject:@"Pack:Wired"],
                WCEnabledEmoticonPacks,
                    
			basicThemeIdentifier,
				WCTheme,
                    
			[NSArray arrayWithObjects:
				[self _defaultBasicTheme],
				[self _defaultHackerTheme],
				[self _defaultNeoTheme],
			 NULL],
				WCThemes,
                    
            [NSNumber numberWithInteger:WCThreadsSplitViewOrientationVertical],
                WCThreadsSplitViewOrientation,
                    
            [NSArray arrayWithObject:
                [NSDictionary dictionaryWithObjectsAndKeys:
                    @"Wired Dev Server",			WCBookmarksName,
                    @"wired.read-write.fr",		WCBookmarksAddress,
                    @"guest",						WCBookmarksLogin,
                    @"",							WCBookmarksNick,
                    @"",							WCBookmarksStatus,
                    [NSString UUIDString],		WCBookmarksIdentifier,
                NULL]],
                WCBookmarks,
			
			[NSNumber numberWithBool:NO],
				WCChatHistoryScrollback,
			[NSNumber numberWithInt:WCChatHistoryScrollbackModifierNone],
				WCChatHistoryScrollbackModifier,
			[NSNumber numberWithBool:YES],
				WCChatTabCompleteNicks,
			@": ",
				WCChatTabCompleteNicksString,
			[NSNumber numberWithBool:NO],
				WCChatTimestampChat,
			[NSNumber numberWithInt:600],
				WCChatTimestampChatInterval,

			[NSArray array],
				WCHighlights,

			[NSArray array],
				WCIgnores,

			[NSArray arrayWithObjects:
				[NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithInt:WCEventsServerConnected],			WCEventsEvent,
					NULL],
				[NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithInt:WCEventsServerDisconnected],		WCEventsEvent,
					NULL],
				[NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithInt:WCEventsError],						WCEventsEvent,
					NULL],
				[NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithInt:WCEventsUserJoined],				WCEventsEvent,
					[NSNumber numberWithBool:YES],								WCEventsPostInChat,
					NULL],
				[NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithInt:WCEventsUserChangedNick],			WCEventsEvent,
					[NSNumber numberWithBool:YES],								WCEventsPostInChat,
					NULL],
				[NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithInt:WCEventsUserLeft],					WCEventsEvent,
					[NSNumber numberWithBool:YES],								WCEventsPostInChat,
					NULL],
				[NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithInt:WCEventsChatReceived],				WCEventsEvent,
					NULL],
				[NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithInt:WCEventsChatSent],					WCEventsEvent,
				NULL],
				[NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithInt:WCEventsMessageReceived],			WCEventsEvent,
					NULL],
				[NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithInt:WCEventsBoardPostReceived],			WCEventsEvent,
					NULL],
				[NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithInt:WCEventsBroadcastReceived],			WCEventsEvent,
					NULL],
				[NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithInt:WCEventsTransferStarted],			WCEventsEvent,
					NULL],
				[NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithInt:WCEventsTransferFinished],			WCEventsEvent,
					NULL],
				[NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithInt:WCEventsUserChangedStatus],			WCEventsEvent,
					[NSNumber numberWithBool:NO],								WCEventsPostInChat,
					NULL],
				[NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithInt:WCEventsHighlightedChatReceived],	WCEventsEvent,
					NULL],
				[NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithInt:WCEventsChatInvitationReceived],	WCEventsEvent,
					NULL],
				NULL],
				WCEvents,
			[NSNumber numberWithFloat:1.0],
				WCEventsVolume,

			[@"~/Downloads" stringByExpandingTildeInPath],
				WCDownloadFolder,
			[NSNumber numberWithBool:NO],
				WCOpenFoldersInNewWindows,
			[NSNumber numberWithBool:YES],
				WCQueueTransfers,
			[NSNumber numberWithBool:YES],
				WCCheckForResourceForks,
			[NSNumber numberWithBool:NO],
				WCRemoveTransfers,
			[NSNumber numberWithInt:WCFilesStyleList],
				WCFilesStyle,
			
			[NSArray arrayWithObject:
				[NSDictionary dictionaryWithObjectsAndKeys:
					@"Read-Write Tracker",          WCTrackerBookmarksName,
					@"wired.read-write.fr",         WCTrackerBookmarksAddress,
					@"",							WCTrackerBookmarksLogin,
					[NSString UUIDString],			WCTrackerBookmarksIdentifier,
					NULL]],
				WCTrackerBookmarks,
				
			[NSDictionary dictionary],
				WCWindowProperties,
			
			[NSArray array],
				WCReadBoardPosts,
			[NSNumber numberWithBool:NO],
				WCBoardPostContinuousSpellChecking,
			
            [NSNumber numberWithInteger:30],
                WCNetworkConnectionTimeout,
                    
            [NSNumber numberWithInteger:10],
                WCNetworkReadTimeout,
                  
            [NSNumber numberWithInteger:2],
                WCNetworkEncryptionCipher,
                    
            [NSNumber numberWithBool:YES],
                WCNetworkCompressionEnabled,
                    
			[NSNumber numberWithBool:NO],
				WCDebug,
					
			[NSNumber numberWithBool:YES],
				WCChatEmbedHTMLInChatEnabled,
					
			[NSNumber numberWithBool:YES],
				WCChatLogsHistoryEnabled,
                    
            [NSNumber numberWithBool:NO],
                WCMigrated20B,
                    
			NULL];
	}
	
	return defaults;
}



#pragma mark -

- (NSDictionary *)bookmarkForURL:(WIURL *)url {
    NSEnumerator	*enumerator;
	NSDictionary	*bookmark;
	
	enumerator = [[self objectForKey:WCBookmarks] objectEnumerator];
	
	while((bookmark = [enumerator nextObject])) {
		if([[bookmark objectForKey:WCBookmarksAddress] isEqualToString:[url host]] &&
           [[bookmark objectForKey:WCBookmarksLogin] isEqualToString:[url user]])
			return bookmark;
	}
	
	return NULL;
}



#pragma mark -

- (NSDictionary *)themeWithIdentifier:(NSString *)identifier {
	NSEnumerator	*enumerator;
	NSDictionary	*theme;
	
	enumerator = [[self objectForKey:WCThemes] objectEnumerator];
	
	while((theme = [enumerator nextObject])) {
		if([[theme objectForKey:WCThemesIdentifier] isEqualToString:identifier])
			return theme;
	}
	
	return NULL;
}



#pragma mark -

- (WITemplateBundle *)templateBundleWithIdentifier:(NSString *)identifier {
	WITemplateBundle	*bundle;
		
	WITemplateBundleManager *privateTemplateManager	= [WITemplateBundleManager templateManagerForPath:[[NSBundle mainBundle] resourcePath]];
	WITemplateBundleManager *publicTemplateManager	= [WITemplateBundleManager templateManagerForPath:[WCApplicationSupportPath stringByStandardizingPath] isPrivate:NO];
	
	bundle = [privateTemplateManager templateWithIdentifier:identifier];
	
	if(bundle)
		return bundle;
	
	bundle = [publicTemplateManager templateWithIdentifier:identifier];
	
	if(bundle)
		return bundle;
		
	return nil;
}



#pragma mark -

- (NSDictionary *)eventWithTag:(NSUInteger)tag {
	NSEnumerator	*enumerator;
	NSDictionary	*event;
	
	enumerator = [[self objectForKey:WCEvents] objectEnumerator];
	
	while((event = [enumerator nextObject])) {
		if([event unsignedIntegerForKey:WCEventsEvent] == tag)
			return event;
	}
	
	return NULL;
}

@end
