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

#import <WiredFoundation/NSString-WIFoundation.h>
#import <WiredFoundation/WIMacros.h>
#import <WiredFoundation/WIURL.h>

@interface WIURL(Private)

+ (NSDictionary *)_portmap;

@end


@implementation WIURL(Private)

+ (NSDictionary *)_portmap {
	static NSDictionary	*portmap;

	if(!portmap) {
		portmap = [[NSDictionary alloc] initWithObjectsAndKeys:
			[NSNumber numberWithInt:2000],		@"wired",
			[NSNumber numberWithInt:2002],		@"wiredtracker",
			[NSNumber numberWithInt:4871],		@"wiredp7",
			NULL];
	}

	return portmap;
}

@end



@implementation WIURL

+ (NSInteger)version {
	return 1;
}



#pragma mark -

+ (id)URLWithString:(NSString *)string {
	return [self URLWithString:string scheme:NULL];
}



+ (id)URLWithString:(NSString *)string scheme:(NSString *)defaultScheme {
	NSString	*scheme, *auth, *user, *password, *path, *query;
	WIURL		*url;
	NSRange		range;
	
	string = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	range = [string rangeOfString:@"://"];

	if(range.location == NSNotFound) {
		scheme = NULL;
	} else {
		scheme = [string substringToIndex:range.location];
		string = [string substringFromIndex:range.location + 3];
	}
	
	range = [string rangeOfString:@"://"];
	
	if(range.location != NSNotFound)
		string = [string substringFromIndex:range.location + 3];

	range = [string rangeOfString:@"/"];

	if(range.location == NSNotFound) {
		path = NULL;
	} else {
		path = [string substringFromIndex:range.location];
		string = [string substringToIndex:range.location];
	}

	range = [string rangeOfString:@"@"];

	if(range.location == NSNotFound) {
		user = NULL;
		password = NULL;
	} else {
		auth = [string substringToIndex:range.location];
		string = [string substringFromIndex:range.location + 1];

		range = [auth rangeOfString:@":"];

		if(range.location == NSNotFound) {
			user = auth;
			password = NULL;
		} else {
			user = [auth substringToIndex:range.location];
			password = [auth substringFromIndex:range.location + 1];
		}
	}

	if(defaultScheme)
		scheme = defaultScheme;

	if(!scheme) {
		if([string hasPrefix:@"www."])
			scheme = @"http";
		else if([string hasPrefix:@"wired."])
			scheme = @"wired";
	}

	if(!scheme)
		return NULL;

	url = [[self alloc] init];
	[url setScheme:scheme];
	[url setHostpair:string];
	[url setUser:user];
	[url setPassword:password];
	
	if(path) {
		range = [path rangeOfString:@"?"];
		
		if(range.location == NSNotFound) {
			[url setPath:path];
		} else {
			query = [path substringFromIndex:range.location + 1];
			path = [path substringToIndex:range.location];
			
			[url setPath:path];
			[url setQuery:query];
		}
	}

	return [url autorelease];
}



+ (id)URLWithScheme:(NSString *)scheme hostpair:(NSString *)hostpair {
	WIURL		*url;
	
	url = [[self alloc] init];
	[url setScheme:scheme];
	[url setHostpair:hostpair];
	
	return [url autorelease];
}



+ (id)URLWithScheme:(NSString *)scheme host:(NSString *)host port:(NSUInteger)port {
	return [[[self alloc] initWithScheme:scheme host:host port:port] autorelease];
}



+ (id)URLWithURL:(NSURL *)url {
	return [self URLWithString:[url absoluteString]];
}



+ (id)fileURLWithPath:(NSString *)path {
	WIURL	*url;

	url = [self URLWithScheme:@"file" host:NULL port:0];
	[url setPath:path];

	return url;
}



- (id)initWithScheme:(NSString *)scheme host:(NSString *)host port:(NSUInteger)port {
	self = [super init];

	_scheme = [scheme retain];
	_host = [host retain];
	_port = port;

	return self;
}



