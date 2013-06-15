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
#import "WCServerConnection.h"

NSString * const WCAccountFieldNameKey				= @"WCAccountFieldNameKey";
NSString * const WCAccountFieldLocalizedNameKey		= @"WCAccountFieldLocalizedNameKey";
NSString * const WCAccountFieldTypeKey				= @"WCAccountFieldTypeKey";
NSString * const WCAccountFieldSectionKey			= @"WCAccountFieldSectionKey";
NSString * const WCAccountFieldReadOnlyKey			= @"WCAccountFieldReadOnlyKey";
NSString * const WCAccountFieldToolTipKey			= @"WCAccountFieldToolTipKey";


@interface WCAccount(Private)

- (id)_initWithMessage:(WIP7Message *)message;

- (void)_writeToMessage:(WIP7Message *)message;

@end


@implementation WCAccount(Private)

- (id)_initWithMessage:(WIP7Message *)message {
	NSEnumerator	*enumerator;
	NSDictionary	*field;
	NSString		*name;
	id				value;
	
	self = [self init];
	
	enumerator = [[[self class] fields] objectEnumerator];
	
	while((field = [enumerator nextObject])) {
		name	= [field objectForKey:WCAccountFieldNameKey];
		value	= NULL;
		
		switch((WCAccountFieldType) [[field objectForKey:WCAccountFieldTypeKey] integerValue]) {
			case WCAccountFieldTypeString:
				value = [message stringForName:name];
				break;
			
			case WCAccountFieldTypeDate:
				value = [message dateForName:name];
				break;

			case WCAccountFieldTypeNumber:
			case WCAccountFieldTypeBoolean:
			case WCAccountFieldTypeEnum:
				value = [message numberForName:name];
				break;
			
			case WCAccountFieldTypeList:
				value = [message listForName:name];
				break;
		}
		
		if(value)
			[_values setObject:value forKey:name];
	}
	
	_originalValues = [_values copy];

	return self;
}



#pragma mark -

- (void)_writeToMessage:(WIP7Message *)message {
	NSEnumerator	*enumerator;
	NSDictionary	*field;
	NSString		*name;
	id				value;
	
	enumerator = [[[self class] fields] objectEnumerator];
	
	while((field = [enumerator nextObject])) {
		if(![[field objectForKey:WCAccountFieldReadOnlyKey] boolValue]) {
			name	= [field objectForKey:WCAccountFieldNameKey];
			value	= [self valueForKey:name];
			
			if(value) {
				switch((WCAccountFieldType) [[field objectForKey:WCAccountFieldTypeKey] integerValue]) {
					case WCAccountFieldTypeString:
						[message setString:value forName:name];
						break;
					
					case WCAccountFieldTypeDate:
						[message setDate:value forName:name];
						break;

					case WCAccountFieldTypeNumber:
					case WCAccountFieldTypeBoolean:
					case WCAccountFieldTypeEnum:
						[message setNumber:value forName:name];
						break;

					case WCAccountFieldTypeList:
						[message setList:value forName:name];
						break;
				}
			}
		}
	}
}

@end


@implementation WCAccount

#define WCAccountFieldDictionary(section, name, localizedname, type, readonly, tooltip)		\
	[NSDictionary dictionaryWithObjectsAndKeys:												\
		[NSNumber numberWithInteger:(section)],		WCAccountFieldSectionKey,				\
		(name),										WCAccountFieldNameKey,					\
		(localizedname),							WCAccountFieldLocalizedNameKey,			\
		[NSNumber numberWithInteger:(type)],		WCAccountFieldTypeKey,					\
		[NSNumber numberWithBool:(readonly)],		WCAccountFieldReadOnlyKey,				\
		(tooltip),									WCAccountFieldToolTipKey,				\
		NULL]

#define WCAccountFieldBooleanDictionary(section, name, localizedname, tooltip)				\
	WCAccountFieldDictionary((section), (name), (localizedname), WCAccountFieldTypeBoolean, NO, (tooltip))

#define WCAccountFieldNumberDictionary(section, name, localizedname, tooltip)				\
	WCAccountFieldDictionary((section), (name), (localizedname), WCAccountFieldTypeNumber, NO, (tooltip))

