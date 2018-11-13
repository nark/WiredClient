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

#import "WCAccount.h"
#import "WCAccountsController.h"
#import "WCAdministration.h"
#import "WCErrorQueue.h"
#import "WCFile.h"
#import "WCFileInfo.h"
#import "WCFiles.h"
#import "WCPreferences.h"
#import "WCPublicChat.h"
#import "WCPublicChatController.h"
#import "WCServer.h"
#import "WCTransfers.h"

#define WCFilesFiles						@"WCFilesFiles"
#define WCFilesDirectories					@"WCFilesDirectories"
#define WCFilesListedFiles					@"WCFilesListedFiles"
#define WCFilesSearchedFiles				@"WCFilesSearchedFiles"

#define WCFilesQuickLookTextExtensions		@"c cc cgi conf css diff h in java log m patch pem php pl plist pod rb rtf s sh status strings tcl text txt xml"
#define WCFilesQuickLookHTMLExtensions		@"htm html shtm shtml svg"
#define WCFilesQuickLookImageExtensions		@"bmp eps jpg jpeg tif tiff gif pct pict pdf png"


NSString * const							WCFilePboardType = @"WCFilePboardType";
NSString * const							WCPlacePboardType = @"WCPlacePboardType";


@interface WCFiles(Private)

- (id)_initFilesWithConnection:(WCServerConnection *)connection file:(WCFile *)file selectFile:(WCFile *)selectFile;

- (void)_themeDidChange;

- (void)_validate;
- (void)_validatePermissions;
- (BOOL)_validateConnected;
- (BOOL)_validateDownload;
- (BOOL)_validateUploadToDirectory:(WCFile *)directory;
- (BOOL)_validateGetInfo;
- (BOOL)_validateCopy;
- (BOOL)_validateQuickLook;
- (BOOL)_validateCreateFolder;
- (BOOL)_validateReload;
- (BOOL)_validateDelete;
- (BOOL)_validateSearch;
- (BOOL)_validateSetLabel;

- (BOOL)_canPreviewFile:(WCFile *)file;

- (WCFile *)_selectedSource;
- (WCServerConnection *)_selectedConnection;
- (WCAccount *)_selectedAccount;
- (NSArray *)_selectedFiles;

- (NSMutableDictionary *)_structureForConnection:(WCServerConnection *)connection;
- (NSMutableDictionary *)_filesForConnection:(WCServerConnection *)connection;
- (NSMutableDictionary *)_directoriesForConnection:(WCServerConnection *)connection;
- (NSMutableArray *)_directoryForConnection:(WCServerConnection *)connection path:(NSString *)path;
- (WCFile *)_existingFileForFile:(WCFile *)file;
- (WCFile *)_existingParentFileForFile:(WCFile *)file;
- (void)_removeDirectoryForConnection:(WCServerConnection *)connection path:(NSString *)path;
- (NSMutableDictionary *)_listedFilesForConnection:(WCServerConnection *)connection;
- (NSMutableArray *)_listedFilesForConnection:(WCServerConnection *)connection message:(WIP7Message *)message;
- (void)_removeListedFilesForConnection:(WCServerConnection *)connection message:(WIP7Message *)message;
- (NSMutableDictionary *)_searchedFilesForConnection:(WCServerConnection *)connection;
- (NSMutableArray *)_searchedFilesForConnection:(WCServerConnection *)connection message:(WIP7Message *)message;
- (void)_removeSearchedFilesForConnection:(WCServerConnection *)connection message:(WIP7Message *)message;

- (BOOL)_existingDirectoryTreeIsWritableForFile:(WCFile *)file;
- (BOOL)_existingDirectoryTreeIsReadableForFile:(WCFile *)file;

- (void)_addConnections;
- (void)_addConnection:(WCServerConnection *)connection;
- (void)_addPlaces;
- (void)_revalidatePlacesForConnection:(WCServerConnection *)connection;
- (void)_invalidatePlacesForConnection:(WCServerConnection *)connection;
- (void)_revalidateFilesForConnection:(WCServerConnection *)connection;
- (void)_revalidateFiles:(NSArray *)files;
- (void)_invalidateFilesForConnection:(WCServerConnection *)connection;
- (void)_removeSubscriptionsForConnection:(WCServerConnection *)connection;

- (NSUInteger)_selectedStyle;
- (void)_selectStyle:(NSUInteger)style;

- (void)_updateWindowTitle;
- (void)_updatePermissions;

- (void)_changeCurrentDirectory:(WCFile *)file selectFiles:(BOOL)selectFiles forceSelection:(BOOL)forceSelection addToHistory:(BOOL)addToHistory;
- (void)_loadFilesAtDirectory:(WCFile *)file selectFiles:(BOOL)selectFiles;
- (void)_reloadFilesAtDirectory:(WCFile *)file;
- (void)_reloadFilesAtDirectory:(WCFile *)file selectFiles:(BOOL)selectFiles;
- (void)_subscribeToDirectory:(WCFile *)file;
- (void)_unsubscribeFromDirectory:(WCFile *)file;

- (void)_reloadSearch;
- (void)_showSearchBar;
- (void)_hideSearchBar;

- (void)_openFiles:(NSArray *)files overrideNewWindow:(BOOL)override;
- (void)_quickLook;
- (void)_reloadStatus;
- (void)_selectFiles;
- (void)_sortFiles;
- (SEL)_sortSelector;

@end


@implementation WCFiles(Private)

- (id)_initFilesWithConnection:(WCServerConnection *)connection file:(WCFile *)file selectFile:(WCFile *)selectFile {
	NSMutableDictionary		*files;
	NSUInteger				i;
	
	self = [super initWithWindowNibName:@"Files"];

	_files					= [[NSMutableDictionary alloc] init];
	_servers				= [[NSMutableArray alloc] init];
	_places					= [[NSMutableArray alloc] init];
	_initialDirectory		= [file retain];
	_history				= [[NSMutableArray alloc] init];
	_subscribedFiles		= [[NSMutableSet alloc] init];
	_quickLookFiles			= [[NSMutableArray alloc] init];
	_searchTransactions		= [[NSMutableSet alloc] init];
	_selectFiles			= [[NSMutableArray alloc] init];
	
	if(selectFile) {
		[_selectFiles addObject:selectFile];
		
		_selectFilesWhenOpening = YES;
	}
	
	_dateFormatter = [[WIDateFormatter alloc] init];
	[_dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	[_dateFormatter setDateStyle:NSDateFormatterMediumStyle];
	[_dateFormatter setNaturalLanguageStyle:WIDateFormatterCapitalizedNaturalLanguageStyle];
	
	_sizeFormatter = [[WISizeFormatter alloc] init];
	
	_truncatingTailParagraphStyle = [[NSMutableParagraphStyle alloc] init];
	[_truncatingTailParagraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];

	_quickLookPanelClass = NSClassFromString(@"QLPreviewPanel");

	[[NSNotificationCenter defaultCenter]
		addObserver:self
		   selector:@selector(selectedThemeDidChange:)
			   name:WCSelectedThemeDidChangeNotification];

	[[NSNotificationCenter defaultCenter]
		addObserver:self
		   selector:@selector(linkConnectionLoggedIn:)
			   name:WCLinkConnectionLoggedInNotification];
	
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		   selector:@selector(linkConnectionDidClose:)
			   name:WCLinkConnectionDidCloseNotification];
	
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		   selector:@selector(linkConnectionDidTerminate:)
			   name:WCLinkConnectionDidTerminateNotification];
	
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		   selector:@selector(serverConnectionServerInfoDidChange:)
			   name:WCServerConnectionServerInfoDidChangeNotification];

	[[NSNotificationCenter defaultCenter]
		addObserver:self
		   selector:@selector(serverConnectionPrivilegesDidChange:)
			   name:WCServerConnectionPrivilegesDidChangeNotification];
	
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		   selector:@selector(accountsControllerAccountsDidChange:)
			   name:WCAccountsControllerAccountsDidChangeNotification];
	
	[self _addPlaces];
	[self _addConnections];
	
	files = [self _filesForConnection:connection];
	
	[files setObject:file forKey:[file path]];
    
	[self window];
	
	i = [_servers indexOfObject:connection];
	
	if(i != NSNotFound)
		[_sourceOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:i + 1] byExtendingSelection:NO];
	
	[self showWindow:self];
	[self retain];

	return self;
}



#pragma mark -

- (void)_themeDidChange {
	NSDictionary		*theme;
	
	theme = [[WCSettings settings] themeWithIdentifier:[[WCSettings settings] objectForKey:WCTheme]];
	
	[_filesOutlineView setUsesAlternatingRowBackgroundColors:[theme boolForKey:WCThemesFileListAlternateRows]];

	switch([[theme objectForKey:WCThemesFileListIconSize] integerValue]) {
		case WCThemesFileListIconSizeLarge:
			[_filesOutlineView setRowHeight:17.0];
			[_filesOutlineView setFont:[NSFont systemFontOfSize:13.0]];
			
			[_filesTreeView setRowHeight:17.0];
			[_filesTreeView setFont:[NSFont systemFontOfSize:13.0]];
			
			_iconWidth = 16.0;
			break;

		case WCThemesFileListIconSizeSmall:
			[_filesOutlineView setRowHeight:14.0];
			[_filesOutlineView setFont:[NSFont systemFontOfSize:10.0]];
			
			[_filesTreeView setRowHeight:14.0];
			[_filesTreeView setFont:[NSFont systemFontOfSize:10.0]];
			
			_iconWidth = 12.0;
			break;
	}
}



#pragma mark -

- (void)_validate {
	if([self _validateConnected]) {
		[[_historyControl cell] setEnabled:(_searching || _historyPosition > 0) forSegment:0];
		[[_historyControl cell] setEnabled:(_historyPosition + 1 < [_history count]) forSegment:1];
	} else {
		[[_historyControl cell] setEnabled:NO forSegment:0];
		[[_historyControl cell] setEnabled:NO forSegment:1];
	}

	[_downloadButton setEnabled:[self _validateDownload]];
	[_uploadButton setEnabled:[self _validateUploadToDirectory:_currentDirectory]];
	[_infoButton setEnabled:[self _validateGetInfo]];
	[_quickLookButton setEnabled:[self _validateQuickLook]];
	[_createFolderButton setEnabled:[self _validateCreateFolder]];
	[_reloadButton setEnabled:[self _validateReload]];
	[_deleteButton setEnabled:[self _validateDelete]];
	[_searchField setEnabled:[self _validateSearch]];
	
	[_filesTreeView validate];
}



- (void)_validatePermissions {
	BOOL			setPermissions, dropBox;
	
	setPermissions	= [[[self _selectedConnection] account] fileSetPermissions];
	dropBox			= ([_typePopUpButton tagOfSelectedItem] == WCFileDropBox);
	
	[_ownerPopUpButton setEnabled:(dropBox && setPermissions)];
	[_ownerPermissionsPopUpButton setEnabled:(dropBox && setPermissions)];
	[_groupPopUpButton setEnabled:(dropBox && setPermissions)];
	[_groupPermissionsPopUpButton setEnabled:(dropBox && setPermissions)];
	[_everyonePermissionsPopUpButton setEnabled:(dropBox && setPermissions)];
}



- (BOOL)_validateConnected {
	WCServerConnection		*connection;
	
	connection = [self _selectedConnection];
	
	return (connection != NULL && [connection isConnected]);
}



- (BOOL)_validateDownload {
	WCAccount		*account;
	
	if(![self _validateConnected])
		return NO;
	
	account = [self _selectedAccount];
	
	if(![account transferDownloadFiles]) {
		if(![self _existingDirectoryTreeIsReadableForFile:_currentDirectory])
			return NO;
	}
	
	return ([[self _selectedFiles] count] > 0);
}



- (BOOL)_validateUploadToDirectory:(WCFile *)directory {
	WCServerConnection		*connection;
	WCAccount				*account;
	
	connection = [directory connection];
	
	if(!connection || ![connection isConnected])
		return NO;
	
	account = [self _selectedAccount];
	
	if(![account transferUploadFiles] || ![account transferUploadDirectories]) {
		if(![self _existingDirectoryTreeIsWritableForFile:directory])
			return NO;
	}
	
	if(![directory isUploadsFolder] && ![account transferUploadAnywhere])
		return NO;
	
	return YES;
}



- (BOOL)_validateGetInfo {
	WCAccount		*account;
	
	if(![self _validateConnected])
		return NO;
	
	account = [self _selectedAccount];
	
	if(![account fileGetInfo]) {
		if(![self _existingDirectoryTreeIsReadableForFile:_currentDirectory])
			return NO;
	}
	
	return ([[self _selectedFiles] count] > 0);
}



- (BOOL)_validateCopy {
    NSArray			*files;
    
    files = [self _selectedFiles];
    
    if([files count] > 0)
        return YES;
    
    return NO;
}



- (BOOL)_validateQuickLook {
	NSEnumerator	*enumerator;
	NSArray			*files;
	WCAccount		*account;
	WCFile			*file;
	
	if(![self _validateConnected])
		return NO;
	
	account = [self _selectedAccount];
	
	if(![account transferDownloadFiles]) {
		if(![self _existingDirectoryTreeIsReadableForFile:_currentDirectory])
			return NO;
	}
	
	files = [self _selectedFiles];
	
	if([files count] == 0)
		return NO;
	
	enumerator = [files objectEnumerator];
	
	while((file = [enumerator nextObject])) {
		if(![self _canPreviewFile:file])
			return NO;
	}
	
	return YES;
}



- (BOOL)_validateCreateFolder {
	WCAccount		*account;
	
	if(![self _validateConnected] || _searching)
		return NO;
	
	account = [self _selectedAccount];
	
	if(![account fileCreateDirectories]) {
		if(![self _existingDirectoryTreeIsWritableForFile:_currentDirectory])
			return NO;
	}
	
	return YES;
}



- (BOOL)_validateReload {
	if(![self _validateConnected] || _searching)
		return NO;
	
	return YES;
}



- (BOOL)_validateSearch {
	if(![self _validateConnected])
		return NO;
	
	return [[self _selectedAccount] fileSearchFiles];
}



