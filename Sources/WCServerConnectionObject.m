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

#import "WCServerConnection.h"
#import "WCServerConnectionObject.h"

@implementation WCServerConnectionObject

+ (NSInteger)version {
	return 1;
}



#pragma mark -

- (id)initWithConnection:(WCServerConnection *)connection {
	self = [self init];
	
	_connection			= connection;
	_connectionName		= [[_connection name] retain];
	_url				= [[_connection URL] retain];
	_bookmark			= [[connection bookmark] retain];
	
	return self;
}



- (id)initWithCoder:(NSCoder *)coder {
    self = [self init];
	
	if([coder decodeIntForKey:@"WCServerConnectionObjectVersion"] != [[self class] version]) {
		[self release];
		
		return NULL;
	}
	
	_connectionName	= [[coder decodeObjectForKey:@"WCServerConnectionObjectName"] retain];
	_url			= [[coder decodeObjectForKey:@"WCServerConnectionObjectURL"] retain];
	_bookmark		= [[coder decodeObjectForKey:@"WCServerConnectionObjectBookmark"] retain];
	
	return self;
}



- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeInt:[[self class] version] forKey:@"WCServerConnectionObjectVersion"];

	[coder encodeObject:_connectionName forKey:@"WCServerConnectionObjectName"];
	[coder encodeObject:_url forKey:@"WCServerConnectionObjectURL"];
	[coder encodeObject:_bookmark forKey:@"WCServerConnectionObjectBookmark"];
}



- (void)dealloc {
	[_connectionName release];
	[_url release];
	[_bookmark release];
	
	[super dealloc];
}



#pragma mark -

- (BOOL)belongsToConnection:(WCServerConnection *)connection {
	if(!_connection) {
		if([[_url hostpair] isEqualToString:[connection URLIdentifier]] ||
		   [[_bookmark objectForKey:WCBookmarksIdentifier] isEqualToString:[connection bookmarkIdentifier]])
			return YES;
	}
	
	return NO;
}



#pragma mark -

- (void)setConnection:(WCServerConnection *)connection {
	_connection = connection;
}



- (WCServerConnection *)connection {
	return _connection;
}



- (NSString *)connectionName {
	return _connectionName;
}



- (WIURL *)URL {
	return _url;
}



- (NSDictionary *)bookmark {
	return _bookmark;
}



- (NSDictionary *)theme {
	NSDictionary		*theme;
	
	theme = [_connection theme];
	
	if(!theme)
		theme = [[WCSettings settings] themeWithIdentifier:[[WCSettings settings] objectForKey:WCTheme]];
	
	return theme;
}

@end