+ (NSArray *)fields {
	static NSArray		*fields;
	
	if(fields)
		return fields;
	
	fields = [[NSArray alloc] initWithObjects:
		WCAccountFieldDictionary(WCAccountFieldSectionNone,
			@"wired.account.name", @"", WCAccountFieldTypeString, NO, @""),
		WCAccountFieldDictionary(WCAccountFieldSectionNone,
			@"wired.account.new_name", @"", WCAccountFieldTypeString, NO, @""),
		WCAccountFieldDictionary(WCAccountFieldSectionNone,
			@"wired.account.full_name", @"", WCAccountFieldTypeString, NO, @""),
		WCAccountFieldDictionary(WCAccountFieldSectionNone,
			@"wired.account.comment", @"", WCAccountFieldTypeString, NO, @""),
		WCAccountFieldDictionary(WCAccountFieldSectionNone,
			@"wired.account.creation_time", @"", WCAccountFieldTypeDate, YES, @""),
		WCAccountFieldDictionary(WCAccountFieldSectionNone,
			@"wired.account.modification_time", @"", WCAccountFieldTypeDate, YES, @""),
		WCAccountFieldDictionary(WCAccountFieldSectionNone,
			@"wired.account.login_time", @"", WCAccountFieldTypeDate, YES, @""),
		WCAccountFieldDictionary(WCAccountFieldSectionNone,
			@"wired.account.edited_by", @"", WCAccountFieldTypeString, YES, @""),
		WCAccountFieldDictionary(WCAccountFieldSectionNone,
			@"wired.account.downloads", @"", WCAccountFieldTypeNumber, YES, @""),
		WCAccountFieldDictionary(WCAccountFieldSectionNone,
			@"wired.account.download_transferred", @"", WCAccountFieldTypeNumber, YES, @""),
		WCAccountFieldDictionary(WCAccountFieldSectionNone,
			@"wired.account.uploads", @"", WCAccountFieldTypeNumber, YES, @""),
		WCAccountFieldDictionary(WCAccountFieldSectionNone,
			@"wired.account.upload_transferred", @"", WCAccountFieldTypeNumber, YES, @""),
		WCAccountFieldDictionary(WCAccountFieldSectionNone,
			@"wired.account.group", @"", WCAccountFieldTypeString, NO, @""),
		WCAccountFieldDictionary(WCAccountFieldSectionNone,
			@"wired.account.groups", @"", WCAccountFieldTypeList, NO, @""),
		WCAccountFieldDictionary(WCAccountFieldSectionNone,
			@"wired.account.password", @"", WCAccountFieldTypeString, NO, @""),
		
		WCAccountFieldDictionary(WCAccountFieldSectionBasics,
			@"wired.account.color", NSLS(@"Color", @"Account field name"), WCAccountFieldTypeEnum, NO,
			@""),
		WCAccountFieldBooleanDictionary(WCAccountFieldSectionBasics,
			@"wired.account.user.cannot_set_nick", NSLS(@"Cannot Set Nick", @"Account field name"),
			@"TBD"),
		WCAccountFieldBooleanDictionary(WCAccountFieldSectionBasics,
			@"wired.account.user.get_info", NSLS(@"Get User Info", @"Account field name"),
			@"TBD"),
		WCAccountFieldBooleanDictionary(WCAccountFieldSectionBasics,
			@"wired.account.chat.set_topic", NSLS(@"Set Chat Topic", @"Account field name"),
			@"TBD"),
		WCAccountFieldBooleanDictionary(WCAccountFieldSectionBasics,
			@"wired.account.chat.create_chats", NSLS(@"Create Chats", @"Account field name"),
			@"TBD"),
		WCAccountFieldBooleanDictionary(WCAccountFieldSectionBasics,
			@"wired.account.message.send_messages", NSLS(@"Send Messages", @"Account field name"),
			@"TBD"),
		WCAccountFieldBooleanDictionary(WCAccountFieldSectionBasics,
			@"wired.account.message.broadcast", NSLS(@"Broadcast Messages", @"Account field name"),
			@"TBD"),

		WCAccountFieldDictionary(WCAccountFieldSectionFiles,
			@"wired.account.files", NSLS(@"Files Folder", @"Account field name"), WCAccountFieldTypeString, NO, 
			@"TBD"),
		WCAccountFieldBooleanDictionary(WCAccountFieldSectionFiles,
			@"wired.account.file.list_files", NSLS(@"List Files", @"Account field name"),
			@"TBD"),
		WCAccountFieldBooleanDictionary(WCAccountFieldSectionFiles,
			@"wired.account.file.search_files", NSLS(@"Search Files", @"Account field name"),
			@"TBD"),
		WCAccountFieldBooleanDictionary(WCAccountFieldSectionFiles,
			@"wired.account.file.get_info", NSLS(@"Get File Info", @"Account field name"),
			@"TBD"),
		WCAccountFieldBooleanDictionary(WCAccountFieldSectionFiles,
			@"wired.account.file.create_directories", NSLS(@"Create Folders", @"Account field name"),
			@"TBD"),
		WCAccountFieldBooleanDictionary(WCAccountFieldSectionFiles,
			@"wired.account.file.create_links", NSLS(@"Create Links", @"Account field name"),
			@"TBD"),
		WCAccountFieldBooleanDictionary(WCAccountFieldSectionFiles,
			@"wired.account.file.move_files", NSLS(@"Move Files", @"Account field name"),
			@"TBD"),
		WCAccountFieldBooleanDictionary(WCAccountFieldSectionFiles,
			@"wired.account.file.rename_files", NSLS(@"Rename Files", @"Account field name"),
			@"TBD"),
		WCAccountFieldBooleanDictionary(WCAccountFieldSectionFiles,
			@"wired.account.file.set_type", NSLS(@"Set Folder Type", @"Account field name"),
			@"TBD"),
		WCAccountFieldBooleanDictionary(WCAccountFieldSectionFiles,
			@"wired.account.file.set_comment", NSLS(@"Set Comments", @"Account field name"),
			@"TBD"),
		WCAccountFieldBooleanDictionary(WCAccountFieldSectionFiles,
			@"wired.account.file.set_permissions", NSLS(@"Set Permissions", @"Account field name"),
			@"TBD"),
		WCAccountFieldBooleanDictionary(WCAccountFieldSectionFiles,
			@"wired.account.file.set_executable", NSLS(@"Set Executable", @"Account field name"),
			@"TBD"),
		WCAccountFieldBooleanDictionary(WCAccountFieldSectionFiles,
			@"wired.account.file.set_label", NSLS(@"Set Label", @"Account field name"),
			@"TBD"),
		WCAccountFieldBooleanDictionary(WCAccountFieldSectionFiles,
			@"wired.account.file.delete_files", NSLS(@"Delete Files", @"Account field name"),
			@"TBD"),
		WCAccountFieldBooleanDictionary(WCAccountFieldSectionFiles,
			@"wired.account.file.access_all_dropboxes", NSLS(@"Access All Drop Boxes", @"Account field name"),
			@"TBD"),
		WCAccountFieldBooleanDictionary(WCAccountFieldSectionFiles,
			@"wired.account.transfer.download_files", NSLS(@"Download Files", @"Account field name"),
			@"TBD"),
		WCAccountFieldBooleanDictionary(WCAccountFieldSectionFiles,
			@"wired.account.transfer.upload_files", NSLS(@"Upload Files", @"Account field name"),
			@"TBD"),
		WCAccountFieldBooleanDictionary(WCAccountFieldSectionFiles,
			@"wired.account.transfer.upload_directories", NSLS(@"Upload Folders", @"Account field name"),
			@"TBD"),
		WCAccountFieldBooleanDictionary(WCAccountFieldSectionFiles,
			@"wired.account.transfer.upload_anywhere", NSLS(@"Upload Anywhere", @"Account field name"),
			@"TBD"),

		WCAccountFieldBooleanDictionary(WCAccountFieldSectionBoards,
			@"wired.account.board.read_boards", NSLS(@"Read Boards", @"Account field name"),
			@"TBD"),
		WCAccountFieldBooleanDictionary(WCAccountFieldSectionBoards,
			@"wired.account.board.add_boards", NSLS(@"Add Boards", @"Account field name"),
			@"TBD"),
		WCAccountFieldBooleanDictionary(WCAccountFieldSectionBoards,
			@"wired.account.board.move_boards", NSLS(@"Move Boards", @"Account field name"),
			@"TBD"),
		WCAccountFieldBooleanDictionary(WCAccountFieldSectionBoards,
			@"wired.account.board.rename_boards", NSLS(@"Rename Boards", @"Account field name"),
			@"TBD"),
		WCAccountFieldBooleanDictionary(WCAccountFieldSectionBoards,
			@"wired.account.board.delete_boards", NSLS(@"Delete Boards", @"Account field name"),
			@"TBD"),
		WCAccountFieldBooleanDictionary(WCAccountFieldSectionBoards,
			@"wired.account.board.get_board_info", NSLS(@"Get Board Info", @"Account field name"),
			@"TBD"),
		WCAccountFieldBooleanDictionary(WCAccountFieldSectionBoards,
			@"wired.account.board.set_board_info", NSLS(@"Set Board Info", @"Account field name"),
			@"TBD"),
		WCAccountFieldBooleanDictionary(WCAccountFieldSectionBoards,
			@"wired.account.board.add_threads", NSLS(@"Add Threads", @"Account field name"),
			@"TBD"),
		WCAccountFieldBooleanDictionary(WCAccountFieldSectionBoards,
			@"wired.account.board.move_threads", NSLS(@"Move Threads", @"Account field name"),
			@"TBD"),
		WCAccountFieldBooleanDictionary(WCAccountFieldSectionBoards,
			@"wired.account.board.add_posts", NSLS(@"Add Posts", @"Account field name"),
			@"TBD"),
		WCAccountFieldBooleanDictionary(WCAccountFieldSectionBoards,
			@"wired.account.board.edit_own_threads_and_posts", NSLS(@"Edit Own Threads & Posts", @"Account field name"),
			@"TBD"),
		WCAccountFieldBooleanDictionary(WCAccountFieldSectionBoards,
			@"wired.account.board.edit_all_threads_and_posts", NSLS(@"Edit All Threads & Posts", @"Account field name"),
			@"TBD"),
		WCAccountFieldBooleanDictionary(WCAccountFieldSectionBoards,
			@"wired.account.board.delete_own_threads_and_posts", NSLS(@"Delete Threads & Own Posts", @"Account field name"),
			@"TBD"),
		WCAccountFieldBooleanDictionary(WCAccountFieldSectionBoards,
			@"wired.account.board.delete_all_threads_and_posts", NSLS(@"Delete Threads & All Posts", @"Account field name"),
			@"TBD"),
			  
		WCAccountFieldBooleanDictionary(WCAccountFieldSectionTracker,
			@"wired.account.tracker.list_servers", NSLS(@"List Servers", @"Account field name"),
			@"TBD"),
		WCAccountFieldBooleanDictionary(WCAccountFieldSectionTracker,
			@"wired.account.tracker.register_servers", NSLS(@"Register Servers", @"Account field name"),
			@"TBD"),

		WCAccountFieldBooleanDictionary(WCAccountFieldSectionUsers,
			@"wired.account.chat.kick_users", NSLS(@"Kick Users", @"Account field name"),
			@"TBD"),
		WCAccountFieldBooleanDictionary(WCAccountFieldSectionUsers,
			@"wired.account.user.disconnect_users", NSLS(@"Disconnect Users", @"Account field name"),
			@"TBD"),
		WCAccountFieldBooleanDictionary(WCAccountFieldSectionUsers,
			@"wired.account.user.ban_users", NSLS(@"Ban Users", @"Account field name"),
			@"TBD"),
		WCAccountFieldBooleanDictionary(WCAccountFieldSectionUsers,
			@"wired.account.user.cannot_be_disconnected", NSLS(@"Cannot Be Disconnected", @"Account field name"),
			@"TBD"),

		WCAccountFieldBooleanDictionary(WCAccountFieldSectionAccounts,
			@"wired.account.account.change_password", NSLS(@"Change Password", @"Account field name"),
			@"TBD"),
		WCAccountFieldBooleanDictionary(WCAccountFieldSectionAccounts,
			@"wired.account.account.list_accounts", NSLS(@"List Accounts", @"Account field name"),
			@"TBD"),
		WCAccountFieldBooleanDictionary(WCAccountFieldSectionAccounts,
			@"wired.account.account.read_accounts", NSLS(@"Read Accounts", @"Account field name"),
			@"TBD"),
		WCAccountFieldBooleanDictionary(WCAccountFieldSectionAccounts,
			@"wired.account.account.create_users", NSLS(@"Create Users", @"Account field name"),
			@"TBD"),
		WCAccountFieldBooleanDictionary(WCAccountFieldSectionAccounts,
			@"wired.account.account.edit_users", NSLS(@"Edit Users", @"Account field name"),
			@"TBD"),
		WCAccountFieldBooleanDictionary(WCAccountFieldSectionAccounts,
			@"wired.account.account.delete_users", NSLS(@"Delete Users", @"Account field name"),
			@"TBD"),
		WCAccountFieldBooleanDictionary(WCAccountFieldSectionAccounts,
			@"wired.account.account.create_groups", NSLS(@"Create Groups", @"Account field name"),
			@"TBD"),
		WCAccountFieldBooleanDictionary(WCAccountFieldSectionAccounts,
			@"wired.account.account.edit_groups", NSLS(@"Edit Groups", @"Account field name"),
			@"TBD"),
		WCAccountFieldBooleanDictionary(WCAccountFieldSectionAccounts,
			@"wired.account.account.delete_groups", NSLS(@"Delete Groups", @"Account field name"),
			@"TBD"),
		WCAccountFieldBooleanDictionary(WCAccountFieldSectionAccounts,
			@"wired.account.account.raise_account_privileges", NSLS(@"Raise Privileges", @"Account field name"),
			@"TBD"),
		
		WCAccountFieldBooleanDictionary(WCAccountFieldSectionAdministration,
			@"wired.account.user.get_users", NSLS(@"Monitor Users", @"Account field name"),
			@"TBD"),
		WCAccountFieldBooleanDictionary(WCAccountFieldSectionAdministration,
			@"wired.account.events.view_events", NSLS(@"View Events", @"Account field name"),
			@"TBD"),
		WCAccountFieldBooleanDictionary(WCAccountFieldSectionAdministration,
			@"wired.account.log.view_log", NSLS(@"View Log", @"Account field name"),
			@"TBD"),
		WCAccountFieldBooleanDictionary(WCAccountFieldSectionAdministration,
			@"wired.account.settings.get_settings", NSLS(@"Read Settings", @"Account field name"),
			@"TBD"),
		WCAccountFieldBooleanDictionary(WCAccountFieldSectionAdministration,
			@"wired.account.settings.set_settings", NSLS(@"Edit Settings", @"Account field name"),
			@"TBD"),
		WCAccountFieldBooleanDictionary(WCAccountFieldSectionAdministration,
			@"wired.account.banlist.get_bans", NSLS(@"Read Banlist", @"Account field name"),
			@"TBD"),
		WCAccountFieldBooleanDictionary(WCAccountFieldSectionAdministration,
			@"wired.account.banlist.add_bans", NSLS(@"Add Bans", @"Account field name"),
			@"TBD"),
		WCAccountFieldBooleanDictionary(WCAccountFieldSectionAdministration,
			@"wired.account.banlist.delete_bans", NSLS(@"Delete Bans", @"Account field name"),
			@"TBD"),

		WCAccountFieldNumberDictionary(WCAccountFieldSectionLimits,
			@"wired.account.file.recursive_list_depth_limit", NSLS(@"Download Folder Depth", @"Account field name"),
			@"TBD"),
		WCAccountFieldNumberDictionary(WCAccountFieldSectionLimits,
			@"wired.account.transfer.download_limit", NSLS(@"Concurrent Downloads", @"Account field name"),
			@"TBD"),
		WCAccountFieldNumberDictionary(WCAccountFieldSectionLimits,
			@"wired.account.transfer.upload_limit", NSLS(@"Concurrent Uploads", @"Account field name"),
			@"TBD"),
		WCAccountFieldNumberDictionary(WCAccountFieldSectionLimits,
			@"wired.account.transfer.download_speed_limit", NSLS(@"Download Speed (KB/s)", @"Account field name"),
			@"TBD"),
		WCAccountFieldNumberDictionary(WCAccountFieldSectionLimits,
			@"wired.account.transfer.upload_speed_limit", NSLS(@"Upload Speed (KB/s)", @"Account field name"),
			@"TBD"),
		NULL];
	
	return fields;
}



