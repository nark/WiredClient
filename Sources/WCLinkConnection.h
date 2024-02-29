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

#import "WCConnection.h"

extern NSString * const WCLinkConnectionWillConnectNotification;
extern NSString * const WCLinkConnectionDidConnectNotification;
extern NSString * const WCLinkConnectionWillDisconnectNotification;
extern NSString * const WCLinkConnectionDidCloseNotification;
extern NSString * const WCLinkConnectionDidTerminateNotification;

extern NSString * const WCLinkConnectionReceivedMessageNotification;
extern NSString * const WCLinkConnectionReceivedErrorMessageNotification;
extern NSString * const WCLinkConnectionReceivedInvalidMessageNotification;
extern NSString * const WCLinkConnectionSentMessageNotification;

extern NSString * const WCLinkConnectionLoggedInNotification;



/*** WTransactionBlock
 * This block is called once the response message
 * associated to request message transaction identifier
 * is received. It provides a response message or error object */
typedef void (^WCTransactionBlock)(WIP7Message *response, WCError *error);



@class WCNotificationCenter;

@interface WCLinkConnection : WCConnection {
	WIP7Link							*_link;
	NSNotificationCenter				*_notificationCenter;
	WIP7NotificationCenter				*_linkNotificationCenter;
    NSMutableDictionary                 *_transactionObjects;
	WIP7UInt32							_transaction;
	
	WCError								*_error;
	
	BOOL								_disconnecting;
}

- (void)linkConnectionDidTerminate:(NSNotification *)notification;
- (void)linkConnectionDidClose:(NSNotification *)notification;
- (void)wiredClientInfoReply:(WIP7Message *)message;
- (void)wiredLoginReply:(WIP7Message *)message;

- (void)addObserver:(id)observer selector:(SEL)action name:(NSString *)name;
- (void)addObserver:(id)observer selector:(SEL)action messageName:(NSString *)messageName;
- (void)removeObserver:(id)observer;
- (void)removeObserver:(id)observer name:(NSString *)name;
- (void)removeObserver:(id)observer messageName:(NSString *)message;
- (void)removeObserver:(id)observer message:(WIP7Message *)message;
- (void)postNotificationName:(NSString *)name;
- (void)postNotificationName:(NSString *)name object:(id)object;
- (void)postNotificationName:(NSString *)name object:(id)object userInfo:(NSDictionary *)userInfo;

- (void)connect;
- (void)terminate;

- (NSUInteger)sendMessage:(WIP7Message *)message;
- (NSUInteger)sendMessage:(WIP7Message *)message fromObserver:(id)observer selector:(SEL)selector;
- (void)replyMessage:(WIP7Message *)message toMessage:(WIP7Message *)message;


//-- BLOCKS API --//
/***
 * Send a message and call the transaction block when the response message
 * corresponding to the request message transaction is received */
- (void)sendMessage:(WIP7Message *)message withBlock:(WCTransactionBlock)block;


- (BOOL)isConnected;
- (BOOL)isDisconnecting;
- (WCError *)error;

@end
