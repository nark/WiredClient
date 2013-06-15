/* $Id$ */

/*
 *  Copyright (c) 2005-2009 Axel Andersson
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

#import "WCLinkConnection.h"

extern NSString * const WCServerConnectionWillReconnectNotification;

extern NSString * const WCServerConnectionTriggeredEventNotification;

extern NSString * const WCServerConnectionThemeDidChangeNotification;

extern NSString * const WCServerConnectionServerInfoDidChangeNotification;
extern NSString * const WCServerConnectionPrivilegesDidChangeNotification;

extern NSString * const WCServerConnectionReceivedServerInfoNotification;
extern NSString * const WCServerConnectionReceivedPingNotification;
extern NSString * const WCServerConnectionReceivedBannerNotification;

extern NSString * const WCServerConnectionReceivedLoginErrorNotification;

extern NSString * const	WCServerConnectionEventConnectionKey;
extern NSString * const WCServerConnectionEventInfo1Key;
extern NSString * const WCServerConnectionEventInfo2Key;


@class WCServer, WCCache, WCUserAccount;
@class WCLink, WCNotificationCenter;
@class WCAdministration, WCPublicChatController, WCConsole, WCServerInfo;

@interface WCServerConnection : WCLinkConnection {
	NSString								*_identifier;
	NSDictionary							*_theme;
	
	NSUInteger								_userID;
	
	WCServer								*_server;
	WCCache									*_cache;
	
	WCAdministration						*_administration;
	WCPublicChatController					*_chatController;
	WCConsole								*_console;
	WCServerInfo							*_serverInfo;
	
	NSMutableArray							*_connectionControllers;
	
	WITimeIntervalFormatter					*_timeIntervalFormatter;
	
	BOOL									_manuallyReconnecting;
	BOOL									_shouldAutoReconnect;
	BOOL									_willAutoReconnect;
	BOOL									_autoReconnecting;
	
	BOOL									_hasConnected;
	
	NSUInteger								_autoReconnectAttempts;
}

- (void)reconnect;

- (void)triggerEvent:(int)event;
- (void)triggerEvent:(int)event info1:(id)info1;
- (void)triggerEvent:(int)event info1:(id)info1 info2:(id)info2;

- (void)setIdentifier:(NSString *)identifier;
- (NSString *)identifier;
- (void)setTheme:(NSDictionary *)theme;
- (NSDictionary *)theme;

- (BOOL)isReconnecting;
- (BOOL)isManuallyReconnecting;
- (BOOL)isAutoReconnecting;
- (BOOL)willAutoReconnect;
- (NSUInteger)userID;
- (NSString *)name;
- (WCUserAccount *)account;
- (WCServer *)server;
- (WCCache *)cache;

- (WCAdministration *)administration;
- (WCPublicChatController *)chatController;
- (WCConsole *)console;
- (WCServerInfo *)serverInfo;

- (BOOL)supportsResourceForks;

- (void)log:(NSString *)format, ...;

- (void)addConnectionController:(WCConnectionController *)connectionController;
- (void)removeConnectionController:(WCConnectionController *)connectionController;

@end
