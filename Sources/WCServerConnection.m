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

#import "WCAccount.h"
#import "WCAdministration.h"
#import "WCApplicationController.h"
#import "WCBoards.h"
#import "WCCache.h"
#import "WCConsole.h"
#import "WCMessages.h"
#import "WCPreferences.h"
#import "WCPublicChat.h"
#import "WCPublicChatController.h"
#import "WCServer.h"
#import "WCServerConnection.h"
#import "WCServerInfo.h"
#import "WCTransfers.h"

NSString * const WCServerConnectionWillReconnectNotification			= @"WCServerConnectionWillReconnectNotification";

NSString * const WCServerConnectionTriggeredEventNotification			= @"WCServerConnectionTriggeredEventNotification";

NSString * const WCServerConnectionThemeDidChangeNotification			= @"WCServerConnectionThemeDidChangeNotification";

NSString * const WCServerConnectionServerInfoDidChangeNotification		= @"WCServerConnectionServerInfoDidChangeNotification";
NSString * const WCServerConnectionPrivilegesDidChangeNotification		= @"WCServerConnectionPrivilegesDidChangeNotification";

NSString * const WCServerConnectionReceivedServerInfoNotification		= @"WCServerConnectionReceivedServerInfoNotification";
NSString * const WCServerConnectionReceivedPingNotification				= @"WCServerConnectionReceivedPingNotification";
NSString * const WCServerConnectionReceivedBannerNotification			= @"WCServerConnectionReceivedBannerNotification";

NSString * const WCServerConnectionReceivedLoginErrorNotification		= @"WCServerConnectionReceivedLoginErrorNotification";

NSString * const WCServerConnectionEventConnectionKey					= @"WCServerConnectionEventConnectionKey";
NSString * const WCServerConnectionEventInfo1Key						= @"WCServerConnectionEventInfo1Key";
NSString * const WCServerConnectionEventInfo2Key						= @"WCServerConnectionEventInfo2Key";


@interface WCServerConnection(Private)

- (void)_triggerAutoReconnect;
- (void)_autoReconnect;

@end


@implementation WCServerConnection(Private)

- (void)_triggerAutoReconnect {
	NSTimeInterval		interval;
	
	if(_shouldAutoReconnect && ([[WCSettings settings] boolForKey:WCAutoReconnect] || [[self bookmark] boolForKey:WCBookmarksAutoReconnect])) {
		if(_autoReconnectAttempts < 6)
			interval = 10.0;
		else if(_autoReconnectAttempts < 10)
			interval = 30.0;
		else if(_autoReconnectAttempts < 15)
			interval = 60.0;
		else if(_autoReconnectAttempts < 21)
			interval = 600.0;
		else
			interval = 3600.0;
		
		[[self chatController] printEvent:[NSSWF:NSLS(@"Reconnecting to %@ in %@...", @"Auto-reconnecting chat message (server, time)"),
			[self name],
			[_timeIntervalFormatter stringFromTimeInterval:interval]]];
		
		[self performSelector:@selector(_autoReconnect) afterDelay:interval];
		
		_autoReconnectAttempts++;
	}
}



- (void)_autoReconnect {
	if(![self isConnected] && !_autoReconnecting) {
		_willAutoReconnect		= NO;
		_autoReconnecting		= YES;
		_manuallyReconnecting	= NO;
		
		[self postNotificationName:WCServerConnectionWillReconnectNotification object:self];

		[self connect];
	}
}

@end



@implementation WCServerConnection