#pragma mark -

+ (id)account {
	return [[[self alloc] init] autorelease];
}



+ (id)accountWithName:(NSString *)name {
	WCAccount		*account;
	
	account = [[self alloc] init];
	
	[account setValue:name forKey:@"wired.account.name"];
	
	return [account autorelease];
}



+ (id)accountWithMessage:(WIP7Message *)message {
	return [[[self alloc] _initWithMessage:message] autorelease];
}



- (id)init {
	self = [super init];
	
	_values = [[NSMutableDictionary alloc] init];
	
	return self;
}



- (void)dealloc {
	[_values release];
	[_originalValues release];
	
	[super dealloc];
}



#pragma mark -

- (id)copyWithZone:(NSZone *)zone {
	WCAccount		*account;
	
	account = [[[self class] allocWithZone:zone] init];

	[account setValues:[self values]];
	
	return account;
}



- (NSUInteger)hash {
	return [[self newName] hash] + [[self name] hash];
}



- (BOOL)isEqual:(id)object {
	if(![object isKindOfClass:[self class]])
		return NO;
	
	if([[self name] isEqualToString:[object newName]])
		return YES;
	
	return [[self name] isEqualToString:[object name]];
}



- (NSString *)description {
	return [NSSWF:@"<%@ %p>{name = %@}",
		[self className],
		self,
		[self name]];
}



