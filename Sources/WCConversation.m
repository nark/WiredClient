/* $Id: WCMessage.h 6709 2009-01-22 16:08:51Z morris $ */

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

#import "WCConversation.h"
#import "WCMessage.h"
#import "WCUser.h"

@interface WCConversation(Private)

- (id)_initWithName:(NSString *)name user:(WCUser *)user expandable:(BOOL)expandable connection:(WCServerConnection *)connection;

- (WCConversation *)_unreadConversationStartingAtConversation:(WCConversation *)startingConversation forwards:(BOOL)forwards passed:(BOOL *)passed;

@end


@implementation WCConversation(Private)

- (id)_initWithName:(NSString *)name user:(WCUser *)user expandable:(BOOL)expandable connection:(WCServerConnection *)connection {
	self = [self initWithConnection:connection];
	
	_name			= [name retain];
	_nick			= [[user nick] retain];
	_expandable		= expandable;
	_user			= user;
	
	return self;
}



#pragma mark -

- (WCConversation *)_unreadConversationStartingAtConversation:(WCConversation *)startingConversation forwards:(BOOL)forwards passed:(BOOL *)passed {
	WCConversation	*conversation;
	NSUInteger		i, count;
	
	count = [_conversations count];
	
	for(i = 0; i < count; i++) {
		conversation = [_conversations objectAtIndex:forwards ? i : count - i - 1];
		
		if(startingConversation == NULL || startingConversation == conversation)
			*passed = YES;
		
		if(*passed && conversation != startingConversation && [conversation isUnread])
			return conversation;
		
		conversation = [conversation _unreadConversationStartingAtConversation:startingConversation
																	  forwards:forwards
																		passed:passed];
		
		if(conversation)
			return conversation;
	}
	
	return NULL;
}

@end



@implementation WCConversation

+ (NSInteger)version {
	return 1;
}



#pragma mark -

+ (id)rootConversation {
	return [[[self alloc] _initWithName:@"<root>" user:NULL expandable:YES connection:NULL] autorelease];
}



+ (id)conversationWithUser:(WCUser *)user connection:(WCServerConnection *)connection {
	return [[[self alloc] _initWithName:[user nick] user:user expandable:NO connection:connection] autorelease];
}



- (id)initWithConnection:(WCServerConnection *)connection {
	self = [super initWithConnection:connection];
	
	_conversations	= [[NSMutableArray alloc] init];
	_messages		= [[NSMutableArray alloc] init];
	
	return self;
}



- (id)initWithCoder:(NSCoder *)coder {
	NSEnumerator	*enumerator;
	WCMessage		*message;
	
    self = [super initWithCoder:coder];
	
	if(!self)
		return NULL;
	
    if([coder decodeIntForKey:@"WCConversationVersion"] != [[self class] version]) {
        [self release];
		
        return NULL;
    }
	
	_name			= [[coder decodeObjectForKey:@"WCConversationName"] retain];
	_conversations	= [[coder decodeObjectForKey:@"WCConversationConversations"] retain];
	_nick			= [[coder decodeObjectForKey:@"WCConversationNick"] retain];
	_expandable		= [coder decodeBoolForKey:@"WCConversationExpandable"];
	
	_messages		= [[NSMutableArray alloc] init];
	enumerator		= [[coder decodeObjectForKey:@"WCConversationMessages"] objectEnumerator];
	
	while((message = [enumerator nextObject]))
		[self addMessage:message];

	return self;
}



- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInt:[[self class] version] forKey:@"WCConversationVersion"];
	
	[coder encodeObject:_name forKey:@"WCConversationName"];
	[coder encodeObject:_conversations forKey:@"WCConversationConversations"];
	[coder encodeObject:_messages forKey:@"WCConversationMessages"];
	[coder encodeObject:_nick forKey:@"WCConversationNick"];
	[coder encodeBool:_expandable forKey:@"WCConversationExpandable"];
	
	[super encodeWithCoder:coder];
}



- (void)dealloc {
	[_name release];
	[_conversations release];
	[_messages release];
	[_nick release];
	
	[super dealloc];
}



#pragma mark -

- (NSString *)description {
	return [NSSWF:@"<%@ %p>{name = %@}", [self className], self, [self name]];
}



#pragma mark -

- (NSString *)name {
	return _user ? [_user nick] : _name;
}



- (BOOL)isExpandable {
	return _expandable;
}



- (void)setUnread:(BOOL)unread {
	_unread = unread;
}



