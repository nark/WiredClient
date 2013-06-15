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

#import "WCFilterView.h"

static void WCFilterViewShader(void *, const float *, float *);

static void WCFilterViewShader(void *info, const float *in, float *out) {
	WCFilterView		*view = info;
	CGFloat				red1, green1, blue1, alpha1;
	CGFloat				red2, green2, blue2, alpha2;
	  
	[view->_color1 getRed:&red1 green:&green1 blue:&blue1 alpha:&alpha1];
	[view->_color2 getRed:&red2 green:&green2 blue:&blue2 alpha:&alpha2];
  
	out[0] = ((red2   - red1)   * *in) + red1; 
  	out[1] = ((green2 - green1) * *in) + green1;
  	out[2] = ((blue2  - blue1)  * *in) + blue1;
  	out[3] = ((alpha2 - alpha1) * *in) + alpha1;
}



@implementation WCFilterView

- (id)initWithFrame:(NSRect)frame {
	static const float		domain[2] = { 0, 1 };
	static const float		range[8] = { 0, 1, 0, 1, 0, 1, 0, 1 };
	CGFunctionCallbacks		callbacks = {0, &WCFilterViewShader, NULL};
	
	self = [super initWithFrame:frame];

	_gradientFunction = CGFunctionCreate(self, 1, domain, 4, range, &callbacks);
	
	_color1 = [[NSColor colorWithCalibratedRed:208.0 / 255.0 green:208.0 / 255.0 blue:208.0 / 255.0 alpha:1.0] retain];
	_color2 = [[NSColor colorWithCalibratedRed:233.0 / 255.0 green:233.0 / 255.0 blue:233.0 / 255.0 alpha:1.0] retain];
	
	return self;
}



- (void)dealloc {
	CGFunctionRelease(_gradientFunction);
	
	[_color1 release];
	[_color2 release];
	
	[super dealloc];
}



#pragma mark -

- (void)drawRect:(NSRect)rect {
	CGContextRef		context;
	CGColorSpaceRef		colorSpace;
	CGShadingRef		shading;
	CGPoint				startPoint, endPoint;
	
  	startPoint = CGPointMake(rect.origin.x, rect.origin.y);
  	endPoint   = CGPointMake(rect.origin.x, rect.origin.y + rect.size.height);
  
	context = (CGContextRef) [[NSGraphicsContext currentContext] graphicsPort];
	CGContextSaveGState(context);
	
	colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
	shading = CGShadingCreateAxial(colorSpace, startPoint, endPoint, _gradientFunction, false, false);
	
	CGContextClipToRect(context, CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height));
	CGContextDrawShading(context, shading);
	
	CGShadingRelease(shading);
	CGColorSpaceRelease(colorSpace );
	CGContextRestoreGState(context);
}

@end
