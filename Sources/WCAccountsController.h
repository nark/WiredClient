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

#import "WCAdministration.h"

extern NSString * const					WCAccountsControllerAccountsDidChangeNotification;

@class WCAccount;

@interface WCAccountsController : WCAdministrationController {
	IBOutlet NSButton					*_allFilterButton;
	IBOutlet NSButton					*_usersFilterButton;
	IBOutlet NSButton					*_groupsFilterButton;
	IBOutlet NSTextField				*_statusTextField;
	IBOutlet NSPopUpButton				*_groupFilterPopUpButton;
	IBOutlet NSMenuItem					*_anyGroupMenuItem;
	IBOutlet NSMenuItem					*_noGroupMenuItem;
	IBOutlet NSSearchField				*_filterSearchField;

	IBOutlet WITableView				*_accountsTableView;
	
	IBOutlet NSButton					*_addButton;
	IBOutlet NSButton					*_deleteButton;
	
	IBOutlet NSTabView					*_accountsTabView;

	IBOutlet NSProgressIndicator		*_progressIndicator;
	IBOutlet NSButton					*_saveButton;

	IBOutlet NSPopUpButton				*_typePopUpButton;
	IBOutlet NSMenuItem					*_userMenuItem;
	IBOutlet NSMenuItem					*_groupMenuItem;

	IBOutlet NSTextField				*_nameTextField;
	IBOutlet NSTextField				*_fullNameTextField;
	IBOutlet NSSecureTextField			*_passwordTextField;
	IBOutlet NSPopUpButton				*_groupPopUpButton;
	IBOutlet NSMenuItem					*_dontChangeGroupMenuItem;
	IBOutlet NSMenuItem					*_noneMenuItem;
	IBOutlet NSTokenField				*_groupsTokenField;
	IBOutlet NSTextView					*_commentTextView;
	IBOutlet NSTextField				*_creationTimeTextField;
	IBOutlet NSTextField				*_modificationTimeTextField;
	IBOutlet NSTextField				*_loginTimeTextField;
	IBOutlet NSTextField				*_editedByTextField;
	IBOutlet NSTextField				*_downloadsTextField;
	IBOutlet NSTextField				*_uploadsTextField;
	
	IBOutlet NSPopUpButton				*_showPopUpButton;
	IBOutlet NSMenuItem					*_allSettingsMenuItem;
	IBOutlet NSMenuItem					*_settingsDefinedAtThisLevelMenuItem;
	IBOutlet NSButton					*_selectAllButton;
    IBOutlet NSButton					*_clearAllButton;
	
	IBOutlet WIOutlineView				*_settingsOutlineView;
	IBOutlet NSTableColumn				*_settingTableColumn;
	IBOutlet NSTableColumn				*_valueTableColumn;
	
	NSArray								*_allSettings;
	NSMutableArray						*_shownSettings;
	
	NSMutableDictionary					*_listedAccounts;
	NSMutableArray						*_allAccounts;
	NSMutableArray						*_allUserAccounts;
	NSMutableArray						*_allGroupAccounts;
	NSMutableArray						*_shownAccounts;
	NSImage								*_userImage;
	NSImage								*_groupImage;
	
	NSMutableArray						*_accounts;
	NSMutableArray						*_selectAccounts;

	BOOL								_requested;
	BOOL								_creating;
	BOOL								_editing;
	BOOL								_touched;
	BOOL								_saving;
	
	NSUInteger							_requestedAccounts;

	NSString							*_accountFilter;
	WIDateFormatter						*_dateFormatter;
	WISizeFormatter						*_sizeFormatter;
	
	NSMutableDictionary					*_deletedAccounts;
}

- (void)wiredAccountListAccountsReply:(WIP7Message *)message;
- (void)wiredAccountSubscribeAccountsReply:(WIP7Message *)message;
- (void)saveSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
- (void)wiredAccountChangeAccountReply:(WIP7Message *)message;
- (void)wiredAccountReadAccountReply:(WIP7Message *)message;


- (NSString *)newDocumentMenuItemTitle;
- (NSString *)deleteDocumentMenuItemTitle;

- (NSArray *)userNames;
- (NSArray *)groupNames;
- (void)editUserAccountWithName:(NSString *)name;

- (IBAction)newDocument:(id)sender;
- (IBAction)deleteDocument:(id)sender;
- (IBAction)touch:(id)sender;
- (IBAction)addAccount:(id)sender;
- (IBAction)deleteAccount:(id)sender;
- (IBAction)duplicateAccount:(id)sender;
- (IBAction)all:(id)sender;
- (IBAction)users:(id)sender;
- (IBAction)groups:(id)sender;
- (IBAction)groupFilter:(id)sender;
- (IBAction)search:(id)sender;
- (IBAction)type:(id)sender;
- (IBAction)group:(id)sender;
- (IBAction)show:(id)sender;
- (IBAction)selectAll:(id)sender;
- (IBAction)clearSetting:(id)sender;
- (IBAction)save:(id)sender;

@end


@interface WCAccountsTableColumn : NSTableColumn

@end
