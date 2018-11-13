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
#import <WiredNetworking/WISocket.h>

#define _WISocketBufferMaxSize				131072


static void _WISocketCallback(CFSocketRef, CFSocketCallBackType, CFDataRef, const void *, void *);

static void _WISocketCallback(CFSocketRef socketRef, CFSocketCallBackType callbackType, CFDataRef address, const void *data, void *info) {
	WISocket		*socket = info;
	
	[[socket delegate] socket:socket handleEvent:(WISocketEvent)callbackType];
}



@interface WISocketTLS(Private)

- (id)_initForClient;

@end


@implementation WISocketTLS(Private)

- (id)_initForClient {
#ifdef WI_SSL
	wi_pool_t	*pool;
	
	self = [super init];
	
	pool = wi_pool_init(wi_pool_alloc());
	_tls = wi_socket_tls_init_with_type(wi_socket_tls_alloc(), WI_SOCKET_TLS_CLIENT);
	wi_release(pool);

	return self;
#else
	[self release];
	
	return NULL;
#endif
}

@end



@implementation WISocketTLS

+ (WISocketTLS *)socketTLSForClient {
	return [[[self alloc] _initForClient] autorelease];
}



- (void)dealloc {
	wi_release(_tls);
	
	[super dealloc];
}



#pragma mark -

- (wi_socket_tls_t *)TLS {
	return _tls;
}



#pragma mark -

- (void)setSSLCiphers:(NSString *)ciphers {
#ifdef WI_SSL
	wi_pool_t	*pool;
	
	pool = wi_pool_init(wi_pool_alloc());
	wi_socket_tls_set_ciphers(_tls, [ciphers wiredString]);
	wi_release(pool);
#endif
}

@end



@interface WISocket(Private)

- (id)_initWithSocket:(wi_socket_t *)socket address:(WIAddress *)address;

- (WIError *)_errorWithCode:(NSInteger)code;

@end


@implementation WISocket(Private)

- (id)_initWithSocket:(wi_socket_t *)socket address:(WIAddress *)address {
	self = [self init];
	
	_socket		= wi_retain(socket);
	_address	= [address retain];
	
	return self;
}



#pragma mark -

- (WIError *)_errorWithCode:(NSInteger)code {
	return [WIError errorWithDomain:WIWiredNetworkingErrorDomain
							   code:code
						   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
									 [WIError errorWithDomain:WILibWiredErrorDomain],
										 WILibWiredErrorKey,
									 [_address string],
										 WIArgumentErrorKey,
									 NULL]];
}

@end



@implementation WISocket

+ (WISocket *)socketWithAddress:(WIAddress *)address type:(WISocketType)type {
	return [[[self alloc] initWithAddress:address type:type] autorelease];
}



+ (WISocket *)socketWithFileDescriptor:(int)sd {
	return [[[self alloc] initWithFileDescriptor:sd] autorelease];
}



- (id)initWithAddress:(WIAddress *)address type:(WISocketType)type {
	wi_pool_t		*pool;
	wi_socket_t		*socket;
	
	pool = wi_pool_init(wi_pool_alloc());
	socket = wi_socket_init_with_address(wi_socket_alloc(), [address address], type);

	self = [self _initWithSocket:socket address:address];
	
	wi_release(socket);
	wi_release(pool);
	
	return self;
}



- (id)initWithFileDescriptor:(int)sd {
	WIAddress		*address;
	wi_pool_t		*pool;
	wi_socket_t		*socket;
	
	pool = wi_pool_init(wi_pool_alloc());
	socket = wi_socket_init_with_descriptor(wi_socket_alloc(), sd);
	address = [[WIAddress alloc] initWithAddress:wi_socket_address(socket)];

	self = [self _initWithSocket:socket address:address];
	
	[address release];
	wi_release(socket);
	wi_release(pool);
	
	return self;
}



- (id)init {
	self = [super init];
	
	_buffer = [[NSMutableString alloc] initWithCapacity:WISocketBufferSize];
	
	return self;
}



