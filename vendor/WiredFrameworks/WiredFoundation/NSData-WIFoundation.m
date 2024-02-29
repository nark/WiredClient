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

#import <WiredFoundation/NSData-WIFoundation.h>
#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonHMAC.h>

NSString * const kCommonCryptoErrorDomain = @"CommonCryptoErrorDomain";


@implementation NSError (CommonCryptoErrorDomain)

+ (NSError *) errorWithCCCryptorStatus: (CCCryptorStatus) status
{
	NSString * description = nil, * reason = nil;
    
	switch ( status )
	{
		case kCCSuccess:
			description = NSLocalizedString(@"Success", @"Error description");
			break;
            
		case kCCParamError:
			description = NSLocalizedString(@"Parameter Error", @"Error description");
			reason = NSLocalizedString(@"Illegal parameter supplied to encryption/decryption algorithm", @"Error reason");
			break;
            
		case kCCBufferTooSmall:
			description = NSLocalizedString(@"Buffer Too Small", @"Error description");
			reason = NSLocalizedString(@"Insufficient buffer provided for specified operation", @"Error reason");
			break;
            
		case kCCMemoryFailure:
			description = NSLocalizedString(@"Memory Failure", @"Error description");
			reason = NSLocalizedString(@"Failed to allocate memory", @"Error reason");
			break;
            
		case kCCAlignmentError:
			description = NSLocalizedString(@"Alignment Error", @"Error description");
			reason = NSLocalizedString(@"Input size to encryption algorithm was not aligned correctly", @"Error reason");
			break;
            
		case kCCDecodeError:
			description = NSLocalizedString(@"Decode Error", @"Error description");
			reason = NSLocalizedString(@"Input data did not decode or decrypt correctly", @"Error reason");
			break;
            
		case kCCUnimplemented:
			description = NSLocalizedString(@"Unimplemented Function", @"Error description");
			reason = NSLocalizedString(@"Function not implemented for the current algorithm", @"Error reason");
			break;
            
		default:
			description = NSLocalizedString(@"Unknown Error", @"Error description");
			break;
	}
    
	NSMutableDictionary * userInfo = [[NSMutableDictionary alloc] init];
	[userInfo setObject: description forKey: NSLocalizedDescriptionKey];
    
	if ( reason != nil )
		[userInfo setObject: reason forKey: NSLocalizedFailureReasonErrorKey];
    
	NSError * result = [NSError errorWithDomain: kCommonCryptoErrorDomain code: status userInfo: userInfo];
	[userInfo release];
    
	return ( result );
}

@end


@implementation NSData(WIDataChecksum)

+ (NSData *)dataWithBase64EncodedString:(NSString *)string {
	NSMutableData			*mutableData;
	NSData					*data;
	const unsigned char		*buffer;
	unsigned char			ch, inbuffer[4], outbuffer[3];
	NSUInteger				i, length, count, position, offset;
	BOOL					ignore, stop, end;
	
	data = [string dataUsingEncoding:NSASCIIStringEncoding];
	length = [data length];
	position = offset = 0;
	buffer = [data bytes];
	mutableData = [NSMutableData dataWithCapacity:length];
	
	while(position < length) {
		ignore = end = NO;
		ch = buffer[position++];
		
		if(ch >= 'A' && ch <= 'Z')
			ch = ch - 'A';
		else if(ch >= 'a' && ch <= 'z')
			ch = ch - 'a' + 26;
		else if(ch >= '0' && ch <= '9')
			ch = ch - '0' + 52;
		else if(ch == '+')
			ch = 62;
		else if(ch == '=')
			end = YES;
		else if(ch == '/')
			ch = 63;
		else
			ignore = YES;
		
		if(!ignore) {
			count = 3;
			stop = NO;
			
			if(end) {
				if(offset == 0)
					break;
				else if(offset == 1 || offset == 2)
					count = 1;
				else
					count = 2;
				
				offset = 3;
				stop = YES;
			}
			
			inbuffer[offset++] = ch;
			
			if(offset == 4) {
				outbuffer[0] =  (inbuffer[0]         << 2) | ((inbuffer[1] & 0x30) >> 4);
				outbuffer[1] = ((inbuffer[1] & 0x0F) << 4) | ((inbuffer[2] & 0x3C) >> 2);
				outbuffer[2] = ((inbuffer[2] & 0x03) << 6) |  (inbuffer[3] & 0x3F);
				
				for(i = 0; i < count; i++)
					[mutableData appendBytes:&outbuffer[i] length:1];

				offset = 0;
			}
			
			if(stop)
				break;
		}
	}
	
	return mutableData;
}



