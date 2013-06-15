//
//  WCChatHistory.h
//  WiredClient
//
//  Created by Rafaël Warnault on 20/05/12.
//  Copyright (c) 2012 Read-Write.fr. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LNWebView;

@interface WCChatHistory : WIWindowController 
<NSToolbarDelegate, NSTableViewDataSource, NSTableViewDelegate, NSOutlineViewDataSource, NSOutlineViewDelegate, NSSplitViewDelegate> {
	
	IBOutlet NSOutlineView		*_historyOutlineView;
	IBOutlet WITableView		*_detailsTableView;
	
	IBOutlet LNWebView			*_detailWebView;
	
	IBOutlet WISplitView		*_historySplitView;
	IBOutlet WISplitView		*_detailsSplitView;
	
	IBOutlet NSSearchField		*_searchField;
	
	NSArray						*_categories;
	NSArray						*_selectedArchives;
	NSMutableArray				*_filteredArchives;
	
	WIChatLogController			*_logController;
}

+ (id)chatHistory;

- (IBAction)search:(id)sender;
- (IBAction)clear:(id)sender;
- (IBAction)revealInFinder:(id)sender;
- (IBAction)exportAsWebArchive:(id)sender;

@end
