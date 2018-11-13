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
#import "WCChatWindow.h"
#import "WCErrorQueue.h"
#import "WCPrivateChat.h"
#import "WCPrivateChatInvitation.h"
#import "WCPublicChat.h"
#import "WCPublicChatController.h"
#import "WCApplicationController.h"
#import "WCServer.h"
#import "WCUser.h"



@interface WCPublicChatController(Private)

- (id)_initPublicChatControllerWithConnection:(WCServerConnection *)connection;

@end


@implementation WCPublicChatController(Private)

- (id)_initPublicChatControllerWithConnection:(WCServerConnection *)connection {
	self = [super init];
	
	[NSBundle loadNibNamed:@"PublicChat" owner:self];
	
	_loadedNib = YES;
	
	[self setConnection:connection];
	
	return self;
}

@end



@implementation WCPublicChatController

+ (id)publicChatControllerWithConnection:(WCServerConnection *)connection {
	return [[[self alloc] _initPublicChatControllerWithConnection:connection] autorelease];
}



- (void)dealloc {
	if(_loadedNib) {
		[_publicChatView release];
		[_banMessagePanel release];
	}
	
	[super dealloc];
}



#pragma mark -

- (void)awakeFromNib {
	[super awakeFromNib];
}



#pragma mark -

- (void)linkConnectionLoggedIn:(NSNotification *)notification {
	WIP7Message		*message;
	
	message = [WIP7Message messageWithName:@"wired.chat.join_chat" spec:WCP7Spec];
	[message setUInt32:[self chatID] forName:@"wired.chat.id"];
	[[self connection] sendMessage:message fromObserver:self selector:@selector(wiredChatJoinChatReply:)];
	
	[[WCPublicChat publicChat] addChatController:self];
    
    if([[WCSettings settings] boolForKey:WCOrderFrontWhenDisconnected]) {
        [[WCPublicChat publicChat] selectChatController:self];
        [[WCPublicChat publicChat] showWindow:self];
    }
	
	[super linkConnectionLoggedIn:notification];
}



- (void)wiredUserBanUserReply:(WIP7Message *)message {
	if([[message name] isEqualToString:@"wired.okay"]) {
		[[self connection] removeObserver:self message:message];
	}
	else if([[message name] isEqualToString:@"wired.error"]) {
		[_errorQueue showError:[WCError errorWithWiredMessage:message]];
		
		[[self connection] removeObserver:self message:message];
	}
}



- (void)wiredChatInvitation:(WIP7Message *)message {
	WCPrivateChatInvitation		*privateChatInvitation;
	WCUser						*user;
	WIP7UInt32					uid, cid;

	[message getUInt32:&cid forName:@"wired.chat.id"];
	[message getUInt32:&uid forName:@"wired.user.id"];

	user = [self userWithUserID:uid];

	if(!user || [user isIgnored])
		return;

	privateChatInvitation = [WCPrivateChatInvitation privateChatInvitationWithConnection:[self connection]
																					user:user
																				  chatID:cid];
	
	[privateChatInvitation showWindow:self];

	[[self connection] triggerEvent:WCEventsChatInvitationReceived info1:user];
}



- (void)wiredAccountChangePasswordReply:(WIP7Message *)message {
	if([[message name] isEqualToString:@"wired.okay"]) {
		[[self connection] removeObserver:self message:message];
	}
	else if([[message name] isEqualToString:@"wired.error"]) {
		[_errorQueue showError:[WCError errorWithWiredMessage:message]];
		
		[[self connection] removeObserver:self message:message];
	}
}


#pragma mark -

- (void)validate {
	BOOL	connected;

	connected = [[self connection] isConnected];

	if([_userListTableView selectedRow] < 0) {
		[_privateChatButton setEnabled:NO];
		[_banButton setEnabled:NO];
	} else {
		[_privateChatButton setEnabled:connected];
		[_banButton setEnabled:([[[self connection] account] userBanUsers] && connected)];
	}

	[super validate];
}