- (NSString *)base64EncodedString {
	NSMutableString			*string;
	const unsigned char		*buffer;
	unsigned char			inbuffer[3], outbuffer[4];
	NSUInteger				i, count, length, position, remaining;
	static char				table[] =
		"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
	
	length = [self length];
	buffer = [self bytes];
	position = 0;
	string = [NSMutableString stringWithCapacity:(NSUInteger) (length * (4.0f / 3.0f)) + 4];
	
	while(position < length) {
		for(i = 0; i < 3; i++) {
			if(position + i < length)
				inbuffer[i] = buffer[position + i];
			else
				inbuffer[i] = '\0';
		}
		
		outbuffer[0] =  (inbuffer[0] & 0xFC) >> 2;
		outbuffer[1] = ((inbuffer[0] & 0x03) << 4) | ((inbuffer[1] & 0xF0) >> 4);
		outbuffer[2] = ((inbuffer[1] & 0x0F) << 2) | ((inbuffer[2] & 0xC0) >> 6);
		outbuffer[3] =   inbuffer[2] & 0x3F;
		
		remaining = length - position;
		
		if(remaining == 1)
			count = 2;
		else if(remaining == 2)
			count = 3;
		else
			count = 4;
		
		for(i = 0; i < count; i++)
			[string appendFormat:@"%c", table[outbuffer[i]]];
		
		for(i = count; i < 4; i++)
			[string appendFormat:@"%c", '='];
		
		position += 3;
	}
	
	return string;
}



#pragma mark -

- (NSString *)SHA1 {
	CC_SHA1_CTX				c;
	static unsigned char	hex[] = "0123456789abcdef";
	unsigned char			sha[CC_SHA1_DIGEST_LENGTH];
	char					text[CC_SHA1_DIGEST_LENGTH * 2 + 1];
	NSUInteger				i;

	CC_SHA1_Init(&c);
	CC_SHA1_Update(&c, [self bytes], (CC_LONG)[self length]);
	CC_SHA1_Final(sha, &c);

	for(i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
		text[i + i]			= hex[sha[i] >> 4];
		text[i + i + 1]		= hex[sha[i] & 0x0F];
	}

	text[i + i] = '\0';

	return [NSString stringWithUTF8String:text];
}

@end



#pragma mark -

@implementation NSData (CommonDigest)

- (NSData *) MD2Sum
{
	unsigned char hash[CC_MD2_DIGEST_LENGTH];
	(void) CC_MD2( [self bytes], (CC_LONG)[self length], hash );
	return ( [NSData dataWithBytes: hash length: CC_MD2_DIGEST_LENGTH] );
}

- (NSData *) MD4Sum
{
	unsigned char hash[CC_MD4_DIGEST_LENGTH];
	(void) CC_MD4( [self bytes], (CC_LONG)[self length], hash );
	return ( [NSData dataWithBytes: hash length: CC_MD4_DIGEST_LENGTH] );
}

- (NSData *) MD5Sum
{
	unsigned char hash[CC_MD5_DIGEST_LENGTH];
	(void) CC_MD5( [self bytes], (CC_LONG)[self length], hash );
	return ( [NSData dataWithBytes: hash length: CC_MD5_DIGEST_LENGTH] );
}

- (NSData *) SHA1Hash
{
	unsigned char hash[CC_SHA1_DIGEST_LENGTH];
	(void) CC_SHA1( [self bytes], (CC_LONG)[self length], hash );
	return ( [NSData dataWithBytes: hash length: CC_SHA1_DIGEST_LENGTH] );
}

- (NSData *) SHA224Hash
{
	unsigned char hash[CC_SHA224_DIGEST_LENGTH];
	(void) CC_SHA224( [self bytes], (CC_LONG)[self length], hash );
	return ( [NSData dataWithBytes: hash length: CC_SHA224_DIGEST_LENGTH] );
}