- (void)dealloc {
	wi_pool_t	*pool;
	
	pool = wi_pool_init(wi_pool_alloc());
	wi_release(_socket);
	wi_release(pool);
	
	[_address release];
	[_buffer release];

	[super dealloc];
}



#pragma mark -

- (WIAddress *)address {
	return _address;
}



- (int)fileDescriptor {
	return wi_socket_descriptor(_socket);
}



- (void *)SSL {
	return wi_socket_ssl(_socket);
}



- (wi_socket_t *)socket {
	return _socket;
}



- (NSString *)cipherVersion {
	NSString		*string;
	wi_pool_t		*pool;
	
	pool = wi_pool_init(wi_pool_alloc());
	string = [NSString stringWithWiredString:wi_socket_cipher_version(_socket)];
	wi_release(pool);
	
	return string;
}



- (NSString *)cipherName {
	NSString		*string;
	wi_pool_t		*pool;
	
	pool = wi_pool_init(wi_pool_alloc());
	string = [NSString stringWithWiredString:wi_socket_cipher_name(_socket)];
	wi_release(pool);
	
	return string;
}



- (NSUInteger)cipherBits {
	return wi_socket_cipher_bits(_socket);
}



- (NSString *)certificateName {
	NSString		*string = NULL;
	wi_pool_t		*pool;
	wi_string_t		*wstring;
	
	pool = wi_pool_init(wi_pool_alloc());
	wstring = wi_socket_certificate_name(_socket);
	
	if(wstring)
		string = [NSString stringWithWiredString:wstring];
	
	wi_release(pool);
	
	return string;
}



- (NSUInteger)certificateBits {
	return wi_socket_certificate_bits(_socket);
}



- (NSString *)certificateHostname {
	NSString		*string = NULL;
	wi_pool_t		*pool;
	wi_string_t		*wstring;
	
	pool = wi_pool_init(wi_pool_alloc());
	wstring = wi_socket_certificate_hostname(_socket);
	
	if(wstring)
		string = [NSString stringWithWiredString:wstring];
	
	wi_release(pool);
	
	return string;
}



#pragma mark -

- (void)setDelegate:(id <WISocketDelegate>)newDelegate {
	delegate = newDelegate;
}



- (id <WISocketDelegate>)delegate {
	return delegate;
}



- (void)setPort:(NSUInteger)port {
	wi_socket_set_port(_socket, port);
	
	[_address setPort:port];
}



- (NSUInteger)port {
	return wi_socket_port(_socket);
}



- (void)setDirection:(WISocketDirection)direction {
	wi_socket_set_direction(_socket, (wi_socket_direction_t) direction);
}



- (WISocketDirection)direction {
	return (WISocketDirection) wi_socket_direction(_socket);
}



- (void)setBlocking:(BOOL)blocking {
	wi_socket_set_blocking(_socket, blocking);
}



- (BOOL)blocking {
	return wi_socket_blocking(_socket);
}



- (void)setInteractive:(BOOL)interactive {
	wi_socket_set_interactive(_socket, interactive);
}



- (BOOL)interactive {
	return wi_socket_interactive(_socket);
}



#pragma mark -

- (BOOL)waitWithTimeout:(NSTimeInterval)timeout {
	wi_pool_t			*pool;
	wi_socket_state_t	state;
	
	pool = wi_pool_init(wi_pool_alloc());
	state = wi_socket_wait(_socket, timeout);
	wi_release(pool);
	
	return (state == WI_SOCKET_READY);
}



#pragma mark -

- (BOOL)connectWithTimeout:(NSTimeInterval)timeout error:(WIError **)error {
	wi_pool_t		*pool;
	BOOL			result = YES;
	
	pool = wi_pool_init(wi_pool_alloc());
	
	if(!wi_socket_connect(_socket, timeout)) {
		if(error)
			*error = [self _errorWithCode:WISocketConnectFailed];
		
		result = NO;
	}
	
	wi_release(pool);
	
	return result;
}



