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

#import <WiredNetworking/NSString-WINetworking.h>
#import <WiredNetworking/WIAddress.h>
#import <WiredNetworking/WIError.h>

@interface WIAddress(Private)

- (id)_initWithAddress:(wi_address_t *)address;

@end


@implementation WIAddress(Private)

- (id)_initWithAddress:(wi_address_t *)address {
	self = [super init];
	
	_address = wi_retain(address);
	_string = [[NSString alloc] initWithWiredString:wi_address_string(_address)];
	
	return self;
}

@end



@implementation WIAddress

+ (WIAddress *)addressWildcardForFamily:(WIAddressFamily)family {
	return [[[self alloc] initWildcardForFamily:family] autorelease];
}



+ (WIAddress *)addressWithString:(NSString *)address error:(WIError **)error {
	return [[[self alloc] initWithString:address error:error] autorelease];
}



+ (WIAddress *)addressWithNetService:(NSNetService *)netService error:(WIError **)error {
	return [[[self alloc] initWithNetService:netService error:error] autorelease];
}



- (id)initWildcardForFamily:(WIAddressFamily)family {
	wi_pool_t		*pool;
	wi_address_t	*address;
	
	pool = wi_pool_init(wi_pool_alloc());
    address = wi_address_wildcard_for_family(family);
	
	self = [self _initWithAddress:address];
	
	wi_retain(pool);
	
	return self;
}



- (id)initWithString:(NSString *)string error:(WIError **)error {
	wi_pool_t		*pool;
	wi_address_t	*address;

	pool = wi_pool_init(wi_pool_alloc());
	address = wi_host_address(wi_host_with_string([string wiredString]));
	
	if(!address) {
		if(error) {
			*error = [WIError errorWithDomain:WIWiredNetworkingErrorDomain
										 code:WIAddressLookupFailed
									 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
										 [WIError errorWithDomain:WILibWiredErrorDomain],
											 WILibWiredErrorKey,
										 string,
											 WIArgumentErrorKey,
										 NULL]];
		}
		
		[self release];
		
		wi_release(pool);

		return NULL;
	}
	
	self = [self _initWithAddress:address];

	wi_release(pool);
	
	return self;
}



- (id)initWithNetService:(NSNetService *)netService error:(WIError **)error {
	NSArray			*addresses;
	NSData			*data;
	wi_pool_t		*pool;
	wi_address_t	*address;
	
	self = [super init];
	
	addresses = [netService addresses];
	
	if([addresses count] == 0) {
		if(error) {
			*error = [WIError errorWithDomain:WIWiredNetworkingErrorDomain
										 code:WIAddressNetServiceLookupFailed];
		}
		
		[self release];
		
		return NULL;
	}
	
	data = [addresses objectAtIndex:0];
	
	pool = wi_pool_init(wi_pool_alloc());
	address = wi_address_init_with_sa(wi_address_alloc(), (struct sockaddr *) [data bytes]);
	
	self = [self _initWithAddress:address];
	
	wi_release(address);
	wi_release(pool);

	return self;
}



- (NSString *)description {
	return [NSSWF:@"<%@: %p>{address = %@}", [self class], self, [self string]];
}



- (void)dealloc {
	[_string release];
	
	wi_release(_address);
	
	[super dealloc];
}



#pragma mark -

- (void)setPort:(NSUInteger)port {
	wi_address_set_port(_address, port);
}



- (NSUInteger)port {
	return wi_address_port(_address);
}



#pragma mark -

- (WIAddressFamily)family {
	return (WIAddressFamily) wi_address_family(_address);
}



- (NSString *)string {
	return _string;
}



- (NSString *)hostname {
	NSString	*string;
	wi_pool_t	*pool;
	
	pool = wi_pool_init(wi_pool_alloc());
	string = [NSString stringWithWiredString:wi_address_hostname(_address)];
	wi_release(pool);
	
	return string;
}



- (struct sockaddr *)sockAddr {
	return wi_address_sa(_address);
}

@end



@implementation WIAddress(WISocketAdditions)

- (id)initWithAddress:(wi_address_t *)address {
	return [self _initWithAddress:address];
}



- (wi_address_t *)address {
	return _address;
}

@end
