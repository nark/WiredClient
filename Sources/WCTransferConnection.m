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

#import "WCServerConnection.h"
#import "WCTransfer.h"
#import "WCTransferConnection.h"

@interface WCTransferConnection(Private)

- (id)_initWithTransfer:(WCTransfer *)transfer;

@end


@implementation WCTransferConnection(Private)

- (id)_initWithTransfer:(WCTransfer *)transfer {
	self = [super init];
	
	_transfer = [transfer retain];
	
	return self;
}

@end



@implementation WCTransferConnection

+ (id)connectionWithTransfer:(WCTransfer *)transfer {
	return [[[self alloc] _initWithTransfer:transfer] autorelease];
}



- (void)dealloc {
	[_socket release];
	[_p7Socket release];
	[_transfer release];
	
	[super dealloc];
}



#pragma mark -

- (BOOL)connectWithTimeout:(NSTimeInterval)timeout error:(WCError **)error {
	WIAddress		*address;
	
	address = [WIAddress addressWithString:[[self URL] host] error:error];
	
	if(!address)
		return NO;
	
	[address setPort:[[self URL] port]];

	_socket = [[WISocket alloc] initWithAddress:address type:WISocketTCP];
	[_socket setInteractive:YES];
	
	if(![_socket connectWithTimeout:timeout error:error])
		return NO;

	_p7Socket = [[WIP7Socket alloc] initWithSocket:_socket spec:WCP7Spec];
	
	if(![_p7Socket connectWithOptions:WIP7EncryptionRSA_AES256_SHA1 | WIP7ChecksumSHA1
						serialization:WIP7Binary
							 username:[[self URL] user]
							 password:[[[self URL] password] SHA1]
							  timeout:timeout
								error:error]) {
		return NO;
	}

	return YES;
}



- (void)disconnect {
	[_p7Socket close];
	[_socket close];
}



- (BOOL)writeMessage:(WIP7Message *)message timeout:(NSTimeInterval)timeout error:(WIError **)error {
	if([_p7Socket writeMessage:message timeout:timeout error:error]) {
		[[_transfer connection] postNotificationName:WCLinkConnectionSentMessageNotification object:message];

		return YES;
	}
	
	return NO;
}



- (WIP7Message *)readMessageWithTimeout:(NSTimeInterval)timeout error:(WIError **)error {
	WIP7Message		*message;
	
	message = [_p7Socket readMessageWithTimeout:timeout error:error];
	
	if(!message)
		return NULL;
	
	if([_p7Socket verifyMessage:message error:error]) {
		if([[message name] isEqualToString:@"wired.error"])
			[[_transfer connection] postNotificationName:WCLinkConnectionReceivedErrorMessageNotification object:message];
		else
			[[_transfer connection] postNotificationName:WCLinkConnectionReceivedMessageNotification object:message];
		
		return message;
	} else {
		[[_transfer connection] postNotificationName:WCLinkConnectionReceivedInvalidMessageNotification
											  object:message
											userInfo:[NSDictionary dictionaryWithObject:*error forKey:@"WCError"]];
		
		return NULL;
	}
}



#pragma mark -

- (WCTransfer *)transfer {
	return _transfer;
}



- (WIP7Socket *)socket {
	return _p7Socket;
}

@end
