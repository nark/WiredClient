/* $Id$ */

/*
 *  Copyright (c) 2009 Axel Andersson
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
#import "WCEventsController.h"
#import "WCServerConnection.h"

enum _WCEventType {
	WCEventUsers				= 0,
	WCEventFiles,
	WCEventAccounts,
	WCEventMessages,
	WCEventBoards,
	WCEventDownloads,
	WCEventUploads,
	WCEventAdministration,
	WCEventTracker,
};
typedef enum _WCEventType		WCEventType;


@interface WCEvent : WIObject {
@public
	WCEventType					_type;
	
	NSString					*_formattedTime;
	
	NSDate						*_time;
	NSString					*_nick;
	NSString					*_login;
	NSString					*_ip;
	NSString					*_message;
}

+ (WCEvent *)eventWithMessage:(WIP7Message *)message dateFormatter:(WIDateFormatter *)dateFormatter sizeFormatter:(WISizeFormatter *)sizeFormatter;

- (NSComparisonResult)compareType:(WCEvent *)event;
- (NSComparisonResult)compareTime:(WCEvent *)event;
- (NSComparisonResult)compareNick:(WCEvent *)event;
- (NSComparisonResult)compareLogin:(WCEvent *)event;
- (NSComparisonResult)compareIP:(WCEvent *)event;
- (NSComparisonResult)compareMessage:(WCEvent *)event;

@end


@implementation WCEvent

+ (WCEvent *)eventWithMessage:(WIP7Message *)message dateFormatter:(WIDateFormatter *)dateFormatter sizeFormatter:(WISizeFormatter *)sizeFormatter {
	NSArray			*parameters;
	NSString		*name, *string;
	WCEvent			*event;
	WCEventType		type;
	
	name			= [message enumNameForName:@"wired.event.event"];
	parameters		= [message listForName:@"wired.event.parameters"];
	
	if([name isEqualToString:@"wired.event.user.logged_in"] && [parameters count] >= 2) {
		type = WCEventUsers;
		string = [NSSWF:NSLS(@"Logged in using \u201c%@\u201d on \u201c%@\u201d", @"Event message (application, os)"),
			[parameters objectAtIndex:0],
			[parameters objectAtIndex:1]];
	}
	else if([name isEqualToString:@"wired.event.user.logged_out"]) {
		type = WCEventUsers;
		string = NSLS(@"Logged out", @"Event message");
	}
	else if([name isEqualToString:@"wired.event.user.login_failed"]) {
		type = WCEventUsers;
		string = NSLS(@"Login failed", @"Event message");
	}
	else if([name isEqualToString:@"wired.event.user.changed_nick"] && [parameters count] >= 2) {
		type = WCEventUsers;
		string = [NSSWF:NSLS(@"Changed nick from \u201c%@\u201d to \u201c%@\u201d", @"Event message (oldnick, newnick)"),
			[parameters objectAtIndex:0],
			[parameters objectAtIndex:1]];
	}
	else if([name isEqualToString:@"wired.event.user.got_info"] && [parameters count] >= 1) {
		type = WCEventUsers;
		string = [NSSWF:NSLS(@"Got info for \u201c%@\u201d", @"Event message (nick)"),
			[parameters objectAtIndex:0]];
	}
	else if([name isEqualToString:@"wired.event.user.disconnected_user"] && [parameters count] >= 1) {
		type = WCEventUsers;
		string = [NSSWF:NSLS(@"Disconnected \u201c%@\u201d", @"Event message (nick)"),
			[parameters objectAtIndex:0]];
	}
	else if([name isEqualToString:@"wired.event.user.banned_user"] && [parameters count] >= 1) {
		type = WCEventUsers;
		string = [NSSWF:NSLS(@"Banned \u201c%@\u201d", @"Event message (nick)"),
			[parameters objectAtIndex:0]];
	}
	else if([name isEqualToString:@"wired.event.user.got_users"]) {
		type = WCEventUsers;
		string = NSLS(@"Monitored users", @"Event message");
	}
	else if([name isEqualToString:@"wired.event.file.listed_directory"] && [parameters count] >= 1) {
		type = WCEventFiles;
		string = [NSSWF:NSLS(@"Listed \u201c%@\u201d", @"Event message (path)"),
			[parameters objectAtIndex:0]];
	}
	else if([name isEqualToString:@"wired.event.file.got_info"] && [parameters count] >= 1) {
		type = WCEventFiles;
		string = [NSSWF:NSLS(@"Got info for \u201c%@\u201d", @"Event message (path)"),
			[parameters objectAtIndex:0]];
	}
	else if([name isEqualToString:@"wired.event.file.moved"] && [parameters count] >= 2) {
		type = WCEventFiles;
		string = [NSSWF:NSLS(@"Moved \u201c%@\u201d to \u201c%@\u201d", @"Event message (frompath, topath)"),
			[parameters objectAtIndex:0],
			[parameters objectAtIndex:1]];
	}
	else if([name isEqualToString:@"wired.event.file.linked"] && [parameters count] >= 2) {
		type = WCEventFiles;
		string = [NSSWF:NSLS(@"Linked \u201c%@\u201d to \u201c%@\u201d", @"Event message (frompath, topath)"),
			[parameters objectAtIndex:0],
			[parameters objectAtIndex:1]];
	}
	else if([name isEqualToString:@"wired.event.file.set_type"] && [parameters count] >= 1) {
		type = WCEventFiles;
		string = [NSSWF:NSLS(@"Changed type for \u201c%@\u201d", @"Event message (path)"),
			[parameters objectAtIndex:0]];
	}
	else if([name isEqualToString:@"wired.event.file.set_comment"] && [parameters count] >= 1) {
		type = WCEventFiles;
		string = [NSSWF:NSLS(@"Changed comment for \u201c%@\u201d", @"Event message (path)"),
			[parameters objectAtIndex:0]];
	}
	else if([name isEqualToString:@"wired.event.file.set_executable"] && [parameters count] >= 1) {
		type = WCEventFiles;
		string = [NSSWF:NSLS(@"Changed executable mode for \u201c%@\u201d", @"Event message (path)"),
			[parameters objectAtIndex:0]];
	}
	else if([name isEqualToString:@"wired.event.file.set_permissions"] && [parameters count] >= 1) {
		type = WCEventFiles;
		string = [NSSWF:NSLS(@"Changed permissions for \u201c%@\u201d", @"Event message (path)"),
			[parameters objectAtIndex:0]];
	}
	else if([name isEqualToString:@"wired.event.file.set_label"] && [parameters count] >= 1) {
		type = WCEventFiles;
		string = [NSSWF:NSLS(@"Changed label for \u201c%@\u201d", @"Event message (path)"),
			[parameters objectAtIndex:0]];
	}
	else if([name isEqualToString:@"wired.event.file.deleted"] && [parameters count] >= 1) {
		type = WCEventFiles;
		string = [NSSWF:NSLS(@"Deleted \u201c%@\u201d", @"Event message (path)"),
			[parameters objectAtIndex:0]];
	}
	else if([name isEqualToString:@"wired.event.file.created_directory"] && [parameters count] >= 1) {
		type = WCEventFiles;
		string = [NSSWF:NSLS(@"Created \u201c%@\u201d", @"Event message (path)"),
			[parameters objectAtIndex:0]];
	}
	else if([name isEqualToString:@"wired.event.file.searched"] && [parameters count] >= 1) {
		type = WCEventFiles;
		string = [NSSWF:NSLS(@"Searched for \u201c%@\u201d", @"Event message (query)"),
			[parameters objectAtIndex:0]];
	}
	else if([name isEqualToString:@"wired.event.file.previewed_file"] && [parameters count] >= 1) {
		type = WCEventFiles;
		string = [NSSWF:NSLS(@"Previewed \u201c%@\u201d", @"Event message (path)"),
			[parameters objectAtIndex:0]];
	}
	else if([name isEqualToString:@"wired.event.account.changed_password"]) {
		type = WCEventAccounts;
		string = NSLS(@"Changed password", @"Event message");
	}
	else if([name isEqualToString:@"wired.event.account.listed_users"]) {
		type = WCEventAccounts;
		string = NSLS(@"Listed users", @"Event message");
	}
	else if([name isEqualToString:@"wired.event.account.listed_groups"]) {
		type = WCEventAccounts;
		string = NSLS(@"Listed groups", @"Event message");
	}
	else if([name isEqualToString:@"wired.event.account.read_user"] && [parameters count] >= 1) {
		type = WCEventAccounts;
		string = [NSSWF:NSLS(@"Read user \u201c%@\u201d", @"Event message (account)"),
			[parameters objectAtIndex:0]];
	}
	else if([name isEqualToString:@"wired.event.account.read_group"] && [parameters count] >= 1) {
		type = WCEventAccounts;
		string = [NSSWF:NSLS(@"Read group \u201c%@\u201d", @"Event message (account)"),
			[parameters objectAtIndex:0]];
	}
	else if([name isEqualToString:@"wired.event.account.created_user"] && [parameters count] >= 1) {
		type = WCEventAccounts;
		string = [NSSWF:NSLS(@"Created user \u201c%@\u201d", @"Event message (account)"),
			[parameters objectAtIndex:0]];
	}
	else if([name isEqualToString:@"wired.event.account.created_group"] && [parameters count] >= 1) {
		type = WCEventAccounts;
		string = [NSSWF:NSLS(@"Created group \u201c%@\u201d", @"Event message (account)"),
			[parameters objectAtIndex:0]];
	}
	else if([name isEqualToString:@"wired.event.account.edited_user"] && [parameters count] >= 1) {
		type = WCEventAccounts;
		string = [NSSWF:NSLS(@"Edited user \u201c%@\u201d", @"Event message (account)"),
			[parameters objectAtIndex:0]];
	}
	else if([name isEqualToString:@"wired.event.account.edited_group"] && [parameters count] >= 1) {
		type = WCEventAccounts;
		string = [NSSWF:NSLS(@"Edited group \u201c%@\u201d", @"Event message (account)"),
			[parameters objectAtIndex:0]];
	}
	else if([name isEqualToString:@"wired.event.account.deleted_user"] && [parameters count] >= 1) {
		type = WCEventAccounts;
		string = [NSSWF:NSLS(@"Deleted user \u201c%@\u201d", @"Event message (account)"),
			[parameters objectAtIndex:0]];
	}
	else if([name isEqualToString:@"wired.event.account.deleted_group"] && [parameters count] >= 1) {
		type = WCEventAccounts;
		string = [NSSWF:NSLS(@"Deleted group \u201c%@\u201d", @"Event message (account)"),
			[parameters objectAtIndex:0]];
	}
	else if([name isEqualToString:@"wired.event.message.sent"] && [parameters count] >= 1) {
		type = WCEventMessages;
		string = [NSSWF:NSLS(@"Sent message to \u201c%@\u201d", @"Event message (nick)"),
			[parameters objectAtIndex:0]];
	}
	else if([name isEqualToString:@"wired.event.message.broadcasted"]) {
		type = WCEventMessages;
		string = NSLS(@"Sent broadcast", @"Event message");
	}
	else if([name isEqualToString:@"wired.event.board.got_boards"]) {
		type = WCEventBoards;
		string = NSLS(@"Got boards", @"Event message");
	}
	else if([name isEqualToString:@"wired.event.board.got_threads"]) {
		type = WCEventBoards;
		string = NSLS(@"Got threads", @"Event message");
	}
	else if([name isEqualToString:@"wired.event.board.got_thread"] && [parameters count] >= 2) {
		type = WCEventBoards;
		string = [NSSWF:NSLS(@"Read thread \u201c%@\u201d in board \u201c%@\u201d", @"Event message (subject, board)"),
			[parameters objectAtIndex:0],
			[parameters objectAtIndex:1]];
	}
	else if([name isEqualToString:@"wired.event.board.added_board"] && [parameters count] >= 1) {
		type = WCEventBoards;
		string = [NSSWF:NSLS(@"Added \u201c%@\u201d", @"Event message (board)"),
			[parameters objectAtIndex:0]];
	}
	else if([name isEqualToString:@"wired.event.board.renamed_board"] && [parameters count] >= 2) {
		type = WCEventBoards;
		string = [NSSWF:NSLS(@"Renamed \u201c%@\u201d to \u201c%@\u201d", @"Event message (board)"),
			[parameters objectAtIndex:0],
			[parameters objectAtIndex:1]];
	}
	else if([name isEqualToString:@"wired.event.board.moved_board"] && [parameters count] >= 2) {
		type = WCEventBoards;
		string = [NSSWF:NSLS(@"Moved \u201c%@\u201d to \u201c%@\u201d", @"Event message (board)"),
			[parameters objectAtIndex:0],
			[parameters objectAtIndex:1]];
	}
	else if([name isEqualToString:@"wired.event.board.deleted_board"] && [parameters count] >= 1) {
		type = WCEventBoards;
		string = [NSSWF:NSLS(@"Deleted \u201c%@\u201d", @"Event message (board)"),
			[parameters objectAtIndex:0]];
	}
	else if([name isEqualToString:@"wired.event.board.set_permissions"] && [parameters count] >= 1) {
		type = WCEventBoards;
		string = [NSSWF:NSLS(@"Change permissions for \u201c%@\u201d", @"Event message (board)"),
			[parameters objectAtIndex:0]];
	}
	else if([name isEqualToString:@"wired.event.board.added_thread"] && [parameters count] >= 2) {
		type = WCEventBoards;
		string = [NSSWF:NSLS(@"Added \u201c%@\u201d in \u201c%@\u201d", @"Event message (subject, board)"),
			[parameters objectAtIndex:0],
			[parameters objectAtIndex:1]];
	}
	else if([name isEqualToString:@"wired.event.board.edited_thread"] && [parameters count] >= 2) {
		type = WCEventBoards;
		string = [NSSWF:NSLS(@"Edited \u201c%@\u201d in \u201c%@\u201d", @"Event message (subject, board)"),
			[parameters objectAtIndex:0],
			[parameters objectAtIndex:1]];
	}
	else if([name isEqualToString:@"wired.event.board.moved_thread"] && [parameters count] >= 3) {
		type = WCEventBoards;
		string = [NSSWF:NSLS(@"Moved \u201c%@\u201d from \u201c%@\u201d to \u201c%@\u201d", @"Event message (subject, oldboard, newboard)"),
			[parameters objectAtIndex:0],
			[parameters objectAtIndex:1],
			[parameters objectAtIndex:2]];
	}
	else if([name isEqualToString:@"wired.event.board.deleted_thread"] && [parameters count] >= 2) {
		type = WCEventBoards;
		string = [NSSWF:NSLS(@"Deleted \u201c%@\u201d in \u201c%@\u201d", @"Event message (subject, board)"),
			[parameters objectAtIndex:0],
			[parameters objectAtIndex:1]];
	}
	else if([name isEqualToString:@"wired.event.board.added_post"] && [parameters count] >= 2) {
		type = WCEventBoards;
		string = [NSSWF:NSLS(@"Added \u201c%@\u201d in \u201c%@\u201d", @"Event message (subject, board)"),
			[parameters objectAtIndex:0],
			[parameters objectAtIndex:1]];
	}
	else if([name isEqualToString:@"wired.event.board.edited_post"] && [parameters count] >= 2) {
		type = WCEventBoards;
		string = [NSSWF:NSLS(@"Edited \u201c%@\u201d in \u201c%@\u201d", @"Event message (subject, board)"),
			[parameters objectAtIndex:0],
			[parameters objectAtIndex:1]];
	}
	else if([name isEqualToString:@"wired.event.board.deleted_post"] && [parameters count] >= 2) {
		type = WCEventBoards;
		string = [NSSWF:NSLS(@"Deleted \u201c%@\u201d \u201c%@\u201d", @"Event message (subject, board)"),
			[parameters objectAtIndex:0],
			[parameters objectAtIndex:1]];
	}
	else if([name isEqualToString:@"wired.event.transfer.started_file_download"] && [parameters count] >= 1) {
		type = WCEventDownloads;
		string = [NSSWF:NSLS(@"Started download of \u201c%@\u201d", @"Event message (path)"),
			[parameters objectAtIndex:0]];
	}
	else if([name isEqualToString:@"wired.event.transfer.stopped_file_download"] && [parameters count] >= 2) {
		type = WCEventDownloads;
		string = [NSSWF:NSLS(@"Stopped download of \u201c%@\u201d after sending %@", @"Event message (path, size)"),
			[parameters objectAtIndex:0],
			[sizeFormatter stringFromSize:[[parameters objectAtIndex:1] unsignedLongLongValue]]];
	}
	else if([name isEqualToString:@"wired.event.transfer.completed_file_download"] && [parameters count] >= 2) {
		type = WCEventDownloads;
		string = [NSSWF:NSLS(@"Completed download of \u201c%@\u201d after sending %@", @"Event message (path, size)"),
			[parameters objectAtIndex:0],
			[sizeFormatter stringFromSize:[[parameters objectAtIndex:1] unsignedLongLongValue]]];
	}
	else if([name isEqualToString:@"wired.event.transfer.started_file_upload"] && [parameters count] >= 1) {
		type = WCEventUploads;
		string = [NSSWF:NSLS(@"Started upload of \u201c%@\u201d", @"Event message (path)"),
			[parameters objectAtIndex:0]];
	}
	else if([name isEqualToString:@"wired.event.transfer.stopped_file_upload"] && [parameters count] >= 2) {
		type = WCEventUploads;
		string = [NSSWF:NSLS(@"Stopped upload of \u201c%@\u201d after sending %@", @"Event message (path, size)"),
			[parameters objectAtIndex:0],
			[sizeFormatter stringFromSize:[[parameters objectAtIndex:1] unsignedLongLongValue]]];
	}
	else if([name isEqualToString:@"wired.event.transfer.completed_file_upload"] && [parameters count] >= 2) {
		type = WCEventUploads;
		string = [NSSWF:NSLS(@"Completed upload of \u201c%@\u201d after sending %@", @"Event message (path, size)"),
			[parameters objectAtIndex:0],
			[sizeFormatter stringFromSize:[[parameters objectAtIndex:1] unsignedLongLongValue]]];
	}
	else if([name isEqualToString:@"wired.event.transfer.completed_directory_upload"] && [parameters count] >= 1) {
		type = WCEventUploads;
		string = [NSSWF:NSLS(@"Completed upload of \u201c%@\u201d", @"Event message (path)"),
			[parameters objectAtIndex:0]];
	}
	else if([name isEqualToString:@"wired.event.log.got_log"]) {
		type = WCEventAdministration;
		string = NSLS(@"Got log", @"Event message");
	}
	else if([name isEqualToString:@"wired.event.events.got_events"]) {
		type = WCEventAdministration;
		string = NSLS(@"Got events", @"Event message");
	}
	else if([name isEqualToString:@"wired.event.settings.got_settings"]) {
		type = WCEventAdministration;
		string = NSLS(@"Got settings", @"Event message");
	}
	else if([name isEqualToString:@"wired.event.settings.set_settings"]) {
		type = WCEventAdministration;
		string = NSLS(@"Set settings", @"Event message");
	}
	else if([name isEqualToString:@"wired.event.banlist.got_bans"]) {
		type = WCEventAdministration;
		string = NSLS(@"Got banlist", @"Event message");
	}
	else if([name isEqualToString:@"wired.event.banlist.added_ban"] && [parameters count] >= 1) {
		type = WCEventAdministration;
		string = [NSSWF:NSLS(@"Added ban of \u201c%@\u201d", @"Event message (ip)"),
			[parameters objectAtIndex:0]];
	}
	else if([name isEqualToString:@"wired.event.banlist.deleted_ban"] && [parameters count] >= 1) {
		type = WCEventAdministration;
		string = [NSSWF:NSLS(@"Deleted ban of \u201c%@\u201d", @"Event message (ip)"),
			[parameters objectAtIndex:0]];
	}
	else if([name isEqualToString:@"wired.event.tracker.got_categories"]) {
		type = WCEventTracker;
		string = NSLS(@"Got tracker categories", @"Event message");
	}
	else if([name isEqualToString:@"wired.event.tracker.got_servers"]) {
		type = WCEventTracker;
		string = NSLS(@"Got tracker servers", @"Event message");
	}
	else if([name isEqualToString:@"wired.event.tracker.registered_server"] && [parameters count] >= 1) {
		type = WCEventTracker;
		string = [NSSWF:NSLS(@"Registered server \u201c%@\u201d", @"Event message (server)"),
			[parameters objectAtIndex:0]];
	}
	else {
		type = 0;
		string = NULL;
	}
	
	if(!string)
		return NULL;
	
	event					= [[self alloc] init];
	event->_type			= type;
	event->_message			= [string retain];
	event->_time			= [[message dateForName:@"wired.event.time"] retain];
	event->_nick			= [[message stringForName:@"wired.user.nick"] retain];
	event->_login			= [[message stringForName:@"wired.user.login"] retain];
	event->_ip				= [[message stringForName:@"wired.user.ip"] retain];
	event->_formattedTime	= [[dateFormatter stringFromDate:event->_time] retain];
	
	return [event autorelease];
}



- (void)dealloc {
	[_formattedTime release];

	[_time release];
	[_nick release];
	[_login release];
	[_ip release];
	[_message release];
	
	[super dealloc];
}



#pragma mark -

- (NSComparisonResult)compareType:(WCEvent *)event {
	if(self->_type < event->_type)
		return NSOrderedAscending;
	else if(self->_type > event->_type)
		return NSOrderedDescending;
	
	return NSOrderedSame;
}



- (NSComparisonResult)compareTime:(WCEvent *)event {
	return [self->_time compare:event->_time];
}



- (NSComparisonResult)compareNick:(WCEvent *)event {
	NSComparisonResult	result;
	
	result = [self->_nick caseInsensitiveCompare:event->_nick];
	
	if(result == NSOrderedSame)
		result = [self compareTime:event];
	
	return result;
}



- (NSComparisonResult)compareLogin:(WCEvent *)event {
	NSComparisonResult	result;
	
	result = [self->_login caseInsensitiveCompare:event->_login];
	
	if(result == NSOrderedSame)
		result = [self compareTime:event];
	
	return result;
}



- (NSComparisonResult)compareIP:(WCEvent *)event {
	NSComparisonResult	result;
	
	result = [self->_ip caseInsensitiveAndNumericCompare:event->_ip];
	
	if(result == NSOrderedSame)
		result = [self compareTime:event];
	
	return result;
}



- (NSComparisonResult)compareMessage:(WCEvent *)event {
	NSComparisonResult	result;
	
	result = [self->_message caseInsensitiveCompare:event->_message];
	
	if(result == NSOrderedSame)
		result = [self compareTime:event];
	
	return result;
}

@end



@interface WCEventsController(Private)

- (WCEvent *)_eventAtIndex:(NSUInteger)index;
- (BOOL)_filterIncludesEvent:(WCEvent *)event;
- (void)_reloadFilter;
- (void)_reloadPopUpButtons;
- (void)_reloadDates;
- (void)_refreshReceivedEvents;

- (void)_requestEvents;
- (void)_sortEvents;

@end


@implementation WCEventsController(Private)

- (WCEvent *)_eventAtIndex:(NSUInteger)index {
	NSUInteger		i;
	
	i = ([_eventsTableView sortOrder] == WISortDescending)
		? [_shownEvents count] - index - 1
		: index;
	
	return [_shownEvents objectAtIndex:i];
}



- (BOOL)_filterIncludesEvent:(WCEvent *)event {
	NSInteger		type;
	
	if([_nickPopUpButton tagOfSelectedItem] >= 0) {
		if(![[_nickPopUpButton titleOfSelectedItem] isEqualToString:event->_nick])
			return NO;
	}
	
	if([_loginPopUpButton tagOfSelectedItem] >= 0) {
		if(![[_loginPopUpButton titleOfSelectedItem] isEqualToString:event->_login])
			return NO;
	}
	
	if([_ipPopUpButton tagOfSelectedItem] >= 0) {
		if(![[_ipPopUpButton titleOfSelectedItem] isEqualToString:event->_ip])
			return NO;
	}
	
	type = [_typePopUpButton tagOfSelectedItem];
	
	if(type >= 0) {
		if((NSUInteger) type != event->_type)
			return NO;
	}
	
	if(_messageFilter && ![event->_message containsSubstring:_messageFilter options:NSCaseInsensitiveSearch])
		return NO;
	
	return YES;
}



- (void)_reloadFilter {
	NSArray			*events;
	WCEvent			*event;
	NSUInteger		i, count;
	
	[_shownEvents removeAllObjects];
	
	events		= ([[_datePopUpButton representedObjectOfSelectedItem] isEqual:[NSNull null]]
		? _allCurrentEvents
		: _allArchivedEvents);
	count		= [events count];
	
	for(i = 0; i < count; i++) {
		event = [events objectAtIndex:i];
		
		if([self _filterIncludesEvent:event])
			[_shownEvents addObject:event];
	}
	
	[_eventsTableView reloadData];
	[_eventsTableView scrollRowToVisible:[_shownEvents count] - 1];
}



- (void)_reloadPopUpButtons {
	while([_nickPopUpButton numberOfItems] > 1)
		[_nickPopUpButton removeItemAtIndex:1];
	
	[_nickPopUpButton addItemsWithTitles:[[_allNicks allObjects] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]];
	
	if([_nickPopUpButton numberOfItems] > 1)
		[_nickPopUpButton insertItem:[NSMenuItem separatorItem] atIndex:1];

	while([_loginPopUpButton numberOfItems] > 1)
		[_loginPopUpButton removeItemAtIndex:1];
	
	[_loginPopUpButton addItemsWithTitles:[[_allLogins allObjects] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]];
	
	if([_loginPopUpButton numberOfItems] > 1)
		[_loginPopUpButton insertItem:[NSMenuItem separatorItem] atIndex:1];
	
	while([_ipPopUpButton numberOfItems] > 1)
		[_ipPopUpButton removeItemAtIndex:1];
	
	[_ipPopUpButton addItemsWithTitles:[[_allIPs allObjects] sortedArrayUsingSelector:@selector(caseInsensitiveAndNumericCompare:)]];
	
	if([_ipPopUpButton numberOfItems] > 1)
		[_ipPopUpButton insertItem:[NSMenuItem separatorItem] atIndex:1];
}



- (void)_reloadDates {
	NSMutableArray			*menuItems;
	NSDate					*date, *weekDate, *selectedDate;
	NSDateComponents		*components;
	NSString				*title;
	
	selectedDate = [_datePopUpButton representedObjectOfSelectedItem];
	
	while([_datePopUpButton numberOfItems] > 1)
		[_datePopUpButton removeItemAtIndex:1];
	
	date		= [NSDate date];
	weekDate	= [_firstDate dateAtStartOfWeek];
	menuItems	= [NSMutableArray array];
	
	while([date compare:weekDate] == NSOrderedDescending) {
		components	= [[NSCalendar currentCalendar] components:NSCalendarUnitYear | NSCalendarUnitWeekOfYear fromDate:weekDate];
		title		= [NSSWF:NSLS(@"Week %u, %u", @"Event archive (week, year)"), [components weekOfYear], [components year]];

		[menuItems addObject:[NSMenuItem itemWithTitle:title representedObject:weekDate]];
		
		weekDate = [weekDate dateByAddingDays:7];
	}
	
	if([menuItems count] > 0) {
		[_datePopUpButton addItem:[NSMenuItem separatorItem]];
		[_datePopUpButton addItems:[menuItems reversedArray]];
	}
	
	if(selectedDate)
		[_datePopUpButton selectItemWithRepresentedObject:selectedDate];
}



- (void)_refreshReceivedEvents {
	WCEvent			*event;
	NSUInteger		i, count;
	BOOL			reloadPopUpButtons = NO;
	
	count = [_receivedEvents count];
	
	for(i = 0; i < count; i++) {
		event = [_receivedEvents objectAtIndex:i];

		if([[_datePopUpButton representedObjectOfSelectedItem] isEqual:[NSNull null]] && [self _filterIncludesEvent:event])
			[_shownEvents addObject:event];
		
		if(![_allNicks containsObject:event->_nick]) {
			[_allNicks addObject:event->_nick];
			
			reloadPopUpButtons = YES;
		}
		
		if(![_allLogins containsObject:event->_login]) {
			[_allLogins addObject:event->_login];
			
			reloadPopUpButtons = YES;
		}
		
		if(![_allIPs containsObject:event->_ip]) {
			[_allIPs addObject:event->_ip];
			
			reloadPopUpButtons = YES;
		}
	}
	
	[_receivedEvents removeAllObjects];

	[_eventsTableView reloadData];
	[_eventsTableView scrollRowToVisible:[_shownEvents count] - 1];
	
	if(reloadPopUpButtons)
		[self _reloadPopUpButtons];
}



#pragma mark -

- (void)_requestEvents {
	WIP7Message		*message;
	
	if(!_requested && [[_administration connection] isConnected] && [[[_administration connection] account] eventsViewEvents]) {
		message = [WIP7Message messageWithName:@"wired.event.get_first_time" spec:WCP7Spec];
		[[_administration connection] sendMessage:message fromObserver:self selector:@selector(wiredEventGetFirstTimeReply:)];
		
		message = [WIP7Message messageWithName:@"wired.event.get_events" spec:WCP7Spec];
		[message setUInt32:1000 forName:@"wired.event.last_event_count"];
		[[_administration connection] sendMessage:message fromObserver:self selector:@selector(wiredEventGetEventsReply:)];
		
		message = [WIP7Message messageWithName:@"wired.event.subscribe" spec:WCP7Spec];
		[[_administration connection] sendMessage:message fromObserver:self selector:@selector(wiredEventSubscribeReply:)];
		
		_requested = YES;
	}
}



- (void)_sortEvents {
	NSTableColumn   *tableColumn;

	tableColumn = [_eventsTableView highlightedTableColumn];
	
	if(tableColumn == _timeTableColumn)
		[_shownEvents sortUsingSelector:@selector(compareTime:)];
	else if(tableColumn == _nickTableColumn)
		[_shownEvents sortUsingSelector:@selector(compareNick:)];
	else if(tableColumn == _loginTableColumn)
		[_shownEvents sortUsingSelector:@selector(compareLogin:)];
	else if(tableColumn == _ipTableColumn)
		[_shownEvents sortUsingSelector:@selector(compareIP:)];
	else if(tableColumn == _imageTableColumn)
		[_shownEvents sortUsingSelector:@selector(compareType:)];
	else if(tableColumn == _messageTableColumn)
		[_shownEvents sortUsingSelector:@selector(compareMessage:)];
}

@end



@implementation WCEventsController

- (id)init {
	self = [super init];
	
	_allCurrentEvents	= [[NSMutableArray alloc] init];
	_allArchivedEvents	= [[NSMutableArray alloc] init];
	_listedEvents		= [[NSMutableArray alloc] init];
	_receivedEvents		= [[NSMutableArray alloc] init];
	_shownEvents		= [[NSMutableArray alloc] init];
	
	_allNicks			= [[NSMutableSet alloc] init];
	_allLogins			= [[NSMutableSet alloc] init];
	_allIPs				= [[NSMutableSet alloc] init];
	
	_dateFormatter = [[WIDateFormatter alloc] init];
	[_dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	[_dateFormatter setDateStyle:NSDateFormatterMediumStyle];
	
	_sizeFormatter = [[WISizeFormatter alloc] init];

	return self;
}



- (void)dealloc {
	[_allCurrentEvents release];
	[_allArchivedEvents release];
	[_listedEvents release];
	[_receivedEvents release];
	[_shownEvents release];
	
	[_dateFormatter release];
	[_sizeFormatter release];
	
	[_allNicks release];
	[_allLogins release];
	[_allIPs release];
	[_messageFilter release];
	
	[_firstDate release];
	
	[super dealloc];
}



#pragma mark -

- (void)windowDidLoad {
	[[_administration connection] addObserver:self selector:@selector(wiredEventEvent:) messageName:@"wired.event.event"];
	
	[_eventsTableView setHighlightedTableColumn:_timeTableColumn sortOrder:WISortAscending];
	
	[[_datePopUpButton itemAtIndex:0] setRepresentedObject:[NSNull null]];
}



- (void)linkConnectionLoggedIn:(NSNotification *)notification {
	_requested = NO;
	
	if([[_administration window] isVisible] && [_administration selectedController] == self)
		[self _requestEvents];
}



- (void)serverConnectionPrivilegesDidChange:(NSNotification *)notification {
	if([[[_administration connection] account] eventsViewEvents]) {
		if([[_administration window] isVisible] && [_administration selectedController] == self)
			[self _requestEvents];
	} else {
		_requested = NO;
	}
}



- (void)wiredEventGetFirstTimeReply:(WIP7Message *)message {
	if([[message name] isEqualToString:@"wired.event.first_time"]) {
		[_firstDate release];
		_firstDate = [[message dateForName:@"wired.event.first_time"] retain];
		
		[self _reloadDates];
	}
	else if([[message name] isEqualToString:@"wired.error"]) {
		[_administration showError:[WCError errorWithWiredMessage:message]];
		
		[[_administration connection] removeObserver:self message:message];
	}
}



- (void)wiredEventGetEventsReply:(WIP7Message *)message {
	NSMutableArray		*events;
	WCEvent				*event;
	NSUInteger			i, count;
	
	if([[message name] isEqualToString:@"wired.event.event_list"]) {
		event = [WCEvent eventWithMessage:message dateFormatter:_dateFormatter sizeFormatter:_sizeFormatter];
		
		if(event) {
			[_listedEvents addObject:event];
			
			[_allNicks addObject:event->_nick];
			[_allLogins addObject:event->_login];
			[_allIPs addObject:event->_ip];
		}
	}
	else if([[message name] isEqualToString:@"wired.event.event_list.done"]) {
		if([_listedEvents count] > 0) {
			event		= [_listedEvents objectAtIndex:0];
			events		= ([[_datePopUpButton representedObjectOfSelectedItem] isEqual:[NSNull null]]
				? _allCurrentEvents
				: _allArchivedEvents);
			
			[events addObjectsFromArray:_listedEvents];
		}
		
		[self _reloadPopUpButtons];
		
		count = [_listedEvents count];
		
		for(i = 0; i < count; i++) {
			event = [_listedEvents objectAtIndex:i];
			
			if([self _filterIncludesEvent:event])
				[_shownEvents addObject:event];
		}
		
		[self _sortEvents];
		
		[_listedEvents removeAllObjects];
		
		[_eventsTableView reloadData];
		[_eventsTableView scrollRowToVisible:[_shownEvents count] - 1];
		
		[[_administration connection] removeObserver:self message:message];
	}
	else if([[message name] isEqualToString:@"wired.error"]) {
		[_administration showError:[WCError errorWithWiredMessage:message]];
		
		[[_administration connection] removeObserver:self message:message];
	}
}



- (void)wiredEventSubscribeReply:(WIP7Message *)message {
	if([[message name] isEqualToString:@"wired.okay"]) {
		[[_administration connection] removeObserver:self message:message];
	}
	else if([[message name] isEqualToString:@"wired.error"]) {
		[_administration showError:[WCError errorWithWiredMessage:message]];
		
		[[_administration connection] removeObserver:self message:message];
	}
}



- (void)wiredEventEvent:(WIP7Message *)message {
	WCEvent				*event;
	
	event = [WCEvent eventWithMessage:message dateFormatter:_dateFormatter sizeFormatter:_sizeFormatter];
	
	if(event) {
		[_allCurrentEvents addObject:event];
		[_receivedEvents addObject:event];
		
		if([_receivedEvents count] > 20)
			[self _refreshReceivedEvents];
		else
			[self performSelectorOnce:@selector(_refreshReceivedEvents) afterDelay:0.1];
	}
}



- (void)wiredDeleteEventsReply:(WIP7Message *)message {
	if([[message name] isEqualToString:@"wired.okay"]) {
		[[_administration connection] removeObserver:self message:message];
	}
	else if([[message name] isEqualToString:@"wired.error"]) {
		[_administration showError:[WCError errorWithWiredMessage:message]];
		
		[[_administration connection] removeObserver:self message:message];
	}
}



#pragma mark -

- (void)controllerWindowDidBecomeKey {
	[self _requestEvents];
}



- (void)controllerDidSelect {
	[self _requestEvents];

	[[_administration window] makeFirstResponder:_eventsTableView];
	
	[_startDatePicker setDateValue:[NSDate date]];
	[_endDatePicker setDateValue:[NSDate dateWithTimeInterval:-7*24*3600 sinceDate:[_startDatePicker dateValue]]];
}



#pragma mark -

- (IBAction)date:(id)sender {
	WIP7Message		*message;
	NSDate			*date;
	
	date = [_datePopUpButton representedObjectOfSelectedItem];
	
	if([date isEqual:[NSNull null]]) {
		[self _reloadFilter];
	} else {
		message = [WIP7Message messageWithName:@"wired.event.get_events" spec:WCP7Spec];
		[message setDate:date forName:@"wired.event.from_time"];
		[message setUInt32:7 forName:@"wired.event.number_of_days"];
		[[_administration connection] sendMessage:message fromObserver:self selector:@selector(wiredEventGetEventsReply:)];
	}
}



- (IBAction)nick:(id)sender {
	[self _reloadFilter];
}



- (IBAction)login:(id)sender {
	[self _reloadFilter];
}



- (IBAction)ip:(id)sender {
	[self _reloadFilter];
}



- (IBAction)type:(id)sender {
	[self _reloadFilter];
}



- (IBAction)message:(id)sender {
	[_messageFilter release];
	
	if([[_messageSearchField stringValue] length] > 0)
		_messageFilter = [[_messageSearchField stringValue] retain];
	else
		_messageFilter = NULL;
	
	[self _reloadFilter];
}

- (IBAction)clearEvents:(id)sender {
	
	[NSApp beginSheet:_clearEventsWindow
	   modalForWindow:[_administration window]
        modalDelegate:self 
	   didEndSelector:NULL
		  contextInfo:nil];
}

- (IBAction)okClear:(id)sender {
	WIP7Message *message;
	
	[NSApp endSheet:_clearEventsWindow];
	[_clearEventsWindow orderOut:sender];
	
	message = [WIP7Message messageWithName:@"wired.event.delete_events" spec:WCP7Spec];
	
	if([_clearMethodMatrix selectedRow] == 1) {
		
		[message setDate:[_startDatePicker dateValue] forName:@"wired.event.from_time"];
		[message setDate:[_endDatePicker dateValue] forName:@"wired.event.to_time"];
	}
	
	[[_administration connection] sendMessage:message 
								 fromObserver:self 
									 selector:@selector(wiredDeleteEventsReply:)];
}

- (IBAction)cancelClear:(id)sender {
	[NSApp endSheet:_clearEventsWindow];
	[_clearEventsWindow orderOut:sender];
}



#pragma mark -

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return [_shownEvents count];
}



- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	WCEvent			*event;
	
	event = [self _eventAtIndex:row];
	
	if(tableColumn == _timeTableColumn)
		return event->_formattedTime;
	else if(tableColumn == _nickTableColumn)
		return event->_nick;
	else if(tableColumn == _loginTableColumn)
		return event->_login;
	else if(tableColumn == _ipTableColumn)
		return event->_ip;
	else if(tableColumn == _imageTableColumn) {
		switch(event->_type) {
			case WCEventUsers:				return [NSImage imageNamed:@"EventsUsers"];				break;
			case WCEventFiles:				return [NSImage imageNamed:@"EventsFiles"];				break;
			case WCEventAccounts:			return [NSImage imageNamed:@"EventsAccounts"];			break;
			case WCEventMessages:			return [NSImage imageNamed:@"EventsMessages"];			break;
			case WCEventBoards:				return [NSImage imageNamed:@"EventsBoards"];			break;
			case WCEventDownloads:			return [NSImage imageNamed:@"EventsDownloads"];			break;
			case WCEventUploads:			return [NSImage imageNamed:@"EventsUploads"];			break;
			case WCEventAdministration:		return [NSImage imageNamed:@"EventsAdministration"];	break;
			case WCEventTracker:			return [NSImage imageNamed:@"EventsTracker"];			break;
		}
	}
	else if(tableColumn == _messageTableColumn)
		return event->_message;

	return NULL;
}



- (void)tableViewShouldCopyInfo:(NSTableView *)tableView {
	NSPasteboard		*pasteboard;
	NSMutableArray		*array;
	NSIndexSet			*indexes;
	WCEvent				*event;
	NSUInteger			index;
	
	array		= [NSMutableArray array];
	indexes		= [_eventsTableView selectedRowIndexes];
	index		= [indexes firstIndex];
	
	while(index != NSNotFound) {
		event = [self _eventAtIndex:index];
		
		[array addObject:[NSSWF:@"%@\t%@\t%@\t%@\t%@",
			event->_formattedTime, event->_nick, event->_login, event->_ip, event->_message]];
		
		index = [indexes indexGreaterThanIndex:index];
    }

	pasteboard = [NSPasteboard generalPasteboard];
	[pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:NULL];
	[pasteboard setString:[array componentsJoinedByString:@"\n"] forType:NSStringPboardType];
}



- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn {
	[_eventsTableView setHighlightedTableColumn:tableColumn];
	[self _sortEvents];
	[_eventsTableView reloadData];
}

@end
