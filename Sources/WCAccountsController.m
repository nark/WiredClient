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
#import "WCApplicationController.h"
#import "WCServerConnection.h"
#import "WCUser.h"

#define	WCAccountsFieldCell											@"WCAccountsFieldCell"
#define	WCAccountsFieldSettings										@"WCAccountsFieldSettings"


NSString * const WCAccountsControllerAccountsDidChangeNotification	= @"WCAccountsControllerAccountsDidChangeNotification";


enum _WCAccountsAction {
	WCAccountsDoNothing,
	WCAccountsCloseWindow,
	WCAccountsSelectTab,
	WCAccountsSelectRow
};
typedef enum _WCAccountsAction										WCAccountsAction;


@interface WCAccountsController(Private)

- (void)_validate;
- (BOOL)_validateAddAccount;
- (BOOL)_validateDeleteAccount;
- (BOOL)_validateDuplicateAccount;

- (void)_requestAccounts;

- (NSDictionary *)_settingForRow:(NSInteger)row;

- (BOOL)_verifyUnsavedAndPerformAction:(WCAccountsAction)action argument:(id)argument;
- (void)_save;
- (BOOL)_canEditAccounts;

- (void)_readAccount:(WCAccount *)account;
- (void)_readAccounts:(NSArray *)accounts;
- (void)_readFromAccounts;
- (void)_validateForAccounts;
- (void)_writeToAccounts:(NSArray *)accounts;

- (WCAccount *)_accountAtIndex:(NSUInteger)index;
- (NSArray *)_selectedAccounts;
- (void)_reloadGroups;
- (void)_reloadSettings;
- (BOOL)_filterIncludesAccount:(WCAccount *)account;
- (void)_reloadFilter;
- (void)_selectAccounts;

@end


@implementation WCAccountsController(Private)

- (void)_validate {
	WCAccount	*account;
	BOOL		save = NO;

	[_addButton setEnabled:[self _validateAddAccount]];
	[_deleteButton setEnabled:[self _validateDeleteAccount]];

	if(_touched && [[_administration connection] isConnected]) {
		account = [[_administration connection] account];
	
		if(_creating && ([account accountCreateUsers] || [account accountCreateGroups]))
			save = YES;
		else if(_editing && ([account accountEditUsers] || [account accountEditGroups]))
			save = YES;
	}

	[_saveButton setEnabled:save];
}

- (BOOL)_validateAddAccount {
	WCAccount		*account;
	
	if(![_administration connection] || ![[_administration connection] isConnected])
		return NO;
	
	account = [[_administration connection] account];

	return ([account accountCreateUsers] || [account accountCreateGroups]);
}

- (BOOL)_validateDeleteAccount {
	NSEnumerator	*enumerator;
	NSArray			*accounts;
	WCAccount		*account, *selectedAccount;
	
	if(![_administration connection] || ![[_administration connection] isConnected])
		return NO;
	
	accounts = [self _selectedAccounts];
	
	if([accounts count] == 0)
		return NO;
	
	account = [[_administration connection] account];
	
	if([account accountDeleteUsers] && [account accountDeleteGroups])
		return YES;

	if([account accountDeleteUsers] || [account accountDeleteGroups]) {
		enumerator = [accounts objectEnumerator];
		
		while((selectedAccount = [enumerator nextObject])) {
			if([selectedAccount isKindOfClass:[WCUserAccount class]] && ![account accountDeleteUsers])
				return NO;
			else if([selectedAccount isKindOfClass:[WCGroupAccount class]] && ![account accountDeleteGroups])
				return NO;
		}
		
		return YES;
	}
	
	return NO;
}

- (BOOL)_validateDuplicateAccount {
	NSArray			*accounts;
	WCAccount		*account;
	
	if(![_administration connection] || ![[_administration connection] isConnected])
		return NO;
	
	accounts = [self _selectedAccounts];
	
	if([accounts count] != 1)
		return NO;

	account = [[_administration connection] account];
	
	if([[accounts objectAtIndex:0] isKindOfClass:[WCUserAccount class]])
		return [account accountCreateUsers];
	else
		return [account accountCreateGroups];
}

#pragma mark -

- (void)_requestAccounts {
	WIP7Message		*message;
	
	if(!_requested && [[_administration connection] isConnected] && [[[_administration connection] account] accountListAccounts]) {
		[_progressIndicator startAnimation:self];

		[_allAccounts removeAllObjects];
		[_allUserAccounts removeAllObjects];
		[_allGroupAccounts removeAllObjects];
		[_shownAccounts removeAllObjects];

		[_accountsTableView reloadData];

		message = [WIP7Message messageWithName:@"wired.account.list_users" spec:WCP7Spec];
		[[_administration connection] sendMessage:message fromObserver:self selector:@selector(wiredAccountListAccountsReply:)];

		message = [WIP7Message messageWithName:@"wired.account.list_groups" spec:WCP7Spec];
		[[_administration connection] sendMessage:message fromObserver:self selector:@selector(wiredAccountListAccountsReply:)];
		
		message = [WIP7Message messageWithName:@"wired.account.subscribe_accounts" spec:WCP7Spec];
		[[_administration connection] sendMessage:message fromObserver:self selector:@selector(wiredAccountSubscribeAccountsReply:)];
		
		_requested = YES;
	}
}

- (void)_reloadAccounts {
	WIP7Message		*message;
	
	if([[_administration connection] isConnected] && [[[_administration connection] account] accountListAccounts]) {
		[_progressIndicator startAnimation:self];
		
		[_allAccounts removeAllObjects];
		[_allUserAccounts removeAllObjects];
		[_allGroupAccounts removeAllObjects];
		[_shownAccounts removeAllObjects];
		
		[_accountsTableView reloadData];
		
		message = [WIP7Message messageWithName:@"wired.account.list_users" spec:WCP7Spec];
		[[_administration connection] sendMessage:message fromObserver:self selector:@selector(wiredAccountListAccountsReply:)];
		
		message = [WIP7Message messageWithName:@"wired.account.list_groups" spec:WCP7Spec];
		[[_administration connection] sendMessage:message fromObserver:self selector:@selector(wiredAccountListAccountsReply:)];
	}
}

#pragma mark -

- (NSDictionary *)_settingForRow:(NSInteger)row {
	return [_shownSettings objectAtIndex:row];
}

#pragma mark -

- (BOOL)_verifyUnsavedAndPerformAction:(WCAccountsAction)action argument:(id)argument {
	NSMutableDictionary		*dictionary;
	NSAlert					*alert;
	
	if(_touched && !_saving) {
		_saving = YES;
		
		dictionary = [[NSMutableDictionary alloc] init];
					  
		[dictionary setObject:[NSNumber numberWithInteger:action] forKey:@"WCAccountsAction"];
		
		if(argument)
			[dictionary setObject:argument forKey:@"WCAccountsArgument"];
		
		alert = [[NSAlert alloc] init];
		
		if([_accounts count] == 1) {
			[alert setMessageText:[NSSWF:
				NSLS(@"Save changes to the \u201c%@\u201d account?", @"Save account dialog title (name)"),
				[_nameTextField stringValue]]];
		} else {
			[alert setMessageText:[NSSWF:
				NSLS(@"Save changes to %u accounts?", @"Save account dialog title (count)"),
				[_accounts count]]];
		}
		
		[alert setInformativeText:NSLS(@"If you don't save the changes, they will be lost.", @"Save account dialog description")];
		[alert addButtonWithTitle:NSLS(@"Save", @"Save account dialog button")];
		[alert addButtonWithTitle:NSLS(@"Cancel", @"Save account dialog button")];
		[alert addButtonWithTitle:NSLS(@"Don't Save", @"Save account dialog button")];
		[alert beginSheetModalForWindow:[_administration window]
						  modalDelegate:self
						 didEndSelector:@selector(saveSheetDidEnd:returnCode:contextInfo:)
							contextInfo:dictionary];
		[alert release];
		
		return NO;
	}
	
	return YES;
}

- (void)_save {
	NSEnumerator		*enumerator;
	WCAccount			*account;
	BOOL				reload = YES;
	
	_touched = NO;
	
	if(_creating) {
		if([_typePopUpButton selectedItem] == _userMenuItem)
			account = [WCUserAccount account];
		else
			account = [WCGroupAccount account];
		
		[account setValues:[[_accounts lastObject] values]];

		[self _writeToAccounts:[NSArray arrayWithObject:account]];
		
		[[_administration connection] sendMessage:[account createAccountMessage]
									 fromObserver:self
										 selector:@selector(wiredAccountChangeAccountReply:)];

		[_selectAccounts setArray:[NSArray arrayWithObject:account]];
		
		reload = NO;
	} else {
		[self _writeToAccounts:_accounts];
			
		if([_accounts count] == 1) {
			account = [_accounts lastObject];
			
			[[_administration connection] sendMessage:[account editAccountMessage]
										 fromObserver:self
											 selector:@selector(wiredAccountChangeAccountReply:)];
			
			if(![[account newName] isEqualToString:[account name]])
				reload = NO;
		} else {
			enumerator = [_accounts objectEnumerator];
		
			while((account = [enumerator nextObject])) {
                
				[[_administration connection] sendMessage:[account editAccountMessage]
											 fromObserver:self
												 selector:@selector(wiredAccountChangeAccountReply:)];
			}
		}

		[_selectAccounts setArray:_accounts];
	}
}

