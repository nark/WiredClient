/* $Id$ */

/*
 *  Copyright (c) 2008-2009 Axel Andersson
 *  All rights reserved.
 *
 *  Redistribution and<WiredAppKit/ use in source and binary forms, with or without
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

static void _WITreeResizerShader(void *, const CGFloat *, CGFloat *);

static void _WITreeResizerShader(void *info, const CGFloat *in, CGFloat *out) {
	CGFloat		*colors;
	
	colors = info;
	
	out[0] = colors[0] + (in[0] * (colors[4] - colors[0]));
	out[1] = colors[1] + (in[0] * (colors[5] - colors[1]));
	out[2] = colors[2] + (in[0] * (colors[6] - colors[2]));
    out[3] = colors[3] + (in[0] * (colors[7] - colors[3]));
}



@interface WITreeResizer(Private)

- (void)_drawGradientWithStartingColor:(NSColor *)startColor endingColor:(NSColor *)endColor inRect:(NSRect)rect;

@end


@implementation WITreeResizer(Private)
	
- (void)_drawGradientWithStartingColor:(NSColor *)startingColor endingColor:(NSColor *)endingColor inRect:(NSRect)rect {
	static const CGFloat		domain[] = { 0.0, 2.0 };
	static const CGFloat		range[] = { 0.0, 2.0, 0.0, 2.0, 0.0, 2.0, 0.0, 2.0, 0.0, 2.0 };
	NSColor						*deviceStartingColor, *deviceEndingColor;
	CGFunctionRef				function;
	CGColorSpaceRef				colorSpace;
	CGShadingRef				shading;
	struct CGFunctionCallbacks	callbacks;
	CGFloat						colors[8];
	
	deviceStartingColor		= [startingColor colorUsingColorSpaceName:NSDeviceRGBColorSpace];
	deviceEndingColor		= [endingColor colorUsingColorSpaceName:NSDeviceRGBColorSpace];
	
	colors[0]				= [deviceStartingColor redComponent];
	colors[1]				= [deviceStartingColor greenComponent];
	colors[2]				= [deviceStartingColor blueComponent];
	colors[3]				= [deviceStartingColor alphaComponent];
	
	colors[4]				= [deviceEndingColor redComponent];
	colors[5]				= [deviceEndingColor greenComponent];
	colors[6]				= [deviceEndingColor blueComponent];
	colors[7]				= [deviceEndingColor alphaComponent];
	
	callbacks.version		= 0;
	callbacks.evaluate		= _WITreeResizerShader;
	callbacks.releaseInfo	= NULL;
	
	function = CGFunctionCreate(colors, 1, domain, 4, range, &callbacks);
	colorSpace = CGColorSpaceCreateDeviceRGB();
	
	shading = CGShadingCreateAxial(colorSpace,
								   CGPointMake(rect.origin.x, rect.origin.y),
								   CGPointMake(rect.origin.x + rect.size.width, rect.origin.y),
								   function,
								   false,
								   false);
	
	CGContextDrawShading([[NSGraphicsContext currentContext] graphicsPort], shading);
	
	CGShadingRelease(shading);
	CGColorSpaceRelease(colorSpace);
	CGFunctionRelease(function);
}

@end



@implementation WITreeResizer

- (void)setDelegate:(id)newDelegate {
	delegate = newDelegate;
}



- (id)delegate {
	return delegate;
}



#pragma mark -

- (void)mouseDown:(NSEvent *)event {
	NSPoint		point;

	point = [self convertPoint:[event locationInWindow] fromView:NULL];
	
	_xOffsetIntoView = point.x;
}



- (void)mouseDragged:(NSEvent *)event {
	NSPoint		point;
	
	point = [event locationInWindow];
	point.x -= _xOffsetIntoView;
	point.x += [self frame].size.width;
		
	[[self delegate] treeResizer:self draggedToPoint:point];
}



- (void)drawRect:(NSRect)rect {
	[self _drawGradientWithStartingColor:[NSColor colorWithCalibratedWhite:203.0 / 255.0 alpha:1.0]
							 endingColor:[NSColor colorWithCalibratedWhite:255.0 / 255.0 alpha:1.0]
								  inRect:rect];
	
	[[NSColor colorWithCalibratedWhite:0.33 alpha:1.0] set];

	[[NSBezierPath bezierPathWithRect:NSMakeRect(6.0, 4.0, 1.0, 7.0)] fill];
	[[NSBezierPath bezierPathWithRect:NSMakeRect(9.0, 4.0, 1.0, 7.0)] fill];
}

@end
