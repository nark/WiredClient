//
//  WIChatLogController.m
//  wired
//
//  Created by Rafaël Warnault on 20/05/12.
//  Copyright (c) 2012 Read-Write.fr. All rights reserved.
//

#import "WIChatLogController.h"
#import "WIChatHistoryBundle.h"


@interface WIChatLogController (Private)

- (void)_checkHistoryBundles;

- (void)_reloadFolders;
- (void)_reloadLogsForFolderWithName:(NSString *)name;

- (NSString *)_pathOfFolderWithName:(NSString *)name;
- (NSString *)_pathExtentionForType:(WIChatLogType)type;

@end





@implementation WIChatLogController (Private)


#pragma mark -

- (void)_checkHistoryBundles {
	NSFileManager	*fileManager;
	NSString		*defaultBundlePath;
	NSError			*error;
	
	fileManager			= [NSFileManager defaultManager];
	defaultBundlePath	= [[NSBundle bundleForClass:[WIChatLogController class]] 
						   pathForResource:@"ChatHistory-default" 
						   ofType:@"WiredHistory"];
	
	if(![fileManager fileExistsAtPath:[self publicHistoryBundlePath]])
		[fileManager copyItemAtPath:defaultBundlePath 
							 toPath:[self publicHistoryBundlePath]
							  error:&error];
		
	if(![fileManager fileExistsAtPath:[self privateHistoryBundlePath]])
		[fileManager copyItemAtPath:defaultBundlePath 
							 toPath:[self privateHistoryBundlePath]
							  error:&error];
	
	
	if(_publicChatHistory) {
		[_publicChatHistory release];
		_publicChatHistory = nil;
	}
	
	if(_privateChatHistory) {
		[_privateChatHistory release];
		_privateChatHistory = nil;
	}
	
	_publicChatHistory	= [[WIChatHistoryBundle alloc] initWithPath:[self publicHistoryBundlePath]];
	_privateChatHistory = [[WIChatHistoryBundle alloc] initWithPath:[self privateHistoryBundlePath]];
	
}





#pragma mark -

- (void)_reloadFolders {
	NSError			*error;
	NSArray			*fileNames;
	NSString		*filePath;
	NSFileManager	*fileManager;
	BOOL			isDir;
	
	[_folders removeAllObjects];
	
	fileManager = [NSFileManager defaultManager];
	fileNames	= [fileManager contentsOfDirectoryAtPath:[self chatLogsPath] error:&error];
	
	for(NSString *fileName in fileNames) {
		 filePath = [[self chatLogsPath] stringByAppendingPathComponent:fileName];
		
		if([fileManager fileExistsAtPath:filePath isDirectory:&isDir] && isDir)
			[_folders addObject:filePath];
	}
}


- (void)_reloadLogsForFolderWithName:(NSString *)name {
	
	NSError			*error;
	NSArray			*fileNames;
	NSString		*path, *filePath;
	NSFileManager	*fileManager;
	BOOL			isDir;
	
	[_logs removeAllObjects];
	
	path		= [self _pathOfFolderWithName:name];
	fileManager = [NSFileManager defaultManager];
	fileNames	= [fileManager contentsOfDirectoryAtPath:path error:&error];
	
	for(NSString *fileName in fileNames) {
		filePath = [path stringByAppendingPathComponent:fileName];
		
		if([fileManager fileExistsAtPath:filePath isDirectory:&isDir] && !isDir)
			[_logs addObject:filePath];
	}
}




#pragma mark -

- (NSString *)_pathOfFolderWithName:(NSString *)name {
	
	for(NSString *folderPath in _folders) {
		if([[folderPath lastPathComponent] isEqualToString:name])
			return folderPath;
	}
	
	return nil;
}


- (NSString *)_pathExtentionForType:(WIChatLogType)type {
	switch (type) {
		case			WIChatLogTypeWebArchive:	return @"webarchive";	break;
		case			WIChatLogTypeTXT:			return @"rtfd";			break;
		default:									return @"webarchive";	break;
	}
	return @"webarchive";
}


@end






@implementation WIChatLogController


#pragma mark -

+ (id)chatLogControllerWithPath:(NSString *)path {
	return [[[[self class] alloc] initWithPath:path] autorelease];
}

+ (NSArray *)typeNames {
	return [NSArray arrayWithObjects:@"Web Archive", @"Plain Text Format", nil];
}

+ (NSArray *)typeExtentions {
	return [NSArray arrayWithObjects:@"webarchive", @"txt", nil];
}



#pragma mark -

- (id)initWithPath:(NSString *)path
{
    self = [super init];
    if (self) {
        _path		= [[path stringByStandardizingPath] retain];
		_folders	= [[NSMutableArray alloc] init];
		_logs		= [[NSMutableArray alloc] init];
		
		[self _checkHistoryBundles];
    }
    return self;
}


- (void)dealloc
{
    [_path release];
	[_folders release];
	[_logs release];
	
	[_publicChatHistory release];
	[_privateChatHistory release];
	
    [super dealloc];
}





#pragma mark -

- (void)appendChatLogAsPlainText:(NSString *)string forConnectionName:(NSString *)name {
			
	NSString		*path, *extention, *dateString, *newFilePath;
	NSFileManager	*fileManager;
	NSDateFormatter *dateFormatter;
	NSError			*error;
	
	dateFormatter = [[NSDateFormatter alloc] init];
	
	[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
	[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
	
	fileManager = [NSFileManager defaultManager];
	path		= [self _pathOfFolderWithName:name];
		
	if(!path || ![fileManager fileExistsAtPath:path]) {
		path = [[self chatLogsPath] stringByAppendingPathComponent:name];
		
		[fileManager createDirectoryAtPath:path
			   withIntermediateDirectories:YES 
								attributes:nil 
									 error:&error];
	}
		
	extention	= @"txt";
	dateString	= [dateFormatter stringFromDate:[NSDate date]];
	newFilePath = [path stringByAppendingPathComponent:[NSSWF:@"%@-%@.%@", name, dateString, extention]];
	
	if(![fileManager fileExistsAtPath:newFilePath]) {
		[string writeToFile:newFilePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
		
	} else {
		NSFileHandle *output = [NSFileHandle fileHandleForWritingAtPath:newFilePath];
		[output seekToEndOfFile];
		[output writeData:[string dataUsingEncoding:NSUTF8StringEncoding]];
	}
		
	[self _reloadLogsForFolderWithName:name];
	
	[dateFormatter release];
}


- (NSArray *)logsForName:(NSString *)name {
	[self _reloadLogsForFolderWithName:name];
	return _logs;
}


- (WIChatHistoryBundle *)publicChatHistoryBundle {
	return _publicChatHistory;
}


- (WIChatHistoryBundle *)privateChatHistoryBundle {
	return _privateChatHistory;
}





#pragma mark -

- (NSString *)path {
	return _path;
}

- (NSString *)chatLogsPath {
	return [_path stringByAppendingPathComponent:@"ChatLogs"];
}

- (NSString *)publicHistoryBundlePath {
	return [_path stringByAppendingPathComponent:@"PublicChatHistory.WiredHistory"];
}


- (NSString *)privateHistoryBundlePath {
	return [_path stringByAppendingPathComponent:@"PrivateChatHistory.WiredHistory"];
}




#pragma mark -

- (NSArray *)folders {
	[self _reloadFolders];
	
	return _folders;
}



@end