- (BOOL)connectWithTLS:(WISocketTLS *)tls timeout:(NSTimeInterval)timeout error:(WIError **)error {
#ifdef WI_SSL
	wi_pool_t		*pool;
	BOOL			result = YES;
	
	pool = wi_pool_init(wi_pool_alloc());
	
	if(!wi_socket_connect_tls(_socket, [tls TLS], timeout)) {
		if(error)
			*error = [self _errorWithCode:WISocketConnectFailed];
		
		result = NO;
	}
	
	wi_release(pool);
	
	return result;
#else
	return NO;
#endif
}



- (BOOL)listenWithError:(WIError **)error {
	wi_pool_t		*pool;
	BOOL			result = YES;
	
	pool = wi_pool_init(wi_pool_alloc());
	
	if(!wi_socket_listen(_socket)) {
		if(error)
			*error = [self _errorWithCode:WISocketListenFailed];
		
		result = NO;
	}
	
	if([_address port] == 0)
		[_address setPort:wi_socket_port(_socket)];
	
	wi_release(pool);
	
	return result;
}



- (WISocket *)acceptWithTimeout:(NSTimeInterval)timeout error:(WIError **)error {
	WISocket		*remoteSocket = NULL;
	wi_pool_t		*pool;
	wi_socket_t		*socket;
	wi_address_t	*address;
	
	pool = wi_pool_init(wi_pool_alloc());

	socket = wi_socket_accept(_socket, timeout, &address);
	
	if(socket)
		remoteSocket = [[[WISocket alloc] _initWithSocket:socket address:[[[WIAddress alloc] initWithAddress:address] autorelease]] autorelease];
	else if(error)
		*error = [self _errorWithCode:WISocketListenFailed];
	
	wi_release(pool);
	
	return remoteSocket;
}



- (void)close {
	wi_pool_t		*pool;

	pool = wi_pool_init(wi_pool_alloc());
	wi_socket_close(_socket);
	wi_release(pool);
}



#pragma mark -

- (BOOL)writeString:(NSString *)string encoding:(NSStringEncoding)encoding timeout:(NSTimeInterval)timeout error:(WIError **)error {
	NSData			*data;
	wi_pool_t		*pool;
	BOOL			result = NO;
	
	pool = wi_pool_init(wi_pool_alloc());
	data = [string dataUsingEncoding:encoding];
	
	if(wi_socket_write_buffer(_socket, timeout, [data bytes], [data length]) < 0) {
		if(error)
			*error = [self _errorWithCode:WISocketWriteFailed];
		
		result = NO;
	}
	
	wi_release(pool);
	
	return result;
}



#pragma mark -

- (NSString *)readStringOfLength:(NSUInteger)length encoding:(NSStringEncoding)encoding timeout:(NSTimeInterval)timeout error:(WIError **)error {
	NSMutableString		*string, *substring;
	wi_pool_t			*pool;
	char				buffer[WISocketBufferSize];
	wi_integer_t		bytes = -1;
	
	pool = wi_pool_init(wi_pool_alloc());
	string = [[NSMutableString alloc] initWithCapacity:length];
	
	while(length > sizeof(buffer)) {
		bytes = wi_socket_read_buffer(_socket, timeout, buffer, sizeof(buffer));
		
		if(bytes <= 0)
			goto end;
		
		substring = [[NSMutableString alloc] initWithBytes:buffer length:bytes encoding:encoding];
		
		if(substring) {
			[string appendString:substring];
			[substring release];
			
			length -= bytes;
		}
	}
	
	if(length > 0) {
		do {
			bytes = wi_socket_read_buffer(_socket, timeout, buffer, length);
			
			if(bytes <= 0)
				goto end;
			
			substring = [[NSMutableString alloc] initWithBytes:buffer length:bytes encoding:encoding];
			
			if(substring) {
				[string appendString:substring];
				[substring release];
			}
		} while(!substring);
	}

end:
	if([string length] == 0) {
		if(bytes < 0) {
			if(error) {
				if(wi_error_domain() == WI_ERROR_DOMAIN_ERRNO && wi_error_code() == ETIMEDOUT) {
					if(!_readTimeoutError)
						_readTimeoutError = [[self _errorWithCode:WISocketReadFailed] retain];
					
					*error = _readTimeoutError;
				} else {
					*error = [self _errorWithCode:WISocketReadFailed];
				}
			}
			
			[string release];
			
			string = NULL;
		}
	}
	
	wi_release(pool);
	
	return [string autorelease];
}