- (BOOL)validateMenuItem:(NSMenuItem *)item {
	SEL			selector;
	BOOL		connected;
	
	selector = [item action];
	connected = [[self connection] isConnected];
	
	if(selector == @selector(startPrivateChat:))
		return connected;
	else if(selector == @selector(ban:))
		return ([[[self connection] account] userBanUsers] && connected);
	else if(selector == @selector(setTopic:))
		return ([[[self connection] account] chatSetTopic] && connected);

	return [super validateMenuItem:item];
}



#pragma mark -

- (void)setConnection:(WCServerConnection *)connection {
	[super setConnection:connection];
	
	[_connection addObserver:self selector:@selector(wiredChatInvitation:) messageName:@"wired.chat.invitation"];
}



#pragma mark -

- (IBAction)startPrivateChat:(id)sender {
	WCUser		*user;
	
	user = [self selectedUser];
	
	if([user userID] == [[self connection] userID])
		user = NULL;
	
	[WCPrivateChat privateChatWithConnection:[self connection] inviteUser:user];
}



- (IBAction)ban:(id)sender {
	[NSApp beginSheet:_banMessagePanel
	   modalForWindow:[_userListSplitView window]
		modalDelegate:self
	   didEndSelector:@selector(banSheetDidEnd:returnCode:contextInfo:)
		  contextInfo:[[self selectedUser] retain]];
}



- (void)banSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	WIP7Message		*message;
	WCUser			*user = contextInfo;

	if(returnCode == NSModalResponseOK) {
		message = [WIP7Message messageWithName:@"wired.user.ban_user" spec:WCP7Spec];
		[message setUInt32:[user userID] forName:@"wired.user.id"];
		[message setString:[_banMessageTextField stringValue] forName:@"wired.user.disconnect_message"];

		if([_banMessagePopUpButton tagOfSelectedItem] > 0) {
			[message setDate:[NSDate dateWithTimeIntervalSinceNow:[_banMessagePopUpButton tagOfSelectedItem]]
					 forName:@"wired.banlist.expiration_date"];
		}
		
		[[self connection] sendMessage:message fromObserver:self selector:@selector(wiredUserBanUserReply:)];
	}

	[user release];

	[_banMessagePanel close];
	[_banMessageTextField setStringValue:@""];
}



#pragma mark -

- (IBAction)changePassword:(id)sender {
	[_newPasswordTextField setStringValue:@""];
	[_verifyPasswordTextField setStringValue:@""];
	[_passwordMismatchTextField setHidden:YES];

	[_changePasswordPanel makeFirstResponder:_newPasswordTextField];

	[NSApp beginSheet:_changePasswordPanel
	   modalForWindow:[_userListSplitView window]
		modalDelegate:self
	   didEndSelector:@selector(changePasswordSheetDidEnd:returnCode:contextInfo:)
		  contextInfo:NULL];
}



- (void)changePasswordSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	WIP7Message		*message;

	[_changePasswordPanel close];

	if(returnCode == NSAlertDefaultReturn) {
		message = [WIP7Message messageWithName:@"wired.account.change_password" spec:WCP7Spec];
		[message setString:[[_newPasswordTextField stringValue] SHA1] forName:@"wired.account.password"];
		[[self connection] sendMessage:message fromObserver:self selector:@selector(wiredAccountChangePasswordReply:)];
	}
}



- (IBAction)submitPasswordSheet:(id)sender {
	NSString		*newPassword, *verifyPassword;
	
	newPassword		= [_newPasswordTextField stringValue];
	verifyPassword	= [_verifyPasswordTextField stringValue];
	
	if([newPassword isEqualToString:verifyPassword]) {
		[self submitSheet:sender];
	} else {
		NSBeep();
		
		[_passwordMismatchTextField setHidden:NO];
	}
}



#pragma mark -

- (void)banner:(id)sender {
	[[[self connection] serverInfo] showWindow:self];
}



#pragma mark -

- (void)clearChat {
	WCUser		*user;
	
	user		= [self userWithUserID:[[self connection] userID]];
	
	if([[WCSettings settings] boolForKey:WCChatLogsHistoryEnabled] && ![self chatIsEmpty])
		[[[[WCApplicationController sharedController] logController] publicChatHistoryBundle] addHistoryForWebView:[self webView] 
													withConnectionName:[[self connection] name]
															  identity:[user nick]];
	
	[super clearChat];
}

@end
