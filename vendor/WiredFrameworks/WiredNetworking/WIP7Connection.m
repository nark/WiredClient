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

#import "WIP7Connection.h"

WIP7Spec							*WCP7Spec;


@implementation WIP7Connection

+ (NSString *)versionStringForMessage:(WIP7Message *)message {
        
	NSString		*applicationName, *applicationVersion, *osName, *osVersion, *arch, *applicationBuild;
	
	applicationName		= [message stringForName:@"wired.info.application.name"];
	applicationVersion	= [message stringForName:@"wired.info.application.version"];
	osName				= [message stringForName:@"wired.info.os.name"];
	osVersion			= [message stringForName:@"wired.info.os.version"];
	arch				= [message stringForName:@"wired.info.arch"];
	applicationBuild    = [message stringForName:@"wired.info.application.build"];
    	
	return [NSSWF:
		NSLS(@"%@ %@ (%@) on %@ %@ (%@)", @"Wired version (application name, application version, application build, os name, os version, architecture)"),
		applicationName, applicationVersion, applicationBuild,
		osName, osVersion, arch];
}



#pragma mark -

+ (id)connection {
	return [[[self alloc] init] autorelease];
}



#pragma mark -

- (id)init {
	self = [super init];
	
	_uuid = [[NSString UUIDString] retain];
	
	return self;
}



- (void)dealloc {
	[_bookmark release];
	[_url release];
	[_uuid release];
	
	[super dealloc];
}



#pragma mark -

- (void)disconnect {
	[self doesNotRecognizeSelector:_cmd];
}



#pragma mark -

- (WIP7Message *)clientInfoMessage {

	return nil;
}



- (WIP7Message *)setNickMessage {
	
	return nil;
}



- (WIP7Message *)setStatusMessage {

	return nil;
}



- (WIP7Message *)setIconMessage {

	return nil;
}



- (WIP7Message *)loginMessage {

	return nil;
}



#pragma mark -

- (void)setURL:(WIURL *)url {
	[url retain];
	[_url release];
	
	_url = url;
}



- (WIURL *)URL {
	return _url;
}



- (void)setBookmark:(NSDictionary *)bookmark {
	[bookmark retain];
	[_bookmark release];
	
	_bookmark = bookmark;
}



- (NSDictionary *)bookmark {
	return _bookmark;
}



- (WIP7Socket *)socket {
	[self doesNotRecognizeSelector:_cmd];
	
	return NULL;
}



- (NSString *)identifier {
	NSString	*identifier;
	
	identifier = [self bookmarkIdentifier];
	
	if(identifier)
		return identifier;
	
	return [self URLIdentifier];
}



- (NSString *)URLIdentifier {
	return [[[self URL] hostpair] stringByAppendingString:[[self URL] user]];
}



- (NSString *)bookmarkIdentifier {
	return nil;
}



- (NSString *)uniqueIdentifier {
	return _uuid;
}

@end