- (NSString *)readStringUpToString:(NSString *)separator encoding:(NSStringEncoding)encoding timeout:(NSTimeInterval)timeout error:(WIError **)error {
	NSString		*string, *substring;
	NSUInteger		index;
	
	index = [_buffer rangeOfString:separator].location;
	
	if(index != NSNotFound) {
		substring = [_buffer substringToIndex:index + [separator length]];
		
		[_buffer deleteCharactersInRange:NSMakeRange(0, [substring length])];
		
		return substring;
	}
	
	while((string = [self readStringOfLength:WISocketBufferSize encoding:encoding timeout:timeout error:error])) {
		if([string length] == 0)
			return string;
		
		[_buffer appendString:string];
		
		index = [_buffer rangeOfString:separator].location;
		
		if(index == NSNotFound) {
			if([_buffer length] > _WISocketBufferMaxSize) {
				substring = [_buffer substringToIndex:_WISocketBufferMaxSize];
				
				[_buffer deleteCharactersInRange:NSMakeRange(0, [substring length])];
				
				return substring;
			}
		} else {
			substring = [_buffer substringToIndex:index + [separator length]];
			
			[_buffer deleteCharactersInRange:NSMakeRange(0, [substring length])];
			
			return substring;
		}
	}
	
	return NULL;
}



- (void)scheduleInRunLoop:(NSRunLoop *)runLoop forMode:(NSString *)mode {
	CFSocketContext			context;
	CFSocketCallBackType	type;
	
	if(!_sourceRef) {
		context.version				= 0;
		context.info				= self;
		context.retain				= NULL;
		context.release				= NULL;
		context.copyDescription		= NULL;
		
		type = kCFSocketNoCallBack;
		
		if([self direction] & WISocketRead)
			type |= kCFSocketReadCallBack;

		if([self direction] & WISocketWrite)
			type |= kCFSocketWriteCallBack;
		
		_socketRef = CFSocketCreateWithNative(NULL,
											  wi_socket_descriptor(_socket),
											  type,
											  _WISocketCallback,
											  &context);
        
        // Add support for iOS kCFStreamNetworkServiceTypeVoIP property
        CFStreamCreatePairWithSocket(kCFAllocatorDefault, wi_socket_descriptor(_socket), &_readStream, &_writeStream);
        CFReadStreamSetProperty(_readStream, kCFStreamNetworkServiceType, kCFStreamNetworkServiceTypeVoIP);
        CFWriteStreamSetProperty(_writeStream, kCFStreamNetworkServiceType, kCFStreamNetworkServiceTypeVoIP);
        
		_sourceRef = CFSocketCreateRunLoopSource(NULL, _socketRef, 0);
	}

	CFRunLoopAddSource([runLoop getCFRunLoop], _sourceRef, (CFStringRef) mode);
}



- (void)removeFromRunLoop:(NSRunLoop *)runLoop forMode:(NSString *)mode {
	if(_sourceRef) {
		CFRunLoopRemoveSource([runLoop getCFRunLoop], _sourceRef, (CFStringRef) mode);
		
		if(_sourceRef) {
			CFRelease(_sourceRef);
			_sourceRef = NULL;
		}
		
		if(_socketRef) {
			CFSocketInvalidate(_socketRef);
			CFRelease(_socketRef);
			_socketRef = NULL;
		}
        
        if(_readStream) {
            CFReadStreamClose(_readStream);
            CFRelease(_readStream);
            _readStream = NULL;
        }
        
        if(_writeStream) {
            CFWriteStreamClose(_writeStream);
            CFRelease(_writeStream);
            _writeStream = NULL;
        }
	}
}

@end
