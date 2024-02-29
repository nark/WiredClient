/* $Id$ */

/*
 *  Copyright (c) 2009 Axel Andersson
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

#import <WiredNetworking/NSNumber-WINetworking.h>

@implementation NSNumber(WINetworking)

+ (NSNumber *)numberWithWiredNumber:(wi_number_t *)number {
	if(!number)
		return NULL;
	
	switch(wi_number_type(number)) {
		case WI_NUMBER_BOOL:
			return [[[self alloc] initWithBool:wi_number_bool(number)] autorelease];
			break;

		case WI_NUMBER_CHAR:
			return [[[self alloc] initWithChar:wi_number_char(number)] autorelease];
			break;

		case WI_NUMBER_SHORT:
			return [[[self alloc] initWithShort:wi_number_short(number)] autorelease];
			break;

		case WI_NUMBER_INT:
			return [[[self alloc] initWithInt:wi_number_int(number)] autorelease];
			break;

		case WI_NUMBER_INT8:
		case WI_NUMBER_INT16:
		case WI_NUMBER_INT32:
			return [[[self alloc] initWithInt:wi_number_int32(number)] autorelease];
			break;

		case WI_NUMBER_INT64:
			return [[[self alloc] initWithLongLong:wi_number_int64(number)] autorelease];
			break;

		case WI_NUMBER_LONG:
			return [[[self alloc] initWithLong:wi_number_long(number)] autorelease];
			break;

		case WI_NUMBER_LONG_LONG:
			return [[[self alloc] initWithLongLong:wi_number_long_long(number)] autorelease];
			break;

		case WI_NUMBER_FLOAT:
			return [[[self alloc] initWithFloat:wi_number_float(number)] autorelease];
			break;

		case WI_NUMBER_DOUBLE:
			return [[[self alloc] initWithDouble:wi_number_double(number)] autorelease];
			break;
	}
	
	return NULL;
}



#pragma mark -

- (wi_number_t *)wiredNumber {
	const char		*type;
	
	type = [self objCType];
	
	if(strcmp(type, @encode(BOOL)) == 0)
		return wi_number_with_bool([self boolValue]);
	else if(strcmp(type, @encode(char)) == 0 || strcmp(type, @encode(unsigned char)) == 0)
		return wi_number_with_char([self charValue]);
	else if(strcmp(type, @encode(short)) == 0 || strcmp(type, @encode(unsigned short)) == 0)
		return wi_number_with_short([self shortValue]);
	else if(strcmp(type, @encode(int)) == 0 || strcmp(type, @encode(unsigned int)) == 0)
		return wi_number_with_int([self intValue]);
	else if(strcmp(type, @encode(int32_t)) == 0 || strcmp(type, @encode(uint32_t)) == 0)
		return wi_number_with_int32([self intValue]);
	else if(strcmp(type, @encode(int64_t)) == 0 || strcmp(type, @encode(uint64_t)) == 0)
		return wi_number_with_int64([self longLongValue]);
	else if(strcmp(type, @encode(NSInteger)) == 0 || strcmp(type, @encode(NSUInteger)) == 0)
		return wi_number_with_integer([self integerValue]);
	else if(strcmp(type, @encode(long)) == 0 || strcmp(type, @encode(unsigned long)) == 0)
		return wi_number_with_long([self longValue]);
	else if(strcmp(type, @encode(long long)) == 0 || strcmp(type, @encode(unsigned long long)) == 0)
		return wi_number_with_long_long([self longLongValue]);
	
	return NULL;
}

@end
