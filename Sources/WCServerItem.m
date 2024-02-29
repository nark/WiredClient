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

#import "WCKeychain.h"
#import "WCServerItem.h"

@implementation WCServerItem

+ (id)itemWithName:(NSString *)name {
	return [[[self alloc] initWithName:name] autorelease];
}



- (id)initWithName:(NSString *)name {
	self = [self init];
	
	_name = [name retain];
	
	return self;
}



- (void)dealloc {
	[_name release];
	
	[super dealloc];
}



#pragma mark -

- (NSString *)name {
	return _name;
}



- (NSImage *)icon {
	return NULL;
}



#pragma mark -

- (NSComparisonResult)compareName:(id)item {
	if([self isKindOfClass:[WCServerTrackerServer class]] && ![item isKindOfClass:[WCServerTrackerServer class]])
		return NSOrderedDescending;
	else if([self isKindOfClass:[WCServerTrackerCategory class]] && ![item isKindOfClass:[WCServerTrackerCategory class]])
		return NSOrderedAscending;
	
	return [[self name] compare:[item name] options:NSCaseInsensitiveSearch];
}



- (NSComparisonResult)compareUsers:(id)item {
	return [self compareName:item];
}



- (NSComparisonResult)compareFilesCount:(id)item {
	return [self compareName:item];
}



- (NSComparisonResult)compareFilesSize:(id)item {
	return [self compareName:item];
}



- (NSComparisonResult)compareServerDescription:(id)item {
	return [self compareName:item];
}

@end



@interface WCServerContainer(Private)

- (id)_itemWithClass:(Class)class name:(NSString *)name;

@end


@implementation WCServerContainer(Private)

- (id)_itemWithClass:(Class)class name:(NSString *)name {
	NSEnumerator	*enumerator;
	id				item;
	
	enumerator = [[self items] objectEnumerator];
	
	while((item = [enumerator nextObject])) {
		if([item class] == class && [[item name] isEqualToString:name])
			return item;
	}
	
	return NULL;
}

@end



@implementation WCServerContainer

- (id)initWithName:(NSString *)name {
    self = [super initWithName:name];
    
    _items = [[NSMutableArray alloc] init];
    
    return self;
}



- (void)dealloc {
	[_items release];
	
	[super dealloc];
}



#pragma mark -

- (NSUInteger)numberOfItems {
    return [_items count];
}



- (NSUInteger)numberOfServerItems {
	return _serverCount;
}



- (NSArray *)items {
    return _items;
}



- (void)sortUsingSelector:(SEL)selector {
    [_items sortUsingSelector:selector];

    [self sortItemsUsingSelector:selector];
}



- (void)sortItemsUsingSelector:(SEL)selector {
	NSEnumerator	*enumerator;
    id				item;

	enumerator = [_items objectEnumerator];
	
	while((item = [enumerator nextObject])) {
        if([item respondsToSelector:@selector(sortUsingSelector:)])
            [item sortUsingSelector:selector];
    }
}



- (void)addItem:(id)item {
	if([item isKindOfClass:[WCServerBonjourServer class]] ||
	   [item isKindOfClass:[WCServerTrackerServer class]] ||
	   [item isKindOfClass:[WCServerBookmarkServer class]]) {
		_serverCount++;
	}
	
	[_items addObject:item];
}



- (void)removeItem:(id)item {
	if([item isKindOfClass:[WCServerBonjourServer class]] ||
	   [item isKindOfClass:[WCServerTrackerServer class]] ||
	   [item isKindOfClass:[WCServerBookmarkServer class]]) {
		_serverCount--;
	}
	
	[_items removeObject:item];
}



- (void)removeAllItems {
	_serverCount = 0;
	
	[_items removeAllObjects];
}



#pragma mark -

- (BOOL)isExpandable {
	return YES;
}

@end



@implementation WCServerBonjour

+ (id)bonjourItem {
	return [self itemWithName:NSLS(@"BONJOUR", @"Bonjour server")];
}



