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

#import "WCTopic.h"

@interface WCTopic(Private)

- (id)_initWithMessage:(WIP7Message *)message;

@end


@implementation WCTopic(Private)

- (id)_initWithMessage:(WIP7Message *)message {
	WIP7UInt32	cid;
	
	self = [super init];

	[message getUInt32:&cid forName:@"wired.chat.id"];

	_chatID = cid;
	_nick = [[message stringForName:@"wired.user.nick"] retain];
	_date = [[message dateForName:@"wired.chat.topic.time"] retain];
	_topic = [[message stringForName:@"wired.chat.topic.topic"] retain];
	
	return self;
}

@end



@implementation WCTopic

+ (id)topicWithMessage:(WIP7Message *)message {
	return [[[self alloc] _initWithMessage:message] autorelease];
}



- (void)dealloc {
	[_nick release];
	[_date release];
	[_topic release];

	[super dealloc];
}



#pragma mark -

- (NSUInteger)chatID {
	return _chatID;
}



- (NSString *)nick {
	return _nick;
}



- (NSDate *)date {
	return _date;
}



- (NSString *)topic {
	return _topic;
}

@end
