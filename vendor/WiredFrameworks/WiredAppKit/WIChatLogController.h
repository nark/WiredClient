//
//  WIChatLogController.h
//  wired
//
//  Created by Rafaël Warnault on 20/05/12.
//  Copyright (c) 2012 Read-Write.fr. All rights reserved.
//

@class WIChatHistoryBundle;

enum  WIChatLogType {
	WIChatLogTypeWebArchive = 0,
	WIChatLogTypeTXT = 1
} typedef WIChatLogType;


@interface WIChatLogController : NSObject {
	NSString			*_path;
	
	NSMutableArray		*_folders;
	NSMutableArray		*_logs;
	
	WIChatHistoryBundle *_publicChatHistory;
	WIChatHistoryBundle *_privateChatHistory;
}


+ (id)chatLogControllerWithPath:(NSString *)path;

+ (NSArray *)typeNames;
+ (NSArray *)typeExtentions;


- (id)initWithPath:(NSString *)path;


- (void)appendChatLogAsPlainText:(NSString *)string forConnectionName:(NSString *)name;

- (WIChatHistoryBundle *)publicChatHistoryBundle;
- (WIChatHistoryBundle *)privateChatHistoryBundle;

- (NSArray *)folders;
- (NSArray *)logsForName:(NSString *)name;

- (NSString *)path;
- (NSString *)chatLogsPath;
- (NSString *)publicHistoryBundlePath;
- (NSString *)privateHistoryBundlePath;

@end