- (NSData *) SHA256Hash
{
	unsigned char hash[CC_SHA256_DIGEST_LENGTH];
	(void) CC_SHA256( [self bytes], (CC_LONG)[self length], hash );
	return ( [NSData dataWithBytes: hash length: CC_SHA256_DIGEST_LENGTH] );
}

- (NSData *) SHA384Hash
{
	unsigned char hash[CC_SHA384_DIGEST_LENGTH];
	(void) CC_SHA384( [self bytes], (CC_LONG)[self length], hash );
	return ( [NSData dataWithBytes: hash length: CC_SHA384_DIGEST_LENGTH] );
}

- (NSData *) SHA512Hash
{
	unsigned char hash[CC_SHA512_DIGEST_LENGTH];
	(void) CC_SHA512( [self bytes], (CC_LONG)[self length], hash );
	return ( [NSData dataWithBytes: hash length: CC_SHA512_DIGEST_LENGTH] );
}

@end

@implementation NSData (CommonCryptor)

- (NSData *) AES256EncryptedDataUsingKey: (id) key error: (NSError **) error
{
	CCCryptorStatus status = kCCSuccess;
	NSData * result = [self dataEncryptedUsingAlgorithm: kCCAlgorithmAES128
													key: key
                                                options: kCCOptionPKCS7Padding
												  error: &status];
    
	if ( result != nil )
		return ( result );
    
	if ( error != NULL )
		*error = [NSError errorWithCCCryptorStatus: status];
    
	return ( nil );
}

- (NSData *) decryptedAES256DataUsingKey: (id) key error: (NSError **) error
{
	CCCryptorStatus status = kCCSuccess;
	NSData * result = [self decryptedDataUsingAlgorithm: kCCAlgorithmAES128
													key: key
                                                options: kCCOptionPKCS7Padding
												  error: &status];
    
	if ( result != nil )
		return ( result );
    
	if ( error != NULL )
		*error = [NSError errorWithCCCryptorStatus: status];
    
	return ( nil );
}

- (NSData *) DESEncryptedDataUsingKey: (id) key error: (NSError **) error
{
	CCCryptorStatus status = kCCSuccess;
	NSData * result = [self dataEncryptedUsingAlgorithm: kCCAlgorithmDES
													key: key
                                                options: kCCOptionPKCS7Padding
												  error: &status];
    
	if ( result != nil )
		return ( result );
    
	if ( error != NULL )
		*error = [NSError errorWithCCCryptorStatus: status];
    
	return ( nil );
}

- (NSData *) decryptedDESDataUsingKey: (id) key error: (NSError **) error
{
	CCCryptorStatus status = kCCSuccess;
	NSData * result = [self decryptedDataUsingAlgorithm: kCCAlgorithmDES
													key: key
                                                options: kCCOptionPKCS7Padding
												  error: &status];
    
	if ( result != nil )
		return ( result );
    
	if ( error != NULL )
		*error = [NSError errorWithCCCryptorStatus: status];
    
	return ( nil );
}

- (NSData *) CASTEncryptedDataUsingKey: (id) key error: (NSError **) error
{
	CCCryptorStatus status = kCCSuccess;
	NSData * result = [self dataEncryptedUsingAlgorithm: kCCAlgorithmCAST
													key: key
                                                options: kCCOptionPKCS7Padding
												  error: &status];
    
	if ( result != nil )
		return ( result );
    
	if ( error != NULL )
		*error = [NSError errorWithCCCryptorStatus: status];
    
	return ( nil );
}

- (NSData *) decryptedCASTDataUsingKey: (id) key error: (NSError **) error
{
	CCCryptorStatus status = kCCSuccess;
	NSData * result = [self decryptedDataUsingAlgorithm: kCCAlgorithmCAST
													key: key
                                                options: kCCOptionPKCS7Padding
												  error: &status];
    
	if ( result != nil )
		return ( result );
    
	if ( error != NULL )
		*error = [NSError errorWithCCCryptorStatus: status];
    
	return ( nil );
}

@end

