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

#import "WCAccount.h"
#import "WCAdministration.h"
#import "WCBanlistController.h"
#import "WCServerConnection.h"

@interface WCBan : WIObject {
@public
	NSString			*_ip;
	NSDate				*_expirationDate;
}

+ (id)banWithMessage:(WIP7Message *)message;

- (NSComparisonResult)compareIP:(WCBan *)ban;
- (NSComparisonResult)compareExpirationDate:(WCBan *)ban;

@end


@implementation WCBan

+ (id)banWithMessage:(WIP7Message *)message {
	WCBan		*ban;
	
	ban = [[self alloc] init];
	
	ban->_ip					= [[message stringForName:@"wired.banlist.ip"] retain];
	ban->_expirationDate		= [[message dateForName:@"wired.banlist.expiration_date"] retain];

	return [ban autorelease];
}



- (void)dealloc {
	[_ip release];
	[_expirationDate release];

	[super dealloc];
}



#pragma mark -

- (NSComparisonResult)compareIP:(WCBan *)ban {
	return [self->_ip caseInsensitiveAndNumericCompare:ban->_ip];
}



- (NSComparisonResult)compareExpirationDate:(WCBan *)ban {
	NSComparisonResult		result;
	
	if(!self->_expirationDate && ban->_expirationDate)
		return NSOrderedAscending;
	else if(self->_expirationDate && !ban->_expirationDate)
		return NSOrderedDescending;
	
	result = [self->_expirationDate compare:ban->_expirationDate];
	
	if(result == NSOrderedSame)
		result = [self compareIP:ban];
	
	return result;
}

@end



@interface WCBanlistController(Private)

- (void)_validate;
- (BOOL)_validateAddBan;
- (BOOL)_validateDeleteBan;

- (void)_requestBans;

- (WCBan *)_banAtIndex:(NSUInteger)index;
- (NSArray *)_selectedBans;
- (void)_sortBans;

@end


@implementation WCBanlistController(Private)

- (void)_validate {
	[_addButton setEnabled:[self _validateAddBan]];
	[_deleteButton setEnabled:[self _validateDeleteBan]];
}



- (BOOL)_validateAddBan {
	if(![_administration connection] || ![[_administration connection] isConnected])
		return NO;
	
	return [[[_administration connection] account] banlistAddBans];
}



- (BOOL)_validateDeleteBan {
	if(![_administration connection] || ![[_administration connection] isConnected])
		return NO;
	
	return ([[[_administration connection] account] banlistDeleteBans] && [[self _selectedBans] count] > 0);
}



#pragma mark -

- (void)_requestBans {
	WIP7Message		*message;
	
	[_bans removeAllObjects];

	if([[_administration connection] isConnected] && [[[_administration connection] account] banlistGetBans]) {
		message = [WIP7Message messageWithName:@"wired.banlist.get_bans" spec:WCP7Spec];
		[[_administration connection] sendMessage:message fromObserver:self selector:@selector(wiredBanlistGetBansReply:)];
		
		[_progressIndicator startAnimation:self];
	}
}



#pragma mark -

- (WCBan *)_banAtIndex:(NSUInteger)index {
	NSUInteger		i;
	
	i = ([_banlistTableView sortOrder] == WISortDescending)
		? [_shownBans count] - index - 1
		: index;
	
	return [_shownBans objectAtIndex:i];
}



- (NSArray *)_selectedBans {
	NSMutableArray		*array;
	NSIndexSet			*indexes;
	NSUInteger			index;
	
	array = [NSMutableArray array];
	indexes = [_banlistTableView selectedRowIndexes];
	index = [indexes firstIndex];
	
	while(index != NSNotFound) {
		[array addObject:[self _banAtIndex:index]];
		
		index = [indexes indexGreaterThanIndex:index];
	}
	
	return array;
}



- (void)_sortBans {
	NSTableColumn   *tableColumn;

	tableColumn = [_banlistTableView highlightedTableColumn];
	
	if(tableColumn == _ipTableColumn)
		[_shownBans sortUsingSelector:@selector(compareIP:)];
	else if(tableColumn == _expiresTableColumn)
		[_shownBans sortUsingSelector:@selector(compareExpirationDate:)];
}

