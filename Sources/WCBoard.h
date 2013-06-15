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

#import "WCServerConnectionObject.h"

enum _WCBoardPermissions {
	WCBoardOwnerWrite					= (2 << 6),
	WCBoardOwnerRead					= (4 << 6),
	WCBoardGroupWrite					= (2 << 3),
	WCBoardGroupRead					= (4 << 3),
	WCBoardEveryoneWrite				= (2 << 0),
	WCBoardEveryoneRead					= (4 << 0)
};
typedef enum _WCBoardPermissions		WCBoardPermissions;


@class WCBoardThread, WCBoardThreadFilter, WCUserAccount;

@interface WCBoard : WCServerConnectionObject {
	NSString							*_name;
	NSString							*_path;
	BOOL								_readable;
	BOOL								_writable;
	
	NSInteger							_sorting;
	BOOL								_expanded;
	
	NSMutableArray						*_boards;
	
	NSMutableArray						*_threadsArray;
	NSMutableDictionary					*_threadsDictionary;
}

+ (WCBoard *)rootBoard;
+ (WCBoard *)rootBoardWithName:(NSString *)name;
+ (WCBoard *)boardWithConnection:(WCServerConnection *)connection;
+ (WCBoard *)boardWithMessage:(WIP7Message *)message connection:(WCServerConnection *)connection;

- (void)setName:(NSString *)name;
- (NSString *)name;
- (void)setPath:(NSString *)path;
- (NSString *)path;
- (void)setSorting:(NSInteger)sorting;
- (NSInteger)sorting;
- (void)setExpanded:(BOOL)expanded;
- (BOOL)isExpanded;
- (BOOL)isExpandable;
- (BOOL)isRootBoard;
- (void)setReadable:(BOOL)readable;
- (BOOL)isReadable;
- (void)setWritable:(BOOL)writable;
- (BOOL)isWritable;

- (NSUInteger)numberOfBoards;
- (NSArray *)boards;
- (NSArray *)subBoards;
- (NSArray *)boardsWithExpansionStatus:(BOOL)expansionStatus;
- (WCBoard *)boardAtIndex:(NSUInteger)index;
- (WCBoard *)boardForConnection:(WCServerConnection *)connection;
- (WCBoard *)boardForPath:(NSString *)path;
- (void)addBoard:(WCBoard *)board;
- (void)removeBoard:(WCBoard *)board;
- (void)removeAllBoards;
- (void)sortBoardsUsingSelector:(SEL)selector includeChildBoards:(BOOL)includeChildBoards;

- (NSUInteger)numberOfThreads;
- (NSUInteger)numberOfThreadsIncludingChildBoards:(BOOL)includeChildBoards;
- (NSUInteger)numberOfUnreadThreadsForConnection:(WCServerConnection *)connection includeChildBoards:(BOOL)includeChildBoards;
- (NSArray *)threads;
- (WCBoardThread *)threadAtIndex:(NSUInteger)index;
- (WCBoardThread *)threadWithID:(NSString *)string;
- (NSUInteger)indexOfThread:(WCBoardThread *)thread;
- (NSArray *)threadsMatchingFilter:(WCBoardThreadFilter *)filter includeChildBoards:(BOOL)includeChildBoards;
- (WCBoardThread *)previousUnreadThreadStartingAtBoard:(WCBoard *)board thread:(WCBoardThread *)thread forwardsInThreads:(BOOL)forwardsInThreads;
- (WCBoardThread *)nextUnreadThreadStartingAtBoard:(WCBoard *)board thread:(WCBoardThread *)thread forwardsInThreads:(BOOL)forwardsInThreads;
- (void)addThread:(WCBoardThread *)thread sortedUsingSelector:(SEL)selector;
- (void)addThreads:(NSArray *)threads;
- (void)removeThread:(WCBoardThread *)thread;
- (void)removeAllThreads;
- (void)sortThreadsUsingSelector:(SEL)selector;

- (void)invalidateForConnection:(WCServerConnection *)connection;
- (void)revalidateForConnection:(WCServerConnection *)connection;

- (NSComparisonResult)compareBoard:(WCBoard *)board;

@end


@interface WCSmartBoard : WCBoard {
	WCBoardThreadFilter				*_filter;
}

+ (id)smartBoard;

- (void)setFilter:(WCBoardThreadFilter *)filter;
- (WCBoardThreadFilter *)filter;

@end


@interface WCSearchBoard : WCSmartBoard

@end
