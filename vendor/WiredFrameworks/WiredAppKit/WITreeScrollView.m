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

#import <WiredAppKit/WITreeResizer.h>
#import <WiredAppKit/WITreeScroller.h>
#import <WiredAppKit/WITreeScrollView.h>

@interface WITreeScrollView(Private)

- (void)_initTreeScrollView;

- (NSRect)_resizerFrame;

@end


@implementation WITreeScrollView(Private)

- (void)_initTreeScrollView {
	WITreeScroller		*scroller;
	
	scroller = [[WITreeScroller alloc] init];
	[self setVerticalScroller:scroller];
	[scroller release];
	
	_resizer = [[WITreeResizer alloc] initWithFrame:[self _resizerFrame]];
	[_resizer setDelegate:self];
	
	[self addSubview:_resizer];
}



- (NSRect)_resizerFrame {
	NSRect		frame;
	
	frame = [self frame];

	return NSMakeRect(frame.size.width - [WITreeScroller scrollerWidth] - 1.0,
					  frame.origin.y + frame.size.height - 20.0,
					  [WITreeScroller scrollerWidth],
					  20.0);
}

@end
	



@implementation WITreeScrollView

- (id)initWithFrame:(NSRect)frame {
	self = [super initWithFrame:frame];
	
	[self _initTreeScrollView];

	return self;
}



- (id)initWithCoder:(NSCoder *)coder {
	self = [super initWithCoder:coder];
	
	[self _initTreeScrollView];
	
	return self;
}



- (void)dealloc {
	[_resizer release];
	
	[super dealloc];
}



#pragma mark -

- (void)setDelegate:(id)newDelegate {
	delegate = newDelegate;
}



- (id)delegate {
	return delegate;
}



#pragma mark -

- (void)treeResizer:(WITreeResizer *)resizeView draggedToPoint:(NSPoint)point {
	[[self delegate] treeScrollView:self shouldResizeToPoint:[self convertPoint:point fromView:NULL]];
}



#pragma mark -

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
	[_resizer setFrame:[self _resizerFrame]];
	
	[super resizeSubviewsWithOldSize:oldSize];
}



- (void)scrollWheel:(NSEvent *)event {
	if(WIAbs([event deltaX]) > WIAbs([event deltaY]) && WIAbs([event deltaX]) > WIAbs([event deltaZ]))
		[[self superview] scrollWheel:event];
	else
		[super scrollWheel:event];
}

@end