- (BOOL)_validateDelete {
	WCAccount		*account;
	
	if(![self _validateConnected])
		return NO;
	
	account = [self _selectedAccount];
	
	if(![account fileDeleteFiles]) {
		if(![self _existingDirectoryTreeIsWritableForFile:_currentDirectory])
			return NO;
	}
	
	return ([[self _selectedFiles] count] > 0);
}



- (BOOL)_validateSetLabel {
	WCAccount		*account;
	
	if(![self _validateConnected])
		return NO;
	
	account = [self _selectedAccount];
	
	if(![account fileSetLabel]) {
		if(![self _existingDirectoryTreeIsWritableForFile:_currentDirectory])
			return NO;
	}
	
	return ([[self _selectedFiles] count] > 0);
}



#pragma mark -

- (BOOL)_canPreviewFile:(WCFile *)file {
	if([file isFolder])
		return NO;
	
	if(!_quickLookPanelClass)
		return NO;
	
	if([file totalSize] > (10 * 1024 * 1024) - (10 * 1024))
		return NO;
	
	return YES;
}



#pragma mark -

- (WCFile *)_selectedSource {
	id			item;
	
	item = [_sourceOutlineView itemAtRow:[_sourceOutlineView selectedRow]];
	
	if([item isKindOfClass:[WCFile class]]) {
		return item;
	}
	else if([item isKindOfClass:[NSString class]]) {
		return [WCFile fileWithRootDirectoryForConnection:
			[[[WCPublicChat publicChat] chatControllerForConnectionIdentifier:item] connection]];
	}
	
	return NULL;
}



- (WCServerConnection *)_selectedConnection {
	id			item;
	
	item = [_sourceOutlineView itemAtRow:[_sourceOutlineView selectedRow]];
	
	if([item isKindOfClass:[WCFile class]])
		return [(WCFile *) item connection];
	else if([item isKindOfClass:[NSString class]])
		return [[[WCPublicChat publicChat] chatControllerForConnectionIdentifier:item] connection];
	
	return NULL;
}



- (WCAccount *)_selectedAccount {
	return [[self _selectedConnection] account];
}



- (NSArray *)_selectedFiles {
	NSEnumerator			*enumerator;
	NSMutableDictionary		*files;
	NSMutableArray			*selectedFiles;
	NSIndexSet				*indexes;
	NSString				*path;
	WCFile					*file;
	NSUInteger				index;
	
	selectedFiles = [NSMutableArray array];
	
	if([self _selectedStyle] == WCFilesStyleList) {
		indexes		= [_filesOutlineView selectedRowIndexes];
		index		= [indexes firstIndex];
		
		while(index != NSNotFound) {
			[selectedFiles addObject:[_filesOutlineView itemAtRow:index]];
			
			index = [indexes indexGreaterThanIndex:index];
		}
	} else {
		files		= [self _filesForConnection:[self _selectedConnection]];
		enumerator	= [[_filesTreeView selectedPaths] objectEnumerator];
		
		while((path = [enumerator nextObject])) {
			file = [files objectForKey:path];
			
			if(file)
				[selectedFiles addObject:file];
		}
	}
	
	return selectedFiles;
}



#pragma mark -

- (NSMutableDictionary *)_structureForConnection:(WCServerConnection *)connection {
	NSMutableDictionary		*structure;
	NSString				*identifier;
	
	identifier = [connection identifier];
	
	if(!identifier)
		identifier = @"<all>";
	
	structure = [_files objectForKey:identifier];
	
	if(!structure) {
		structure = [[NSMutableDictionary alloc] init];
		[_files setObject:structure forKey:identifier];
		[structure release];
	}
	
	return structure;
}



- (NSMutableDictionary *)_filesForConnection:(WCServerConnection *)connection {
	NSMutableDictionary		*structure, *files;
	
	structure		= [self _structureForConnection:connection];
	files			= [structure objectForKey:WCFilesFiles];
	
	if(!files) {
		files = [[NSMutableDictionary alloc] init];
		[structure setObject:files forKey:WCFilesFiles];
		[files release];
	}
	
	return files;
}



- (NSMutableDictionary *)_directoriesForConnection:(WCServerConnection *)connection {
	NSMutableDictionary		*structure, *directories;
	
	structure		= [self _structureForConnection:connection];
	directories		= [structure objectForKey:WCFilesDirectories];
	
	if(!directories) {
		directories = [[NSMutableDictionary alloc] init];
		[structure setObject:directories forKey:WCFilesDirectories];
		[directories release];
	}
	
	return directories;
}



- (NSMutableArray *)_directoryForConnection:(WCServerConnection *)connection path:(NSString *)path {
	NSMutableDictionary		*directories;
	NSMutableArray			*directory;
	
	if(!path)
		return NULL;
	
	directories		= [self _directoriesForConnection:connection];
	directory		= [directories objectForKey:path];
		
	if(!directory) {
		directory = [[NSMutableArray alloc] init];
		[directories setObject:directory forKey:path];
		[directory release];
	}
	
	return directory;
}



- (WCFile *)_existingFileForFile:(WCFile *)file {
	WCFile		*existingFile;
	
	existingFile = [[self _filesForConnection:[file connection]] objectForKey:[file path]];
	
	return existingFile ? existingFile : file;
}



- (WCFile *)_existingParentFileForFile:(WCFile *)file {
	if(!file || [[file path] isEqualToString:@"/"])
		return NULL;
	
	return [self _existingFileForFile:[WCFile fileWithDirectory:[[file path] stringByDeletingLastPathComponent]
													 connection:[file connection]]];
}



- (void)_removeDirectoryForConnection:(WCServerConnection *)connection path:(NSString *)path {
	NSMutableDictionary		*directories;
	
	directories = [self _directoriesForConnection:connection];
	
	[directories removeObjectForKey:path];
}



- (NSMutableDictionary *)_listedFilesForConnection:(WCServerConnection *)connection {
	NSMutableDictionary		*structure, *listedFiles;
	
	structure		= [self _structureForConnection:connection];
	listedFiles		= [structure objectForKey:WCFilesListedFiles];
	
	if(!listedFiles) {
		listedFiles = [[NSMutableDictionary alloc] init];
		[structure setObject:listedFiles forKey:WCFilesListedFiles];
		[listedFiles release];
	}
	
	return listedFiles;
}



- (NSMutableArray *)_listedFilesForConnection:(WCServerConnection *)connection message:(WIP7Message *)message {
	NSMutableDictionary		*files;
	NSMutableArray			*listedFiles;
	NSNumber				*transaction;
	
	files			= [self _listedFilesForConnection:connection];
	transaction		= [message numberForName:@"wired.transaction"];
	listedFiles		= [files objectForKey:transaction];
	
	if(!listedFiles) {
		listedFiles = [[NSMutableArray alloc] init];
		[files setObject:listedFiles forKey:transaction];
		[listedFiles release];
	}
	
	return listedFiles;
}



- (void)_removeListedFilesForConnection:(WCServerConnection *)connection message:(WIP7Message *)message {
	NSMutableDictionary		*files;
	NSNumber				*transaction;
	
	files			= [self _listedFilesForConnection:connection];
	transaction		= [message numberForName:@"wired.transaction"];
	
	[files removeObjectForKey:transaction];
}



- (NSMutableDictionary *)_searchedFilesForConnection:(WCServerConnection *)connection {
	NSMutableDictionary		*structure, *searchedFiles;
	
	structure		= [self _structureForConnection:connection];
	searchedFiles	= [structure objectForKey:WCFilesSearchedFiles];
	
	if(!searchedFiles) {
		searchedFiles = [[NSMutableDictionary alloc] init];
		[structure setObject:searchedFiles forKey:WCFilesSearchedFiles];
		[searchedFiles release];
	}
	
	return searchedFiles;
}



- (NSMutableArray *)_searchedFilesForConnection:(WCServerConnection *)connection message:(WIP7Message *)message {
	NSMutableDictionary		*files;
	NSMutableArray			*searchedFiles;
	NSNumber				*transaction;
	
	files			= [self _searchedFilesForConnection:connection];
	transaction		= [message numberForName:@"wired.transaction"];
	searchedFiles	= [files objectForKey:transaction];
	
	if(!searchedFiles) {
		searchedFiles = [[NSMutableArray alloc] init];
		[files setObject:searchedFiles forKey:transaction];
		[searchedFiles release];
	}
	
	return searchedFiles;
}



- (void)_removeSearchedFilesForConnection:(WCServerConnection *)connection message:(WIP7Message *)message {
	NSMutableDictionary		*files;
	NSNumber				*transaction;
	
	files			= [self _searchedFilesForConnection:connection];
	transaction		= [message numberForName:@"wired.transaction"];
	
	[files removeObjectForKey:transaction];
}



#pragma mark -

- (BOOL)_existingDirectoryTreeIsWritableForFile:(WCFile *)file {
	WCFile		*parentFile;
	
	if(_searching)
		return NO;
	
	parentFile = file;
	
	do {
		if([parentFile isWritable])
			return YES;
	} while((parentFile = [self _existingParentFileForFile:parentFile]));
	
	return NO;
}



- (BOOL)_existingDirectoryTreeIsReadableForFile:(WCFile *)file {
	WCFile		*parentFile;
	
	if(_searching)
		return NO;
	
	parentFile = file;
	
	do {
		if([parentFile isReadable])
			return YES;
	} while((parentFile = [self _existingParentFileForFile:parentFile]));
	
	return NO;
}



#pragma mark -

- (void)_addConnections {
	NSEnumerator				*enumerator;
	WCPublicChatController		*chatController;
	WCServerConnection			*connection;
	
	enumerator = [[[WCPublicChat publicChat] chatControllers] objectEnumerator];
	
	while((chatController = [enumerator nextObject])) {
		connection = [chatController connection];
		
		[self _addConnection:connection];
		[self _revalidatePlacesForConnection:connection];
		
		[_servers addObject:connection];
	}
	
	[_sourceOutlineView reloadData];
}



- (void)_addConnection:(WCServerConnection *)connection {
	[connection addObserver:self selector:@selector(wiredFileDirectoryChanged:) messageName:@"wired.file.directory_changed"];
	[connection addObserver:self selector:@selector(wiredFileDirectoryDeleted:) messageName:@"wired.file.directory_deleted"];
}



- (void)_addPlaces {
	NSData		*data;
	
	data = [[WCSettings settings] objectForKey:WCPlaces];
	
	if(data)
		[_places addObjectsFromArray:[NSKeyedUnarchiver unarchiveObjectWithData:data]];
}



- (void)_revalidatePlacesForConnection:(WCServerConnection *)connection {
	NSEnumerator		*enumerator;
	WCFile				*place;

	enumerator = [_places objectEnumerator];
	
	while((place = [enumerator nextObject])) {
		if([place belongsToConnection:connection])
			[place setConnection:connection];
	}
}



- (void)_invalidatePlacesForConnection:(WCServerConnection *)connection {
	NSEnumerator		*enumerator;
	WCFile				*place;

	enumerator = [_places objectEnumerator];
	
	while((place = [enumerator nextObject])) {
		if([place connection] == connection)
			[place setConnection:NULL];
	}
}



- (void)_revalidateFilesForConnection:(WCServerConnection *)connection {
	NSEnumerator			*enumerator;
	WCFile					*file;
	
	enumerator = [[[self _filesForConnection:connection] allValues] objectEnumerator];
	
	while((file = [enumerator nextObject])) {
		if([file belongsToConnection:connection])
			[file setConnection:connection];
	}
}



- (void)_revalidateFiles:(NSArray *)files {
	NSEnumerator			*enumerator;
	WCFile					*file;
	WCServerConnection		*connection;
	NSUInteger				i, count;
	
	enumerator = [files objectEnumerator];
	
	while((file = [enumerator nextObject])) {
		count = [_servers count];
		
		for(i = 0; i < count; i++) {
			connection = [_servers objectAtIndex:i];
			
			if([file belongsToConnection:connection])
				[file setConnection:connection];
		}
	}
}



- (void)_invalidateFilesForConnection:(WCServerConnection *)connection {
	NSEnumerator			*enumerator;
	WCFile					*file;
	
	enumerator = [[[self _filesForConnection:connection] allValues] objectEnumerator];
	
	while((file = [enumerator nextObject])) {
		if([file connection] == connection)
			[file setConnection:NULL];
	}
}



- (void)_removeSubscriptionsForConnection:(WCServerConnection *)connection {
	NSEnumerator		*enumerator;
	NSMutableSet		*unsubscribedFiles;
	WCFile				*file;
	
	unsubscribedFiles	= [NSMutableSet set];
	enumerator			= [_subscribedFiles objectEnumerator];
	
	while((file = [enumerator nextObject])) {
		if([file connection] == connection)
			[unsubscribedFiles addObject:file];
	}
	
	[_subscribedFiles minusSet:unsubscribedFiles];
}


	
#pragma mark -

- (NSUInteger)_selectedStyle {
	return [[_styleControl cell] tagForSegment:[_styleControl selectedSegment]];
}



- (void)_selectStyle:(NSUInteger)style {
	if(style == WCFilesStyleList) {
		[_filesTabView selectTabViewItemWithIdentifier:@"List"];
		[[self window] makeFirstResponder:_filesOutlineView];
	} else {
		[_filesTabView selectTabViewItemWithIdentifier:@"Tree"];

		if(_currentDirectory)
			[_filesTreeView selectPath:[_currentDirectory path] byExtendingSelection:NO];

		[[self window] makeFirstResponder:_filesTreeView];
	}
}



#pragma mark -

- (void)_updateWindowTitle {
	if(_searching)
		[[self window] setTitle:NSLS(@"Searching", @"Files window title") withSubtitle:[[[self _selectedSource] connection] name]];
	else
		[[self window] setTitle:NSLS(@"Files", @"Files window title") withSubtitle:[_currentDirectory path]];
}



