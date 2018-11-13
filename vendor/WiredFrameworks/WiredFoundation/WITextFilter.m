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

#import <WiredFoundation/WITextFilter.h>

@implementation WITextFilter

- (id)initWithSelectors:(SEL)selector, ... {
	NSMutableArray	*array;
	SEL				eachSelector;
	NSUInteger		i;
	va_list			ap;
	
	self = [super init];
	
	va_start(ap, selector);

	array = [[NSMutableArray alloc] initWithObjects:NSStringFromSelector(selector), NULL];
	
	while((eachSelector = va_arg(ap, SEL)))
		[array addObject:NSStringFromSelector(eachSelector)];
	
	va_end(ap);
	
	_count = [array count];
	_selectors = malloc(_count * sizeof(SEL));
	
	for(i = 0; i < _count; i++)
		_selectors[i] = NSSelectorFromString([array objectAtIndex:i]);

	[array release];
	
	return self;
}



- (void)dealloc {
	free(_selectors);
	
	[super dealloc];
}



#pragma mark -

- (void)filter:(id)string {
	NSUInteger		i;
	
	for(i = 0; i < _count; i++)
		[string performSelector:_selectors[i] withObject:self];
}

@end
