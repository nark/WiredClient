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

#import <WiredAppKit/NSSplitView-WIAppKit.h>

@implementation NSSplitView(WIAppKit)

- (void)setPropertiesFromDictionary:(NSDictionary *)dictionary {
	NSArray			*subviews;
	NSRect			frame, previousFrame;
	id				object;
	NSUInteger		count;
	BOOL			isVertical, usePercent = YES;
	
	isVertical	= [self isVertical];
	subviews	= [self subviews];
	frame		= [self frame];
	
	object = [dictionary objectForKey:@"_WISplitView_frame"];
	
	if(object) {
		previousFrame = NSRectFromString(object);
		
		if((isVertical && frame.size.width == previousFrame.size.width) ||
		   (!isVertical && frame.size.height == previousFrame.size.height)) 
			usePercent = NO;
	}
	
	if(usePercent)
		object = [dictionary objectForKey:@"_WISplitView_percents"];
	else
		object = [dictionary objectForKey:@"_WISplitView_pixels"];
		
	if(object) {
		count = [object count];
		
		if(count > [subviews count])
			count = [subviews count];
		
//		for(i = 0; i < count; i++) {
//			view = [subviews objectAtIndex:i];
//			
//			if(usePercent) {
//				percent = [[object objectAtIndex:i] doubleValue];
//				
//				if(isVertical)
//					[view setFrameSize:NSMakeSize(percent * frame.size.width, [view frame].size.height)];
//				else
//					[view setFrameSize:NSMakeSize([view frame].size.height, percent * frame.size.height)];
//			} else {
//				size = [[object objectAtIndex:i] floatValue];
//				
//				if(isVertical)
//					[view setFrameSize:NSMakeSize(size, [view frame].size.height)];
//				else
//					[view setFrameSize:NSMakeSize([view frame].size.height, size)];
//			}
//		}

		[self adjustSubviews];
	}
}



- (NSDictionary *)propertiesDictionary {
	NSMutableDictionary		*dictionary;
	NSMutableArray			*percents, *pixels;
	NSArray					*subviews;
	NSView					*view;
	NSRect					frame;
	CGFloat					percent, pixel;
	NSUInteger				i, count;
	BOOL					isVertical;
	
	dictionary	= [NSMutableDictionary dictionary];
	pixels		= [NSMutableArray array];
	percents	= [NSMutableArray array];
	
	isVertical	= [self isVertical];
	subviews	= [self subviews];
	frame		= [self frame];
	count		= [subviews count];
	
	for(i = 0; i < count; i++) {
		view = [subviews objectAtIndex:i];
		
		if(isVertical) {
			pixel	= [view frame].size.width;
			percent	= pixel / frame.size.width;
		} else {
			pixel	= [view frame].size.height;
			percent	= pixel / frame.size.height;
		}
		
		if([self isSubviewCollapsed:view]) {
			pixel	= 0.0;
			percent	= 0.0;
		}
		
		[pixels addObject:[NSNumber numberWithDouble:pixel]];
		[percents addObject:[NSNumber numberWithDouble:percent]];
	}

	[dictionary setObject:pixels forKey:@"_WISplitView_pixels"];
	[dictionary setObject:percents forKey:@"_WISplitView_percents"];
	[dictionary setObject:NSStringFromRect(frame) forKey:@"_WISplitView_frame"];

	return dictionary;
}

@end