- (BOOL)isUnread {
	return _unread;
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



#pragma mark -

- (NSUInteger)numberOfConversations {
	return [_conversations count];
}



- (NSArray *)conversations {
	return _conversations;
}



- (WCConversation *)conversationAtIndex:(NSUInteger)index {
	return [_conversations objectAtIndex:index];
}



- (WCConversation *)conversationForUser:(WCUser *)user connection:(WCServerConnection *)connection {
	WCConversation		*conversation;
	NSUInteger			i, count;

	count = [_conversations count];
	
	for(i = 0; i < count; i++) {
		conversation = [_conversations objectAtIndex:i];

		if([conversation user] == user && [conversation connection] == connection)
			return conversation;
	}
	
	return NULL;
}



- (WCConversation *)previousUnreadConversationStartingAtConversation:(WCConversation *)conversation {
	BOOL	passed = NO;
	
	return [self _unreadConversationStartingAtConversation:conversation forwards:NO passed:&passed];
}



- (WCConversation *)nextUnreadConversationStartingAtConversation:(WCConversation *)conversation {
	BOOL	passed = NO;
	
	return [self _unreadConversationStartingAtConversation:conversation forwards:YES passed:&passed];
}



- (void)addConversations:(NSArray *)conversations {
	[_conversations addObjectsFromArray:conversations];
}



- (void)addConversation:(WCConversation *)conversation {
	[_conversations addObject:conversation];
}



- (void)removeConversation:(WCConversation *)conversation {
	[_conversations removeObject:conversation];
}



- (void)removeAllConversations {
	[_conversations removeAllObjects];
}



#pragma mark -

- (NSUInteger)numberOfMessages {
	return [_messages count];
}



- (NSUInteger)numberOfUnreadMessagesForConnection:(WCServerConnection *)connection includeChildConversations:(BOOL)includeChildConversations {
	WCMessage		*message;
	NSUInteger		i, count, unread;
	
	unread = 0;
	count = [_messages count];
	
	for(i = 0; i < count; i++) {
		message = [_messages objectAtIndex:i];
		
		if(!connection || [message connection] == connection) {
			if([message isUnread])
				unread++;
		}
	}
	
	if(includeChildConversations) {
		count = [_conversations count];
		
		for(i = 0; i < count; i++)
			unread += [[_conversations objectAtIndex:i] numberOfUnreadMessagesForConnection:connection includeChildConversations:includeChildConversations];
	}
	
	return unread;
}



- (NSArray *)messages {
	return _messages;
}



- (NSArray *)unreadMessages {
	NSMutableArray	*messages;
	WCMessage		*message;
	NSUInteger		i, count;
	
	messages = [NSMutableArray array];
	count = [_messages count];
		
	for(i = 0; i < count; i++) {
		message = [_messages objectAtIndex:i];
		
		if([message isUnread])
			[messages addObject:message];
	}
	
	count = [_conversations count];
	
	for(i = 0; i < count; i++)
		[messages addObjectsFromArray:[[_conversations objectAtIndex:i] unreadMessages]];

	return messages;
}



- (WCMessage *)messageAtIndex:(NSUInteger)index {
	return [_messages objectAtIndex:index];
}



- (void)addMessage:(WCMessage *)message {
	[message setConversation:self];

	if([message isUnread])
		_unread = YES;
	
	if(!_nick)
		_nick = [[message nick] retain];

	[_messages addObject:message];
}



- (void)removeMessage:(WCMessage *)message {
	[message setConversation:NULL];
	[_messages removeObject:message];
}



- (void)removeAllMessages {
	[_messages makeObjectsPerformSelector:@selector(setConversation:) withObject:NULL];
	[_messages removeAllObjects];
}



#pragma mark -

- (void)invalidateForConnection:(WCServerConnection *)connection {
	WCConversation	*conversation;
	WCMessage		*message;
	NSUInteger		i, count;
	
	count = [_messages count];
		
	for(i = 0; i < count; i++) {
		message = [_messages objectAtIndex:i];
		
		if([message connection] == connection) {
			[message setConnection:NULL];
			[message setUser:NULL];
		}
	}
	
	count = [_conversations count];
	
	for(i = 0; i < count; i++) {
		conversation = [_conversations objectAtIndex:i];
		
		if([conversation connection] == connection) {
			[conversation setConnection:NULL];
			[conversation setUser:NULL];
		}
		
		[conversation invalidateForConnection:connection];
	}
}



- (void)revalidateForConnection:(WCServerConnection *)connection {
	WCConversation	*conversation;
	WCMessage		*message;
	NSUInteger		i, count;
	
	count = [_messages count];
		
	for(i = 0; i < count; i++) {
		message = [_messages objectAtIndex:i];
		
		if([message belongsToConnection:connection])
			[message setConnection:connection];
	}
	
	count = [_conversations count];
	
	for(i = 0; i < count; i++) {
		conversation = [_conversations objectAtIndex:i];
		
		if([conversation belongsToConnection:connection])
			[conversation setConnection:connection];
		
		[conversation revalidateForConnection:connection];
	}
}



- (void)invalidateForUser:(WCUser *)user {
	WCConversation	*conversation;
	WCMessage		*message;
	NSUInteger		i, count;
	
	count = [_messages count];
	
	for(i = 0; i < count; i++) {
		message = [_messages objectAtIndex:i];
		
		if([message user] == user)
			[message setUser:NULL];
	}
	
	count = [_conversations count];
	
	for(i = 0; i < count; i++) {
		conversation = [_conversations objectAtIndex:i];
		
		if([conversation user] == user)
			[conversation setUser:NULL];
		
		[conversation invalidateForUser:user];
	}
}



- (void)revalidateForUser:(WCUser *)user {
	WCConversation	*conversation;
	WCMessage		*message;
	NSUInteger		i, count;
	
	count = [_messages count];
	
	for(i = 0; i < count; i++) {
		message = [_messages objectAtIndex:i];
		
		if(![message user] && [message connection] == [user connection]) {
			if([[user nick] isEqualToString:[message nick]])
				[message setUser:user];
		}
	}
	
	count = [_conversations count];
	
	for(i = 0; i < count; i++) {
		conversation = [_conversations objectAtIndex:i];
		
		if(![conversation user] && [conversation connection] == [user connection]) {
			if([[user nick] isEqualToString:[conversation nick]])
				[conversation setUser:user];
		}
		
		[conversation revalidateForUser:user];
	}
}

@end



@implementation WCMessageConversation : WCConversation

+ (id)rootConversation {
	return [[[self alloc] _initWithName:NSLS(@"Conversations", @"Messages item") user:NULL expandable:YES connection:NULL] autorelease];
}

@end



@implementation WCBroadcastConversation : WCConversation

+ (id)rootConversation {
	return [[[self alloc] _initWithName:NSLS(@"Broadcasts", @"Messages item") user:NULL expandable:YES connection:NULL] autorelease];
}

@end
