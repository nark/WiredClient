//
//  WIChatHistoryBundle.m
//  wired
//
//  Created by Rafaël Warnault on 20/05/12.
//  Copyright (c) 2012 Read-Write.fr. All rights reserved.
//

#import "WIChatHistoryBundle.h"
#import "WebView-WIAppKit.h"


NSString * const WIChatHistoryBundleAddedNotification	= @"WIChatHistoryBundleAddedNotification";



@interface WIChatHistoryBundle (Private)

- (void)_reloadFolders;
- (void)_reloadArchivesInFolderWithName:(NSString *)name;

- (NSString *)_pathOfFolderWithName:(NSString *)name;

@end



@implementation WIChatHistoryBundle (Private)

- (void)_reloadFolders {
	NSError			*error;
	NSArray			*fileNames;
	NSString		*filePath;
	NSFileManager	*fileManager;
	BOOL			isDir;
	
	[_folders removeAllObjects];
	
	fileManager = [NSFileManager defaultManager];
	fileNames	= [fileManager contentsOfDirectoryAtPath:[self resourcePath] error:&error];
	
	for(NSString *fileName in fileNames) {
		filePath = [[self resourcePath] stringByAppendingPathComponent:fileName];
		
		if([fileManager fileExistsAtPath:filePath isDirectory:&isDir] && isDir && ![[filePath pathExtension] isEqualToString:@"lproj"])
			[_folders addObject:filePath];
	}
}


- (void)_reloadArchivesInFolderWithName:(NSString *)name {
	NSError			*error;
	NSArray			*fileNames;
	NSString		*path, *filePath;
	NSFileManager	*fileManager;
	
	[_archives removeAllObjects];
	
	path		= [self _pathOfFolderWithName:name];
	fileManager = [NSFileManager defaultManager];
	fileNames	= [fileManager contentsOfDirectoryAtPath:path error:&error];
	
	for(NSString *fileName in fileNames) {
		filePath = [path stringByAppendingPathComponent:fileName];
		
		if([fileManager fileExistsAtPath:filePath])
			[_archives addObject:filePath];
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

@end




@implementation WIChatHistoryBundle


#pragma mark -

+ (id)historyBundleWithPath:(NSString *)path {
	return [[[[self class] alloc] initWithPath:path] autorelease];
}




#pragma mark -


- (id)initWithPath:(NSString *)path
{
    self = [super initWithPath:path];
    if (self) {
		_folders	= [[NSMutableArray alloc] init];
		_archives	= [[NSMutableArray alloc] init];
		
		[self _reloadFolders];
    }
    return self;
}


- (void)dealloc
{
    [_folders release];
    [_archives release];
    [super dealloc];
}





#pragma mark -

- (void)addHistoryForWebView:(WebView *)webview withConnectionName:(NSString *)name identity:(NSString *)identity {
	
	NSString			*folderPath, *archivePath;
	NSFileManager		*fileManager;
	NSError				*error;
		
	fileManager		= [NSFileManager defaultManager];
	folderPath		= [self _pathOfFolderWithName:name];
	
	
	if(!folderPath || ![fileManager fileExistsAtPath:folderPath]) {
		folderPath	= [[self resourcePath] stringByAppendingPathComponent:name];
			
		[fileManager createDirectoryAtPath:folderPath
			   withIntermediateDirectories:YES 
								attributes:nil 
									 error:&error];
	}
		
	archivePath = [folderPath stringByAppendingPathComponent:[NSSWF:@"%@-%@-%d.webarchive", identity, name, (int)[[NSDate date] timeIntervalSince1970]]];
	
	[webview exportContentToFileAtPath:archivePath forType:WIChatLogTypeWebArchive];
	[self _reloadArchivesInFolderWithName:name];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:WIChatHistoryBundleAddedNotification
														object:self];
	
}


- (void)clearHistory {
	NSError *error;
	
	for(NSString *folder in _folders) {
		[[NSFileManager defaultManager] removeItemAtPath:folder error:&error];
	}
	
	[_folders removeAllObjects];
	
	[self _reloadFolders];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:WIChatHistoryBundleAddedNotification
														object:self];
}



- (void)reloadData {
	[self _reloadFolders];
}



#pragma mark -

- (NSArray *)folders {
	
	return _folders;
}


- (NSArray *)archivesInFolderWithName:(NSString *)name {

	[self _reloadArchivesInFolderWithName:name];
	
	return _archives;
}



@end
