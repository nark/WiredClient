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

#import <WiredFoundation/NSArray-WIFoundation.h>
#import <objc/message.h>

@implementation NSArray(WIFoundation)

- (NSString *)stringAtIndex:(NSUInteger)index {
	if(index < [self count])
		return [self objectAtIndex:index];
	
	return @"";
}



- (id)safeObjectAtIndex:(NSUInteger)index {
	if(index < [self count])
		return [self objectAtIndex:index];
	
	return NULL;
}



#pragma mark -

- (NSUInteger)indexOfString:(NSString *)string {
	return [self indexOfString:string options:0];
}



- (NSUInteger)indexOfString:(NSString *)string options:(NSUInteger)options {
	NSEnumerator	*enumerator;
	NSRange			range;
	id				object;
	NSUInteger		i = 0;

	enumerator = [self objectEnumerator];

	while((object = [enumerator nextObject])) {
		if([object isKindOfClass:[NSString class]]) {
			range = [object rangeOfString:string options:options];
			
			if(range.location != NSNotFound)
				return i;
		}
		
		i++;
	}

	return NSNotFound;
}



- (BOOL)containsString:(NSString *)string {
	return ([self indexOfString:string options:0] != NSNotFound);
}



- (BOOL)containsString:(NSString *)string options:(NSUInteger)options {
	return ([self indexOfString:string options:options] != NSNotFound);
}



- (NSArray *)stringsMatchingString:(NSString *)string {
	return [self stringsMatchingString:string options:0];
}



- (NSArray *)stringsMatchingString:(NSString *)string options:(NSUInteger)options {
	NSEnumerator	*enumerator;
	NSMutableArray	*array;
	NSRange			range;
	id				object;
	
	array = [NSMutableArray array];
	enumerator = [self objectEnumerator];
	
	while((object = [enumerator nextObject])) {
		if([object isKindOfClass:[NSString class]]) {
			range = [object rangeOfString:string options:options];
			
			if(range.location != NSNotFound)
				[array addObject:object];
		}
	}
	
	return array;
}


- (void)makeObjectsPerformSelector:(SEL)selector withObject:(id)object1 withObject:(id)object2 {
	NSEnumerator	*enumerator;
	id				object;

	enumerator = [self objectEnumerator];

	while((object = [enumerator nextObject]))
		objc_msgSend(object, selector, object1, object2);
}



- (void)makeObjectsPerformSelector:(SEL)selector withBool:(BOOL)value {
	NSEnumerator	*enumerator;
	id				object;

	enumerator = [self objectEnumerator];

	while((object = [enumerator nextObject]))
		objc_msgSend(object, selector, value);
}



- (NSArray *)subarrayToIndex:(NSUInteger)index {
	return [self subarrayWithRange:NSMakeRange(0, index)];
}



- (NSArray *)subarrayFromIndex:(NSUInteger)index {
	return [self subarrayWithRange:NSMakeRange(index, [self count] - index)];
}



- (NSArray *)reversedArray {
	NSEnumerator	*enumerator;
	NSMutableArray  *array;
	id				object;
	
	array = [NSMutableArray array];
	enumerator = [self reverseObjectEnumerator];
	
	while((object = [enumerator nextObject]))
		[array addObject:object];

	return array;
}



- (NSArray *)shuffledArray {
	NSMutableArray		*array;
	NSUInteger			i, count;
	
	array = [self mutableCopy];
	count = [array count];
	
	for(i = 0; i < count; i++)
		[array moveObjectAtIndex:i toIndex:random() % count];
	
	return [array autorelease];
}



#pragma mark -


- (NSNumber *)minimumNumber {
	NSEnumerator	*enumerator;
	NSNumber		*number = NULL;
	id				object;
	
	enumerator = [self objectEnumerator];
	
	while((object = [enumerator nextObject])) {
		if([object isKindOfClass:[NSNumber class]]) {
			if(!number || [object unsignedLongLongValue] < [number unsignedLongLongValue])
				number = object;
		}
	}
	
	return number;
}



- (NSNumber *)maximumNumber {
	NSEnumerator	*enumerator;
	NSNumber		*number = NULL;
	id				object;
	
	enumerator = [self objectEnumerator];
	
	while((object = [enumerator nextObject])) {
		if([object isKindOfClass:[NSNumber class]]) {
			if(!number || [object unsignedLongLongValue] > [number unsignedLongLongValue])
				number = object;
		}
	}
	
	return number;
}

@end



@implementation NSArray(WIDeepMutableCopying)

- (NSMutableArray *)deepMutableCopyWithZone:(NSZone *)zone {
	NSEnumerator	*enumerator;
	NSMutableArray	*array;
	id				object, copy;
	
	array = [[NSMutableArray allocWithZone:zone] initWithCapacity:[self count]];
	enumerator = [self objectEnumerator];
	
	while((object = [enumerator nextObject])) {
		copy = [object deepMutableCopyWithZone:zone];
		[array addObject:copy];
		[copy release];
	}
	
	return array;
}

@end



@implementation NSMutableArray(WIFoundation)

- (void)addObject:(id)object sortedUsingSelector:(SEL)selector {
	IMP					method;
	NSComparisonResult	result;
	NSUInteger			i, count;

	count = [self count];
	
	if(count == 0) {
		[self addObject:object];
	} else {
		method = [object methodForSelector:selector];

		for(i = 0; i < count; i++) {
			result = (NSComparisonResult) method(object, selector, [self objectAtIndex:i]);
			
			if(result < 0) {
				[self insertObject:object atIndex:i];
				
				return;
			}
		}
			
		[self addObject:object];
	}
}



- (NSUInteger)moveObjectAtIndex:(NSUInteger)from toIndex:(NSUInteger)to {
	id			object;
	NSUInteger	index;

	if(from == to)
		return from;
	
	object = [self objectAtIndex:from];
	index = (to <= from) ? to : to - 1;

	[object retain];
	[self removeObjectAtIndex:from];
	[self insertObject:object atIndex:index];
	[object release];
	
	return index;
}



#pragma mark -

- (void)reverse {
	[self setArray:[self reversedArray]];
}



- (void)shuffle {
	[self setArray:[self shuffledArray]];
}

@end
