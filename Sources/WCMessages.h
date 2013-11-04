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

#import "WCEmoticonViewController.h"

extern NSString * const								WCMessagesDidChangeUnreadCountNotification;

@class WCConversationController, WCSourceSplitView;
@class WDConversation, WCConversation, WCMessageConversation, WCBroadcastConversation, WCUser;

@interface WCMessages : NSWindowController <WCEmoticonViewControllerDelegate> {
	IBOutlet WCConversationController				*_conversationController;
	
	IBOutlet WCSourceSplitView						*_conversationsSplitView;
	IBOutlet WISplitView							*_messagesSplitView;
    
	IBOutlet WIOutlineView							*_conversationsOutlineView;
    IBOutlet NSTreeController                       *_conversationsTreeController;
    IBOutlet NSPopUpButton                          *_conversationPopUpButton;
    IBOutlet NSPopUpButton                          *_conversationsFiltersPopUpButton;
    IBOutlet NSSearchField                          *_conversationsSearchField;
    IBOutlet NSButton                               *_conversationsOnlineButton;
	
	IBOutlet NSTextField							*_messageTextField;
    IBOutlet NSButton								*_emoticonButton;
    
	IBOutlet NSPanel								*_broadcastPanel;
	IBOutlet NSTextView								*_broadcastTextView;
    
    IBOutlet WebView                                *_conversationWebView;
    IBOutlet NSView                                 *_messagesView;
    
	WDConversation									*_selectedConversation;
	WIDateFormatter									*_dialogDateFormatter;
    
    NSArray                                         *_sortDescriptors;
    BOOL                                            *_sorting;
}

@property (assign) IBOutlet WebView                 *conversationWebView;
@property (assign) IBOutlet NSView                  *messagesView;

@property (readonly)            NSManagedObjectContext          *managedObjectContext;
@property (readwrite, retain)   NSArray                         *sortDescriptors;

+ (id)messages;

- (NSString *)saveDocumentMenuItemTitle;

- (void)showPrivateMessageToUser:(WCUser *)user;
- (void)showBroadcastForConnection:(WCServerConnection *)connection;
- (void)sendMessage:(NSString *)string toUser:(WCUser *)user;
- (NSUInteger)numberOfUnreadMessages;
- (NSUInteger)numberOfUnreadMessagesForConnection:(WCServerConnection *)connection;

- (IBAction)saveDocument:(id)sender;
- (IBAction)saveConversation:(id)sender;

- (IBAction)conversationsFilters:(id)sender;
- (IBAction)conversationsSearch:(id)sender;

- (IBAction)markAsRead:(id)sender;
- (IBAction)revealInUserList:(id)sender;
- (IBAction)deleteConversation:(id)sender;
- (IBAction)deleteMessage:(id)sender;
- (IBAction)showEmoticons:(id)sender;

@end