- (void)_updatePermissions {
	NSArray					*array;
	WCServerConnection		*connection;
	
	connection = [self _selectedConnection];

	[_ownerPopUpButton removeAllItems];
	[_ownerPopUpButton addItem:[NSMenuItem itemWithTitle:NSLS(@"None", @"Create folder owner popup title") tag:1]];
	
	array = [[[connection administration] accountsController] userNames];
	
	if(array) {
		if([array count] > 0) {
			[_ownerPopUpButton addItem:[NSMenuItem separatorItem]];
			[_ownerPopUpButton addItemsWithTitles:array];
			[_ownerPopUpButton selectItemWithTitle:[[connection URL] user]];
		}
		
		[_permissionsProgressIndicator stopAnimation:self];
	} else {
		[_permissionsProgressIndicator startAnimation:self];
	}
	
	[_ownerPermissionsPopUpButton selectItemWithTag:WCFileOwnerRead | WCFileOwnerWrite];
	
	[_groupPopUpButton removeAllItems];
	[_groupPopUpButton addItem:[NSMenuItem itemWithTitle:NSLS(@"None", @"Create folder group popup title") tag:1]];
	
	array = [[[connection administration] accountsController] groupNames];
	
	if(array) {
		if([array count] > 0) {
			[_groupPopUpButton addItem:[NSMenuItem separatorItem]];
			[_groupPopUpButton addItemsWithTitles:array];
		}
		
		[_permissionsProgressIndicator stopAnimation:self];
	} else {
		[_permissionsProgressIndicator startAnimation:self];
	}
		
	[_groupPopUpButton selectItemAtIndex:0];
	[_groupPermissionsPopUpButton selectItemWithTag:0];

	[_everyonePermissionsPopUpButton selectItemWithTag:WCFileEveryoneWrite];
}



#pragma mark -

- (void)_changeCurrentDirectory:(WCFile *)file selectFiles:(BOOL)selectFiles forceSelection:(BOOL)forceSelection addToHistory:(BOOL)addToHistory {
	NSEnumerator	*enumerator;
	NSMutableSet	*unsubscribedFiles;
	WCFile			*subscribedFile;
	
	if(_searching) {
		[_searchField setStringValue:@""];
		
		[self search:self];
	}
	
	if([self _selectedStyle] == WCFilesStyleList && _initialDirectory) {
		file = [[_initialDirectory retain] autorelease];
		
		[_initialDirectory release];
		_initialDirectory = NULL;
	}
	
	file = [self _existingFileForFile:file];
	
	if(_currentDirectory) {
		if([file isEqual:_currentDirectory]) {
			[_selectFiles removeAllObjects];
			
			return;
		}
	
		unsubscribedFiles	= [NSMutableSet set];
		enumerator			= [_subscribedFiles objectEnumerator];
		
		while((subscribedFile = [enumerator nextObject])) {
			if(![[file path] hasPrefix:[subscribedFile path]]) {
				[self _unsubscribeFromDirectory:subscribedFile];
				
				[unsubscribedFiles addObject:subscribedFile];
			}
		}
		
		[_subscribedFiles minusSet:unsubscribedFiles];
	}
	
	if(addToHistory) {
		if([_history count] > 0 && _historyPosition != [_history count] - 1)
			[_history removeObjectsInRange:NSMakeRange(_historyPosition + 1, [_history count] - _historyPosition - 1)];
		
		[_history addObject:file];

		_historyPosition = [_history count] - 1;
	}

	[file retain];
	[_currentDirectory release];
	
	_currentDirectory = file;
	_currentDirectoryDeleted = NO;
	
	[self _updateWindowTitle];
	
	if(!_selectFilesWhenOpening) {
		if(_initialDirectory)
			[_selectFiles setArray:[NSArray arrayWithObject:_initialDirectory]];
		else if(forceSelection)
			[_selectFiles setArray:[NSArray arrayWithObject:_currentDirectory]];
	}
	
	[_initialDirectory release];
	_initialDirectory = NULL;

	if(_selectFilesWhenOpening || forceSelection)
		selectFiles = YES;
	
	[self _loadFilesAtDirectory:file selectFiles:selectFiles];
	
	if(![_subscribedFiles containsObject:file]) {
		[self _subscribeToDirectory:file];
		
		[_subscribedFiles addObject:file];
	}
	
	[self _validate];
}



- (void)_loadFilesAtDirectory:(WCFile *)file selectFiles:(BOOL)selectFiles {
	NSMutableArray			*directory;
	WCServerConnection		*connection;
	
	connection		= [file connection];
	directory		= [[self _directoriesForConnection:connection] objectForKey:[file path]];
    
	if([directory count] > 0) {
		if([_selectFiles count] == 0)
			[_selectFiles setArray:[self _selectedFiles]];
		
		[_filesOutlineView reloadData];
		[_filesTreeView reloadData];
		
		[self _reloadStatus];
		
		if(selectFiles)
			[self _selectFiles];
		else
			[_selectFiles removeAllObjects];
	} else {
		[self _reloadFilesAtDirectory:file selectFiles:selectFiles];
	}
	
	_selectFilesWhenOpening = NO;
}



- (void)_reloadFilesAtDirectory:(WCFile *)file {
	[self _reloadFilesAtDirectory:file selectFiles:YES];
}



- (void)_reloadFilesAtDirectory:(WCFile *)file selectFiles:(BOOL)selectFiles {
	NSMutableArray			*directory;
    WIP7Message				*message;
	WCServerConnection		*connection;
	
	if([file type] == WCFileDropBox && ![file isReadable])
		return;
	
	if([_selectFiles count] == 0)
		[_selectFiles setArray:[self _selectedFiles]];
	
	connection		= [file connection];
	directory		= [self _directoryForConnection:connection path:[file path]];
    	
	[directory removeAllObjects];
	
	[_filesTreeView reloadData];
	[_filesOutlineView reloadData];

	[_progressIndicator startAnimation:self];
	
	if(!selectFiles)
		[_selectFiles removeAllObjects];
	
    message = [WIP7Message messageWithName:@"wired.file.list_directory" spec:WCP7Spec];
    [message setString:[file path] forName:@"wired.file.path"];
    [connection sendMessage:message fromObserver:self selector:@selector(wiredFileListPathReply:)];
}



- (void)_subscribeToDirectory:(WCFile *)file {
	WIP7Message		*message;
	
	message = [WIP7Message messageWithName:@"wired.file.subscribe_directory" spec:WCP7Spec];
	[message setString:[file path] forName:@"wired.file.path"];
	[[file connection] sendMessage:message fromObserver:self selector:@selector(wiredFileSubscribeDirectoryReply:)];
}



- (void)_unsubscribeFromDirectory:(WCFile *)file {
	WIP7Message		*message;
	
	message = [WIP7Message messageWithName:@"wired.file.unsubscribe_directory" spec:WCP7Spec];
	[message setString:[file path] forName:@"wired.file.path"];
	[[file connection] sendMessage:message fromObserver:self selector:@selector(wiredFileUnsubscribeDirectoryReply:)];
}



#pragma mark -

- (void)_reloadSearch {
	NSEnumerator			*enumerator;
	NSArray					*connections;
	WIP7Message				*message;
	WCServerConnection		*connection;
	WIP7UInt32				transaction;
	
	if([[_searchField stringValue] length] > 0) {
		if([_thisServerButton state] == NSOnState)
			connections = [NSArray arrayWithObject:[[self _selectedSource] connection]];
		else
			connections = _servers;
		
		if(!_searching) {
			_styleBeforeSearch = [self _selectedStyle];
			_directoryBeforeSearch = [_currentDirectory retain];
			
			[_currentDirectory release];
			_currentDirectory = [[WCFile fileWithDirectory:@"<search>" connection:NULL] retain];
			
			[self _selectStyle:WCFilesStyleList];
			
			[_styleControl selectSegmentWithTag:WCFilesStyleList];
			[_styleControl setEnabled:NO];
		
			_searching = YES;
			
			[self _updateWindowTitle];
			[self _showSearchBar];
		}
		
		[self _removeDirectoryForConnection:NULL path:@"<search>"];
		
		enumerator = [connections objectEnumerator];
		
		while((connection = [enumerator nextObject])) {
			
			if([[_searchField stringValue] length] > 2) {
				[_progressIndicator startAnimation:self];
		
				message = [WIP7Message messageWithName:@"wired.file.search" spec:WCP7Spec];
				[message setString:[_searchField stringValue] forName:@"wired.file.query"];
				transaction = [connection sendMessage:message fromObserver:self selector:@selector(wiredFileSearchListReply:)];
				
				[_searchTransactions addObject:[NSNumber numberWithUnsignedInteger:transaction]];
			}
		}
		
		[_filesOutlineView reloadData];
		
		[self _validate];
		[self _reloadStatus];
	} else {
		if(_searching) {
			[_currentDirectory release];
			_currentDirectory = _directoryBeforeSearch;
			
			_directoryBeforeSearch = NULL;
			
			[self _selectStyle:_styleBeforeSearch];

			[_styleControl selectSegmentWithTag:_styleBeforeSearch];
			[_styleControl setEnabled:YES];
			
			_searching = NO;
			
			[self _validate];
			[self _updateWindowTitle];
			[self _hideSearchBar];
			
			[_filesOutlineView reloadData];
		}
	}
}



- (void)_showSearchBar {
	NSRect		scrollFrame, thisServerFrame, allServersFrame;
	
	[_thisServerButton setTitle:[NSSWF:NSLS(@"\u201c%@\u201d", @"Search bar button"), [[[self _selectedSource] connection] name]]];
	[_thisServerButton sizeToFit];
	
	thisServerFrame				= [_thisServerButton frame];
	allServersFrame				= [_allServersButton frame];
	allServersFrame.origin.x	= thisServerFrame.origin.x + thisServerFrame.size.width + 8.0;
	
	[_allServersButton setFrame:allServersFrame];
	
	scrollFrame					= [_filesScrollView frame];
	scrollFrame.size.height		-= [_searchBarView frame].size.height + 1.0;
	
	[_filesScrollView setFrame:scrollFrame];
	[_searchBarView setHidden:NO];
}



- (void)_hideSearchBar {
	NSRect		scrollFrame;

	scrollFrame					= [_filesScrollView frame];
	scrollFrame.size.height		+= [_searchBarView frame].size.height + 1.0;
	
	[_filesScrollView setFrame:scrollFrame];
	[_searchBarView setHidden:YES];
}



#pragma mark -