- (id)init {
	self = [super init];
	
	_server					= [[WCServer alloc] init];
	_cache					= [[WCCache alloc] initWithCapacity:100];
	_connectionControllers	= [[NSMutableArray alloc] init];
	_identifier				= [[NSString UUIDString] retain];
	
	_timeIntervalFormatter	= [[WITimeIntervalFormatter alloc] init];
	
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		   selector:@selector(nickDidChange:)
			   name:WCNickDidChangeNotification];

	[[NSNotificationCenter defaultCenter]
		addObserver:self
		   selector:@selector(statusDidChange:)
			   name:WCStatusDidChangeNotification];

	[[NSNotificationCenter defaultCenter]
		addObserver:self
		   selector:@selector(iconDidChange:)
			   name:WCIconDidChangeNotification];

	[[NSNotificationCenter defaultCenter]
		addObserver:self
		   selector:@selector(themeDidChange:)
			   name:WCThemeDidChangeNotification];

	[[NSNotificationCenter defaultCenter]
		addObserver:self
		   selector:@selector(bookmarkDidChange:)
			   name:WCBookmarkDidChangeNotification];

	[self addObserver:self
			 selector:@selector(chatSelfWasKickedFromPublicChat:)
				 name:WCChatSelfWasKickedFromPublicChatNotification];

	[self addObserver:self
			 selector:@selector(chatSelfWasBanned:)
				 name:WCChatSelfWasBannedNotification];

	[self addObserver:self
			 selector:@selector(chatSelfWasDisconnected:)
				 name:WCChatSelfWasDisconnectedNotification];

	[self addObserver:self selector:@selector(wiredServerInfo:) messageName:@"wired.server_info"];
	[self addObserver:self selector:@selector(wiredAccountPrivileges:) messageName:@"wired.account.privileges"];
	
	return self;
}



- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[_identifier release];
	[_theme release];
	
	[_server release];
	[_cache release];
	
	[_connectionControllers release];
	[_chatController release];
	
	[_timeIntervalFormatter release];
	
	[super dealloc];
}



#pragma mark -

- (void)nickDidChange:(NSNotification *)notification {
	[self sendMessage:[self setNickMessage]];
}



- (void)statusDidChange:(NSNotification *)notification {
	[self sendMessage:[self setStatusMessage]];
}



- (void)iconDidChange:(NSNotification *)notification {
	[self sendMessage:[self setIconMessage]];
}



- (void)themeDidChange:(NSNotification *)notification {
	NSDictionary	*theme;
	NSString		*identifier;
	
	theme		= [notification object];
	identifier	= [theme objectForKey:WCThemesIdentifier];
	
	if([identifier isEqualToString:[[self theme] objectForKey:WCThemesIdentifier]] ||
	   (![[self bookmark] objectForKey:WCBookmarksTheme] && [identifier isEqualToString:[[WCSettings settings] objectForKey:WCTheme]])) {
		[self setTheme:theme];
		
		[self postNotificationName:WCServerConnectionThemeDidChangeNotification object:self];
	}
}



- (void)bookmarkDidChange:(NSNotification *)notification {
	NSDictionary	*bookmark, *theme;
	NSString		*identifier;
	
	bookmark	= [notification object];
	identifier	= [bookmark objectForKey:WCBookmarksIdentifier];
	
	if([identifier isEqualToString:[[self bookmark] objectForKey:WCBookmarksIdentifier]]) {
		theme = [[WCSettings settings] themeWithIdentifier:[bookmark objectForKey:WCBookmarksTheme]];
		
		if(!theme)
			theme = [[WCSettings settings] themeWithIdentifier:[[WCSettings settings] objectForKey:WCTheme]];
		
		if(![[[self theme] objectForKey:WCThemesIdentifier] isEqualToString:[theme objectForKey:WCThemesIdentifier]]) {
			[self setTheme:theme];
			
			[self postNotificationName:WCServerConnectionThemeDidChangeNotification object:self];
		}
		
		[self setBookmark:bookmark];
		
		[self sendMessage:[self setNickMessage]];
		[self sendMessage:[self setStatusMessage]];
	}
}



- (void)linkConnectionDidTerminate:(NSNotification *)notification {
	NSEnumerator			*enumerator;
	WCConnectionController	*controller;

	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_autoReconnect)];
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_triggerAutoReconnect)];
	
	enumerator = [[[_connectionControllers copy] autorelease] objectEnumerator];
	
	while((controller = [enumerator nextObject]))
		[controller close];
	
	[_connectionControllers removeAllObjects];
	
	[_chatController release];
	_chatController = NULL;
	
	[super linkConnectionDidTerminate:notification];
}