#pragma mark -

- (WIP7Message *)createAccountMessage {
	[self doesNotRecognizeSelector:_cmd];

	return NULL;
}



- (WIP7Message *)editAccountMessage {
	[self doesNotRecognizeSelector:_cmd];
	
	return NULL;
}



#pragma mark -

- (void)setName:(NSString *)name {
	[self setValue:name forKey:@"wired.account.name"];
}



- (NSString *)name {
	return [self valueForKey:@"wired.account.name"];
}



- (void)setNewName:(NSString *)newName {
	[self setValue:newName forKey:@"wired.account.new_name"];
}



- (NSString *)newName {
	return [self valueForKey:@"wired.account.new_name"];
}



- (void)setComment:(NSString *)comment {
	[self setValue:comment forKey:@"wired.account.comment"];
}



- (NSString *)comment {
	return [self valueForKey:@"wired.account.comment"];
}



- (void)setColor:(WCAccountColor)color {
	[self setValue:[NSNumber numberWithInteger:color] forKey:@"wired.account.color"];
}



- (WCAccountColor)color {
	return [[self valueForKey:@"wired.account.color"] integerValue];
}



- (NSDate *)creationDate {
	return [self valueForKey:@"wired.account.creation_time"];
}



- (NSDate *)modificationDate {
	return [self valueForKey:@"wired.account.modification_time"];
}