- (void)_openFiles:(NSArray *)files overrideNewWindow:(BOOL)override {
	NSEnumerator		*enumerator;
	NSMutableArray		*downloadFiles;
	WCFile				*file;
	BOOL				optionKey, newWindows;
	
	downloadFiles		= [NSMutableArray array];
	optionKey			= [[NSApp currentEvent] alternateKeyModifier];
	newWindows			= [[WCSettings settings] boolForKey:WCOpenFoldersInNewWindows];
	enumerator			= [files objectEnumerator];
	
	while((file = [enumerator nextObject])) {
		if([file connection] && [[file connection] isConnected]) {
			switch([file type]) {
				case WCFileDirectory:
				case WCFileUploads:
				case WCFileDropBox:
					if(override || (newWindows && !optionKey) || (!newWindows && optionKey))
						[WCFiles filesWithConnection:[file connection] file:file];
					else
						[self _changeCurrentDirectory:file selectFiles:YES forceSelection:NO addToHistory:YES];
					break;

				case WCFileFile:
					[downloadFiles addObject:file];
					break;
			}
		}
	}
	
	
	if([downloadFiles count] > 0)
		[[WCTransfers transfers] downloadFiles:files];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"

- (void)_quickLook {
    
	NSEnumerator	*enumerator;
	WIP7Message		*message;
	WCFile			*file;
	id				quickLookPanel;
	
	[_quickLookFiles removeAllObjects];

	enumerator = [[self _selectedFiles] objectEnumerator];

	while((file = [enumerator nextObject])) {
		if(![file previewItemURL]) {
			message = [WIP7Message messageWithName:@"wired.file.preview_file" spec:WCP7Spec];
			[message setString:[file path] forName:@"wired.file.path"];
			[[file connection] sendMessage:message fromObserver:self selector:@selector(wiredFilePreviewFileReply:)];
		}

		[_quickLookFiles addObject:file];
	}

	quickLookPanel = [_quickLookPanelClass performSelector:@selector(sharedPreviewPanel)];
	
	if([quickLookPanel isVisible])
		[quickLookPanel orderOut:self];
	else
		[quickLookPanel makeKeyAndOrderFront:self];

	if(NSAppKitVersionNumber >= 1038.0) {
		if([quickLookPanel respondsToSelector:@selector(reloadData)])
			[quickLookPanel performSelector:@selector(reloadData)];
	}
}



- (void)_reloadStatus {
	NSEnumerator			*enumerator;
	NSMutableArray			*directory;
	NSString				*path;

	path			= [_currentDirectory path];
	directory		= [self _directoryForConnection:[_currentDirectory connection] path:path];
	enumerator		= [directory objectEnumerator];

	if([path isEqualToString:@"/"]) {
		[_statusTextField setStringValue:[NSSWF:
			NSLS(@"%lu %@, %@ total, %@ available", @"Files info (count, 'item(s)', size, available)"),
			[directory count],
			[directory count] == 1
				? NSLS(@"item", @"Item singular")
				: NSLS(@"items", @"Item plural"),
			[_sizeFormatter stringFromSize:[[[_currentDirectory connection] server] size]],
			[_sizeFormatter stringFromSize:[_currentDirectory freeSpace]]]];
	} else {
		[_statusTextField setStringValue:[NSSWF:
			NSLS(@"%lu %@, %@ available", @"Files info (count, 'item(s)', available)"),
			[directory count],
			[directory count] == 1
				? NSLS(@"item", @"Item singular")
				: NSLS(@"items", @"Item plural"),
			[_sizeFormatter stringFromSize:[_currentDirectory freeSpace]]]];
	}
}



- (void)_selectFiles {
	NSEnumerator			*enumerator;
	NSMutableArray			*directory;
	NSMutableIndexSet		*indexes;
	WCFile					*file;
	NSUInteger				i, count;
	BOOL					complete, first;
	id						item;
    
    //file = nil;
	
	if([_selectFiles count] > 0) {
		directory		= [self _directoryForConnection:[self _selectedConnection] path:[_currentDirectory path]];
		indexes			= [NSMutableIndexSet indexSet];
		enumerator		= [_selectFiles objectEnumerator];
		first			= YES;
		complete		= YES;
        		
		while((file = [enumerator nextObject])) {
			count = [_filesOutlineView numberOfRows];
			
			for(i = 0; i < count; i++) {
				item = [_filesOutlineView itemAtRow:i];
				
				if([[item path] isEqualToString:[file path]]) {
					[indexes addIndex:i];
					
					break;
				}
			}
			
			[_filesTreeView selectPath:[file path] byExtendingSelection:!first];
            
			if([self _selectedStyle] == WCFilesStyleList) {
				if(![[_currentDirectory path] isEqualToString:[file path]]) {
					do {
						file = [self _existingParentFileForFile:file];
					} while([_filesOutlineView isItemExpanded:file]);
				}
			} else {
                if([file isFolder])
                    file = [self _existingParentFileForFile:file];
			}
			
			if(![[_currentDirectory path] isEqualToString:[file path]])
				complete = NO;
			
			first = NO;
		}
		      
		if([indexes count] > 0) {
			[_filesOutlineView selectRowIndexes:indexes byExtendingSelection:NO];
			[_filesOutlineView scrollRowToVisible:[indexes firstIndex]];
		}
		
		if(complete)
			[_selectFiles removeAllObjects];
	} else {
		if([self _selectedStyle] == WCFilesStyleTree)
			[_filesTreeView selectPath:[_filesTreeView selectedPath] byExtendingSelection:NO];
	}
}



- (void)_sortFiles {
	NSEnumerator			*enumerator;
	NSMutableArray			*directory;
	WISortOrder				sortOrder;
	SEL						selector;

	selector		= [self _sortSelector];
	sortOrder		= [_filesOutlineView sortOrder];
	enumerator		= [[self _directoriesForConnection:_searching ? NULL : [_currentDirectory connection]] objectEnumerator];
	
	while((directory = [enumerator nextObject])) {
		[directory sortUsingSelector:selector];
		
		if(sortOrder == WISortDescending)
			[directory reverse];
	}
}



- (SEL)_sortSelector {
	NSTableColumn		*tableColumn;

	tableColumn = [_filesOutlineView highlightedTableColumn];
	
	if(tableColumn == _nameTableColumn)
		return @selector(compareName:);
	else if(tableColumn == _kindTableColumn)
		return @selector(compareKind:);
	else if(tableColumn == _createdTableColumn)
		return @selector(compareCreationDate:);
	else if(tableColumn == _modifiedTableColumn)
		return @selector(compareModificationDate:);
	else if(tableColumn == _sizeTableColumn)
		return @selector(compareSize:);
	
	return @selector(compareName:);
}

@end



@implementation WCFiles

+ (id)filesWithConnection:(WCServerConnection *)connection file:(WCFile *)file {
	return [[[self alloc] _initFilesWithConnection:connection file:file selectFile:NULL] autorelease];
}



+ (id)filesWithConnection:(WCServerConnection *)connection file:(WCFile *)file selectFile:(WCFile *)selectFile {
	return [[[self alloc] _initFilesWithConnection:connection file:file selectFile:selectFile] autorelease];
}



- (void)dealloc {
	NSEnumerator			*enumerator;
	WCServerConnection		*connection;
	
	enumerator = [_servers objectEnumerator];
	
	while((connection = [enumerator nextObject]))
		[connection removeObserver:self];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[_errorQueue release];
	
	[_files release];
	[_servers release];
	[_places release];
	[_quickLookFiles release];
	[_searchTransactions release];
	[_history release];
	[_subscribedFiles release];
	[_selectFiles release];
	[_initialDirectory release];
	
	[_dateFormatter release];
	[_sizeFormatter release];
	
	[super dealloc];
}



#pragma mark -

- (void)windowDidLoad {
	NSToolbar			*toolbar;
	NSInvocation		*invocation;
	NSUInteger			style;

	toolbar = [[NSToolbar alloc] initWithIdentifier:@"Files"];
	[toolbar setDisplayMode:NSToolbarDisplayModeIconOnly];
	[toolbar setDelegate:self];
	[toolbar setShowsBaselineSeparator:NO];
	[toolbar setAllowsUserCustomization:YES];
	[toolbar setAutosavesConfiguration:YES];
	[[self window] setToolbar:toolbar];
	[toolbar release];
	
	[self setShouldCascadeWindows:YES];
	[self setWindowFrameAutosaveName:@"Files"];

	_errorQueue = [[WCErrorQueue alloc] initWithWindow:[self window]];
	
	if([_sourceOutlineView respondsToSelector:@selector(setSelectionHighlightStyle:)]) {
		style = 1; // NSTableViewSelectionHighlightStyleSourceList
		
		invocation = [NSInvocation invocationWithTarget:_sourceOutlineView action:@selector(setSelectionHighlightStyle:)];
		[invocation setArgument:&style atIndex:2];
		[invocation invoke];
	}
	
	[_sourceOutlineView registerForDraggedTypes:[NSArray arrayWithObjects:WCFilePboardType, WCPlacePboardType, NSFilenamesPboardType, NULL]];
	[_sourceOutlineView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:YES];
	[_sourceOutlineView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:NO];

	[_filesOutlineView setTarget:self];
	[_filesOutlineView setDoubleAction:@selector(open:)];
	[_filesOutlineView setEscapeAction:@selector(deselectAll:)];
	[_filesOutlineView setSpaceAction:@selector(quickLook:)];
	[_filesOutlineView setAllowsUserCustomization:YES];
	[_filesOutlineView setDefaultHighlightedTableColumnIdentifier:@"Name"];
	[_filesOutlineView setDefaultTableColumnIdentifiers:
		[NSArray arrayWithObjects:@"Name", @"Size", NULL]];
	[_filesOutlineView setAutosaveName:@"Files"];
    [_filesOutlineView setAutosaveTableColumns:YES];
	[_filesOutlineView registerForDraggedTypes:[NSArray arrayWithObjects:WCFilePboardType, NSFilenamesPboardType, NULL]];
	[_filesOutlineView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:YES];
	[_filesOutlineView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:NO];
	
	[_filesTreeView setTarget:self];
	[_filesTreeView setDoubleAction:@selector(open:)];
	[_filesTreeView setSpaceAction:@selector(quickLook:)];
	[_filesTreeView registerForDraggedTypes:[NSArray arrayWithObjects:WCFilePboardType, NSFilenamesPboardType, NULL]];
	[_filesTreeView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:YES];
	[_filesTreeView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:NO];

	[_styleControl selectSegmentWithTag:[[WCSettings settings] integerForKey:WCFilesStyle]];
	
	[self _hideSearchBar];
	[self _selectStyle:[self _selectedStyle]];
	[self _reloadStatus];
	[self _themeDidChange];
	[self _validate];
	
	[_sourceOutlineView reloadData];
	[_filesOutlineView reloadData];
	[_filesTreeView reloadData];

	[_sourceOutlineView expandItem:[NSNumber numberWithInteger:0]];
	[_sourceOutlineView expandItem:[NSNumber numberWithInteger:1]];
}



- (void)windowWillClose:(NSNotification *)notification {
	NSEnumerator		*enumerator;
	WCFile				*subscribedFile;
	
	enumerator = [_subscribedFiles objectEnumerator];
	
	while((subscribedFile = [enumerator nextObject]))
		[self _unsubscribeFromDirectory:subscribedFile];
	
	[self autorelease];
}



- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)identifier willBeInsertedIntoToolbar:(BOOL)willBeInsertedIntoToolbar {
	NSToolbarItem	*item;
	
	if([identifier isEqualToString:@"History"]) {
		return [NSToolbarItem toolbarItemWithIdentifier:identifier
												   name:NSLS(@"Back/Forward", @"Back/forward toolbar item")
												content:_historyControl
												 target:self
												 action:@selector(history:)];
	}
	else if([identifier isEqualToString:@"Style"]) {
		return [NSToolbarItem toolbarItemWithIdentifier:identifier
												   name:NSLS(@"View", @"View toolbar item")
												content:_styleControl
												 target:self
												 action:@selector(style:)];
	}
	else if([identifier isEqualToString:@"Download"]) {
		return [NSToolbarItem toolbarItemWithIdentifier:identifier
												   name:NSLS(@"Download", @"Download toolbar item")
												content:_downloadButton
												 target:self
												 action:@selector(download:)];
	}
	else if([identifier isEqualToString:@"Upload"]) {
		return [NSToolbarItem toolbarItemWithIdentifier:identifier
												   name:NSLS(@"Upload", @"Upload toolbar item")
												content:_uploadButton
												 target:self
												 action:@selector(upload:)];
	}
	else if([identifier isEqualToString:@"GetInfo"]) {
		return [NSToolbarItem toolbarItemWithIdentifier:identifier
												   name:NSLS(@"Get Info", @"Get info toolbar item")
												content:_infoButton
												 target:self
												 action:@selector(getInfo:)];
	}
	else if([identifier isEqualToString:@"QuickLook"]) {
		return [NSToolbarItem toolbarItemWithIdentifier:identifier
												   name:NSLS(@"Quick Look", @"Quick Look toolbar item")
												content:_quickLookButton
												 target:self
												 action:@selector(quickLook:)];
	}
	else if([identifier isEqualToString:@"CreateFolder"]) {
		return [NSToolbarItem toolbarItemWithIdentifier:identifier
												   name:NSLS(@"New Folder", @"New folder toolbar item")
												content:_createFolderButton
												 target:self
												 action:@selector(createFolder:)];
	}
	else if([identifier isEqualToString:@"Reload"]) {
		return [NSToolbarItem toolbarItemWithIdentifier:identifier
												   name:NSLS(@"Reload", @"Reload toolbar item")
												content:_reloadButton
												 target:self
												 action:@selector(reload:)];
	}
	else if([identifier isEqualToString:@"Delete"]) {
		return [NSToolbarItem toolbarItemWithIdentifier:identifier
												   name:NSLS(@"Delete", @"Delete toolbar item")
												content:_deleteButton
												 target:self
												 action:@selector(delete:)];
	}
	else if([identifier isEqualToString:@"Search"]) {
		item = [NSToolbarItem toolbarItemWithIdentifier:identifier
												   name:NSLS(@"Search", @"Search toolbar item")
												content:_searchField
												 target:self
												 action:@selector(search:)];
		
		[item setMinSize:NSMakeSize(50.0, [_searchField frame].size.height)];
		[item setMaxSize:NSMakeSize(250.0, [_searchField frame].size.height)];
		
		return item;
	}
	
	return NULL;
}



- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
	return [NSArray arrayWithObjects:
		@"History",
		@"Style",
		NSToolbarSpaceItemIdentifier,
		@"Download",
		@"Upload",
		@"GetInfo",
		@"QuickLook",
		@"CreateFolder",
		@"Reload",
		@"Delete",
		NSToolbarFlexibleSpaceItemIdentifier,
		@"Search",
		NULL];
}



- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
	return [NSArray arrayWithObjects:
		@"History",
		@"Style",
		@"Download",
		@"Upload",
		@"GetInfo",
		@"QuickLook",
		@"CreateFolder",
		@"Reload",
		@"Delete",
		@"Search",
		NSToolbarSeparatorItemIdentifier,
		NSToolbarSpaceItemIdentifier,
		NSToolbarFlexibleSpaceItemIdentifier,
		NSToolbarCustomizeToolbarItemIdentifier,
		NULL];
}



- (void)selectedThemeDidChange:(NSNotification *)notification {
	[self _themeDidChange];
}



- (void)linkConnectionLoggedIn:(NSNotification *)notification {
	WCServerConnection		*connection;
	
	connection = [notification object];
	
	if(![connection isKindOfClass:[WCServerConnection class]])
		return;
	
	[self _revalidatePlacesForConnection:connection];
	[self _revalidateFilesForConnection:connection];
	
	if(![connection isReconnecting]) {
		[_servers addObject:connection];
		
		[_sourceOutlineView reloadData];
	}

	[self _addConnection:connection];
	[self _validate];
	
	if(!_searching && _currentDirectory && !_currentDirectoryDeleted)
		[self _subscribeToDirectory:_currentDirectory];
}



- (void)linkConnectionDidClose:(NSNotification *)notification {
	WCServerConnection		*connection;
	
	connection = [notification object];
	
	if(![connection isKindOfClass:[WCServerConnection class]])
		return;
	
	[self _removeSubscriptionsForConnection:connection];
	[self _invalidatePlacesForConnection:connection];
	[self _invalidateFilesForConnection:connection];
	
	[connection removeObserver:self];
	
	[self _validate];
}



- (void)linkConnectionDidTerminate:(NSNotification *)notification {
	WCServerConnection		*connection;

	connection = [notification object];

	if(![connection isKindOfClass:[WCServerConnection class]])
		return;
	
	[self _removeSubscriptionsForConnection:connection];
	[self _invalidatePlacesForConnection:connection];
	[self _invalidateFilesForConnection:connection];
	
	if([_currentDirectory connection] == connection) {
		[_currentDirectory release];
		
		_currentDirectory = NULL;

		[_filesOutlineView reloadData];
		[_filesTreeView reloadData];
	}
	
	[_servers removeObject:connection];
	[_sourceOutlineView reloadData];
	
	[connection removeObserver:self];
	
	[self _validate];
}



- (void)serverConnectionServerInfoDidChange:(NSNotification *)notification {
	[_sourceOutlineView reloadData];
}



- (void)serverConnectionPrivilegesDidChange:(NSNotification *)notification {
	[self _validate];
}



- (void)accountsControllerAccountsDidChange:(NSNotification *)notification {
	[self _updatePermissions];
}



- (void)wiredFileDirectoryChanged:(WIP7Message *)message {
	WCFile		*file;
	
	file = [self _existingFileForFile:[WCFile fileWithDirectory:[message stringForName:@"wired.file.path"]
													 connection:[message contextInfo]]];
	
	[self performSelectorOnce:@selector(_reloadFilesAtDirectory:) withObject:file afterDelay:0.1];
}



- (void)wiredFileDirectoryDeleted:(WIP7Message *)message {
	WCFile		*file;
	
	file = [self _existingFileForFile:[WCFile fileWithDirectory:[message stringForName:@"wired.file.path"]
													 connection:[message contextInfo]]];
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self
											 selector:@selector(_reloadFilesAtDirectory:)
											   object:file];
	
	[_subscribedFiles removeObject:file];
	
	if(file == _currentDirectory)
		_currentDirectoryDeleted = YES;
}



