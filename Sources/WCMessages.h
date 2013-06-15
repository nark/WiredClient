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

extern NSString * const								WCMessagesDidChangeUnreadCountNotification;


@class WCConversationController, WCSourceSplitView;
@class WCConversation, WCMessageConversation, WCBroadcastConversation, WCUser;

@interface WCMessages : WIWindowController {
	IBOutlet WCConversationController				*_conversationController;
	
	IBOutlet WCSourceSplitView						*_conversationsSplitView;
	IBOutlet NSView									*_conversationsView;
	IBOutlet NSView									*_messagesView;
	IBOutlet WISplitView							*_messagesSplitView;
	IBOutlet NSView									*_messageTopView;
	IBOutlet NSView									*_messageBottomView;

	IBOutlet WIOutlineView							*_conversationsOutlineView;
	IBOutlet NSTableColumn							*_conversationTableColumn;
	IBOutlet NSTableColumn							*_unreadTableColumn;
	
	IBOutlet NSButton								*_deleteConversationButton;
	
	IBOutlet NSTextView								*_messageTextView;

	IBOutlet NSPanel								*_broadcastPanel;
	IBOutlet NSTextView								*_broadcastTextView;
	
	IBOutlet NSMenu									*_chatSmileysMenu;

	WCConversation									*_conversations;
	WCMessageConversation							*_messageConversations;
	WCBroadcastConversation							*_broadcastConversations;
	WCConversation									*_selectedConversation;
	
	NSImage											*_conversationIcon;
	
	WIDateFormatter									*_dialogDateFormatter;
}

+ (id)messages;

- (NSString *)saveDocumentMenuItemTitle;

- (void)showPrivateMessageToUser:(WCUser *)user;
- (void)showBroadcastForConnection:(WCServerConnection *)connection;
- (NSUInteger)numberOfUnreadMessages;
- (NSUInteger)numberOfUnreadMessagesForConnection:(WCServerConnection *)connection;

- (IBAction)saveDocument:(id)sender;
- (IBAction)saveConversation:(id)sender;

- (IBAction)revealInUserList:(id)sender;
- (IBAction)clearMessages:(id)sender;
- (IBAction)deleteConversation:(id)sender;

@end
