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

// ugly !!!
#define WI_RSA 1

#import <WiredNetworking/NSString-WINetworking.h>
#import <WiredNetworking/WIError.h>
#import <WiredNetworking/WIP7Message.h>
#import <WiredNetworking/WIP7Socket.h>
#import <WiredNetworking/WIP7Spec.h>
#import <WiredNetworking/WISocket.h>

static void _WIP7SocketReadMessage(wi_p7_socket_t *, wi_p7_message_t *, void *);
static void _WIP7SocketWroteMessage(wi_p7_socket_t *, wi_p7_message_t *, void *);


static void _WIP7SocketReadMessage(wi_p7_socket_t *p7Socket, wi_p7_message_t *p7Message, void *contextInfo) {
	[[(id) contextInfo delegate] P7Socket:contextInfo readMessage:[WIP7Message messageWithMessage:p7Message spec:[(id) contextInfo spec]]];
}



static void _WIP7SocketWroteMessage(wi_p7_socket_t *p7Socket, wi_p7_message_t *p7Message, void *contextInfo) {
	[[(id) contextInfo delegate] P7Socket:contextInfo wroteMessage:[WIP7Message messageWithMessage:p7Message spec:[(id) contextInfo spec]]];
}



@interface WIP7Socket(Private)

- (WIError *)_errorWithCode:(NSInteger)code;

@end


@implementation WIP7Socket(Private)

- (WIError *)_errorWithCode:(NSInteger)code {
	return [WIError errorWithDomain:WIWiredNetworkingErrorDomain
							   code:code
						   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
									 [WIError errorWithDomain:WILibWiredErrorDomain],
										 WILibWiredErrorKey,
									 [[_socket address] string],
										 WIArgumentErrorKey,
									 NULL]];
}

@end



@implementation WIP7Socket

+ (void)initialize {
//	wi_p7_socket_debug = true;
}



#pragma mark -

- (id)initWithSocket:(WISocket *)socket spec:(WIP7Spec *)spec {
	self = [super init];
	
	_socket		= [socket retain];
	_spec		= [spec retain];
	
	_p7Socket = wi_p7_socket_init_with_socket(wi_p7_socket_alloc(), [_socket socket], [_spec spec]);
	
	return self;
}



- (void)dealloc {
	[_socket release];
	[_spec release];
	
	[_readTimeoutError release];
	
	wi_release(_p7Socket);
	
	[super dealloc];
}



#pragma mark -

- (void)setDelegate:(id)aDelegate {
	delegate = aDelegate;
	
	if([delegate respondsToSelector:@selector(P7Socket:readMessage:)])
	   wi_p7_socket_set_read_message_callback(_p7Socket, _WIP7SocketReadMessage, self);
	else
		wi_p7_socket_set_read_message_callback(_p7Socket, NULL, NULL);

	if([delegate respondsToSelector:@selector(P7Socket:wroteMessage:)])
		wi_p7_socket_set_wrote_message_callback(_p7Socket, _WIP7SocketWroteMessage, self);
	else
		wi_p7_socket_set_wrote_message_callback(_p7Socket, NULL, NULL);
}



- (id)delegate {
	return delegate;
}



#pragma mark -

- (WISocket *)socket {
	return _socket;
}



- (wi_p7_socket_t *)P7Socket {
	return _p7Socket;
}



- (WIP7Spec *)spec {
	return _spec;
}



- (NSUInteger)options {
	return wi_p7_socket_options(_p7Socket);
}



- (WIP7Serialization)serialization {
	return wi_p7_socket_serialization(_p7Socket);
}



- (NSString *)remoteProtocolName {
	return [NSString stringWithWiredString:wi_p7_socket_remote_protocol_name(_p7Socket)];
}



- (NSString *)remoteProtocolVersion {
	return [NSString stringWithWiredString:wi_p7_socket_remote_protocol_version(_p7Socket)];
}



- (BOOL)usesEncryption {
	return WI_P7_ENCRYPTION_ENABLED([self options]);
}



- (NSString *)cipherName {
    
#ifdef WI_RSA
	wi_cipher_t		*cipher;
	cipher = wi_p7_socket_cipher(_p7Socket);
	
	return cipher ? [NSString stringWithWiredString:wi_cipher_name(cipher)] : NULL;
#else
	return NULL;
#endif
}



- (NSUInteger)cipherBits {
#ifdef WI_RSA
	wi_cipher_t		*cipher;
	
	cipher = wi_p7_socket_cipher(_p7Socket);
	
	return cipher ? wi_cipher_bits(cipher) : 0;
#else
	return 0;
#endif
}



