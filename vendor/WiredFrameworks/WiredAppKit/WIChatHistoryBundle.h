//
//  WIChatHistoryBundle.h
//  wired
//
//  Created by Rafaël Warnault on 20/05/12.
//  Copyright (c) 2012 Read-Write.fr. All rights reserved.
//


extern NSString * const WIChatHistoryBundleAddedNotification;

@interface WIChatHistoryBundle : NSBundle {
	NSMutableArray			*_folders;
	NSMutableArray			*_archives;
}

+ (id)historyBundleWithPath:(NSString *)path;

- (void)addHistoryForWebView:(WebView *)webview withConnectionName:(NSString *)name identity:(NSString *)identity;
- (void)reloadData;
- (void)clearHistory;

- (NSArray *)folders;
- (NSArray *)archivesInFolderWithName:(NSString *)name;

@end
