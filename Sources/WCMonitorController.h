/* $Id$ */

/*
 *  Copyright (c) 2008-2009 Axel Andersson
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

#import "WCAdministration.h"

@interface WCMonitorController : WCAdministrationController {
	IBOutlet NSButton					*_allFilterButton;
	IBOutlet NSButton					*_downloadingFilterButton;
	IBOutlet NSButton					*_uploadingFilterButton;
	IBOutlet NSTextField				*_downloadSpeedTextField;
	IBOutlet NSTextField				*_uploadSpeedTextField;
	IBOutlet NSButton					*_disconnectButton;
	IBOutlet NSSearchField				*_filterSearchField;

	IBOutlet WITableView				*_usersTableView;
	IBOutlet NSTableColumn				*_iconTableColumn;
	IBOutlet NSTableColumn				*_nickTableColumn;
	IBOutlet NSTableColumn				*_statusTableColumn;
	IBOutlet NSTableColumn				*_userInfoTableColumn;
    
	IBOutlet NSPanel					*_disconnectMessagePanel;
	IBOutlet NSTextField				*_disconnectMessageTextField;
	
	NSMutableArray						*_listedUsers;
	NSMutableArray						*_allUsers;
	NSMutableArray						*_shownUsers;

	NSString							*_userFilter;
	WIDateFormatter						*_dateFormatter;
	WISizeFormatter						*_sizeFormatter;
	WITimeIntervalFormatter				*_timeIntervalFormatter;

	BOOL								_error;
}

- (void)wiredUserGetUsersReply:(WIP7Message *)message;

- (IBAction)all:(id)sender;
- (IBAction)downloading:(id)sender;
- (IBAction)uploading:(id)sender;

- (IBAction)disconnect:(id)sender;
- (IBAction)search:(id)sender;

- (IBAction)getInfo:(id)sender;
- (IBAction)revealInFiles:(id)sender;

@end
