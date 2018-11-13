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

@class WISocket, WIError;

@interface WIP7Link : WIObject {
	WISocket				*_socket;
	WIP7Socket				*_p7Socket;
	WIURL					*_url;
	
	NSTimer					*_pingTimer;
	WIP7Message				*_pingMessage;
	
	NSLock					*_lock;
	
	id						_delegate;
	BOOL					_delegateLinkConnected;
	BOOL					_delegateLinkClosed;
	BOOL					_delegateLinkTerminated;
	BOOL					_delegateLinkSentCommand;
	BOOL					_delegateLinkReceivedMessage;
	BOOL					_delegateLinkDisconnectedError;
	BOOL					_delegateLinkCipher;
	BOOL					_delegateLinkCompressionEnabled;
	
	BOOL					_reading;
	BOOL					_closing;
	BOOL					_terminating;
}

- (id)initLinkWithURL:(WIURL *)url;

- (void)setDelegate:(id)delegate;
- (id)delegate;

- (WIURL *)URL;
- (WIP7Socket *)socket;
- (BOOL)isReading;

- (void)connect;
- (void)disconnect;
- (void)terminate;
- (void)sendMessage:(WIP7Message *)message;

@end


@interface NSObject(WIP7LinkDelegate)

- (void)linkConnected:(WIP7Link *)link;
- (void)linkClosed:(WIP7Link *)link error:(WIError *)error;
- (void)linkTerminated:(WIP7Link *)link;
- (void)link:(WIP7Link *)link sentMessage:(WIP7Message *)message;
- (void)link:(WIP7Link *)link receivedMessage:(WIP7Message *)message;

- (WIError *)linkDisconnectedError:(WIP7Link *)link;

- (NSUInteger)linkCipher:(WIP7Link *)link;
- (BOOL)linkCompressionEnabled:(WIP7Link *)link;

@end
