/* $Id$ */

/*
 *  Copyright (c) 2005-2009 Axel Andersson
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

//#import "WCApplicationController.h"
#import "WIP7Connection.h"
#import "WIP7Link.h"
#import "WIP7Socket.h"
#import "WIError.h"
#import "WIAddress.h"
#import "WISocket.h"
#import "WIThread.h"


#define WD_CLIENT_PING_INTERVAL		30.0


@interface WIP7Link(Private)

- (BOOL)_messageLoopWithError:(WIError **)error;

- (void)_schedulePingTimer;
- (void)_invalidatePingTimer;

- (NSUInteger)_TLSOptions;

@end


@implementation WIP7Link(Private)

- (BOOL)_messageLoopWithError:(WIError **)outError {
	NSAutoreleasePool		*pool;
	WIP7Message				*message;
	WIError					*error;
	BOOL					state;
	NSUInteger				i = 0;
	NSInteger				code;
	
	pool = [[NSAutoreleasePool alloc] init];

	while(!_closing && !_terminating) {
		if(++i % 100 == 0) {
			[pool release];
			pool = [[NSAutoreleasePool alloc] init];
		}

		do {
			state = [_socket waitWithTimeout:0.1];
		} while(!state && !_closing && !_terminating);
		
		if(_closing || _terminating)
			break;
		
		[_lock lock];
		message = [_p7Socket readMessageWithTimeout:10.0 error:&error];
		[_lock unlock];
		
		if(!message) {
			code = [[[error userInfo] objectForKey:WILibWiredErrorKey] code];
			
			if(code == ETIMEDOUT)
				continue;
			else if(code == WI_ERROR_SOCKET_EOF) {
				
				if(_delegateLinkDisconnectedError)
					*outError = [[_delegate linkDisconnectedError:self] retain];
				else
					*outError = [[WIError alloc] initWithDomain:WIWiredNetworkingErrorDomain code:WISocketConnectFailed];
				
			} else {
				*outError = [error retain];
			}
			break;
		}
		
		if(_delegateLinkReceivedMessage)
			[_delegate performSelectorOnMainThread:@selector(link:receivedMessage:) withObject:self withObject:message];
	}
	
	[pool release];
	
	return NO;
}



#pragma mark -

- (void)pingTimer:(NSTimer *)timer {
    [self sendMessage:_pingMessage];
}

- (void)_schedulePingTimer {
	_pingTimer = [[NSTimer scheduledTimerWithTimeInterval:WD_CLIENT_PING_INTERVAL
												   target:self
												 selector:@selector(pingTimer:)
												 userInfo:NULL
												  repeats:YES] retain];
}



- (void)_invalidatePingTimer {
	[_pingTimer invalidate];
}


#pragma mark - 

- (NSUInteger)_TLSOptions {
    NSUInteger options = 0;
    NSInteger cipherTag = -1;
    
	if(_delegateLinkCipher)
        cipherTag = [_delegate linkCipher:self];
    
	if(_delegateLinkCompressionEnabled)
		if([_delegate linkCompressionEnabled:self])
			options = options | WIP7CompressionDeflate;
    
    if(cipherTag != -1) {
        switch (cipherTag) {
            case 0: options = options | WIP7EncryptionRSA_AES128_SHA1; break;
            case 1: options = options | WIP7EncryptionRSA_AES192_SHA1;  break;
            case 2: options = options | WIP7EncryptionRSA_AES256_SHA1; break;
            case 3: options = options | WIP7EncryptionRSA_BF128_SHA1; break;
            case 4: options = options | WIP7EncryptionRSA_3DES192_SHA1; break;
            case 5: options = options | WIP7EncryptionRSA_AES256_SHA256; break;
        }
    } else {
       options = options | WIP7EncryptionRSA_AES256_SHA1;
    }
    
    options = options | WIP7ChecksumSHA1;
    
    return options;
}



@end


@implementation WIP7Link

- (id)initLinkWithURL:(WIURL *)url {
	self = [super init];
	
	_url			= [url retain];
	_pingMessage	= [[WIP7Message alloc] initWithName:@"wired.send_ping" spec:WCP7Spec];
	_lock			= [[NSLock alloc] init];
	
	return self;
}



- (void)dealloc {
	[_url release];
	[_pingTimer release];
	[_pingMessage release];
	[_lock release];
	
	[super dealloc];
}



#pragma mark -

- (void)setDelegate:(id)delegate {
	_delegate						= delegate;
	
	_delegateLinkConnected			= [_delegate respondsToSelector:@selector(linkConnected:)];
	_delegateLinkClosed				= [_delegate respondsToSelector:@selector(linkClosed:error:)];
	_delegateLinkTerminated			= [_delegate respondsToSelector:@selector(linkTerminated:)];
	_delegateLinkSentCommand		= [_delegate respondsToSelector:@selector(link:sentMessage:)];
	_delegateLinkReceivedMessage	= [_delegate respondsToSelector:@selector(link:receivedMessage:)];
	_delegateLinkDisconnectedError	= [_delegate respondsToSelector:@selector(linkDisconnectedError:)];
	_delegateLinkCipher				= [_delegate respondsToSelector:@selector(linkCipher:)];
	_delegateLinkCompressionEnabled = [_delegate respondsToSelector:@selector(linkCompressionEnabled:)];
}



- (id)delegate {
	return _delegate;
}



#pragma mark -

- (WIURL *)URL {
	return _url;
}



- (WIP7Socket *)socket {
	return _p7Socket;
}



- (BOOL)isReading {
	return _reading;
}



#pragma mark -

- (void)connect {
	_reading = YES;
	_terminating = NO;
	
	[WIThread detachNewThreadSelector:@selector(linkThread:) toTarget:self withObject:NULL];
}



- (void)disconnect {
	_closing = YES;
	_reading = NO;
}



- (void)terminate {
	_terminating = YES;
	_reading = NO;
}



- (void)sendMessage:(WIP7Message *)message {
	[_lock lock];
	[_p7Socket writeMessage:message timeout:0.0 error:NULL];
	[_lock unlock];
	
	if(_delegateLinkSentCommand)
		[_delegate link:self sentMessage:message];
}



#pragma mark -

- (void)linkThread:(id)arg {
	NSAutoreleasePool	*pool, *loopPool = NULL;
	WIError				*error = NULL;
	WIAddress			*address;

	pool = [[NSAutoreleasePool alloc] init];
	
	address = [WIAddress addressWithString:[_url host] error:&error];
	
	if(address) {
		[address setPort:[_url port]];

		_socket = [[WISocket alloc] initWithAddress:address type:WISocketTCP];
		[_socket setInteractive:YES];
		[_socket setDirection:WISocketRead];
		
		if([_socket connectWithTimeout:30.0 error:&error]) {
			_p7Socket = [[WIP7Socket alloc] initWithSocket:_socket spec:WCP7Spec];
            
            NSUInteger options = [self _TLSOptions];

			if([_p7Socket connectWithOptions:options
							   serialization:WIP7Binary
									username:[_url user]
									password:[[_url password] SHA1]
									 timeout:30.0
									   error:&error]) {
				if(_delegateLinkConnected)
					[_delegate performSelectorOnMainThread:@selector(linkConnected:) withObject:self];
				
				[self performSelectorOnMainThread:@selector(_schedulePingTimer)];

				[self _messageLoopWithError:&error];

				[self performSelectorOnMainThread:@selector(_invalidatePingTimer)];
			}
		}
	}
	
	if(_terminating) {
		if(_delegateLinkTerminated)
			[_delegate performSelectorOnMainThread:@selector(linkTerminated:) withObject:self waitUntilDone:YES];
	} else {
		if(_delegateLinkClosed)
			[_delegate performSelectorOnMainThread:@selector(linkClosed:error:) withObject:self withObject:error waitUntilDone:YES];
	}
	
	_reading = NO;
	
	[_lock lock];

	[_p7Socket release];
	[_socket release];
	
	_p7Socket = NULL;
	_socket = NULL;
	
	[_lock unlock];
	
	[loopPool release];
	[pool release];
}

@end
