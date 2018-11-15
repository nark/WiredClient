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

#import "WCCache.h"
#import "WCConnect.h"
#import "WCConsole.h"
#import "WCErrorQueue.h"
#import "WCFile.h"
#import "WCFileInfo.h"
#import "WCFiles.h"
#import "WCPreferences.h"
#import "WCPublicChat.h"
#import "WCServer.h"
#import "WCServerConnection.h"
#import "WCServerInfo.h"
#import "WCStats.h"
#import "WCTransfer.h"
#import "WCTransferCell.h"
#import "WCTransferConnection.h"
#import "WCTransfers.h"

#define WCTransfersFileExtension				@"WiredTransfer"
#define WCTransfersFileExtendedAttributeName	@"fr.read-write.WiredTransfer"
#define WCTransferPboardType					@"WCTransferPboardType"

NSString * const WCTransfersQueueUpdatedNotification    = @"WCTransfersQueueUpdatedNotification";

static inline NSTimeInterval _WCTransfersTimeInterval(void) {
	struct timeval		tv;

	gettimeofday(&tv, NULL);

	return tv.tv_sec + ((double) tv.tv_usec / 1000000.0);
}


@interface WCTransfers(Private)

- (void)_validate;
- (BOOL)_validateStart;
- (BOOL)_validatePause;
- (BOOL)_validateStop;
- (BOOL)_validateRemove;
- (BOOL)_validateClear;
- (BOOL)_validateConnect;
- (BOOL)_validateQuickLook;
- (BOOL)_validateRevealInFinder;
- (BOOL)_validateRevealInFiles;

- (void)_themeDidChange;
- (void)_reload;

- (void)_presentError:(WCError *)error forConnection:(WCServerConnection *)connection transfer:(WCTransfer *)transfer;

- (NSArray *)_selectedTransfers;
- (WCTransfer *)_unfinishedTransferWithPath:(NSString *)path connection:(WCServerConnection *)connection;
- (WCTransfer *)_transferWithState:(WCTransferState)state;
- (WCTransfer *)_transferWithState:(WCTransferState)state class:(Class)class;
- (WCTransfer *)_transferWithTransaction:(NSUInteger)transaction;
- (NSUInteger)_numberOfWorkingTransfersOfClass:(Class)class connection:(WCServerConnection *)connection;

- (NSString *)_statusForTransfer:(WCTransfer *)transfer;

- (void)_requestNextTransferForConnection:(WCServerConnection *)connection;
- (void)_requestTransfer:(WCTransfer *)transfer;
- (void)_startTransfer:(WCTransfer *)transfer first:(BOOL)first;
- (void)_queueTransfer:(WCTransfer *)transfer;
- (void)_createRemainingDirectoriesForTransfer:(WCTransfer *)transfer;
- (void)_invalidateTransfersForConnection:(WCServerConnection *)connection;
- (void)_saveTransfers;
- (void)_finishTransfer:(WCTransfer *)transfer;
- (void)_removeTransfer:(WCTransfer *)transfer;

- (BOOL)_downloadFiles:(NSArray *)file toFolder:(NSString *)destination;
- (BOOL)_downloadFile:(WCFile *)file toFolder:(NSString *)destination;
- (BOOL)_uploadPaths:(NSArray *)paths toFolder:(WCFile *)destination;
- (BOOL)_uploadPath:(NSString *)path toFolder:(WCFile *)destination;

- (WCTransferConnection *)_transferConnectionForTransfer:(WCTransfer *)transfer;
- (BOOL)_sendDownloadFileMessageOnConnection:(WCTransferConnection *)connection forFile:(WCFile *)file error:(WCError **)error;
- (BOOL)_sendUploadFileMessageOnConnection:(WCTransferConnection *)connection forFile:(WCFile *)file error:(WCError **)error;
- (BOOL)_sendUploadMessageOnConnection:(WCTransferConnection *)connection forFile:(WCFile *)file dataLength:(WIFileOffset)dataLength rsrcLength:(WIFileOffset)rsrcLength error:(WCError **)error;
- (BOOL)_createRemainingDirectoriesOnConnection:(WCTransferConnection *)connection forTransfer:(WCTransfer *)transfer error:(WCError **)error;
- (BOOL)_connectConnection:(WCTransferConnection *)connection forTransfer:(WCTransfer *)transfer error:(WCError **)error;
- (WIP7Message *)_runConnection:(WCTransferConnection *)connection forTransfer:(WCTransfer *)transfer untilReceivingMessageName:(NSString *)messageName error:(WCError **)error;
- (void)_runDownload:(WCTransfer *)transfer;
- (void)_runUpload:(WCTransfer *)transfer;

- (void)_cleanTransfers;

@end


@implementation WCTransfers(Private)

- (void)_validate {
	[_startButton setEnabled:[self _validateStart]];
	[_pauseButton setEnabled:[self _validatePause]];
	[_stopButton setEnabled:[self _validateStop]];
	[_removeButton setEnabled:[self _validateRemove]];
	[_clearButton setEnabled:[self _validateClear]];
	
	[_connectButton setEnabled:[self _validateConnect]];
	[_quickLookButton setEnabled:[self _validateQuickLook]];
	[_revealInFinderButton setEnabled:[self _validateRevealInFinder]];
	[_revealInFilesButton setEnabled:[self _validateRevealInFiles]];

	[[[self window] toolbar] validateVisibleItems];
}



- (BOOL)_validateStart {
	NSEnumerator	*enumerator;
	NSArray			*transfers;
	WCTransfer		*transfer;
	
	transfers = [self _selectedTransfers];
	
	if([transfers count] == 0)
		return NO;
	
	enumerator = [transfers objectEnumerator];
	
	while((transfer = [enumerator nextObject])) {
		if(![transfer connection] || ![[transfer connection] isConnected])
			return NO;
	
		if([transfer state] != WCTransferLocallyQueued && [transfer state] != WCTransferPaused &&
		   [transfer state] != WCTransferStopped && [transfer state] != WCTransferDisconnected) {
			return NO;
		}
	}
	
	return YES;
}



- (BOOL)_validatePause {
	NSEnumerator	*enumerator;
	NSArray			*transfers;
	WCTransfer		*transfer;
	
	transfers = [self _selectedTransfers];
	
	if([transfers count] == 0)
		return NO;
	
	enumerator = [transfers objectEnumerator];
	
	while((transfer = [enumerator nextObject])) {
		if(![transfer connection] || ![[transfer connection] isConnected])
			return NO;
	
		if([transfer state] != WCTransferRunning)
			return NO;
	}
	
	return YES;
}



- (BOOL)_validateStop {
	return [self _validatePause];
}



- (BOOL)_validateRemove {
	return ([[self _selectedTransfers] count] > 0);
}



- (BOOL)_validateClear {
	return ([self _transferWithState:WCTransferFinished] != NULL);
}



- (BOOL)_validateConnect {
	NSEnumerator	*enumerator;
	NSArray			*transfers;
	WCTransfer		*transfer;
	
	transfers = [self _selectedTransfers];
	
	if([transfers count] == 0)
		return NO;
	
	enumerator = [transfers objectEnumerator];
	
	while((transfer = [enumerator nextObject])) {
		if([transfer connection])
			return NO;
	}
	
	return YES;
}



- (BOOL)_validateQuickLook {
	return ([[self _selectedTransfers] count] > 0 && _quickLookPanelClass != NULL);
}



- (BOOL)_validateRevealInFinder {
	return ([[self _selectedTransfers] count] > 0);
}



- (BOOL)_validateRevealInFiles {
	NSEnumerator	*enumerator;
	NSArray			*transfers;
	WCTransfer		*transfer;
	
	transfers = [self _selectedTransfers];
	
	if([transfers count] == 0)
		return NO;
	
	enumerator = [transfers objectEnumerator];
	
	while((transfer = [enumerator nextObject])) {
		if(![transfer connection] || ![[transfer connection] isConnected])
			return NO;
	}
	
	return YES;
}



- (void)_themeDidChange {
	NSDictionary		*theme;
	
	theme = [[WCSettings settings] themeWithIdentifier:[[WCSettings settings] objectForKey:WCTheme]];
	
	if([theme boolForKey:WCThemesTransferListShowProgressBar]) {
		[_transfersTableView setRowHeight:46.0];
		[[_infoTableColumn dataCell] setDrawsProgressIndicator:YES];
	} else {
		[_transfersTableView setRowHeight:34.0];
		[[_infoTableColumn dataCell] setDrawsProgressIndicator:NO];
	}
	
	[_transfersTableView setUsesAlternatingRowBackgroundColors:[theme boolForKey:WCThemesTransferListAlternateRows]];
}



- (void)_reload {
	[_transfersTableView reloadData];
	[_transfersTableView setNeedsDisplay:YES];
}



#pragma mark -

- (void)_presentError:(WCError *)error forConnection:(WCServerConnection *)connection transfer:(WCTransfer *)transfer {
	if(![[self window] isVisible])
		[self showWindow:self];
	
	[connection triggerEvent:WCEventsError info1:error];
	
	[_errorQueue showError:error withIdentifier:[transfer identifier]];
}



#pragma mark -

- (NSArray *)_selectedTransfers {
	NSMutableArray		*array;
	NSIndexSet			*indexes;
	NSUInteger			index;
	
	array	= [NSMutableArray array];
	indexes	= [_transfersTableView selectedRowIndexes];
	index	= [indexes firstIndex];
	
	while(index != NSNotFound) {
		[array addObject:[_transfers objectAtIndex:index]];
		
		index = [indexes indexGreaterThanIndex:index];
	}
	
	return array;
}



- (WCTransfer *)_unfinishedTransferWithPath:(NSString *)path connection:(WCServerConnection *)connection {
	NSEnumerator		*enumerator;
	WCTransfer			*transfer;

	enumerator = [_transfers objectEnumerator];

	while((transfer = [enumerator nextObject])) {
		if([transfer state] != WCTransferFinished) {
			if([transfer isFolder]) {
				if([[transfer remotePath] isEqualToString:path] ||
				   [path hasPrefix:[[transfer remotePath] stringByAppendingString:@"/"]])
					return transfer;
			} else {
				if([transfer containsUntransferredFile:[WCFile fileWithFile:path connection:connection]])
					return transfer;
			}
		}
	}

	return NULL;
}



- (WCTransfer *)_transferWithState:(WCTransferState)state {
	NSEnumerator		*enumerator;
	WCTransfer			*transfer;

	enumerator = [_transfers objectEnumerator];

	while((transfer = [enumerator nextObject])) {
		if([transfer state] == state)
			return transfer;
	}

	return NULL;
}



- (WCTransfer *)_transferWithState:(WCTransferState)state class:(Class)class {
	NSEnumerator		*enumerator;
	WCTransfer			*transfer;

	enumerator = [_transfers objectEnumerator];

	while((transfer = [enumerator nextObject])) {
		if([transfer state] == state && [transfer class] == class)
			return transfer;
	}

	return NULL;
}



- (WCTransfer *)_transferWithTransaction:(NSUInteger)transaction {
	WCTransfer			*transfer;
	NSUInteger			i, count;

	count = [_transfers count];
	
	for(i = 0; i < count; i++) {
		transfer = [_transfers objectAtIndex:i];
		
		if([transfer transaction] == transaction)
			return transfer;
	}
	
	return NULL;
}



- (NSUInteger)_numberOfWorkingTransfersOfClass:(Class)class connection:(WCServerConnection *)connection {
	NSEnumerator		*enumerator;
	WCTransfer			*transfer;
	NSUInteger			count = 0;

	enumerator = [_transfers objectEnumerator];

	while((transfer = [enumerator nextObject])) {
		if([transfer connection] == connection && [transfer class] == class && [transfer isWorking])
			count++;
	}

	return count;
}