@end



@implementation WCBanlistController

- (id)init {
	self = [super init];

	_bans		= [[NSMutableArray alloc] init];
	_shownBans	= [[NSMutableArray alloc] init];

	return self;
}



- (void)dealloc {
	[_bans release];
	[_shownBans release];
	[_dateFormatter release];
	
	[super dealloc];
}



#pragma mark -

- (void)windowDidLoad {
	[_banlistTableView setTarget:self];
	[_banlistTableView setDeleteAction:@selector(deleteBan:)];
	[_banlistTableView setDefaultHighlightedTableColumnIdentifier:@"IP"];

	_dateFormatter = [[WIDateFormatter alloc] init];
	[_dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	[_dateFormatter setDateStyle:NSDateFormatterMediumStyle];
	[_dateFormatter setNaturalLanguageStyle:WIDateFormatterCapitalizedNaturalLanguageStyle];
	
	[_banlistTableView setPropertiesFromDictionary:
		[[[WCSettings settings] objectForKey:WCWindowProperties] objectForKey:@"WCBanlistTableView"]];
	
	[self _validate];
}



- (void)linkConnectionLoggedIn:(NSNotification *)notification {
	if([[_administration window] isVisible] && [_administration selectedController] == self)
		[self _requestBans];
}



- (void)serverConnectionPrivilegesDidChange:(NSNotification *)notification {
	if([[_administration window] isVisible] && [_administration selectedController] == self)
		[self _requestBans];

	[self _validate];
}



- (void)wiredBanlistGetBansReply:(WIP7Message *)message {
	if([[message name] isEqualToString:@"wired.banlist.list"]) {
		[_bans addObject:[WCBan banWithMessage:message]];
	}
	else if([[message name] isEqualToString:@"wired.banlist.list.done"]) {
		[_shownBans setArray:_bans];
		[_bans removeAllObjects];
		
		[self _sortBans];

		[_banlistTableView reloadData];

		[_progressIndicator stopAnimation:self];
	}
}



- (void)wiredBanlistDeleteBanReply:(WIP7Message *)message {
	if([[message name] isEqualToString:@"wired.error"])
		[_administration showError:[WCError errorWithWiredMessage:message]];
}



- (void)wiredBanlistAddBanReply:(WIP7Message *)message {
	if([[message name] isEqualToString:@"wired.error"])
		[_administration showError:[WCError errorWithWiredMessage:message]];
}



#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem *)item {
	SEL		selector;
	
	selector = [item action];
	
	if(selector == @selector(newDocument:))
		return [self _validateAddBan];
	else if(selector == @selector(deleteDocument:))
		return [self _validateDeleteBan];
	
	return YES;
}



#pragma mark -

- (void)controllerWindowDidBecomeKey {
	[self _requestBans];
}



- (void)controllerWindowWillClose {
	[[WCSettings settings] setObject:[_banlistTableView propertiesDictionary]
							  forKey:@"WCBanlistTableView"
				  inDictionaryForKey:WCWindowProperties];
}



- (void)controllerDidSelect {
	[self _requestBans];

	[[_administration window] makeFirstResponder:_banlistTableView];
}



#pragma mark -

- (IBAction)submitSheet:(id)sender {
	BOOL	valid = YES;
	
	if([sender window] == _addBanPanel)
		valid = ([[_addBanTextField stringValue] length] > 0);
	
	if(valid)
		[super submitSheet:sender];
}



#pragma mark -

- (NSString *)newDocumentMenuItemTitle {
	return NSLS(@"New Ban\u2026", @"New menu item");
}



- (NSString *)deleteDocumentMenuItemTitle {
	NSArray			*bans;
	
	bans = [self _selectedBans];
	
	switch([bans count]) {
		case 0:
			return NSLS(@"Delete Ban\u2026", @"Delete menu item");
			break;
		
		case 1:
			return [NSSWF:NSLS(@"Delete \u201c%@\u201d\u2026", @"Delete menu item (IP)"), ((WCBan *) [bans objectAtIndex:0])->_ip];
			break;
		
		default:
			return [NSSWF:NSLS(@"Delete %u Items\u2026", @"Delete menu item (count)"), [bans count]];
			break;
	}
}