- (BOOL)_canEditAccounts {
	NSEnumerator	*enumerator;
	WCAccount		*account;
	BOOL			user, group, editable;
	
	user		= NO;
	group		= NO;
	enumerator	= [_accounts objectEnumerator];
	
	while((account = [enumerator nextObject])) {
		if([account isKindOfClass:[WCUserAccount class]] || (_creating && [_typePopUpButton selectedItem] == _userMenuItem))
			user = YES;
		else if([account isKindOfClass:[WCGroupAccount class]] || (_creating && [_typePopUpButton selectedItem] == _groupMenuItem))
			group = YES;
	}
	
	editable	= YES;
	account		= [[_administration connection] account];
	
	if(user) {
		if(_creating && ![account accountCreateUsers])
			editable = NO;
		else if(_editing && ![account accountEditUsers])
			editable = NO;
	}
	
	if(group) {
		if(_creating && ![account accountCreateGroups])
			editable = NO;
		else if(_editing && ![account accountEditGroups])
			editable = NO;
	}
	
	return editable;
}

#pragma mark -

- (void)_readAccount:(WCAccount *)account {
	WIP7Message		*message;
	
	if([account isKindOfClass:[WCUserAccount class]])
		message = [WIP7Message messageWithName:@"wired.account.read_user" spec:WCP7Spec];
	else
		message = [WIP7Message messageWithName:@"wired.account.read_group" spec:WCP7Spec];

	[message setString:[account name] forName:@"wired.account.name"];
	[[_administration connection] sendMessage:message fromObserver:self selector:@selector(wiredAccountReadAccountReply:)];
	
	[_progressIndicator startAnimation:self];
}

- (void)_readAccounts:(NSArray *)accounts {
	NSEnumerator	*enumerator;
	WCAccount		*account;
	
	[_accounts removeAllObjects];
	
	_requestedAccounts = [accounts count];
	
	enumerator = [accounts objectEnumerator];
	
	while((account = [enumerator nextObject]))
		[self _readAccount:account];
}

- (void)_readFromAccounts {
	NSEnumerator		*enumerator;
	NSDictionary		*section;
	NSArray				*groups;
	NSString			*group;
	WCAccount			*account;
	
	if([_accounts count] == 1) {
		if([_groupPopUpButton indexOfItem:_dontChangeGroupMenuItem] != -1)
			[_groupPopUpButton removeItem:_dontChangeGroupMenuItem];
		
		account = [_accounts lastObject];

		if(_editing) {
			if([account isKindOfClass:[WCUserAccount class]]) {
				[_typePopUpButton selectItem:_userMenuItem];
				
				if([(WCUserAccount *) account fullName])
					[_fullNameTextField setStringValue:[(WCUserAccount *) account fullName]];
				else
					[_fullNameTextField setStringValue:@""];
				
				if([(WCUserAccount *) account password] && ![[(WCUserAccount *) account password] isEqualToString:[@"" SHA1]])
					[_passwordTextField setStringValue:[(WCUserAccount *) account password]];
				else
					[_passwordTextField setStringValue:@""];
				
				if([[(WCUserAccount *) account group] length] > 0)
					[_groupPopUpButton selectItemWithTitle:[(WCUserAccount *) account group]];
				else
					[_groupPopUpButton selectItem:_noneMenuItem];
				
				if([(WCUserAccount *) account groups])
					[_groupsTokenField setStringValue:[[(WCUserAccount *) account groups] componentsJoinedByString:@","]];
				else
					[_groupsTokenField setStringValue:@""];
		
				if([(WCUserAccount *) account loginDate] && ![[(WCUserAccount *) account loginDate] isAtBeginningOfAnyEpoch])
					[_loginTimeTextField setStringValue:[_dateFormatter stringFromDate:[(WCUserAccount *) account loginDate]]];
				else
					[_loginTimeTextField setStringValue:@""];
				
				[_downloadsTextField setStringValue:[NSSWF:NSLS(@"%u completed, %@ transferred", @"Account transfer stats (count, transferred"),
					[(WCUserAccount *) account downloads],
					[_sizeFormatter stringFromSize:[(WCUserAccount *) account downloadTransferred]]]];
				
				[_uploadsTextField setStringValue:[NSSWF:NSLS(@"%u completed, %@ transferred", @"Account transfer stats (count, transferred"),
					[(WCUserAccount *) account uploads],
					[_sizeFormatter stringFromSize:[(WCUserAccount *) account uploadTransferred]]]];
			}
			else if([account isKindOfClass:[WCGroupAccount class]]) {
				[_typePopUpButton selectItem:_groupMenuItem];
				[_fullNameTextField setStringValue:@""];
				[_passwordTextField setStringValue:@""];
				[_groupPopUpButton selectItem:_noneMenuItem];
				[_groupsTokenField setStringValue:@""];
				[_loginTimeTextField setStringValue:@""];
				[_downloadsTextField setStringValue:@""];
				[_uploadsTextField setStringValue:@""];
			}
			
			[_nameTextField setStringValue:[account name]];
			[_commentTextView setString:[account comment]];

			if([account creationDate] && ![[account creationDate] isAtBeginningOfAnyEpoch])
				[_creationTimeTextField setStringValue:[_dateFormatter stringFromDate:[account creationDate]]];
			else
				[_creationTimeTextField setStringValue:@""];

			if([account modificationDate] && ![[account modificationDate] isAtBeginningOfAnyEpoch])
				[_modificationTimeTextField setStringValue:[_dateFormatter stringFromDate:[account modificationDate]]];
			else
				[_modificationTimeTextField setStringValue:@""];

			if([account editedBy])
				[_editedByTextField setStringValue:[account editedBy]];
			else
				[_editedByTextField setStringValue:@""];
		}
	}
	else if([_accounts count] == 0) {
		if([_groupPopUpButton indexOfItem:_dontChangeGroupMenuItem] != -1)
			[_groupPopUpButton removeItem:_dontChangeGroupMenuItem];
		
		[_typePopUpButton selectItem:_userMenuItem];
		[_nameTextField setStringValue:@""];
		[_fullNameTextField setStringValue:@""];
		[_passwordTextField setStringValue:@""];
		[_groupPopUpButton selectItem:_noneMenuItem];
		[_groupsTokenField setStringValue:@""];
		[_commentTextView setString:@""];
		[_creationTimeTextField setStringValue:@""];
		[_modificationTimeTextField setStringValue:@""];
		[_loginTimeTextField setStringValue:@""];
		[_editedByTextField setStringValue:@""];
		[_downloadsTextField setStringValue:@""];
		[_uploadsTextField setStringValue:@""];
	}
	else {
		if([_groupPopUpButton indexOfItem:_dontChangeGroupMenuItem] == -1) {
			[_groupPopUpButton insertItem:_dontChangeGroupMenuItem atIndex:0];
			
			[_dontChangeGroupMenuItem setState:NSOffState];
		}
		
		group			= NULL;
		enumerator		= [_accounts objectEnumerator];
		
		while((account = [enumerator nextObject])) {
			if(group) {
				if(![account isKindOfClass:[WCUserAccount class]] || ![group isEqualToString:[(WCUserAccount *) account group]]) {
					group = NULL;
					
					break;
				}
			} else {
				if([account isKindOfClass:[WCUserAccount class]])
					group = [(WCUserAccount *) account group];
			}
		}
		
		groups			= NULL;
		enumerator		= [_accounts objectEnumerator];
		
		while((account = [enumerator nextObject])) {
			if(groups) {
				if(![account isKindOfClass:[WCUserAccount class]] || ![groups isEqualToArray:[(WCUserAccount *) account groups]]) {
					groups = NULL;
					
					break;
				}
			} else {
				if([account isKindOfClass:[WCUserAccount class]])
					groups = [(WCUserAccount *) account groups];
			}
		}
		
		[_typePopUpButton selectItem:_userMenuItem];
		[_nameTextField setStringValue:@""];
		[_fullNameTextField setStringValue:@""];
		[_passwordTextField setStringValue:@""];
		
		if(group == NULL)
			[_groupPopUpButton selectItem:_dontChangeGroupMenuItem];
		else if([group length] == 0)
			[_groupPopUpButton selectItem:_noneMenuItem];
		else
			[_groupPopUpButton selectItemWithTitle:group];
		
		if(groups == NULL)
			[_groupsTokenField setStringValue:NSLS(@"<Multiple values>", @"Account field value")];
		else
			[_groupsTokenField setStringValue:[groups componentsJoinedByString:@","]];
		
		[_commentTextView setString:@""];
		[_creationTimeTextField setStringValue:@""];
		[_modificationTimeTextField setStringValue:@""];
		[_loginTimeTextField setStringValue:@""];
		[_editedByTextField setStringValue:@""];
		[_downloadsTextField setStringValue:@""];
		[_uploadsTextField setStringValue:@""];
	}
	
	[self _reloadSettings];
	
	[_settingsOutlineView reloadData];

	enumerator = [_shownSettings objectEnumerator];
	
	while((section = [enumerator nextObject]))
		[_settingsOutlineView expandItem:section];
}