#pragma mark -

- (NSImage *)icon {
	return [NSImage imageNamed:@"Bonjour"];
}

@end



@interface WCServerBonjourServer(Private)

- (id)_initWithNetService:(NSNetService *)netService;

@end


@implementation WCServerBonjourServer(Private)

- (id)_initWithNetService:(NSNetService *)netService {
	self = [self initWithName:[netService name]];
	
	_netService = [netService retain];
	
	return self;
}

@end



@implementation WCServerBonjourServer

+ (id)itemWithNetService:(NSNetService *)netService {
	return [[[self alloc] _initWithNetService:netService] autorelease];
}



- (void)dealloc {
	[_netService release];
	
	[super dealloc];
}



#pragma mark -

- (NSNetService *)netService {
	return _netService;
}



- (WIURL *)URL {
	return [self URLWithError:NULL];
}



- (WIURL *)URLWithError:(WCError **)error {
	WIAddress		*address;
	
	address = [WIAddress addressWithNetService:[self netService] error:error];
	
	if(!address)
		return NULL;
			
	return [WIURL URLWithScheme:@"wiredp7" host:[address string] port:[address port]];
}

@end



@implementation WCServerBookmarks

+ (id)bookmarksItem {
	return [self itemWithName:NSLS(@"BOOKMARKS", @"Bookmarks server")];
}



#pragma mark -

- (NSImage *)icon {
	return [NSImage imageNamed:@"BookmarksSmall"];
}

@end



@interface WCServerBookmarkServer(Private)

- (id)_initWithBookmark:(NSDictionary *)bookmark;

@end


@implementation WCServerBookmarkServer(Private)

- (id)_initWithBookmark:(NSDictionary *)bookmark {
	self = [self initWithName:[bookmark objectForKey:WCBookmarksName]];
	
	_bookmark = [bookmark retain];
	
	_url = [[WIURL URLWithString:[bookmark objectForKey:WCBookmarksAddress] scheme:@"wiredp7"] retain];
	[_url setUser:[bookmark objectForKey:WCBookmarksLogin]];
	//[_url setPassword:[[WCKeychain keychain] passwordForBookmark:bookmark]];
	
	return self;
}

@end



@implementation WCServerBookmarkServer

+ (id)itemWithBookmark:(NSDictionary *)bookmark {
	return [[[self alloc] _initWithBookmark:bookmark] autorelease];
}



- (void)dealloc {
	[_bookmark release];
	[_url release];
	
	[super dealloc];
}



#pragma mark -

- (NSDictionary *)bookmark {
	return _bookmark;
}



- (WIURL *)URL {
	return _url;
}

@end



@interface WCServerTracker(Private)

- (id)_initWithBookmark:(NSDictionary *)bookmark;

@end


@implementation WCServerTracker(Private)

- (id)_initWithBookmark:(NSDictionary *)bookmark {
	self = [self initWithName:[bookmark objectForKey:WCTrackerBookmarksName]];
	
	_bookmark = [bookmark retain];
	
	_url = [[WIURL URLWithString:[bookmark objectForKey:WCTrackerBookmarksAddress] scheme:@"wiredp7"] retain];
	[_url setUser:[bookmark objectForKey:WCTrackerBookmarksLogin]];
	[_url setPassword:[[WCKeychain keychain] passwordForTrackerBookmark:bookmark]];
	
	return self;
}

@end



@implementation WCServerTracker

+ (id)itemWithBookmark:(NSDictionary *)bookmark {
	return [[[self alloc] _initWithBookmark:bookmark] autorelease];
}



- (void)dealloc {
	[_bookmark release];
	[_url release];
	
	[super dealloc];
}



#pragma mark -

