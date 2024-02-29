/* $Id$ */

/*
 *  Copyright (c) 2008-2009 Axel Andersson
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

#import <WiredAppKit/WITreeCell.h>

@implementation WITreeCell

- (id)init {
	self = [super init];
	
	_arrowImage = [[NSImage alloc] initWithContentsOfFile:
		[[NSBundle bundleWithIdentifier:WIAppKitBundleIdentifier] pathForResource:@"WITreeCell-RightArrow" ofType:@"icns"]];
	_leaf = YES;
	
	return self;
}



- (id)copyWithZone:(NSZone *)zone {
    WITreeCell		*cell;
	
	cell = [super copyWithZone:zone];
    cell->_arrowImage = [_arrowImage retain];
	cell->_leaf = _leaf;
	
	return cell;
}



- (void)dealloc {
	[_arrowImage release];
	
	[super dealloc];
}



#pragma mark -

- (void)setLeaf:(BOOL)leaf {
	_leaf = leaf;
}



- (BOOL)isLeaf {
	return _leaf;
}



#pragma mark -

- (void)drawWithFrame:(NSRect)frame inView:(NSView *)view {
	NSSize		imageSize;
	NSRect		imageFrame;
	
	imageSize = [_arrowImage size];
		
	NSDivideRect(frame, &imageFrame, &frame, imageSize.width, NSMaxXEdge);
		
	if(!_leaf) {
		if([self drawsBackground]) {
			[[self backgroundColor] set];
			NSRectFill(imageFrame);
		}
		
		imageFrame.origin.x += 3.0;
		imageFrame.size = imageSize;
		
		if([view isFlipped])
			imageFrame.origin.y += ceil((frame.size.height + imageFrame.size.height) / 2.0);
		else
			imageFrame.origin.y += ceil((frame.size.height - imageFrame.size.height) / 2.0);
		
		[_arrowImage compositeToPoint:imageFrame.origin operation:NSCompositeSourceOver];
	}
	
	[super drawWithFrame:frame inView:view];
}

@end