- (void)linkConnectionDidClose:(NSNotification *)notification {
	NSString	*reason;
	NSInteger	code;
	BOOL		autoReconnect = YES;
	
	[super linkConnectionDidClose:notification];
	
	if(_hasConnected && [[[WCPublicChat publicChat] chatControllers] containsObject:_chatController]) {
		[self triggerEvent:WCEventsServerDisconnected];
		
		reason = [_error localizedFailureReason];
		
		if([reason length] > 0)
			reason = [reason substringToIndex:[reason length] - 1];
		
		if([self isReconnecting]) {
			if(reason)
				[_chatController printEvent:reason];
			
			if([[_error domain] isEqualToString:WIWiredNetworkingErrorDomain] && [_error code] == WISocketConnectFailed) {
				code = [[[_error userInfo] objectForKey:WILibWiredErrorKey] code];
				
				if(code == WI_ERROR_P7_HANDSHAKEFAILED ||
				   code == WI_ERROR_P7_INCOMPATIBLESPEC ||
				   code == WI_ERROR_P7_AUTHENTICATIONFAILED) {
					autoReconnect = NO;
				}
			}
		} else {
			if([reason length] > 0) {
				[_chatController printEvent:[NSSWF:NSLS(@"Disconnected from %@: %@", @"Disconnected chat message (server, error)"),
					[self name], reason]];
			} else {
				[_chatController printEvent:[NSSWF:NSLS(@"Disconnected from %@", @"Disconnected chat message (server)"),
					[self name], reason]];
			}			
            
            if([[WCSettings settings] boolForKey:WCOrderFrontWhenDisconnected]) {
                [[WCPublicChat publicChat] selectChatController:_chatController];
                [[WCPublicChat publicChat] showWindow:self];
            }
		}
		
		if(!_manuallyReconnecting && !_disconnecting && autoReconnect) {
			[self performSelector:@selector(_triggerAutoReconnect) afterDelay:1.0];
			
			_willAutoReconnect = YES;
		}

		_manuallyReconnecting	= NO;
		_autoReconnecting		= NO;
	}
}



- (void)wiredSendPing:(WIP7Message *)message {
	[self replyMessage:[WIP7Message messageWithName:@"wired.ping" spec:WCP7Spec] toMessage:message];
}



- (void)wiredServerInfo:(WIP7Message *)message {
	[_server setWithMessage:message];
	
	if([self isReconnecting]) {
		[[self chatController] printEvent:[NSSWF:NSLS(@"Reconnected to %@", @"Reconnected chat message"),
			[self name]]];
	}

	[self postNotificationName:WCServerConnectionServerInfoDidChangeNotification object:self];
}



- (void)wiredClientInfoReply:(WIP7Message *)message {
	[self wiredServerInfo:message];
	[super wiredClientInfoReply:message];
}



- (void)wiredLoginReply:(WIP7Message *)message {
	if([[message name] isEqualToString:@"wired.login"]) {
		[message getUInt32:(unsigned int*)&_userID forName:@"wired.user.id"];

		[self triggerEvent:WCEventsServerConnected];
	}
	else if([[message name] isEqualToString:@"wired.account.privileges"]) {
		[_server setAccount:[WCUserAccount accountWithMessage:message]];

		[self postNotificationName:WCServerConnectionPrivilegesDidChangeNotification object:self];
	}
	else if([[message name] isEqualToString:@"wired.banned"]) {
		[_error release];
		_error = [[WCError errorWithDomain:WCWiredClientErrorDomain code:WCWiredClientBanned] retain];
		
		[self postNotificationName:WCServerConnectionReceivedLoginErrorNotification object:self];
	}
	else if([[message name] isEqualToString:@"wired.error"]) {
		[_error release];
		_error = [[WCError errorWithWiredMessage:message] retain];
		
		[self postNotificationName:WCServerConnectionReceivedLoginErrorNotification object:self];
	}
	
	[super wiredLoginReply:message];

	_manuallyReconnecting	= NO;
	_autoReconnecting		= NO;
	_shouldAutoReconnect	= YES;

	_autoReconnectAttempts	= 0;
	
	_hasConnected			= YES;
}



- (void)wiredAccountPrivileges:(WIP7Message *)message {
	[_server setAccount:[WCUserAccount accountWithMessage:message]];

	[self postNotificationName:WCServerConnectionPrivilegesDidChangeNotification object:self];
}



- (void)chatSelfWasKickedFromPublicChat:(NSNotification *)notification {
	_shouldAutoReconnect = NO;
	
	[self disconnect];
}



- (void)chatSelfWasBanned:(NSNotification *)notification {
	_shouldAutoReconnect = NO;
    
    [self disconnect];
}