- (id)initWithCoder:(NSCoder *)coder {
    self = [self init];
	
	if([coder decodeIntForKey:@"WIURLVersion"] != [[self class] version]) {
		[self release];
		
		return NULL;
	}
	
	_scheme		= [[coder decodeObjectForKey:@"WIURLScheme"] retain];
	_host		= [[coder decodeObjectForKey:@"WIURLHost"] retain];
	_port		= [coder decodeIntForKey:@"WIURLPort"];
	_user		= [[coder decodeObjectForKey:@"WIURLUser"] retain];
	_password	= [[coder decodeObjectForKey:@"WIURLPassword"] retain];
	_path		= [[coder decodeObjectForKey:@"WIURLPath"] retain];
	_query		= [[coder decodeObjectForKey:@"WIURLQuery"] retain];
	
	return self;
}



- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeInt:(int)[[self class] version] forKey:@"WIURLVersion"];
	
	[coder encodeObject:_scheme forKey:@"WIURLScheme"];
	[coder encodeObject:_host forKey:@"WIURLHost"];
	[coder encodeInt:(int)_port forKey:@"WIURLPort"];
	[coder encodeObject:_user forKey:@"WIURLUser"];
	[coder encodeObject:_password forKey:@"WIURLPassword"];
	[coder encodeObject:_path forKey:@"WIURLPath"];
	[coder encodeObject:_query forKey:@"WIURLQuery"];
}



- (NSString *)description {
	return [self humanReadableString];
}



- (void)dealloc {
	[_scheme release];
	[_host release];
	[_user release];
	[_password release];
	[_path release];
	[_query release];

	[super dealloc];
}



#pragma mark -

- (id)copyWithZone:(NSZone *)zone {
	WIURL	*url;
	
	url = [[[self class] allocWithZone:zone] initWithScheme:[self scheme] host:[self host] port:[self port]];
	[url setUser:[self user]];
	[url setPassword:[self password]];
	[url setPath:[self path]];
	[url setQuery:[self query]];
		
	return url;
}



#pragma mark -

- (NSUInteger)hash {
	return [[self string] hash];
}



- (BOOL)isEqual:(id)url {
	return [[self string] isEqualToString:[url string]];
}



#pragma mark -