#pragma mark -

- (BOOL)_downloadFiles:(NSArray *)files toFolder:(NSString *)destination {
	NSEnumerator		*enumerator;
	NSMutableArray		*existingFiles;
	NSAlert				*alert;
	NSString			*path, *title, *description;
	WCFile				*file;
	WCError				*error;
	BOOL				isDirectory;
	
	if(![[NSFileManager defaultManager] directoryExistsAtPath:destination]) {
		error = [WCError errorWithDomain:WCWiredClientErrorDomain code:WCWiredClientTransferDownloadDirectoryNotFound argument:destination];
		file = [files objectAtIndex:0];
		
		[self _presentError:error forConnection:[file connection] transfer:NULL];
		
		return NO;
	}
	
	existingFiles		= [NSMutableArray array];
	enumerator			= [files objectEnumerator];
	
	while((file = [enumerator nextObject])) {
		path = [destination stringByAppendingPathComponent:[file name]];
		
		if([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory]) {
			if(!(isDirectory && [file isFolder])) {
				[existingFiles addObject:path];
				
				continue;
			}
		}
	}
	
	if([existingFiles count] > 0) {
		if([existingFiles count] == 1) {
			title = [NSSWF:NSLS(@"Overwrite \u201c%@\u201d?", @"Transfers overwrite alert title (name)"),
				[[existingFiles objectAtIndex:0] lastPathComponent]];
			description = NSLS(@"The file already exists on disk. Overwrite to delete it.",
				@"Transfers overwrite alert description");
		} else {
			title = [NSSWF:NSLS(@"Overwrite %u files?", @"Transfers overwrite alert title (count)"),
				[existingFiles count]];
			description = NSLS(@"Some files already exist on disk. Overwrite to delete them.",
				@"Transfers overwrite alert description");
		}
		
		alert = [[[NSAlert alloc] init] autorelease];
		[alert setMessageText:title];
		[alert setInformativeText:description];
		[alert addButtonWithTitle:NSLS(@"Cancel", @"Transfers overwrite alert button")];
		[alert addButtonWithTitle:NSLS(@"Overwrite", @"Transfers overwrite alert button")];
		
		if([alert runModal] == NSAlertFirstButtonReturn)
			return NO;
		
		enumerator = [existingFiles objectEnumerator];
		
		while((path = [enumerator nextObject]))
            [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
	}
	
	enumerator = [files objectEnumerator];
	
	while((file = [enumerator nextObject])) {
		if(![self _downloadFile:file toFolder:destination])
			return NO;
	}
	
	return YES;
}



- (BOOL)_downloadFile:(WCFile *)file toFolder:(NSString *)destination {
	NSString				*path;
	WCDownloadTransfer		*transfer;
	WCError					*error;
	NSUInteger				count;

	if([self _unfinishedTransferWithPath:[file path] connection:[file connection]]) {
		error = [WCError errorWithDomain:WCWiredClientErrorDomain code:WCWiredClientTransferExists argument:[file path]];
		
		[self _presentError:error forConnection:[file connection] transfer:NULL];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:WCTransfersQueueUpdatedNotification
                                                            object:[transfer connection]
                                                          userInfo:nil];
		
		return NO;
	}
	
	path = [destination stringByAppendingPathComponent:[file name]];
	
	transfer = [WCDownloadTransfer transferWithConnection:[file connection]];
	[transfer setDestinationPath:destination];
	[transfer setRemotePath:[file path]];
	[transfer setName:[file name]];
	
	if([file type] == WCFileFile) {
		if(![path hasSuffix:WCTransfersFileExtension])
			path = [path stringByAppendingPathExtension:WCTransfersFileExtension];

		[file setDataTransferred:[[NSFileManager defaultManager] fileSizeAtPath:path]];
		
		if([[file connection] supportsResourceForks])
			[file setRsrcTransferred:[[NSFileManager defaultManager] resourceForkSizeAtPath:path]];
		
		[file setTransferLocalPath:path];
		
		[transfer setSize:[file dataSize] + [file rsrcSize]];
		[transfer setFile:file];
		[transfer addUntransferredFile:file];
		[transfer setDataTransferred:[[transfer firstUntransferredFile] dataTransferred]];
		[transfer setRsrcTransferred:[[transfer firstUntransferredFile] rsrcTransferred]];
		[transfer setLocalPath:path];
	} else {
		[file setTransferLocalPath:path];
		
		[transfer addUncreatedDirectory:file];
		[transfer setFolder:YES];
		[transfer setLocalPath:path];
	}
	
	[_transfers addObject:transfer];
	
	[self _saveTransfers];

	count = [self _numberOfWorkingTransfersOfClass:[transfer class] connection:[file connection]];

	if(count == 1)
		[self showWindow:self];
	
	if(count > 1 && [[WCSettings settings] boolForKey:WCQueueTransfers])
		[transfer setState:WCTransferLocallyQueued];
	else
		[self _requestTransfer:transfer];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:WCTransfersQueueUpdatedNotification
                                                        object:[transfer connection]
                                                      userInfo:nil];
	
	[_transfersTableView reloadData];
	
	return YES;
}



- (BOOL)_uploadPaths:(NSArray *)paths toFolder:(WCFile *)destination {
	NSDirectoryEnumerator	*directoryEnumerator;
	NSEnumerator			*enumerator;
	NSAlert					*alert;
	NSString				*path, *eachPath, *fullPath, *resourceForkPath, *title, *description;
	NSUInteger				resourceForks;
	BOOL					isDirectory;
	
	if([[WCSettings settings] boolForKey:WCCheckForResourceForks] && ![[destination connection] supportsResourceForks]) {
		resourceForks		= 0;
		resourceForkPath	= NULL;
		enumerator			= [paths objectEnumerator];
		
		while((path = [enumerator nextObject])) {
			isDirectory				= [[NSFileManager defaultManager] directoryExistsAtPath:path];
			directoryEnumerator		= [[NSFileManager defaultManager] enumeratorWithFileAtPath:path];

			while((eachPath = [directoryEnumerator nextObject])) {
				if([[eachPath lastPathComponent] hasPrefix:@"."]) {
					[directoryEnumerator skipDescendents];
					
					continue;
				}
				
				if(isDirectory)
					fullPath = [path stringByAppendingPathComponent:eachPath];
				else
					fullPath = path;
				
				if([[NSFileManager defaultManager] resourceForkSizeAtPath:fullPath] > 0) {
					resourceForks++;
					resourceForkPath = fullPath;
				}
			}
		}
	
		if(resourceForks > 0) {
			if(resourceForks == 1) {
				title = [NSSWF:NSLS(@"Upload \u201c%@\u201d without resource fork?", @"Transfers resource fork alert title (name)"),
					[resourceForkPath lastPathComponent]];
				description = NSLS(@"The file has a resource fork, which is not handled by this server. Only the data part will be uploaded, possibly resulting in a corrupted file. You may need to use an archiver to ensure the file are uploaded correctly.", @"Transfers resource fork alert description");
			} else {
				title = NSLS(@"Upload files without resource forks?", @"Transfers resource fork alert title");
				description = NSLS(@"Some files have resource forks, which are not handled by this server. Only the data parts will be uploaded, possibly resulting in corrupted files. You may need to use an archiver to ensure the files are uploaded correctly.", @"Transfers resource fork alert description");
			}
			
			alert = [[[NSAlert alloc] init] autorelease];
			[alert setMessageText:title];
			[alert setInformativeText:description];
			[alert addButtonWithTitle:NSLS(@"Cancel", @"Transfers resource fork alert button")];
			[alert addButtonWithTitle:NSLS(@"Upload", @"Transfers resource fork alert button")];
			
			if([alert runModal] == NSAlertFirstButtonReturn)
				return NO;
		}
	}
	
	enumerator = [paths objectEnumerator];
	
	while((path = [enumerator nextObject])) {
		if(![self _uploadPath:path toFolder:destination])
			return NO;
	}
	
	return YES;
}



- (BOOL)_uploadPath:(NSString *)path toFolder:(WCFile *)destination {
	NSDirectoryEnumerator	*enumerator;
	NSString				*eachPath, *remotePath, *localPath, *serverPath;
	WCTransfer				*transfer;
	WCFile					*file;
	WCError					*error;
	NSUInteger				count;
	BOOL					isDirectory;
	
	remotePath = [[destination path] stringByAppendingPathComponent:[path lastPathComponent]];

	if([self _unfinishedTransferWithPath:remotePath connection:[destination connection]]) {
		error = [WCError errorWithDomain:WCWiredClientErrorDomain code:WCWiredClientTransferExists argument:remotePath];
		[self _presentError:error forConnection:[destination connection] transfer:NULL];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:WCTransfersQueueUpdatedNotification
                                                            object:[transfer connection]
                                                          userInfo:nil];
		
		return NO;
	}

	transfer = [WCUploadTransfer transferWithConnection:[destination connection]];
	[transfer setDestinationPath:[destination path]];
	[transfer setLocalPath:path];
	[transfer setName:[path lastPathComponent]];
	[transfer setRemotePath:remotePath];
	
	if([[NSFileManager defaultManager] directoryExistsAtPath:path]) {
		[transfer setFolder:YES];
		[transfer setState:WCTransferListing];
	}
	
	enumerator = [[NSFileManager defaultManager] enumeratorWithFileAtPath:path];

	while((eachPath = [enumerator nextObject])) {
		if([[eachPath lastPathComponent] hasPrefix:@"."]) {
			if([[[enumerator fileAttributes] fileType] isEqualToString:NSFileTypeDirectory])
				[enumerator skipDescendents];
			
			continue;
		}

		if([transfer isFolder]) {
			localPath	= [[transfer localPath] stringByAppendingPathComponent:eachPath];
			serverPath	= [remotePath stringByAppendingPathComponent:eachPath];
		} else {
			localPath	= path;
			serverPath	= remotePath;
		}

		if([[NSFileManager defaultManager] fileExistsAtPath:localPath isDirectory:&isDirectory]) {
			if(isDirectory) {
				[transfer addUncreatedDirectory:[WCFile fileWithDirectory:serverPath connection:[destination connection]]];
			} else {
				file = [WCFile fileWithFile:serverPath connection:[destination connection]];
				[file setUploadDataSize:[[NSFileManager defaultManager] fileSizeAtPath:localPath]];
				
				if([[destination connection] supportsResourceForks])
					[file setUploadRsrcSize:[[NSFileManager defaultManager] resourceForkSizeAtPath:localPath]];
				
				[file setTransferLocalPath:localPath];
				
				[transfer setSize:[transfer size] + [file uploadDataSize]];
				
				if([[destination connection] supportsResourceForks])
					[transfer setSize:[transfer size] + [file uploadRsrcSize]];
				
				[transfer addUntransferredFile:file];
				
				if(![transfer isFolder])
					[transfer setFile:file];
			}
		}
	}
	
	[_transfers addObject:transfer];
	
	[self _saveTransfers];

	count = [self _numberOfWorkingTransfersOfClass:[transfer class] connection:[destination connection]];
	
	if(count == 1)
		[self showWindow:self];
	
	if(count > 1 && [[WCSettings settings] boolForKey:WCQueueTransfers])
		[transfer setState:WCTransferLocallyQueued];
	else
		[self _requestTransfer:transfer];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:WCTransfersQueueUpdatedNotification
                                                        object:[transfer connection]
                                                      userInfo:nil];
	
	[_transfersTableView reloadData];
	
	return YES;
}