- (BOOL)usesCompression {
	return WI_P7_COMPRESSION_ENABLED([self options]);
}



- (double)compressionRatio {
	return wi_p7_socket_compression_ratio(_p7Socket);
}



#pragma mark -

- (BOOL)verifyMessage:(WIP7Message *)message error:(WIError **)error {
	wi_pool_t		*pool;
	wi_boolean_t	result;
	
	pool = wi_pool_init(wi_pool_alloc());
	result = wi_p7_socket_verify_message(_p7Socket, [message message]);
	wi_release(pool);
	
	if(!result) {
		if(error)
			*error = [WIError errorWithDomain:WILibWiredErrorDomain];
		
		return NO;
	}
	
	return YES;
}



#pragma mark -

- (BOOL)connectWithOptions:(NSUInteger)options serialization:(WIP7Serialization)serialization username:(NSString *)username password:(NSString *)password timeout:(NSTimeInterval)timeout error:(WIError **)error {
	wi_pool_t		*pool;
	wi_boolean_t	result;
	
	pool = wi_pool_init(wi_pool_alloc());
	result = wi_p7_socket_connect(_p7Socket, timeout, options, serialization, [username wiredString], [password wiredString]);
	wi_release(pool);

	if(!result) {
		if(error)
			*error = [self _errorWithCode:WISocketConnectFailed];
		
		return NO;
	}
	
	return YES;
}



- (BOOL)acceptWithOptions:(NSUInteger)options timeout:(NSTimeInterval)timeout error:(WIError **)error {
	wi_pool_t		*pool;
	wi_boolean_t	result;
	
	pool = wi_pool_init(wi_pool_alloc());
	result = wi_p7_socket_accept(_p7Socket, timeout, options);
	wi_release(pool);
	
	if(!result) {
		if(error)
			*error = [self _errorWithCode:WISocketConnectFailed];
		
		return NO;
	}
	
	return YES;
}



- (void)close {
	wi_p7_socket_close(_p7Socket);
}



#pragma mark -

- (BOOL)writeMessage:(WIP7Message *)message timeout:(NSTimeInterval)timeout error:(WIError **)error {
	wi_pool_t			*pool;
	wi_boolean_t		result;
    
	pool = wi_pool_init(wi_pool_alloc());
	result = wi_p7_socket_write_message(_p7Socket, timeout, [message message]);
	wi_release(pool);
	
	if(!result) {
		if(error)
			*error = [self _errorWithCode:WISocketWriteFailed];
		
		return NO;
	}
	
	return YES;
}



- (WIP7Message *)readMessageWithTimeout:(NSTimeInterval)timeout error:(WIError **)error {
	wi_pool_t			*pool;
	wi_p7_message_t		*result;
	WIP7Message			*message;
	
	pool = wi_pool_init(wi_pool_alloc());
	result = wi_p7_socket_read_message(_p7Socket, timeout);
	
	if(!result) {
		if(error) {
			if(wi_error_domain() == WI_ERROR_DOMAIN_ERRNO && wi_error_code() == ETIMEDOUT) {
				if(!_readTimeoutError)
					_readTimeoutError = [[self _errorWithCode:WISocketReadFailed] retain];
				
				*error = _readTimeoutError;
			} else {
				*error = [self _errorWithCode:WISocketReadFailed];
			}
		}
		
		wi_release(pool);
		
		return NULL;
	}
	
	message = [WIP7Message messageWithMessage:result spec:_spec];
	
	wi_release(pool);
	
	return message;
}



- (BOOL)writeOOBData:(const void *)data length:(NSUInteger)length timeout:(NSTimeInterval)timeout error:(WIError **)error {
	wi_boolean_t		result;
	
	result = wi_p7_socket_write_oobdata(_p7Socket, timeout, data, (WIP7UInt32)length);

	if(!result) {
		if(error)
			*error = [self _errorWithCode:WISocketWriteFailed];
		
		return NO;
	}
	
	return YES;
}



- (NSInteger)readOOBData:(void **)data timeout:(NSTimeInterval)timeout error:(WIError **)error {
	wi_integer_t		result;
	
	result = wi_p7_socket_read_oobdata(_p7Socket, timeout, data);
	
	if(result < 0) {
			if(wi_error_domain() == WI_ERROR_DOMAIN_ERRNO && wi_error_code() == ETIMEDOUT) {
				if(!_readTimeoutError)
					_readTimeoutError = [[self _errorWithCode:WISocketReadFailed] retain];
				
				*error = _readTimeoutError;
			} else {
				*error = [self _errorWithCode:WISocketReadFailed];
			}
		
		return result;
	}
	
	return result;
}

@end
