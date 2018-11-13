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
#import <WiredAppKit/WITableHeaderView.h>
#import <WiredAppKit/WITableView.h>

@implementation WITableHeaderView

- (void)dealloc {
	[_menu release];
	
	[super dealloc];
}



#pragma mark -

- (NSMenu *)menuForEvent:(NSEvent *)event {
	NSEnumerator	*enumerator;
	NSTableColumn	*tableColumn;
	NSMenuItem		*menuItem;
	WITableView		*tableView;
	NSUInteger		i, count;
	
	tableView = (WITableView *) [self tableView];

	if(![tableView allowsUserCustomization])
		return NULL;

	if(!_menu) {
		_menu = [[NSMenu alloc] initWithTitle:[tableView description]];
		enumerator = [[[tableView allTableColumns] subarrayFromIndex:1] objectEnumerator];
		
		while((tableColumn = [enumerator nextObject])) {
			menuItem = [[NSMenuItem alloc] initWithTitle:[[tableColumn headerCell] stringValue]
												  action:@selector(selectColumn:)
										   keyEquivalent:@""];
			[menuItem setRepresentedObject:tableColumn];
			[_menu addItem:menuItem];
			[menuItem release];
		}
	}
	
	count = [_menu numberOfItems];
	
	for(i = 0; i < count; i++) {
		menuItem = (NSMenuItem *) [_menu itemAtIndex:i];
		tableColumn = [menuItem representedObject];
		
		if([[tableView tableColumns] containsObject:tableColumn])
			[menuItem setState:NSOnState];
		else
			[menuItem setState:NSOffState];
	}
	
	return _menu;
}



- (void)selectColumn:(id)sender {
	NSTableColumn	*tableColumn;
	WITableView		*tableView;
	
	tableView = (WITableView *) [self tableView];
	tableColumn = [sender representedObject];
	
	if([sender state] == NSOnState)
		[tableView excludeTableColumn:tableColumn];
	else
		[tableView includeTableColumn:tableColumn];
}

@end