#pragma mark -

- (NSString *)_statusForTransfer:(WCTransfer *)transfer {
	NSString			*format;
	NSTimeInterval		interval;
	NSUInteger			speedLimit;
	WIFileOffset		size, transferred, remaining;
	WCTransferState		state;
	double				speed;
	
	state = [transfer state];
	
	if(state == WCTransferWaiting && [transfer numberOfTransferredFiles] > 1)
		state = WCTransferRunning;
	
	switch(state) {
		case WCTransferLocallyQueued:
			return NSLS(@"Queued", @"Transfer locally queued");
			break;
			
		case WCTransferWaiting:
			return NSLS(@"Waiting", @"Transfer waiting");
			break;
			
		case WCTransferQueued:
			return [NSSWF:NSLS(@"Queued at position %lu", @"Transfer queued (position)"),
				[transfer queuePosition]];
			break;
		
		case WCTransferListing:
			return [NSSWF:NSLS(@"Listing directory... %lu %@", @"Transfer listing (files, 'file(s)'"),
				[transfer numberOfUntransferredFiles] + [transfer numberOfTransferredFiles],
				[transfer numberOfUntransferredFiles] + [transfer numberOfTransferredFiles] == 1
					? NSLS(@"file", @"File singular")
					: NSLS(@"files", @"File plural")];
			break;
			
		case WCTransferCreatingDirectories:
			return [NSSWF:NSLS(@"Creating directories... %lu", @"Transfer directories (directories"),
				[[transfer createdDirectories] count]];
			break;
			
		case WCTransferRunning:
			size			= [transfer size];
			transferred		= [transfer dataTransferred] + [transfer rsrcTransferred];
			remaining		= (transferred < size) ? size - transferred : 0;
			speed			= [transfer speed];
			speedLimit		= [transfer speedLimit];
			interval		= (speed > 0) ? (double) remaining / (double) speed : 0;
			
			if([transfer isFolder] && [transfer numberOfUntransferredFiles] + [transfer numberOfTransferredFiles] > 1) {
				if(speedLimit > 0) {
					return [NSSWF:NSLS(@"%lu of %lu files, %@ of %@, %@/s (%@/s), %@",
									   @"Transfer status (files, transferred, size, speed, speed limit, time)"),
						[transfer numberOfTransferredFiles],
						[transfer numberOfUntransferredFiles] + [transfer numberOfTransferredFiles],
						[_sizeFormatter stringFromSize:transferred],
						[_sizeFormatter stringFromSize:[transfer size]],
						[_sizeFormatter stringFromSize:speed],
						[_sizeFormatter stringFromSize:speedLimit],
						[_timeIntervalFormatter stringFromTimeInterval:interval]];
				} else {
					return [NSSWF:NSLS(@"%lu of %lu files, %@ of %@, %@/s, %@",
									   @"Transfer status (files, transferred, size, speed, time)"),
						[transfer numberOfTransferredFiles],
						[transfer numberOfUntransferredFiles] + [transfer numberOfTransferredFiles],
						[_sizeFormatter stringFromSize:transferred],
						[_sizeFormatter stringFromSize:[transfer size]],
						[_sizeFormatter stringFromSize:speed],
						[_timeIntervalFormatter stringFromTimeInterval:interval]];
				}
			} else {
				if(speedLimit > 0) {
					return [NSSWF:NSLS(@"%@ of %@, %@/s (%@/s limit), %@",
									   @"Transfer status (transferred, size, speed, speed limit, time)"),
						[_sizeFormatter stringFromSize:transferred],
						[_sizeFormatter stringFromSize:size],
						[_sizeFormatter stringFromSize:speed],
						[_sizeFormatter stringFromSize:speedLimit],
						[_timeIntervalFormatter stringFromTimeInterval:interval]];
				} else {
					return [NSSWF:NSLS(@"%@ of %@, %@/s, %@",
									   @"Transfer status (transferred, size, speed, time)"),
						[_sizeFormatter stringFromSize:transferred],
						[_sizeFormatter stringFromSize:size],
						[_sizeFormatter stringFromSize:speed],
						[_timeIntervalFormatter stringFromTimeInterval:interval]];
				}
			}
			break;
			
		case WCTransferPausing:
			return NSLS(@"Pausing\u2026", @"Transfer pausing");
			break;
			
		case WCTransferStopping:
			return NSLS(@"Stopping\u2026", @"Transfer stopping");
			break;
			
		case WCTransferDisconnecting:
			return NSLS(@"Disconnecting\u2026", @"Transfer disconnecting");
			break;

		case WCTransferRemoving:
			return NSLS(@"Removing\u2026", @"Transfer removing");
			break;

		case WCTransferPaused:
		case WCTransferStopped:
		case WCTransferDisconnected:
			transferred = [transfer dataTransferred] + [transfer rsrcTransferred];
			
			if([transfer isFolder] && [transfer numberOfUntransferredFiles] + [transfer numberOfTransferredFiles] > 1) {
				if([transfer state] == WCTransferPaused)
					format = NSLS(@"Paused at %lu of %lu files, %@ of %@", @"Transfer paused (files, transferred, size)");
				else if([transfer state] == WCTransferStopped)
					format = NSLS(@"Stopped at %lu of %lu files, %@ of %@", @"Transfer stopped (files, transferred, size)");
				else
					format = NSLS(@"Disconnected at %lu of %lu files, %@ of %@", @"Transfer disconnected (files, transferred, size)");

				return [NSSWF:format,
					[transfer numberOfTransferredFiles],
					[transfer numberOfUntransferredFiles] + [transfer numberOfTransferredFiles],
					[_sizeFormatter stringFromSize:transferred],
					[_sizeFormatter stringFromSize:[transfer size]]];
			} else {
				if([transfer state] == WCTransferPaused)
					format = NSLS(@"Paused at %@ of %@", @"Transfer stopped (transferred, size)");
				else if([transfer state] == WCTransferStopped)
					format = NSLS(@"Stopped at %@ of %@", @"Transfer stopped (transferred, size)");
				else
					format = NSLS(@"Disconnected at %@ of %@", @"Transfer disconnected (transferred, size)");

				return [NSSWF:format,
					[_sizeFormatter stringFromSize:transferred],
					[_sizeFormatter stringFromSize:[transfer size]]];
			}
			break;
			
		case WCTransferFinished:
			transferred		= [transfer dataTransferred] + [transfer rsrcTransferred];
			interval		= [transfer accumulatedTime];
			speed			= (interval > 0.0) ? [transfer actualTransferred] / interval : 0.0;
			
			if([transfer isFolder] && [transfer numberOfUntransferredFiles] + [transfer numberOfTransferredFiles] > 1) {
				return [NSSWF:NSLS(@"Finished %lu files, average %@/s, average %@, took %@",
								   @"Transfer finished (files, transferred, speed, time)"),
					[transfer numberOfTransferredFiles],
					[_sizeFormatter stringFromSize:transferred],
					[_sizeFormatter stringFromSize:speed],
					[_timeIntervalFormatter stringFromTimeInterval:interval]];
			} else {
				return [NSSWF:NSLS(@"Finished %@, average %@/s, took %@",
								   @"Transfer finished (transferred, speed, time)"),
					[_sizeFormatter stringFromSize:transferred],
					[_sizeFormatter stringFromSize:speed],
					[_timeIntervalFormatter stringFromTimeInterval:interval]];
			}
			break;
	}
	
	return @"";
}



#pragma mark -

- (void)_requestNextTransferForConnection:(WCServerConnection *)connection {
	WCTransfer		*transfer = NULL;
	NSUInteger		downloads, uploads;
	
	if(![[WCSettings settings] boolForKey:WCQueueTransfers]) {
		transfer	= [self _transferWithState:WCTransferLocallyQueued];
	} else {
		downloads	= [self _numberOfWorkingTransfersOfClass:[WCDownloadTransfer class] connection:connection];
		uploads		= [self _numberOfWorkingTransfersOfClass:[WCUploadTransfer class] connection:connection];
		
		if(downloads == 0 && uploads == 0)
			transfer = [self _transferWithState:WCTransferLocallyQueued];
		else if(downloads == 0)
			transfer = [self _transferWithState:WCTransferLocallyQueued class:[WCDownloadTransfer class]];
		else if(uploads == 0)
			transfer = [self _transferWithState:WCTransferLocallyQueued class:[WCUploadTransfer class]];
		
	}

	if(transfer)
		[self _requestTransfer:transfer];
}



- (void)_requestTransfer:(WCTransfer *)transfer {
	NSString		*path;
	WIP7Message		*message;
	NSUInteger		transaction;

	[_errorQueue dismissErrorWithIdentifier:[transfer identifier]];
	
	if([transfer isFolder]) {
		[transfer setState:WCTransferListing];
		
		if([transfer isKindOfClass:[WCDownloadTransfer class]]) {
			path = [transfer remotePath];
		} else {
			path = [[transfer destinationPath] stringByAppendingPathComponent:
				[[transfer localPath] lastPathComponent]];

			message = [WIP7Message messageWithName:@"wired.transfer.upload_directory" spec:WCP7Spec];
			[message setString:[transfer remotePath] forName:@"wired.file.path"];
			[[transfer connection] sendMessage:message fromObserver:self selector:@selector(wiredTransferUploadDirectoryReply:)];
		}

		message = [WIP7Message messageWithName:@"wired.file.list_directory" spec:WCP7Spec];
		[message setString:path forName:@"wired.file.path"];
		[message setBool:YES forName:@"wired.file.recursive"];
		
		transaction = [[transfer connection] sendMessage:message fromObserver:self selector:@selector(wiredFileListPathReply:)];
		
		[transfer setTransaction:transaction];
	} else {
		[self _startTransfer:transfer first:YES];
	}

	[self _validate];
}



- (void)_startTransfer:(WCTransfer *)transfer first:(BOOL)first {
	[[transfer connection] triggerEvent:WCEventsTransferStarted info1:transfer];

	if(![transfer isTerminating])
		[transfer setState:WCTransferWaiting];
    	
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_queueTransfer:) object:transfer];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:WCTransfersQueueUpdatedNotification
                                                        object:[transfer connection]
                                                      userInfo:nil];

	[WIThread detachNewThreadSelector:@selector(transferThread:) toTarget:self withObject:transfer];
}



- (void)_queueTransfer:(WCTransfer *)transfer { 
	[transfer setState:WCTransferQueued];
	
	[_transfersTableView setNeedsDisplay:YES]; 
}



- (void)_createRemainingDirectoriesForTransfer:(WCTransfer *)transfer {
	NSArray			*directories;
	WIP7Message		*message;
	WCFile			*directory;
	NSUInteger		i, count;
	
	directories = [transfer uncreatedDirectories];
	count = [directories count];
	
	if(count > 0 && ![transfer isTerminating]) {
		[transfer setState:WCTransferCreatingDirectories];
		
		[self _validate];
	}
	
	for(i = 0; i < count; i++) {
		directory = [directories objectAtIndex:i];
		
		if([transfer isKindOfClass:[WCDownloadTransfer class]]) {
			[[NSFileManager defaultManager] createDirectoryAtPath:[directory transferLocalPath]];
			
			[transfer addCreatedDirectory:directory];
		} else {
			message = [WIP7Message messageWithName:@"wired.transfer.upload_directory" spec:WCP7Spec];
			[message setString:[directory path] forName:@"wired.file.path"];
			[[transfer connection] sendMessage:message fromObserver:self selector:@selector(wiredTransferUploadDirectoryReply:)];
			
			[transfer addCreatedDirectory:directory];
		}
	}
	
	[transfer removeAllUncreatedDirectories];
}



