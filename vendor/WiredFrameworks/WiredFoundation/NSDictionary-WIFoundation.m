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

#import <WiredFoundation/NSDictionary-WIFoundation.h>
#import <WiredFoundation/NSNumber-WIFoundation.h>

@implementation NSDictionary(WIFoundation)

- (int)intForKey:(id)key {
	id	object;
	
	object = [self objectForKey:key];
	
	if(object)
		return [object intValue];
	
	return 0;
}



- (unsigned int)unsignedIntForKey:(id)key {
	id	object;
	
	object = [self objectForKey:key];
	
	if(object)
		return [object unsignedIntValue];
	
	return 0;
}



- (NSInteger)integerForKey:(id)key {
	id	object;
	
	object = [self objectForKey:key];
	
	if(object)
		return [object integerValue];
	
	return 0;
}



- (NSUInteger)unsignedIntegerForKey:(id)key {
	id	object;
	
	object = [self objectForKey:key];
	
	if(object)
		return [object unsignedIntegerValue];
	
	return 0;
}



- (BOOL)boolForKey:(id)key {
	id	object;
	
	object = [self objectForKey:key];
	
	if(object)
		return [object boolValue];
	
	return NO;
}



- (float)floatForKey:(id)key {
	id	object;
	
	object = [self objectForKey:key];
	
	if(object)
		return [object floatValue];
	
	return 0.0f;
}



- (double)doubleForKey:(id)key {
	id	object;
	
	object = [self objectForKey:key];
	
	if(object)
		return [object doubleValue];
	
	return 0.0;
}

@end



@implementation NSMutableDictionary(WIFoundation)

- (void)setInt:(int)value forKey:(id)key {
	[self setObject:[NSNumber numberWithInt:value] forKey:key];
}



- (void)setUnsignedInt:(unsigned int)value forKey:(id)key {
	[self setObject:[NSNumber numberWithUnsignedInt:value] forKey:key];
}



- (void)setInteger:(NSInteger)value forKey:(id)key {
	[self setObject:[NSNumber numberWithInteger:value] forKey:key];
}



- (void)setUnsignedInteger:(NSUInteger)value forKey:(id)key {
	[self setObject:[NSNumber numberWithUnsignedInteger:value] forKey:key];
}



- (void)setBool:(BOOL)value forKey:(id)key {
	[self setObject:[NSNumber numberWithBool:value] forKey:key];
}



- (void)setFloat:(float)value forKey:(id)key {
	[self setObject:[NSNumber numberWithFloat:value] forKey:key];
}



- (void)setDouble:(double)value forKey:(id)key {
	[self setObject:[NSNumber numberWithDouble:value] forKey:key];
}

@end
