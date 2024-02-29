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

#import "WCAccount.h"
#import "WCBoard.h"
#import "WCBoardThread.h"

@interface WCBoard(Private)

- (id)_initWithMessage:(WIP7Message *)message connection:(WCServerConnection *)connection;
- (id)_initWithPath:(NSString *)path name:(NSString *)name connection:(WCServerConnection *)connection ;

- (WCBoard *)_boardWithName:(NSString *)name;
- (WCBoardThread *)_unreadThreadStartingAtBoard:(WCBoard *)startingBoard thread:(WCBoardThread *)startingThread forwardsInBoards:(BOOL)forwardsInBoards forwardsInThreads:(BOOL)forwardsInThreads passed:(BOOL *)passed;

@end


@implementation WCBoard(Private)

- (id)_initWithMessage:(WIP7Message *)message connection:(WCServerConnection *)connection {
	NSString		*path;
	WIP7Bool		readable, writable;
	    
	path = [message stringForName:@"wired.board.board"];
	
	[message getBool:&readable forName:@"wired.board.readable"];
	[message getBool:&writable forName:@"wired.board.writable"];

	self = [self _initWithPath:path name:[path lastPathComponent] connection:connection];
	
	_readable = readable;
	_writable = writable;
	
	return self;
}



- (id)_initWithPath:(NSString *)path name:(NSString *)name connection:(WCServerConnection *)connection {
	self = [self initWithConnection:connection];
	    
	_name				= [name retain];
	_path				= [path retain];
	_boards				= [[NSMutableArray alloc] init];
	_threadsArray		= [[NSMutableArray alloc] init];
	_threadsDictionary	= [[NSMutableDictionary alloc] init];
	
	return self;
}



#pragma mark -

- (WCBoard *)_boardWithName:(NSString *)name {
	NSEnumerator	*enumerator;
	WCBoard			*board;
	
	enumerator = [_boards objectEnumerator];
	
	while((board = [enumerator nextObject])) {
		if([[board name] isEqualToString:name])
			return board;
	}
	
	return NULL;
}



#pragma mark -

- (WCBoardThread *)_unreadThreadStartingAtBoard:(WCBoard *)startingBoard thread:(WCBoardThread *)startingThread forwardsInBoards:(BOOL)forwardsInBoards forwardsInThreads:(BOOL)forwardsInThreads passed:(BOOL *)passed {
	WCBoard			*board;
	WCBoardThread	*thread;
	NSUInteger		i, count;
	
	count = [_threadsArray count];
	
	for(i = 0; i < count; i++) {
		thread = [_threadsArray objectAtIndex:forwardsInThreads ? i : count - i - 1];
		
		if((startingBoard == NULL || startingBoard == self) &&
		   (startingThread == NULL || startingThread == thread))
			*passed = YES;
		
		if(*passed && thread != startingThread && [thread isUnread])
			return thread;
	}
	
	count = [_boards count];
	
	for(i = 0; i < count; i++) {
		board = [_boards objectAtIndex:forwardsInBoards ? i : count - i - 1];
		thread = [board _unreadThreadStartingAtBoard:startingBoard
											  thread:startingThread
									forwardsInBoards:forwardsInBoards
								   forwardsInThreads:forwardsInThreads
											  passed:passed];
		
		if(thread)
			return thread;
	}
	
	return NULL;
}

@end



@implementation WCBoard

+ (NSInteger)version {
	return 1;
}



#pragma mark -

+ (WCBoard *)rootBoard {
	return [[[self alloc] _initWithPath:@"/" name:@"<root>" connection:NULL] autorelease];
}



+ (WCBoard *)rootBoardWithName:(NSString *)name {
	return [[[self alloc] _initWithPath:@"/" name:name connection:NULL] autorelease];
}



+ (WCBoard *)boardWithConnection:(WCServerConnection *)connection {
	return [[[self alloc] _initWithPath:@"/" name:[connection name] connection:connection] autorelease];
}



+ (WCBoard *)boardWithMessage:(WIP7Message *)message connection:(WCServerConnection *)connection {
	NSString		*path;
	WCBoard			*board;
	WIP7Bool		readable, writable;
	
    
	path = [message stringForName:@"wired.board.board"];
	
	[message getBool:&readable forName:@"wired.board.readable"];
	[message getBool:&writable forName:@"wired.board.writable"];

	board = [[self alloc] _initWithPath:path name:[path lastPathComponent] connection:connection];
	
	[board setReadable:readable];
	[board setWritable:writable];
	
	return board;
}



- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
	
	if(!self)
		return NULL;
	
	if([coder decodeIntForKey:@"WCBoardVersion"] != [[self class] version]) {
		[self release];
		
		return NULL;
	}
	
	_path = [[coder decodeObjectForKey:@"WCBoardPath"] retain];
	
	return self;
}



- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeInt:[[self class] version] forKey:@"WCBoardVersion"];
	
	[coder encodeObject:_path forKey:@"WCBoardPath"];
	
	[super encodeWithCoder:coder];
}



- (void)dealloc {
	[_name release];
	[_path release];
	[_boards release];
	[_threadsArray release];
	[_threadsDictionary release];
	
	[super dealloc];
}



#pragma mark -

- (BOOL)isEqual:(id)object {
	if(![object isKindOfClass:[self class]])
		return NO;
	
	return ([[self path] isEqual:[object path]] && [self connection] == [(WCBoard *) object connection]);
}



- (NSUInteger)hash {
	return [[self path] hash] + [[self connection] hash];
}



- (NSString *)description {
	return [NSSWF:@"<%@: %p>{board = %@}", [self class], self, [self path]];
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



- (void)setPath:(NSString *)path {
	NSMutableString		*childPath;
	WCBoard				*board;
	NSRange				range;
	NSUInteger			i, count;
	
	count = [_boards count];
	
	for(i = 0; i < count; i++) {
		board = [_boards objectAtIndex:i];
		
		if(![board isKindOfClass:[WCSmartBoard class]]) {
			childPath	= [[[board path] mutableCopy] autorelease];
			range		= [childPath rangeOfString:_path];
			
			if(range.location == 0) {
				[childPath replaceCharactersInRange:range withString:path];
				
				[board setPath:childPath];
			}
		}
	}
	
	[path retain];
	[_path release];
	
	_path = path;
}



- (NSString *)path {
	return _path;
}



- (void)setSorting:(NSInteger)sorting {
	_sorting = sorting;
}



- (NSInteger)sorting {
	return _sorting;
}



- (void)setExpanded:(BOOL)expanded {
	_expanded = expanded;
}



- (BOOL)isExpanded {
	return _expanded;
}



- (BOOL)isExpandable {
	return ([_boards count] > 0);
}



- (BOOL)isRootBoard {
	return [_path isEqualToString:@"/"];
}



- (void)setReadable:(BOOL)readable {
	_readable = readable;
}



- (BOOL)isReadable {
	return _readable;
}



- (void)setWritable:(BOOL)writable {
	_writable = writable;
}



- (BOOL)isWritable {
	return _writable;
}



#pragma mark -

- (NSUInteger)numberOfBoards {
	return [_boards count];
}



- (NSArray *)boards {
	return _boards;
}

/* Hightly recursive */
- (NSArray *)subBoards {
    NSMutableArray *subBoards = [NSMutableArray array];
    
    for(WCBoard *board in [self boards]) {
        [subBoards addObject:board];
        [subBoards addObjectsFromArray:[board subBoards]];
    }
    return subBoards;
}


- (NSArray *)boardsWithExpansionStatus:(BOOL)expansionStatus {
	NSMutableArray		*array;
	WCBoard				*board;
	NSUInteger			i, count;
	
	array = [NSMutableArray array];
	count = [_boards count];
	
	for(i = 0; i < count; i++) {
		board = [_boards objectAtIndex:i];
		
		if([board isExpanded] == expansionStatus && [board numberOfBoards] > 0)
			[array addObject:board];
		
		[array addObjectsFromArray:[board boardsWithExpansionStatus:expansionStatus]];
	}
	
	return array;
}



- (WCBoard *)boardAtIndex:(NSUInteger)index {
	return [_boards objectAtIndex:index];
}



- (WCBoard *)boardForConnection:(WCServerConnection *)connection {
	NSEnumerator	*enumerator;
	WCBoard			*board;
	
	enumerator = [_boards objectEnumerator];
	
	while((board = [enumerator nextObject])) {
		if([board connection] == connection)
			return board;
	}
	
	return NULL;
}



- (WCBoard *)boardForPath:(NSString *)path {
	NSEnumerator	*enumerator;
	NSArray			*components;
	NSString		*component;
	WCBoard			*board, *child;
	
	components	= [path componentsSeparatedByString:@"/"];

	if([components count] == 0)
		return self;
	
	board = self;
	enumerator = [components objectEnumerator];
	
	while((component = [enumerator nextObject])) {
		child = [board _boardWithName:component];
		
		if(!child)
			break;
		
		board = child;
	}
	
	return board;
}



- (void)addBoard:(WCBoard *)board {
	[_boards addObject:board sortedUsingSelector:@selector(compareBoard:)];
}



- (void)removeBoard:(WCBoard *)board {
	[_boards removeObject:board];
}



- (void)removeAllBoards {
	[_boards removeAllObjects];
}



- (void)sortBoardsUsingSelector:(SEL)selector includeChildBoards:(BOOL)includeChildBoards {
	WCBoard			*board;
	NSUInteger		i, count;
	
	[_boards sortUsingSelector:selector];

	if(includeChildBoards) {
		count = [_boards count];
		
		for(i = 0; i < count; i++) {
			board = [_boards objectAtIndex:i];
			
			if(![board isKindOfClass:[WCSmartBoard class]])
				[board sortBoardsUsingSelector:selector includeChildBoards:includeChildBoards];
		}
	}
}



#pragma mark -

- (NSUInteger)numberOfThreads {
	return [_threadsArray count];
}



- (NSUInteger)numberOfThreadsIncludingChildBoards:(BOOL)includeChildBoards {
	WCBoard			*board;
	NSUInteger		i, count, number = 0;
	
	number = [_threadsArray count];
	
	if(includeChildBoards) {
		count = [_boards count];
		
		for(i = 0; i < count; i++) {
			board = [_boards objectAtIndex:i];
			
			if(![board isKindOfClass:[WCSmartBoard class]])
				number += [board numberOfThreadsIncludingChildBoards:includeChildBoards];
		}
	}
	
	return number;
}



- (NSUInteger)numberOfUnreadThreadsForConnection:(WCServerConnection *)connection includeChildBoards:(BOOL)includeChildBoards {
	WCBoard				*board;
	WCBoardThread		*thread;
	WCBoardPost			*post;
	NSUInteger			i, j, count, count2, unread = 0;
	
	count = [_threadsArray count];
	
	for(i = 0; i < count; i++) {
		thread = [_threadsArray objectAtIndex:i];

		if(!connection || [thread connection] == connection) {
			if([thread isUnread])
				unread++;
			
			count2 = [[thread posts] count];
			
			for(j = 0; j < count2; j++) {
				post = [thread postAtIndex:j];
				
				if([post isUnread])
					unread++;
			}
		}
	}
	
	if(includeChildBoards) {
		count = [_boards count];
		
		for(i = 0; i < count; i++) {
			board = [_boards objectAtIndex:i];
			
			if(board && ![board isKindOfClass:[WCSmartBoard class]])
				unread += [board numberOfUnreadThreadsForConnection:connection includeChildBoards:includeChildBoards];
		}
	}
		
	return unread;
}



- (NSArray *)threads {
	return _threadsArray;
}



- (WCBoardThread *)threadAtIndex:(NSUInteger)index {
	return [_threadsArray objectAtIndex:index];
}



- (WCBoardThread *)threadWithID:(NSString *)string {
	return [_threadsDictionary objectForKey:string];
}



- (NSUInteger)indexOfThread:(WCBoardThread *)thread {
	return [_threadsArray indexOfObject:thread];
}



- (NSArray *)threadsMatchingFilter:(WCBoardThreadFilter *)filter includeChildBoards:(BOOL)includeChildBoards {
	NSMutableArray		*threads;
	WCBoard				*board;
	WCBoardThread		*thread;
	NSUInteger			i, count;
	
	threads		= [NSMutableArray array];
	count		= [_threadsArray count];
	
	for(i = 0; i < count; i++) {
		thread = [_threadsArray objectAtIndex:i];
		
		if([thread hasPostMatchingFilter:filter])
			[threads addObject:thread];
	}
	
	if(includeChildBoards) {
		count = [_boards count];
		
		for(i = 0; i < count; i++) {
			board = [_boards objectAtIndex:i];
			
			if(![board isKindOfClass:[WCSmartBoard class]])
				[threads addObjectsFromArray:[board threadsMatchingFilter:filter includeChildBoards:includeChildBoards]];
		}
	}
	
	return threads;
}



- (WCBoardThread *)previousUnreadThreadStartingAtBoard:(WCBoard *)board thread:(WCBoardThread *)thread forwardsInThreads:(BOOL)forwardsInThreads {
	BOOL	passed = NO;
	
	return [self _unreadThreadStartingAtBoard:board thread:thread forwardsInBoards:NO forwardsInThreads:!forwardsInThreads passed:&passed];
}



- (WCBoardThread *)nextUnreadThreadStartingAtBoard:(WCBoard *)board thread:(WCBoardThread *)thread forwardsInThreads:(BOOL)forwardsInThreads {
	BOOL	passed = NO;
	
	return [self _unreadThreadStartingAtBoard:board thread:thread forwardsInBoards:YES forwardsInThreads:forwardsInThreads passed:&passed];
}



- (void)addThread:(WCBoardThread *)thread sortedUsingSelector:(SEL)selector {
	[_threadsArray addObject:thread sortedUsingSelector:selector];
	[_threadsDictionary setObject:thread forKey:[thread threadID]];
}



- (void)addThreads:(NSArray *)threads {
	NSEnumerator		*enumerator;
	WCBoardThread		*thread;
	
	enumerator = [threads objectEnumerator];
	
	while((thread = [enumerator nextObject])) {
		if(![_threadsDictionary objectForKey:[thread threadID]]) {
			[_threadsArray addObject:thread];
			[_threadsDictionary setObject:thread forKey:[thread threadID]];
		}
	}
}



- (void)removeThread:(WCBoardThread *)thread {
	[_threadsArray removeObject:thread];
	[_threadsDictionary removeObjectForKey:[thread threadID]];
}



- (void)removeAllThreads {
	[_threadsArray removeAllObjects];
	[_threadsDictionary removeAllObjects];
}



- (void)sortThreadsUsingSelector:(SEL)selector {
	[_threadsArray sortUsingSelector:selector];
}



#pragma mark -

- (void)invalidateForConnection:(WCServerConnection *)connection {
	WCBoard			*board;
	WCBoardThread	*thread;
	NSUInteger		i, count;
	
	count = [_threadsArray count];
	
	for(i = 0; i < count; i++) {
		thread = [_threadsArray objectAtIndex:i];
		
		if([thread connection] == connection) {
			[thread setConnection:NULL];
			[[thread posts] makeObjectsPerformSelector:@selector(setConnection:) withObject:NULL];
		}
	}
	
	count = [_boards count];
	
	for(i = 0; i < count; i++) {
		board = [_boards objectAtIndex:i];
		
		if([board connection] == connection)
			[board setConnection:NULL];
		
		[board invalidateForConnection:connection];
	}
}



- (void)revalidateForConnection:(WCServerConnection *)connection {
	WCBoard			*board;
	WCBoardThread	*thread;
	NSUInteger		i, count;
	
	count = [_threadsArray count];
	
	for(i = 0; i < count; i++) {
		thread = [_threadsArray objectAtIndex:i];
		
		if([thread belongsToConnection:connection]) {
			[thread setConnection:connection];
			[[thread posts] makeObjectsPerformSelector:@selector(setConnection:) withObject:connection];
		}
	}
	
	count = [_boards count];
	
	for(i = 0; i < count; i++) {
		board = [_boards objectAtIndex:i];
		
		if([board belongsToConnection:connection])
			[board setConnection:connection];
		
		[board revalidateForConnection:connection];
	}
}



#pragma mark -

- (NSComparisonResult)compareBoard:(WCBoard *)board {
	if([self sorting] > [board sorting])
		return NSOrderedAscending;
	else if([self sorting] < [board sorting])
		return NSOrderedDescending;
	
	return [[self name] compare:[board name] options:NSCaseInsensitiveSearch];
}

@end



@implementation WCSmartBoard

+ (id)smartBoard {
	return [[[self alloc] _initWithPath:@"/SmartBoard" name:@"<root>" connection:NULL] autorelease];
}



#pragma mark -

- (void)setFilter:(WCBoardThreadFilter *)filter {
	[filter retain];
	[_filter release];
	
	_filter = filter;
}



- (WCBoardThreadFilter *)filter {
	return _filter;
}

@end



@implementation WCSearchBoard

+ (id)searchBoard {
	return [[[self alloc] _initWithPath:@"/SearchBoard" name:@"<root>" connection:NULL] autorelease];
}

@end
