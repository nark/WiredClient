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
#import "WCFile.h"
#import "WCFileInfo.h"
#import "WCFiles.h"
#import "WCServerConnection.h"

@interface WCFileInfo(Private)

+ (NSString *)_stringForFolderCount:(WIFileOffset)count;

- (id)_initFileInfoWithConnection:(WCServerConnection *)connection files:(NSArray *)files;

- (void)_addItemWithTitle:(NSString *)title tag:(NSInteger)tag firstInPopUpButton:(NSPopUpButton *)popUpButton;

- (void)_showFileInfo;
- (void)_sendFileInfo;
- (void)_sendFileInfoTimeout;

@end


@implementation WCFileInfo(Private)

+ (NSString *)_stringForFolderCount:(WIFileOffset)count {
	return [NSSWF:
		NSLS(@"%llu %@", @"File info folder size (count, 'item(s)'"),
		count,
		count == 1
			? NSLS(@"item", @"Item singular")
			: NSLS(@"items", @"Item plural")];
}



#pragma mark -

- (id)_initFileInfoWithConnection:(WCServerConnection *)connection files:(NSArray *)files {
	NSEnumerator	*enumerator;
	WIP7Message		*message;
	WCFile			*file;
	
	self = [super initWithWindowNibName:@"FileInfo" connection:connection singleton:NO];

	_files = [files retain];
	_info = [[NSMutableArray alloc] init];

	enumerator = [_files objectEnumerator];
	
	while((file = [enumerator nextObject])) {
		message = [WIP7Message messageWithName:@"wired.file.get_info" spec:WCP7Spec];
		[message setString:[file path] forName:@"wired.file.path"];
		[[self connection] sendMessage:message fromObserver:self selector:@selector(wiredFileGetInfoReply:)];
	}
	
	[self window];

	return self;
}



#pragma mark -

- (void)_addItemWithTitle:(NSString *)title tag:(NSInteger)tag firstInPopUpButton:(NSPopUpButton *)popUpButton {
	NSMenuItem		*item;
	
	item = [NSMenuItem itemWithTitle:title tag:tag];
	
	if([popUpButton numberOfItems] == 0) {
		[[popUpButton menu] addItem:item];
	} else {
		[[popUpButton menu] insertItem:[NSMenuItem separatorItem] atIndex:0];
		[[popUpButton menu] insertItem:item atIndex:0];
	}

	[popUpButton selectItemAtIndex:0];
}


#pragma mark -

