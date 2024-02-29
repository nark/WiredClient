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

@class WCBoard, WCBoardThreadFilter, WCBoardPost;

@interface WCBoardThread : WCServerConnectionObject {
    NSString                            *_board;
	NSString							*_threadID;
	NSUInteger							_replies;
	NSString							*_subject;
	NSString							*_text;
	NSDate								*_postDate;
	NSDate								*_editDate;
	NSString							*_latestReplyID;
	NSDate								*_latestReplyDate;
	BOOL								_ownThread;
	NSString							*_nick;
	NSString							*_icon;

	BOOL								_unread;
	BOOL								_loaded;
	NSMutableArray						*_posts;
	
	NSButton							*_goToLatestReplyButton;
}

+ (WCBoardThread *)threadWithMessage:(WIP7Message *)message connection:(WCServerConnection *)connection;

- (NSString *)board;
- (void)setBoard:(NSString *)board;
- (NSString *)threadID;
- (void)setSubject:(NSString *)subject;
- (NSString *)subject;
- (void)setText:(NSString *)text;
- (NSString *)text;
- (NSDate *)postDate;
- (void)setEditDate:(NSDate *)editDate;
- (NSDate *)editDate;
- (BOOL)isOwnThread;
- (void)setNumberOfReplies:(NSUInteger)numberOfReplies;
- (NSUInteger)numberOfReplies;
- (void)setLatestReplyID:(NSString *)latestReplyID;
- (NSString *)latestReplyID;
- (void)setLatestReplyDate:(NSDate *)latestReplyDate;
- (NSDate *)latestReplyDate;
- (NSString *)nick;
- (void)setIcon:(NSString *)icon;
- (NSString *)icon;
- (void)setUnread:(BOOL)unread;
- (BOOL)isUnread;
- (void)setLoaded:(BOOL)loaded;
- (BOOL)isLoaded;

- (NSButton *)goToLatestReplyButton;

- (NSArray *)posts;
- (WCBoardPost *)postAtIndex:(NSUInteger)index;
- (WCBoardPost *)postWithID:(NSString *)postID;
- (WCBoardPost *)latestPost;

- (BOOL)hasPostMatchingFilter:(WCBoardThreadFilter *)filter;
- (void)addPost:(WCBoardPost *)post;
- (void)removePost:(WCBoardPost *)post;
- (void)removeAllPosts;

- (NSComparisonResult)compareUnread:(id)object;
- (NSComparisonResult)compareSubject:(id)object;
- (NSComparisonResult)compareNick:(id)object;
- (NSComparisonResult)compareNumberOfReplies:(id)object;
- (NSComparisonResult)compareDate:(id)object;
- (NSComparisonResult)compareLatestReplyDate:(id)object;

@end


@interface WCBoardThreadFilter : WIObject {
	NSString							*_name;
	NSString							*_board;
	NSString							*_text;
	NSString							*_subject;
	NSString							*_nick;
	BOOL								_unread;
}

+ (id)filter;

- (void)setName:(NSString *)name;
- (NSString *)name;
- (void)setBoard:(NSString *)board;
- (NSString *)board;
- (void)setText:(NSString *)text;
- (NSString *)text;
- (void)setSubject:(NSString *)subject;
- (NSString *)subject;
- (void)setNick:(NSString *)nick;
- (NSString *)nick;
- (void)setUnread:(BOOL)unread;
- (BOOL)unread;

@end