- (void)wiredFileListPathReply:(WIP7Message *)message {
	NSEnumerator			*enumerator;
	NSMutableDictionary		*files;
	NSMutableArray			*listedFiles, *directory;
	NSString				*path;
	WCServerConnection		*connection;
	WCFile					*file, *listedFile;
	WIP7UInt64				free;
	WIP7Bool				value;
	
	connection = [message contextInfo];

	if([[message name] isEqualToString:@"wired.file.file_list"]) {
		file			= [WCFile fileWithMessage:message connection:connection];
		listedFiles		= [self _listedFilesForConnection:connection message:message];
		
		[listedFiles addObject:file];
	}
	else if([[message name] isEqualToString:@"wired.file.file_list.done"]) {
		[_progressIndicator stopAnimation:self];
		
		path			= [message stringForName:@"wired.file.path"];
		files			= [self _filesForConnection:connection];
		file			= [files objectForKey:path];
		directory		= [self _directoryForConnection:connection path:path];
		listedFiles		= [self _listedFilesForConnection:connection message:message];
		enumerator		= [listedFiles objectEnumerator];
		
		[directory removeAllObjects];
        
		while((listedFile = [enumerator nextObject])) {
			[files setObject:listedFile forKey:[listedFile path]];
			[directory addObject:listedFile];
		}
		
		[self _removeListedFilesForConnection:connection message:message];
		
		[directory sortUsingSelector:[self _sortSelector]];
		
		if([_filesOutlineView sortOrder] == WISortDescending)
			[directory reverse];

		[_filesOutlineView reloadData];
		[_filesTreeView reloadData];
		
		[message getUInt64:&free forName:@"wired.file.available"];
		
		[file setFreeSpace:free];
		
		if([message getBool:&value forName:@"wired.file.readable"])
			[file setReadable:value];
		
		if([message getBool:&value forName:@"wired.file.writable"])
			[file setWritable:value];
		
		[self _reloadStatus];
		[self _selectFiles];
		[self _validate];
		
		[connection removeObserver:self message:message];
	}
	else if([[message name] isEqualToString:@"wired.error"]) {
		[_progressIndicator stopAnimation:self];
		
		[_errorQueue showError:[WCError errorWithWiredMessage:message]];
		
		[connection removeObserver:self message:message];
	}
}



- (void)wiredFileSearchListReply:(WIP7Message *)message {
	NSEnumerator			*enumerator;
	NSMutableDictionary		*files;
	NSMutableArray			*searchedFiles, *directory;
	WCServerConnection		*connection;
	WCFile					*file;
	WIP7UInt32				transaction;
	
	connection = [message contextInfo];
	
	if([[message name] isEqualToString:@"wired.file.search_list"]) {
		file			= [WCFile fileWithMessage:message connection:connection];
		searchedFiles	= [self _searchedFilesForConnection:connection message:message];
		
		[searchedFiles addObject:file];
	}
	else if([[message name] isEqualToString:@"wired.file.search_list.done"]) {
		files			= [self _filesForConnection:NULL];
		directory		= [self _directoryForConnection:NULL path:@"<search>"];
		searchedFiles	= [self _searchedFilesForConnection:connection message:message];
		enumerator		= [searchedFiles objectEnumerator];
		
		while((file = [enumerator nextObject])) {
			[files setObject:file forKey:[file path]];
			[directory addObject:file];
		}
		
		[self _removeSearchedFilesForConnection:connection message:message];
		
		[directory sortUsingSelector:[self _sortSelector]];
		
		if([_filesOutlineView sortOrder] == WISortDescending)
			[directory reverse];
		
		[_filesOutlineView reloadData];
		
		[self _reloadStatus];
		
		if([message getUInt32:&transaction forName:@"wired.transaction"])
			[_searchTransactions removeObject:[NSNumber numberWithUnsignedInteger:transaction]];
		
		if([_searchTransactions count] == 0)
			[_progressIndicator stopAnimation:self];
		
		[connection removeObserver:self message:message];
	}
	else if([[message name] isEqualToString:@"wired.error"]) {
		if([message getUInt32:&transaction forName:@"wired.transaction"])
			[_searchTransactions removeObject:[NSNumber numberWithUnsignedInteger:transaction]];
		
		if([_searchTransactions count] == 0)
			[_progressIndicator stopAnimation:self];
		
		[_errorQueue showError:[WCError errorWithWiredMessage:message]];
		
		[connection removeObserver:self message:message];
	}
}



- (void)wiredFileSubscribeDirectoryReply:(WIP7Message *)message {
	WCServerConnection		*connection;
	
	connection = [message contextInfo];
	
	if([[message name] isEqualToString:@"wired.okay"]) {
		[connection removeObserver:self message:message];
	}
	else if([[message name] isEqualToString:@"wired.error"]) {
		[_errorQueue showError:[WCError errorWithWiredMessage:message]];
		
		[connection removeObserver:self message:message];
	}
}



- (void)wiredFileUnsubscribeDirectoryReply:(WIP7Message *)message {
	WCServerConnection		*connection;
	
	connection = [message contextInfo];
	
	if([[message name] isEqualToString:@"wired.okay"]) {
		[connection removeObserver:self message:message];
	}
	else if([[message name] isEqualToString:@"wired.error"]) {
		[_errorQueue showError:[WCError errorWithWiredMessage:message]];
		
		[connection removeObserver:self message:message];
	}
}



- (void)wiredFileCreateDirectoryReply:(WIP7Message *)message {
	if([[message name] isEqualToString:@"wired.error"])
		[_errorQueue showError:[WCError errorWithWiredMessage:message]];
}



- (void)wiredFileDeleteReply:(WIP7Message *)message {
	if([[message name] isEqualToString:@"wired.error"])
		[_errorQueue showError:[WCError errorWithWiredMessage:message]];
}



- (void)wiredFileMoveReply:(WIP7Message *)message {
	if([[message name] isEqualToString:@"wired.error"]) {
		[_errorQueue showError:[WCError errorWithWiredMessage:message]];

		[self performSelectorOnce:@selector(_reloadFilesAtDirectory:) withObject:_currentDirectory afterDelay:0.1];
	}
}



- (void)wiredFileLinkReply:(WIP7Message *)message {
	if([[message name] isEqualToString:@"wired.error"])
		[_errorQueue showError:[WCError errorWithWiredMessage:message]];
}



- (void)wiredFilePreviewFileReply:(WIP7Message *)message {
	NSEnumerator			*enumerator;
	NSString				*path;
	NSURL					*url;
	WCServerConnection		*connection;
	WCFile					*file;
	id						quickLookPanel;
	
	connection = [message contextInfo];
	
	if([[message name] isEqualToString:@"wired.file.preview"]) {
		path			= [message stringForName:@"wired.file.path"];
		enumerator		= [_quickLookFiles objectEnumerator];
		
		while((file = [enumerator nextObject])) {
			if([[file path] isEqualToString:path]) {
				url = [NSURL fileURLWithPath:[NSFileManager temporaryPathWithFilename:[path lastPathComponent]]];
				
				[[message dataForName:@"wired.file.preview"] writeToURL:url atomically:YES];
				
				[file setPreviewItemURL:url];
				
				break;
			}
		}
		
		if(file) {
			quickLookPanel = [_quickLookPanelClass performSelector:@selector(sharedPreviewPanel)];
			
			if(NSAppKitVersionNumber >= 1038.0) {
					if([quickLookPanel respondsToSelector:@selector(refreshCurrentPreviewItem)])
						[quickLookPanel performSelector:@selector(refreshCurrentPreviewItem)];
			} else {
				if([quickLookPanel respondsToSelector:@selector(setURLs:)]) {
					[quickLookPanel performSelector:@selector(setURLs:)
										 withObject:[NSArray arrayWithObject:[[_quickLookFiles objectAtIndex:0] previewItemURL]]];
				}
			}
		}
		
		[connection removeObserver:self message:message];
	}
	else if([[message name] isEqualToString:@"wired.error"]) {
		[_errorQueue showError:[WCError errorWithWiredMessage:message]];
		
		[connection removeObserver:self message:message];
	}
}

#pragma clang diagnostic pop

- (void)wiredFileSetLabelReply:(WIP7Message *)message {
	WCServerConnection		*connection;
	
	connection = [message contextInfo];
	
	if([[message name] isEqualToString:@"wired.okay"]) {
		[connection removeObserver:self message:message];
	}
	else if([[message name] isEqualToString:@"wired.error"]) {
		[_errorQueue showError:[WCError errorWithWiredMessage:message]];
		
		[connection removeObserver:self message:message];
	}
}



- (void)controlTextDidChange:(NSNotification *)notification {
	NSControl		*control;
	WCFileType		type;
	
	control = [notification object];
	
	if(control == _nameTextField) {
		type = [WCFile folderTypeForString:[_nameTextField stringValue]];
		
		if(type != WCFileDirectory) {
			[_typePopUpButton selectItemWithTag:type];
			
			[self _validatePermissions];
		}
	}
}



#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem *)item {
	SEL		selector;
	
	selector = [item action];
	
	if(selector == @selector(getInfo:))
		return [self _validateGetInfo];
	else if(selector == @selector(newDocument:))
		return [self _validateCreateFolder];
	else if(selector == @selector(deleteDocument:))
		return [self _validateDelete];
	else if(selector == @selector(reloadDocument:))
		return [self _validateReload];
	else if(selector == @selector(quickLook:))
		return [self _validateQuickLook];
	else if(selector == @selector(label:))
		return [self _validateSetLabel];
	
	return YES;
}



#pragma mark -

- (NSString *)newDocumentMenuItemTitle {
	return NSLS(@"New Folder\u2026", @"New menu item");
}



- (NSString *)deleteDocumentMenuItemTitle {
	NSArray		*files;
	
	files = [self _selectedFiles];
	
	switch([files count]) {
		case 0:
			return NSLS(@"Delete File\u2026", @"Delete menu item");
			break;
		
		case 1:
			return [NSSWF:NSLS(@"Delete \u201c%@\u201d\u2026", @"Delete menu item (file)"), [[files objectAtIndex:0] name]];
			break;
		
		default:
			return [NSSWF:NSLS(@"Delete %u Items\u2026", @"Delete menu item (count)"), [files count]];
			break;
	}
}



- (NSString *)reloadDocumentMenuItemTitle {
	if(_searching)
		return NULL;
	
	return [NSSWF:NSLS(@"Reload \u201c%@\u201d", @"Reload menu item (file)"), [_currentDirectory name]];
}



- (NSString *)quickLookMenuItemTitle {
	NSArray		*files;
	
	files = [self _selectedFiles];
	
	switch([files count]) {
		case 0:
			return NSLS(@"Quick Look", @"Quick Look menu item");
			break;
		
		case 1:
			return [NSSWF:NSLS(@"Quick Look \u201c%@\u201d", @"Quick Look menu item (file)"), [[files objectAtIndex:0] name]];
			break;
		
		default:
			return [NSSWF:NSLS(@"Quick Look %u Items", @"Quick Look menu item (count)"), [files count]];
			break;
	}
}



#pragma mark -

- (IBAction)open:(id)sender {
	NSArray			*files;
	NSUInteger		style;
	
	if([self _selectedStyle] == WCFilesStyleList && [_filesOutlineView clickedHeader])
		return;

	style = [self _selectedStyle];
	files = [self _selectedFiles];
	
	[self _openFiles:files overrideNewWindow:(style == WCFilesStyleTree || [files count] > 1 || _searching)];
}



- (IBAction)deselectAll:(id)sender {
	[_filesOutlineView deselectAll:self];
}



- (IBAction)enclosingFolder:(id)sender {
	WCFile		*file;
	
	if(![[_currentDirectory path] isEqualToString:@"/"]) {
		[_selectFiles removeAllObjects];
		[_selectFiles addObject:_currentDirectory];
		
		file = [self _existingParentFileForFile:_currentDirectory];
		
		[self _openFiles:[NSArray arrayWithObject:file] overrideNewWindow:([self _selectedStyle] == WCFilesStyleTree)];
	}
}



- (IBAction)label:(id)sender {
	NSEnumerator	*enumerator;
	WIP7Message		*message;
	WCFile			*file;
	WCFileLabel		label;
	
	if(![self _validateSetLabel])
		return;

	label		= [sender tag];
	enumerator	= [[self _selectedFiles] objectEnumerator];
	
	while((file = [enumerator nextObject])) {
		message = [WIP7Message messageWithName:@"wired.file.set_label" spec:WCP7Spec];
		[message setString:[file path] forName:@"wired.file.path"];
		[message setEnum:label forName:@"wired.file.label"];
		[[file connection] sendMessage:message fromObserver:self selector:@selector(wiredFileSetLabelReply:)];
	}
}



#pragma mark -

- (IBAction)history:(id)sender {
	NSArray		*history;
	
	history = [_history copy];
	
	if([_historyControl selectedSegment] == 0) {
		if(_searching) {
			[_searchField setStringValue:@""];
			
			[self _reloadSearch];
		}
		else if(_historyPosition > 0) {
			[self _changeCurrentDirectory:[_history objectAtIndex:_historyPosition - 1]
							  selectFiles:NO
						   forceSelection:YES
							 addToHistory:NO];
			
			_historyPosition--;
		}
	} else {
		if(_historyPosition < [_history count] - 1) {
			[self _changeCurrentDirectory:[_history objectAtIndex:_historyPosition + 1]
							  selectFiles:NO
						   forceSelection:YES
							 addToHistory:NO];
			
			_historyPosition++;
		}
	}
	
	[_history setArray:history];
	
	[self _validate];
}



- (IBAction)style:(id)sender {
	NSUInteger		style;
	
	style = [self _selectedStyle];
	
	[self _selectStyle:style];
	[self _loadFilesAtDirectory:_currentDirectory selectFiles:NO];
	
	[[WCSettings settings] setInteger:style forKey:WCFilesStyle];
}



- (IBAction)download:(id)sender {
	if(![self _validateDownload])
		return;

	[[WCTransfers transfers] downloadFiles:[self _selectedFiles]];
}



- (IBAction)upload:(id)sender {
	NSOpenPanel		*openPanel;
	
	if(![self _validateUploadToDirectory:_currentDirectory])
		return;

	openPanel = [NSOpenPanel openPanel];

	[openPanel setCanChooseDirectories:[[[self _selectedConnection] account] transferUploadDirectories]];
	[openPanel setCanChooseFiles:[[[self _selectedConnection] account] transferUploadFiles]];
	[openPanel setAllowsMultipleSelection:YES];
    
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result) {
        NSMutableArray			*urlPaths;
        NSArray                 *paths;
        
        if(result == NSModalResponseOK) {
            urlPaths = [NSMutableArray array];
            
            for(NSURL *url in [openPanel URLs]) {
                [urlPaths addObject:[url path]];
            }
            
            paths = [urlPaths sortedArrayUsingSelector:@selector(finderCompare:)];
            
            [[WCTransfers transfers] uploadPaths:paths toFolder:_currentDirectory];
        }
    }];
}