- (NSString *)editedBy {
	return [self valueForKey:@"wired.account.edited_by"];
}



- (NSString *)files {
	return [self valueForKey:@"wired.account.files"];
}



- (BOOL)userCannotSetNick {
	return [[self valueForKey:@"wired.account.user.cannot_set_nick"] boolValue];
}



- (BOOL)userGetInfo {
	return [[self valueForKey:@"wired.account.user.get_info"] boolValue];
}



- (BOOL)userDisconnectUsers {
	return [[self valueForKey:@"wired.account.user.disconnect_users"] boolValue];
}



- (BOOL)userBanUsers {
	return [[self valueForKey:@"wired.account.user.ban_users"] boolValue];
}



- (BOOL)userCannotBeDisconnected {
	return [[self valueForKey:@"wired.account.user.cannot_be_disconnected"] boolValue];
}



- (BOOL)userGetUsers {
	return [[self valueForKey:@"wired.account.user.get_users"] boolValue];
}



- (BOOL)chatSetTopic {
	return [[self valueForKey:@"wired.account.chat.set_topic"] boolValue];
}



- (BOOL)chatKickUsers {
	return [[self valueForKey:@"wired.account.chat.kick_users"] boolValue];
}



- (BOOL)chatCreateChats {
	return [[self valueForKey:@"wired.account.chat.create_chats"] boolValue];
}



