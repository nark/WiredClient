//
//  WCBoardsViewController.h
//  WiredClient
//
//  Created by Rafaël Warnault on 23/02/13.
//
//

#import <Cocoa/Cocoa.h>

@class WCBoardThreadController, WCErrorQueue, WCSourceSplitView, WCBoard, WCSmartBoard, WCBoardThread;

@interface WCBoardsViewController : NSViewController <NSToolbarDelegate> {
	IBOutlet WCBoardThreadController				*_threadController;
	
	IBOutlet WCSourceSplitView						*_boardsSplitView;
	IBOutlet NSView									*_boardsView;
	IBOutlet NSView									*_threadsView;
	IBOutlet WISplitView							*_threadsSplitView;
	IBOutlet NSView									*_threadListView;
	IBOutlet NSView									*_threadView;
    
	IBOutlet WIOutlineView							*_boardsOutlineView;
	IBOutlet NSTableColumn							*_boardTableColumn;
	IBOutlet NSTableColumn							*_unreadBoardTableColumn;
	IBOutlet NSButton								*_addBoardButton;
	IBOutlet NSButton								*_deleteBoardButton;
	
	IBOutlet WITableView							*_threadsTableView;
	IBOutlet NSTableColumn							*_unreadThreadTableColumn;
	IBOutlet NSTableColumn							*_subjectTableColumn;
	IBOutlet NSTableColumn							*_nickTableColumn;
	IBOutlet NSTableColumn							*_repliesTableColumn;
	IBOutlet NSTableColumn							*_threadTimeTableColumn;
	IBOutlet NSTableColumn							*_postTimeTableColumn;
    
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
    
    WCServerConnection                              *_connection;
	WCErrorQueue									*_errorQueue;
	
	WCBoard											*_boards;
	WCBoard											*_smartBoards;
	id												_selectedBoard;
	WCSmartBoard									*_searchBoard;
	
	NSMutableDictionary								*_boardsByThreadID;
	
	WIDateFormatter									*_dateFormatter;
	
	NSArray											*_collapsedBoards;
	BOOL											_expandingBoards;
	
	NSMutableSet									*_receivedBoards;
	NSMutableSet									*_readIDs;
	
	BOOL											_searching;
}

+ (id)boardsControllerWithConnection:(WCServerConnection *)connection;

- (NSString *)newDocumentMenuItemTitle;
- (NSString *)deleteDocumentMenuItemTitle;
- (NSString *)reloadDocumentMenuItemTitle;
- (NSString *)saveDocumentMenuItemTitle;

- (void)selectThread:(WCBoardThread *)thread;
- (WCBoard *)selectedBoard;

- (void)setConnection:(WCServerConnection *)connection;
- (WCServerConnection *)connection;

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
- (IBAction)addThread:(id)sender;
- (IBAction)deleteThread:(id)sender;
- (IBAction)saveThread:(id)sender;
- (IBAction)markAllAsRead:(id)sender;
- (IBAction)markAsRead:(id)sender;
- (IBAction)markAsUnread:(id)sender;
- (IBAction)search:(id)sender;

- (IBAction)goToLatestReply:(id)sender;

- (IBAction)bold:(id)sender;
- (IBAction)italic:(id)sender;
- (IBAction)underline:(id)sender;
- (IBAction)color:(id)sender;
- (IBAction)center:(id)sender;
- (IBAction)quote:(id)sender;
- (IBAction)code:(id)sender;
- (IBAction)url:(id)sender;
- (IBAction)image:(id)sender;


@end