- (void)_validateForAccounts {
	NSEnumerator	*enumerator;
	WCAccount		*account;
	BOOL			editable, group;
	
	[_userMenuItem setEnabled:[[[_administration connection] account] accountCreateUsers]];
	[_groupMenuItem setEnabled:[[[_administration connection] account] accountCreateGroups]];
	
	if([_accounts count] == 1) {
		account		= [_accounts lastObject];
		editable	= [self _canEditAccounts];
		
		[_typePopUpButton setEnabled:(_creating && editable)];
		[_nameTextField setEnabled:editable];
		
		if([account isKindOfClass:[WCUserAccount class]] || (_creating && [_typePopUpButton selectedItem] == _userMenuItem)) {
			[_fullNameTextField setEnabled:editable];
			[_passwordTextField setEnabled:editable];
			[_groupPopUpButton setEnabled:editable];
			[_groupsTokenField setEnabled:editable];
		}
		else if([account isKindOfClass:[WCGroupAccount class]] || (_creating && [_typePopUpButton selectedItem] == _groupMenuItem)) {
			[_fullNameTextField setEnabled:NO];
			[_passwordTextField setEnabled:NO];
			[_groupPopUpButton setEnabled:NO];
			[_groupsTokenField setEnabled:NO];
		}

		[_commentTextView setEditable:editable];
		[_selectAllButton setEnabled:YES];
        [_clearAllButton setEnabled:YES];
	}
	else if([_accounts count] == 0) {
		[_typePopUpButton setEnabled:NO];
		[_nameTextField setEnabled:NO];
		[_fullNameTextField setEnabled:NO];
		[_passwordTextField setEnabled:NO];
		[_groupPopUpButton setEnabled:NO];
		[_groupsTokenField setEnabled:NO];
		[_commentTextView setEditable:NO];
		[_selectAllButton setEnabled:NO];
        [_clearAllButton setEnabled:NO];
	}
	else {
		group			= NO;
		enumerator		= [_accounts objectEnumerator];
		
		while((account = [enumerator nextObject])) {
			if([account isKindOfClass:[WCGroupAccount class]])
				group = YES;
		}
		
		[_typePopUpButton setEnabled:NO];
		[_nameTextField setEnabled:NO];
		[_fullNameTextField setEnabled:NO];
		[_passwordTextField setEnabled:NO];
		[_groupPopUpButton setEnabled:!group];
		[_groupsTokenField setEnabled:!group];
		[_commentTextView setEditable:NO];
		[_selectAllButton setEnabled:YES];
        [_clearAllButton setEnabled:YES];
	}
	
	[_settingsOutlineView setNeedsDisplay:YES];
}

- (void)_writeToAccounts:(NSArray *)accounts {
	NSEnumerator	*enumerator;
	NSString		*password, *group;
	NSArray			*groups;
	WCAccount		*account;
	
	if([accounts count] == 1) {
		account = [accounts lastObject];
		
		if(_editing)
			[account setNewName:[_nameTextField stringValue]];
		else
			[account setName:[_nameTextField stringValue]];
		
		[account setComment:[_commentTextView string]];
		
		if([account isKindOfClass:[WCUserAccount class]]) {
			[(WCUserAccount *) account setFullName:[_fullNameTextField stringValue]];

			if([[_passwordTextField stringValue] isEqualToString:@""])
				password = [@"" SHA1];
			else if(![[(WCUserAccount *) account password] isEqualToString:[_passwordTextField stringValue]])
				password = [[_passwordTextField stringValue] SHA1];
			else
				password = [(WCUserAccount *) account password];
			
			[(WCUserAccount *) account setPassword:password];
			
			if([_groupPopUpButton selectedItem] != _noneMenuItem)
				group = [_groupPopUpButton titleOfSelectedItem];
			else
				group = @"";
			
			[(WCUserAccount *) account setGroup:group];

			groups = [[_groupsTokenField stringValue] componentsSeparatedByCharactersFromSet:
				[_groupsTokenField tokenizingCharacterSet]];
			
			if(!groups)
				groups = [NSArray array];

			[(WCUserAccount *) account setGroups:groups];
		}
	} else {
		enumerator = [accounts objectEnumerator];
		
		while((account = [enumerator nextObject])) {
			if([account isKindOfClass:[WCUserAccount class]]) {
				if([_groupPopUpButton selectedItem] != _dontChangeGroupMenuItem) {
					if([_groupPopUpButton selectedItem] != _noneMenuItem)
						group = [_groupPopUpButton titleOfSelectedItem];
					else
						group = @"";
					
					[(WCUserAccount *) account setGroup:group];
				}
				
				if(![[_groupsTokenField stringValue] isEqualToString:NSLS(@"<Multiple values>", @"Account field value")]) {
					groups = [[_groupsTokenField stringValue] componentsSeparatedByCharactersFromSet:
						[_groupsTokenField tokenizingCharacterSet]];
					
					if(!groups)
						groups = [NSArray array];
				
					[(WCUserAccount *) account setGroups:groups];
				}
			}
		}
	}
}

#pragma mark -

- (WCAccount *)_accountAtIndex:(NSUInteger)index {
	NSUInteger		i;
	
	i = ([_accountsTableView sortOrder] == WISortDescending)
		? [_shownAccounts count] - index - 1
		: index;
	
	return [_shownAccounts objectAtIndex:i];
}

- (NSArray *)_selectedAccounts {
	NSMutableArray		*array;
	NSIndexSet			*indexes;
	NSUInteger			index;
	
	array		= [NSMutableArray array];
	indexes		= [_accountsTableView selectedRowIndexes];
	index		= [indexes firstIndex];
	
	while(index != NSNotFound) {
		[array addObject:[self _accountAtIndex:index]];
		
		index = [indexes indexGreaterThanIndex:index];
	}
	
	return array;
}

- (void)_reloadGroups {
	NSEnumerator		*enumerator;
	NSMutableArray		*groupAccounts;
	WCAccount			*account;
	NSUInteger			count;
	
	count = ([_groupPopUpButton indexOfItem:_dontChangeGroupMenuItem] == -1) ? 1 : 2;
	
	while([_groupPopUpButton numberOfItems] > (NSInteger) count)
		[_groupPopUpButton removeItemAtIndex:count];
	
	while([_groupFilterPopUpButton numberOfItems] > 2)
		[_groupFilterPopUpButton removeItemAtIndex:2];

	groupAccounts	= [NSMutableArray array];
	enumerator		= [_allAccounts objectEnumerator];
	
	while((account = [enumerator nextObject])) {
		if([account isKindOfClass:[WCGroupAccount class]])
			[groupAccounts addObject:account];
	}
	
	if([groupAccounts count] > 0) {
		[[_groupFilterPopUpButton menu] addItem:[NSMenuItem separatorItem]];
		[[_groupPopUpButton menu] addItem:[NSMenuItem separatorItem]];
		
		enumerator = [groupAccounts objectEnumerator];
	
		while((account = [enumerator nextObject])) {
			if([account isKindOfClass:[WCGroupAccount class]]) {
				[_groupFilterPopUpButton addItemWithTitle:[account name]];
				[_groupPopUpButton addItemWithTitle:[account name]];
			}
		}
	}
}

- (void)_reloadSettings {
	NSEnumerator			*enumerator, *settingsEnumerator, *accountsEnumerator;
	NSMutableDictionary		*newSection;
	NSMutableArray			*settings;
	NSDictionary			*section, *setting;
	WCAccount				*account;
	
	if([_showPopUpButton selectedItem] == _allSettingsMenuItem) {
		[_shownSettings setArray:_allSettings];
	} else {
		[_shownSettings removeAllObjects];
	
		enumerator = [_allSettings objectEnumerator];
		
		while((section = [enumerator nextObject])) {
			settings			= [NSMutableArray array];
			settingsEnumerator	= [[section objectForKey:WCAccountsFieldSettings] objectEnumerator];
			
			while((setting = [settingsEnumerator nextObject])) {
				accountsEnumerator = [_accounts objectEnumerator];
				
				while((account = [accountsEnumerator nextObject])) {
					if([account valueForKey:[setting objectForKey:WCAccountFieldNameKey]]) {
						[settings addObject:setting];
						
						break;
					}
				}
			}
			
			if([settings count] > 0) {
				newSection = [[section mutableCopy] autorelease];
				[newSection setObject:settings forKey:WCAccountsFieldSettings];
				[_shownSettings addObject:newSection];
			}
		}
	}
	
	[_settingsOutlineView reloadData];
	
	enumerator = [_shownSettings objectEnumerator];
	
	while((section = [enumerator nextObject]))
		[_settingsOutlineView expandItem:section];
}