- (void)_showFileInfo {
	NSEnumerator	*enumerator;
	WCFile			*file;
	NSRect			rect;
	CGFloat			offset, height;
	NSUInteger		folders, files, dropBoxes;
	WIFileOffset	fileSize, folderSize;
	
	if([_info count] == 1) {
		file = [_info objectAtIndex:0];
	
		[_iconImageView setImage:[file iconWithWidth:32.0 open:NO]];
		[_fileTextField setStringValue:[file name]];
		[_kindTextField setStringValue:[file kind]];
		[_kindPopUpButton selectItemWithTag:[file type]];
		[_whereTextField setStringValue:[[file path] stringByDeletingLastPathComponent]];
		[_createdTextField setStringValue:[_dateFormatter stringFromDate:[file creationDate]]];
		[_modifiedTextField setStringValue:[_dateFormatter stringFromDate:[file modificationDate]]];
		[_labelPopUpButton selectItemWithTag:[file label]];
		[_commentTextField setStringValue:[file comment]];
		
		if([file type] == WCFileFile) {
			[_sizeTextField setStringValue:[_sizeFormatter stringFromSize:[file totalSize]]];
		} else {
			[_sizeTextField setStringValue:
				[[self class] _stringForFolderCount:[file directoryCount]]];
		}

		[self setYOffset:74.0];
		[self resizeTitleTextField:_commentTitleTextField withTextField:NULL];
		
		if([file type] == WCFileDropBox) {
			[self resizeTitleTextField:_everyoneTitleTextField withPopUpButton:_everyonePermissionsPopUpButton];
			[self resizeTitleTextField:NULL withPopUpButton:_groupPermissionsPopUpButton];
			[self resizeTitleTextField:_groupTitleTextField withPopUpButton:_groupPopUpButton];
			[self resizeTitleTextField:NULL withPopUpButton:_ownerPermissionsPopUpButton];
			[self resizeTitleTextField:_ownerTitleTextField withPopUpButton:_ownerPopUpButton];
			
			if([[file group] length] > 0 && [_groupPopUpButton indexOfItemWithTitle:[file group]] == -1)
				[self _addItemWithTitle:[file group] tag:0 firstInPopUpButton:_groupPopUpButton];

			[self _addItemWithTitle:NSLS(@"None", @"File info popup title") tag:-2 firstInPopUpButton:_groupPopUpButton];

			if([[file group] length] > 0)
				[_groupPopUpButton selectItemWithTitle:[file group]];
			else
				[_groupPopUpButton selectItemAtIndex:0];

			if([[file owner] length] > 0 && [_ownerPopUpButton indexOfItemWithTitle:[file owner]] == -1)
				[self _addItemWithTitle:[file owner] tag:0 firstInPopUpButton:_ownerPopUpButton];

			[self _addItemWithTitle:NSLS(@"None", @"File info popup title") tag:-2 firstInPopUpButton:_ownerPopUpButton];
			
			if([[file owner] length] > 0)
				[_ownerPopUpButton selectItemWithTitle:[file owner]];
			else
				[_ownerPopUpButton selectItemAtIndex:0];

			[_ownerPermissionsPopUpButton selectItemWithTag:[file permissions] & (WCFileOwnerWrite | WCFileOwnerRead)];
			[_groupPermissionsPopUpButton selectItemWithTag:[file permissions] & (WCFileGroupWrite | WCFileGroupRead)];
			[_everyonePermissionsPopUpButton selectItemWithTag:[file permissions] & (WCFileEveryoneWrite | WCFileEveryoneRead)];
		} else {
			[self removeView:&_everyoneTitleTextField];
			[self removeView:&_everyonePermissionsPopUpButton];
			[self removeView:&_groupTitleTextField];
			[self removeView:&_groupPopUpButton];
			[self removeView:&_groupPermissionsPopUpButton];
			[self removeView:&_ownerTitleTextField];
			[self removeView:&_ownerPopUpButton];
			[self removeView:&_ownerPermissionsPopUpButton];
		}
		
		[self resizeTitleTextField:_labelTitleTextField withPopUpButton:_labelPopUpButton];
		[self resizeTitleTextField:_modifiedTitleTextField withTextField:_modifiedTextField];
		[self resizeTitleTextField:_createdTitleTextField withTextField:_createdTextField];
		[self resizeTitleTextField:_whereTitleTextField withTextField:_whereTextField];
		[self resizeTitleTextField:_sizeTitleTextField withTextField:_sizeTextField];
		
		if([file isFolder]) {
			[self resizeTitleTextField:_kindTitleTextField withPopUpButton:_kindPopUpButton];
			[self removeView:&_kindTextField];
		} else {
			[self resizeTitleTextField:_kindTitleTextField withTextField:_kindTextField];
			[self removeView:&_kindPopUpButton];
		}
	} else {
		[_iconImageView setImage:[NSImage imageNamed:@"MultipleItems"]];
		
		folders = files = dropBoxes = 0;
		fileSize = folderSize = 0;
		enumerator = [_info objectEnumerator];
		
		while((file = [enumerator nextObject])) {
			if([file isFolder]) {
				folderSize += [file directoryCount];
				folders++;
				
				if([file type] == WCFileDropBox)
					dropBoxes++;
			} else {
				files++;
				fileSize += [file totalSize];
			}
		}
		
		[_fileTextField setStringValue:[[self class] _stringForFolderCount:files + folders]];
		[_fileTextField setEditable:NO];
		[_fileTextField setBordered:NO];
		[_fileTextField setDrawsBackground:NO];
		[_kindTextField setStringValue:[(WCFile *) [_info lastObject] kind]];
		[_whereTextField setStringValue:[[[_info lastObject] path] stringByDeletingLastPathComponent]];
		
		if(files > 0 && folders > 0) {
			 [_sizeTextField setStringValue:[NSSWF:@"%@, %@",
				[[self class] _stringForFolderCount:folderSize],
				[_sizeFormatter stringFromSize:fileSize]]];
		}
		else if(files > 0) {
			[_sizeTextField setStringValue:[_sizeFormatter stringFromSize:fileSize]];
		}
		else if(folders > 0) {
			[_sizeTextField setStringValue:[[self class] _stringForFolderCount:folderSize]];
		}
		
		[self setYOffset:22.0];
		[self removeView:&_modifiedTextField];
		[self removeView:&_modifiedTitleTextField];
		[self removeView:&_createdTextField];
		[self removeView:&_createdTitleTextField];
		[self removeView:&_commentTextField];
		[self removeView:&_commentTitleTextField];

		if(dropBoxes == 0) {
			[self removeView:&_everyoneTitleTextField];
			[self removeView:&_everyonePermissionsPopUpButton];
			[self removeView:&_groupTitleTextField];
			[self removeView:&_groupPopUpButton];
			[self removeView:&_groupPermissionsPopUpButton];
			[self removeView:&_ownerTitleTextField];
			[self removeView:&_ownerPopUpButton];
			[self removeView:&_ownerPermissionsPopUpButton];
		} else {
			[self resizeTitleTextField:_everyoneTitleTextField withPopUpButton:_everyonePermissionsPopUpButton];
			[self resizeTitleTextField:NULL withPopUpButton:_groupPermissionsPopUpButton];
			[self resizeTitleTextField:_groupTitleTextField withPopUpButton:_groupPopUpButton];
			[self resizeTitleTextField:NULL withPopUpButton:_ownerPermissionsPopUpButton];
			[self resizeTitleTextField:_ownerTitleTextField withPopUpButton:_ownerPopUpButton];
			
			[self _addItemWithTitle:NSLS(@"Don't Change", @"File info popup title")
								tag:-1
				 firstInPopUpButton:_everyonePermissionsPopUpButton];
			[self _addItemWithTitle:NSLS(@"None", @"File info popup title")
								tag:-2
				 firstInPopUpButton:_groupPopUpButton];
			[self _addItemWithTitle:NSLS(@"Don't Change", @"File info popup title")
								tag:-1
				 firstInPopUpButton:_groupPopUpButton];
			[self _addItemWithTitle:NSLS(@"Don't Change", @"File info popup title")
								tag:-1
				 firstInPopUpButton:_groupPermissionsPopUpButton];
			[self _addItemWithTitle:NSLS(@"None", @"File info popup title")
								tag:-2
				 firstInPopUpButton:_ownerPopUpButton];
			[self _addItemWithTitle:NSLS(@"Don't Change", @"File info popup title")
								tag:-1
				 firstInPopUpButton:_ownerPopUpButton];
			[self _addItemWithTitle:NSLS(@"Don't Change", @"File info popup title")
								tag:-1
				 firstInPopUpButton:_ownerPermissionsPopUpButton];
		}

		[self resizeTitleTextField:_labelTitleTextField withPopUpButton:_labelPopUpButton];

		[self _addItemWithTitle:NSLS(@"Don't Change", @"File info popup title")
							tag:-1
			 firstInPopUpButton:_labelPopUpButton];

		[self resizeTitleTextField:_whereTitleTextField withTextField:_whereTextField];
		[self resizeTitleTextField:_sizeTitleTextField withTextField:_sizeTextField];
		
		if(folders == 0) {
			[self removeView:&_kindTextField];
			[self removeView:&_kindTitleTextField];
			[self removeView:&_kindPopUpButton];
		} else {
			[self removeView:&_kindTextField];
			[self resizeTitleTextField:_kindTitleTextField withPopUpButton:_kindPopUpButton];
			
			[self _addItemWithTitle:NSLS(@"Don't Change", @"File info folder type popup title")
								tag:-1
				 firstInPopUpButton:_kindPopUpButton];

			[_kindPopUpButton selectItemAtIndex:0];
		}
	}
	
	offset = [self yOffset];
	rect = [_fileTextField frame];
	rect.origin.y = offset + 20.0;
	[_fileTextField setFrame:rect];
	
	rect = [_iconImageView frame];
	rect.origin.y = offset + 12.0;
	[_iconImageView setFrame:rect];
	
	rect = [[self window] frame];
	height = rect.size.height;
	rect.size.height = offset + 84.0;
	rect.origin.y -= rect.size.height - height;
	[[self window] setFrame:rect display:YES];
	
	[self showWindow:self];
}



