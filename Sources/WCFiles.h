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

extern NSString * const					WCFilePboardType;
extern NSString * const					WCPlacePboardType;


@class WCFilterView, WCFile, WCErrorQueue;

@interface WCFiles : WIWindowController <NSToolbarDelegate, NSComboBoxDelegate, NSComboBoxDataSource> {
	IBOutlet NSSegmentedControl			*_historyControl;
	IBOutlet NSSegmentedControl			*_styleControl;
	IBOutlet NSButton					*_downloadButton;
	IBOutlet NSButton					*_uploadButton;
	IBOutlet NSButton					*_infoButton;
	IBOutlet NSButton					*_quickLookButton;
	IBOutlet NSButton					*_createFolderButton;
	IBOutlet NSButton					*_reloadButton;
	IBOutlet NSButton					*_deleteButton;
	IBOutlet NSSearchField				*_searchField;
	
	IBOutlet WCFilterView				*_searchBarView;
	IBOutlet NSButton					*_thisServerButton;
	IBOutlet NSButton					*_allServersButton;
	
	IBOutlet WIOutlineView				*_sourceOutlineView;
	IBOutlet NSTableColumn				*_sourceTableColumn;

	IBOutlet NSTabView					*_filesTabView;

	IBOutlet NSScrollView				*_filesScrollView;
	IBOutlet WIOutlineView				*_filesOutlineView;
	IBOutlet NSTableColumn				*_nameTableColumn;
	IBOutlet NSTableColumn				*_kindTableColumn;
	IBOutlet NSTableColumn				*_createdTableColumn;
	IBOutlet NSTableColumn				*_modifiedTableColumn;
	IBOutlet NSTableColumn				*_sizeTableColumn;
	IBOutlet NSTableColumn				*_serverTableColumn;

	IBOutlet WITreeView					*_filesTreeView;
	
	IBOutlet NSTextField				*_statusTextField;
	IBOutlet NSProgressIndicator		*_progressIndicator;
	
	IBOutlet NSPanel					*_createFolderPanel;
	IBOutlet NSTextField				*_nameTextField;
	IBOutlet NSPopUpButton				*_typePopUpButton;
	IBOutlet NSPopUpButton				*_ownerPopUpButton;
	IBOutlet NSPopUpButton				*_ownerPermissionsPopUpButton;
	IBOutlet NSPopUpButton				*_groupPopUpButton;
	IBOutlet NSPopUpButton				*_groupPermissionsPopUpButton;
	IBOutlet NSPopUpButton				*_everyonePermissionsPopUpButton;
	IBOutlet NSProgressIndicator		*_permissionsProgressIndicator;

	WCErrorQueue						*_errorQueue;
	
	NSMutableDictionary					*_directories;
	NSMutableDictionary					*_files;
	NSMutableArray						*_servers;
	NSMutableArray						*_places;
	NSMutableArray						*_quickLookFiles;
	NSMutableArray						*_selectFiles;
	BOOL								_selectFilesWhenOpening;
	
	BOOL								_searching;
	NSUInteger							_styleBeforeSearch;
	WCFile								*_directoryBeforeSearch;
	NSMutableSet						*_searchTransactions;
	
	NSMutableArray						*_history;
	NSUInteger							_historyPosition;
	
	NSMutableSet						*_subscribedFiles;
	
	WCFile								*_initialDirectory;
	WCFile								*_currentDirectory;
	BOOL								_currentDirectoryDeleted;
	
	WIDateFormatter						*_dateFormatter;
	WISizeFormatter						*_sizeFormatter;
	
	NSMutableParagraphStyle				*_truncatingTailParagraphStyle;
	
	Class								_quickLookPanelClass;
	
	CGFloat								_iconWidth;
}

- (void)wiredFilePreviewFileReply:(WIP7Message *)message;
- (void)wiredFileSubscribeDirectoryReply:(WIP7Message *)message;
+ (id)filesWithConnection:(WCServerConnection *)connection file:(WCFile *)file;
+ (id)filesWithConnection:(WCServerConnection *)connection file:(WCFile *)file selectFile:(WCFile *)selectFile;
- (void)accountsControllerAccountsDidChange:(NSNotification *)notification;
- (void)wiredFileDirectoryChanged:(WIP7Message *)message;
- (void)wiredFileDirectoryDeleted:(WIP7Message *)message;
- (void)selectedThemeDidChange:(NSNotification *)notification;
- (void)wiredFileUnsubscribeDirectoryReply:(WIP7Message *)message;
- (void)wiredFileSearchListReply:(WIP7Message *)message;

- (NSString *)newDocumentMenuItemTitle;
- (NSString *)deleteDocumentMenuItemTitle;
- (NSString *)reloadDocumentMenuItemTitle;
- (NSString *)quickLookMenuItemTitle;

- (IBAction)open:(id)sender;
- (IBAction)enclosingFolder:(id)sender;
- (IBAction)label:(id)sender;

- (IBAction)history:(id)sender;
- (IBAction)style:(id)sender;
- (IBAction)download:(id)sender;
- (IBAction)upload:(id)sender;
- (IBAction)getInfo:(id)sender;
- (IBAction)copyInternalURL:(id)sender;
- (IBAction)copyExternalURL:(id)sender;
- (IBAction)copyPath:(id)sender;
- (IBAction)quickLook:(id)sender;
- (IBAction)newDocument:(id)sender;
- (IBAction)createFolder:(id)sender;
- (IBAction)type:(id)sender;
- (IBAction)reloadDocument:(id)sender;
- (IBAction)reload:(id)sender;
- (IBAction)deleteDocument:(id)sender;
- (IBAction)delete:(id)sender;
- (IBAction)search:(id)sender;

- (IBAction)thisServer:(id)sender;
- (IBAction)allServers:(id)sender;

@end