static void FixKeyLengths( CCAlgorithm algorithm, NSMutableData * keyData, NSMutableData * ivData )
{
	NSUInteger keyLength = [keyData length];
	switch ( algorithm )
	{
		case kCCAlgorithmAES128:
		{
			if ( keyLength <= 16 )
			{
				[keyData setLength: 16];
			}
			else if ( keyLength <= 24 )
			{
				[keyData setLength: 24];
			}
			else
			{
				[keyData setLength: 32];
			}
            
			break;
		}
            
		case kCCAlgorithmDES:
		{
			[keyData setLength: 8];
			break;
		}
            
		case kCCAlgorithm3DES:
		{
			[keyData setLength: 24];
			break;
		}
            
		case kCCAlgorithmCAST:
		{
			if ( keyLength <= 5 )
			{
				[keyData setLength: 5];
			}
			else if ( keyLength > 16 )
			{
				[keyData setLength: 16];
			}
            
			break;
		}
            
		case kCCAlgorithmRC4:
		{
			if ( keyLength > 512 )
				[keyData setLength: 512];
			break;
		}
            
		default:
			break;
	}
    
	[ivData setLength: [keyData length]];
}

@implementation NSData (LowLevelCommonCryptor)

- (NSData *) _runCryptor: (CCCryptorRef) cryptor result: (CCCryptorStatus *) status
{
	size_t bufsize = CCCryptorGetOutputLength( cryptor, (size_t)[self length], true );
	void * buf = malloc( bufsize );
	size_t bufused = 0;
    size_t bytesTotal = 0;
	*status = CCCryptorUpdate( cryptor, [self bytes], (size_t)[self length],
							  buf, bufsize, &bufused );
	if ( *status != kCCSuccess )
	{
		free( buf );
		return ( nil );
	}
    
    bytesTotal += bufused;
    
	// From Brent Royal-Gordon (Twitter: architechies):
	//  Need to update buf ptr past used bytes when calling CCCryptorFinal()
	*status = CCCryptorFinal( cryptor, buf + bufused, bufsize - bufused, &bufused );
	if ( *status != kCCSuccess )
	{
		free( buf );
		return ( nil );
	}
    
    bytesTotal += bufused;
    
	return ( [NSData dataWithBytesNoCopy: buf length: bytesTotal] );
}

- (NSData *) dataEncryptedUsingAlgorithm: (CCAlgorithm) algorithm
									 key: (id) key
								   error: (CCCryptorStatus *) error
{
	return ( [self dataEncryptedUsingAlgorithm: algorithm
										   key: key
                          initializationVector: nil
									   options: 0
										 error: error] );
}

- (NSData *) dataEncryptedUsingAlgorithm: (CCAlgorithm) algorithm
									 key: (id) key
                                 options: (CCOptions) options
								   error: (CCCryptorStatus *) error
{
    return ( [self dataEncryptedUsingAlgorithm: algorithm
										   key: key
                          initializationVector: nil
									   options: options
										 error: error] );
}

- (NSData *) dataEncryptedUsingAlgorithm: (CCAlgorithm) algorithm
									 key: (id) key
					initializationVector: (id) iv
								 options: (CCOptions) options
								   error: (CCCryptorStatus *) error
{
	CCCryptorRef cryptor = NULL;
	CCCryptorStatus status = kCCSuccess;
    
	NSParameterAssert([key isKindOfClass: [NSData class]] || [key isKindOfClass: [NSString class]]);
	NSParameterAssert(iv == nil || [iv isKindOfClass: [NSData class]] || [iv isKindOfClass: [NSString class]]);
    
	NSMutableData * keyData, * ivData;
	if ( [key isKindOfClass: [NSData class]] )
		keyData = (NSMutableData *) [key mutableCopy];
	else
		keyData = [[key dataUsingEncoding: NSUTF8StringEncoding] mutableCopy];
    
	if ( [iv isKindOfClass: [NSString class]] )
		ivData = [[iv dataUsingEncoding: NSUTF8StringEncoding] mutableCopy];
	else
		ivData = (NSMutableData *) [iv mutableCopy];	// data or nil
    
	[keyData autorelease];
	[ivData autorelease];
    
	// ensure correct lengths for key and iv data, based on algorithms
	FixKeyLengths( algorithm, keyData, ivData );
    
	status = CCCryptorCreate( kCCEncrypt, algorithm, options,
                             [keyData bytes], [keyData length], [ivData bytes],
                             &cryptor );
    
	if ( status != kCCSuccess )
	{
		if ( error != NULL )
			*error = status;
		return ( nil );
	}
    
	NSData * result = [self _runCryptor: cryptor result: &status];
	if ( (result == nil) && (error != NULL) )
		*error = status;
    
	CCCryptorRelease( cryptor );
    
	return ( result );
}