- (BOOL)_filterIncludesAccount:(WCAccount *)account {
	NSMenuItem		*item;
	BOOL			passed;
	
	if([_allFilterButton state] != NSOnState) {
		passed = NO;
		
		if([_usersFilterButton state] == NSOnState && [account isKindOfClass:[WCUserAccount class]])
			passed = YES;
		else if([_groupsFilterButton state] == NSOnState && [account isKindOfClass:[WCGroupAccount class]])
			passed = YES;
	
		if(!passed)
			return NO;
	}
	
	item = [_groupFilterPopUpButton selectedItem];
	
	if(item != _anyGroupMenuItem) {
		passed = NO;
		
		if([account isKindOfClass:[WCUserAccount class]]) {
			if(item == _noGroupMenuItem)
				passed = [[(WCUserAccount *) account group] isEqualToString:@""];
			else
				passed = [[(WCUserAccount *) account group] isEqualToString:[item title]];
		}
		
		if(!passed)
			return NO;
	}
	
	if(_accountFilter) {
		passed = NO;
		
		if([[account name] containsSubstring:_accountFilter])
			passed = YES;
		
		if([account isKindOfClass:[WCUserAccount class]]) {
			if([[(WCUserAccount *) account fullName] containsSubstring:_accountFilter])
				passed = YES;
		}

		if(!passed)
			return NO;
	}
	
	return YES;
}

- (void)_reloadFilter {
	NSEnumerator	*enumerator;
	WCAccount		*account;
	
	[_shownAccounts removeAllObjects];
	
	enumerator = [_allAccounts objectEnumerator];
	
	while((account = [enumerator nextObject])) {
		if([self _filterIncludesAccount:account])
			[_shownAccounts addObject:account];
	}
	
	[_statusTextField setStringValue:[NSSWF:NSLS(@"%u %@", @"Accounts (count, 'account(s)'"),
		[_shownAccounts count],
		[_shownAccounts count] == 1
			? NSLS(@"account", @"Account singular")
			: NSLS(@"accounts", @"Account plural")]];
}

- (void)_selectAccounts {
	NSEnumerator			*enumerator;
	NSMutableIndexSet		*indexes;
	WCAccount				*account;
	NSUInteger				index;
	
	if([_selectAccounts count] > 0) {
		indexes		= [NSMutableIndexSet indexSet];
		enumerator	= [_selectAccounts objectEnumerator];
		
		while((account = [enumerator nextObject])) {
			index = [_shownAccounts indexOfObject:account];
			
			if(index != NSNotFound)
				[indexes addIndex:index];
		}
		
		[_accountsTableView selectRowIndexes:indexes byExtendingSelection:NO];
		[_selectAccounts removeAllObjects];
	} else {
		if([[_accountsTableView selectedRowIndexes] count] == 0) {
			indexes		= [NSMutableIndexSet indexSet];
			enumerator	= [_accounts objectEnumerator];
			
			while((account = [enumerator nextObject])) {
				index = [_shownAccounts indexOfObject:account];
				
				if(index != NSNotFound)
					[indexes addIndex:index];
			}
			
			[_accountsTableView selectRowIndexes:indexes byExtendingSelection:NO];
		}
	}
}

@end



@implementation WCAccountsController

- (id)init {
	NSEnumerator			*enumerator;
	NSMutableDictionary		*setting;
	NSDictionary			*field;
	NSMutableArray			*basicsSettings, *filesSettings, *boardsSettings, *trackerSettings, *usersSettings, *accountsSettings, *administrationSettings, *limitsSettings;
	NSButtonCell			*buttonCell;
	NSTextFieldCell			*textFieldCell;
	NSPopUpButtonCell		*popUpButtonCell;
	
	self = [super init];
	
	_listedAccounts			= [[NSMutableDictionary alloc] init];
	_allAccounts			= [[NSMutableArray alloc] init];
	_allUserAccounts		= [[NSMutableArray alloc] init];
	_allGroupAccounts		= [[NSMutableArray alloc] init];
	_shownAccounts			= [[NSMutableArray alloc] init];
	_userImage				= [[NSImage imageNamed:@"User"] retain];
	_groupImage				= [[NSImage imageNamed:@"Group"] retain];
	_accounts				= [[NSMutableArray alloc] init];
	_selectAccounts			= [[NSMutableArray alloc] init];
	_deletedAccounts		= [[NSMutableDictionary alloc] init];

	basicsSettings			= [NSMutableArray array];
	filesSettings			= [NSMutableArray array];
	boardsSettings			= [NSMutableArray array];
	trackerSettings			= [NSMutableArray array];
	usersSettings			= [NSMutableArray array];
	accountsSettings		= [NSMutableArray array];
	administrationSettings	= [NSMutableArray array];
	limitsSettings			= [NSMutableArray array];
	enumerator				= [[WCAccount fields] objectEnumerator];
	
	while((field = [enumerator nextObject])) {
		setting = [[field mutableCopy] autorelease];
		
		switch((WCAccountFieldType) [[setting objectForKey:WCAccountFieldTypeKey] integerValue]) {
			case WCAccountFieldTypeBoolean:
				buttonCell = [[NSButtonCell alloc] initTextCell:@""];
				[buttonCell setControlSize:NSSmallControlSize];
				[buttonCell setButtonType:NSSwitchButton];
				[buttonCell setAllowsMixedState:YES];
				[setting setObject:buttonCell forKey:WCAccountsFieldCell];
				[buttonCell release];
				break;

			case WCAccountFieldTypeNumber:
			case WCAccountFieldTypeString:
				textFieldCell = [[NSTextFieldCell alloc] initTextCell:@""];
				[textFieldCell setControlSize:NSSmallControlSize];
				[textFieldCell setEditable:YES];
				[textFieldCell setSelectable:YES];
				[textFieldCell setFont:[NSFont smallSystemFont]];
				[setting setObject:textFieldCell forKey:WCAccountsFieldCell];
				[textFieldCell release];
				break;
			
			case WCAccountFieldTypeEnum:
				popUpButtonCell = [[NSPopUpButtonCell alloc] initTextCell:@"" pullsDown:NO];
				[popUpButtonCell setControlSize:NSSmallControlSize];
				[popUpButtonCell setBordered:NO];
				[popUpButtonCell setFont:[NSFont smallSystemFont]];
				
				if([[setting objectForKey:WCAccountFieldNameKey] isEqualToString:@"wired.account.color"]) {
					[popUpButtonCell addItem:[NSMenuItem itemWithTitle:NSLS(@"Black", @"Account color")
																 image:[NSImage imageNamed:@"LabelBlack"]]];
					[popUpButtonCell addItem:[NSMenuItem itemWithTitle:NSLS(@"Red", @"Account color")
																 image:[NSImage imageNamed:@"LabelRed"]]];
					[popUpButtonCell addItem:[NSMenuItem itemWithTitle:NSLS(@"Orange", @"Account color")
																 image:[NSImage imageNamed:@"LabelOrange"]]];
					[popUpButtonCell addItem:[NSMenuItem itemWithTitle:NSLS(@"Green", @"Account color")
																 image:[NSImage imageNamed:@"LabelGreen"]]];
					[popUpButtonCell addItem:[NSMenuItem itemWithTitle:NSLS(@"Blue", @"Account color")
																 image:[NSImage imageNamed:@"LabelBlue"]]];
					[popUpButtonCell addItem:[NSMenuItem itemWithTitle:NSLS(@"Purple", @"Account color")
																 image:[NSImage imageNamed:@"LabelPurple"]]];
				}
				
				[setting setObject:popUpButtonCell forKey:WCAccountsFieldCell];
				[popUpButtonCell release];
				break;
			
			case WCAccountFieldTypeDate:
			case WCAccountFieldTypeList:
				break;
		}
		
		switch((WCAccountFieldSection) [[setting objectForKey:WCAccountFieldSectionKey] integerValue]) {
			case WCAccountFieldSectionNone:
				break;
				
			case WCAccountFieldSectionBasics:
				[basicsSettings addObject:setting];
				break;

			case WCAccountFieldSectionFiles:
				[filesSettings addObject:setting];
				break;

			case WCAccountFieldSectionBoards:
				[boardsSettings addObject:setting];
				break;

			case WCAccountFieldSectionTracker:
				[trackerSettings addObject:setting];
				break;

			case WCAccountFieldSectionUsers:
				[usersSettings addObject:setting];
				break;

			case WCAccountFieldSectionAccounts:
				[accountsSettings addObject:setting];
				break;

			case WCAccountFieldSectionAdministration:
				[administrationSettings addObject:setting];
				break;

			case WCAccountFieldSectionLimits:
				[limitsSettings addObject:setting];
				break;
		}
	}
	
	_allSettings = [[NSArray alloc] initWithObjects:
		[NSDictionary dictionaryWithObjectsAndKeys:
			NSLS(@"Basics", @"Account section"),			WCAccountFieldLocalizedNameKey,
			basicsSettings,									WCAccountsFieldSettings,
			NULL],	
		[NSDictionary dictionaryWithObjectsAndKeys:
			NSLS(@"Files", @"Account section"),				WCAccountFieldLocalizedNameKey,
			filesSettings,									WCAccountsFieldSettings,
			NULL],
		[NSDictionary dictionaryWithObjectsAndKeys:
			NSLS(@"Boards", @"Account section"),			WCAccountFieldLocalizedNameKey,
			boardsSettings,									WCAccountsFieldSettings,
			NULL],
		[NSDictionary dictionaryWithObjectsAndKeys:
			NSLS(@"Tracker", @"Account section"),			WCAccountFieldLocalizedNameKey,
			trackerSettings,								WCAccountsFieldSettings,
			NULL],
		[NSDictionary dictionaryWithObjectsAndKeys:
			NSLS(@"Users", @"Account section"),				WCAccountFieldLocalizedNameKey,
			usersSettings,									WCAccountsFieldSettings,
			NULL],
		[NSDictionary dictionaryWithObjectsAndKeys:
			NSLS(@"Accounts", @"Account section"),			WCAccountFieldLocalizedNameKey,
			accountsSettings,								WCAccountsFieldSettings,
			NULL],
		[NSDictionary dictionaryWithObjectsAndKeys:
			NSLS(@"Administration", @"Account section"),	WCAccountFieldLocalizedNameKey,
			administrationSettings,							WCAccountsFieldSettings,
			NULL],
		[NSDictionary dictionaryWithObjectsAndKeys:
			NSLS(@"Limits", @"Account section"),			WCAccountFieldLocalizedNameKey,
			limitsSettings,									WCAccountsFieldSettings,
			NULL],
		NULL];
	
	_shownSettings = [_allSettings mutableCopy];

	return self;
}

