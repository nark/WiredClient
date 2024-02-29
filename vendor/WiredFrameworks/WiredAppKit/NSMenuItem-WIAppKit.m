/* $Id$ */

/*
 *  Copyright (c) 2006-2009 Axel Andersson
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

#import <WiredAppKit/NSMenuItem-WIAppKit.h>

@implementation NSMenuItem(WIAppKit)

+ (NSMenuItem *)itemWithTitle:(NSString *)title {
	return [self itemWithTitle:title action:NULL keyEquivalent:@""];
}



+ (NSMenuItem *)itemWithTitle:(NSString *)title tag:(NSInteger)tag {
	return [self itemWithTitle:title tag:tag action:NULL];
}



+ (NSMenuItem *)itemWithTitle:(NSString *)title tag:(NSInteger)tag action:(SEL)action {
	NSMenuItem		*item;

	item = [self itemWithTitle:title action:action];
	[item setTag:tag];
	
	return item;
}



+ (NSMenuItem *)itemWithTitle:(NSString *)title action:(SEL)action {
	return [self itemWithTitle:title action:action keyEquivalent:@""];
}



+ (NSMenuItem *)itemWithTitle:(NSString *)title action:(SEL)action keyEquivalent:(NSString *)keyEquivalent {
	return [[[self alloc] initWithTitle:title action:action keyEquivalent:keyEquivalent] autorelease];
}



+ (NSMenuItem *)itemWithTitle:(NSString *)title representedObject:(id)representedObject {
	NSMenuItem		*item;

	item = [self itemWithTitle:title];
	[item setRepresentedObject:representedObject];
	
	return item;
}



+ (NSMenuItem *)itemWithTitle:(NSString *)title image:(NSImage *)image {
	NSMenuItem		*item;

	item = [self itemWithTitle:title];
	[item setImage:image];
	
	return item;
}



#pragma mark -

+ (NSMenuItem *)itemWithAttributedTitle:(NSAttributedString *)title tag:(NSInteger)tag {
	NSMenuItem		*item;

	item = [self itemWithTitle:[title string] tag:tag];
	[item setAttributedTitle:title];
	
	return item;
}

@end
