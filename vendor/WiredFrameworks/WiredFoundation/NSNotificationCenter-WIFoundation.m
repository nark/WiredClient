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
#import <WiredFoundation/NSNotificationCenter-WIFoundation.h>
#import <WiredFoundation/NSThread-WIFoundation.h>

@implementation NSNotificationCenter(WIFoundation)

- (void)addObserver:(id)observer selector:(SEL)selector name:(NSString *)name {
	[self addObserver:observer selector:selector name:name object:NULL];
}



- (void)removeObserver:(id)observer name:(NSString *)name {
	[self removeObserver:observer name:name object:NULL];
}



- (void)postNotificationName:(NSString *)name {
	[self postNotificationName:name object:NULL];
}



#pragma mark -

- (void)mainThreadPostNotificationName:(NSString *)name {
	[self mainThreadPostNotificationName:name waitUntilDone:NO];
}



- (void)mainThreadPostNotificationName:(NSString *)name waitUntilDone:(BOOL)waitUntilDone {
	[self performSelectorOnMainThread:@selector(postNotificationName:object:)
						   withObject:name
						   withObject:NULL
						waitUntilDone:waitUntilDone];
}



- (void)mainThreadPostNotificationName:(NSString *)name object:(id)object {
	[self mainThreadPostNotificationName:name object:object waitUntilDone:NO];
}



- (void)mainThreadPostNotificationName:(NSString *)name object:(id)object waitUntilDone:(BOOL)waitUntilDone {
	[self performSelectorOnMainThread:@selector(postNotificationName:object:)
						   withObject:name
						   withObject:object
						waitUntilDone:waitUntilDone];
}



- (void)mainThreadPostNotificationName:(NSString *)name object:(id)object userInfo:(NSDictionary *)userInfo {
	[self mainThreadPostNotificationName:name object:object userInfo:userInfo waitUntilDone:NO];
}



- (void)mainThreadPostNotificationName:(NSString *)name object:(id)object userInfo:(NSDictionary *)userInfo waitUntilDone:(BOOL)waitUntilDone {
	[self performSelectorOnMainThread:@selector(postNotificationName:object:userInfo:)
						   withObject:name
						   withObject:object
						   withObject:userInfo
						waitUntilDone:waitUntilDone];
}

@end