- (IBAction)getInfo:(id)sender {
	NSEnumerator		*enumerator;
	NSArray				*files;
	WCFile				*file;
	
	if(![self _validateGetInfo])
		return;
	
	files = [self _selectedFiles];
	
	if([[NSApp currentEvent] alternateKeyModifier]) {
		enumerator = [files objectEnumerator];
		
		while((file = [enumerator nextObject]))
			[WCFileInfo fileInfoWithConnection:[file connection] file:file];
	} else {
		file = [files objectAtIndex:0];
		
		[WCFileInfo fileInfoWithConnection:[file connection] files:files];
	}
}



- (IBAction)copyExternalURL:(id)sender {
	NSArray			*files;
    NSMutableArray  *urls;
	NSString        *urlString;
    
	if(![self _validateCopy])
		return;
	
	files		= [self _selectedFiles];
    urls        = [NSMutableArray arrayWithCapacity:[files count]];
    
	if(files) {
        for (WCFile *file in files) {
            // format to wired://@:/
            urlString = [file externalURLString];
            [urls addObject:[file externalURLString]];
        }
        
        NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
        [pasteboard clearContents];
        [pasteboard writeObjects:urls];
    }
}


- (IBAction)copyInternalURL:(id)sender {
	NSArray			*files;
    NSMutableArray  *urls;
	NSString        *urlString;
    
	if(![self _validateCopy])
		return;
	
	files		= [self _selectedFiles];
    urls        = [NSMutableArray arrayWithCapacity:[files count]];    
    
	if(files) {
        for (WCFile *file in files) {
            // format to wired:///
            urlString = [file internalURLString];
            [urls addObject:[file internalURLString]];
        }
        
        NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
        [pasteboard clearContents]; 
        [pasteboard writeObjects:urls];
    }
}


- (IBAction)copyPath:(id)sender {
	NSArray			*files;
    NSMutableArray  *paths;
	
	if(![self _validateCopy])
		return;
	
	files		= [self _selectedFiles];
    paths        = [NSMutableArray arrayWithCapacity:[files count]];    
    
	if(files) {
        for (WCFile *file in files) {
            // format to wired:///
            [paths addObject:[file path]];
        }
        
        NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
        [pasteboard clearContents]; 
        [pasteboard writeObjects:paths];
    }
}



- (IBAction)quickLook:(id)sender {
	NSEnumerator	*enumerator;
	NSArray			*files;
	NSAlert			*alert;
	WCFile			*file;
	BOOL			confirmQuickLook = NO;
	
	if(![self _validateQuickLook])
		return;
	
	files		= [self _selectedFiles];
	enumerator	= [files objectEnumerator];
	
	while((file = [enumerator nextObject])) {
		if(![file previewItemURL] && [file totalSize] >= 512 * 1024)
			confirmQuickLook = YES;
	}
	
	if(confirmQuickLook) {
		alert = [[NSAlert alloc] init];
		
		if([files count] == 1) {
			[alert setMessageText:[NSSWF:
				NSLS(@"Are you sure you want to Quick Look \u201c%@\u201d?", @"Confirm Quick Look dialog title"),
				[[files objectAtIndex:0] name]]];
			[alert setInformativeText:
				NSLS(@"This file is large and make take a while to load.", @"Confirm Quick Look dialog description")];
		} else {
			[alert setMessageText:[NSSWF:
				NSLS(@"Are you sure you want to Quick Look %u items?", @"Confirm Quick Look dialog title"),
				[files count]]];
			[alert setInformativeText:
				NSLS(@"Some of the files are large and make take a while to load.", @"Confirm Quick Look dialog description")];
		}
		
		[alert addButtonWithTitle:NSLS(@"Quick Look", @"Confirm Quick Look button title")];
		[alert addButtonWithTitle:NSLS(@"Cancel", @"Confirm Quick Look button title")];
		[alert beginSheetModalForWindow:[self window]
						  modalDelegate:self
						 didEndSelector:@selector(quickLookSheetDidEnd:returnCode:contextInfo:)
							contextInfo:NULL];
		[alert release];
	} else {
		[self _quickLook];
	}
}



- (void)quickLookSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	if(returnCode == NSAlertDefaultReturn)
		[self _quickLook];
}



- (IBAction)newDocument:(id)sender {
	[self createFolder:sender];
}



- (IBAction)createFolder:(id)sender {
	NSEnumerator		*enumerator;
	NSMenuItem			*item;
	
	if(![self _validateCreateFolder])
		return;
	
	if(![[_typePopUpButton lastItem] image]) {
		enumerator = [[_typePopUpButton itemArray] objectEnumerator];
		
		while((item = [enumerator nextObject]))
			[item setImage:[WCFile iconForFolderType:[item tag] width:16.0 open:NO]];
	}
	
	[_nameTextField setStringValue:NSLS(@"Untitled", @"New folder name")];
	[_nameTextField selectText:self];
	[_typePopUpButton selectItemWithTag:WCFileDirectory];
	
	[self _validatePermissions];
	[self _updatePermissions];
	
	[NSApp beginSheet:_createFolderPanel
	   modalForWindow:[self window]
		modalDelegate:self
	   didEndSelector:@selector(createFolderSheetDidEnd:returnCode:contextInfo:)
		  contextInfo:NULL];
}



- (void)createFolderSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	NSString		*path, *owner, *group;
	WIP7Message		*message;
	NSUInteger		ownerPermissions, groupPermissions, everyonePermissions;
	WCFileType		type;

	[_createFolderPanel close];

	if(returnCode == NSAlertDefaultReturn) {
		path = [[_currentDirectory path] stringByAppendingPathComponent:[_nameTextField stringValue]];
		
		message = [WIP7Message messageWithName:@"wired.file.create_directory" spec:WCP7Spec];
		[message setString:path forName:@"wired.file.path"];
		
		type = [_typePopUpButton tagOfSelectedItem];

		if(type != WCFileDirectory)
			[message setEnum:type forName:@"wired.file.type"];
		
		if(type == WCFileDropBox) {
			owner					= ([_ownerPopUpButton tagOfSelectedItem] == 0) ? [_ownerPopUpButton titleOfSelectedItem] : @"";
			ownerPermissions		= [_ownerPermissionsPopUpButton tagOfSelectedItem];
			group					= ([_groupPopUpButton tagOfSelectedItem] == 0) ? [_groupPopUpButton titleOfSelectedItem] : @"";
			groupPermissions		= [_groupPermissionsPopUpButton tagOfSelectedItem];
			everyonePermissions		= [_everyonePermissionsPopUpButton tagOfSelectedItem];
			
			[message setString:owner forName:@"wired.file.owner"];
			[message setBool:(ownerPermissions & WCFileOwnerRead) forName:@"wired.file.owner.read"];
			[message setBool:(ownerPermissions & WCFileOwnerWrite) forName:@"wired.file.owner.write"];
			[message setString:group forName:@"wired.file.group"];
			[message setBool:(groupPermissions & WCFileGroupRead) forName:@"wired.file.group.read"];
			[message setBool:(groupPermissions & WCFileGroupWrite) forName:@"wired.file.group.write"];
			[message setBool:(everyonePermissions & WCFileEveryoneRead) forName:@"wired.file.everyone.read"];
			[message setBool:(everyonePermissions & WCFileEveryoneWrite) forName:@"wired.file.everyone.write"];
		}
		
		[[self _selectedConnection] sendMessage:message fromObserver:self selector:@selector(wiredFileCreateDirectoryReply:)];
	}
}



- (IBAction)type:(id)sender {
	[self _validatePermissions];
}



- (IBAction)reloadDocument:(id)sender {
	[self reload:sender];
}



- (IBAction)reload:(id)sender {
	NSEnumerator	*enumerator;
	NSArray			*files;
	WCFile			*file;
	
	if(![self _validateReload])
		return;
	
	files = [self _selectedFiles];
	
	if([self _selectedStyle] == WCFilesStyleList && [files count] > 0) {
		enumerator = [files objectEnumerator];
		
		while((file = [enumerator nextObject])) {
			if(![_filesOutlineView isItemExpanded:file])
				file = [self _existingParentFileForFile:file];
			
			[self _reloadFilesAtDirectory:file];
		}
	} else {
		[self _reloadFilesAtDirectory:_currentDirectory];
	}
}



- (IBAction)deleteDocument:(id)sender {
	[self delete:sender];
}



- (IBAction)delete:(id)sender {
	NSAlert			*alert;
	NSArray			*files;
	NSString		*title;
	
	if(![self _validateDelete])
		return;

	files = [self _selectedFiles];

	if([files count] == 1) {
		title = [NSSWF:
			NSLS(@"Are you sure you want to delete \u201c%@\u201d?", @"Delete file dialog title (filename)"),
			[[files objectAtIndex:0] name]];
	} else {
		title = [NSSWF:
			NSLS(@"Are you sure you want to delete %lu items?", @"Delete file dialog title (count)"),
			[files count]];
	}

	alert = [[NSAlert alloc] init];
	[alert setMessageText:title];
	[alert setInformativeText:NSLS(@"This cannot be undone.", @"Delete file dialog description")];
	[alert addButtonWithTitle:NSLS(@"Delete", @"Delete file button title")];
	[alert addButtonWithTitle:NSLS(@"Cancel", @"Delete file button title")];
	[alert beginSheetModalForWindow:[self window]
					  modalDelegate:self
					 didEndSelector:@selector(deleteSheetDidEnd:returnCode:contextInfo:)
						contextInfo:NULL];
	[alert release];
}



- (void)deleteSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	NSEnumerator	*enumerator;
	NSArray			*files;
	NSString		*path;
	WIP7Message		*message;
	WCFile			*file;

	if(returnCode == NSAlertFirstButtonReturn) {
		files		= [self _selectedFiles];
		enumerator	= [files objectEnumerator];

		if([self _selectedStyle] == WCFilesStyleTree) {
			file = [files objectAtIndex:0];
			path = [[file path] stringByDeletingLastPathComponent];
			
			[self _changeCurrentDirectory:[WCFile fileWithDirectory:path connection:[file connection]]
							  selectFiles:YES
						   forceSelection:NO
							 addToHistory:NO];
		}

		while((file = [enumerator nextObject])) {
			message = [WIP7Message messageWithName:@"wired.file.delete" spec:WCP7Spec];
			[message setString:[file path] forName:@"wired.file.path"];
			[[file connection] sendMessage:message fromObserver:self selector:@selector(wiredFileDeleteReply:)];
		}
	}
}



- (IBAction)search:(id)sender {
	[self _reloadSearch];
}



#pragma mark -

- (IBAction)thisServer:(id)sender {
	[_allServersButton setState:NSOffState];

	[self _reloadSearch];
}



- (IBAction)allServers:(id)sender {
	[_thisServerButton setState:NSOffState];

	[self _reloadSearch];
}



#pragma mark -

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
	WCFile		*file;
	
	if(outlineView == _sourceOutlineView) {
		if(!item)
			return 2;
		
		if([item isKindOfClass:[NSNumber class]]) {
			if([item unsignedIntegerValue] == 0)
				return [_servers count];
			else
				return [_places count];
		}
	}
	else if(outlineView == _filesOutlineView) {
		if(item)
			file = item;
		else
			file = _currentDirectory;
		
		return [[self _directoryForConnection:[file connection] path:[file path]] count];
	}
	
	return 0;
}



- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
	WCFile		*file;
	
	if(outlineView == _sourceOutlineView) {
		if(!item)
			return [NSNumber numberWithInteger:index];
		
		if([item isKindOfClass:[NSNumber class]]) {
			if([item unsignedIntegerValue] == 0)
				return [[_servers objectAtIndex:index] identifier];
			else
				return [_places objectAtIndex:index];
		}
	}
	else if(outlineView == _filesOutlineView) {
		if(item)
			file = item;
		else
			file = _currentDirectory;
		
		return [[self _directoryForConnection:[file connection] path:[file path]] objectAtIndex:index];
	}
	
	return NULL;
}



- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
	NSDictionary			*attributes;
	NSString				*label;
	WCServerConnection		*connection;
	WCFile					*file;
	
	if(outlineView == _sourceOutlineView) {
		if([item isKindOfClass:[NSNumber class]]) {
			if([item unsignedIntegerValue] == 0)
				label = NSLS(@"Servers", @"Files header");
			else
				label = NSLS(@"Places", @"Files header");
			
			attributes = [NSDictionary dictionaryWithObjectsAndKeys:
				[NSColor colorWithCalibratedRed:96.0 / 255.0 green:110.0 / 255.0 blue:128.0 / 255.0 alpha:1.0],
					NSForegroundColorAttributeName,
				[NSFont boldSystemFontOfSize:11.0],
					NSFontAttributeName,
				_truncatingTailParagraphStyle,
					NSParagraphStyleAttributeName,
				NULL];
			
			return [NSAttributedString attributedStringWithString:[label uppercaseString] attributes:attributes];
		}
		else if([item isKindOfClass:[WCFile class]]) {
			connection = [(WCFile *) item connection];
			
			if(connection && [connection isConnected]) {
				attributes = [NSDictionary dictionaryWithObjectsAndKeys:
					[NSColor blackColor],
						NSForegroundColorAttributeName,
					[NSFont systemFontOfSize:11.0],
						NSFontAttributeName,
					_truncatingTailParagraphStyle,
						NSParagraphStyleAttributeName,
					NULL];
			} else {
				attributes = [NSDictionary dictionaryWithObjectsAndKeys:
					[NSColor colorWithCalibratedRed:96.0 / 255.0 green:110.0 / 255.0 blue:128.0 / 255.0 alpha:1.0],
						NSForegroundColorAttributeName,
					[NSFont systemFontOfSize:11.0],
						NSFontAttributeName,
					_truncatingTailParagraphStyle,
						NSParagraphStyleAttributeName,
					NULL];
			}
			
			return [NSAttributedString attributedStringWithString:[item name] attributes:attributes];
		}
		else if([item isKindOfClass:[NSString class]]) {
			connection = [[[WCPublicChat publicChat] chatControllerForConnectionIdentifier:item] connection];
			
			return [connection name];
		}
	}
	else if(outlineView == _filesOutlineView) {
		file = item;
		
		if(tableColumn == _nameTableColumn)
			return [file name];
		else if(tableColumn == _kindTableColumn)
			return [file kind];
		else if(tableColumn == _createdTableColumn)
			return [_dateFormatter stringFromDate:[file creationDate]];
		else if(tableColumn == _modifiedTableColumn)
			return [_dateFormatter stringFromDate:[file modificationDate]];
		else if(tableColumn == _sizeTableColumn)
			return [file isFolder] ? [file humanReadableDirectoryCount] : [_sizeFormatter stringFromSize:[file totalSize]];
		else if(tableColumn == _serverTableColumn)
			return [[file connection] name];
	}

	return NULL;
}



- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
	if(outlineView == _sourceOutlineView)
		return [item isKindOfClass:[NSNumber class]];
	else if(outlineView == _filesOutlineView)
		return [item isFolder];
	
	return NO;
}



- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {
	NSImage		*image;
	
	if(outlineView == _sourceOutlineView) {
		if([item isKindOfClass:[WCFile class]]) {
			image = [item iconWithWidth:16.0 open:NO];
			
			[cell setImage:image];
		}
		else if([item isKindOfClass:[NSString class]]) {
			image = [NSImage imageNamed:@"WiredServer"];
			
			[image setSize:NSMakeSize(16.0, 16.0)];
			[cell setImage:image];
		}
		else {
			[cell setImage:NULL];
		}
		
		[cell setVerticalTextOffset:3.0];
	}
	else if(outlineView == _filesOutlineView) {
		if(tableColumn == _nameTableColumn) {
			image = [item iconWithWidth:_iconWidth open:[_filesOutlineView isItemExpanded:item]];
			
			[cell setImage:image];
		}
	}
}



- (NSColor *)outlineView:(NSOutlineView *)outlineView labelColorByItem:(id)item {
	if(outlineView == _filesOutlineView)
		return [item labelColor];
	
	return NULL;
}



- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item {
	if(outlineView == _sourceOutlineView) {
		if([item isKindOfClass:[NSNumber class]])
			return NO;
		
		if([item isKindOfClass:[WCFile class]])
			return ([(WCFile *) item connection] != NULL && [[(WCFile *) item connection] isConnected]);
	}
	
	return YES;
}



- (void)outlineViewItemDidExpand:(NSNotification *)notification {
	WCFile		*file;
	
	if([notification object] == _filesOutlineView) {
		file = [[notification userInfo] objectForKey:@"NSObject"];
		
		[self _subscribeToDirectory:file];
		[self _loadFilesAtDirectory:file selectFiles:NO];
		
		[_subscribedFiles addObject:file];
	}
}



- (void)outlineViewItemDidCollapse:(NSNotification *)notification {
	WCFile		*file;
	
	if([notification object] == _filesOutlineView) {
		file = [[notification userInfo] objectForKey:@"NSObject"];
		
		if([_subscribedFiles containsObject:file]) {
			[self _unsubscribeFromDirectory:file];
			
			[_subscribedFiles removeObject:file];
				
			[_filesOutlineView setNeedsDisplay:YES];
		}
	}
}



- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
	NSOutlineView		*outlineView;
	
	outlineView = [notification object];
	
	if(outlineView == _sourceOutlineView)
		[self _changeCurrentDirectory:[self _selectedSource] selectFiles:NO forceSelection:YES addToHistory:YES];
	else if(outlineView == _filesOutlineView)
		[self _validate];
}



- (void)outlineView:(NSOutlineView *)outlineView didClickTableColumn:(NSTableColumn *)tableColumn {
	[_filesOutlineView setHighlightedTableColumn:tableColumn];
	[self _sortFiles];
	[_filesOutlineView reloadData];
	
	[self _validate];
}



- (NSString *)outlineView:(NSOutlineView *)outlineView stringValueByItem:(id)item {
	if(outlineView == _filesOutlineView)
		return [(WCFile *) item name];
	
	return NULL;
}



- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pasteboard {
	NSEnumerator		*enumerator;
	WCFile				*file;
	id					item;
	
	enumerator = [items objectEnumerator];

	if(outlineView == _sourceOutlineView) {
		while((item = [enumerator nextObject])) {
			if(![item isKindOfClass:[WCFile class]])
				return NO;
		}
		
		[pasteboard declareTypes:[NSArray arrayWithObject:WCPlacePboardType] owner:NULL];
		[pasteboard setData:[NSKeyedArchiver archivedDataWithRootObject:items] forType:WCPlacePboardType];
		
		return YES;
	}
	else if(outlineView == _filesOutlineView) {
		while((file = [enumerator nextObject])) {
			if(![file connection] || ![[file connection] isConnected])
				return NO;
		}
		
		[pasteboard declareTypes:[NSArray arrayWithObjects:WCFilePboardType, NSFilesPromisePboardType, NULL] owner:NULL];
		[pasteboard setData:[NSKeyedArchiver archivedDataWithRootObject:items] forType:WCFilePboardType];
	    [pasteboard setPropertyList:[NSArray arrayWithObject:NSFileTypeForHFSTypeCode('\0\0\0\0')] forType:NSFilesPromisePboardType];
		
		return YES;
	}
	
	return NO;
}



- (NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)index {
	NSEnumerator		*enumerator;
	NSPasteboard		*pasteboard;
	NSEvent				*event;
	NSArray				*types, *sources;
	WCFile				*sourceFile, *destinationFile;
	BOOL				copy, link;

	pasteboard	= [info draggingPasteboard];
	types		= [pasteboard types];
	event		= [NSApp currentEvent];
	link		= ([event alternateKeyModifier] && [event commandKeyModifier]);

	if(outlineView == _sourceOutlineView) {
		if([types containsObject:WCFilePboardType]) {
			if(!item)
				return NSDragOperationNone;
			
			sources		= [NSKeyedUnarchiver unarchiveObjectWithData:[pasteboard dataForType:WCFilePboardType]];
			enumerator	= [sources reverseObjectEnumerator];
			
			if([item isKindOfClass:[NSNumber class]]) {
				if([item unsignedIntegerValue] != 0) {
					while((sourceFile = [enumerator nextObject])) {
						if(![sourceFile isFolder])
							return NSDragOperationNone;
					}
					
					return NSDragOperationCopy;
				}
			}
			else if([item isKindOfClass:[NSString class]] || [item isKindOfClass:[WCFile class]]) {
				if([item isKindOfClass:[NSString class]]) {
					destinationFile = [WCFile fileWithRootDirectoryForConnection:
						[[[WCPublicChat publicChat] chatControllerForConnectionIdentifier:item] connection]];
				} else {
					destinationFile = item;
				}
				
				if(![destinationFile connection] || ![[destinationFile connection] isConnected])
					return NSDragOperationNone;
				
				copy = NO;
				
				while((sourceFile = [enumerator nextObject])) {
					if([sourceFile connection] == [destinationFile connection])
						return NSDragOperationNone;
					
					if([sourceFile volume] != [destinationFile volume])
						copy = YES;
				
					if([[[sourceFile path] stringByDeletingLastPathComponent] isEqualToString:[destinationFile path]])
						return NSDragOperationNone;
				}
				
				if(link)
					return NSDragOperationLink;
				else if(copy)
					return NSDragOperationCopy;
				else
					return NSDragOperationMove;
			}

			return NSDragOperationNone;
		}
		else if([types containsObject:WCPlacePboardType]) {
			if([item isKindOfClass:[NSNumber class]] && [item unsignedIntegerValue] == 1 && index >= 0) {
				[_sourceOutlineView setDropRow:-1 dropOperation:(NSTableViewDropOperation)NSDragOperationMove];
				
				return NSDragOperationMove;
			}
			
			return NSDragOperationNone;
		}
		else if([types containsObject:NSFilenamesPboardType]) {
			return NSDragOperationCopy;
		}
	}
	else if(outlineView == _filesOutlineView) {
		destinationFile = item ? item : _currentDirectory;
		
		if(index >= 0) {
			destinationFile = _currentDirectory;
			
			[_filesOutlineView setDropItem:NULL dropChildIndex:NSOutlineViewDropOnItemIndex];
		}
		
		if(![destinationFile isFolder]) {
			destinationFile = [self _existingParentFileForFile:destinationFile];
			
			if(destinationFile == _currentDirectory)
				[_filesOutlineView setDropItem:NULL dropChildIndex:NSOutlineViewDropOnItemIndex];
			else
				[_filesOutlineView setDropItem:destinationFile dropChildIndex:NSOutlineViewDropOnItemIndex];
		}
		
		if([types containsObject:WCFilePboardType]) {
			sources		= [NSKeyedUnarchiver unarchiveObjectWithData:[pasteboard dataForType:WCFilePboardType]];
			enumerator	= [sources reverseObjectEnumerator];
			copy		= NO;
			
			[self _revalidateFiles:sources];
			
			while((sourceFile = [enumerator nextObject])) {
				if([sourceFile connection] != [destinationFile connection])
					return NSDragOperationNone;
				
				if([sourceFile volume] != [destinationFile volume])
					copy = YES;
				
				if([[[sourceFile path] stringByDeletingLastPathComponent] isEqualToString:[destinationFile path]])
					return NSDragOperationNone;
			}
			
			if(link)
				return NSDragOperationLink;
			else if(copy)
				return NSDragOperationCopy;
			else
				return NSDragOperationMove;
		}
		else if([types containsObject:NSFilenamesPboardType]) {
			return NSDragOperationCopy;
		}
	}
	
	return NSDragOperationNone;
}



- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)index {
	NSPasteboard		*pasteboard;
	NSEnumerator		*enumerator;
	NSEvent				*event;
	NSArray				*types, *sources;
	NSString			*destinationPath;
	WIP7Message			*message;
	WCFile				*sourceFile, *destinationFile, *parentFile;
	NSUInteger			oldIndex;
	BOOL				link;
	
	pasteboard	= [info draggingPasteboard];
	types		= [pasteboard types];
	event		= [NSApp currentEvent];
	link		= ([event alternateKeyModifier] && [event commandKeyModifier]);
	
	if(outlineView == _sourceOutlineView) {
		if([types containsObject:WCFilePboardType]) {
			sources		= [NSKeyedUnarchiver unarchiveObjectWithData:[pasteboard dataForType:WCFilePboardType]];
			enumerator	= [sources reverseObjectEnumerator];
			
			if([item isKindOfClass:[NSNumber class]]) {
				[self _revalidateFiles:sources];
				
				while((sourceFile = [enumerator nextObject])) {
					if([sourceFile isFolder])
						[_places insertObject:sourceFile atIndex:index];
				}
				
				[[WCSettings settings] setObject:[NSKeyedArchiver archivedDataWithRootObject:_places] forKey:WCPlaces];
			}
			else if([item isKindOfClass:[NSString class]] || [item isKindOfClass:[WCFile class]]) {
				if([item isKindOfClass:[NSString class]]) {
					destinationFile = [WCFile fileWithRootDirectoryForConnection:
						[[[WCPublicChat publicChat] chatControllerForConnectionIdentifier:item] connection]];
				} else {
					destinationFile = item;
				}

				destinationPath = [destinationFile path];
				
				[self _revalidateFiles:sources];
				
				if(!link) {
					[self _removeDirectoryForConnection:[destinationFile connection] path:destinationPath];
					[self performSelectorOnce:@selector(_reloadFilesAtDirectory:) withObject:destinationFile afterDelay:0.1];
				}
				
				while((sourceFile = [enumerator nextObject])) {
					parentFile = [self _existingParentFileForFile:sourceFile];
					
					[self _removeDirectoryForConnection:[parentFile connection] path:[parentFile path]];
					[self performSelectorOnce:@selector(_reloadFilesAtDirectory:) withObject:parentFile afterDelay:0.1];
					
					message = [WIP7Message messageWithName:link ? @"wired.file.link" : @"wired.file.move" spec:WCP7Spec];
					[message setString:[sourceFile path] forName:@"wired.file.path"];
					[message setString:[destinationPath stringByAppendingPathComponent:[sourceFile name]] forName:@"wired.file.new_path"];
					[[destinationFile connection] sendMessage:message fromObserver:self selector:@selector(wiredFileMoveReply:)];
				}
				
				[_filesOutlineView reloadData];
			}
			
			[_sourceOutlineView reloadData];
			
			return YES;
		}
		else if([types containsObject:WCPlacePboardType]) {
			sources		= [NSKeyedUnarchiver unarchiveObjectWithData:[pasteboard dataForType:WCPlacePboardType]];
			enumerator	= [sources reverseObjectEnumerator];
			
			while((sourceFile = [enumerator nextObject])) {
				oldIndex = [_places indexOfObject:sourceFile];
				
				[_places moveObjectAtIndex:oldIndex toIndex:index];
			}
			
			[_sourceOutlineView reloadData];
			
			[self _revalidateFiles:sources];
			
			return YES;
		}
		else if([types containsObject:NSFilenamesPboardType]) {
			return NO;
		}
	}
	else if(outlineView == _filesOutlineView) {
		destinationFile = item ? item : _currentDirectory;
		destinationPath = [destinationFile path];

		if([types containsObject:WCFilePboardType]) {
			sources			= [NSKeyedUnarchiver unarchiveObjectWithData:[pasteboard dataForType:WCFilePboardType]];
			enumerator		= [sources reverseObjectEnumerator];
			
			[self _revalidateFiles:sources];

			if(!link) {
				[self _removeDirectoryForConnection:[destinationFile connection] path:destinationPath];
				[self performSelectorOnce:@selector(_reloadFilesAtDirectory:) withObject:destinationFile afterDelay:0.1];
			}
			
			while((sourceFile = [enumerator nextObject])) {
				parentFile = [self _existingParentFileForFile:sourceFile];
				
				[self _removeDirectoryForConnection:[parentFile connection] path:[parentFile path]];
				[self performSelectorOnce:@selector(_reloadFilesAtDirectory:) withObject:parentFile afterDelay:0.1];
				
				message = [WIP7Message messageWithName:link ? @"wired.file.link" : @"wired.file.move" spec:WCP7Spec];
				[message setString:[sourceFile path] forName:@"wired.file.path"];
				[message setString:[destinationPath stringByAppendingPathComponent:[sourceFile name]] forName:@"wired.file.new_path"];
				[[destinationFile connection] sendMessage:message fromObserver:self selector:@selector(wiredFileMoveReply:)];
			}
				
			[_filesOutlineView reloadData];
			
			return YES;
		}
		else if([types containsObject:NSFilenamesPboardType]) {
			sources = [[pasteboard propertyListForType:NSFilenamesPboardType] sortedArrayUsingSelector:@selector(finderCompare:)];
			
			return [[WCTransfers transfers] uploadPaths:sources toFolder:destinationFile];
		}
	}
	
	return NO;
}


