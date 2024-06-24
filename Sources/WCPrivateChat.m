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
#import "WCPrivateChat.h"
#import "WCPrivateChatController.h"
#import "WCApplicationController.h"
#import "WCServerConnection.h"
#import "WCUser.h"

@interface WCPrivateChat(Private)

- (id)_initPrivateChatWithConnection:(WCServerConnection *)connection chatID:(NSUInteger)chatID inviteUser:(WCUser *)user;

@end


@implementation WCPrivateChat(Private)

- (id)_initPrivateChatWithConnection:(WCServerConnection *)connection chatID:(NSUInteger)chatID inviteUser:(WCUser *)user {
	self = [super initWithWindowNibName:@"PrivateChat"
								   name:NSLS(@"Private Chat", @"Chat window title")
							 connection:connection
							  singleton:NO];
	
	[self window];
	
	[_chatController setConnection:connection];
	[_chatController setChatID:chatID];
	[_chatController setInviteUser:user];

	return self;
}

@end


@implementation WCPrivateChat

+ (id)privateChatWithConnection:(WCServerConnection *)connection {
	return [[[self alloc] _initPrivateChatWithConnection:connection chatID:0 inviteUser:NULL] autorelease];
}



+ (id)privateChatWithConnection:(WCServerConnection *)connection chatID:(NSUInteger)chatID {
	return [[[self alloc] _initPrivateChatWithConnection:connection chatID:chatID inviteUser:NULL] autorelease];
}



+ (id)privateChatWithConnection:(WCServerConnection *)connection inviteUser:(WCUser *)user {
	return [[[self alloc] _initPrivateChatWithConnection:connection chatID:0 inviteUser:user] autorelease];
}



+ (id)privateChatWithConnection:(WCServerConnection *)connection chatID:(NSUInteger)chatID inviteUser:(WCUser *)user {
	return [[[self alloc] _initPrivateChatWithConnection:connection chatID:0 inviteUser:user] autorelease];
}



#pragma mark -

- (void)windowDidLoad {
	[_chatController awakeInWindow:[self window]];

	[self setShouldCascadeWindows:YES];
	[self setWindowFrameAutosaveName:@"PrivateChat"];

	[[self window] setTitle:[_connection name] withSubtitle:[self name]];

	[super windowDidLoad];
}



- (void)windowWillClose:(NSNotification *)notification {
	WIP7Message		*message;
	WCUser			*user;
	
	user = [_chatController userWithUserID:[[_chatController connection] userID]];
	
	if([[WCSettings settings] boolForKey:WCChatLogsHistoryEnabled] && ![_chatController chatIsEmpty])
		[[[[WCApplicationController sharedController] logController] privateChatHistoryBundle] addHistoryForWebView:[_chatController webView] 
                                        withConnectionName:[[_chatController connection] name]
                                            identity:[user nick]];
	
	message = [WIP7Message messageWithName:@"wired.chat.leave_chat" spec:WCP7Spec];
	[message setUInt32:[_chatController chatID] forName:@"wired.chat.id"];
	[[self connection] sendMessage:message];
	
	[_chatController saveWindowProperties];
}



- (void)serverConnectionServerInfoDidChange:(NSNotification *)notification {
	[[self window] setTitle:[_connection name] withSubtitle:[self name]];
	
	[super serverConnectionServerInfoDidChange:notification];
}



#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem *)item {
	return [_chatController validateMenuItem:item];
}


#pragma mark -

- (NSString *)saveDocumentMenuItemTitle {
	return [_chatController saveDocumentMenuItemTitle];
}



#pragma mark -

- (IBAction)saveDocument:(id)sender {
	[_chatController saveChat:sender];
}



- (IBAction)getInfo:(id)sender {
	[_chatController getInfo:sender];
}



- (IBAction)saveChat:(id)sender {
	[_chatController saveChat:sender];
}



- (IBAction)setTopic:(id)sender {
	[_chatController setTopic:sender];
}


- (IBAction)toggleUserList:(id)sender {
    [_chatController toggleUserList:sender];
}



#pragma mark -

- (NSTextField *)insertionTextField {
	return [_chatController insertionTextField];
}

@end
