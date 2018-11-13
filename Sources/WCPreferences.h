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

extern NSString * const								WCPreferencesDidChangeNotification;
extern NSString * const								WCThemeDidChangeNotification;
extern NSString * const								WCEmoticonsDidChangeNotification;
extern NSString * const								WCSelectedThemeDidChangeNotification;
extern NSString * const								WCChatLogsFolderPathChangedNotification;
extern NSString * const								WCBookmarksDidChangeNotification;
extern NSString * const								WCBookmarkDidChangeNotification;
extern NSString * const								WCIgnoresDidChangeNotification;
extern NSString * const								WCTrackerBookmarksDidChangeNotification;
extern NSString * const								WCTrackerBookmarkDidChangeNotification;
extern NSString * const								WCNickDidChangeNotification;
extern NSString * const								WCStatusDidChangeNotification;
extern NSString * const								WCIconDidChangeNotification;

@class WCEmoticonPreferences, WCThemesPreferences;

@interface WCPreferences : WIPreferencesController <NSMenuDelegate, NSTableViewDelegate> {
	IBOutlet NSView									*_generalView;
	IBOutlet NSView									*_themesView;
    IBOutlet NSView									*_appearanceView;
	IBOutlet NSView									*_bookmarksView;
	IBOutlet NSView									*_chatView;
	IBOutlet NSView									*_eventsView;
	IBOutlet NSView									*_filesView;
	IBOutlet NSView									*_trackersView;
	IBOutlet NSView									*_advancedView;
    
	IBOutlet NSTabView								*_chatTabView;

	IBOutlet NSTextField							*_nickTextField;
	IBOutlet NSTextField							*_statusTextField;
	IBOutlet WIImageViewWithImagePicker				*_iconImageView;
	IBOutlet NSButton								*_checkForUpdateButton;
	IBOutlet NSButton								*_showConnectAtStartupButton;
	IBOutlet NSButton								*_showServersAtStartupButton;
	IBOutlet NSButton								*_confirmDisconnectButton;
	IBOutlet NSButton								*_autoReconnectButton;
    IBOutlet NSButton								*_orderFrontOnDisconnectButton;
    
    IBOutlet NSMatrix								*_threadsSplitViewMatrix;
    IBOutlet NSPopUpButton							*_emoticonPacksPopUpButton;
	
    IBOutlet NSWindow                               *_themesWindow;
    IBOutlet NSWindow                               *_addThemeWindow;
    IBOutlet NSWindow                               *_manageThemesWindow;
    IBOutlet NSTextField                            *_addThemeNameTextField;
    IBOutlet NSPopUpButton							*_themesPopUpButton;
	IBOutlet NSButton								*_addThemeButton;
	IBOutlet NSButton								*_deleteThemeButton;
	IBOutlet NSButton								*_selectThemeButton;
    IBOutlet NSButton                               *_customizeThemesButton;
	
	IBOutlet NSPopUpButton							*_themesTemplatesPopUpButton;
	IBOutlet NSWindow								*_themesTemplatesWindow;
	IBOutlet NSTableView							*_themesTemplatesTableView;
	IBOutlet NSTableView							*_themesTableView;
    
	IBOutlet NSTextField							*_themesChatFontTextField;
	IBOutlet NSButton								*_themesChatFontButton;
	IBOutlet NSColorWell							*_themesChatTextColorWell;
	IBOutlet NSColorWell							*_themesChatBackgroundColorWell;
	IBOutlet NSColorWell							*_themesChatURLsColorWell;
	IBOutlet NSColorWell							*_themesChatEventsColorWell;
	IBOutlet NSColorWell							*_themesChatTimestampEveryLineColorWell;
	IBOutlet NSTextField							*_themesMessagesFontTextField;
	IBOutlet NSButton								*_themesMessagesFontButton;
	IBOutlet NSColorWell							*_themesMessagesTextColorWell;
	IBOutlet NSColorWell							*_themesMessagesBackgroundColorWell;
	IBOutlet NSTextField							*_themesBoardsFontTextField;
	IBOutlet NSButton								*_themesBoardsFontButton;
	IBOutlet NSColorWell							*_themesBoardsTextColorWell;
	IBOutlet NSColorWell							*_themesBoardsBackgroundColorWell;
	
	IBOutlet NSButton								*_themesShowSmileysButton;
	IBOutlet NSButton								*_themesChatTimestampEveryLineButton;
	IBOutlet NSMatrix								*_themesUserListIconSizeMatrix;
	IBOutlet NSButton								*_themesUserListAlternateRowsButton;
	IBOutlet NSMatrix								*_themesFileListIconSizeMatrix;
	IBOutlet NSButton								*_themesFileListAlternateRowsButton;
	IBOutlet NSButton								*_themesTransferListShowProgressBarButton;
	IBOutlet NSButton								*_themesTransferListAlternateRowsButton;
	IBOutlet NSButton								*_themesTrackerListAlternateRowsButton;
	IBOutlet NSMatrix								*_themesMonitorIconSizeMatrix;
	IBOutlet NSButton								*_themesMonitorAlternateRowsButton;
	