#pragma mark -

- (IBAction)newDocument:(id)sender {
	[self addBan:sender];
}



- (IBAction)deleteDocument:(id)sender {
	[self deleteBan:sender];
}



- (IBAction)addBan:(id)sender {
	if(![self _validateAddBan])
		return;
	
	[NSApp beginSheet:_addBanPanel
	   modalForWindow:[_administration window]
		modalDelegate:self
	   didEndSelector:@selector(addSheetDidEnd:returnCode:contextInfo:)
		  contextInfo:NULL];
}



- (void)addSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	WIP7Message		*message;
	
	if(returnCode == NSAlertDefaultReturn) {
		message = [WIP7Message messageWithName:@"wired.banlist.add_ban" spec:WCP7Spec];
		[message setString:[_addBanTextField stringValue] forName:@"wired.banlist.ip"];
		
		if([_addBanPopUpButton tagOfSelectedItem] > 0) {
			[message setDate:[NSDate dateWithTimeIntervalSinceNow:[_addBanPopUpButton tagOfSelectedItem]]
					 forName:@"wired.banlist.expiration_date"];
		}
		
		[[_administration connection] sendMessage:message fromObserver:self selector:@selector(wiredBanlistAddBanReply:)];
	}
	
	[_addBanPanel close];
	[_addBanTextField setStringValue:@""];
}



- (IBAction)deleteBan:(id)sender {
	NSAlert			*alert;
	NSArray			*bans;
	NSString		*title;
	
	if(![self _validateDeleteBan])
		return;
	
	bans = [self _selectedBans];
	
	if([bans count] == 1) {
		title = [NSSWF:
			NSLS(@"Are you sure you want to delete \u201c%@\u201d?", @"Delete ban dialog title (IP)"),
			((WCBan *) [bans objectAtIndex:0])->_ip];
	} else {
		title = [NSSWF:
			NSLS(@"Are you sure you want to delete %lu items?", @"Delete ban dialog title (count)"),
			[bans count]];
	}

	alert = [[NSAlert alloc] init];
	[alert setMessageText:title];
	[alert setInformativeText:NSLS(@"This cannot be undone.", @"Delete ban dialog description")];
	[alert addButtonWithTitle:NSLS(@"Delete", @"Delete ban dialog button title")];
	[alert addButtonWithTitle:NSLS(@"Cancel", @"Delete ban dialog button title")];
	[alert beginSheetModalForWindow:[_administration window]
					  modalDelegate:self
					 didEndSelector:@selector(deleteSheetDidEnd:returnCode:contextInfo:)
						contextInfo:NULL];
	[alert release];
}



- (void)deleteSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	NSEnumerator	*enumerator;
	WIP7Message		*message;
	WCBan			*ban;
	
	if(returnCode == NSAlertFirstButtonReturn) {
		enumerator = [[self _selectedBans] objectEnumerator];
		
		while((ban = [enumerator nextObject])) {
			message = [WIP7Message messageWithName:@"wired.banlist.delete_ban" spec:WCP7Spec];
			[message setString:ban->_ip forName:@"wired.banlist.ip"];
			
			if(ban->_expirationDate)
				[message setDate:ban->_expirationDate forName:@"wired.banlist.expiration_date"];
			
			[[_administration connection] sendMessage:message fromObserver:self selector:@selector(wiredBanlistDeleteBanReply:)];
		}
		
		[self _requestBans];
	}
}



#pragma mark -

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return [_shownBans count];
}



- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	WCBan		*ban;
	
	ban = [self _banAtIndex:row];
	
	if(tableColumn == _ipTableColumn)
		return ban->_ip;
	else if(tableColumn == _expiresTableColumn)
		return ban->_expirationDate ? [_dateFormatter stringFromDate:ban->_expirationDate] : NSLS(@"Never", @"Banlist expiration");
	
	return NULL;
}



- (void)tableViewSelectionDidChange:(NSNotification *)notification {
	[self _validate];
}



- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn {
	[_banlistTableView setHighlightedTableColumn:tableColumn];
	[self _sortBans];
	[_banlistTableView reloadData];
}

@end