- (void)chatSelfWasDisconnected:(NSNotification *)notification {
	_shouldAutoReconnect = NO;
}



#pragma mark -

- (void)connect {
	if(!_chatController) {
#if defined(WCConfigurationDebug) || defined(WCConfigurationTest)
		_console		= [WCConsole consoleWithConnection:self];
#endif
		
		_administration	= [WCAdministration administrationWithConnection:self];
		_serverInfo		= [WCServerInfo serverInfoWithConnection:self];

		_chatController	= [[WCPublicChatController publicChatControllerWithConnection:self] retain];
	}
	
	[super connect];
}



- (void)reconnect {
	if(![self isConnected] && !_manuallyReconnecting) {
		_autoReconnecting		= NO;
		_manuallyReconnecting	= YES;
		_willAutoReconnect		= NO;
		_shouldAutoReconnect	= YES;
		
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_autoReconnect)];
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_triggerAutoReconnect)];
		
		[[self chatController] printEvent:[NSSWF:NSLS(@"Reconnecting to %@...", @"Reconnecting chat message"),
			[self name]]];
		
		[self postNotificationName:WCServerConnectionWillReconnectNotification object:self];

		[self connect];
	}
}



#pragma mark -

- (void)triggerEvent:(int)tag {
	[self triggerEvent:tag info1:NULL info2:NULL];
}



- (void)triggerEvent:(int)tag info1:(id)info1 {
	[self triggerEvent:tag info1:info1 info2:NULL];
}



- (void)triggerEvent:(int)tag info1:(id)info1 info2:(id)info2 {
	NSMutableDictionary	*userInfo;
	NSDictionary		*event;
	
	event = [[WCSettings settings] eventWithTag:tag];
	userInfo = [NSMutableDictionary dictionaryWithObject:self forKey:WCServerConnectionEventConnectionKey];
	
	if(info1)
		[userInfo setObject:info1 forKey:WCServerConnectionEventInfo1Key];
	
	if(info2)
		[userInfo setObject:info2 forKey:WCServerConnectionEventInfo2Key];
	
	[self postNotificationName:WCServerConnectionTriggeredEventNotification object:event userInfo:userInfo];
}



#pragma mark -

- (void)setIdentifier:(NSString *)identifier {
	[identifier retain];
	[_identifier release];
	
	_identifier = identifier;
}



- (NSString *)identifier {
	return _identifier;
}



- (void)setTheme:(NSDictionary *)theme {
	[_theme release];
	_theme = [theme copy];
}



- (NSDictionary *)theme {
	return _theme;
}



#pragma mark -

- (BOOL)isDisconnecting {
	return _disconnecting;
}



- (BOOL)isReconnecting {
	return (_manuallyReconnecting || _autoReconnecting);
}



- (BOOL)isManuallyReconnecting {
	return _manuallyReconnecting;
}



- (BOOL)isAutoReconnecting {
	return _autoReconnecting;
}



- (BOOL)willAutoReconnect {
	return _willAutoReconnect;
}



- (NSUInteger)userID {
	return _userID;
}



- (NSString *)name {
	return [_server name];
}



- (WCUserAccount *)account {
	return [_server account];
}



- (WCServer *)server {
	return _server;
}



- (WCCache *)cache {
	return _cache;
}



#pragma mark -

- (WCAdministration *)administration {
	return _administration;
}



- (WCPublicChatController *)chatController {
	return _chatController;
}



- (WCConsole *)console {
	return _console;
}



- (WCServerInfo *)serverInfo {
	return _serverInfo;
}



#pragma mark -

- (BOOL)supportsResourceForks {
	return [[self server] supportsResourceForks];
}



#pragma mark -

- (void)log:(NSString *)format, ... {
	NSString		*string;
	va_list			ap;
	
	va_start(ap, format);
	string = [[NSString alloc] initWithFormat:format arguments:ap];
	va_end(ap);
	
	[_console log:string];
	
	[string release];
}



#pragma mark -

- (void)addConnectionController:(WCConnectionController *)connectionController {
	[_connectionControllers addObject:connectionController];
}



- (void)removeConnectionController:(WCConnectionController *)connectionController {
	[_connectionControllers removeObject:connectionController];
}

@end
