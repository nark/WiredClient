/* $Id: WCLink.m 7968 2009-10-18 23:43:10Z morris $ */

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

#import "WLink.h"
#import "WError.h"


@interface WLink(Private)

- (BOOL)_messageLoopWithError:(WIError **)error;

- (void)_schedulePingTimer;
- (void)_invalidatePingTimer;

@end


@implementation WLink(Private)

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
		message = [_p7Socket readMessageWithTimeout:5.0 error:&error];
		[_lock unlock];
		
		if(!message) {
			code = [[[error userInfo] objectForKey:WILibWiredErrorKey] code];
			
			if(code == ETIMEDOUT)
				continue;
			else if(code == WI_ERROR_SOCKET_EOF)
				*outError = [[WError alloc] initWithDomain:WCWiredClientErrorDomain code:WCWiredClientServerDisconnected];
			else
				*outError = [error retain];
			
			break;
		}
		
		if(_delegateLinkReceivedMessage)
			[_delegate performSelectorOnMainThread:@selector(link:receivedMessage:) withObject:self withObject:message];
	}
	
	[pool release];
	
	return NO;
}



#pragma mark -

- (void)_schedulePingTimer {
	_pingTimer = [[NSTimer scheduledTimerWithTimeInterval:60.0
												   target:self
												 selector:@selector(pingTimer:)
												 userInfo:NULL
												  repeats:YES] retain];
}



- (void)_invalidatePingTimer {
	[_pingTimer invalidate];
}

@end


@implementation WLink

- (id)initLinkWithURL:(WIURL *)url p7Spec:(WIP7Spec *)spec {
	self = [super init];
	
	_spec			= [spec retain];
	_url			= [url retain];
	_pingMessage	= [[WIP7Message alloc] initWithName:@"wired.send_ping" spec:_spec];
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
    if(_p7Socket)
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
		
		if([_socket connectWithTimeout:10.0 error:&error]) {
			_p7Socket = [[WIP7Socket alloc] initWithSocket:_socket spec:_spec];

			if([_p7Socket connectWithOptions:WIP7EncryptionRSA_AES256_SHA1 | WIP7ChecksumSHA1 | WIP7CompressionDeflate
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



- (void)pingTimer:(NSTimer *)timer {
	[self sendMessage:_pingMessage];
}

@end
