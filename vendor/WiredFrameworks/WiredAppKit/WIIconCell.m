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

#import <WiredAppKit/WIIconCell.h>

@implementation WIIconCell

- (id)init {
	self = [super init];
	
	[self setLineBreakMode:NSLineBreakByTruncatingTail];

	return self;
}



- (id)copyWithZone:(NSZone *)zone {
    WIIconCell		*cell;
	
	cell = [super copyWithZone:zone];
	
    cell->_image					= [_image retain];
    cell->_horizontalTextOffset		= _horizontalTextOffset;
    cell->_verticalTextOffset		= _verticalTextOffset;
    cell->_textHeight				= _textHeight;
	
	return cell;
}



- (void)dealloc {
	[_image release];

	[super dealloc];
}



#pragma mark -

- (void)setImage:(NSImage *)image {
	[image retain];
	[_image release];
	
	_image = image;
}



- (NSImage *)image {
	return _image;
}



- (void)setHorizontalTextOffset:(CGFloat)offset {
	_horizontalTextOffset = offset;
}



- (CGFloat)horizontalTextOffset {
	return _horizontalTextOffset;
}



- (void)setVerticalTextOffset:(CGFloat)offset {
	_verticalTextOffset = offset;
}



- (CGFloat)verticalTextOffset {
	return _verticalTextOffset;
}



- (void)setTextHeight:(CGFloat)height {
	_textHeight = height;
}



- (CGFloat)textHeight {
	return _textHeight;
}



#pragma mark -

- (void)editWithFrame:(NSRect)frame inView:(NSView *)view editor:(NSText *)editor delegate:(id)object event:(NSEvent *)event {
	NSRect		textFrame, imageFrame;
	
	if(_image)
		NSDivideRect(frame, &imageFrame, &textFrame, 5.0 + [_image size].width + _horizontalTextOffset, NSMinXEdge);
	else
		NSDivideRect(frame, &imageFrame, &textFrame, _horizontalTextOffset, NSMinXEdge);

	textFrame.origin.y		+= _verticalTextOffset;
	textFrame.size.height	-= _verticalTextOffset;

	if(_textHeight > 0.0)
		textFrame.size.height = _textHeight;

	[super editWithFrame:textFrame inView:view editor:editor delegate:object event:event];
}



- (void)selectWithFrame:(NSRect)frame inView:(NSView *)view editor:(NSText *)editor delegate:(id)delegate start:(NSInteger)start length:(NSInteger)length {
	NSRect		textFrame, imageFrame;
	
	if(_image)
		NSDivideRect(frame, &imageFrame, &textFrame, 5.0 + [_image size].width + _horizontalTextOffset, NSMinXEdge);
	else
		NSDivideRect(frame, &imageFrame, &textFrame, _horizontalTextOffset, NSMinXEdge);

	textFrame.origin.y		+= _verticalTextOffset;
	textFrame.size.height	-= _verticalTextOffset;

	if(_textHeight > 0.0)
		textFrame.size.height = _textHeight;

	[super selectWithFrame:textFrame inView:view editor:editor delegate:delegate start:start length:length];
}



- (void)drawWithFrame:(NSRect)frame inView:(NSView *)view {
	NSSize		imageSize;
	NSRect		textFrame, imageFrame;
	
	imageSize = [_image size];
	
	if(_image)
		NSDivideRect(frame, &imageFrame, &textFrame, 5.0 + imageSize.width + _horizontalTextOffset, NSMinXEdge);
	else
		NSDivideRect(frame, &imageFrame, &textFrame, _horizontalTextOffset, NSMinXEdge);
	
	if(_image) {
		if([self drawsBackground]) {
			[[self backgroundColor] set];
			NSRectFill(imageFrame);
		}
		
		imageFrame.origin.x += 4.0;
		imageFrame.size = imageSize;
		
		if([view isFlipped])
			imageFrame.origin.y += ceil((textFrame.size.height + imageFrame.size.height) / 2.0);
		else
			imageFrame.origin.y += ceil((textFrame.size.height - imageFrame.size.height) / 2.0);
		
		[_image compositeToPoint:imageFrame.origin operation:NSCompositeSourceOver];
        //[_image drawAtPoint:imageFrame.origin fromRect:view.bounds operation:NSCompositeSourceOver fraction:1.0];
	}
	
	textFrame.origin.y		+= _verticalTextOffset;
	textFrame.size.height	-= _verticalTextOffset;
	
	if(_textHeight > 0.0)
		textFrame.size.height = _textHeight;

	[super drawWithFrame:textFrame inView:view];
}

@end
