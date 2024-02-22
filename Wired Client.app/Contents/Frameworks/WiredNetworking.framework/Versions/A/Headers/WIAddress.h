/* $Id$ */

/*
 *  Copyright (c) 2006-2009 Axel Andersson
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

enum _WIAddressFamily {
	WIAddressNull					= WI_ADDRESS_NULL,
	WIAddressIPv4					= WI_ADDRESS_IPV4,
	WIAddressIPv6					= WI_ADDRESS_IPV6
};
typedef enum _WIAddressFamily		WIAddressFamily;


@class WIError;

@interface WIAddress : WIObject {
	wi_address_t					*_address;
	
	NSString						*_string;
}

+ (WIAddress *)addressWildcardForFamily:(WIAddressFamily)family;
+ (WIAddress *)addressWithString:(NSString *)address error:(WIError **)error;
+ (WIAddress *)addressWithNetService:(NSNetService *)netService error:(WIError **)error;

- (id)initWildcardForFamily:(WIAddressFamily)family;
- (id)initWithString:(NSString *)address error:(WIError **)error;
- (id)initWithNetService:(NSNetService *)netService error:(WIError **)error;

- (void)setPort:(NSUInteger)port;
- (NSUInteger)port;

- (WIAddressFamily)family;
- (NSString *)string;
- (NSString *)hostname;
- (struct sockaddr *)sockAddr;

@end


@interface WIAddress(WISocketAdditions)

- (id)initWithAddress:(wi_address_t *)address;
- (wi_address_t *)address;

@end