- (BOOL)messageSendMessages {
	return [[self valueForKey:@"wired.account.message.send_messages"] boolValue];
}



- (BOOL)messageBroadcast {
	return [[self valueForKey:@"wired.account.message.broadcast"] boolValue];
}



- (BOOL)boardReadBoards {
	return [[self valueForKey:@"wired.account.board.read_boards"] boolValue];
}



- (BOOL)boardAddBoards {
	return [[self valueForKey:@"wired.account.board.add_boards"] boolValue];
}



- (BOOL)boardMoveBoards {
	return [[self valueForKey:@"wired.account.board.move_boards"] boolValue];
}



- (BOOL)boardRenameBoards {
	return [[self valueForKey:@"wired.account.board.rename_boards"] boolValue];
}



- (BOOL)boardDeleteBoards {
	return [[self valueForKey:@"wired.account.board.delete_boards"] boolValue];
}



- (BOOL)boardGetBoardInfo {
	return [[self valueForKey:@"wired.account.board.get_board_info"] boolValue];
}



- (BOOL)boardSetBoardInfo {
	return [[self valueForKey:@"wired.account.board.set_board_info"] boolValue];
}



- (BOOL)boardAddThreads {
	return [[self valueForKey:@"wired.account.board.add_threads"] boolValue];
}



- (BOOL)boardMoveThreads {
	return [[self valueForKey:@"wired.account.board.move_threads"] boolValue];
}

- (BOOL)boardDeleteThreads {
    return [[self valueForKey:@"wired.account.board.delete_threads"] boolValue];
}



- (BOOL)boardAddPosts {
	return [[self valueForKey:@"wired.account.board.add_posts"] boolValue];
}



- (BOOL)boardEditOwnThreadsAndPosts {
	return [[self valueForKey:@"wired.account.board.edit_own_threads_and_posts"] boolValue];
}



- (BOOL)boardEditAllThreadsAndPosts {
	return [[self valueForKey:@"wired.account.board.edit_all_threads_and_posts"] boolValue];
}



- (BOOL)boardDeleteOwnThreadsAndPosts {
	return [[self valueForKey:@"wired.account.board.delete_own_threads_and_posts"] boolValue];
}



- (BOOL)boardDeleteAllThreadsAndPosts {
	return [[self valueForKey:@"wired.account.board.delete_all_threads_and_posts"] boolValue];
}



- (BOOL)fileListFiles {
	return [[self valueForKey:@"wired.account.file.list_files"] boolValue];
}



- (BOOL)fileSearchFiles {
	return [[self valueForKey:@"wired.account.file.search_files"] boolValue];
}



- (BOOL)fileGetInfo {
	return [[self valueForKey:@"wired.account.file.get_info"] boolValue];
}



