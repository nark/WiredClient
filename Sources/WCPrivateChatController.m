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

#import "WCPrivateChatController.h"
#import "WCApplicationController.h"
#import "WCPublicChat.h"
#import "WCUser.h"

@implementation WCPrivateChatController

- (void)dealloc {
	[_inviteUser release];
	
	[super dealloc];
}



#pragma mark -

- (void)awakeFromNib {
	[_userListTableView registerForDraggedTypes:[NSArray arrayWithObject:WCUserPboardType]];
    
	[super awakeFromNib];
}



#pragma mark -

- (void)wiredChatCreateChatReply:(WIP7Message *)message {
	WIP7Message		*reply;

	[message getUInt32:&_chatID forName:@"wired.chat.id"];
	
	reply = [WIP7Message messageWithName:@"wired.chat.join_chat" spec:WCP7Spec];
	[reply setUInt32:[self chatID] forName:@"wired.chat.id"];
	[[self connection] sendMessage:reply fromObserver:self selector:@selector(wiredChatJoinChatReply:)];

	[_privateChat showWindow:self];
}



- (void)wiredChatJoinChatReply:(WIP7Message *)message {
	WIP7Message		*reply;

	[super wiredChatJoinChatReply:message];
	
	if([[message name] isEqualToString:@"wired.chat.user_list.done"]) {
		if(_inviteUser) {
			reply = [WIP7Message messageWithName:@"wired.chat.invite_user" spec:WCP7Spec];
			[reply setUInt32:[self chatID] forName:@"wired.chat.id"];
			[reply setUInt32:[_inviteUser userID] forName:@"wired.user.id"];
			[[self connection] sendMessage:reply];

			[self setInviteUser:NULL];
		}
	}
}



- (void)wiredChatUserDeclineInvitation:(WIP7Message *)message {
	WCUser		*user;
	WIP7UInt32	uid, cid;

	[message getUInt32:&cid forName:@"wired.chat.id"];
	
	if(cid != [self chatID])
		return;
	
	[message getUInt32:&uid forName:@"wired.user.id"];

	user = [[[self connection] chatController] userWithUserID:uid];
	
	if(!user)
		return;

	[self printEvent:[NSSWF:NSLS(@"%@ has declined invitation", @"Private chat decline message (nick)"),
		[user nick]]];
}



#pragma mark -

- (void)setChatID:(NSUInteger)chatID {
	WIP7Message		*message;
	
	_chatID = chatID;

	if(_chatID == 0) {
		message = [WIP7Message messageWithName:@"wired.chat.create_chat" spec:WCP7Spec];
		[[self connection] sendMessage:message fromObserver:self selector:@selector(wiredChatCreateChatReply:)];
	} else {
		message = [WIP7Message messageWithName:@"wired.chat.join_chat" spec:WCP7Spec];
		[message setUInt32:_chatID forName:@"wired.chat.id"];
		[[self connection] sendMessage:message fromObserver:self selector:@selector(wiredChatJoinChatReply:)];
	}
}



- (NSUInteger)chatID {
	return _chatID;
}



- (void)setInviteUser:(WCUser *)inviteUser {
	[inviteUser retain];
	[_inviteUser release];
	
	_inviteUser = inviteUser;
}



- (WCUser *)inviteUser {
	return _inviteUser;
}



- (void)setConnection:(WCServerConnection *)connection {
	[super setConnection:connection];
	
	[_connection addObserver:self
					selector:@selector(wiredChatUserDeclineInvitation:)
				 messageName:@"wired.chat.user_decline_invitation"];
	
}



#pragma mark -

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation {
	if(row >= 0)
		[tableView setDropRow:-1 dropOperation:NSTableViewDropOn];

	return NSDragOperationGeneric;
}



- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation {
	NSPasteboard		*pasteboard;
	WIP7Message			*message;
	NSUInteger			userID;

	pasteboard	= [info draggingPasteboard];
	userID		= [[pasteboard stringForType:WCUserPboardType] integerValue];

	message = [WIP7Message messageWithName:@"wired.chat.invite_user" spec:WCP7Spec];
	[message setUInt32:[self chatID] forName:@"wired.chat.id"];
	[message setUInt32:userID forName:@"wired.user.id"];
	[[self connection] sendMessage:message];
	
	return YES;
}



#pragma mark -

- (void)clearChat {
	WCUser *user;
	
	user = [self userWithUserID:[[self connection] userID]];
	
	if([[WCSettings settings] boolForKey:WCChatLogsHistoryEnabled] && ![self chatIsEmpty])
		[[[[WCApplicationController sharedController] logController] privateChatHistoryBundle] addHistoryForWebView:[self webView] 
                withConnectionName:[[self connection] name]
                    identity:[user nick]];
	
	[super clearChat];
}

@end