- (WCServerTrackerCategory *)categoryForPath:(NSString *)path {
	NSEnumerator	*enumerator;
	NSArray			*components;
	NSString		*component;
	id				item, child;
	
	components		= [path pathComponents];
	item			= self;
	enumerator		= [components objectEnumerator];
	
	while((component = [enumerator nextObject])) {
		child = [item _itemWithClass:[WCServerTrackerCategory class] name:component];
		
		if(!child)
			return NULL;
		
		item = child;
	}
	
	if([item isKindOfClass:[WCServerTrackerCategory class]])
		return item;
	
	return NULL;
}



#pragma mark -

- (NSImage *)icon {
	NSImage		*image;
	
	image = [NSImage imageNamed:@"WiredServer"];
	
	[image setSize:NSMakeSize(16.0, 16.0)];
	
	return image;
}



- (NSDictionary *)bookmark {
	return _bookmark;
}



- (WIURL *)URL {
	return _url;
}



- (void)setState:(WCServerTrackerState)state {
	_state = state;
}



- (WCServerTrackerState)state {
	return _state;
}

@end



@implementation WCServerTrackerCategory

@end



@interface WCServerTrackerServer(Private)

- (id)_initWithMessage:(WIP7Message *)message;

@end


@implementation WCServerTrackerServer(Private)

- (id)_initWithMessage:(WIP7Message *)message {
	WIP7UInt64		filesCount, filesSize;
	WIP7UInt32		users;
	WIP7Bool		tracker;
	
	self = [self initWithName:[message stringForName:@"wired.info.name"]];
	
	[message getBool:&tracker forName:@"wired.tracker.tracker"];
	[message getUInt32:&users forName:@"wired.tracker.users"];
	[message getUInt64:&filesCount forName:@"wired.info.files.count"];
	[message getUInt64:&filesSize forName:@"wired.info.files.size"];
	
	_tracker			= tracker;
	_categoryPath		= [[message stringForName:@"wired.tracker.category"] retain];
	_url				= [[WIURL URLWithString:[message stringForName:@"wired.tracker.url"] scheme:@"wiredp7"] retain];
	_serverDescription	= [[message stringForName:@"wired.info.description"] retain];
	_users				= users;
	_filesCount			= filesCount;
	_filesSize			= filesSize;
	
	return self;
}

@end



@implementation WCServerTrackerServer

+ (id)itemWithMessage:(WIP7Message *)message {
	return [[[self alloc] _initWithMessage:message] autorelease];
}



- (void)dealloc {
	[_serverDescription release];
	
	[super dealloc];
}



#pragma mark -

- (NSImage *)icon {
	return NULL;
}



- (BOOL)isExpandable {
	return [self isTracker];
}



- (BOOL)isTracker {
	return _tracker;
}



- (NSString *)categoryPath {
	return _categoryPath;
}



- (NSString *)serverDescription {
	return _serverDescription;
}



- (NSUInteger)users {
	return _users;
}



- (NSUInteger)filesCount {
	return _filesCount;
}



- (WIFileOffset)filesSize {
	return _filesSize;
}



#pragma mark -

- (NSComparisonResult)compareUsers:(id)item {
	if([item isKindOfClass:[self class]]) {
		if([self users] > [item users])
			return NSOrderedDescending;
		else if([self users] < [item users])
			return NSOrderedAscending;
	}
		
	return [self compareName:item];
}



- (NSComparisonResult)compareFilesCount:(id)item {
	if([item isKindOfClass:[self class]]) {
		if([self filesCount] > [item filesCount])
			return NSOrderedDescending;
		else if([self filesCount] < [item filesCount])
			return NSOrderedAscending;
	}
	
	return [self compareName:item];
}



- (NSComparisonResult)compareFilesSize:(id)item {
	if([item isKindOfClass:[self class]]) {
		if([self filesSize] > [item filesSize])
			return NSOrderedDescending;
		else if([self filesSize] < [item filesSize])
			return NSOrderedAscending;
	}
	
	return [self compareName:item];
}



- (NSComparisonResult)compareServerDescription:(id)item {
	return [[self serverDescription] compare:[item serverDescription] options:NSCaseInsensitiveSearch];
}

@end
