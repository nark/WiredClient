/* $Id$ */

/*
 *  Copyright (c) 2008-2009 Axel Andersson
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

#import "WCWebDataSource.h"

extern NSString * const         WCBoardsDidChangeUnreadCountNotification;

@class WCBoardThreadController, WCErrorQueue, WCSourceSplitView, WCBoard, WCSmartBoard, WCBoardThread;

@interface WCBoards : WIWindowController <NSToolbarDelegate, NSOutlineViewDataSource, NSOutlineViewDelegate, NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate, WCWebDataSource> {
	IBOutlet WCSourceSplitView						*_boardsSplitView;
    IBOutlet NSImageView                            *_boardsSplitViewImageView;
	IBOutlet NSView									*_boardsView;
	IBOutlet NSView									*_threadsView;
	IBOutlet WISplitView							*_threadsHorizontalSplitView;
    IBOutlet NSImageView                            *_threadsHorizontalSplitViewImageView;
    IBOutlet NSView                                 *_threadsHorizontalSplitViewBarView;
    IBOutlet WISplitView							*_threadsVerticalSplitView;
    IBOutlet NSImageView                            *_threadsVerticalSplitViewImageView;
	IBOutlet NSView									*_threadListView;
	IBOutlet NSView									*_threadView;

	IBOutlet WIOutlineView							*_boardsOutlineView;
	IBOutlet NSTableColumn							*_boardTableColumn;
	IBOutlet NSTableColumn							*_unreadBoardTableColumn;
	IBOutlet NSButton								*_addBoardButton;
	IBOutlet NSButton								*_deleteBoardButton;
	
	IBOutlet WITableView							*_threadsHorizontalTableView;
    IBOutlet WITableView							*_threadsVerticalTableView;
	IBOutlet NSTableColumn							*_unreadThreadTableColumn;
	IBOutlet NSTableColumn							*_subjectTableColumn;
	IBOutlet NSTableColumn							*_nickTableColumn;
	IBOutlet NSTableColumn							*_repliesTableColumn;
	IBOutlet NSTableColumn							*_threadTimeTableColumn;
	IBOutlet NSTableColumn							*_postTimeTableColumn;
    IBOutlet NSPopUpButton                          *_threadSortingPopUpButton;

	IBOutlet NSPanel								*_addBoardPanel;
	IBOutlet NSPopUpButton							*_boardLocationPopUpButton;
	IBOutlet NSTextField							*_nameTextField;
	IBOutlet NSPopUpButton							*_addOwnerPopUpButton;
	IBOutlet NSPopUpButton							*_addOwnerPermissionsPopUpButton;
	IBOutlet NSPopUpButton							*_addGroupPopUpButton;
	IBOutlet NSPopUpButton							*_addGroupPermissionsPopUpButton;
	IBOutlet NSPopUpButton							*_addEveryonePermissionsPopUpButton;
	
	IBOutlet NSPanel								*_setPermissionsPanel;
	IBOutlet NSPopUpButton							*_setOwnerPopUpButton;
	IBOutlet NSPopUpButton							*_setOwnerPermissionsPopUpButton;
	IBOutlet NSPopUpButton							*_setGroupPopUpButton;
	IBOutlet NSPopUpButton							*_setGroupPermissionsPopUpButton;
	IBOutlet NSPopUpButton							*_setEveryonePermissionsPopUpButton;
	IBOutlet NSProgressIndicator					*_permissionsProgressIndicator;

	IBOutlet NSPanel								*_postPanel;
	IBOutlet NSPopUpButton							*_postLocationPopUpButton;
	IBOutlet NSTextField							*_subjectTextField;
	IBOutlet NSTextView								*_postTextView;
	IBOutlet NSButton								*_postButton;
	
	IBOutlet NSPanel								*_smartBoardPanel;
	IBOutlet NSTextField							*_smartBoardNameTextField;
	IBOutlet NSComboBox								*_boardFilterComboBox;
	IBOutlet NSTextField							*_subjectFilterTextField;
	IBOutlet NSTextField							*_textFilterTextField;
	IBOutlet NSTextField							*_nickFilterTextField;
	IBOutlet NSButton								*_unreadFilterButton;
	IBOutlet NSTextField                            *_maxTitleLengthTextField;
    IBOutlet NSSearchField                          *_searchTextField;
    
    WCBoardThreadController                         *_threadController;
	WCErrorQueue									*_errorQueue;
    
    NSString                                        *_fileLinkBase64String;
	NSString                                        *_unreadPostBase64String;
	NSString                                        *_defaultIconBase64String;
	
	WCBoard											*_boards;
	WCBoard											*_smartBoards;
    WCBoard											*_searchBoards;
	id												_selectedBoard;
	WCSmartBoard									*_searchBoard;
	
	NSMutableDictionary								*_boardsByThreadID;
		
	NSArray											*_collapsedBoards;
	BOOL											_expandingBoards;
	
	NSMutableSet									*_receivedBoards;
	NSMutableSet									*_readIDs;
	
	BOOL											_searching;
    BOOL                                            _reloadingThreads;
}

+ (id)boards;

- (NSString *)lastMessageDate;

- (NSString *)newDocumentMenuItemTitle;
- (NSString *)deleteDocumentMenuItemTitle;
- (NSString *)reloadDocumentMenuItemTitle;
- (NSString *)saveDocumentMenuItemTitle;

- (void)selectThread:(WCBoardThread *)thread;
- (WCBoard *)selectedBoard;

- (NSUInteger)numberOfUnreadThreads;
- (NSUInteger)numberOfUnreadThreadsForConnection:(WCServerConnection *)connection;

- (IBAction)newDocument:(id)sender;
- (IBAction)deleteDocument:(id)sender;
- (IBAction)saveDocument:(id)sender;
- (IBAction)addBoard:(id)sender;
- (IBAction)addSmartBoard:(id)sender;
- (IBAction)editSmartBoard:(id)sender;
- (IBAction)deleteBoard:(id)sender;
- (IBAction)renameBoard:(id)sender;
- (IBAction)changePermissions:(id)sender;
- (IBAction)location:(id)sender;
- (IBAction)sortThreads:(id)sender;
- (IBAction)addThread:(id)sender;
- (IBAction)deleteThread:(id)sender;
- (IBAction)saveThread:(id)sender;
- (IBAction)markAllAsRead:(id)sender;
- (IBAction)markAsRead:(id)sender;
- (IBAction)markAsUnread:(id)sender;
- (IBAction)search:(id)sender;

- (IBAction)goToLatestReply:(id)sender;
- (IBAction)openThreadInSeparatedWindow:(id)sender;

- (IBAction)bold:(id)sender;
- (IBAction)italic:(id)sender;
- (IBAction)underline:(id)sender;
- (IBAction)color:(id)sender;
- (IBAction)center:(id)sender;
- (IBAction)quote:(id)sender;
- (IBAction)code:(id)sender;
- (IBAction)url:(id)sender;
- (IBAction)image:(id)sender;


- (void)wiredBoardGetThreadReply:(WIP7Message *)message;
- (void)wiredBoardBoardGetInfoReply:(WIP7Message *)message;
- (void)wiredBoardGetBoardsReply:(WIP7Message *)message;
- (void)wiredBoardGetThreadsReply:(WIP7Message *)message;
- (void)wiredBoardSubscribeBoardsReply:(WIP7Message *)message;


@end
