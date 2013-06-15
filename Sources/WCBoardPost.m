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

#import "WCBoardPost.h"

@implementation WCBoardPost

+ (WCBoardPost *)postWithMessage:(WIP7Message *)message connection:(WCServerConnection *)connection {
	return [[[self alloc] initWithMessage:message connection:connection] autorelease];
}



- (id)initWithMessage:(WIP7Message *) message connection:(WCServerConnection *)connection {
	WIP7Bool	ownPost;
	
	self = [self initWithConnection:connection];
	
	[message getBool:&ownPost forName:@"wired.board.own_post"];
	
	_postID		= [[message UUIDForName:@"wired.board.post"] retain];
	_postDate	= [[message dateForName:@"wired.board.post_date"] retain];
	_editDate	= [[message dateForName:@"wired.board.edit_date"] retain];
	_text		= [[message stringForName:@"wired.board.text"] retain];
	_nick		= [[message stringForName:@"wired.user.nick"] retain];
	_icon		= [[[message dataForName:@"wired.user.icon"] base64EncodedString] retain];
	_ownPost	= ownPost;
	
	return self;
}



- (void)dealloc {
	[_postID release];
	[_postDate release];
	[_editDate release];
	[_nick release];
	[_icon release];
	[_text release];
	
	[super dealloc];
}



#pragma mark -

- (NSString *)description {
	return [NSSWF:@"<%@: %p>{id = %@, postdate = %@}",
		[self class], self, [self postID], [self postDate]];
}



#pragma mark -

- (NSString *)postID {
	return _postID;
}



- (NSDate *)postDate {
	return _postDate;
}



- (void)setEditDate:(NSDate *)editDate {
	[editDate retain];
	[_editDate release];
	
	_editDate = editDate;
}



- (NSDate *)editDate {
	return _editDate;
}



- (NSString *)nick {
	return _nick;
}



- (NSString *)icon {
	return _icon;
}



- (BOOL)isOwnPost {
	return _ownPost;
}



- (void)setText:(NSString *)text {
	[text retain];
	[_text release];
	
	_text = text;
}



- (NSString *)text {
	return _text;
}



- (void)setUnread:(BOOL)unread {
	_unread = unread;
}



- (BOOL)isUnread {
	return _unread;
}



#pragma mark -

- (NSComparisonResult)compareDate:(id)object {
	return [_postDate compare:[object postDate]];
}

@end
