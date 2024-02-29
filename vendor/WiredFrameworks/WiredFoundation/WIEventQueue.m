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

#import <WiredFoundation/WIEventQueue.h>

NSString * const WIEventFileDeleteNotification				= @"WIEventFileDeleteNotification";
NSString * const WIEventFileWriteNotification				= @"WIEventFileWriteNotification";
NSString * const WIEventFileExtendNotification				= @"WIEventFileExtendNotification";
NSString * const WIEventFileAttributeChangeNotification		= @"WIEventFileAttributeChangeNotification";
NSString * const WIEventFileLinkCountChangeNotification		= @"WIEventFileLinkCountChangeNotification";
NSString * const WIEventFileRenameNotification				= @"WIEventFileRenameNotification";
NSString * const WIEventFileRevokeNotification				= @"WIEventFileRevokeNotification";



@interface WIEventFile : WIObject {
	NSString				*_path;
	int						_fd;
}


- (id)initWithPath:(NSString *)path fileDescriptor:(int)fd;
- (NSString *)path;
- (int)fileDescriptor;

@end


@implementation WIEventFile

- (id)initWithPath:(NSString *)path fileDescriptor:(int)fd {
	self = [super init];
	
	_path = [path retain];
	_fd = fd;
	
	return self;
}



- (void)dealloc {
	[_path release];
	
	[super dealloc];
}



#pragma mark -

- (NSString *)path {
	return _path;
}



- (int)fileDescriptor {
	return _fd;
}

@end



@interface WIEventQueue(Private)

- (void)_processQueue;

@end


@implementation WIEventQueue(Private)

- (void)_processQueue {
	NSString				*path;
	struct timespec			ts = { 0, 0 };
	struct kevent			ev;
	
	while(kevent(_fd, NULL, 0, &ev, 1, &ts) > 0) {
		if(ev.filter == EVFILT_VNODE) {
			path = [(NSString *) ev.udata retain];
			
			if(ev.fflags & NOTE_DELETE)
				[_center postNotificationName:WIEventFileDeleteNotification object:path];
			
			if(ev.fflags & NOTE_WRITE)
				[_center postNotificationName:WIEventFileWriteNotification object:path];
			
			if(ev.fflags & NOTE_EXTEND)
				[_center postNotificationName:WIEventFileExtendNotification object:path];
			
			if(ev.fflags & NOTE_ATTRIB)
				[_center postNotificationName:WIEventFileAttributeChangeNotification object:path];
			
			if(ev.fflags & NOTE_LINK)
				[_center postNotificationName:WIEventFileLinkCountChangeNotification object:path];
			
			if(ev.fflags & NOTE_RENAME)
				[_center postNotificationName:WIEventFileRenameNotification object:path];
			
			if(ev.fflags & NOTE_REVOKE)
				[_center postNotificationName:WIEventFileRevokeNotification object:path];
			
			[path release];
		}
	}
}

@end



@implementation WIEventQueue

+ (WIEventQueue *)sharedQueue {
	static WIEventQueue		*sharedQueue;

	if(!sharedQueue)
		sharedQueue = [[self alloc] init];

	return sharedQueue;
}



- (id)init {
	self = [super init];
	
	_fd = kqueue();
	
	if(_fd < 0) {
		[self release];
		
		return NULL;
	}
	
	_fileHandle = [[NSFileHandle alloc] initWithFileDescriptor:_fd];
	[_fileHandle waitForDataInBackgroundAndNotify];
	
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		   selector:@selector(fileHandleDataAvailable:)
			   name:NSFileHandleDataAvailableNotification
			 object:_fileHandle];
	
	_center = [[NSNotificationCenter alloc] init];
	_files = [[NSMutableDictionary alloc] init];
	
	return self;
}



- (void)dealloc {
	[self removeAllPaths];
	
	[_center release];
	[_fileHandle release];
	
	if(close(_fd) < 0)
		NSLog(@"*** %@: close(): %s", [self class], strerror(errno));
	
	[_files release];
	
	[super dealloc];
}



#pragma mark -

- (void)fileHandleDataAvailable:(NSNotification *)notification {
	[self _processQueue];
	
	[_fileHandle waitForDataInBackgroundAndNotify];
}



#pragma mark -

- (NSNotificationCenter *)notificationCenter {
	return _center;
}



#pragma mark -

- (void)addPath:(NSString *)path {
	[self addPath:path forMode:WIEventFileDelete |
							   WIEventFileWrite |
							   WIEventFileRename |
							   WIEventFileAttributeChange];
}



- (void)addPath:(NSString *)path forMode:(WIEventMode)mode {
	WIEventFile		*file;
	struct kevent	ev;
	int				fd;
	
	fd = open([path fileSystemRepresentation], O_EVTONLY, 0);
	
	if(fd < 0) {
		NSLog(@"*** %@: open(): %s", [self class], strerror(errno));
		
		return;
	}
	
	file = [[WIEventFile alloc] initWithPath:path fileDescriptor:fd];
	
	EV_SET(&ev, fd, EVFILT_VNODE, EV_ADD | EV_ENABLE | EV_CLEAR, mode, 0, path);
	
	if(kevent(_fd, &ev, 1, NULL, 0, NULL) < 0) {
		[file release];
		
		return;
	}
	
	[_files setObject:file forKey:path];
	[file release];
}



- (void)removePath:(NSString *)path {
	WIEventFile		*file;
	
	file = [_files objectForKey:path];
	
	if(!file)
		return;
	
	if(close([file fileDescriptor]) < 0)
		NSLog(@"*** %@: close(): %s", [self class], strerror(errno));
	
	[_files removeObjectForKey:path];
}



- (void)removeAllPaths {
	NSEnumerator	*enumerator;
	WIEventFile		*file;
	
	enumerator = [_files objectEnumerator];
	
	while((file = [enumerator nextObject])) {
		if(close([file fileDescriptor]) < 0)
			NSLog(@"*** %@: close(): %s", [self class], strerror(errno));
	}
	
	[_files removeAllObjects];
}

@end