- (BOOL)fileCreateDirectories {
	return [[self valueForKey:@"wired.account.file.create_directories"] boolValue];
}



- (BOOL)fileCreateLinks {
	return [[self valueForKey:@"wired.account.file.create_links"] boolValue];
}



- (BOOL)fileMoveFiles {
	return [[self valueForKey:@"wired.account.file.move_files"] boolValue];
}



- (BOOL)fileRenameFiles {
	return [[self valueForKey:@"wired.account.file.rename_files"] boolValue];
}



- (BOOL)fileSetType {
	return [[self valueForKey:@"wired.account.file.set_type"] boolValue];
}



- (BOOL)fileSetComment {
	return [[self valueForKey:@"wired.account.file.set_comment"] boolValue];
}



- (BOOL)fileSetPermissions {
	return [[self valueForKey:@"wired.account.file.set_permissions"] boolValue];
}



- (BOOL)fileSetExecutable {
	return [[self valueForKey:@"wired.account.file.set_executable"] boolValue];
}



- (BOOL)fileSetLabel {
	return [[self valueForKey:@"wired.account.file.set_label"] boolValue];
}



- (BOOL)fileDeleteFiles {
	return [[self valueForKey:@"wired.account.file.delete_files"] boolValue];
}



- (BOOL)fileAccessAllDropboxes {
	return [[self valueForKey:@"wired.account.file.access_all_dropboxes"] boolValue];
}



- (NSUInteger)fileRecursiveListDepthLimit {
	return [[self valueForKey:@"wired.account.file.recursive_list_depth_limit"] unsignedIntegerValue];
}



- (BOOL)transferDownloadFiles {
	return [[self valueForKey:@"wired.account.transfer.download_files"] boolValue];
}



- (BOOL)transferUploadFiles {
	return [[self valueForKey:@"wired.account.transfer.upload_files"] boolValue];
}



- (BOOL)transferUploadDirectories {
	return [[self valueForKey:@"wired.account.transfer.upload_directories"] boolValue];
}



- (BOOL)transferUploadAnywhere {
	return [[self valueForKey:@"wired.account.transfer.upload_anywhere"] boolValue];
}



- (NSUInteger)transferDownloadLimit {
	return [[self valueForKey:@"wired.account.transfer.download_limit"] unsignedIntegerValue];
}



- (NSUInteger)transferUploadLimit {
	return [[self valueForKey:@"wired.account.transfer.upload_limit"] unsignedIntegerValue];
}



- (NSUInteger)transferDownloadSpeedLimit {
	return [[self valueForKey:@"wired.account.transfer.download_speed_limit"] unsignedIntegerValue];
}



- (NSUInteger)transferUploadSpeedLimit {
	return [[self valueForKey:@"wired.account.transfer.upload_speed_limit"] unsignedIntegerValue];
}



- (BOOL)accountChangePassword {
	return [[self valueForKey:@"wired.account.account.change_password"] boolValue];
}



- (BOOL)accountListAccounts {
	return [[self valueForKey:@"wired.account.account.list_accounts"] boolValue];
}



- (BOOL)accountReadAccounts {
	return [[self valueForKey:@"wired.account.account.read_accounts"] boolValue];
}



- (BOOL)accountCreateUsers {
	return [[self valueForKey:@"wired.account.account.create_users"] boolValue];
}



- (BOOL)accountEditUsers {
	return [[self valueForKey:@"wired.account.account.edit_users"] boolValue];
}



- (BOOL)accountDeleteUsers {
	return [[self valueForKey:@"wired.account.account.delete_users"] boolValue];
}



- (BOOL)accountCreateGroups {
	return [[self valueForKey:@"wired.account.account.create_groups"] boolValue];
}



- (BOOL)accountEditGroups {
	return [[self valueForKey:@"wired.account.account.edit_groups"] boolValue];
}



- (BOOL)accountDeleteGroups {
	return [[self valueForKey:@"wired.account.account.delete_groups"] boolValue];
}



- (BOOL)accountRaiseAccountPrivileges {
	return [[self valueForKey:@"wired.account.account.raise_account_privileges"] boolValue];
}



- (BOOL)logViewLog {
	return [[self valueForKey:@"wired.account.log.view_log"] boolValue];
}



- (BOOL)eventsViewEvents {
	return [[self valueForKey:@"wired.account.events.view_events"] boolValue];
}



- (BOOL)settingsGetSettings {
	return [[self valueForKey:@"wired.account.settings.get_settings"] boolValue];
}



- (BOOL)settingsSetSettings {
	return [[self valueForKey:@"wired.account.settings.set_settings"] boolValue];
}



- (BOOL)banlistGetBans {
	return [[self valueForKey:@"wired.account.banlist.get_bans"] boolValue];
}



