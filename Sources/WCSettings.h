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

extern NSString * const						WCNick;
extern NSString * const						WCStatus;
extern NSString * const						WCIcon;

extern NSString * const						WCCheckForUpdate;

extern NSString * const						WCShowChatWindowAtStartup;
extern NSString * const						WCShowConnectAtStartup;
extern NSString * const						WCShowServersAtStartup;

extern NSString * const                     WCApplicationMenuEnabled;

extern NSString * const						WCHideUserList;
extern NSString * const						WCHideServerList;

extern NSString * const						WCConfirmDisconnect;
extern NSString * const						WCAutoReconnect;
extern NSString * const						WCOrderFrontWhenDisconnected;

extern NSString * const						WCTheme;

extern NSString * const						WCThemes;
extern NSString * const						WCThemesName;
extern NSString * const						WCThemesBuiltinName;
extern NSString * const						WCThemesIdentifier;
extern NSString * const						WCThemesTemplate;
extern NSString * const						WCThemesShowSmileys;
extern NSString * const						WCThemesChatFont;
extern NSString * const						WCThemesChatTextColor;
extern NSString * const						WCThemesChatBackgroundColor;
extern NSString * const						WCThemesChatEventsColor;
extern NSString * const						WCThemesChatURLsColor;
extern NSString * const						WCThemesChatTimestampEveryLineColor;
extern NSString * const						WCThemesChatTimestampEveryLine;
extern NSString * const						WCThemesMessagesFont;
extern NSString * const						WCThemesMessagesTextColor;
extern NSString * const						WCThemesMessagesBackgroundColor;
extern NSString * const						WCThemesBoardsFont;
extern NSString * const						WCThemesBoardsTextColor;
extern NSString * const						WCThemesBoardsBackgroundColor;
extern NSString * const						WCThemesUserListIconSize;

enum {
	WCThemesUserListIconSizeLarge			= 1,
	WCThemesUserListIconSizeSmall			= 0
};

extern NSString * const						WCThemesUserListAlternateRows;
extern NSString * const						WCThemesFileListAlternateRows;
extern NSString * const						WCThemesFileListIconSize;

enum {
	WCThemesFileListIconSizeLarge			= 1,
	WCThemesFileListIconSizeSmall			= 0
};

extern NSString * const						WCThemesTransferListShowProgressBar;
extern NSString * const						WCThemesTransferListAlternateRows;
extern NSString * const						WCThemesTrackerListAlternateRows;
extern NSString * const						WCThemesMonitorIconSize;

enum {
	WCThemesMonitorIconSizeLarge			= 1,
	WCThemesMonitorIconSizeSmall			= 0
};

extern NSString * const						WCThemesMonitorAlternateRows;
extern NSString * const						WCThreadsSplitViewOrientation;

enum {
	WCThreadsSplitViewOrientationVertical   = 1,
	WCThreadsSplitViewOrientationHorizontal = 0
};

extern NSString * const						WCMessageConversations;
extern NSString * const						WCBroadcastConversations;

extern NSString * const						WCBookmarks;
extern NSString * const						WCBookmarksName;
extern NSString * const						WCBookmarksAddress;
extern NSString * const						WCBookmarksLogin;
extern NSString * const						WCBookmarksPassword;
extern NSString * const						WCBookmarksIdentifier;
extern NSString * const						WCBookmarksNick;
extern NSString * const						WCBookmarksStatus;
extern NSString * const						WCBookmarksAutoConnect;
extern NSString * const						WCBookmarksAutoReconnect;
extern NSString * const						WCBookmarksTheme;

extern NSString * const						WCChatHistoryScrollback;
extern NSString * const						WCChatHistoryScrollbackModifier;

enum {
	WCChatHistoryScrollbackModifierNone		= 0,
	WCChatHistoryScrollbackModifierCommand	= 1,
	WCChatHistoryScrollbackModifierOption	= 2,
	WCChatHistoryScrollbackModifierControl	= 3
};

extern NSString * const						WCChatTabCompleteNicks;
extern NSString * const						WCChatTabCompleteNicksString;
extern NSString * const						WCChatTimestampChat;
extern NSString * const						WCChatTimestampChatInterval;
extern NSString * const						WCChatLogsHistoryEnabled;
extern NSString * const						WCChatLogsPlainTextEnabled;
extern NSString * const						WCChatLogsPath;
extern NSString * const						WCChatEmbedHTMLInChatEnabled;
extern NSString * const						WCChatAnimatedImagesEnabled;

extern NSString * const						WCHighlights;
extern NSString * const						WCHighlightsPattern;
extern NSString * const						WCHighlightsColor;

extern NSString * const						WCIgnores;
extern NSString * const						WCIgnoresNick;

extern NSString * const						WCEvents;
extern NSString * const						WCEventsEvent;

enum {
	WCEventsServerConnected					= 1,
	WCEventsServerDisconnected				= 2,
	WCEventsError							= 3,
	WCEventsUserJoined						= 4,
	WCEventsUserChangedNick					= 5,
	WCEventsUserLeft						= 6,
	WCEventsChatReceived					= 7,
	WCEventsMessageReceived					= 8,
	WCEventsBoardPostReceived				= 9,
	WCEventsBroadcastReceived				= 10,
	WCEventsTransferStarted					= 11,
	WCEventsTransferFinished				= 12,
	WCEventsUserChangedStatus				= 13,
	WCEventsHighlightedChatReceived			= 14,
	WCEventsChatInvitationReceived			= 15,
	WCEventsChatSent						= 16
};

extern NSString * const						WCEventsPlaySound;
extern NSString * const						WCEventsSound;
extern NSString * const						WCEventsBounceInDock;
extern NSString * const						WCEventsPostInChat;
extern NSString * const						WCEventsShowDialog;
extern NSString * const						WCEventsNotificationCenter;

extern NSString * const						WCEventsVolume;

extern NSString * const						WCTransferList;
extern NSString * const						WCDownloadFolder;
extern NSString * const						WCOpenFoldersInNewWindows;
extern NSString * const						WCQueueTransfers;
extern NSString * const						WCCheckForResourceForks;
extern NSString * const						WCRemoveTransfers;
extern NSString * const						WCFilesStyle;

enum {
	WCFilesStyleList						= 0,
	WCFilesStyleTree						= 1
};

extern NSString * const						WCTrackerBookmarks;
extern NSString * const						WCTrackerBookmarksName;
extern NSString * const						WCTrackerBookmarksAddress;
extern NSString * const						WCTrackerBookmarksLogin;
extern NSString * const						WCTrackerBookmarksPassword;
extern NSString * const						WCTrackerBookmarksIdentifier;

extern NSString * const						WCWindowProperties;

extern NSString * const						WCCollapsedBoards;
extern NSString * const						WCReadBoardPosts;
extern NSString * const						WCBoardFilters;
extern NSString * const						WCBoardPostContinuousSpellChecking;

extern NSString * const						WCPlaces;

extern NSString * const                     WCNetworkConnectionTimeout;
extern NSString * const                     WCNetworkReadTimeout;
extern NSString * const                     WCNetworkEncryptionCipher;
extern NSString * const                     WCNetworkCompressionEnabled;

extern NSString * const						WCDebug;
extern NSString * const						WCMigrated20B;

@interface WCSettings : WISettings

- (NSDictionary *)bookmarkForURL:(WIURL *)url;

- (NSDictionary *)themeWithIdentifier:(NSString *)identifier;
- (WITemplateBundle *)templateBundleWithIdentifier:(NSString *)identifier;

- (NSDictionary *)eventWithTag:(NSUInteger)tag;

@end
