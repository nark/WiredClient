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
#import <WiredAppKit/NSAttributedString-WIAppKit.h>
#import <WiredAppKit/WITextView.h>

@interface WITextView(Private)

- (NSAttributedString *)_filteredString:(NSString *)string withFilter:(WITextFilter *)filter;

@end


@implementation WITextView(Private)

- (NSAttributedString *)_filteredString:(NSString *)string withFilter:(WITextFilter *)filter {
	NSMutableAttributedString   *attributedString;
	NSDictionary				*attributes;
	
	attributes = [NSDictionary dictionaryWithObjectsAndKeys:
		[self textColor],		NSForegroundColorAttributeName,
		[self font],			NSFontAttributeName,
		NULL];

	attributedString = [NSMutableAttributedString attributedStringWithString:string attributes:attributes];
	[attributedString applyFilter:filter];
	
	return attributedString;
}

@end



@implementation WITextView

- (void)dealloc {
	[_textColor release];
	
	[super dealloc];
}



#pragma mark -

- (void)resetCursorRects {
	NSLayoutManager			*layoutManager;
	NSTextContainer			*textContainer;
	NSAttributedString		*string;
	NSCursor				*cursor;
	id						attribute;
	NSPoint					point;
	NSRectArray				rects;
	NSRect					rect, visibleRect;
	NSRange					range, characterRange, attributeRange;
	NSUInteger				i, count;
	
	cursor			= [NSCursor pointingHandCursor];
	layoutManager	= [self layoutManager];
	textContainer	= [self textContainer];
	string			= [self textStorage];
	
	point			= [self textContainerOrigin];
	visibleRect		= [self visibleRect];
	rect			= NSOffsetRect(visibleRect, -point.x, -point.y);
	
	range			= [layoutManager glyphRangeForBoundingRect:rect inTextContainer:textContainer];
	characterRange	= [layoutManager characterRangeForGlyphRange:range actualGlyphRange:NULL];
	attributeRange	= NSMakeRange(characterRange.location, 0);
	
	while(NSMaxRange(attributeRange) < NSMaxRange(characterRange)) {
		attribute = [string attribute:NSLinkAttributeName 
							  atIndex:NSMaxRange(attributeRange)
					   effectiveRange:&attributeRange];
		
		if(attribute) {
			rects = [layoutManager rectArrayForCharacterRange:attributeRange
								 withinSelectedCharacterRange:NSMakeRange(NSNotFound, 0)
											  inTextContainer:textContainer
													rectCount:&count];
			
			for(i = 0; i < count; i++)
				[self addCursorRect:NSIntersectionRect(rects[i], visibleRect) cursor:cursor];
		}
	}
}



- (void)setTextColor:(NSColor *)textColor {
	[textColor retain];
	[_textColor release];
	
	_textColor = textColor;
}



- (NSColor *)textColor {
	return _textColor;
}



#pragma mark -

- (void)setString:(NSString *)string withFilter:(WITextFilter *)filter {
	[[self textStorage] setAttributedString:[self _filteredString:string withFilter:filter]];
}



- (void)appendString:(NSString *)string withFilter:(WITextFilter *)filter {
	[[self textStorage] appendAttributedString:[self _filteredString:string withFilter:filter]];
}

@end
