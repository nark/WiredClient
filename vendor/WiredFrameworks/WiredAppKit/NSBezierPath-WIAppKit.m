/* $Id$ */

/*
 *  Copyright (c) 2007-2009 Axel Andersson
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

#import <WiredAppKit/NSBezierPath-WIAppKit.h>

@implementation NSBezierPath(WIAppKit)

+ (NSBezierPath *)bezierPathWithRoundedRect:(NSRect)rect cornerRadius:(CGFloat)cornerRadius {
	NSBezierPath		*path;
	
	path = [self bezierPath];
	cornerRadius = MIN(cornerRadius, 0.5 * MIN(rect.size.width, rect.size.height));
	rect = NSInsetRect(rect, cornerRadius, cornerRadius);
	
	[path appendBezierPathWithArcWithCenter:NSMakePoint(rect.origin.x, rect.origin.y)
									 radius:cornerRadius
								 startAngle:180.0
								   endAngle:270.0];

	[path appendBezierPathWithArcWithCenter:NSMakePoint(rect.origin.x + rect.size.width, rect.origin.y)
									 radius:cornerRadius
								 startAngle:270.0
								   endAngle:360.0];

	[path appendBezierPathWithArcWithCenter:NSMakePoint(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height)
									 radius:cornerRadius
								 startAngle:0.0
								   endAngle:90.0];

	[path appendBezierPathWithArcWithCenter:NSMakePoint(rect.origin.x, rect.origin.y + rect.size.height)
									 radius:cornerRadius
								 startAngle:90.0
								   endAngle:180.0];

	[path closePath];

	return path;	
}

@end
