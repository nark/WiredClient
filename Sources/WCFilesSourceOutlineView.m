/* $Id$ */

/*
 *  Copyright (c) 2009 Axel Andersson
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

#import "WCFiles.h"
#import "WCFilesSourceOutlineView.h"

@interface WCFilesSourceOutlineView(Private)

- (void)_initFilesSourceOutlineView;

@end


@implementation WCFilesSourceOutlineView(Private)

- (void)_initFilesSourceOutlineView {
	_draggedFiles = [[NSMutableArray alloc] init];
}

@end



@implementation WCFilesSourceOutlineView

- (id)initWithFrame:(NSRect)frame {
	self = [super initWithFrame:frame];
	
	[self _initFilesSourceOutlineView];
	
	return self;
}



- (id)initWithCoder:(NSCoder *)coder {
	self = [super initWithCoder:coder];
	
	[self _initFilesSourceOutlineView];
	
	return self;
}



- (void)dealloc {
	[_draggedFiles release];
	
	[super dealloc];
}


	
#pragma mark -


- (void)dragImage:(NSImage *)image at:(NSPoint)point offset:(NSSize)offset event:(NSEvent *)event pasteboard:(NSPasteboard *)pasteboard source:(id)source slideBack:(BOOL)slideBack {
	[_draggedFiles setArray:[NSKeyedUnarchiver unarchiveObjectWithData:[pasteboard dataForType:WCPlacePboardType]]];
	
	[super dragImage:image at:point offset:offset event:event pasteboard:pasteboard source:source slideBack:NO];
}



- (void)draggedImage:(NSImage *)image endedAt:(NSPoint)point operation:(NSDragOperation)operation {
    if(!NSMouseInRect([[self window] convertScreenToBase:point], [self bounds], NO)) {
		NSShowAnimationEffect(NSAnimationEffectDisappearingItemDefault,
							  [NSEvent mouseLocation],
							  NSZeroSize,
							  NULL,
							  NULL,
							  NULL);
		
		[(WCFiles *)[self dataSource] outlineView:self removeItems:_draggedFiles];
    }
	
	[_draggedFiles removeAllObjects];
}

@end