- (void)dealloc {
	[_dontChangeGroupMenuItem release];
	
	[_allSettings release];
	[_shownSettings release];
	
	[_userImage release];
	[_groupImage release];

	[_listedAccounts release];
	[_allAccounts release];
	[_allUserAccounts release];
	[_allGroupAccounts release];
	[_shownAccounts release];
	
	[_accounts release];
	[_selectAccounts release];
	
	[_dateFormatter release];
	[_sizeFormatter release];
	[_accountFilter release];
	
	[_deletedAccounts release];

	[super dealloc];
}

#pragma mark -

- (void)windowDidLoad {
	[[_administration connection] addObserver:self
									 selector:@selector(wiredAccountAccountsChanged:)
								  messageName:@"wired.account.accounts_changed"];
	
	[_accountsTableView setTarget:self];
	[_accountsTableView setDeleteAction:@selector(delete:)];
	
	[_settingsOutlineView setTarget:self];
	[_settingsOutlineView setDeleteAction:@selector(clearSetting:)];
	
	[_dontChangeGroupMenuItem retain];
	
	_dateFormatter = [[WIDateFormatter alloc] init];
	[_dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	[_dateFormatter setDateStyle:NSDateFormatterMediumStyle];
	[_dateFormatter setNaturalLanguageStyle:WIDateFormatterCapitalizedNaturalLanguageStyle];
	
	_sizeFormatter = [[WISizeFormatter alloc] init];
	
	[self _validateForAccounts];
	[self _readFromAccounts];
}

- (void)linkConnectionLoggedIn:(NSNotification *)notification {
	[_allAccounts removeAllObjects];
	[_allUserAccounts removeAllObjects];
	[_allGroupAccounts removeAllObjects];
	[_shownAccounts removeAllObjects];
	
	[_accountsTableView reloadData];
	
	_requested = NO;

	if([[_administration window] isVisible] && [_administration selectedController] == self)
		[self _requestAccounts];
	
	[self _validate];
}

- (void)serverConnectionPrivilegesDidChange:(NSNotification *)notification {
	if([[[_administration connection] account] accountListAccounts]) {
		if([[_administration window] isVisible] && [_administration selectedController] == self)
			[self _requestAccounts];
	} else {
		_requested = NO;
	}
	
	[self _validate];
	[self _validateForAccounts];
}

- (void)wiredAccountAccountsChanged:(WIP7Message *)message {
	if([_selectAccounts count] == 0)
		[_selectAccounts setArray:[self _selectedAccounts]];
	
	[self _reloadAccounts];
}

- (void)wiredAccountListAccountsReply:(WIP7Message *)message {
	NSMutableArray		*accounts;
	NSNumber			*number;
	WIP7UInt32			transaction;
	
	[message getUInt32:&transaction forName:@"wired.transaction"];
	
	number		= [NSNumber numberWithUnsignedInteger:transaction];
	accounts	= [_listedAccounts objectForKey:number];
	
	if(!accounts) {
		accounts = [NSMutableArray array];
		
		[_listedAccounts setObject:accounts forKey:number];
	}
	
	if([[message name] isEqualToString:@"wired.account.user_list"]) {
		[accounts addObject:[WCUserAccount accountWithMessage:message]];
	}
	else if([[message name] isEqualToString:@"wired.account.user_list.done"]) {
		[_allUserAccounts setArray:accounts];
		
		[_listedAccounts removeObjectForKey:number];
		
		[[_administration connection] removeObserver:self message:message];
	}
	else if([[message name] isEqualToString:@"wired.account.group_list"]) {
		[accounts addObject:[WCGroupAccount accountWithMessage:message]];
	}
	else if([[message name] isEqualToString:@"wired.account.group_list.done"]) {
		[_allGroupAccounts setArray:accounts];
		
		[_listedAccounts removeObjectForKey:number];
		
		[_progressIndicator stopAnimation:self];
		
		[_allAccounts setArray:_allUserAccounts];
		[_allAccounts addObjectsFromArray:_allGroupAccounts];
		[_allAccounts sortUsingSelector:@selector(compareName:)];

		[self _reloadFilter];
		[self _reloadGroups];
		
		[_accountsTableView reloadData];
		
		[self _selectAccounts];
		
		[[_administration connection] removeObserver:self message:message];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:WCAccountsControllerAccountsDidChangeNotification
															object:self];
	}
	else if([[message name] isEqualToString:@"wired.error"]) {
		[_administration showError:[WCError errorWithWiredMessage:message]];
		
		[[_administration connection] removeObserver:self message:message];
	}
}

- (void)wiredAccountSubscribeAccountsReply:(WIP7Message *)message {
	if([[message name] isEqualToString:@"wired.okay"]) {
		[[_administration connection] removeObserver:self message:message];
		
		[[_administration connection] removeObserver:self message:message];
	}
	else if([[message name] isEqualToString:@"wired.error"]) {
		[_administration showError:[WCError errorWithWiredMessage:message]];
		
		[[_administration connection] removeObserver:self message:message];
	}
}

- (void)wiredAccountReadAccountReply:(WIP7Message *)message {
	NSEnumerator	*enumerator;
	WCUserAccount	*userAccount;
	WCAccount		*account;
	
	if([[message name] isEqualToString:@"wired.account.user"] || [[message name] isEqualToString:@"wired.account.group"]) {
		if([[message name] isEqualToString:@"wired.account.user"])
			account = [WCUserAccount accountWithMessage:message];
		else
			account = [WCGroupAccount accountWithMessage:message];
		
		if(_requestedAccounts == [_accounts count]) {
			if([account isKindOfClass:[WCGroupAccount class]]) {
				enumerator = [_accounts objectEnumerator];
				
				while((userAccount = [enumerator nextObject])) {
					if([userAccount isKindOfClass:[WCUserAccount class]]) {
						if([[userAccount group] isEqualToString:[account name]])
							[userAccount setGroupAccount:(WCGroupAccount *) account];
					}
				}
			}
			
			[_progressIndicator stopAnimation:self];
			
			[self _validateForAccounts];
			[self _readFromAccounts];
		} else {
			[_accounts addObject:account];
			
			if([_accounts count] == _requestedAccounts) {
				enumerator = [_accounts objectEnumerator];
				
				while((userAccount = [enumerator nextObject])) {
					if([userAccount isKindOfClass:[WCUserAccount class]]) {
						if([[userAccount group] length] > 0)
							[self _readAccount:[WCGroupAccount accountWithName:[userAccount group]]];
					}
				}
				
				[_progressIndicator stopAnimation:self];
			
				_editing = YES;

				[self _validateForAccounts];
				[self _readFromAccounts];
			}
		}
		
		[[_administration connection] removeObserver:self message:message];
	}
	else if([[message name] isEqualToString:@"wired.error"]) {
		[_administration showError:[WCError errorWithWiredMessage:message]];
		
		[[_administration connection] removeObserver:self message:message];
	}
}

- (void)wiredAccountChangeAccountReply:(WIP7Message *)message {
	if([[message name] isEqualToString:@"wired.okay"]) {
		[_accounts removeAllObjects];
		
		_creating	= NO;
		_editing	= NO;
		_touched	= NO;
		
		[self _validateForAccounts];
		[self _readFromAccounts];
		[self _reloadAccounts];
		
		[[_administration window] setDocumentEdited:NO];
		
		[self _validate];
		
		[[_administration connection] removeObserver:self message:message];
	}
	else if([[message name] isEqualToString:@"wired.error"]) {
		_touched = YES;
		
		[_administration showError:[WCError errorWithWiredMessage:message]];
		
		[[_administration connection] removeObserver:self message:message];
	}
}

