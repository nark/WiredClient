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

#import "WCMessage.h"
#import "WCUser.h"

@interface WCMessage(Private)

- (id)_initWithDirection:(WCMessageDirection)direction message:(NSString *)message user:(WCUser *)user unread:(BOOL)unread connection:(WCServerConnection *)connection;

@end


@implementation WCMessage(Private)

- (id)_initWithDirection:(WCMessageDirection)direction message:(NSString *)message user:(WCUser *)user unread:(BOOL)unread connection:(WCServerConnection *)connection {
	self = [super initWithConnection:connection];

	_direction		= direction;
	_nick			= [[user nick] retain];
	_message		= [message retain];
	_date			= [[NSDate date] retain];
	_unread			= unread;
	
	_user			= user;

	return self;
}

@end


@implementation WCMessage

+ (NSInteger)version {
	return 1;
}



#pragma mark -

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
	
	if(!self)
		return NULL;
	
    if([coder decodeIntForKey:@"WCMessageVersion"] != [[self class] version]) {
        [self release];
		
        return NULL;
    }
	
	_direction		= [coder decodeIntForKey:@"WCMessageDirection"];
	_unread			= ![coder decodeBoolForKey:@"WCMessageRead"];
	_nick			= [[coder decodeObjectForKey:@"WCMessageUserNick"] retain];
	_message		= [[coder decodeObjectForKey:@"WCMessageMessage"] retain];
	_date			= [[coder decodeObjectForKey:@"WCMessageDate"] retain];
	
	return self;
}



- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInt:[[self class] version] forKey:@"WCMessageVersion"];
	
	[coder encodeInt:_direction forKey:@"WCMessageDirection"];
	[coder encodeBool:!_unread forKey:@"WCMessageRead"];
	[coder encodeObject:_nick forKey:@"WCMessageUserNick"];
	[coder encodeObject:_message forKey:@"WCMessageMessage"];
	[coder encodeObject:_date forKey:@"WCMessageDate"];
	
	[super encodeWithCoder:coder];
}



- (void)dealloc {
	[_nick release];
	[_message release];
	[_date release];

	[super dealloc];
}



#pragma mark -

- (NSString *)description {
	NSString	*type = @"";
	
	if([self isKindOfClass:[WCPrivateMessage class]])
		type = @"message";
	else
		type = @"broadcast";
	
	return [NSSWF:@"<%@ %p>{type = %@, user = %@, date = %@}", [self className], self, type, [self nick], [self date]];
}



#pragma mark -

- (WCMessageDirection)direction {
	return _direction;
}



- (void)setUser:(WCUser *)user {
	_user = user;
}



- (WCUser *)user {
	return _user;
}



- (NSString *)nick {
	return _user ? [_user nick] : _nick;
}



- (NSString *)message {
	return _message;
}



- (NSDate *)date {
	return _date;
}



#pragma mark -

- (void)setUnread:(BOOL)unread {
	_unread = unread;
}



- (BOOL)isUnread {
	return _unread;
}



- (void)setConversation:(WCConversation *)conversation {
	_conversation = conversation;
}



- (WCConversation *)conversation {
	return _conversation;
}



#pragma mark -

- (NSComparisonResult)compareUser:(WCMessage *)message {
	NSComparisonResult	result;
	
	result = [[self nick] compare:[message nick] options:NSCaseInsensitiveSearch];
	
	if(result != NSOrderedSame)
		return result;
	
	return [self compareDate:message];
}



- (NSComparisonResult)compareDate:(WCMessage *)message {
	return [[self date] compare:[message date]];
}

@end



@implementation WCPrivateMessage

+ (WCPrivateMessage *)messageFromUser:(WCUser *)user message:(NSString *)message connection:(WCServerConnection *)connection {
	return [[[self alloc] _initWithDirection:WCMessageFrom message:message user:user unread:YES connection:connection] autorelease];
}



+ (WCPrivateMessage *)messageToSomeoneFromUser:(WCUser *)user message:(NSString *)message connection:(WCServerConnection *)connection {
	return [[[self alloc] _initWithDirection:WCMessageTo message:message user:user unread:NO connection:connection] autorelease];
}

@end



@implementation WCBroadcastMessage

+ (WCBroadcastMessage *)broadcastFromUser:(WCUser *)user message:(NSString *)message connection:(WCServerConnection *)connection {
	return [[[self alloc] _initWithDirection:WCMessageFrom message:message user:user unread:YES connection:connection] autorelease];
}

@end
