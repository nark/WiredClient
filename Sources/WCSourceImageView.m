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

#import "WCSourceImageView.h"
#import "WCSourceSplitView.h"

@implementation WCSourceImageView

- (void)mouseDown:(NSEvent *)event {
	NSEvent			*nextEvent;
	NSView			*view;
	NSRect			frame;
	NSPoint			point;
	id				delegate;
	CGFloat			minCoordinate, maxCoordinate;
	BOOL			tooMuchLeft, tooMuchRight, previousTooMuchLeft, previousTooMuchRight;
	
	if(![_splitView isVertical])
		return;
	
	view			= [[_splitView subviews] objectAtIndex:0];
	delegate		= [_splitView delegate];
	minCoordinate	= 0.0;
	maxCoordinate	= [_splitView frame].size.width;
	
	if([delegate respondsToSelector:@selector(splitView:constrainMinCoordinate:ofSubviewAt:)])
		minCoordinate = [delegate splitView:_splitView constrainMinCoordinate:minCoordinate ofSubviewAt:0];
	
	if([delegate respondsToSelector:@selector(splitView:constrainMaxCoordinate:ofSubviewAt:)])
		maxCoordinate = [delegate splitView:_splitView constrainMaxCoordinate:maxCoordinate ofSubviewAt:0];
	
	[[NSCursor resizeLeftRightCursor] push]; 
	
	previousTooMuchLeft = previousTooMuchRight = NO;
	
	while(YES) {
        nextEvent = [[self window] nextEventMatchingMask:NSLeftMouseUpMask | NSLeftMouseDraggedMask];
		
		switch([nextEvent type]) {
			case NSLeftMouseDragged:
				frame = [view frame];
				point = [nextEvent locationInWindow];
				
				tooMuchLeft = (minCoordinate > 0.0 && point.x < minCoordinate);
				
				if(tooMuchLeft) {
					if(!previousTooMuchLeft)
						[[NSCursor resizeRightCursor] push];

					previousTooMuchLeft = YES;
					
					continue;
				}
				
				if(previousTooMuchLeft) {
					if(point.x >= [self frame].origin.x + ([self frame].size.width / 2.0)) {
						[NSCursor pop];
						
						previousTooMuchLeft = NO;
					} else {
						continue;
					}
				}
				
				tooMuchRight = (maxCoordinate > 0.0 && point.x > maxCoordinate);
				
				if(tooMuchRight) {
					if(!previousTooMuchRight)
						[[NSCursor resizeLeftCursor] push];
					
					previousTooMuchRight = YES;
					
					continue;
				}
				
				if(previousTooMuchRight) {
					if(point.x < [self frame].origin.x + ([self frame].size.width / 2.0)) {
						[NSCursor pop];
						
						previousTooMuchRight = NO;
					} else {
						continue;
					}
				}
				
				frame.size.width = point.x;
				
				[view setFrame:frame];
				[_splitView adjustSubviews];
				break;
		
			case NSLeftMouseUp:
				[NSCursor pop];
				return;
				break;
			
			default:
				[super mouseDown:event];
				break;
		}
	}
}



- (void)resetCursorRects {
	[self addCursorRect:[self visibleRect] cursor:[NSCursor resizeLeftRightCursor]];
}

@end
