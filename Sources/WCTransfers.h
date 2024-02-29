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

extern NSString * const WCTransfersQueueUpdatedNotification;

@class WCErrorQueue, WCFile, WCTransfer;
 
@interface WCTransfers : WIWindowController <NSToolbarDelegate, NSComboBoxDataSource, NSComboBoxDelegate> {
	IBOutlet WITableView					*_transfersTableView;
	IBOutlet NSTableColumn					*_iconTableColumn;
	IBOutlet NSTableColumn					*_infoTableColumn;
	
	IBOutlet NSButton						*_startButton;
	IBOutlet NSButton						*_pauseButton;
	IBOutlet NSButton						*_stopButton;
	IBOutlet NSButton						*_removeButton;
	IBOutlet NSButton						*_clearButton;
	IBOutlet NSButton						*_connectButton;
	IBOutlet NSButton						*_quickLookButton;
	IBOutlet NSButton						*_revealInFinderButton;
	IBOutlet NSButton						*_revealInFilesButton;
	
	WCErrorQueue							*_errorQueue;

	NSMutableArray							*_transfers;
	NSMutableArray							*_quickLookTransfers;

	NSImage									*_folderImage;
	NSTimer									*_timer;
	NSLock									*_lock;
	
	WISizeFormatter							*_sizeFormatter;
	WITimeIntervalFormatter					*_timeIntervalFormatter;
	
	Class									_quickLookPanelClass;
}

- (void)wiredTransferUploadDirectoryReply:(WIP7Message *)message;
- (void)transferThread:(id)arg;
- (void)wiredFileListPathReply:(WIP7Message *)message;

+ (id)transfers;

+ (BOOL)downloadFileAtPath:(NSString *)path forConnection:(WCServerConnection *)connection;

- (NSString *)deleteDocumentMenuItemTitle;
- (NSString *)quickLookMenuItemTitle;

- (NSInteger)numberOfUncompleteTransfers;

- (BOOL)addTransferAtPath:(NSString *)path;
- (BOOL)downloadFiles:(NSArray *)files;
- (BOOL)downloadFiles:(NSArray *)files toFolder:(NSString *)destination;
- (BOOL)uploadPaths:(NSArray *)paths toFolder:(WCFile *)destination;

- (IBAction)deleteDocument:(id)sender;
- (IBAction)start:(id)sender;
- (IBAction)pause:(id)sender;
- (IBAction)stop:(id)sender;
- (IBAction)remove:(id)sender;
- (IBAction)clear:(id)sender;
- (IBAction)connect:(id)sender;
- (IBAction)quickLook:(id)sender;
- (IBAction)revealInFinder:(id)sender;
- (IBAction)revealInFiles:(id)sender;

@end
