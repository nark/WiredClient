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

#import <WiredNetworking/WIP7Message.h>

enum _WIP7Options {
	WIP7CompressionDeflate						= WI_P7_COMPRESSION_DEFLATE,
	WIP7EncryptionRSA_AES128_SHA1				= WI_P7_ENCRYPTION_RSA_AES128_SHA1,
	WIP7EncryptionRSA_AES192_SHA1				= WI_P7_ENCRYPTION_RSA_AES192_SHA1,
	WIP7EncryptionRSA_AES256_SHA1				= WI_P7_ENCRYPTION_RSA_AES256_SHA1,
	WIP7EncryptionRSA_BF128_SHA1				= WI_P7_ENCRYPTION_RSA_BF128_SHA1,
	WIP7EncryptionRSA_3DES192_SHA1				= WI_P7_ENCRYPTION_RSA_3DES192_SHA1,
    WIP7EncryptionRSA_AES256_SHA256				= WI_P7_ENCRYPTION_RSA_AES256_SHA256,
	WIP7ChecksumSHA1							= WI_P7_CHECKSUM_SHA1,
    WIP7ChecksumSHA256							= WI_P7_CHECKSUM_SHA256,
	WIP7All										= WI_P7_ALL
};
typedef enum _WIP7Options						WIP7Options;


@class WIError, WIP7Message, WIP7Spec, WISocket;

@interface WIP7Socket : WIObject {
	id											delegate;
	
	WISocket									*_socket;
	WIP7Spec									*_spec;
	
	WIError										*_readTimeoutError;
	
	wi_p7_socket_t								*_p7Socket;
}

- (id)initWithSocket:(WISocket *)socket spec:(WIP7Spec *)spec;

- (void)setDelegate:(id)delegate;
- (id)delegate;

- (WISocket *)socket;
- (wi_p7_socket_t *)P7Socket;
- (WIP7Spec *)spec;
- (NSUInteger)options;
- (WIP7Serialization)serialization;
- (NSString *)remoteProtocolName;
- (NSString *)remoteProtocolVersion;
- (BOOL)usesEncryption;
- (NSString *)cipherName;
- (NSUInteger)cipherBits;
- (BOOL)usesCompression;
- (double)compressionRatio;

- (BOOL)verifyMessage:(WIP7Message *)message error:(WIError **)error;

- (BOOL)connectWithOptions:(NSUInteger)options serialization:(WIP7Serialization)serialization username:(NSString *)username password:(NSString *)password timeout:(NSTimeInterval)timeout error:(WIError **)error;
- (BOOL)acceptWithOptions:(NSUInteger)options timeout:(NSTimeInterval)timeout error:(WIError **)error;
- (void)close;

- (BOOL)writeMessage:(WIP7Message *)message timeout:(NSTimeInterval)timeout error:(WIError **)error;
- (WIP7Message *)readMessageWithTimeout:(NSTimeInterval)timeout error:(WIError **)error;
- (BOOL)writeOOBData:(const void *)data length:(NSUInteger)length timeout:(NSTimeInterval)timeout error:(WIError **)error;
- (NSInteger)readOOBData:(void **)data timeout:(NSTimeInterval)timeout error:(WIError **)error;

@end


@interface NSObject(WIP7SocketDelegate)

- (void)P7Socket:(WIP7Socket *)socket readMessage:(WIP7Message *)message;
- (void)P7Socket:(WIP7Socket *)socket wroteMessage:(WIP7Message *)message;

@end