- (void)_sendFileInfo {
	NSEnumerator		*enumerator;
	NSString			*parentPath, *path = NULL, *owner, *group;
	WIP7Message			*message;
	WCFile				*file;
	WCFileType			type;
	WCFileLabel			label;
	NSUInteger			ownerPermissions, groupPermissions, everyonePermissions;
	NSInteger			tag;
	BOOL				sentMessage = NO;

	parentPath = [[[_files objectAtIndex:0] path] stringByDeletingLastPathComponent];

	if([[self window] isOnScreen] && [[self connection] isConnected]) {
		enumerator = [_info objectEnumerator];
		
		while((file = [enumerator nextObject])) {
			path = [file path];
			
			if([file isFolder]) {
				type = ([_kindPopUpButton tagOfSelectedItem] >= 0)
					? (WCFileType) [_kindPopUpButton tagOfSelectedItem]
					: [file type];
				
				if(type != [file type]) {
					message = [WIP7Message messageWithName:@"wired.file.set_type" spec:WCP7Spec];
					[message setString:path forName:@"wired.file.path"];
					[message setEnum:type forName:@"wired.file.type"];
					[[self connection] sendMessage:message fromObserver:self selector:@selector(wiredFileSetTypeReply:)];
					
					sentMessage = YES;
				}
			}
			
			if([file type] == WCFileDropBox) {
				tag = [_ownerPopUpButton tagOfSelectedItem];
				owner = (tag >= 0) ? [_ownerPopUpButton titleOfSelectedItem] : (tag == -1) ? [file owner] : @"";
				tag = [_ownerPermissionsPopUpButton tagOfSelectedItem];
				ownerPermissions = (tag >= 0) ? (NSUInteger) tag : [file permissions];
				tag = [_groupPopUpButton tagOfSelectedItem];
				group = (tag >= 0) ? [_groupPopUpButton titleOfSelectedItem] : (tag == -1) ? [file group] : @"";
				tag = [_groupPermissionsPopUpButton tagOfSelectedItem];
				groupPermissions = (tag >= 0) ? (NSUInteger) tag : [file permissions];
				tag = [_everyonePermissionsPopUpButton tagOfSelectedItem];
				everyonePermissions = (tag >= 0) ? (NSUInteger) tag : [file permissions];
				
				if(![owner isEqualToString:[file owner]] || ![group isEqualToString:[file group]] ||
				   (ownerPermissions | groupPermissions | everyonePermissions) != [file permissions]) {
					message = [WIP7Message messageWithName:@"wired.file.set_permissions" spec:WCP7Spec];
					[message setString:path forName:@"wired.file.path"];
					[message setString:owner forName:@"wired.file.owner"];
					[message setBool:(ownerPermissions & WCFileOwnerRead) forName:@"wired.file.owner.read"];
					[message setBool:(ownerPermissions & WCFileOwnerWrite) forName:@"wired.file.owner.write"];
					[message setString:group forName:@"wired.file.group"];
					[message setBool:(groupPermissions & WCFileGroupRead) forName:@"wired.file.group.read"];
					[message setBool:(groupPermissions & WCFileGroupWrite) forName:@"wired.file.group.write"];
					[message setBool:(everyonePermissions & WCFileEveryoneRead) forName:@"wired.file.everyone.read"];
					[message setBool:(everyonePermissions & WCFileEveryoneWrite) forName:@"wired.file.everyone.write"];
					[[self connection] sendMessage:message fromObserver:self selector:@selector(wiredFileSetPermissionsReply:)];
					
					sentMessage = YES;
				}
			}
			
			label = ([_labelPopUpButton tagOfSelectedItem] >= 0)
				? (WCFileLabel) [_labelPopUpButton tagOfSelectedItem]
				: [file label];
			
			if(label != [file label]) {
				message = [WIP7Message messageWithName:@"wired.file.set_label" spec:WCP7Spec];
				[message setString:[file path] forName:@"wired.file.path"];
				[message setEnum:label forName:@"wired.file.label"];
				[[self connection] sendMessage:message fromObserver:self selector:@selector(wiredFileSetLabelReply:)];
					
				sentMessage = YES;
			}
		}
		
		if([_info count] == 1) {
			file = [_info objectAtIndex:0];
			
			if(![[file comment] isEqualToString:[_commentTextField stringValue]]) {
				message = [WIP7Message messageWithName:@"wired.file.set_comment" spec:WCP7Spec];
				[message setString:[file path] forName:@"wired.file.path"];
				[message setString:[_commentTextField stringValue] forName:@"wired.file.comment"];
				[[self connection] sendMessage:message fromObserver:self selector:@selector(wiredFileSetCommentReply:)];
					
				sentMessage = YES;
			}

			if(![[file name] isEqualToString:[_fileTextField stringValue]]) {
				path = [parentPath stringByAppendingPathComponent:[_fileTextField stringValue]];

				message = [WIP7Message messageWithName:@"wired.file.move" spec:WCP7Spec];
				[message setString:[file path] forName:@"wired.file.path"];
				[message setString:path forName:@"wired.file.new_path"];
				[[self connection] sendMessage:message fromObserver:self selector:@selector(wiredFileMoveReply:)];
					
				sentMessage = YES;
			}
		}
	}
	
	if(sentMessage) {
		[self retain];
		
		[self performSelector:@selector(_sendFileInfoTimeout) afterDelay:3.0];
	}
}