- (NSData *) decryptedDataUsingAlgorithm: (CCAlgorithm) algorithm
									 key: (id) key		// data or string
								   error: (CCCryptorStatus *) error
{
	return ( [self decryptedDataUsingAlgorithm: algorithm
										   key: key
						  initializationVector: nil
									   options: 0
										 error: error] );
}

- (NSData *) decryptedDataUsingAlgorithm: (CCAlgorithm) algorithm
									 key: (id) key		// data or string
                                 options: (CCOptions) options
								   error: (CCCryptorStatus *) error
{
    return ( [self decryptedDataUsingAlgorithm: algorithm
										   key: key
						  initializationVector: nil
									   options: options
										 error: error] );
}

- (NSData *) decryptedDataUsingAlgorithm: (CCAlgorithm) algorithm
									 key: (id) key		// data or string
					initializationVector: (id) iv		// data or string
								 options: (CCOptions) options
								   error: (CCCryptorStatus *) error
{
	CCCryptorRef cryptor = NULL;
	CCCryptorStatus status = kCCSuccess;
    
	NSParameterAssert([key isKindOfClass: [NSData class]] || [key isKindOfClass: [NSString class]]);
	NSParameterAssert(iv == nil || [iv isKindOfClass: [NSData class]] || [iv isKindOfClass: [NSString class]]);
    
	NSMutableData * keyData, * ivData;
	if ( [key isKindOfClass: [NSData class]] )
		keyData = (NSMutableData *) [key mutableCopy];
	else
		keyData = [[key dataUsingEncoding: NSUTF8StringEncoding] mutableCopy];
    
	if ( [iv isKindOfClass: [NSString class]] )
		ivData = [[iv dataUsingEncoding: NSUTF8StringEncoding] mutableCopy];
	else
		ivData = (NSMutableData *) [iv mutableCopy];	// data or nil
    
	[keyData autorelease];
	[ivData autorelease];
    
	// ensure correct lengths for key and iv data, based on algorithms
	FixKeyLengths( algorithm, keyData, ivData );
    
	status = CCCryptorCreate( kCCDecrypt, algorithm, options,
                             [keyData bytes], [keyData length], [ivData bytes],
                             &cryptor );
    
	if ( status != kCCSuccess )
	{
		if ( error != NULL )
			*error = status;
		return ( nil );
	}
    
	NSData * result = [self _runCryptor: cryptor result: &status];
	if ( (result == nil) && (error != NULL) )
		*error = status;
    
	CCCryptorRelease( cryptor );
    
	return ( result );
}

@end

@implementation NSData (CommonHMAC)

- (NSData *) HMACWithAlgorithm: (CCHmacAlgorithm) algorithm
{
	return ( [self HMACWithAlgorithm: algorithm key: nil] );
}

- (NSData *) HMACWithAlgorithm: (CCHmacAlgorithm) algorithm key: (id) key
{
	NSParameterAssert(key == nil || [key isKindOfClass: [NSData class]] || [key isKindOfClass: [NSString class]]);
    
	NSData * keyData = nil;
	if ( [key isKindOfClass: [NSString class]] )
		keyData = [key dataUsingEncoding: NSUTF8StringEncoding];
	else
		keyData = (NSData *) key;
    
	// this could be either CC_SHA1_DIGEST_LENGTH or CC_MD5_DIGEST_LENGTH. SHA1 is larger.
	unsigned char buf[CC_SHA1_DIGEST_LENGTH];
	CCHmac( algorithm, [keyData bytes], [keyData length], [self bytes], [self length], buf );
    
	return ( [NSData dataWithBytes: buf length: (algorithm == kCCHmacAlgMD5 ? CC_MD5_DIGEST_LENGTH : CC_SHA1_DIGEST_LENGTH)] );
}

@end