- (void)wiredAccountDeleteAccountReply:(WIP7Message *)message {
	NSEnumerator	*enumerator;
	NSArray			*accounts;
	NSAlert			*alert;
	NSNumber		*key;
	NSString		*title, *description;
	WCError			*error;
	NSUInteger		lastTransaction;
	WIP7UInt32		transaction;
	
	if([[message name] isEqualToString:@"wired.okay"] || [[message name] isEqualToString:@"wired.error"]) {
		if([[message name] isEqualToString:@"wired.error"])
			error = [WCError errorWithWiredMessage:message];
		else
			error = NULL;
		
		if([message getUInt32:&transaction forName:@"wired.transaction"]) {
			if([[message name] isEqualToString:@"wired.okay"] || [error code] != WCWiredProtocolAccountInUse)
				[_deletedAccounts removeObjectForKey:[NSNumber numberWithUnsignedInteger:transaction]];
			
			lastTransaction		= 0;
			enumerator			= [_deletedAccounts keyEnumerator];
			
			while((key = [enumerator nextObject])) {
				if([key unsignedIntegerValue] > lastTransaction)
					lastTransaction = [key unsignedIntegerValue];
			}
			
			if(lastTransaction > 0 && lastTransaction <= transaction) {
				accounts = [_deletedAccounts allValues];
				
				if([accounts count] == 1) {
					title = [NSSWF:
						NSLS(@"Are you sure you want to delete \u201c%@\u201d?", @"Delete account dialog title (filename)"),
						[[accounts objectAtIndex:0] name]];
					description = NSLS(@"The account is currently used by a logged in user. Deleting it will disconnect the affected user. This cannot be undone.",
									   @"Delete and disconnect account dialog description");
				} else {
					title = [NSSWF:
						NSLS(@"Are you sure you want to delete %lu items?", @"Delete and disconnect account dialog title (count)"),
						[accounts count]];
					description = NSLS(@"The accounts are currently used by logged in users. Deleting them will disconnect the affected users. This cannot be undone.",
									   @"Delete and disconnect account dialog description");
				}
				
				alert = [[NSAlert alloc] init];
				[alert setMessageText:title];
				[alert setInformativeText:description];
				[alert addButtonWithTitle:NSLS(@"Delete & Disconnect", @"Delete and disconnect account dialog button title")];
				[alert addButtonWithTitle:NSLS(@"Cancel", @"Delete and disconnect account dialog button title")];
				[alert beginSheetModalForWindow:[_administration window]
								  modalDelegate:self
								 didEndSelector:@selector(deleteAndDisconnectSheetDidEnd:returnCode:contextInfo:)
									contextInfo:NULL];
				[alert release];
			}
		}
		
		if(error && [error code] != WCWiredProtocolAccountInUse)
			[_administration showError:error];

		[[_administration connection] removeObserver:self message:message];
	}
}

- (void)textDidChange:(NSNotification *)notification {
	[self touch:self];
}

- (void)controlTextDidChange:(NSNotification *)notification {
	[self touch:self];
}

- (NSArray *)tokenField:(NSTokenField *)tokenField completionsForSubstring:(NSString *)substring indexOfToken:(NSInteger)tokenIndex indexOfSelectedItem:(NSInteger *)selectedIndex {
	NSEnumerator		*enumerator;
	NSMutableArray		*array;
	WCAccount			*account;
	
	array = [NSMutableArray array];
	enumerator = [_allAccounts objectEnumerator];
	
	while((account = [enumerator nextObject])) {
		if([account isKindOfClass:[WCGroupAccount class]] && [[account name] hasPrefix:substring])
			[array addObject:[account name]];
	}
	
	return array;
}

#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem *)item {
	SEL		selector;
	
	selector = [item action];
	
	if(selector == @selector(newDocument:))
		return [self _validateAddAccount];
	else if(selector == @selector(deleteDocument:))
		return [self _validateDeleteAccount];
	else if(selector == @selector(duplicateAccount:))
		return [self _validateDuplicateAccount];
	
	return YES;
}

#pragma mark -

- (BOOL)controllerWindowShouldClose {
	return [self _verifyUnsavedAndPerformAction:WCAccountsCloseWindow argument:NULL];
}

- (void)controllerDidSelect {
	[self _requestAccounts];
	
	[[_administration window] makeFirstResponder:_accountsTableView];
}

- (BOOL)controllerShouldUnselectForNewController:(id)controller {
	return [self _verifyUnsavedAndPerformAction:WCAccountsSelectTab argument:controller];
}

#pragma mark -

- (NSSize)minimumWindowSize {
	return NSMakeSize(678.0, 571.0);
}

#pragma mark -

- (NSString *)newDocumentMenuItemTitle {
	return NSLS(@"New Account\u2026", @"New menu item");
}

- (NSString *)deleteDocumentMenuItemTitle {
	NSArray			*accounts;
	
	accounts = [self _selectedAccounts];
	
	switch([accounts count]) {
		case 0:
			return NSLS(@"Delete Account\u2026", @"Delete menu item");
			break;
		
		case 1:
			return [NSSWF:NSLS(@"Delete \u201c%@\u201d\u2026", @"Delete menu item (account)"), [[accounts objectAtIndex:0] name]];
			break;
		
		default:
			return [NSSWF:NSLS(@"Delete %u Items\u2026", @"Delete menu item (count)"), [accounts count]];
			break;
	}
}

#pragma mark -

- (NSArray *)userNames {
	NSEnumerator	*enumerator;
	NSMutableArray	*array;
	WCAccount		*account;
	
	if(_requested) {
		array			= [NSMutableArray array];
		enumerator		= [_allUserAccounts objectEnumerator];

		while((account = [enumerator nextObject]))
			[array addObject:[account name]];
		
		[array sortUsingSelector:@selector(caseInsensitiveCompare:)];

		return array;
	} else {
		[self _requestAccounts];
		
		if(_requested)
			return nil;
		else
			return [NSArray array];
	}
}

- (NSArray *)groupNames {
	NSEnumerator	*enumerator;
	NSMutableArray	*array;
	WCAccount		*account;

	if(_requested) {
		array			= [NSMutableArray array];
		enumerator		= [_allGroupAccounts objectEnumerator];

		while((account = [enumerator nextObject]))
			[array addObject:[account name]];
		
		[array sortUsingSelector:@selector(caseInsensitiveCompare:)];

		return array;
	} else {
		[self _requestAccounts];
		
		if(_requested)
			return nil;
		else
			return [NSArray array];
	}
}

- (void)editUserAccountWithName:(NSString *)name {
	WCAccount	*account;
	NSInteger	i, count;
	
	count = [_shownAccounts count];
	
	for(i = 0; i < count; i++) {
		account = [_shownAccounts objectAtIndex:i];
		
		if([account isKindOfClass:[WCUserAccount class]] && [[account name]isEqualToString:name]) {
			[_accountsTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:i] byExtendingSelection:NO];
			
			break;
		}
	}
	
	[_administration selectController:self];
	[_administration showWindow:self];
}

#pragma mark -

- (IBAction)newDocument:(id)sender {
	[self addAccount:sender];
}

- (IBAction)deleteDocument:(id)sender {
	[self deleteAccount:sender];
}

- (IBAction)touch:(id)sender {
	_touched = YES;

	[[_administration window] setDocumentEdited:YES];
	
	[self _validate];
}

- (IBAction)addAccount:(id)sender {
	WCUserAccount		*account;
	
	if(![self _validateAddAccount])
		return;
	
	[_accounts removeAllObjects];

	[self _readFromAccounts];

	account = [[[WCUserAccount alloc] init] autorelease];
	[account setName:NSLS(@"Untitled", @"Account name")];
	[_accounts addObject:account];

	_creating	= YES;
	_editing	= NO;
	_touched	= YES;
	
	[_accountsTabView selectTabViewItemAtIndex:0];
	
	if([[[_administration connection] account] accountCreateUsers])
		[_typePopUpButton selectItem:_userMenuItem];
	else
		[_typePopUpButton selectItem:_groupMenuItem];
	
	[_nameTextField setStringValue:[account name]];
	
	[self _validate];
	[self _validateForAccounts];
	[self _readFromAccounts];
	
	[[_administration window] setDocumentEdited:YES];
	
	[[_administration window] makeFirstResponder:_nameTextField];
	[_nameTextField selectText:self];
}

- (IBAction)deleteAccount:(id)sender {
	NSAlert			*alert;
	NSArray			*accounts;
	NSString		*title;
	
	if(![self _validateDeleteAccount])
		return;

	accounts = [self _selectedAccounts];

	if([accounts count] == 1) {
		title = [NSSWF:
			NSLS(@"Are you sure you want to delete \u201c%@\u201d?", @"Delete account dialog title (filename)"),
			[[accounts objectAtIndex:0] name]];
	} else {
		title = [NSSWF:
			NSLS(@"Are you sure you want to delete %lu items?", @"Delete account dialog title (count)"),
			[accounts count]];
	}

	alert = [[NSAlert alloc] init];
	[alert setMessageText:title];
	[alert setInformativeText:NSLS(@"This cannot be undone.", @"Delete account dialog description")];
	[alert addButtonWithTitle:NSLS(@"Delete", @"Delete account dialog button title")];
	[alert addButtonWithTitle:NSLS(@"Cancel", @"Delete account dialog button title")];
	[alert beginSheetModalForWindow:[_administration window]
					  modalDelegate:self
					 didEndSelector:@selector(deleteSheetDidEnd:returnCode:contextInfo:)
						contextInfo:NULL];
	[alert release];
}

