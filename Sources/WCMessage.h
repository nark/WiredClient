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

#import "WCServerConnectionObject.h"

enum _WCMessageDirection {
	WCMessageFrom,
	WCMessageTo
};
typedef enum _WCMessageDirection	WCMessageDirection;


@class WCConversation, WCUser;

@interface WCMessage : WCServerConnectionObject <NSSplitViewDelegate, NSCoding> {
	WCMessageDirection				_direction;
	BOOL							_unread;
	NSString						*_nick;
	NSString						*_message;
	NSDate							*_date;
	
	WCConversation					*_conversation;
	WCUser							*_user;
}

- (WCMessageDirection)direction;
- (void)setUser:(WCUser *)user;
- (WCUser *)user;
- (NSString *)nick;
- (NSString *)message;
- (NSDate *)date;

- (void)setUnread:(BOOL)unread;
- (BOOL)isUnread;
- (void)setConversation:(WCConversation *)conversation;
- (WCConversation *)conversation;

- (NSComparisonResult)compareUser:(WCMessage *)message;
- (NSComparisonResult)compareDate:(WCMessage *)message;

- (id)proxyForJson;

@end


@interface WCPrivateMessage : WCMessage

+ (WCPrivateMessage *)messageFromUser:(WCUser *)user message:(NSString *)message connection:(WCServerConnection *)connection;
+ (WCPrivateMessage *)messageToSomeoneFromUser:(WCUser *)user message:(NSString *)message connection:(WCServerConnection *)connection;

@end


@interface WCBroadcastMessage : WCMessage

+ (WCBroadcastMessage *)broadcastFromUser:(WCUser *)user message:(NSString *)message connection:(WCServerConnection *)connection;

@end