- (void)_invalidateTransfersForConnection:(WCServerConnection *)connection {
	NSEnumerator		*enumerator;
	WCTransfer			*transfer;
	
	enumerator = [_transfers objectEnumerator];
	
	while((transfer = [enumerator nextObject])) {
		if([transfer connection] == connection) {
			if([transfer isWorking])
				[transfer setState:WCTransferDisconnecting];
			
			[transfer setConnection:NULL];
		}
	}
}



- (void)_saveTransfers {
	NSEnumerator		*enumerator;
	NSMutableArray		*transfers;
	WCTransfer			*transfer;
	
	transfers = [NSMutableArray array];
	enumerator = [_transfers objectEnumerator];
	
	while((transfer = [enumerator nextObject])) {
		if(![transfer isWorking])
			[transfers addObject:transfer];
	}
	
	[[WCSettings settings] setObject:[NSKeyedArchiver archivedDataWithRootObject:transfers] forKey:WCTransferList];
}



- (void)_finishTransfer:(WCTransfer *)transfer {
	NSString			*path, *newPath;
	NSDictionary		*dictionary;
    NSError             *error;
	WCFile				*file;
	WCTransferState		state;
	BOOL				download, next = YES;
	
	[transfer retain];
	
	file		= [[transfer firstUntransferredFile] retain];
	path		= [file transferLocalPath];
	download	= [transfer isKindOfClass:[WCDownloadTransfer class]];
	error       = nil;
    
    // if transfer is finished
	if((download && [file dataTransferred] + [file rsrcTransferred] >= [file dataSize] + [file rsrcSize]) ||
	   (!download && [file dataTransferred] + [file rsrcTransferred] >= [file uploadDataSize] + [file uploadRsrcSize])) {
        
        // if download is finished, move and rename target file
		if([transfer isKindOfClass:[WCDownloadTransfer class]]) {
			newPath = [path stringByDeletingPathExtension];
			
			[[NSFileManager defaultManager] removeExtendedAttributeForName:WCTransfersFileExtendedAttributeName atPath:path error:NULL];
			[[NSFileManager defaultManager] moveItemAtPath:path toPath:newPath error:&error];
            
			[transfer setLocalPath:newPath];
			path = newPath;
			
			if([file isExecutable]) {
                // make downloaded file executable
				dictionary = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:0755] forKey:NSFilePosixPermissions];
                [[NSFileManager defaultManager] setAttributes:dictionary ofItemAtPath:path error:&error];
			}
		}
		
		if(file) {
			[transfer addTransferredFile:file];
			[transfer removeUntransferredFile:file];
		}
		
		if([transfer numberOfUntransferredFiles] == 0) {
			[[transfer transferConnection] disconnect];
			[transfer setTransferConnection:NULL];
			[transfer setState:WCTransferFinished];
            
    
			[[transfer progressIndicator] setDoubleValue:1.0];
			
			if([[WCSettings settings] boolForKey:WCRemoveTransfers])
				[self _removeTransfer:transfer];

			[_transfersTableView reloadData];

			[self _validate];

			[[transfer connection] triggerEvent:WCEventsTransferFinished info1:transfer];
		} else {
			[self _startTransfer:transfer first:NO];

			next = NO;
		}
        
    // if transfer is stopped 
	} else {        
        [[transfer transferConnection] disconnect];
		[transfer setTransferConnection:NULL];
        
		state = [transfer state];
		
		if(state == WCTransferPausing) {
			[transfer setState:WCTransferPaused];
			
			next = NO;
		}
		else if(state == WCTransferDisconnecting) {
			[transfer setState:WCTransferDisconnected];
            
			next = NO;
		}
		else if(state == WCTransferRemoving) {
			[self _removeTransfer:transfer];
		}
		else {
			[transfer setState:WCTransferStopped];
		}
		
		[_transfersTableView reloadData];
		
		[self _validate];
	}

	if(next)
		[self _requestNextTransferForConnection:[transfer connection]];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:WCTransfersQueueUpdatedNotification
                                                        object:[transfer connection]
                                                      userInfo:nil];
	
	[file release];
	[transfer release];
}



- (void)_finishTransfer:(WCTransfer *)transfer withError:(WCError *)error {
	WCServerConnection		*connection;
	
    connection = [transfer connection];
        
    if(error) {
        [self _presentError:error forConnection:connection transfer:transfer];
    }

    [self _finishTransfer:transfer];
    
    if(![[error domain] isEqualToString:WCWiredClientErrorDomain] &&
	   ![[error domain] isEqualToString:WCWiredProtocolErrorDomain] &&
	   [[WCSettings settings] boolForKey:WCAutoReconnect] &&
	   ([connection isConnected] || [connection isAutoReconnecting] || [connection willAutoReconnect]) &&
	   [transfer actualTransferred] > 0) {
		[self performSelector:@selector(_requestTransfer:) withObject:transfer afterDelay:2.0];
	}
}



- (void)_removeTransfer:(WCTransfer *)transfer {
	[[transfer progressIndicator] removeFromSuperview];

    [[NSNotificationCenter defaultCenter] postNotificationName:WCTransfersQueueUpdatedNotification
                                                        object:[transfer connection]];

    [_transfers removeObject:transfer];
	[self _saveTransfers];
}



- (void)_cleanTransfers {
    WCTransfer              *transfer;
    
    if(![self _validateClear])
        return;
    
    while((transfer = [self _transferWithState:WCTransferFinished])) {
        [[transfer progressIndicator] removeFromSuperview];
        [_transfers removeObject:transfer];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:WCTransfersQueueUpdatedNotification
                                                        object:nil];
    
    [_transfersTableView setNeedsDisplay:YES];
    [_transfersTableView reloadData];
    
    [self _saveTransfers];
    [self _validate];
}


#pragma mark -

- (WCTransferConnection *)_transferConnectionForTransfer:(WCTransfer *)transfer {
	WCTransferConnection		*connection;
	
	connection = [WCTransferConnection connectionWithTransfer:transfer];
	[connection setURL:[[transfer connection] URL]];
	[connection setBookmark:[[transfer connection] bookmark]];
	
	return connection;
}



- (BOOL)_sendDownloadFileMessageOnConnection:(WCTransferConnection *)connection forFile:(WCFile *)file error:(WCError **)error {
	WIP7Message		*message;
	
	message = [WIP7Message messageWithName:@"wired.transfer.download_file" spec:WCP7Spec];
	[message setString:[file path] forName:@"wired.file.path"];
	[message setUInt64:[file dataTransferred] forName:@"wired.transfer.data_offset"];
	[message setUInt64:[file rsrcTransferred] forName:@"wired.transfer.rsrc_offset"];

	return [connection writeMessage:message timeout:30.0 error:error];
}



- (BOOL)_sendUploadFileMessageOnConnection:(WCTransferConnection *)connection forFile:(WCFile *)file error:(WCError **)error {
	WIP7Message		*message;
    NSDictionary    *attributes;
    
	message = [WIP7Message messageWithName:@"wired.transfer.upload_file" spec:WCP7Spec];
	[message setString:[file path] forName:@"wired.file.path"];
	[message setUInt64:[file uploadDataSize] forName:@"wired.transfer.data_size"];
	[message setUInt64:[file uploadRsrcSize] forName:@"wired.transfer.rsrc_size"];
	
    attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[file transferLocalPath] error:error];
    
    if ([[attributes valueForKey:NSFilePosixPermissions] shortValue] & 0111) {
        [message setBool:YES forName:@"wired.file.executable"];
    }
	
	return [connection writeMessage:message timeout:30.0 error:error];
}



- (BOOL)_sendUploadMessageOnConnection:(WCTransferConnection *)connection forFile:(WCFile *)file dataLength:(WIFileOffset)dataLength rsrcLength:(WIFileOffset)rsrcLength error:(WCError **)error {
	NSData			*finderInfo;
	WIP7Message		*message;
	
	message = [WIP7Message messageWithName:@"wired.transfer.upload" spec:WCP7Spec];
	[message setString:[file path] forName:@"wired.file.path"];
	[message setUInt64:dataLength forName:@"wired.transfer.data"];
	[message setUInt64:rsrcLength forName:@"wired.transfer.rsrc"];
	
	finderInfo = [[NSFileManager defaultManager] finderInfoAtPath:[file transferLocalPath]];
	
	[message setData:finderInfo ? finderInfo : [NSData data] forName:@"wired.transfer.finderinfo"];
	
	return [connection writeMessage:message timeout:30.0 error:error];
}



- (BOOL)_createRemainingDirectoriesOnConnection:(WCTransferConnection *)connection forTransfer:(WCTransfer *)transfer error:(WCError **)error {
	NSArray			*directories;
	WIP7Message		*message;
	WCFile			*directory;
	NSUInteger		i, count;
	
	directories = [transfer uncreatedDirectories];
	count = [directories count];
	
	if(count > 0 && ![transfer isTerminating]) {
		[transfer setState:WCTransferCreatingDirectories];
		
		[self performSelectorOnMainThread:@selector(_validate)];
	}
	
	for(i = 0; i < count; i++) {
		directory = [directories objectAtIndex:i];
		
		if([transfer isKindOfClass:[WCDownloadTransfer class]]) {
			[[NSFileManager defaultManager] createDirectoryAtPath:[[directories objectAtIndex:i] transferLocalPath]];
			
			[transfer addCreatedDirectory:directory];
			[transfer removeUncreatedDirectory:directory];
			
			count--;
			i--;
		} else {
			message = [WIP7Message messageWithName:@"wired.transfer.upload_directory" spec:WCP7Spec];
			[message setString:[directory path] forName:@"wired.file.path"];

			if(![connection writeMessage:message timeout:30.0 error:error])
				return NO;
			
			message = [self _runConnection:connection
							   forTransfer:transfer
				 untilReceivingMessageName:@"wired.okay"
									 error:error];
			
			if(!message)
				return NO;
			
			[transfer addCreatedDirectory:directory];
			[transfer removeUncreatedDirectory:directory];
			
			count--;
			i--;
		}
	}
	
	[transfer removeAllUncreatedDirectories];
	
	return YES;
}



- (BOOL)_connectConnection:(WCTransferConnection *)connection forTransfer:(WCTransfer *)transfer error:(WCError **)error {
	WIP7Message		*message;
	
	if(![connection connectWithTimeout:30.0 error:error])
		return NO;
	
	if(![connection writeMessage:[connection clientInfoMessage] timeout:30.0 error:error] ||
	   ![connection writeMessage:[connection setNickMessage] timeout:30.0 error:error] ||
	   ![connection writeMessage:[connection setStatusMessage] timeout:30.0 error:error] ||
	   ![connection writeMessage:[connection setIconMessage] timeout:30.0 error:error] ||
	   ![connection writeMessage:[connection loginMessage] timeout:30.0 error:error])
		return NO;
	
	message = [self _runConnection:connection
					   forTransfer:transfer
		 untilReceivingMessageName:@"wired.account.privileges"
							 error:error];
	
	if(!message)
		return NO;
	
	return YES;
}