- (void)deleteSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	NSEnumerator	*enumerator;
	WIP7Message		*message;
	WCAccount		*account;
	NSUInteger		transaction;

	if(returnCode == NSAlertFirstButtonReturn) {
		enumerator = [[self _selectedAccounts] objectEnumerator];

		while((account = [enumerator nextObject])) {
			if([account isKindOfClass:[WCUserAccount class]]) {
				message = [WIP7Message messageWithName:@"wired.account.delete_user" spec:WCP7Spec];
				[message setBool:NO forName:@"wired.account.disconnect_users"];
			} else {
				message = [WIP7Message messageWithName:@"wired.account.delete_group" spec:WCP7Spec];
			}
			
			[message setString:[account name] forName:@"wired.account.name"];
			
			transaction = [[_administration connection] sendMessage:message
													   fromObserver:self
														   selector:@selector(wiredAccountDeleteAccountReply:)];
			
			[_deletedAccounts setObject:account forKey:[NSNumber numberWithUnsignedInteger:transaction]];
		}
	}
}

- (void)deleteAndDisconnectSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	NSEnumerator	*enumerator;
	WIP7Message		*message;
	WCAccount		*account;
	
	if(returnCode == NSAlertFirstButtonReturn) {
		enumerator = [_deletedAccounts objectEnumerator];

		while((account = [enumerator nextObject])) {
			if([account isKindOfClass:[WCUserAccount class]]) {
				message = [WIP7Message messageWithName:@"wired.account.delete_user" spec:WCP7Spec];
				[message setBool:YES forName:@"wired.account.disconnect_users"];
			} else {
				message = [WIP7Message messageWithName:@"wired.account.delete_group" spec:WCP7Spec];
			}
			
			[message setString:[account name] forName:@"wired.account.name"];
			
			[[_administration connection] sendMessage:message
										 fromObserver:self
											 selector:@selector(wiredAccountDeleteAccountReply:)];
		}
	}
	
	[_deletedAccounts removeAllObjects];
}

- (IBAction)duplicateAccount:(id)sender {
	NSArray				*names;
	WCAccount			*account;
	
	if(![self _validateDuplicateAccount])
		return;
	
	account		= [[[_accounts objectAtIndex:0] copy] autorelease];
	names		= [account isKindOfClass:[WCUserAccount class]] ? [self userNames] : [self groupNames];

	[account setName:[WCApplicationController copiedNameForName:[account name] existingNames:names]];
	
	[[_administration connection] sendMessage:[account createAccountMessage]
								 fromObserver:self
									 selector:@selector(wiredAccountChangeAccountReply:)];
	
	[_selectAccounts setArray:[NSArray arrayWithObject:account]];
}

- (IBAction)all:(id)sender {
	[_usersFilterButton setState:NSOffState];
	[_groupsFilterButton setState:NSOffState];
	
	[_selectAccounts setArray:[self _selectedAccounts]];
	
	[self _reloadFilter];

	[_accountsTableView reloadData];
	
	[self _selectAccounts];
}

- (IBAction)users:(id)sender {
	[_allFilterButton setState:NSOffState];
	[_groupsFilterButton setState:NSOffState];
	
	[_selectAccounts setArray:[self _selectedAccounts]];
	
	[self _reloadFilter];
	
	[_accountsTableView reloadData];
	
	[self _selectAccounts];
}

- (IBAction)groups:(id)sender {
	[_usersFilterButton setState:NSOffState];
	[_allFilterButton setState:NSOffState];

	[_selectAccounts setArray:[self _selectedAccounts]];
	
	[self _reloadFilter];
	
	[_accountsTableView reloadData];
	
	[self _selectAccounts];
}

- (IBAction)groupFilter:(id)sender {
	[_selectAccounts setArray:[self _selectedAccounts]];
	
	[self _reloadFilter];
	
	[_accountsTableView reloadData];
	
	[self _selectAccounts];
}

- (IBAction)search:(id)sender {
	[_accountFilter release];
	
	if([[_filterSearchField stringValue] length] > 0)
		_accountFilter = [[_filterSearchField stringValue] retain];
	else
		_accountFilter = NULL;
	
	[_selectAccounts setArray:[self _selectedAccounts]];
	
	[self _reloadFilter];
	
	[_accountsTableView reloadData];
	
	[self _selectAccounts];
}

- (IBAction)type:(id)sender {
	WCUserAccount		*userAccount;
	
	if(_creating) {
		if([_typePopUpButton selectedItem] == _groupMenuItem) {
			[_groupPopUpButton selectItemAtIndex:0];
		
			userAccount = [_accounts lastObject];
			
			[userAccount setGroup:@""];
			[userAccount setGroupAccount:NULL];
		}
	}
	
	[self _validateForAccounts];
}

- (IBAction)group:(id)sender {
	NSEnumerator		*enumerator;
	WCUserAccount		*account;
	
	if([_typePopUpButton selectedItem] == _userMenuItem) {
		enumerator = [_accounts objectEnumerator];
		
		while((account = [enumerator nextObject])) {
			if([_groupPopUpButton selectedItem] == _dontChangeGroupMenuItem) {
				[account setGroup:[account originalGroup]];
				[account setGroupAccount:NULL];
			}
			else if([_groupPopUpButton selectedItem] == _noneMenuItem) {
				[account setGroup:@""];
				[account setGroupAccount:NULL];
			}
			else {
				[account setGroup:[_groupPopUpButton titleOfSelectedItem]];
			}
				
			if([[account group] length] > 0)
				[self _readAccount:[WCGroupAccount accountWithName:[account group]]];
		}
		
		[_settingsOutlineView reloadData];

		[self touch:self];
	} else {
		[_groupPopUpButton selectItemAtIndex:0];
	}
}

- (IBAction)show:(id)sender {
	[self _reloadSettings];
}

- (IBAction)selectAll:(id)sender {
	NSEnumerator		*enumerator, *settingsEnumerator, *accountsEnumerator;
	NSDictionary		*section, *setting;
	WCAccount			*account;
	
	enumerator = [_shownSettings objectEnumerator];
	
	while((section = [enumerator nextObject])) {
		settingsEnumerator = [[section objectForKey:WCAccountsFieldSettings] objectEnumerator];
		
		while((setting = [settingsEnumerator nextObject])) {
			if([[setting objectForKey:WCAccountFieldTypeKey] integerValue] == WCAccountFieldTypeBoolean) {
				accountsEnumerator = [_accounts objectEnumerator];
				
				while((account = [accountsEnumerator nextObject]))
					[account setValue:[NSNumber numberWithBool:YES] forKey:[setting objectForKey:WCAccountFieldNameKey]];
			}
		}
	}
	
	[_settingsOutlineView reloadData];
	
	[self touch:self];
}

- (IBAction)clearSetting:(id)sender {
	NSEnumerator		*enumerator;
	NSDictionary		*setting;
	NSString			*name;
//	NSIndexSet			*indexes;
	WCAccount			*account;
	NSInteger			index;
	BOOL				changed = NO;
	
//	indexes		= [_settingsOutlineView selectedRowIndexes];
//	index		= [indexes firstIndex];
    
    for(index = 0; index < [_settingsOutlineView numberOfRows]; index++) {
        setting		= [_settingsOutlineView itemAtRow:index];
		name		= [setting objectForKey:WCAccountFieldNameKey];
		
		if(name) {
			enumerator = [_accounts objectEnumerator];
			
			while((account = [enumerator nextObject]))
				[account setValue:NULL forKey:name];
			
			changed = YES;
		}
		
		//index = [indexes indexGreaterThanIndex:index];
    }

	if(changed) {
		[self touch:self];
		
		if([_showPopUpButton selectedItem] == _settingsDefinedAtThisLevelMenuItem)
			[self _reloadSettings];
	
		[_settingsOutlineView reloadData];
	}
}

- (IBAction)save:(id)sender {
	[[_administration window] makeFirstResponder:_accountsTableView];
	
	[self _save];
}

- (void)saveSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	NSDictionary		*dictionary = contextInfo;
	id					argument;
	WCAccountsAction	action;
	
	action		= [[dictionary objectForKey:@"WCAccountsAction"] integerValue];
	argument	= [dictionary objectForKey:@"WCAccountsArgument"];
	
	if(returnCode != NSAlertSecondButtonReturn) {
		if(returnCode == NSAlertFirstButtonReturn) {
			[self _save];
			
			[_selectAccounts removeAllObjects];
		} else {
			[_accounts removeAllObjects];
			
			_creating	= NO;
			_editing	= NO;
			
			[self _validateForAccounts];
			[self _readFromAccounts];
			
			[[_administration window] setDocumentEdited:NO];
			
			[self _validate];
		}
		
		_touched = NO;
		
		switch(action) {
			case WCAccountsDoNothing:
			default:
				break;
				
			case WCAccountsCloseWindow:
				[_accountsTableView deselectAll:self];
				
				[_administration close];
				break;
			
			case WCAccountsSelectTab:
				[_accountsTableView deselectAll:self];
				
				[_administration selectController:argument];
				break;
				
			case WCAccountsSelectRow:
				[_selectAccounts removeAllObjects];
				
				[_accountsTableView selectRowIndexes:argument byExtendingSelection:NO];
				break;
		}
	}
	
	_saving = NO;
	
	[dictionary release];
}



