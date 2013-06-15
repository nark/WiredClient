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

#import "WCServerConnection.h"
#import "WCStats.h"

#define WCStatsPath								@"~/Library/Application Support/Wired Client/Stats.plist"


NSString * const WCStatsDownloaded				= @"Downloaded";
NSString * const WCStatsUploaded				= @"Uploaded";
NSString * const WCStatsChat					= @"Chat";
NSString * const WCStatsOnline					= @"Online";
NSString * const WCStatsMessagesSent			= @"Messages Sent";
NSString * const WCStatsMessagesReceived		= @"Messages Received";


static OSStatus _WCStatsEventSystemTimeDateChanged(EventHandlerCallRef, EventRef, void *);


@interface WCStats(Private)

- (id)_objectForKey:(id)key;
- (void)_setObject:(id)object forKey:(id)key;

- (void)_startCountingTime;
- (void)_stopCountingTime;
- (void)_resetTime;

- (void)_saveStats;

@end



static OSStatus _WCStatsEventSystemTimeDateChanged(EventHandlerCallRef nextHandler, EventRef event, void *userData) {
	[(id) userData _resetTime];

	return noErr;
}



@implementation WCStats(Private)

- (id)_objectForKey:(id)key {
	id			object;
	double		seconds;

	[_lock lock];
	
	if([key isEqualToString:WCStatsOnline] && _date) {
		seconds = [[_stats objectForKey:WCStatsOnline] doubleValue];
		object = [NSNumber numberWithDouble:seconds + [[NSDate date] timeIntervalSinceDate:_date]];
	} else {
		object = [_stats objectForKey:key];
	}

	[_lock unlock];

	return object;
}



- (void)_setObject:(id)object forKey:(id)key {
	[_lock lock];
	[_stats setObject:object forKey:key];
	[_lock unlock];
}



#pragma mark -

- (void)_startCountingTime {
	[_lock lock];

	if(!_date)
		_date = [[NSDate date] retain];

	[_lock unlock];
}



- (void)_stopCountingTime {
	[_lock lock];

	if(_date) {
		[_stats setObject:[self _objectForKey:WCStatsOnline] forKey:WCStatsOnline];

		[_date release];
		_date = NULL;
	}

	[_lock unlock];
}



- (void)_resetTime {
	[_date release];
	_date = [[NSDate date] retain];
}



#pragma mark -

- (void)_saveStats {
	[_lock lock];

	if(_date) {
		[_stats setObject:[self _objectForKey:WCStatsOnline] forKey:WCStatsOnline];

		[_date release];
		_date = [[NSDate date] retain];
	}

	[_stats writeToFile:[WCStatsPath stringByStandardizingPath] atomically:YES];
	[_lock unlock];
}

@end


@implementation WCStats

+ (WCStats *)stats {
	static id	sharedStats;

	if(!sharedStats)
		sharedStats = [[self alloc] init];

	return sharedStats;
}



- (id)init {
	EventHandlerUPP		eventHandlerUPP;
	EventTypeSpec		eventTypeSpec;
	
	self = [super init];

	_lock = [[NSRecursiveLock alloc] init];

	_stats = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
		[NSNumber numberWithInt:0],		WCStatsDownloaded,
		[NSNumber numberWithInt:0],		WCStatsUploaded,
		[NSNumber numberWithInt:0],		WCStatsChat,
		[NSNumber numberWithInt:0],		WCStatsOnline,
		[NSNumber numberWithInt:0],		WCStatsMessagesSent,
		[NSNumber numberWithInt:0],		WCStatsMessagesReceived,
		NULL];
	
	[_stats addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:[WCStatsPath stringByStandardizingPath]]];

	if([[_stats objectForKey:WCStatsOnline] doubleValue] > 864000000.0)
		[_stats setObject:[NSNumber numberWithInt:0] forKey:WCStatsOnline];
	
	_sizeFormatter = [[WISizeFormatter alloc] init];
	
	_timeIntervalFormatter = [[WITimeIntervalFormatter alloc] init];
	
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		   selector:@selector(applicationWillTerminate:)
			   name:NSApplicationWillTerminateNotification];

	[[NSNotificationCenter defaultCenter]
		addObserver:self
		   selector:@selector(linkConnectionDidClose:)
			   name:WCLinkConnectionDidCloseNotification];
	
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		   selector:@selector(linkConnectionDidTerminate:)
			   name:WCLinkConnectionDidTerminateNotification];

	[[NSNotificationCenter defaultCenter]
		addObserver:self
		   selector:@selector(linkConnectionLoggedIn:)
			   name:WCLinkConnectionLoggedInNotification];

	eventHandlerUPP				= NewEventHandlerUPP(_WCStatsEventSystemTimeDateChanged);
	eventTypeSpec.eventClass	= kEventClassSystem;
	eventTypeSpec.eventKind		= kEventSystemTimeDateChanged;
	
	InstallApplicationEventHandler(eventHandlerUPP, 1, &eventTypeSpec, self, &_eventHandlerRef);
	
	[NSTimer scheduledTimerWithTimeInterval:300.0
									 target:self
								   selector:@selector(saveTimer:)
								   userInfo:NULL
									repeats:YES];

	return self;
}



- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[_lock release];
	[_stats release];
	[_date release];
	
	[_sizeFormatter release];
	[_timeIntervalFormatter release];
	
	RemoveEventHandler(_eventHandlerRef);
	
	[super dealloc];
}



#pragma mark -

- (void)applicationWillTerminate:(NSNotification *)notification {
	[self _saveStats];
}



- (void)linkConnectionDidClose:(NSNotification *)notification {
	if(![[notification object] isKindOfClass:[WCServerConnection class]])
		return;
	
	if(_connections == 1)
		[self _stopCountingTime];
	
	_connections--;
}



- (void)linkConnectionDidTerminate:(NSNotification *)notification {
	if(![[notification object] isKindOfClass:[WCServerConnection class]])
		return;
	
	if([[notification object] isConnected]) {
		if(_connections == 1)
			[self _stopCountingTime];
		
		_connections--;
	}
}



- (void)linkConnectionLoggedIn:(NSNotification *)notification {
	if(![[notification object] isKindOfClass:[WCServerConnection class]])
		return;
	
	if(_connections == 0)
		[self _startCountingTime];
	
	_connections++;
}



#pragma mark -

- (void)saveTimer:(NSTimer *)timer {
	[self _saveStats];
}



#pragma mark -

- (unsigned int)unsignedIntForKey:(id)key {
	return [[self _objectForKey:key] unsignedIntValue];
}



- (unsigned long long)unsignedLongLongForKey:(id)key {
	return [[self _objectForKey:key] unsignedLongLongValue];
}



- (void)setUnsignedInt:(unsigned int)number forKey:(id)key {
	[self _setObject:[NSNumber numberWithUnsignedInt:number] forKey:key];
}



- (void)setUnsignedLongLong:(unsigned long long)number forKey:(id)key {
	[self _setObject:[NSNumber numberWithUnsignedLongLong:number] forKey:key];
}



- (void)addUnsignedInt:(unsigned int)number forKey:(id)key {
	unsigned int	value;
	
	value = number + [self unsignedIntForKey:key];
	[self _setObject:[NSNumber numberWithUnsignedInt:value] forKey:key];
}



- (void)addUnsignedLongLong:(unsigned long long)number forKey:(id)key {
	unsigned long long	value;
	
	value = number + [self unsignedLongLongForKey:key];
	[self _setObject:[NSNumber numberWithUnsignedLongLong:value] forKey:key];
}



#pragma mark -

- (NSString *)stringValue {
	NSString		*string;

	[_lock lock];
	
	string = [NSSWF:NSLS(@"%@ downloaded, %@ uploaded, %@ chat, %@ online, %lu %@ received, %lu %@ sent", @"Stats message"),
		[_sizeFormatter stringFromNumber:[self _objectForKey:WCStatsDownloaded]],
		[_sizeFormatter stringFromNumber:[self _objectForKey:WCStatsUploaded]],
		[_sizeFormatter stringFromNumber:[self _objectForKey:WCStatsChat]],
		[_timeIntervalFormatter stringFromNumber:[self _objectForKey:WCStatsOnline]],
		[[self _objectForKey:WCStatsMessagesReceived] unsignedIntegerValue],
		[[self _objectForKey:WCStatsMessagesReceived] unsignedIntegerValue] == 1
			? NSLS(@"message", @"Message singular")
			: NSLS(@"messages", @"Message plural"),
		[[self _objectForKey:WCStatsMessagesSent] unsignedIntegerValue],
		[[self _objectForKey:WCStatsMessagesSent] unsignedIntegerValue] == 1
			? NSLS(@"message", @"Message singular")
			: NSLS(@"messages", @"Message plural")];

	[_lock unlock];

	return string;
}

@end
