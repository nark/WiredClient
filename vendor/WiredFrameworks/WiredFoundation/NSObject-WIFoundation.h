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

@interface NSObject(WIFoundation)

+ (NSBundle *)bundle;
- (NSBundle *)bundle;

+ (void)cancelPreviousPerformRequestsWithTarget:(id)target selector:(SEL)selector;

- (void)performSelector:(SEL)selector afterDelay:(NSTimeInterval)delay;
- (void)performSelectorOnce:(SEL)selector afterDelay:(NSTimeInterval)delay;
- (void)performSelectorOnce:(SEL)selector withObject:(id)object afterDelay:(NSTimeInterval)delay;

@end


@interface NSObject(WIObjectPropertylistSerialization)

- (BOOL)isKindOfPropertyListSerializableClass;

@end


@interface NSObject(WIDeepMutableCopying)

- (id)deepMutableCopy;
- (id)deepMutableCopyWithZone:(NSZone *)zone;

@end


@interface NSObject(WIThreadScheduling)

- (void)performSelectorOnMainThread:(SEL)selector;
- (void)performSelectorOnMainThread:(SEL)selector waitUntilDone:(BOOL)waitUntilDone;
- (void)performSelectorOnMainThread:(SEL)selector withObject:(id)object1;
- (void)performSelectorOnMainThread:(SEL)selector withObject:(id)object1 withObject:(id)object2;
- (void)performSelectorOnMainThread:(SEL)selector withObject:(id)object1 withObject:(id)object2 waitUntilDone:(BOOL)waitUntilDone;
- (void)performSelectorOnMainThread:(SEL)selector withObject:(id)object1 withObject:(id)object2 withObject:(id)object3;
- (void)performSelectorOnMainThread:(SEL)selector withObject:(id)object1 withObject:(id)object2 withObject:(id)object3 waitUntilDone:(BOOL)waitUntilDone;
- (void)performInvocationOnMainThread:(NSInvocation *)invocation;
- (void)performInvocationOnMainThread:(NSInvocation *)invocation waitUntilDone:(BOOL)waitUntilDone;

@end
