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
#import "WCBoardThread.h"
#import "WCBoards.h"

@interface WCBoardThread(Private)

- (id)_initWithMessage:(WIP7Message *)message connection:(WCServerConnection *)connection;

@end


@implementation WCBoardThread(Private)

- (id)_initWithMessage:(WIP7Message *)message connection:(WCServerConnection *)connection {
	WIP7UInt32		replies;
	WIP7Bool		ownThread;
	
	self = [super initWithConnection:connection];
    	
	_goToLatestReplyButton = [[NSButton alloc] init];
	[_goToLatestReplyButton setButtonType:NSMomentaryLightButton];
	[_goToLatestReplyButton setBordered:NO];
	[[_goToLatestReplyButton cell] setHighlightsBy:NSContentsCellMask];
	[_goToLatestReplyButton setImage:[NSImage imageNamed:@"GoToLatestPost"]];
	[_goToLatestReplyButton retain];
	
	[message getUInt32:&replies forName:@"wired.board.replies"];
	[message getBool:&ownThread forName:@"wired.board.own_thread"];
	
	_replies			= replies;
	_threadID			= [[message UUIDForName:@"wired.board.thread"] retain];
	_subject			= [[message stringForName:@"wired.board.subject"] retain];
	_postDate			= [[message dateForName:@"wired.board.post_date"] retain];
	_editDate			= [[message dateForName:@"wired.board.edit_date"] retain];
	_latestReplyID		= [[message UUIDForName:@"wired.board.latest_reply"] retain];
	_latestReplyDate	= [[message dateForName:@"wired.board.latest_reply_date"] retain];
	_ownThread			= ownThread;
	_nick				= [[message stringForName:@"wired.user.nick"] retain];
	_posts				= [[NSMutableArray alloc] init];
	
	return self;
}

@end



@implementation WCBoardThread

+ (WCBoardThread *)threadWithMessage:(WIP7Message *)message connection:(WCServerConnection *)connection {
	return [[[self alloc] _initWithMessage:message connection:connection] autorelease];
}



- (void)dealloc {
	[_threadID release];
	[_posts release];

	[_goToLatestReplyButton removeFromSuperview];
	[_goToLatestReplyButton release];
	
	[super dealloc];
}



#pragma mark -

- (BOOL)isEqual:(id)object {
	if(![self isKindOfClass:[object class]])
		return NO;
	
	return [[self threadID] isEqualToString:[object threadID]];
}



- (NSUInteger)hash {
	return [_threadID hash];
}



- (NSString *)description {
	return [NSSWF:@"<%@: %p>{id = %@, posts = %@}", [self class], self, [self threadID], [self posts]];
}



#pragma mark -

- (NSString *)threadID {
	return _threadID;
}



- (void)setSubject:(NSString *)subject {
	[subject retain];
	[_subject release];
	
	_subject = subject;
}



- (NSString *)subject {
	return _subject;
}



- (void)setText:(NSString *)text {
	[text retain];
	[_text release];
	
	_text = text;
}