- (WIP7Message *)_runConnection:(WCTransferConnection *)connection forTransfer:(WCTransfer *)transfer untilReceivingMessageName:(NSString *)messageName error:(WCError **)error {
	NSString			*name;
	WIP7Message			*message, *reply;
	NSInteger			code;
	WIP7UInt32			queue, transaction;
	
	while([transfer isWorking]) {
		message = [connection readMessageWithTimeout:0.0 error:error];
	
		if(!message) {
			code = [[[*error userInfo] objectForKey:WILibWiredErrorKey] code];

			if(code == ETIMEDOUT)
				continue;

			return NULL;
		}
		
		name = [message name];
		
		if([name isEqualToString:messageName]) {
			*error = NULL;
			
			return message;
		}
		
		if([name isEqualToString:@"wired.transfer.queue"]) {
			[message getUInt32:&queue forName:@"wired.transfer.queue_position"];
			
			[transfer setQueuePosition:queue];

			[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_queueTransfer:) object:transfer]; 

	        if([transfer state] == WCTransferRunning) 
				[self performSelector:@selector(_queueTransfer:) withObject:transfer afterDelay:0.5]; 
	        else 
				[self _queueTransfer:transfer]; 
		}
		else if([name isEqualToString:@"wired.send_ping"]) {
			reply = [WIP7Message messageWithName:@"wired.ping" spec:WCP7Spec];
			
			if([message getUInt32:&transaction forName:@"wired.transaction"])
				[reply setUInt32:transaction forName:@"wired.transaction"];
			
			if(![connection writeMessage:reply timeout:30.0 error:error])
				return NULL;
		}
		else if([name isEqualToString:@"wired.error"]) {
			*error = [WCError errorWithWiredMessage:message];
			
			return NULL;
		}
	}
	
	*error = NULL;
	
	return NULL;
}



- (void)_runDownload:(WCTransfer *)transfer {
	NSAutoreleasePool			*pool;
	NSProgressIndicator			*progressIndicator;
	NSString					*dataPath, *rsrcPath;
	NSData						*finderInfo;
	WIP7Socket					*socket;
	WIP7Message					*message;
	WCTransferConnection		*connection;
	WCFile						*file;
	WCError						*error;
	void						*buffer;
	NSTimeInterval				time, speedTime, statsTime;
	NSUInteger					i, speedBytes, statsBytes;
	NSInteger					readBytes;
	WIP7UInt64					dataLength, rsrcLength;
	double						percent;
	int							dataFD, rsrcFD, writtenBytes;
	BOOL						data;
		
	error = NULL;
	connection = [transfer transferConnection];
	
	if(!connection) {
		connection = [self _transferConnectionForTransfer:transfer];
		
		if(![self _connectConnection:connection forTransfer:transfer error:&error]) {
			[transfer setState:WCTransferStopping];
			[transfer signalTerminated];
			
			[self performSelectorOnMainThread:@selector(_finishTransfer:withError:)
								   withObject:transfer
								   withObject:error];

			return;
		}
		
		[transfer setTransferConnection:connection];
	}
	
	file				= [transfer firstUntransferredFile];
	dataPath			= [file transferLocalPath];
	rsrcPath			= [NSFileManager resourceForkPathForPath:dataPath];
	speedBytes			= 0;
	statsBytes			= 0;
	i					= 0;
	socket				= [connection socket];
	speedTime			= _WCTransfersTimeInterval();
	statsTime			= speedTime;
	progressIndicator	= [transfer progressIndicator];
	data				= YES;
	
	[[socket socket] setInteractive:NO];
	
	if(![self _createRemainingDirectoriesOnConnection:connection forTransfer:transfer error:&error]) {
		if(![transfer isTerminating]) {
			[transfer setState:WCTransferDisconnecting];
			[transfer signalTerminated];
		}
		
		[self performSelectorOnMainThread:@selector(_finishTransfer:withError:)
							   withObject:transfer
							   withObject:error];
		
		return;
	}
	
	if(![self _sendDownloadFileMessageOnConnection:connection forFile:file error:&error]) {
		if(![transfer isTerminating]) {
			[transfer setState:WCTransferDisconnecting];
			[transfer signalTerminated];
		}
		
		[self performSelectorOnMainThread:@selector(_finishTransfer:withError:)
							   withObject:transfer
							   withObject:error];
		
		return;
	}
	
	message = [self _runConnection:connection
					   forTransfer:transfer
		 untilReceivingMessageName:@"wired.transfer.download"
							 error:&error];
	
	if(!message) {
		if(![transfer isTerminating]) {
			[transfer setState:WCTransferDisconnecting];
			[transfer signalTerminated];
		}
		
		if(error) {
			[self performSelectorOnMainThread:@selector(_finishTransfer:withError:)
								   withObject:transfer
								   withObject:error];
		} else {
			[self performSelectorOnMainThread:@selector(_finishTransfer:)
								   withObject:transfer];
		}
		
		return;
	}
	
	[message getUInt64:&dataLength forName:@"wired.transfer.data"];
	[message getUInt64:&rsrcLength forName:@"wired.transfer.rsrc"];
	
	dataFD = open([dataPath fileSystemRepresentation], O_WRONLY | O_APPEND | O_CREAT, 0666);
	rsrcFD = open([rsrcPath fileSystemRepresentation], O_WRONLY | O_APPEND | O_CREAT, 0666);
	
	if((dataFD < 0 || lseek(dataFD, [file dataTransferred], SEEK_SET) < 0) ||
	   (rsrcFD < 0 || lseek(rsrcFD, [file rsrcTransferred], SEEK_SET) < 0)) {
		error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno];
		
		if(![transfer isTerminating]) {
			[transfer setState:WCTransferDisconnecting];
			[transfer signalTerminated];
		}
		
		if(dataFD >= 0)
			close(dataFD);
		
		if(rsrcFD >= 0)
			close(rsrcFD);

		[self performSelectorOnMainThread:@selector(_finishTransfer:withError:)
							   withObject:transfer
							   withObject:error];
		
		return;
	}
	
	finderInfo = [message dataForName:@"wired.transfer.finderinfo"];
	
	if([finderInfo length] > 0)
		[[NSFileManager defaultManager] setFinderInfo:finderInfo atPath:dataPath];
	
	if(![transfer isTerminating]) {
		[transfer setState:WCTransferRunning];
		
		[self performSelectorOnMainThread:@selector(_validate)];
	}
	
	wi_speed_calculator_add_bytes_at_time(transfer->_speedCalculator, 0, speedTime);
	
	pool = [[NSAutoreleasePool alloc] init];
	
	while(![transfer isTerminating]) {
		if(data && dataLength == 0)
			data = NO;
		
		if(!data && rsrcLength == 0)
			break;
		
		readBytes = [socket readOOBData:&buffer timeout:30.0 error:&error];
		
		if(readBytes <= 0) {
			[transfer setState:WCTransferDisconnecting];

			break;
		}
		
		if((data && dataLength < (NSUInteger) readBytes) || (!data && rsrcLength < (NSUInteger) readBytes)) {
			error = [WCError errorWithDomain:WCWiredClientErrorDomain code:WCWiredClientTransferFailed argument:[transfer name]];
			
			break;
		}
		
		writtenBytes = write(data ? dataFD : rsrcFD, buffer, readBytes);
		
		if(writtenBytes <= 0) {
			if(writtenBytes < 0)
				error = [WCError errorWithDomain:WCWiredClientErrorDomain code:WCWiredClientTransferFailed argument:[transfer name]];
			
			break;
		}
		
		if(data) {
			dataLength					-= readBytes;
			transfer->_dataTransferred	+= readBytes;
			file->_dataTransferred		+= readBytes;
		} else {
			rsrcLength					-= readBytes;
			transfer->_rsrcTransferred	+= readBytes;
			file->_rsrcTransferred		+= readBytes;
		}
			
		transfer->_actualTransferred	+= readBytes;
		statsBytes						+= readBytes;
		speedBytes						+= readBytes;
		percent							= (transfer->_dataTransferred + transfer->_rsrcTransferred) / (double) transfer->_size;
		time							= _WCTransfersTimeInterval();
		
        dispatch_async(dispatch_get_main_queue(), ^{
            if(percent == 1.00 || percent - [progressIndicator doubleValue] >= 0.001)
                [progressIndicator setDoubleValue:percent];
        });
	
		if(transfer->_speed == 0.0 || time - speedTime > 0.33) {
			wi_speed_calculator_add_bytes_at_time(transfer->_speedCalculator, speedBytes, speedTime);

			transfer->_speed = wi_speed_calculator_speed(transfer->_speedCalculator);
			
			speedBytes = 0;
			speedTime = time;
		}
		
		if(time - statsTime > 10.0) {
			[[WCStats stats] addUnsignedLongLong:statsBytes forKey:WCStatsDownloaded];
			
			statsBytes = 0;
			statsTime = time;
		}
		
		if(++i % 100 == 0) {
			[pool release];
			pool = [[NSAutoreleasePool alloc] init];
		}
	}
	
	close(dataFD);
	close(rsrcFD);
	
	wi_speed_calculator_add_bytes_at_time(transfer->_speedCalculator, speedBytes, speedTime);
	
	transfer->_speed = wi_speed_calculator_speed(transfer->_speedCalculator);
	
	if(statsBytes > 0)
		[[WCStats stats] addUnsignedLongLong:statsBytes forKey:WCStatsDownloaded];

	[transfer signalTerminated];
	
	if(error) {
		[self performSelectorOnMainThread:@selector(_finishTransfer:withError:)
							   withObject:transfer
							   withObject:error];
	} else {
		[self performSelectorOnMainThread:@selector(_finishTransfer:)
							   withObject:transfer];
	}
	
	[pool release];
}



