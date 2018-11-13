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

#import <WiredAppKit/NSMenu-WIAppKit.h>
#import <WiredAppKit/NSPopUpButton-WIAppKit.h>

@implementation NSPopUpButton(WIAppKit)

- (void)addItem:(NSMenuItem *)item {
	[[self cell] addItem:item];
}



- (void)addItems:(NSArray *)items {
	[[self cell] addItems:items];
}



- (void)insertItem:(NSMenuItem *)item atIndex:(NSUInteger)index {
	[[self cell] insertItem:item atIndex:index];
}



- (void)removeItem:(NSMenuItem *)item {
	[[self cell] removeItem:item];
}



#pragma mark -

- (NSInteger)tagOfSelectedItem {
	return [[self cell] tagOfSelectedItem];
}



- (NSMenuItem *)itemWithTag:(NSInteger)tag {
	return [[self cell] itemWithTag:tag];
}



#pragma mark -

- (void)selectItemWithRepresentedObject:(id)representedObject {
	[[self cell] selectItemWithRepresentedObject:representedObject];
}



- (id)representedObjectOfSelectedItem {
	return [[self cell] representedObjectOfSelectedItem];
}

@end



@implementation NSPopUpButtonCell(WIAppKit)

- (void)addItem:(NSMenuItem *)item {
	[[self menu] addItem:item];
}



- (void)addItems:(NSArray *)items {
	[[self menu] addItems:items];
}



- (void)insertItem:(NSMenuItem *)item atIndex:(NSUInteger)index {
	[[self menu] insertItem:item atIndex:index];
}



- (void)removeItem:(NSMenuItem *)item {
	[[self menu] removeItem:item];
}



#pragma mark -

- (NSInteger)tagOfSelectedItem {
	return [[self selectedItem] tag];
}



- (NSMenuItem *)itemWithTag:(NSInteger)tag {
	return (NSMenuItem *) [[self menu] itemWithTag:tag];
}



#pragma mark -

- (void)selectItemWithRepresentedObject:(id)representedObject {
	NSInteger		index;
	
	index = [self indexOfItemWithRepresentedObject:representedObject];
	
	if(index < 0)
		return;
	
	[self selectItemAtIndex:index];
}



- (id)representedObjectOfSelectedItem {
	return [[self selectedItem] representedObject];
}

@end