- (BOOL)banlistAddBans {
	return [[self valueForKey:@"wired.account.banlist.add_bans"] boolValue];
}



- (BOOL)banlistDeleteBans {
	return [[self valueForKey:@"wired.account.banlist.delete_bans"] boolValue];
}



- (BOOL)trackerListServers {
	return [[self valueForKey:@"wired.account.tracker.list_servers"] boolValue];
}



- (BOOL)trackerRegisterServers {
	return [[self valueForKey:@"wired.account.tracker.register_servers"] boolValue];
}



#pragma mark -

- (void)setValue:(id)value forKey:(NSString *)key {
	if(value)
		[_values setObject:value forKey:key];
	else
		[_values removeObjectForKey:key];
}



- (id)valueForKey:(NSString *)key {
	return [_values objectForKey:key];
}



- (id)originalValueForKey:(NSString *)key {
	return [_originalValues objectForKey:key];
}



- (void)setValues:(NSDictionary *)values {
	[_values release];
	_values = [values mutableCopy];
}



- (NSDictionary *)values {
	return _values;
}



#pragma mark -

- (NSComparisonResult)compareName:(WCAccount *)account {
	return [[self name] compare:[account name] options:NSCaseInsensitiveSearch];
}



- (NSComparisonResult)compareType:(WCAccount *)account {
	if([self isKindOfClass:[WCUserAccount class]] && [account isKindOfClass:[WCGroupAccount class]])
		return NSOrderedAscending;
	else if([self isKindOfClass:[WCGroupAccount class]] && [account isKindOfClass:[WCUserAccount class]])
		return NSOrderedDescending;

	return [self compareName:account];
}

@end



@implementation WCUserAccount

- (void)dealloc {
	[_groupAccount release];
	
	[super dealloc];
}



#pragma mark -

- (WIP7Message *)createAccountMessage {
	WIP7Message		*message;
	
	message = [WIP7Message messageWithName:@"wired.account.create_user" spec:WCP7Spec];

	[self _writeToMessage:message];
	
	return message;
}



- (WIP7Message *)editAccountMessage {
	WIP7Message		*message;
	
	message = [WIP7Message messageWithName:@"wired.account.edit_user" spec:WCP7Spec];

	[self _writeToMessage:message];
	
	return message;
}



#pragma mark -

- (void)setGroupAccount:(WCGroupAccount *)account {
	[account retain];
	[_groupAccount release];
	
	_groupAccount = account;
}



- (WCGroupAccount *)groupAccount {
	return _groupAccount;
}



#pragma mark -

- (NSDate *)loginDate {
	return [self valueForKey:@"wired.account.login_time"];
}



- (NSUInteger)downloads {
	return [[self valueForKey:@"wired.account.downloads"] unsignedIntegerValue];
}



- (WIFileOffset)downloadTransferred {
	return [[self valueForKey:@"wired.account.download_transferred"] unsignedLongLongValue];
}



- (NSUInteger)uploads {
	return [[self valueForKey:@"wired.account.uploads"] unsignedIntegerValue];
}



- (WIFileOffset)uploadTransferred {
	return [[self valueForKey:@"wired.account.upload_transferred"] unsignedLongLongValue];
}



- (void)setFullName:(NSString *)fullName {
	[self setValue:fullName forKey:@"wired.account.full_name"];
}



- (NSString *)fullName {
	return [self valueForKey:@"wired.account.full_name"];
}



- (void)setGroup:(NSString *)group {
	[self setValue:group forKey:@"wired.account.group"];
}



- (NSString *)group {
	return [self valueForKey:@"wired.account.group"];
}



- (NSString *)originalGroup {
	return [self originalValueForKey:@"wired.account.group"];
}



- (void)setGroups:(NSArray *)groups {
	[self setValue:groups forKey:@"wired.account.groups"];
}



- (NSArray *)groups {
	return [self valueForKey:@"wired.account.groups"];
}



- (void)setPassword:(NSString *)password {
	[self setValue:password forKey:@"wired.account.password"];
}



- (NSString *)password {
	return [self valueForKey:@"wired.account.password"];
}

@end



@implementation WCGroupAccount

- (WIP7Message *)createAccountMessage {
	WIP7Message		*message;
	
	message = [WIP7Message messageWithName:@"wired.account.create_group" spec:WCP7Spec];

	[self _writeToMessage:message];
	
	return message;
}



- (WIP7Message *)editAccountMessage {
	WIP7Message		*message;
	
	message = [WIP7Message messageWithName:@"wired.account.edit_group" spec:WCP7Spec];

	[self _writeToMessage:message];
	
	return message;
}

@end
