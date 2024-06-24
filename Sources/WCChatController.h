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

extern NSString * const WCChatUserAppearedNotification;
extern NSString * const WCChatUserDisappearedNotification;
extern NSString * const WCChatUserNickDidChangeNotification;
extern NSString * const WCChatSelfWasKickedFromPublicChatNotification;
extern NSString * const WCChatSelfWasBannedNotification;
extern NSString * const WCChatSelfWasDisconnectedNotification;
extern NSString * const WCChatRegularChatDidAppearNotification;
extern NSString * const WCChatHighlightedChatDidAppearNotification;
extern NSString * const WCChatEventDidAppearNotification;

extern NSString * const WCChatHighlightColorKey;

extern NSString * const WCUserPboardType;


@class SBJson4Writer, LNWebView, LNScrollView, WCChatTextView, WCChatWindow, WCServerConnection, WCErrorQueue, WCTopic, WCUser;

@interface WCChatController : WIObject <NSMenuDelegate> {
	IBOutlet WISplitView							*_userListSplitView;
    IBOutlet NSImageView                            *_splitResizeView;
    
	IBOutlet NSView									*_chatView;
	IBOutlet NSTextField							*_topicTextField;
	IBOutlet NSTextField							*_topicNickTextField;
	IBOutlet WISplitView							*_chatSplitView;
	IBOutlet NSScrollView							*_chatOutputScrollView;
	IBOutlet LNScrollView							*_chatInputScrollView;
	//IBOutlet NSTextView								*_chatInputTextView;
    IBOutlet NSTextField							*_chatInputTextField;
	IBOutlet NSMenu									*_chatSmileysMenu;
    IBOutlet NSButton                               *_showEmoticonsButtons;
	
	IBOutlet WebView								*_chatOutputWebView;

	IBOutlet NSView									*_userListView;
	IBOutlet NSButton								*_privateMessageButton;
	IBOutlet NSButton								*_infoButton;
	IBOutlet NSButton								*_kickButton;
	IBOutlet WITableView							*_userListTableView;
	IBOutlet LNScrollView							*_userListScrollView;
	IBOutlet NSTableColumn							*_iconTableColumn;
	IBOutlet NSTableColumn							*_nickTableColumn;

	IBOutlet NSPanel								*_setTopicPanel;
	IBOutlet NSTextView								*_setTopicTextView;

	IBOutlet NSMenu									*_userListMenu;
	IBOutlet NSMenuItem								*_sendPrivateMessageMenuItem;
	IBOutlet NSMenuItem								*_getInfoMenuItem;
	IBOutlet NSMenuItem								*_ignoreMenuItem;
	
	IBOutlet NSPanel								*_kickMessagePanel;
	IBOutlet NSTextField							*_kickMessageTextField;

	IBOutlet NSView									*_saveChatView;
	IBOutlet NSPopUpButton							*_saveChatFileFormatPopUpButton;
	IBOutlet NSPopUpButton							*_saveChatPlainTextEncodingPopUpButton;
	
	WCServerConnection								*_connection;
	
	WCErrorQueue									*_errorQueue;
    SBJson4Writer                                   *_jsonWriter;

	NSMutableArray									*_commandHistory;
	NSUInteger										_currentCommand;
	NSString										*_currentString;
	
	NSMutableDictionary								*_users;
	NSMutableArray									*_allUsers, *_shownUsers;
	BOOL											_receivedUserList;
	
	NSString										*_chatTemplate;
	NSFont											*_chatFont;
	NSColor											*_chatColor;
	NSColor											*_eventsColor;
	NSColor											*_timestampEveryLineColor;
	NSMutableArray									*_highlightPatterns;
	NSMutableArray									*_highlightColors;
    BOOL											_showSmileys;
	
	NSDate											*_timestamp;
	WCTopic											*_topic;
	
	WIDateFormatter									*_timestampDateFormatter;
	WIDateFormatter									*_timestampEveryLineDateFormatter;
	WIDateFormatter									*_topicDateFormatter;
	
	NSMutableDictionary								*_pings;
	
	BOOL											_loadedNib;
}

- (void)wiredSendPingReply:(WIP7Message *)message;

+ (NSString *)outputForShellCommand:(NSString *)command;

+ (void)applyHTMLTagsForURLToMutableString:(NSMutableString *)mutableString;
+ (void)applyHTMLTagsForSmileysToMutableString:(NSMutableString *)mutableString;
+ (void)applyHTMLEscapingToMutableString:(NSMutableString *)mutableString;
+ (BOOL)checkHTMLRestrictionsForString:(NSString *)string;

+ (NSString *)stringByDecomposingSmileyAttributesInAttributedString:(NSAttributedString *)attributedString;
//+ (NSDictionary *)smileyRegexs;
+ (BOOL)isHTMLString:(NSString *)string;

- (void)themeDidChange:(NSDictionary *)theme;
- (void)linkConnectionLoggedIn:(NSNotification *)notification;
- (void)wiredChatJoinChatReply:(WIP7Message *)message;

- (NSString *)saveDocumentMenuItemTitle;

- (void)validate;

- (void)setConnection:(WCServerConnection *)connection;
- (WCServerConnection *)connection;

- (NSView *)view;
- (WebView *)webView;
- (void)awakeInWindow:(NSWindow *)window;
- (void)loadWindowProperties;
- (void)saveWindowProperties;

- (WCUser *)selectedUser;
- (NSArray *)selectedUsers;
- (NSArray *)users;
- (NSArray *)nicks;
- (WCUser *)userAtIndex:(NSUInteger)index;
- (WCUser *)userWithUserID:(NSUInteger)uid;
- (void)selectUser:(WCUser *)user;
- (NSUInteger)chatID;
- (NSTextField *)insertionTextField;

- (void)sendChat:(NSString *)message;
- (void)printEvent:(NSString *)message;
- (void)printChatNowPlaying;

- (void)clearChat;
- (BOOL)chatIsEmpty;

- (IBAction)saveDocument:(id)sender;
- (IBAction)stats:(id)sender;
- (IBAction)saveChat:(id)sender;
- (IBAction)setTopic:(id)sender;
- (IBAction)sendPrivateMessage:(id)sender;
- (IBAction)getInfo:(id)sender;
- (IBAction)kick:(id)sender;
- (IBAction)editAccount:(id)sender;
- (IBAction)ignore:(id)sender;
- (IBAction)unignore:(id)sender;
- (IBAction)toggleUserList:(id)sender;
- (IBAction)showUserList:(id)sender;
- (IBAction)hideUserList:(id)sender;
- (IBAction)showEmoticons:(id)sender;
- (IBAction)fileFormat:(id)sender;

@end