- (NSString *)string {
	NSMutableString		*string;
	
	string = [[NSMutableString alloc] init];
	[string appendString:[[self scheme] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	[string appendString:@"://"];
	
	if([[self host] length] > 0) {
		if([[self user] length] > 0) {
			[string appendString:[[self user] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
			
			if([[self password] length] > 0) {
				[string appendString:@":"];
				[string appendString:[[self password] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
			}

			[string appendString:@"@"];
		}
		
		[string appendString:[[self host] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
		
		if([self port] != 0)
			[string appendFormat:@":%lu", (unsigned long)[self port]];
	}
	
	if([[self path] length] > 0)
		[string appendString:[[self path] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding charactersToLeaveUnescaped:@"#"]];
	
	if([[self query] length] > 0)
		[string appendFormat:@"?%@", [[self query] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	
	return [string autorelease];
}



- (NSString *)humanReadableString {
	NSMutableString		*string;
	
	if([self isFileURL])
		return [self path];

	string = [[NSMutableString alloc] init];
	[string appendFormat:@"%@://", [self scheme]];

	if([[self host] length] > 0) {
		if([[self user] length] > 0 && ![[self user] isEqualToString:@"guest"])
			[string appendFormat:@"%@@", [self user]];

		[string appendString:[self hostpair]];
	}

	[string appendString:[[self path] length] > 0 ? [self path] : @"/"];

	if([[self query] length] > 0)
		[string appendFormat:@"?%@", [self query]];

	return [string autorelease];
}



- (WIURL *)URLByDeletingLastPathComponent {
	WIURL	*url;

	url = [self copy];
	[url setPath:[[url path] stringByDeletingLastPathComponent]];

	return [url autorelease];
}



- (NSURL *)URL {
	if([self isFileURL])
		return [NSURL fileURLWithPath:[self path]];

	return [NSURL URLWithString:[self string]];
}



- (BOOL)isFileURL {
	return [[self scheme] isEqualToString:@"file"];
}



#pragma mark -

- (void)setScheme:(NSString *)value {
	[value retain];
	[_scheme release];

	_scheme = value;
}



- (NSString *)scheme {
	return _scheme;
}



- (void)setHostpair:(NSString *)value {
	NSString		*host;
	NSRange			range;
	NSUInteger		port;
	
	if([value hasPrefix:@"["] && [value containsSubstring:@"]"]) {
		value	= [value substringFromIndex:1];
		range	= [value rangeOfString:@"]" options:NSBackwardsSearch];
		host	= [value substringToIndex:range.location];
		port	= 0;
		
		if([value containsSubstring:@"]:"]) {
			range = [value rangeOfString:@"]:" options:NSBackwardsSearch];
			
			if(range.location != [value length] - 2)
				port = [[value substringFromIndex:range.location + 2] unsignedIntValue];
		}
	}
	else if([[value componentsSeparatedByString:@":"] count] == 2) {
		range = [value rangeOfString:@":" options:NSBackwardsSearch];

		if(range.location == NSNotFound || range.location == 0 ||
		   range.location == [value length] - 1) {
			host = value;
			port = 0;
		} else {
			host = [value substringToIndex:range.location];
			port = [[value substringFromIndex:range.location + 1] unsignedIntValue];
		}
	} else {
		host = value;
		port = 0;
	}
	
    if(port == 0)
        port = [[[WIURL _portmap] objectForKey:_scheme] unsignedIntValue];

	[self setHost:host];
	[self setPort:port];
}



- (NSString *)hostpair {
	if([[[WIURL _portmap] objectForKey:[self scheme]] unsignedIntValue] == [self port])
		return [self host];
	
	if([[self host] containsSubstring:@":"])
		return [NSSWF:@"[%@]:%lu", [self host], (unsigned long)[self port]];

	return [NSSWF:@"%@:%lu", [self host], (unsigned long)[self port]];
}



- (void)setHost:(NSString *)value {
	[value retain];
	[_host release];

	_host = value;
}



- (NSString *)host {
	return _host;
}



- (void)setPort:(NSUInteger)value {
	_port = value;
}



- (NSUInteger)port {
	return _port;
}



- (void)setUser:(NSString *)value {
	[value retain];
	[_user release];

	_user = value;
}



- (NSString *)user {
	return _user;
}



- (void)setPassword:(NSString *)value {
	[value retain];
	[_password release];

	_password = value;
}



- (NSString *)password {
	return _password;
}



- (void)setPath:(NSString *)value {
	[value retain];
	[_path release];

	_path = value;
}



- (NSString *)path {
	return _path;
}



- (NSString *)pathExtension {
	return [_path pathExtension];
}



- (NSString *)lastPathComponent {
	return [_path lastPathComponent];
}



- (void)setQuery:(NSString *)value {
	[value retain];
	[_query release];

	_query = value;
}



- (NSString *)query {
	return _query;
}



- (NSDictionary *)queryParameters {
	NSEnumerator			*enumerator;
	NSMutableDictionary		*dictionary;
	NSArray					*parameters, *sides;
	NSString				*string;
	
	dictionary = [NSMutableDictionary dictionary];
	parameters = [[self query] componentsSeparatedByCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"&;"]];
	enumerator = [parameters objectEnumerator];
	
	while((string = [enumerator nextObject])) {
		sides = [string componentsSeparatedByString:@"="];
		
		if([sides count] == 2)
			[dictionary setObject:[sides objectAtIndex:1] forKey:[sides objectAtIndex:0]];
	}
	
	return dictionary;
}

@end
