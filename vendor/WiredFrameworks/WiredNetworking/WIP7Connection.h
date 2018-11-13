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


#import "WIP7Message.h"


#define WCServerPort					4871
#define WCBonjourName					@"_wired._tcp."
#define WCDefaultLogin					@"guest"


extern WIP7Spec							*WCP7Spec;


@interface WIP7Connection : WIObject {
	WIURL								*_url;
	NSDictionary						*_bookmark;
	NSString							*_uuid;
}

+ (NSString *)versionStringForMessage:(WIP7Message *)message;

+ (id)connection;

- (void)disconnect;

- (WIP7Message *)clientInfoMessage;
- (WIP7Message *)setNickMessage;
- (WIP7Message *)setStatusMessage;
- (WIP7Message *)setIconMessage;
- (WIP7Message *)loginMessage;

- (void)setURL:(WIURL *)url;
- (WIURL *)URL;
- (void)setBookmark:(NSDictionary *)bookmark;
- (NSDictionary *)bookmark;
- (WIP7Socket *)socket;
- (NSString *)identifier;
- (NSString *)URLIdentifier;
- (NSString *)bookmarkIdentifier;
- (NSString *)uniqueIdentifier;

@end
