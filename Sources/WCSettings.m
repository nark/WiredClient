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
NSString * const WCBookmarksEncryptionCipher            = @"EncryptionCipher";

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

//- (NSDictionary *)_defaultBasicTheme;
//- (NSDictionary *)_defaultHackerTheme;
//- (NSDictionary *)_defaultNeoTheme;

@end


@implementation WCSettings(Private)

static NSString *defaultThemeIdentifier;


- (void)_upgrade {
//
//    NSEnumerator            *enumerator, *keyEnumerator;
//    NSDictionary            *defaults, *defaultTheme;
//    NSArray                    *themes, *bookmarks;
//    NSMutableArray            *newThemes, *newBookmarks;
//    NSDictionary            *theme, *builtinTheme, *bookmark;
//    NSMutableDictionary        *newTheme, *newBookmark;
//    NSString                *key, *password, *identifier, *builtinName;
//
//    defaults        = [self defaults];
//    defaultTheme    = [[defaults objectForKey:WCThemes] objectAtIndex:0];
//
//    /* Convert old font/color settings to theme */
//    if([[self objectForKey:WCThemes] isEqualToArray:[NSArray arrayWithObject:defaultTheme]]) {
//        newTheme = [[defaultTheme mutableCopy] autorelease];
//
//        if([self objectForKey:_WCChatURLsColor]) {
//            [newTheme setObject:WIStringFromColor([NSUnarchiver unarchiveObjectWithData:[self objectForKey:_WCChatURLsColor]])
//                         forKey:WCThemesChatURLsColor];
//        }
//
//        if([self objectForKey:_WCChatTextColor]) {
//            [newTheme setObject:WIStringFromColor([NSUnarchiver unarchiveObjectWithData:[self objectForKey:_WCChatTextColor]])
//                         forKey:WCThemesChatTextColor];
//        }
//
//        if([self objectForKey:_WCChatBackgroundColor]) {
//            [newTheme setObject:WIStringFromColor([NSUnarchiver unarchiveObjectWithData:[self objectForKey:_WCChatBackgroundColor]])
//                         forKey:WCThemesChatBackgroundColor];
//        }
//
//        if([self objectForKey:_WCChatEventsColor]) {
//            [newTheme setObject:WIStringFromColor([NSUnarchiver unarchiveObjectWithData:[self objectForKey:_WCChatEventsColor]])
//                         forKey:WCThemesChatEventsColor];
//        }
//
//        if([self objectForKey:_WCChatFont]) {
//            [newTheme setObject:WIStringFromFont([NSUnarchiver unarchiveObjectWithData:[self objectForKey:_WCChatFont]])
//                         forKey:WCThemesChatFont];
//        }
//
//        if([self objectForKey:_WCTimestampEveryLine]) {
//            [newTheme setObject:[self objectForKey:_WCTimestampEveryLine]
//                         forKey:WCThemesChatTimestampEveryLine];
//        }
//
//        if([self objectForKey:_WCTimestampEveryLineColor]) {
//            [newTheme setObject:WIStringFromColor([NSUnarchiver unarchiveObjectWithData:[self objectForKey:_WCTimestampEveryLineColor]])
//                         forKey:WCThemesChatTimestampEveryLineColor];
//        }
//
//        if([self objectForKey:_WCMessagesTextColor]) {
//            [newTheme setObject:WIStringFromColor([NSUnarchiver unarchiveObjectWithData:[self objectForKey:_WCMessagesTextColor]])
//                         forKey:WCThemesMessagesTextColor];
//        }
//
//        if([self objectForKey:_WCMessagesBackgroundColor]) {
//            [newTheme setObject:WIStringFromColor([NSUnarchiver unarchiveObjectWithData:[self objectForKey:_WCMessagesBackgroundColor]])
//                         forKey:WCThemesMessagesBackgroundColor];
//        }
//
//        if([self objectForKey:_WCMessagesFont]) {
//            [newTheme setObject:WIStringFromFont([NSUnarchiver unarchiveObjectWithData:[self objectForKey:_WCMessagesFont]])
//                         forKey:WCThemesMessagesFont];
//        }
//
//        if([self objectForKey:_WCNewsTextColor]) {
//            [newTheme setObject:WIStringFromColor([NSUnarchiver unarchiveObjectWithData:[self objectForKey:_WCNewsTextColor]])
//                         forKey:WCThemesBoardsTextColor];
//        }
//
//        if([self objectForKey:_WCNewsBackgroundColor]) {
//            [newTheme setObject:WIStringFromColor([NSUnarchiver unarchiveObjectWithData:[self objectForKey:_WCNewsBackgroundColor]])
//                         forKey:WCThemesBoardsBackgroundColor];
//        }
//
//        if([self objectForKey:_WCNewsFont]) {
//            [newTheme setObject:WIStringFromFont([NSUnarchiver unarchiveObjectWithData:[self objectForKey:_WCNewsFont]])
//                         forKey:WCThemesBoardsFont];
//        }
//
//        if([self objectForKey:_WCFilesAlternateRows]) {
//            [newTheme setObject:[self objectForKey:_WCFilesAlternateRows]
//                         forKey:WCThemesFileListAlternateRows];
//        }
//
//        if([self objectForKey:_WCTransfersShowProgressBar]) {
//            [newTheme setObject:[self objectForKey:_WCTransfersShowProgressBar]
//                         forKey:WCThemesTransferListShowProgressBar];
//        }
//
//        if([self objectForKey:_WCTransfersAlternateRows]) {
//            [newTheme setObject:[self objectForKey:_WCTransfersAlternateRows]
//                         forKey:WCThemesTransferListAlternateRows];
//        }
//
//        if([self objectForKey:_WCTrackersAlternateRows]) {
//            [newTheme setObject:[self objectForKey:_WCTrackersAlternateRows]
//                         forKey:WCThemesTrackerListAlternateRows];
//        }
//
//        if([self objectForKey:_WCShowSmileys]) {
//            [newTheme setObject:[self objectForKey:_WCShowSmileys]
//                         forKey:WCThemesShowSmileys];
//        }
//
//        if(![newTheme isEqualToDictionary:defaultTheme]) {
//            [newTheme setObject:@"Wired Client 1.x" forKey:WCThemesName];
//            [newTheme setObject:[NSString UUIDString] forKey:WCThemesIdentifier];
//
//            [self addObject:newTheme toArrayForKey:WCThemes];
//        }
//
//        /*
//        [self removeObjectForKey:_WCChatTextColor];
//        [self removeObjectForKey:_WCChatBackgroundColor];
//        [self removeObjectForKey:_WCChatEventsColor];
//        [self removeObjectForKey:_WCChatURLsColor];
//        [self removeObjectForKey:_WCChatFont];
//        [self removeObjectForKey:_WCChatUserListAlternateRows];
//        [self removeObjectForKey:_WCChatUserListIconSize];
//        [self removeObjectForKey:_WCTimestampEveryLineColor];
//        [self removeObjectForKey:_WCMessagesTextColor];
//        [self removeObjectForKey:_WCMessagesBackgroundColor];
//        [self removeObjectForKey:_WCMessagesFont];
//        [self removeObjectForKey:_WCMessagesListAlternateRows];
//        [self removeObjectForKey:_WCNewsTextColor];
//        [self removeObjectForKey:_WCNewsBackgroundColor];
//        [self removeObjectForKey:_WCNewsFont];
//        [self removeObjectForKey:_WCFilesAlternateRows];
//        [self removeObjectForKey:_WCTransfersShowProgressBar];
//        [self removeObjectForKey:_WCTransfersAlternateRows];
//        [self removeObjectForKey:_WCTrackersAlternateRows];
//        [self removeObjectForKey:_WCShowSmileys];
//        */
//    }
//
//    /* Convert themes */
//    builtinName        = NULL;
//    identifier        = [self objectForKey:WCTheme];
//    themes            = [self objectForKey:WCThemes];
//    newThemes        = [NSMutableArray array];
//    enumerator        = [themes objectEnumerator];
//
//    while((theme = [enumerator nextObject])) {
//        if([theme objectForKey:WCThemesBuiltinName]) {
//            if([[theme objectForKey:WCThemesIdentifier] isEqualToString:identifier])
//                builtinName = [theme objectForKey:WCThemesBuiltinName];
//        } else {
//            newTheme        = [[theme mutableCopy] autorelease];
//            keyEnumerator    = [defaultTheme keyEnumerator];
//
//            while((key = [keyEnumerator nextObject])) {
//                if(![key isEqualToString:WCThemesBuiltinName]) {
//                    if(![newTheme objectForKey:key])
//                        [newTheme setObject:[defaultTheme objectForKey:key] forKey:key];
//                }
//            }
//
//            [newThemes addObject:newTheme];
//        }
//    }
//
//    /* Add all default themes */
//    enumerator = [[defaults objectForKey:WCThemes] reverseObjectEnumerator];
//
//    while((builtinTheme = [enumerator nextObject])) {
//        if([newThemes count] > 0)
//            [newThemes insertObject:builtinTheme atIndex:0];
//        else
//            [newThemes addObject:builtinTheme];
//
//        if(builtinName && [[builtinTheme objectForKey:WCThemesBuiltinName] isEqualToString:builtinName])
//            [self setObject:[builtinTheme objectForKey:WCThemesIdentifier] forKey:WCTheme];
//    }
//
//    [self setObject:newThemes forKey:WCThemes];
//
//    /* Convert bookmarks */
//    bookmarks        = [self objectForKey:WCBookmarks];
//    newBookmarks    = [NSMutableArray array];
//    enumerator        = [bookmarks objectEnumerator];
//
//    while((bookmark = [enumerator nextObject])) {
//        newBookmark = [[bookmark mutableCopy] autorelease];
//
//        if(![newBookmark objectForKey:WCBookmarksIdentifier])
//            [newBookmark setObject:[NSString UUIDString] forKey:WCBookmarksIdentifier];
//
//        if(![newBookmark objectForKey:WCBookmarksNick])
//            [newBookmark setObject:@"" forKey:WCBookmarksNick];
//
//        if(![newBookmark objectForKey:WCBookmarksStatus])
//            [newBookmark setObject:@"" forKey:WCBookmarksStatus];
//
//        password = [newBookmark objectForKey:WCBookmarksPassword];
//
//        if(password) {
//            if([password length] > 0)
//                [[WCKeychain keychain] setPassword:password forBookmark:newBookmark];
//
//            [newBookmark removeObjectForKey:WCBookmarksPassword];
//        }
//
//        [newBookmarks addObject:newBookmark];
//    }
//
//    [self setObject:newBookmarks forKey:WCBookmarks];
//
//    /* Convert tracker bookmarks */
//    bookmarks        = [self objectForKey:WCTrackerBookmarks];
//    newBookmarks    = [NSMutableArray array];
//    enumerator        = [bookmarks objectEnumerator];
//
//    while((bookmark = [enumerator nextObject])) {
//        newBookmark = [[bookmark mutableCopy] autorelease];
//
//        if(![newBookmark objectForKey:WCTrackerBookmarksIdentifier])
//            [newBookmark setObject:[NSString UUIDString] forKey:WCTrackerBookmarksIdentifier];
//
//        if(![newBookmark objectForKey:WCTrackerBookmarksLogin])
//            [newBookmark setObject:@"" forKey:WCTrackerBookmarksLogin];
//
//        [newBookmarks addObject:newBookmark];
//    }
//
//    /* Check download folder */
//    if(![[NSFileManager defaultManager] directoryExistsAtPath:[self objectForKey:WCDownloadFolder]])
//        [self setObject:[@"~/Desktop" stringByExpandingTildeInPath] forKey:WCDownloadFolder];
//
//    [self setObject:newBookmarks forKey:WCTrackerBookmarks];
//
//
//    /* Upgrade to 2.0b54+ */
//    if(![self objectForKey:WCNetworkConnectionTimeout])
//        [self setObject:[NSNumber numberWithInteger:30] forKey:WCNetworkConnectionTimeout];
//
//    if(![self objectForKey:WCNetworkReadTimeout])
//        [self setObject:[NSNumber numberWithInteger:10] forKey:WCNetworkReadTimeout];
//
//    if(![self objectForKey:WCNetworkEncryptionCipher])
//        [self setObject:[NSNumber numberWithInteger:2] forKey:WCNetworkEncryptionCipher];
//
//    if(![self objectForKey:WCNetworkCompressionEnabled])
//        [self setObject:[NSNumber numberWithBool:YES] forKey:WCNetworkCompressionEnabled];
//
//
//    /* Update from 2.0 (243) to 2.0 (244): add WCEventsChatSent */
//    BOOL chatSentEventFound = NO;
//    NSArray *events = [self objectForKey:WCEvents];
//
//    for(NSDictionary *event in events) {
//        if([[event objectForKey:@"WCEventsEvent"] integerValue] == WCEventsChatSent) {
//            chatSentEventFound = YES;
//            continue;
//        }
//    }
//    if(!chatSentEventFound) {
//        id event = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:WCEventsChatSent], WCEventsEvent, NULL];
//        [self addObject:event toArrayForKey:@"WCEvents"];
//    }
//
//
//    /* Update from 2.0 (244) to 2.0 (245 - webkit): add template in theme */
//    NSArray *allThemes  = [self objectForKey:WCThemes];
//    NSInteger index     = 0;
//    BOOL neoThemeFound  = NO;
//
//    // add the neo theme if needed
//    for(NSDictionary *theme in allThemes) {
//        if([[theme objectForKey:WCThemesName] isEqualToString:@"Neo"]) {
//            neoThemeFound = YES;
//            continue;
//        }
//    }
//
//    if(!neoThemeFound) {
//        NSDictionary *neoTheme;
//
//        neoTheme = [self _defaultLightTheme];
//
//        [self addObject:neoTheme toArrayForKey:WCThemes];
//        [self setString:[neoTheme objectForKey:WCThemesIdentifier] forKey:WCTheme];
//    }
//
//    // add templates if needed
//    allThemes = [self objectForKey:WCThemes];
//
//    for(NSDictionary *theme in allThemes) {
//        if(![theme objectForKey:WCThemesTemplate]) {
//            NSDictionary *newTheme = [theme mutableCopy];
//
////            if([[newTheme objectForKey:WCThemesName] isEqualToString:@"Basic"])
////                [newTheme setValue:@"fr.read-write.Basic" forKey:WCThemesTemplate];
////
////            else if([[newTheme objectForKey:WCThemesName] isEqualToString:@"Hacker"])
////                [newTheme setValue:@"fr.read-write.Hacker" forKey:WCThemesTemplate];
////
////            else
//
//            if([[newTheme objectForKey:WCThemesName] isEqualToString:@"Neo"])
//                [newTheme setValue:@"fr.read-write.Neo" forKey:WCThemesTemplate];
//
//            [self replaceObjectAtIndex:index withObject:newTheme inArrayForKey:WCThemes];
//
//            [newTheme release];
//        }
//        index++;
//    }
//
//    /* Update from 2.0 (259) to 2.0 (260 - servers sidebar) */
//    if(![self objectForKey:WCHideServerList])
//        [self setObject:[NSNumber numberWithBool:NO] forKey:WCHideServerList];
//
//    if(![self objectForKey:WCHideUserList])
//        [self setObject:[NSNumber numberWithBool:NO] forKey:WCHideUserList];
//
//    /* Update from 2.0 (263) to 2.0 (264 - application menu) */
//    if(![self objectForKey:WCApplicationMenuEnabled])
//        [self setObject:[NSNumber numberWithBool:NO] forKey:WCApplicationMenuEnabled];
    
    NSLog(@"Upgrade settings...");
    
    if (![self boolForKey:@"WCMigratedTo_2_5__32"]) {
        NSLog(@"Upgrade settings to 2_5__32...");
        
        // make sure to reset old versions themes
        [self removeObjectForKey:WCThemes];
        [self setString:defaultThemeIdentifier forKey:WCTheme];

        [self setObject:[NSArray arrayWithObjects: [self _defaultTheme], NULL]
                 forKey:WCThemes];

        [self setBool:true forKey:@"WCMigratedTo_2_5__32"];
    }
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

- (NSDictionary *)_defaultTheme {
    NSDictionary *dictionary;
    
    dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                  NSLS(@"Wired", @"Theme"),                                            WCThemesName,
                  @"Wired",                                                            WCThemesBuiltinName,
                  defaultThemeIdentifier,                                                WCThemesIdentifier,
                  @"fr.read-write.Neo",                                            WCThemesTemplate,
                  WIStringFromFont([NSFont userFixedPitchFontOfSize:11.0]),            WCThemesChatFont,
                  WIStringFromColor([NSColor darkGrayColor]),                            WCThemesChatTextColor,
                  WIStringFromColor([NSColor whiteColor]),                            WCThemesChatBackgroundColor,
                  WIStringFromColor([NSColor lightGrayColor]),                      WCThemesChatEventsColor,
                  WIStringFromColor([NSColor lightGrayColor]),                      WCThemesChatTimestampEveryLineColor,
                  WIStringFromColor([NSColor linkColor]),                            WCThemesChatURLsColor,
                  WIStringFromFont([NSFont fontWithName:@"Helvetica" size:13.0]),    WCThemesMessagesFont,
                  WIStringFromColor([NSColor darkGrayColor]),                            WCThemesMessagesTextColor,
                  WIStringFromColor([NSColor whiteColor]),                            WCThemesMessagesBackgroundColor,
                  WIStringFromFont([NSFont fontWithName:@"Helvetica" size:13.0]),    WCThemesBoardsFont,
                  WIStringFromColor([NSColor darkGrayColor]),                            WCThemesBoardsTextColor,
                  WIStringFromColor([NSColor whiteColor]),                            WCThemesBoardsBackgroundColor,
                  [NSNumber numberWithBool:YES],                                        WCThemesShowSmileys,
                  [NSNumber numberWithBool:YES],                                        WCThemesChatTimestampEveryLine,
                  [NSNumber numberWithInteger:WCThemesUserListIconSizeLarge],        WCThemesUserListIconSize,
                  [NSNumber numberWithBool:YES],                                        WCThemesUserListAlternateRows,
                  [NSNumber numberWithBool:YES],                                        WCThemesFileListAlternateRows,
                  [NSNumber numberWithInteger:WCThemesFileListIconSizeLarge],        WCThemesFileListIconSize,
                  [NSNumber numberWithBool:YES],                                        WCThemesTransferListShowProgressBar,
                  [NSNumber numberWithBool:YES],                                        WCThemesTransferListAlternateRows,
                  [NSNumber numberWithBool:YES],                                        WCThemesTrackerListAlternateRows,
                  [NSNumber numberWithInteger:WCThemesMonitorIconSizeLarge],            WCThemesMonitorIconSize,
                  [NSNumber numberWithBool:YES],                                        WCThemesMonitorAlternateRows,
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
	
    
    if(!defaultThemeIdentifier)
        defaultThemeIdentifier = [[NSString UUIDString] retain];
    
    
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
                    
            defaultThemeIdentifier,
				WCTheme,
                    
			[NSArray arrayWithObjects:
             [self _defaultTheme],
             NULL],
				WCThemes,
                    
            [NSNumber numberWithInteger:WCThreadsSplitViewOrientationVertical],
                WCThreadsSplitViewOrientation,
                    
            [NSArray arrayWithObject:
                [NSDictionary dictionaryWithObjectsAndKeys:
                    @"Wired Dev Server",			WCBookmarksName,
                    @"wired.read-write.fr",		    WCBookmarksAddress,
                    @"guest",						WCBookmarksLogin,
                    @"",							WCBookmarksNick,
                    @"",							WCBookmarksStatus,
                    [NSString UUIDString],		    WCBookmarksIdentifier,
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

- (NSDictionary *)themeWithName:(NSString *)name {
    NSEnumerator    *enumerator;
    NSDictionary    *theme;
    
    enumerator = [[self objectForKey:WCThemes] objectEnumerator];
    
    while((theme = [enumerator nextObject])) {
        if([[theme objectForKey:WCThemesBuiltinName] isEqualToString:name])
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
