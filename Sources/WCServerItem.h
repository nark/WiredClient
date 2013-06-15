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

@interface WCServerItem : WIObject {
	NSString						*_name;
}

+ (id)itemWithName:(NSString *)name;
- (id)initWithName:(NSString *)name;

- (NSString *)name;
- (NSImage *)icon;

- (NSComparisonResult)compareName:(id)item;
- (NSComparisonResult)compareUsers:(id)item;
- (NSComparisonResult)compareFilesCount:(id)item;
- (NSComparisonResult)compareFilesSize:(id)item;
- (NSComparisonResult)compareServerDescription:(id)item;

@end


@interface WCServerContainer : WCServerItem {
    NSMutableArray					*_items;
	NSUInteger						_serverCount;
}

- (NSUInteger)numberOfItems;
- (NSUInteger)numberOfServerItems;
- (NSArray *)items;
- (void)sortUsingSelector:(SEL)selector;
- (void)sortItemsUsingSelector:(SEL)selector;

- (void)addItem:(id)item;
- (void)removeItem:(id)item;
- (void)removeAllItems;

- (BOOL)isExpandable;

@end


@interface WCServerBonjour : WCServerContainer

+ (id)bonjourItem;

@end


@interface WCServerBonjourServer : WCServerItem {
	NSNetService					*_netService;
}

+ (id)itemWithNetService:(NSNetService *)netService;

- (NSNetService *)netService;
- (WIURL *)URLWithError:(WCError **)error;

@end


@interface WCServerBookmarks : WCServerContainer

+ (id)bookmarksItem;

@end


@interface WCServerBookmarkServer : WCServerItem {
	NSDictionary					*_bookmark;
	WIURL							*_url;
}

+ (id)itemWithBookmark:(NSDictionary *)bookmark;

- (NSDictionary *)bookmark;
- (WIURL *)URL;

@end


enum _WCServerTrackerState {
	WCServerTrackerIdle,
	WCServerTrackerLoading,
	WCServerTrackerLoaded
};
typedef enum _WCServerTrackerState	WCServerTrackerState;

@class WCServerTrackerCategory;

@interface WCServerTracker : WCServerContainer {
	NSDictionary					*_bookmark;
	WIURL							*_url;
	WCServerTrackerState			_state;
}

+ (id)itemWithBookmark:(NSDictionary *)bookmark;

- (WCServerTrackerCategory *)categoryForPath:(NSString *)path;

- (NSDictionary *)bookmark;
- (WIURL *)URL;
- (void)setState:(WCServerTrackerState)state;
- (WCServerTrackerState)state;

@end


@interface WCServerTrackerCategory : WCServerContainer

@end


@interface WCServerTrackerServer : WCServerTracker {
	BOOL							_tracker;
	NSString						*_categoryPath;
	NSString						*_serverDescription;
	NSUInteger						_users;
	NSUInteger						_filesCount;
	WIFileOffset					_filesSize;
}

+ (id)itemWithMessage:(WIP7Message *)message;

- (BOOL)isTracker;
- (NSString *)categoryPath;
- (NSString *)serverDescription;
- (NSUInteger)users;
- (NSUInteger)filesCount;
- (WIFileOffset)filesSize;

@end