- (NSString *)text {
	return _text;
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



- (BOOL)isOwnThread {
	return _ownThread;
}



- (void)setNumberOfReplies:(NSUInteger)replies {
	_replies = replies;
}



- (NSUInteger)numberOfReplies {
	return _replies;
}



- (void)setLatestReplyID:(NSString *)latestReplyID {
	[latestReplyID retain];
	[_latestReplyID release];
	
	_latestReplyID = latestReplyID;
}



- (NSString *)latestReplyID {
	return _latestReplyID;
}



- (void)setLatestReplyDate:(NSDate *)latestReplyDate {
	[latestReplyDate retain];
	[_latestReplyDate release];
	
	_latestReplyDate = latestReplyDate;
}



- (NSDate *)latestReplyDate {
    
    if(!_latestReplyDate)
        return _postDate;
    
	return _latestReplyDate;
}



- (NSString *)nick {
	return _nick;
}



- (void)setIcon:(NSString *)icon {
	[icon retain];
	[_icon release];
	
	_icon = icon;
}



- (NSString *)icon {
	return _icon;
}



- (void)setUnread:(BOOL)unread {
	_unread = unread;
}



- (BOOL)isUnread {
	return _unread;
}



- (void)setLoaded:(BOOL)loaded {
	_loaded = loaded;
}



- (BOOL)isLoaded {
	return _loaded;
}



#pragma mark -

- (NSButton *)goToLatestReplyButton {
	return _goToLatestReplyButton;
}



#pragma mark -

- (NSArray *)posts {
	return _posts;
}



- (WCBoardPost *)postAtIndex:(NSUInteger)index {
	return [_posts objectAtIndex:index];
}



- (WCBoardPost *)postWithID:(NSString *)postID {
	NSEnumerator		*enumerator;
	WCBoardPost			*post;
	
	enumerator = [_posts objectEnumerator];
	
	while((post = [enumerator nextObject])) {
		if([[post postID] isEqualToString:postID])
			return post;
	}
	
	return NULL;
}


- (WCBoardPost *)latestPost {
	return [_posts lastObject];
}



- (BOOL)hasPostMatchingFilter:(WCBoardThreadFilter *)filter {
	
	NSEnumerator		*enumerator;
	NSString			*boardString, *textString, *subjectString, *nickString;
	WCBoardPost			*post;
	WCBoard				*board;
	
	if([filter unread] && ![self isUnread])
		return NO;
		
	boardString		= [filter board];
	textString		= [filter text];
	subjectString	= [filter subject];
	nickString		= [filter nick];
	enumerator		= [_posts objectEnumerator];
	board			= [[WCBoards boards] selectedBoard];
	
	if(board && [boardString length] > 0) {
		if([[[board path] lastPathComponent] containsSubstring:boardString options:NSCaseInsensitiveSearch])
			return YES;
	}
	
	if([filter unread]) {
		if([self isUnread])
			return YES;
	}
	
	if([textString length] > 0 && [[self text] containsSubstring:textString options:NSCaseInsensitiveSearch])
		return YES;
	
	if([subjectString length] > 0 && [[self subject] containsSubstring:subjectString options:NSCaseInsensitiveSearch])
		return YES;
	
	if([nickString length] > 0 && [[self nick] containsSubstring:nickString options:NSCaseInsensitiveSearch])
		return YES;
	
	while((post = [enumerator nextObject])) {
		if([filter unread]) {
			if([post isUnread])
				return YES;
		}
		
		if([textString length] > 0 && [[post text] containsSubstring:textString options:NSCaseInsensitiveSearch])
			return YES;
		
		if([nickString length] > 0 && [[post nick] containsSubstring:nickString options:NSCaseInsensitiveSearch])
			return YES;
	}
	
	return NO;
}



- (void)addPost:(WCBoardPost *)post {
	[_posts addObject:post sortedUsingSelector:@selector(compareDate:)];
}



- (void)removePost:(WCBoardPost *)post {
	[_posts removeObject:post];
}



- (void)removeAllPosts {
	[_posts removeAllObjects];
}



#pragma mark -

- (NSComparisonResult)compareUnread:(id)object {
	if([self isUnread] && ![object isUnread])
		return NSOrderedAscending;
    else if(![self isUnread] && [object isUnread])
        return NSOrderedDescending;
	
	return [self compareDate:object];
}



- (NSComparisonResult)compareSubject:(id)object {
	NSComparisonResult		result;
	
	result = [[self subject] compare:[object subject] options:NSCaseInsensitiveSearch];
	
	if(result == NSOrderedSame)
		result = [self compareDate:object];
	
	return result;
}



- (NSComparisonResult)compareNick:(id)object {
	NSComparisonResult		result;
	
	result = [[self nick] compare:[object nick] options:NSCaseInsensitiveSearch];
	
	if(result == NSOrderedSame)
		result = [self compareDate:object];
	
	return result;
}



- (NSComparisonResult)compareNumberOfReplies:(id)object {
	if([self numberOfReplies] > [object numberOfReplies])
		return NSOrderedAscending;
	else if([self numberOfReplies] < [object numberOfReplies])
		return NSOrderedDescending;

	return [self compareLatestReplyDate:object];
}



- (NSComparisonResult)compareDate:(id)object {
	return [[self postDate] compare:[object postDate]];
}



- (NSComparisonResult)compareLatestReplyDate:(id)object {
    
//    NSLog(@"[self latestReplyDate]: %@", [self latestReplyDate]);
//    NSLog(@"[object latestReplyDate]: %@", [object latestReplyDate]);
    
	return [[self latestReplyDate] compare:[object latestReplyDate]];
}

@end



@implementation WCBoardThreadFilter

+ (NSInteger)version {
	return 2;
}



#pragma mark -

+ (id)filter {
	return [[[self alloc] init] autorelease];
}



- (id)initWithCoder:(NSCoder *)coder {
	self = [super init];
	
	_name			= [[coder decodeObjectForKey:@"WCBoardThreadFilterName"] retain];
	_board			= [[coder decodeObjectForKey:@"WCBoardThreadFilterBoard"] retain];
	_text			= [[coder decodeObjectForKey:@"WCBoardThreadFilterText"] retain];
	_subject		= [[coder decodeObjectForKey:@"WCBoardThreadFilterSubject"] retain];
	_nick			= [[coder decodeObjectForKey:@"WCBoardThreadFilterNick"] retain];
	_unread			= [coder decodeBoolForKey:@"WCBoardThreadFilterUnread"];
	
	if(!_board)
		_board = [@"" retain];

	return self;
}



- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInt:[[self class] version] forKey:@"WCBoardThreadFilterVersion"];
	
	[coder encodeObject:_name forKey:@"WCBoardThreadFilterName"];
	[coder encodeObject:_board forKey:@"WCBoardThreadFilterBoard"];
	[coder encodeObject:_text forKey:@"WCBoardThreadFilterText"];
	[coder encodeObject:_subject forKey:@"WCBoardThreadFilterSubject"];
	[coder encodeObject:_nick forKey:@"WCBoardThreadFilterNick"];
	[coder encodeBool:_unread forKey:@"WCBoardThreadFilterUnread"];
}



- (void)dealloc {
	[_name release];
	[_board release];
	[_text release];
	[_subject release];
	[_nick release];
	
	[super dealloc];
}



#pragma mark -

- (void)setName:(NSString *)name {
	[name retain];
	[_name release];
	
	_name = name;
}



- (NSString *)name {
	return _name;
}



- (void)setBoard:(NSString *)board {
	[board retain];
	[_board release];
	
	_board = board;
}



- (NSString *)board {
	return _board;
}



- (void)setText:(NSString *)text {
	[text retain];
	[_text release];
	
	_text = text;
}



- (NSString *)text {
	return _text;
}



- (void)setSubject:(NSString *)subject {
	[subject retain];
	[_subject release];
	
	_subject = subject;
}



- (NSString *)subject {
	return _subject;
}



- (void)setNick:(NSString *)nick {
	[nick retain];
	[_nick release];
	
	_nick = nick;
}



- (NSString *)nick {
	return _nick;
}



- (void)setUnread:(BOOL)unread {
	_unread = unread;
}



- (BOOL)unread {
	return _unread;
}

@end