	IBOutlet NSButton								*_chatHistoryScrollbackButton;
	IBOutlet NSPopUpButton							*_chatHistoryScrollbackModifierPopUpButton;
	IBOutlet NSButton								*_chatTabCompleteNicksButton;
	IBOutlet NSTextField							*_chatTabCompleteNicksTextField;
	IBOutlet NSButton								*_chatTimestampChatButton;
	IBOutlet NSTextField							*_chatTimestampChatIntervalTextField;
	IBOutlet NSButton								*_chatHistoryButton;
	IBOutlet NSButton								*_chatLogsButton;
	IBOutlet NSButton								*_chatLogsHistoryRevealButton;
	IBOutlet NSButton								*_chatLogsPlainTextRevealButton;
	IBOutlet NSPopUpButton							*_chatLogsFolderPopUpButton;
	IBOutlet NSMenuItem								*_chatLogsFolderMenuItem;
	IBOutlet NSButton								*_chatAllowEmbedHTMLButton;
	IBOutlet NSButton								*_chatAnimatedImagesButton;
	
	IBOutlet NSTableView							*_highlightsTableView;
	IBOutlet NSButton								*_addHighlightButton;
	IBOutlet NSButton								*_deleteHighlightButton;
	IBOutlet NSTableColumn							*_highlightsPatternTableColumn;
	IBOutlet NSTableColumn							*_highlightsColorTableColumn;
	
	IBOutlet NSTableView							*_ignoresTableView;
	IBOutlet NSButton								*_addIgnoreButton;
	IBOutlet NSButton								*_deleteIgnoreButton;
	IBOutlet NSTableColumn							*_ignoresNickTableColumn;
	
	IBOutlet NSSlider								*_eventsVolumeSlider;
	IBOutlet NSPopUpButton							*_eventsEventPopUpButton;
	IBOutlet NSButton								*_eventsPlaySoundButton;
	IBOutlet NSPopUpButton							*_eventsSoundsPopUpButton;
	IBOutlet NSButton								*_eventsBounceInDockButton;
	IBOutlet NSButton								*_eventsPostInChatButton;
	IBOutlet NSButton								*_eventsShowDialogButton;
	IBOutlet NSButton								*_eventsNotificationCenterButton;
    
	IBOutlet NSPopUpButton							*_filesDownloadFolderPopUpButton;
	IBOutlet NSMenuItem								*_filesDownloadFolderMenuItem;
	IBOutlet NSButton								*_filesOpenFoldersInNewWindowsButton;
	IBOutlet NSButton								*_filesQueueTransfersButton;
	IBOutlet NSButton								*_filesRemoveTransfersButton;
    
    IBOutlet NSTextField                            *_networkConnectionTimeoutTextField;
    IBOutlet NSTextField                            *_networkReadTimeoutTextField;
    IBOutlet NSPopUpButton                          *_networkCipherPopUpButton;
    IBOutlet NSButton                               *_networkCompressionButton;
    
	IBOutlet NSView									*_bookmarksExportView;
    
    IBOutlet WCThemesPreferences                    *_themesPreferences;
	IBOutlet WCEmoticonPreferences                  *_emoticonPreferences;
    
	WITemplateBundleManager							*_privateTemplateManager;
	WITemplateBundleManager							*_publicTemplateManager;
	
	NSString										*_bookmarksPassword;
	NSString										*_trackerBookmarksPassword;
}

@property (readwrite, retain) IBOutlet              WCEmoticonPreferences *emoticonPreferences;

+ (WCPreferences *)preferences;

- (BOOL)importThemeFromFile:(NSString *)path;
- (BOOL)importTemplateFromFile:(NSString *)path;
- (BOOL)importBookmarksFromFile:(NSString *)path;
- (BOOL)importTrackerBookmarksFromFile:(NSString *)path;
- (NSImage *)imageForTheme:(NSDictionary *)theme size:(NSSize)size;

- (IBAction)changePreferences:(id)sender;

- (IBAction)customizeEmoticons:(id)sender;
- (IBAction)selectEmoticonPack:(id)sender;

- (IBAction)customizeTheme:(id)sender;
- (IBAction)closeTheme:(id)sender;
- (IBAction)addTheme:(id)sender;
- (IBAction)cancelAddTheme:(id)sender;
- (IBAction)okAddTheme:(id)sender;
- (IBAction)editTheme:(id)sender;
- (IBAction)deleteTheme:(id)sender;
- (IBAction)duplicateTheme:(id)sender;
- (IBAction)exportTheme:(id)sender;
- (IBAction)importTheme:(id)sender;
- (IBAction)selectTheme:(id)sender;
- (IBAction)changeTheme:(id)sender;
- (IBAction)changeThemeFont:(id)sender;

- (IBAction)selectThemeTemplate:(id)sender;
- (IBAction)addThemeTemplate:(id)sender;
- (IBAction)manageThemeTemplates:(id)sender;
- (IBAction)closeManageThemeTemplates:(id)sender;
- (IBAction)deleteThemeTemplate:(id)sender;

- (IBAction)exportBookmarks:(id)sender;
- (IBAction)importBookmarks:(id)sender;
- (IBAction)exportTrackerBookmarks:(id)sender;
- (IBAction)importTrackerBookmarks:(id)sender;

- (IBAction)chatRevealChatHistory:(id)sender;
- (IBAction)chatRevealChatLogs:(id)sender;
- (IBAction)otherChatLogsFolder:(id)sender;

- (IBAction)addHighlight:(id)sender;
- (IBAction)deleteHighlight:(id)sender;

- (IBAction)addIgnore:(id)sender;
- (IBAction)deleteIgnore:(id)sender;

- (IBAction)selectEvent:(id)sender;
- (IBAction)changeEvent:(id)sender;

- (IBAction)otherDownloadFolder:(id)sender;
- (IBAction)changeNetwork:(id)sender;

@end
