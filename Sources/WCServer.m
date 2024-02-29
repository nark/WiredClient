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

#import "WCAccount.h"
#import "WCServer.h"
#import "WCServerConnection.h"

@implementation WCServer

- (void)dealloc {
	[_name release];
	[_serverDescription release];
	[_serverVersion release];
	[_startupDate release];
	[_banner release];
	
	[_userAccount release];

	[super dealloc];
}



#pragma mark -

- (void)setWithMessage:(WIP7Message *)message {
	WIP7UInt64		files, size;
	WIP7UInt32		downloads, uploads, downloadSpeed, uploadSpeed;
	WIP7Bool		supportsResourceForks;
	
	[_name release];
	[_serverDescription release];
	[_serverVersion release];
	[_startupDate release];
	[_banner release];
	
	[message getBool:&supportsResourceForks forName:@"wired.info.supports_rsrc"];
	[message getUInt64:&files forName:@"wired.info.files.count"];
	[message getUInt64:&size forName:@"wired.info.files.size"];
	[message getUInt32:&downloads forName:@"wired.info.downloads"];
	[message getUInt32:&uploads forName:@"wired.info.uploads"];
	[message getUInt32:&downloadSpeed forName:@"wired.info.download_speed"];
	[message getUInt32:&uploadSpeed forName:@"wired.info.upload_speed"];
	
	_name					= [[message stringForName:@"wired.info.name"] retain];
	_serverDescription		= [[message stringForName:@"wired.info.description"] retain];
	_serverVersion			= [[WCServerConnection versionStringForMessage:message] retain];
	_startupDate			= [[message dateForName:@"wired.info.start_time"] retain];
	_banner					= [[NSImage alloc] initWithData:[message dataForName:@"wired.info.banner"]];
	_files					= files;
	_size					= size;
	_downloads				= downloads;
	_uploads				= uploads;
	_downloadSpeed			= downloadSpeed;
	_uploadSpeed			= uploadSpeed;
	_supportsResourceForks	= supportsResourceForks;
}



#pragma mark -

- (NSString *)name {
	return _name;
}



- (NSString *)serverDescription {
	return _serverDescription;
}



- (NSString *)serverVersion {
	return _serverVersion;
}



- (NSDate *)startupDate {
	return _startupDate;
}



- (NSImage *)banner {
	return _banner;
}



- (NSUInteger)files {
	return _files;
}



- (WIFileOffset)size {
	return _size;
}



- (NSUInteger)downloads {
	return _downloads;
}



- (NSUInteger)uploads {
	return _uploads;
}



- (NSUInteger)downloadSpeed {
	return _downloadSpeed;
}



- (NSUInteger)uploadSpeed {
	return _uploadSpeed;
}



#pragma mark -

- (void)setAccount:(WCUserAccount *)account {
	[account retain];
	[_userAccount release];

	_userAccount = account;
}



- (WCUserAccount *)account {
	return _userAccount;
}



#pragma mark -

- (BOOL)supportsResourceForks {
	return _supportsResourceForks;
}

@end
