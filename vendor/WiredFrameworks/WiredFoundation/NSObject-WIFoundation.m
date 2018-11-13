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

#import <WiredFoundation/NSObject-WIFoundation.h>
#import <WiredFoundation/NSInvocation-WIFoundation.h>
#import <WiredFoundation/NSThread-WIFoundation.h>

@implementation NSObject(WIFoundation)

+ (NSBundle *)bundle {
	return [NSBundle bundleForClass:self];
}



- (NSBundle *)bundle {
	return [[self class] bundle];
}



#pragma mark -

+ (void)cancelPreviousPerformRequestsWithTarget:(id)target selector:(SEL)selector {
	[NSObject cancelPreviousPerformRequestsWithTarget:target selector:selector object:NULL];
}


#pragma mark -

- (void)performSelector:(SEL)selector afterDelay:(NSTimeInterval)delay {
	[self performSelector:selector withObject:NULL afterDelay:delay];
}



- (void)performSelectorOnce:(SEL)selector afterDelay:(NSTimeInterval)delay {
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:selector object:NULL];
	[self performSelector:selector withObject:NULL afterDelay:delay];
}



- (void)performSelectorOnce:(SEL)selector withObject:(id)object afterDelay:(NSTimeInterval)delay {
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:selector object:object];
	[self performSelector:selector withObject:object afterDelay:delay];
}

@end



@implementation NSObject(WIObjectPropertylistSerialization)

- (BOOL)isKindOfPropertyListSerializableClass {
	return ([self isKindOfClass:[NSData class]] ||
			[self isKindOfClass:[NSDate class]] ||
			[self isKindOfClass:[NSNumber class]] ||
			[self isKindOfClass:[NSString class]] ||
			[self isKindOfClass:[NSArray class]] ||
			[self isKindOfClass:[NSDictionary class]]);
}

@end



@implementation NSObject(WIDeepMutableCopying)

- (id)deepMutableCopy {
	return [self deepMutableCopyWithZone:NULL];
}



- (id)deepMutableCopyWithZone:(NSZone *)zone {
	if([self respondsToSelector:@selector(mutableCopyWithZone:)])
		return [(id) self mutableCopyWithZone:zone];
	else if([self respondsToSelector:@selector(copyWithZone:)])
		return [(id) self copyWithZone:zone];
	
	return NULL;
}

@end




@implementation NSObject(WIThreadScheduling)

- (void)performSelectorOnMainThread:(SEL)action {
	[self performSelectorOnMainThread:action withObject:NULL waitUntilDone:NO];
}



- (void)performSelectorOnMainThread:(SEL)action waitUntilDone:(BOOL)waitUntilDone {
	[self performSelectorOnMainThread:action withObject:NULL waitUntilDone:waitUntilDone];
}



- (void)performSelectorOnMainThread:(SEL)action withObject:(id)object1 {
	[self performSelectorOnMainThread:action withObject:object1 waitUntilDone:NO];
}



- (void)performSelectorOnMainThread:(SEL)action withObject:(id)object1 withObject:(id)object2 {
	[self performSelectorOnMainThread:action withObject:object1 withObject:object2 waitUntilDone:NO];
}



- (void)performSelectorOnMainThread:(SEL)action withObject:(id)object1 withObject:(id)object2 waitUntilDone:(BOOL)waitUntilDone {
	NSInvocation	*invocation;
	
	if([NSThread isMainThread]) {
		[self performSelector:action withObject:object1 withObject:object2];
	} else {
		invocation = [NSInvocation invocationWithTarget:self action:action];
		[invocation setArgument:&object1 atIndex:2];
		[invocation setArgument:&object2 atIndex:3];
		[self performInvocationOnMainThread:invocation waitUntilDone:waitUntilDone];
	}
}



- (void)performSelectorOnMainThread:(SEL)action withObject:(id)object1 withObject:(id)object2 withObject:(id)object3 {
	[self performSelectorOnMainThread:action withObject:object1 withObject:object2 withObject:object3 waitUntilDone:NO];
}



- (void)performSelectorOnMainThread:(SEL)action withObject:(id)object1 withObject:(id)object2 withObject:(id)object3 waitUntilDone:(BOOL)waitUntilDone {
	NSInvocation	*invocation;
	
	invocation = [NSInvocation invocationWithTarget:self action:action];
	[invocation setArgument:&object1 atIndex:2];
	[invocation setArgument:&object2 atIndex:3];
	[invocation setArgument:&object3 atIndex:4];
	
	if([NSThread isMainThread])
		[invocation invoke];
	else
		[self performInvocationOnMainThread:invocation waitUntilDone:waitUntilDone];
}



- (void)performInvocationOnMainThread:(NSInvocation *)invocation {
	[self performInvocationOnMainThread:invocation waitUntilDone:NO];
}



- (void)performInvocationOnMainThread:(NSInvocation *)invocation waitUntilDone:(BOOL)waitUntilDone {
	[invocation retainArguments];
	[invocation performSelectorOnMainThread:@selector(invoke) withObject:NULL waitUntilDone:waitUntilDone];
}

@end