- (void)outlineView:(NSOutlineView *)outlineView removeItems:(NSArray *)items {
	NSEnumerator		*enumerator;
	id					item;
	NSUInteger			index;
	
	if(outlineView == _sourceOutlineView) {
		[self _revalidateFiles:items];
		
		enumerator = [items objectEnumerator];
		
		while((item = [enumerator nextObject])) {
			index = [_places indexOfObject:item];
			
			if(index != NSNotFound)
				[_places removeObjectAtIndex:index];
		}
		
		[[WCSettings settings] setObject:[NSKeyedArchiver archivedDataWithRootObject:_places] forKey:WCPlaces];

		[_sourceOutlineView reloadData];
	}
}



- (void)outlineViewShouldCopyInfo:(NSOutlineView *)outlineView {
	NSEnumerator		*enumerator;
	NSMutableString		*string;
	NSPasteboard		*pasteboard;
	WCFile				*file;
	
	string			= [NSMutableString string];
	enumerator		= [[self _selectedFiles] objectEnumerator];
	
	while((file = [enumerator nextObject])) {
		if([string length] > 0)
			[string appendString:@"\n"];
		
		[string appendString:[file name]];
	}
	
	pasteboard = [NSPasteboard generalPasteboard];
	[pasteboard declareTypes:[NSArray arrayWithObjects:NSStringPboardType, WCFilePboardType, NULL] owner:NULL];
	[pasteboard setString:string forType:NSStringPboardType];
}



- (NSArray *)outlineView:(NSOutlineView *)outlineView namesOfPromisedFilesDroppedAtDestination:(NSURL *)destination forDraggedItems:(NSArray *)items {
	NSEnumerator		*enumerator;
	NSMutableArray		*files, *names;
	WCFile				*file;
	
	files			= [NSMutableArray array];
	names			= [NSMutableArray array];
	enumerator		= [items objectEnumerator];

	while((file = [enumerator nextObject])) {
		if([file connection] && [[file connection] isConnected]) {
			[files addObject:file];
			[names addObject:[file name]];
		}
	}

	if([[WCTransfers transfers] downloadFiles:files toFolder:[destination path]])
		return names;
	
	return NULL;
}



#pragma mark -

- (NSUInteger)treeView:(WITreeView *)tree numberOfItemsForPath:(NSString *)path {
	NSMutableArray		*directory;
	
	directory = [self _directoryForConnection:[self _selectedConnection] path:path];
	
	return [directory count];
}



- (NSString *)treeView:(WITreeView *)tree nameForRow:(NSUInteger)row inPath:(NSString *)path {
	NSMutableArray		*directory;
	
	directory = [self _directoryForConnection:[self _selectedConnection] path:path];
	
	if(row >= [directory count])
		return @"";
	
	return [[directory objectAtIndex:row] name];
}



- (BOOL)treeView:(WITreeView *)tree isPathExpandable:(NSString *)path {
	WCFile			*file;
	
	file = [[self _filesForConnection:[self _selectedConnection]] objectForKey:path];
	
	return [file isFolder];
}



- (NSDictionary *)treeView:(WITreeView *)tree attributesForPath:(NSString *)path {
	WCFile			*file;
	
	file = [[self _filesForConnection:[self _selectedConnection]] objectForKey:path];

	return [NSDictionary dictionaryWithObjectsAndKeys:
		[file iconWithWidth:128.0 open:NO],						WIFileIcon,
		[NSNumber numberWithUnsignedLongLong:[file totalSize]],	WIFileSize,
		[file kind],											WIFileKind,
		[file creationDate],									WIFileCreationDate,
		[file modificationDate],								WIFileModificationDate,
		NULL];
}



- (void)treeView:(WITreeView *)tree changedPath:(NSString *)path {
	WCFile			*file;
	
	if([self _selectedStyle] == WCFilesStyleTree) {
		file = [[self _filesForConnection:[self _selectedConnection]] objectForKey:path];
		
		if(file) {
			if(![file isFolder]) {
				file = [self _existingFileForFile:[WCFile fileWithDirectory:[[file path] stringByDeletingLastPathComponent]
																 connection:[file connection]]];
			}
			
			[self _changeCurrentDirectory:file selectFiles:YES forceSelection:NO addToHistory:YES];
			[self _validate];
		}
	}
}



- (void)treeView:(WITreeView *)tree willDisplayCell:(id)cell forPath:(NSString *)path {
	WCFile			*file;
	
	file = [[self _filesForConnection:[self _selectedConnection]] objectForKey:path];
	
	[cell setImage:[file iconWithWidth:_iconWidth open:[[_currentDirectory path] hasPrefix:path]]];
}



- (NSColor *)treeView:(WITreeView *)treeView labelColorForPath:(NSString *)path {
	WCFile			*file;
	
	file = [[self _filesForConnection:[self _selectedConnection]] objectForKey:path];
	
	return [file labelColor];
}



- (BOOL)treeView:(WITreeView *)treeView writePaths:(NSArray *)paths toPasteboard:(NSPasteboard *)pasteboard {
	NSEnumerator			*enumerator;
	NSMutableDictionary		*files;
	NSMutableArray			*sources;
	NSString				*path;
	WCFile					*file;
	
	files		= [self _filesForConnection:[self _selectedConnection]];
	sources		= [NSMutableArray array];
	enumerator	= [paths objectEnumerator];
	
	while((path = [enumerator nextObject])) {
		file = [files objectForKey:path];
		
		if(!file || ![file connection] || ![[file connection] isConnected])
			return NO;
		
		[sources addObject:file];
	}
	
	[pasteboard declareTypes:[NSArray arrayWithObjects:WCFilePboardType, NSFilesPromisePboardType, NULL] owner:NULL];
	[pasteboard setData:[NSKeyedArchiver archivedDataWithRootObject:sources] forType:WCFilePboardType];
    [pasteboard setPropertyList:[NSArray arrayWithObject:NSFileTypeForHFSTypeCode('\0\0\0\0')] forType:NSFilesPromisePboardType];
	
	return YES;
}



- (NSDragOperation)treeView:(WITreeView *)treeView validateDrop:(id <NSDraggingInfo>)info proposedPath:(NSString *)path {
	NSPasteboard		*pasteboard;
	NSEnumerator		*enumerator;
	NSEvent				*event;
	NSArray				*types, *sources;
	NSString			*destinationPath;
	WCFile				*sourceFile, *destinationFile;
	BOOL				link, copy;
	
	pasteboard			= [info draggingPasteboard];
	types				= [pasteboard types];
	event				= [NSApp currentEvent];
	destinationPath		= path;
	link				= ([event alternateKeyModifier] && [event commandKeyModifier]);
	
	if([types containsObject:WCFilePboardType]) {
		destinationFile		= [[self _filesForConnection:[self _selectedConnection]] objectForKey:destinationPath];
		sources				= [NSKeyedUnarchiver unarchiveObjectWithData:[pasteboard dataForType:WCFilePboardType]];
		enumerator			= [sources reverseObjectEnumerator];
		
		if(!destinationFile)
			return NSDragOperationNone;
		
		[self _revalidateFiles:sources];

		copy = NO;
		
		while((sourceFile = [enumerator nextObject])) {
			if([sourceFile connection] != [destinationFile connection])
				return NSDragOperationNone;
			
			if([sourceFile volume] != [destinationFile volume])
				copy = YES;
			
			if([[[sourceFile path] stringByDeletingLastPathComponent] isEqualToString:[destinationFile path]])
				return NSDragOperationNone;
		}
		
		if(link)
			return NSDragOperationLink;
		else if(copy)
			return NSDragOperationCopy;
		else
			return NSDragOperationMove;
	}
	else if([types containsObject:NSFilenamesPboardType]) {
		return NSDragOperationCopy;
	}

	return NSDragOperationNone;
}



- (BOOL)treeView:(WITreeView *)treeView acceptDrop:(id <NSDraggingInfo>)info path:(NSString *)path {
	NSPasteboard		*pasteboard;
	NSEnumerator		*enumerator;
	NSEvent				*event;
	NSArray				*types, *sources;
	NSString			*destinationPath;
	WIP7Message			*message;
	WCFile				*sourceFile, *destinationFile, *parentFile;
	BOOL				link;
	
	pasteboard			= [info draggingPasteboard];
	types				= [pasteboard types];
	event				= [NSApp currentEvent];
	destinationPath		= path;
	destinationFile		= [[self _filesForConnection:[self _selectedConnection]] objectForKey:destinationPath];
	link				= ([event alternateKeyModifier] && [event commandKeyModifier]);

	if([types containsObject:WCFilePboardType]) {
		sources			= [NSKeyedUnarchiver unarchiveObjectWithData:[pasteboard dataForType:WCFilePboardType]];
		enumerator		= [sources reverseObjectEnumerator];
		
		if(!destinationFile)
			return NO;
		
		[self _revalidateFiles:sources];
		
		if(!link) {
			[self _removeDirectoryForConnection:[destinationFile connection] path:destinationPath];
			[self performSelectorOnce:@selector(_reloadFilesAtDirectory:) withObject:destinationFile afterDelay:0.1];
		}
		
		while((sourceFile = [enumerator nextObject])) {
			parentFile = [self _existingParentFileForFile:sourceFile];
			
			[self _removeDirectoryForConnection:[destinationFile connection] path:[parentFile path]];
			[self performSelectorOnce:@selector(_reloadFilesAtDirectory:) withObject:parentFile afterDelay:0.1];
			
			message = [WIP7Message messageWithName:link ? @"wired.file.link" : @"wired.file.move" spec:WCP7Spec];
			[message setString:[sourceFile path] forName:@"wired.file.path"];
			[message setString:[destinationPath stringByAppendingPathComponent:[sourceFile name]] forName:@"wired.file.new_path"];
			[[destinationFile connection] sendMessage:message fromObserver:self selector:@selector(wiredFileMoveReply:)];
		}
		
		[_filesTreeView reloadData];
		
		return YES;
	}
	else if([types containsObject:NSFilenamesPboardType]) {
		sources = [[pasteboard propertyListForType:NSFilenamesPboardType] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
		
		return [[WCTransfers transfers] uploadPaths:sources toFolder:destinationFile];
	}
	
	return NO;
}



- (void)treeViewShouldCopyInfo:(WITreeView *)treeView {
	[self performSelector:@selector(outlineViewShouldCopyInfo:) withObject:NULL];
}



- (NSArray *)treeView:(WITreeView *)treeView namesOfPromisedFilesDroppedAtDestination:(NSURL *)destination forDraggedPaths:(NSArray *)paths {
	NSEnumerator			*enumerator;
	NSMutableDictionary		*allFiles;
	NSMutableArray			*files, *names;
	NSString				*path;
	WCFile					*file;
	
	allFiles		= [self _filesForConnection:[self _selectedConnection]];
	files			= [NSMutableArray array];
	names			= [NSMutableArray array];
	enumerator		= [paths objectEnumerator];
	
	while((path = [enumerator nextObject])) {
		file = [allFiles objectForKey:path];
		
		if(file && [file connection] && [[file connection] isConnected]) {
			[files addObject:file];
			[names addObject:[file name]];
		}
	}

	if([[WCTransfers transfers] downloadFiles:files toFolder:[destination path]])
		return names;
	
	return NULL;
}



- (BOOL)treeView:(WITreeView *)tree validateMoreInfoButtonForPath:(NSString *)path {
	return [self _validateGetInfo];
}



- (void)treeView:(WITreeView *)tree showMoreInfoForPath:(NSString *)path {
	[self getInfo:self];
}



#pragma mark -

- (BOOL)acceptsPreviewPanelControl:(id /*QLPreviewPanel **/)panel {
    return YES;
}



- (void)beginPreviewPanelControl:(id /*QLPreviewPanel **/)panel {
    [panel setDelegate:self];
    [panel setDataSource:self];
}



- (void)endPreviewPanelControl:(id /*QLPreviewPanel **/) panel {
}



- (NSInteger)numberOfPreviewItemsInPreviewPanel:(id /*QLPreviewPanel **/)panel {
	return [_quickLookFiles count];
}



- (id /*id <QLPreviewItem>*/)previewPanel:(id /*QLPreviewPanel **/)panel previewItemAtIndex:(NSInteger)index {
	return [_quickLookFiles objectAtIndex:index];
}



- (NSRect)previewPanel:(id /*QLPreviewPanel **/)panel sourceFrameOnScreenForPreviewItem:(id /*id <QLPreviewItem>*/)item {
	NSMutableArray	*directory;
	NSString		*path;
	NSRect			frame;
	NSUInteger		index;
	NSInteger		row;
	
	if([self _selectedStyle] == WCFilesStyleList) {
		row = [_filesOutlineView rowForItem:item];
		
		if(row >= 0) {
			frame				= [_filesOutlineView convertRect:[_filesOutlineView frameOfCellAtColumn:0 row:row] toView:NULL];
			frame.origin		= [[self window] convertPointToScreen:frame.origin];

			return NSMakeRect(frame.origin.x, frame.origin.y, frame.size.height, frame.size.height);
		}
	} else {
		path		= [[item path] stringByDeletingLastPathComponent];
		directory	= [self _directoryForConnection:[(WCFile *) item connection] path:path];
		index		= [directory indexOfObject:item];
			
		if(index != NSNotFound) {
			frame			= [_filesTreeView frameOfRow:index inPath:path];
			frame.origin	= [[self window] convertPointToScreen:frame.origin];

			return NSMakeRect(frame.origin.x, frame.origin.y, frame.size.height, frame.size.height);
		}
	}

	return NSZeroRect;
}

@end
