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

@interface WIURL : WIObject <NSCoding, NSCopying> {
	NSString			*_scheme;
	NSString			*_host;
	NSUInteger			_port;
	NSString			*_user;
	NSString			*_password;
	NSString			*_path;
	NSString			*_query;
}

+ (id)URLWithString:(NSString *)string;
+ (id)URLWithString:(NSString *)string scheme:(NSString *)defaultScheme;
+ (id)URLWithScheme:(NSString *)scheme hostpair:(NSString *)pairhost;
+ (id)URLWithScheme:(NSString *)scheme host:(NSString *)host port:(NSUInteger)port;
+ (id)URLWithURL:(NSURL *)url;
+ (id)fileURLWithPath:(NSString *)path;

- (id)initWithScheme:(NSString *)scheme host:(NSString *)host port:(NSUInteger)port;

- (NSString *)string;
- (NSString *)humanReadableString;
- (WIURL *)URLByDeletingLastPathComponent;
- (NSURL *)URL;
- (BOOL)isFileURL;

- (void)setScheme:(NSString *)value;
- (NSString *)scheme;
- (void)setHostpair:(NSString *)value;
- (NSString *)hostpair;
- (void)setHost:(NSString *)value;
- (NSString *)host;
- (void)setPort:(NSUInteger)value;
- (NSUInteger)port;
- (void)setUser:(NSString *)value;
- (NSString *)user;
- (void)setPassword:(NSString *)value;
- (NSString *)password;
- (void)setPath:(NSString *)value;
- (NSString *)path;
- (NSString *)pathExtension;
- (NSString *)lastPathComponent;
- (void)setQuery:(NSString *)query;
- (NSString *)query;
- (NSDictionary *)queryParameters;

@end