- (void)_sendFileInfoTimeout {
	[self autorelease];
}

@end


@implementation WCFileInfo

+ (id)fileInfoWithConnection:(WCServerConnection *)connection file:(WCFile *)file {
	return [[[self alloc] _initFileInfoWithConnection:connection files:[NSArray arrayWithObject:file]] autorelease];
}



+ (id)fileInfoWithConnection:(WCServerConnection *)connection files:(NSArray *)files {
	return [[[self alloc] _initFileInfoWithConnection:connection files:files] autorelease];
}



- (void)dealloc {
	[_files release];
	[_info release];
	[_dateFormatter release];
	[_sizeFormatter release];

	[super dealloc];
}



#pragma mark -

- (void)windowDidLoad {
	NSEnumerator		*enumerator;
	NSMenuItem			*item;
	
	enumerator = [[_kindPopUpButton itemArray] objectEnumerator];
	
	while((item = [enumerator nextObject]))
		[item setImage:[WCFile iconForFolderType:[item tag] width:12.0 open:NO]];
	
	if([_files count] == 1) {
		[[self window] setTitle:[NSSWF:
			NSLS(@"%@ Info", @"File info window title (filename)"), [[_files objectAtIndex:0] name]]];
	} else {
		[[self window] setTitle:
			NSLS(@"Multiple Items Info", @"File info window title for multiple files")];
	}
	
	[self setShouldCascadeWindows:YES];
	[self setShouldSaveWindowFrameOriginOnly:YES];
	[self setWindowFrameAutosaveName:@"FileInfo"];
	
	_dateFormatter = [[WIDateFormatter alloc] init];
	[_dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	[_dateFormatter setDateStyle:NSDateFormatterMediumStyle];
	[_dateFormatter setNaturalLanguageStyle:WIDateFormatterCapitalizedNaturalLanguageStyle];
	
	_sizeFormatter = [[WISizeFormatter alloc] init];
	[_sizeFormatter setAppendsRawNumber:YES];
	
	[_ownerPopUpButton addItemsWithTitles:[[[[self connection] administration] accountsController] userNames]];
	[_groupPopUpButton addItemsWithTitles:[[[[self connection] administration] accountsController] groupNames]];

	[self setDefaultFrame:[_kindTextField frame]];
	
	[super windowDidLoad];
}



- (void)windowWillClose:(NSNotification *)notification {
	[self _sendFileInfo];
}



- (void)controlTextDidChange:(NSNotification *)notification {
	NSControl		*control;
	WCFileType		type;
	
	control = [notification object];
	
	if(control == _fileTextField) {
		type = [WCFile folderTypeForString:[_fileTextField stringValue]];
		
		if(type == WCFileUploads || type == WCFileDropBox)
			[_kindPopUpButton selectItemWithTag:type];
	}
}



- (void)wiredFileGetInfoReply:(WIP7Message *)message {
	NSEnumerator	*enumerator;
	WCFile			*file, *eachFile;

	if([[message name] isEqualToString:@"wired.file.info"]) {
		file = [WCFile fileWithMessage:message connection:[self connection]];
		enumerator = [_files objectEnumerator];

		while((eachFile = [enumerator nextObject])) {
			if([[file path] isEqualToString:[eachFile path]]) {
				[_info addObject:file];
				
				break;
			}
		}
		
		if([_info count] == [_files count])
			[self _showFileInfo];
	}
	else if([[message name] isEqualToString:@"wired.error"]) {
		[[[WCError errorWithWiredMessage:message] alert] runNonModal];
		
		[self close];
	}
}



- (void)wiredFileSetTypeReply:(WIP7Message *)message {
	if([[message name] isEqualToString:@"wired.error"])
		[[[WCError errorWithWiredMessage:message] alert] runNonModal];
}



- (void)wiredFileSetPermissionsReply:(WIP7Message *)message {
	if([[message name] isEqualToString:@"wired.error"])
		[[[WCError errorWithWiredMessage:message] alert] runNonModal];
}



- (void)wiredFileSetLabelReply:(WIP7Message *)message {
	if([[message name] isEqualToString:@"wired.error"])
		[[[WCError errorWithWiredMessage:message] alert] runNonModal];
}



- (void)wiredFileSetCommentReply:(WIP7Message *)message {
	if([[message name] isEqualToString:@"wired.error"])
		[[[WCError errorWithWiredMessage:message] alert] runNonModal];
}



- (void)wiredFileMoveReply:(WIP7Message *)message {
	if([[message name] isEqualToString:@"wired.error"])
		[[[WCError errorWithWiredMessage:message] alert] runNonModal];
}



#pragma mark -

- (void)validate {
	WCAccount	*account;
	BOOL		connected;
	
	connected = [[self connection] isConnected];
	account = [[self connection] account];
	
	[_fileTextField setEnabled:(connected && [account fileRenameFiles])];
	[_kindPopUpButton setEnabled:(connected && [account fileSetType])];
	[_labelPopUpButton setEnabled:(connected && [account fileSetLabel])];
	[_ownerPopUpButton setEnabled:(connected && [account fileSetPermissions])];
	[_ownerPermissionsPopUpButton setEnabled:(connected && [account fileSetPermissions])];
	[_groupPopUpButton setEnabled:(connected && [account fileSetPermissions])];
	[_groupPermissionsPopUpButton setEnabled:(connected && [account fileSetPermissions])];
	[_everyonePermissionsPopUpButton setEnabled:(connected && [account fileSetPermissions])];
	[_commentTextField setEnabled:(connected && [account fileSetComment])];
}

@end