- (void)_runUpload:(WCTransfer *)transfer {
	NSAutoreleasePool			*pool;
	NSProgressIndicator			*progressIndicator;
	NSString					*dataPath;
	WIP7Socket					*socket;
	WIP7Message					*message;
	WCTransferConnection		*connection;
	WCFile						*file;
	WCError						*error;
	char						buffer[8192];
	NSTimeInterval				time, speedTime, statsTime;
	NSUInteger					i, sendBytes, speedBytes, statsBytes;
	WIP7UInt64					dataLength;
	WIP7UInt64					dataOffset;
	double						percent;
	ssize_t						readBytes;
	int							dataFD;
	BOOL						data;
	
	error = NULL;
	connection = [transfer transferConnection];
	
	if(!connection) {
		connection = [self _transferConnectionForTransfer:transfer];
		
		if(![self _connectConnection:connection forTransfer:transfer error:&error]) {
			if(![transfer isTerminating]) {
				[transfer setState:WCTransferDisconnecting];
				[transfer signalTerminated];
			}
			
			[self performSelectorOnMainThread:@selector(_finishTransfer:withError:)
								   withObject:transfer
								   withObject:error];
			
			return;
		}
		
		[transfer setTransferConnection:connection];
	}
	
	file				= [transfer firstUntransferredFile];
	dataPath			= [file transferLocalPath];
	speedBytes			= 0;
	statsBytes			= 0;
	i					= 0;
	socket				= [connection socket];
	speedTime			= _WCTransfersTimeInterval();
	statsTime			= _WCTransfersTimeInterval();
	progressIndicator	= [transfer progressIndicator];
	data				= YES;
	
	[[socket socket] setInteractive:NO];
	
	if(![self _createRemainingDirectoriesOnConnection:connection forTransfer:transfer error:&error]) {
		if(![transfer isTerminating]) {
			[transfer setState:WCTransferDisconnecting];
			[transfer signalTerminated];
		}

		[self performSelectorOnMainThread:@selector(_finishTransfer:withError:)
							   withObject:transfer
							   withObject:error];
		
		return;
	}

	if(![self _sendUploadFileMessageOnConnection:connection forFile:file error:&error]) {
		if(![transfer isTerminating]) {
			[transfer setState:WCTransferDisconnecting];
			[transfer signalTerminated];
		}
		
		[self performSelectorOnMainThread:@selector(_finishTransfer:withError:)
							   withObject:transfer
							   withObject:error];
		
		return;
	}
	
	message = [self _runConnection:connection
					   forTransfer:transfer
		 untilReceivingMessageName:@"wired.transfer.upload_ready"
							 error:&error];
	
	if(!message) {
		if(![transfer isTerminating]) {
			[transfer setState:WCTransferDisconnecting];
			[transfer signalTerminated];
		}
		
		if(error) {
			[self performSelectorOnMainThread:@selector(_finishTransfer:withError:)
								   withObject:transfer
								   withObject:error];
		} else {
			[self performSelectorOnMainThread:@selector(_finishTransfer:)
								   withObject:transfer];
		}
		
		return;
	}
	
	[message getUInt64:&dataOffset forName:@"wired.transfer.data_offset"];
    
	dataLength = [file uploadDataSize] - dataOffset;
    
	if([file dataTransferred] == 0) {
		[file setDataTransferred:dataOffset];
		[transfer setDataTransferred:[transfer dataTransferred] + dataOffset];
	} else {
        [file setDataTransferred:dataOffset];
		[transfer setDataTransferred:dataOffset];
    }
	

	
	if(![self _sendUploadMessageOnConnection:connection forFile:file dataLength:dataLength rsrcLength:0 error:&error]) {
		if(![transfer isTerminating]) {
			[transfer setState:WCTransferDisconnecting];
			[transfer signalTerminated];
		}
		
		[self performSelectorOnMainThread:@selector(_finishTransfer:withError:)
							   withObject:transfer
							   withObject:error];
		
		return;
	}
	
	dataFD = open([dataPath fileSystemRepresentation], O_RDONLY, 0666);
	
	if((dataFD < 0 || lseek(dataFD, [file dataTransferred], SEEK_SET) < 0)) {
		error = [WCError errorWithDomain:NSPOSIXErrorDomain code:errno];
		
		if(![transfer isTerminating]) {
			[transfer setState:WCTransferDisconnecting];
			[transfer signalTerminated];
		}
		
		if(dataFD >= 0)
			close(dataFD);
		
		[self performSelectorOnMainThread:@selector(_finishTransfer:withError:)
							   withObject:transfer
							   withObject:error];
		
		return;
	}

	if(![transfer isTerminating]) {
		[transfer setState:WCTransferRunning];
		
		[self performSelectorOnMainThread:@selector(_validate)];
	}
	
	wi_speed_calculator_add_bytes_at_time(transfer->_speedCalculator, 0, speedTime);

	pool = [[NSAutoreleasePool alloc] init];

	while(![transfer isTerminating]) {
		if(data && dataLength == 0)
			data = NO;
		
		if(!data)
			break;
		
		readBytes = read(data ? dataFD : 0, buffer, sizeof(buffer));

		if(readBytes <= 0) {
			if(readBytes < 0)
				error = [WCError errorWithDomain:WCWiredClientErrorDomain code:WCWiredClientTransferFailed argument:[transfer name]];

			if(![transfer isTerminating])
				[transfer setState:WCTransferDisconnecting];
			
			break;
		}
		
		if(data)
			sendBytes = (dataLength < (NSUInteger) readBytes) ? dataLength : (NSUInteger) readBytes;
    
		
		if(![socket writeOOBData:buffer length:sendBytes timeout:30.0 error:&error]) {
			[transfer setState:WCTransferDisconnecting];

			break;
		}

		if(data) {
			dataLength					-= sendBytes;
			transfer->_dataTransferred	+= sendBytes;
			file->_dataTransferred		+= sendBytes;
		}
		
		transfer->_actualTransferred	+= readBytes;
		speedBytes						+= sendBytes;
		statsBytes						+= sendBytes;
		percent							= (transfer->_dataTransferred + transfer->_rsrcTransferred) / (double) transfer->_size;
		time							= _WCTransfersTimeInterval();
		
        dispatch_async(dispatch_get_main_queue(), ^{
            if(percent == 1.00 || percent - [progressIndicator doubleValue] >= 0.001)
                [progressIndicator setDoubleValue:percent];
        });
		
		if(transfer->_speed == 0.0 || time - speedTime > 0.33) {
			wi_speed_calculator_add_bytes_at_time(transfer->_speedCalculator, speedBytes, speedTime);
			
			transfer->_speed = wi_speed_calculator_speed(transfer->_speedCalculator);
			
			speedBytes = 0;
			speedTime = time;
		}

		if(time - statsTime > 10.0) {
			[[WCStats stats] addUnsignedLongLong:statsBytes forKey:WCStatsUploaded];

			statsBytes = 0;
			statsTime = time;
		}

		if(++i % 100 == 0) {
			[pool release];
			pool = NULL;
		}
	}
	
	close(dataFD);
	
	wi_speed_calculator_add_bytes_at_time(transfer->_speedCalculator, speedBytes, speedTime);
	
	transfer->_speed = wi_speed_calculator_speed(transfer->_speedCalculator);
	
	if(statsBytes > 0)
		[[WCStats stats] addUnsignedLongLong:statsBytes forKey:WCStatsDownloaded];

	[transfer signalTerminated];
	
	if(error) {
		[self performSelectorOnMainThread:@selector(_finishTransfer:withError:)
							   withObject:transfer
							   withObject:error];
	} else {
		[self performSelectorOnMainThread:@selector(_finishTransfer:)
							   withObject:transfer];
	}
	
	[pool release];
}

@end


@implementation WCTransfers

+ (id)transfers {
	static WCTransfers   *sharedTransfers;
	
	if(!sharedTransfers)
		sharedTransfers = [[self alloc] init];
	
	return sharedTransfers;
}





#pragma mark -

+ (BOOL)downloadFileAtPath:(NSString *)path forConnection:(WCServerConnection *)connection {
    WCFile  *file;
    
    path    = [path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    file    = [WCFile fileWithFile:path connection:connection];
    
    if(file && ![file isFolder]) {
        [[WCTransfers transfers] downloadFiles:[NSArray arrayWithObject:file]];
        return YES;
    }
    
    return NO;
}




#pragma mark -

- (id)init {
	self = [super initWithWindowNibName:@"Transfers"];

	_folderImage			= [[NSImage imageNamed:@"Folder"] retain];

	_quickLookTransfers		= [[NSMutableArray alloc] init];
	_quickLookPanelClass	= NSClassFromString(@"QLPreviewPanel");
	
	_sizeFormatter			= [[WISizeFormatter alloc] init];
	_timeIntervalFormatter	= [[WITimeIntervalFormatter alloc] init];

	[[NSNotificationCenter defaultCenter]
		addObserver:self
		   selector:@selector(applicationWillTerminate:)
			   name:NSApplicationWillTerminateNotification];

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
		   selector:@selector(linkConnectionWillDisconnect:)
			   name:WCLinkConnectionWillDisconnectNotification];

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

	_timer = [NSTimer scheduledTimerWithTimeInterval:0.33
											  target:self
											selector:@selector(updateTimer:)
											userInfo:NULL
											 repeats:YES];
	[_timer retain];
	
	[self window];
	
	return self;
}



- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[_errorQueue release];
	[_timer release];
	[_folderImage release];
	[_transfers release];
	[_quickLookTransfers release];
	
	[_sizeFormatter release];
	[_timeIntervalFormatter release];

	[super dealloc];
}



#pragma mark -

- (void)windowDidLoad {
	NSEnumerator	*enumerator;
	NSToolbar		*toolbar;
	NSData			*data;
	WCTransfer		*transfer;
	
	_errorQueue = [[WCErrorQueue alloc] initWithWindow:[self window]];
	
	toolbar = [[NSToolbar alloc] initWithIdentifier:@"Transfers"];
	[toolbar setDelegate:self];
	[toolbar setAllowsUserCustomization:YES];
	[toolbar setAutosavesConfiguration:YES];
	[[self window] setToolbar:toolbar];
	[toolbar release];
	
	[self setShouldCascadeWindows:NO];
	[self setWindowFrameAutosaveName:@"Transfers"];

	[_transfersTableView setTarget:self];
	[_transfersTableView setSpaceAction:@selector(quickLook:)];
	[_transfersTableView registerForDraggedTypes:
		[NSArray arrayWithObjects:NSStringPboardType, WCTransferPboardType, NULL]];

    data = [[WCSettings settings] objectForKey:WCTransferList];

    if(data)
        _transfers = [[NSKeyedUnarchiver unarchiveObjectWithData:data] retain];
	
	if(!_transfers)
		_transfers = [[NSMutableArray alloc] init];
	
	enumerator = [_transfers objectEnumerator];
	
	while((transfer = [enumerator nextObject])) {
		if([transfer state] == WCTransferDisconnecting)
			[transfer setState:WCTransferDisconnected];
	}
	
	[_transfersTableView reloadData];

	[self _themeDidChange];
}



- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)identifier willBeInsertedIntoToolbar:(BOOL)willBeInsertedIntoToolbar {
	NSToolbarItem	*item;
	NSMenuItem		*menuRepresentation;
	NSString		*title;
	NSControl		*control;
	SEL				selector;
	
	if([identifier isEqualToString:@"Start"]) {
		selector	= @selector(start:);
		title		= NSLS(@"Start", @"Start transfer toolbar item");
		control		= _startButton;
	}
	else if([identifier isEqualToString:@"Pause"]) {		
		selector	= @selector(pause:);
		title		= NSLS(@"Pause", @"Pause transfer toolbar item");
		control		= _pauseButton;
	}
	else if([identifier isEqualToString:@"Stop"]) {
		selector	= @selector(stop:);
		title		= NSLS(@"Stop", @"Stop transfer toolbar item");
		control		= _stopButton;
	}
	else if([identifier isEqualToString:@"Remove"]) {
		selector	= @selector(remove:);
		title		= NSLS(@"Remove", @"Remove transfer toolbar item");
		control		= _removeButton;
	}
	else if([identifier isEqualToString:@"Clear"]) {		
		selector	= @selector(clear:);
		title		= NSLS(@"Clear", @"Clear transfers toolbar item");
		control		= _clearButton;
	}
	else if([identifier isEqualToString:@"Connect"]) {
		selector	= @selector(connect:);
		title		= NSLS(@"Connect", @"Connect transfer toolbar item");
		control		= _connectButton;
	}
	else if([identifier isEqualToString:@"QuickLook"]) {
		selector	= @selector(quickLook:);
		title		= NSLS(@"Quick Look", @"Quick look transfers toolbar item");
		control		= _quickLookButton;
	}
	else if([identifier isEqualToString:@"RevealInFinder"]) {
		selector	= @selector(revealInFinder:);
		title		= NSLS(@"Reveal In Finder", @"Reveal transfer in Finder toolbar item");
		control		= _revealInFinderButton;
	}
	else if([identifier isEqualToString:@"RevealInFiles"]) {		
		selector	= @selector(revealInFiles:);
		title		= NSLS(@"Reveal In Files", @"Reveal transfer in files toolbar item");
		control		= _revealInFilesButton;
	}
	
	item		= [NSToolbarItem toolbarItemWithIdentifier:identifier
												name:title
											 content:control
											  target:self
											  action:selector];
	
	menuRepresentation = [[NSMenuItem alloc] initWithTitle:title
													action:selector
											 keyEquivalent:@""];
	
	[menuRepresentation setTarget:self];
	[item setMenuFormRepresentation:menuRepresentation];
	[menuRepresentation release];
	
	return item;
}



- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
	return [NSArray arrayWithObjects:
		@"Start",
		@"Pause",
		@"Stop",
		@"Remove",
		@"Clear",
		NSToolbarFlexibleSpaceItemIdentifier,
		@"Connect",
		@"QuickLook",
		@"RevealInFinder",
		@"RevealInFiles",
		NULL];
}



- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
	return [NSArray arrayWithObjects:
		@"Start",
		@"Pause",
		@"Stop",
		@"Remove",
		@"Clear",
		@"Connect",
		@"QuickLook",
		@"RevealInFinder",
		@"RevealInFiles",
		NSToolbarSeparatorItemIdentifier,
		NSToolbarSpaceItemIdentifier,
		NSToolbarFlexibleSpaceItemIdentifier,
		NSToolbarCustomizeToolbarItemIdentifier,
		NULL];
}



- (void)applicationWillTerminate:(NSNotification *)notification {
	NSEnumerator		*enumerator;
	NSData				*data;
	NSString			*path;
	WCTransfer			*transfer;
	WCFile				*file;

	enumerator = [_transfers objectEnumerator];

	while((transfer = [enumerator nextObject])) {
		if([transfer isWorking]) {
			[transfer setState:WCTransferDisconnecting];
			
			if([transfer waitUntilTerminatedBeforeDate:[NSDate dateWithTimeIntervalSinceNow:1.0]])
				[transfer setState:WCTransferDisconnected];
		}
	}

	enumerator = [_transfers objectEnumerator];

	while((transfer = [enumerator nextObject])) {
		if(![transfer isFolder] && [transfer isStopped] && [transfer state] != WCTransferDisconnected) {
			file = [transfer firstUntransferredFile];
			
			if(file) {
				path = [file transferLocalPath];
				data = [NSKeyedArchiver archivedDataWithRootObject:transfer];
				
				[[NSFileManager defaultManager] setExtendedAttribute:data
															 forName:WCTransfersFileExtendedAttributeName
															  atPath:path
															   error:NULL];
			}
		}
	}

	[self _saveTransfers];
}



- (void)linkConnectionLoggedIn:(NSNotification *)notification {
	NSEnumerator			*enumerator;
	WCServerConnection		*connection;
	WCTransfer				*transfer;

	if(![[notification object] isKindOfClass:[WCServerConnection class]])
		return;

	connection = [notification object];
	enumerator = [_transfers objectEnumerator];
	
	while((transfer = [enumerator nextObject])) {
		if([transfer belongsToConnection:connection])
			[transfer setConnection:connection];
		
		if([transfer connection] == connection && [transfer state] == WCTransferDisconnected)
			[self _requestTransfer:transfer];
	}
	
	[_transfersTableView setNeedsDisplay:YES];
	[_transfersTableView reloadData];
	
	[self _validate];
}



- (void)linkConnectionWillDisconnect:(NSNotification *)notification {
	NSEnumerator			*enumerator;
	WCServerConnection		*connection;
	WCTransfer				*transfer;
	
	if(![[notification object] isKindOfClass:[WCServerConnection class]])
		return;

	connection = [notification object];
	enumerator = [_transfers objectEnumerator];

	while((transfer = [enumerator nextObject])) {
		if([transfer connection] == connection && [transfer isWorking])
			[transfer setState:WCTransferDisconnecting];
	}
	
	[_transfersTableView setNeedsDisplay:YES];
	[_transfersTableView reloadData];
	
	[self _validate];
}



- (void)linkConnectionDidClose:(NSNotification *)notification {
	if(![[notification object] isKindOfClass:[WCServerConnection class]])
		return;
	
	[self _invalidateTransfersForConnection:[notification object]];
	
	[self _validate];
}



- (void)linkConnectionDidTerminate:(NSNotification *)notification {
	if(![[notification object] isKindOfClass:[WCServerConnection class]])
		return;
	
	[self _invalidateTransfersForConnection:[notification object]];
	
	[self _validate];
}



- (void)serverConnectionServerInfoDidChange:(NSNotification *)notification {
	NSEnumerator			*enumerator;
	WCServerConnection		*connection;
	WCTransfer				*transfer;
	
	connection = [notification object];
	enumerator = [_transfers objectEnumerator];

	while((transfer = [enumerator nextObject])) {
		if([transfer connection] == connection)
			[transfer refreshSpeedLimit];
	}
	
	[_transfersTableView setNeedsDisplay:YES];
}



- (void)serverConnectionPrivilegesDidChange:(NSNotification *)notification {
	NSEnumerator			*enumerator;
	WCServerConnection		*connection;
	WCTransfer				*transfer;
	
	connection = [notification object];
	enumerator = [_transfers objectEnumerator];

	while((transfer = [enumerator nextObject])) {
		if([transfer connection] == connection)
			[transfer refreshSpeedLimit];
	}
	
	[_transfersTableView setNeedsDisplay:YES];
}



- (void)selectedThemeDidChange:(NSNotification *)notification {
	[self _themeDidChange];
}



- (void)wiredFileListPathReply:(WIP7Message *)message {
	NSString			*rootPath, *localPath;
	WCTransfer			*transfer;
	WCFile				*file;
	NSRect				rect;
	WIP7UInt32			transaction;
	
	[message getUInt32:&transaction forName:@"wired.transaction"];

	transfer = [self _transferWithTransaction:transaction];

	if(!transfer)
		return;

	if([[message name] isEqualToString:@"wired.file.file_list"]) {
		file = [WCFile fileWithMessage:message connection:[transfer connection]];
		
		if([transfer isKindOfClass:[WCDownloadTransfer class]]) {
			rootPath = [[transfer remotePath] stringByDeletingLastPathComponent];
			localPath = [[transfer destinationPath] stringByAppendingPathComponent:
				[[file path] substringFromIndex:[rootPath length]]];
			
			[file setTransferLocalPath:localPath];
			
			if([file type] == WCFileFile) {
				if(![transfer containsTransferredFile:file] && ![transfer containsUntransferredFile:file]) {
					if([[NSFileManager defaultManager] fileExistsAtPath:localPath]) {
						[transfer setDataTransferred:[transfer dataTransferred] + [file dataSize]];
						[transfer setRsrcTransferred:[transfer rsrcTransferred] + [file rsrcSize]];
					} else {
						[transfer setSize:[transfer size] + [file dataSize] + [file rsrcSize]];
						
						if(![localPath hasSuffix:WCTransfersFileExtension])
							localPath = [localPath stringByAppendingPathExtension:WCTransfersFileExtension];
						
						[file setDataTransferred:[[NSFileManager defaultManager] fileSizeAtPath:localPath]];
						
						if([[file connection] supportsResourceForks])
							[file setRsrcTransferred:[[NSFileManager defaultManager] resourceForkSizeAtPath:localPath]];
						
						[file setTransferLocalPath:localPath];
						
						[transfer addUntransferredFile:file];
						[transfer setDataTransferred:[transfer dataTransferred] + [file dataTransferred]];
						[transfer setRsrcTransferred:[transfer rsrcTransferred] + [file rsrcTransferred]];
					}
				}
			} else {
				if(![transfer containsUncreatedDirectory:file] && ![transfer containsCreatedDirectory:file])
					[transfer addUncreatedDirectory:file];
			}
		} else {
			if([file type] == WCFileFile) {
				if([transfer containsUntransferredFile:file])
					[transfer removeUntransferredFile:file];
				
				if(![transfer containsTransferredFile:file]) {
					[transfer setDataTransferred:[transfer dataTransferred] + [file dataSize] + [file rsrcSize]];
					[transfer removeUntransferredFile:file];
				}
			} else {
				if([transfer containsUncreatedDirectory:file])
					[transfer removeUncreatedDirectory:file];
				
				if(![transfer containsCreatedDirectory:file])
					[transfer addCreatedDirectory:file];
			}
		}
		
		if([[transfer uncreatedDirectories] count] + [[transfer createdDirectories] count] % 10 == 0 ||
		   [transfer numberOfUntransferredFiles] + [transfer numberOfTransferredFiles] % 10 == 0) {
			rect = [_transfersTableView frameOfCellAtColumn:1 row:[_transfers indexOfObject:transfer]];

			[_transfersTableView setNeedsDisplayInRect:rect];
		}
	}
	else if([[message name] isEqualToString:@"wired.file.file_list.done"]) {
		if([transfer numberOfUntransferredFiles] > 0) {
			[self _startTransfer:transfer first:YES];
		} else {
			[self _createRemainingDirectoriesForTransfer:transfer];
			[self _finishTransfer:transfer];
		}
		
		[[transfer connection] removeObserver:self message:message];
	}
	else if([[message name] isEqualToString:@"wired.error"]) {
		[_errorQueue showError:[WCError errorWithWiredMessage:message]];
		
		[[transfer connection] removeObserver:self message:message];
	}
}



- (void)wiredTransferUploadDirectoryReply:(WIP7Message *)message {
	WCServerConnection		*connection;
	WCError					*error;
	
	connection = [message contextInfo];
	
	if([[message name] isEqualToString:@"wired.okay"]) {
		[connection removeObserver:self message:message];
	}
	else if([[message name] isEqualToString:@"wired.error"]) {
		error = [WCError errorWithWiredMessage:message];
		
		if([error code] != WCWiredProtocolFileExists)
			[_errorQueue showError:error];
		
		[connection removeObserver:self message:message];
	}
}



#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem *)item {
	SEL		selector;
	
	selector = [item action];
	
	if(selector == @selector(start:))
		return [self _validateStart];
	else if(selector == @selector(pause:))
		return [self _validatePause];
	else if(selector == @selector(stop:))
		return [self _validateStop];
	else if(selector == @selector(remove:) || selector == @selector(deleteDocument:))
		return [self _validateRemove];
	else if(selector == @selector(clear:))
		return [self _validateClear];
	else if(selector == @selector(connect:))
		return [self _validateConnect];
	else if(selector == @selector(quickLook:))
		return [self _validateQuickLook];
	else if(selector == @selector(revealInFinder:))
		return [self _validateRevealInFinder];
	else if(selector == @selector(revealInFiles:))
		return [self _validateRevealInFiles];
	
	return YES;
}



#pragma mark -

- (void)transferThread:(id)arg {
	NSAutoreleasePool		*pool;
	WCTransfer				*transfer = arg;
	
	pool = [[NSAutoreleasePool alloc] init];
	
	if([transfer isKindOfClass:[WCDownloadTransfer class]])
		[self _runDownload:transfer];
	else
		[self _runUpload:transfer];
	
	[pool release];
}



- (void)updateTimer:(NSTimer *)timer {
	NSRect			rect;
	NSUInteger		i, count;
	
	count = [_transfers count];
	
	for(i = 0; i < count; i++) {
		if([[_transfers objectAtIndex:i] isWorking]) {
			rect = [_transfersTableView frameOfCellAtColumn:1 row:i];

			[_transfersTableView setNeedsDisplayInRect:rect];
		}
	}
}



#pragma mark -

- (NSString *)deleteDocumentMenuItemTitle {
	NSArray			*transfers;
	
	transfers = [self _selectedTransfers];
	
	if([transfers count] == 1)
		return [NSSWF:NSLS(@"Remove \u201c%@\u201d", @"Delete menu item (transfer"), [[transfers objectAtIndex:0] name]];
	else if([transfers count] > 1)
		return [NSSWF:NSLS(@"Remove %u Items", @"Delete menu item (count"), [transfers count]];
	else
		return NSLS(@"Delete", @"Delete menu item");
}



