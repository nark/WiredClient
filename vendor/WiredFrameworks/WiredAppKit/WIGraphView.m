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
#import <WiredAppKit/WIGraphView.h>

@implementation WIGraphView

- (id)initWithFrame:(NSRect)frame {
	self = [super initWithFrame:frame];
	
	_canvas = [[NSImage alloc] initWithSize:frame.size];

	_inLabelAttributes = [[NSMutableDictionary alloc] init];
	[_inLabelAttributes setObject:[NSFont systemFontOfSize:9.0] forKey:NSFontAttributeName];

	_outLabelAttributes = [[NSMutableDictionary alloc] init];
	[_outLabelAttributes setObject:[NSFont systemFontOfSize:9.0] forKey:NSFontAttributeName];

	[self setBackgroundColor:[NSColor blackColor]];
	[self setInColor:[NSColor greenColor]];
	[self setOutColor:[NSColor redColor]];
	
	return self;
}



- (void)dealloc {
	[_canvas release];
	
	[_backgroundColor release];
	[_inColor release];
	[_outColor release];
	
	[_inData release];
	[_outData release];

	[_inLabel release];
	[_inLabelAttributes release];
	[_outLabel release];
	[_outLabelAttributes release];
	
	[super dealloc];
}



#pragma mark -

- (void)setInData:(NSArray *)data {
	[data retain];
	[_inData release];
	
	_inData = data;
}



- (void)setOutData:(NSArray *)data {
	[data retain];
	[_outData release];
	
	_outData = data;
}



#pragma mark -

- (void)setBackgroundColor:(NSColor *)color {
	[color retain];
	[_backgroundColor release];
	
	_backgroundColor = color;
}



- (NSColor *)backgroundColor {
	return _backgroundColor;
}



- (void)setInColor:(NSColor *)color {
	[color retain];
	[_inColor release];
	
	_inColor = color;
	
	[_inLabelAttributes setObject:_inColor forKey:NSForegroundColorAttributeName];
}



- (NSColor *)inColor {
	return _inColor;
}



- (void)setOutColor:(NSColor *)color {
	[color retain];
	[_outColor release];
	
	_outColor = color;
	
	[_outLabelAttributes setObject:_outColor forKey:NSForegroundColorAttributeName];
}



- (NSColor *)outColor {
	return _outColor;
}



- (void)setDrawsLabel:(BOOL)drawsLabel {
	_drawsLabel = drawsLabel;
}



- (BOOL)drawsLabel {
	return _drawsLabel;
}



- (void)setInLabel:(NSString *)label {
	[_inLabel release];
	_inLabel = [[NSAttributedString alloc] initWithString:label attributes:_inLabelAttributes];
}



- (NSString *)inLabel {
	return [_inLabel string];
}



- (void)setOutLabel:(NSString *)label {
	[_outLabel release];
	_outLabel = [[NSAttributedString alloc] initWithString:label attributes:_outLabelAttributes];
}



- (NSString *)outLabel {
	return [_outLabel string];
}



#pragma mark -

- (void)drawRect:(NSRect)rect {
	NSArray			*inData, *outData;
	NSBezierPath	*path;
	NSPoint			point;
	double			max, inMax, outMax;
	double			height, inWidth, outWidth;
	NSInteger		i, inPoints, outPoints;
	
	[_canvas setSize:rect.size];
	[_canvas lockFocus];
	[_backgroundColor set];
	NSRectFill(rect);
	[_canvas unlockFocus];
	
	inPoints = [_inData count];
	outPoints = [_outData count];
	
	if(inPoints < rect.size.width / 3.0) {
		inData = _inData;
		inWidth = inPoints > 0 ? rect.size.width / inPoints : 0.0;
	} else {
		i = (rect.size.width / 3.0) + 1;
		inData = [_inData subarrayWithRange:NSMakeRange(inPoints - i, i)];
		inPoints = [inData count];
		inWidth = 3.0;
	}
	
	if(outPoints < rect.size.width / 3.0) {
		outData = _outData;
		outWidth = outPoints > 0 ? rect.size.width / outPoints : 0.0;
	} else {
		i = (rect.size.width / 3.0) + 1;
		outData = [_outData subarrayWithRange:NSMakeRange(outPoints - i, i)];
		outPoints = [outData count];
		outWidth = 3.0;
	}
	
	inMax = inPoints > 0 ? [[inData maximumNumber] doubleValue] : 0.0;
	outMax = outPoints > 0 ? [[outData maximumNumber] doubleValue] : 0.0;
	max = inMax > outMax ? inMax : outMax;
	
	if(outPoints > 0) {
		height = max > 0.0
			? (rect.size.height - 1.0) * ([[outData objectAtIndex:0] doubleValue] / max)
			: 0.0;
		point = NSMakePoint(0.0, height + 1.0);
		path = [NSBezierPath bezierPath];
		[path setLineWidth:2.0];
		[path moveToPoint:point];

		for(i = 1; i < outPoints; i++) {
			height = max > 0.0
				? (rect.size.height - 2.0) * ([[outData objectAtIndex:i] doubleValue] / max)
				: 0.0;
			point = NSMakePoint(i * outWidth, height + 1.0);
			[path lineToPoint:point];
			[path moveToPoint:point];
		}

		[path closePath];

		[_canvas lockFocus];
		[_outColor set];
		[path stroke];

		if(_drawsLabel && [_outLabel length] > 0)
			[_outLabel drawAtPoint:NSMakePoint(3.0, 13.0)];

		[_canvas unlockFocus];
	}
	
	if(inPoints > 0.0) {
		height = max > 0.0
			? rect.size.height * ([[inData objectAtIndex:0] doubleValue] / max)
			: 0.0;
		point = NSMakePoint(0.0, height + 1.0);
		path = [NSBezierPath bezierPath];
		[path setLineWidth:2.0];
		[path moveToPoint:point];
		
		for(i = 1; i < inPoints; i++) {
			height = max > 0.0
				? (rect.size.height - 2.0) * ([[inData objectAtIndex:i] doubleValue] / max)
				: 0.0;
			point = NSMakePoint(i * inWidth, height + 1.0);
			[path lineToPoint:point];
			[path moveToPoint:point];
		}
		
		[path closePath];
		
		[_canvas lockFocus];
		[_inColor set];
		[path stroke];
		
		if(_drawsLabel && [_inLabel length] > 0)
			[_inLabel drawAtPoint:NSMakePoint(3.0, 4.0)];

		[_canvas unlockFocus];
	}
	
	[_canvas compositeToPoint:rect.origin operation:NSCompositeSourceOver];
}

@end
