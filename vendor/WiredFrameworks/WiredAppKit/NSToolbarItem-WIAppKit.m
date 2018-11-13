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

#import <WiredAppKit/NSToolbarItem-WIAppKit.h>

@implementation NSToolbarItem(WIAppKit)

+ (NSToolbarItem *)toolbarItemWithIdentifier:(NSString *)identifier name:(NSString *)name content:(id)content target:(id)target action:(SEL)action {
	NSToolbarItem	*item;

	item = [[NSToolbarItem alloc] initWithItemIdentifier:identifier];

	if([name length] > 0) {
		[item setLabel:name];
		[item setPaletteLabel:name];
		[item setToolTip:name];
	}

	if([content isKindOfClass:[NSControl class]]) {
		[content setTarget:target];
		[content setAction:action];
	} else {
		[item setTarget:target];
		[item setAction:action];
	}

	if([content isKindOfClass:[NSImage class]]) {
		[item setImage:content];
	}
	else if([content isKindOfClass:[NSView class]]) {
		[item setView:content];
		[item setMinSize:[content frame].size];
		[item setMaxSize:[content frame].size];
	}

	return [item autorelease];
}

@end