- (NSString *)quickLookMenuItemTitle {
	NSArray			*transfers;
	
	transfers = [self _selectedTransfers];
	
	if([transfers count] == 1)
		return [NSSWF:NSLS(@"Quick Look \u201c%@\u201d", @"Quick Look menu item (transfer"), [[transfers objectAtIndex:0] name]];
	else if([transfers count] > 1)
		return [NSSWF:NSLS(@"Quick Look %u Items", @"Quick Look menu item (count"), [transfers count]];
	else
		return NSLS(@"Quick Look", @"Quick Look menu item");
}




#pragma mark -

- (NSInteger)numberOfUncompleteTransfers {
    NSInteger count = 0;
    
    for(WCTransfer *transfer in _transfers) {
        if([transfer state] != WCTransferDisconnected) {
            if([transfer numberOfUntransferredFiles] > 0) {
                count++;
            }
        }
    }
    
    return count;
}





#pragma mark -

- (BOOL)addTransferAtPath:(NSString *)path {
	NSEnumerator			*enumerator;
	NSData					*data;
	WCServerConnection		*connection;
	WCTransfer				*transfer, *existingTransfer;
	NSUInteger				index;
	
	[self showWindow:self];
	
	data = [[NSFileManager defaultManager] extendedAttributeForName:WCTransfersFileExtendedAttributeName atPath:path error:NULL];
	
	if(!data)
		return NO;
	
	transfer = [NSKeyedUnarchiver unarchiveObjectWithData:data];
	
	if(!transfer || ![transfer isKindOfClass:[WCTransfer class]])
		return NO;
	
	enumerator = [[[WCPublicChat publicChat] chatControllers] objectEnumerator];
	
	while((connection = [enumerator nextObject])) {
		if([transfer belongsToConnection:connection]) {
			[transfer setConnection:connection];
			
			break;
		}
	}
	
	if(![transfer connection])
		return NO;
	
	existingTransfer = [self _unfinishedTransferWithPath:[[transfer firstUntransferredFile] path]
											  connection:[transfer connection]];
	
	if(existingTransfer) {
		index = [_transfers indexOfObject:existingTransfer];
	} else {
		[transfer setState:WCTransferDisconnected];
		
		[_transfers addObject:transfer];
		[_transfersTableView reloadData];
		
		index = [_transfers count] - 1;
	}
	
	if(index != NSNotFound)
		[_transfersTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
	
	return YES;
}



- (BOOL)downloadFiles:(NSArray *)files {
	return [self _downloadFiles:files
					   toFolder:[[[WCSettings settings] objectForKey:WCDownloadFolder] stringByStandardizingPath]];
}



- (BOOL)downloadFiles:(NSArray *)files toFolder:(NSString *)destination {
	return [self _downloadFiles:files toFolder:destination];
}



- (BOOL)uploadPaths:(NSArray *)paths toFolder:(WCFile *)destination {
	return [self _uploadPaths:paths toFolder:destination];
}



#pragma mark -

- (IBAction)deleteDocument:(id)sender {
	[self remove:sender];
}



- (IBAction)start:(id)sender {
	NSEnumerator	*enumerator;
	WCTransfer		*transfer;
	
	if(![self _validateStart])
		return;
	
	enumerator = [[self _selectedTransfers] objectEnumerator];
	
	while((transfer = [enumerator nextObject])) {
		[transfer setState:WCTransferWaiting];
		
		[self _requestTransfer:transfer];
	}
		
	[_transfersTableView setNeedsDisplay:YES];

	[self _validate];
}



- (IBAction)pause:(id)sender {
	NSEnumerator	*enumerator;
	WCTransfer		*transfer;
	
	if(![self _validatePause])
		return;
	
	enumerator = [[self _selectedTransfers] objectEnumerator];
	
	while((transfer = [enumerator nextObject]))
		[transfer setState:WCTransferPausing];
	
	[_transfersTableView setNeedsDisplay:YES];

	[self _validate];
}



- (IBAction)stop:(id)sender {
	NSEnumerator	*enumerator;
	WCTransfer		*transfer;
	
	if(![self _validateStop])
		return;
	
	enumerator = [[self _selectedTransfers] objectEnumerator];
	
	while((transfer = [enumerator nextObject]))
		[transfer setState:WCTransferStopping];

	[_transfersTableView setNeedsDisplay:YES];

	[self _validate];
}



- (IBAction)remove:(id)sender {
	NSEnumerator	*enumerator;
	WCTransfer		*transfer;
	
	if(![self _validateRemove])
		return;

	enumerator = [[self _selectedTransfers] objectEnumerator];
	
	while((transfer = [enumerator nextObject])) {
		if([transfer isWorking])
			[transfer setState:WCTransferRemoving];
		else
			[self _removeTransfer:transfer];
	}

	[_transfersTableView setNeedsDisplay:YES];
	[_transfersTableView reloadData];
	
	[self _validate];
}



- (IBAction)clear:(id)sender {
    [self performSelector:@selector(_cleanTransfers) withObject:nil];
}



- (IBAction)quickLook:(id)sender {
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    
	NSEnumerator		*enumerator;
	NSMutableArray		*urls;
	WCTransfer			*transfer;
	id					quickLookPanel;
	
	if(![self _validateQuickLook])
		return;
	
	[_quickLookTransfers removeAllObjects];
	
	urls			= [NSMutableArray array];
	enumerator		= [[self _selectedTransfers] objectEnumerator];
	
	while((transfer = [enumerator nextObject])) {
		[_quickLookTransfers addObject:transfer];
		[urls addObject:[transfer previewItemURL]];
	}
	
	quickLookPanel = [_quickLookPanelClass performSelector:@selector(sharedPreviewPanel)];

	if([quickLookPanel isVisible])
		[quickLookPanel orderOut:self];
	else
		[quickLookPanel makeKeyAndOrderFront:self];
	
	if(NSAppKitVersionNumber >= 1038.0) {
		if([quickLookPanel respondsToSelector:@selector(reloadData)])
			[quickLookPanel performSelector:@selector(reloadData)];
	} else {
		if([quickLookPanel respondsToSelector:@selector(setURLs:)]) {
			[quickLookPanel performSelector:@selector(setURLs:)
								 withObject:urls];
		}
	}
    
#pragma clang diagnostic pop
}



- (IBAction)connect:(id)sender {
	NSEnumerator	*enumerator;
	WCConnect		*connect;
	WCTransfer		*transfer;
	
	if(![self _validateConnect])
		return;
	
	enumerator = [[self _selectedTransfers] objectEnumerator];
	
	while((transfer = [enumerator nextObject])) {
		connect = [WCConnect connectWithURL:[transfer URL] bookmark:[transfer bookmark]];
		[connect showWindow:self];
		[connect connect:self];
	}
}



- (IBAction)revealInFinder:(id)sender {
	NSEnumerator	*enumerator;
	NSString		*path;
	WCTransfer		*transfer;
	
	if(![self _validateRevealInFinder])
		return;
	
	enumerator = [[self _selectedTransfers] objectEnumerator];
	
	while((transfer = [enumerator nextObject])) {
		if([transfer isFolder])
			path = [[transfer destinationPath] stringByAppendingPathComponent:[transfer name]];
		else
			path = [transfer localPath];
		
		[[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:@""];
	}
}



- (IBAction)revealInFiles:(id)sender {
	NSEnumerator	*enumerator;
	NSString		*path;
	WCTransfer		*transfer;
    WCFile          *file;
	
	if(![self _validateRevealInFiles])
		return;
	
	enumerator = [[self _selectedTransfers] objectEnumerator];
	
	while((transfer = [enumerator nextObject])) {
		path = [transfer remotePath];
        file = [WCFile fileWithDirectory:path connection:[transfer connection]];
		
		[WCFiles filesWithConnection:[transfer connection]
								file:[WCFile fileWithDirectory:[path stringByDeletingLastPathComponent] connection:[transfer connection]]
						  selectFile:file];
	}
}



#pragma mark -

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return [_transfers count];
}



- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	WCTransfer		*transfer;

	transfer = [_transfers objectAtIndex:row];
    
    if(!transfer)
        return NULL;

	if(tableColumn == _iconTableColumn) {
		return [transfer icon];
	}
	else if(tableColumn == _infoTableColumn) {
		return [NSDictionary dictionaryWithObjectsAndKeys:
			[transfer name],						WCTransferCellNameKey,
			[self _statusForTransfer:transfer],		WCTransferCellStatusKey,
			[transfer progressIndicator],			WCTransferCellProgressKey,
			NULL];
	}

	return NULL;
}



- (void)tableViewSelectionDidChange:(NSNotification *)notification {
	[self _validate];
}



- (void)tableViewFlagsDidChange:(NSTableView *)tableView {
	[self _validate];
}



- (void)tableViewShouldCopyInfo:(NSTableView *)tableView {
	NSEnumerator		*enumerator;
	NSPasteboard		*pasteboard;
	NSMutableString		*string;
	WCTransfer			*transfer;

	string			= [NSMutableString string];
	enumerator		= [[self _selectedTransfers] objectEnumerator];
	
	while((transfer = [enumerator nextObject]))
		[string appendFormat:@"%@",[NSSWF:@"%@ - %@\n", [transfer name], [self _statusForTransfer:transfer]]];
	
	[string trimCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

	pasteboard = [NSPasteboard generalPasteboard];
	[pasteboard declareTypes:[NSArray arrayWithObjects:NSStringPboardType, NULL] owner:NULL];
	[pasteboard setString:string forType:NSStringPboardType];
}



- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation {
	if(operation != NSTableViewDropAbove)
		return NSDragOperationNone;

	return NSDragOperationGeneric;
}



- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)indexes toPasteboard:(NSPasteboard *)pasteboard {
	WCTransfer		*transfer;
	NSString		*string;
	NSUInteger		index;

	index		= [indexes firstIndex];
	transfer	= [_transfers objectAtIndex:index];
	string		= [NSSWF:@"%@ - %@", [transfer name], [self _statusForTransfer:transfer]];

	[pasteboard declareTypes:[NSArray arrayWithObjects:NSStringPboardType, WCTransferPboardType, NULL] owner:NULL];
	[pasteboard setString:[NSSWF:@"%ld", index] forType:WCTransferPboardType];
	[pasteboard setString:string forType:NSStringPboardType];

	return YES;
}



- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation {
	NSPasteboard	*pasteboard;
	NSArray			*types;
	NSInteger		fromRow;

	pasteboard	= [info draggingPasteboard];
	types		= [pasteboard types];

	if([types containsObject:WCTransferPboardType]) {
		fromRow = [[pasteboard stringForType:WCTransferPboardType] integerValue];
		[_transfers moveObjectAtIndex:fromRow toIndex:row];
		[_transfersTableView reloadData];

		return YES;
	}

	return NO;
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
	return [_quickLookTransfers count];
}



- (id /*id <QLPreviewItem>*/)previewPanel:(id /*QLPreviewPanel **/)panel previewItemAtIndex:(NSInteger)index {
	return [_quickLookTransfers objectAtIndex:index];
}



- (NSRect)previewPanel:(id /*QLPreviewPanel **/)panel sourceFrameOnScreenForPreviewItem:(id /*id <QLPreviewItem>*/)item {
	NSRect			frame;
	NSUInteger		index;
	
	index = [_transfers indexOfObject:item];
	
	if(index != NSNotFound) {
		frame				= [_transfersTableView convertRect:[_transfersTableView frameOfCellAtColumn:0 row:index] toView:NULL];
		frame.origin		= [[self window] convertBaseToScreen:frame.origin];

		return NSMakeRect(frame.origin.x, frame.origin.y, frame.size.height, frame.size.height);
	}

	return NSZeroRect;
}

@end
