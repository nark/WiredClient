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

#import "WCPrivateChat.h"
#import "WCPrivateChatInvitation.h"
#import "WCUser.h"

@interface WCPrivateChatInvitation(Private)

- (id)_initPrivateChatInvitationWithConnection:(WCServerConnection *)connection user:(WCUser *)user chatID:(NSUInteger)chatID;

@end


@implementation WCPrivateChatInvitation(Private)

- (id)_initPrivateChatInvitationWithConnection:(WCServerConnection *)connection user:(WCUser *)user chatID:(NSUInteger)chatID {
	self = [super initWithWindowNibName:@"PrivateChatInvitation" connection:connection singleton:NO];
	
	_user		= [user retain];
	_chatID		= chatID;
	
	[self window];
	
	return self;
}

@end



@implementation WCPrivateChatInvitation

+ (id)privateChatInvitationWithConnection:(WCServerConnection *)connection user:(WCUser *)user chatID:(NSUInteger)chatID {
	return [[[self alloc] _initPrivateChatInvitationWithConnection:connection user:user chatID:chatID] autorelease];
}



- (void)dealloc {
	[_user release];
	
	[super dealloc];
}



#pragma mark -

- (void)windowDidLoad {
	[_titleTextField setStringValue:[NSSWF:
		NSLS(@"%@ has invited you to a private chat.", @"Private chat invite dialog title (nick)"),
		[_user nick]]];
	
	[_descriptionTextField setStringValue:[NSSWF:
		NSLS(@"Join to open a separate private chat with %@.", @"Private chat invite dialog description (nick)"),
		[_user nick]]];
	
	[[self window] center];
	
	[self setShouldCascadeWindows:YES];
	[self setWindowFrameAutosaveName:@"PrivateChatInvitation"];
}



#pragma mark -

- (IBAction)join:(id)sender {
	WCPrivateChat	*chat;

	chat = [WCPrivateChat privateChatWithConnection:[self connection] chatID:_chatID];
	[chat showWindow:self];
	
	[self close];
}



- (IBAction)decline:(id)sender {
	WIP7Message		*message;
	
	message = [WIP7Message messageWithName:@"wired.chat.decline_invitation" spec:WCP7Spec];
	[message setUInt32:_chatID forName:@"wired.chat.id"];
	[[self connection] sendMessage:message];
	
	[self close];
}



- (IBAction)ignore:(id)sender {
	[self close];
}

@end