#pragma mark -

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return [_shownAccounts count];
}



- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	WCAccount		*account;

	account = [self _accountAtIndex:row];

	return [account name];
}



- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	WCAccount		*account;
	
	account = [self _accountAtIndex:row];
	
	if([account isKindOfClass:[WCUserAccount class]])
		[cell setImage:_userImage];
	else
		[cell setImage:_groupImage];
	
	[cell setTextColor:[WCUser colorForColor:[account color] idleTint:NO]];
}


- (NSString *)tableView:(NSTableView *)tableView stringValueForRow:(NSInteger)row {
	return [[self _accountAtIndex:row] name];
}



- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
	if(row != [_accountsTableView selectedRow])
		return [self _verifyUnsavedAndPerformAction:WCAccountsSelectRow argument:[NSIndexSet indexSetWithIndex:row]];
	
	return YES;
}



- (void)tableViewSelectionDidChange:(NSNotification *)notification {
	if([self _verifyUnsavedAndPerformAction:WCAccountsDoNothing argument:NULL]) {
		if([[[_administration connection] account] accountReadAccounts]) {
			if([_accountsTableView numberOfSelectedRows] > 0) {
				[self _readAccounts:[self _selectedAccounts]];
			} else {
				[_accounts removeAllObjects];
				
				_editing = _creating = NO;

				[self _validateForAccounts];
				[self _readFromAccounts];
			}
		}
		
		[self _validate];
	}
}



#pragma mark -

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
	if([_accounts count] == 0)
		return 0;
	
	if(!item)
		return [_shownSettings count];
	
	return [[item objectForKey:WCAccountsFieldSettings] count];
}



- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
	if(!item)
		return [_shownSettings objectAtIndex:index];
	
	return [[item objectForKey:WCAccountsFieldSettings] objectAtIndex:index];
}



- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
	NSEnumerator			*enumerator;
	NSMutableSet			*values;
	NSAttributedString		*attributedString;
	NSDictionary			*attributes;
	NSString				*name;
	WCAccount				*account;
	id						cell, value;
	WCAccountFieldType		type;
	
	if(tableColumn == _settingTableColumn) {
		return [item objectForKey:WCAccountFieldLocalizedNameKey];
	}
	else if(tableColumn == _valueTableColumn) {
		type = [[item objectForKey:WCAccountFieldTypeKey] integerValue];
		name = [item objectForKey:WCAccountFieldNameKey];
		cell = [item objectForKey:WCAccountsFieldCell];
		
		if(!name)
			return NULL;
		
		if(type == WCAccountFieldTypeEnum) {
			if([[cell itemAtIndex:0] tag] == -1) {
				[cell removeItemAtIndex:0];
				[cell removeItemAtIndex:0];
			}
		}
		
		if([_accounts count] == 1) {
			account		= [_accounts lastObject];
			value		= [account valueForKey:name];
			
            if(!value && [account isKindOfClass:[WCUserAccount class]])
				value = [[(WCUserAccount *) account groupAccount] valueForKey:name];
            
		} else {
			values		= [NSMutableSet set];
			enumerator	= [_accounts objectEnumerator];
			
			while((account = [enumerator nextObject])) {
				value = [account valueForKey:name];
				
				if(!value) {
					switch(type) {
						case WCAccountFieldTypeString:
							value = @"";
							break;
						case WCAccountFieldTypeDate:
							value = [NSDate date];
							break;
						case WCAccountFieldTypeNumber:
							value = [NSNumber numberWithInteger:0];
							break;
						case WCAccountFieldTypeBoolean:
							value = [NSNumber numberWithBool:0];
							break;
						case WCAccountFieldTypeEnum:
							value = [NSNumber numberWithInteger:-1];
							break;
						case WCAccountFieldTypeList:
							value = [NSArray array];
							break;
					}
				}
				
				[values addObject:value];
			}
			
			if([values count] == 1) {
				value = [values anyObject];
			}
			else if([values count] == 0) {
				value = NULL;
			}
			else {
				attributes			= [NSDictionary dictionaryWithObjectsAndKeys:
					[NSColor grayColor],	NSForegroundColorAttributeName,
					[cell font],			NSFontAttributeName,
					NULL];
				attributedString	= [NSAttributedString attributedStringWithString:NSLS(@"<Multiple values>", @"Account field value")
																		  attributes:attributes];
				
				if(type == WCAccountFieldTypeBoolean)
					value = [NSNumber numberWithInteger:NSMixedState];
				else if(type == WCAccountFieldTypeEnum) {
					[cell insertItem:[NSMenuItem itemWithAttributedTitle:attributedString tag:-1] atIndex:0];
					[cell insertItem:[NSMenuItem separatorItem] atIndex:1];
					
					value = [NSNumber numberWithInteger:0];
				}
				else {
					value = [attributedString string];
				}
			}
		}
		
		if([name isEqualToString:@"wired.account.transfer.download_speed_limit"] ||
		   [name isEqualToString:@"wired.account.transfer.upload_speed_limit"]) {
			if([value isKindOfClass:[NSNumber class]])
				value = [NSNumber numberWithInteger:[value doubleValue] / 1024.0];
		}
		
		if(type == WCAccountFieldTypeNumber && [value isKindOfClass:[NSNumber class]] && [value integerValue] == 0)
			value = NULL;

		return value;
	}

	return NULL;
}



- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item {
	if(tableColumn == _valueTableColumn)
		return ([item objectForKey:WCAccountFieldNameKey] != NULL);

	return NO;
}



- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
	NSEnumerator			*enumerator;
	NSString				*name;
	WCAccount				*account;
	id						cell, value;
	WCAccountFieldType		type;
	
	type	= [[item objectForKey:WCAccountFieldTypeKey] integerValue];
	name	= [item objectForKey:WCAccountFieldNameKey];
	cell	= [item objectForKey:WCAccountsFieldCell];
	value	= object;
	
	if(type == WCAccountFieldTypeNumber) {
		if([object isKindOfClass:[NSString class]] && [object length] == 0)
			return;
		
		value = [NSNumber numberWithInteger:[value integerValue]];
	}
	else if(type == WCAccountFieldTypeBoolean) {
		value = [NSNumber numberWithBool:([value integerValue] == -1) ? YES : [value boolValue]];
	}
	else if(type == WCAccountFieldTypeEnum) {
		if([value integerValue] < 0)
			return;
		
		if([[cell itemAtIndex:0] tag] == -1)
			value = [NSNumber numberWithInteger:[value integerValue] - 2];
	}

	if([name isEqualToString:@"wired.account.transfer.download_speed_limit"] ||
	   [name isEqualToString:@"wired.account.transfer.upload_speed_limit"])
		value = [NSNumber numberWithInteger:[value integerValue] * 1024.0];

	enumerator = [_accounts objectEnumerator];
	
	while((account = [enumerator nextObject]))
		[account setValue:value forKey:name];
	
	[self touch:self];
	
	[_settingsOutlineView setNeedsDisplay:YES];
}



- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {
	NSEnumerator			*enumerator;
	NSString				*name;
	WCAccount				*account;
	id						value;
	WCAccountFieldType		type;
	BOOL					set = NO;
	
	type		= [[item objectForKey:WCAccountFieldTypeKey] integerValue];
	name		= [item objectForKey:WCAccountFieldNameKey];
	enumerator	= [_accounts objectEnumerator];
	value		= [cell objectValue];
	
	while((account = [enumerator nextObject])) {
		if([account valueForKey:name]) {
			set = YES;
			
			break;
		}
	}
	
	if(set)
		[cell setFont:[[cell font] fontByAddingTrait:NSBoldFontMask]];
	else
		[cell setFont:[[cell font] fontByAddingTrait:NSUnboldFontMask]];
	
	if([cell respondsToSelector:@selector(setTextColor:)]) {
		if([value isKindOfClass:value] && [value isEqualToString:NSLS(@"<Multiple values>", @"Account field value")])
			[cell setTextColor:[NSColor grayColor]];
		else
			[cell setTextColor:[NSColor blackColor]];
	}
	
	if(tableColumn == _valueTableColumn)
		[cell setEnabled:[self _canEditAccounts]];
}



- (NSString *)outlineView:(NSOutlineView *)outlineView toolTipForCell:(NSCell *)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)tableColumn item:(id)item mouseLocation:(NSPoint)mouseLocation {
	return [item objectForKey:WCAccountFieldToolTipKey];
}



- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
	return ([[item objectForKey:WCAccountsFieldSettings] count] > 0);
}

@end



@implementation WCAccountsTableColumn

- (id)dataCellForRow:(NSInteger)row {
	id		cell;
	
	cell = [[(NSOutlineView *) [self tableView] itemAtRow:row] objectForKey:WCAccountsFieldCell];
	
	if(cell)
		return cell;
	
	return [super dataCellForRow:row];
}

@end
