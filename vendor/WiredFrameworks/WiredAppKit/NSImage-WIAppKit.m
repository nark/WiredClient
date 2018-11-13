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

#import <WiredFoundation/NSObject-WIFoundation.h>
#import <WiredAppKit/NSBezierPath-WIAppKit.h>
#import <WiredAppKit/NSImage-WIAppKit.h>

#import <WiredAppKit/CTBadge.h>

@implementation NSImage(WIAppKit)

+ (NSImage *)imageWithData:(NSData *)data {
	return [[[self alloc] initWithData:data] autorelease];
}



+ (NSImage *)imageWithContentsOfFile:(NSString *)file {
	return [[[self alloc] initWithContentsOfFile:file] autorelease];
}



+ (NSImage *)imageWithPillForCount:(NSUInteger)count inActiveWindow:(BOOL)inActiveWindow onSelectedRow:(BOOL)onSelectedRow {
	NSDictionary		*attributes;
	NSColor				*backgroundColor, *textColor;
	NSImage				*image;
	NSSize				size;
	
	if(count == 0)
		return NULL;
	
	if(count < 10)
		size.width = 20.0;
	else if(count < 100)
		size.width = 27.0;
	else if(count < 1000)
		size.width = 34.0;
	else
		size.width = 39.0;
	
	size.height = 14.0;
	
	image = [[NSImage alloc] initWithSize:size];
	
	[image lockFocus];
	
	if(onSelectedRow) {
		if(inActiveWindow) {
			backgroundColor		= [NSColor whiteColor];
			textColor			= [NSColor colorWithCalibratedRed:136.0 / 255.0 green:160.0 / 255.0 blue:214.0 / 255.0 alpha:1.0];
		} else {
			backgroundColor		= [NSColor whiteColor];
			textColor			= [NSColor colorWithCalibratedWhite:166.0 / 255.0 alpha:1.0];
		}
	} else {
		if(inActiveWindow) {
			backgroundColor		= [NSColor colorWithCalibratedRed:136.0 / 255.0 green:160.0 / 255.0 blue:214.0 / 255.0 alpha:1.0];
			textColor			= [NSColor whiteColor];
		} else {
			backgroundColor		= [NSColor colorWithCalibratedWhite:166.0 / 255.0 alpha:1.0];
			textColor			= [NSColor whiteColor];
		}
	}
	
	[backgroundColor set];
	[[NSBezierPath bezierPathWithRoundedRect:NSMakeRect(0.0, 0.0, size.width, size.height) cornerRadius:7.0] fill];
	
	attributes = [NSDictionary dictionaryWithObjectsAndKeys:
				  [NSFont boldSystemFontOfSize:11.0],
				  NSFontAttributeName,
				  textColor,
				  NSForegroundColorAttributeName,
				  NULL];
	
	[[NSSWF:@"%lu", (unsigned long)count] drawInRect:NSMakeRect(6.0, 0.0, size.width, size.height) withAttributes:attributes];
	
	[image unlockFocus];
	
	return [image autorelease];
}



#pragma mark -

- (NSImage *)tintedImageWithColor:(NSColor *)color {
	NSImage		*image;
	NSSize		size;
    NSRect      rect;

	size = [self size];
    rect = NSMakeRect(0, 0, [self size].width, [self size].height);
    
	image = [[NSImage alloc] initWithSize:size];
	[image lockFocus];

	[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationNone];
	[[NSGraphicsContext currentContext] setShouldAntialias:NO];

	[self compositeToPoint:NSZeroPoint operation:NSCompositeSourceOver];
    //[self drawAtPoint:NSZeroPoint fromRect:rect operation:NSCompositeSourceOver fraction:1.0];
    
	[color set];
	NSRectFillUsingOperation(NSMakeRect(0, 0, size.width, size.height), NSCompositeSourceAtop);
	[image unlockFocus];

	return [image autorelease];
}



- (NSImage *)badgedImageWithInt:(NSUInteger)unread {
    CTBadge                 *ctBadge;
	static NSImage			*badgeImage;
	NSImage					*image, *badge;
	NSRect					badgeRect;
	NSSize					size;
	BOOL					small;

	if(unread == 0)
		return self;
	
    ctBadge     = [CTBadge systemBadge];
    badgeImage  = [ctBadge badgeOfSize:14.0 forValue:(unsigned int)unread];
	size        = [self size];
	small       = (size.width == 32.0);
	badge       = badgeImage;

    badgeRect.origin	= NSMakePoint(([self size].width-[badge size].width), 1.0);
    badgeRect.size		= [badge size];
    
	image = [[NSImage alloc] initWithSize:small ? NSMakeSize(32.0, 32.0) : NSMakeSize(128.0, 128.0)];
	[image lockFocus];

	[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
	[[NSGraphicsContext currentContext] setShouldAntialias:YES];
    
    [self drawInRect:small ? NSMakeRect(0.0, 0.0, 32.0, 32.0) : NSMakeRect(0.0, 0.0, 128.0, 128.0)
			fromRect:NSMakeRect(0.0, 0.0, size.width, size.width)
		   operation:NSCompositeSourceOver
			fraction:1.0];
    
    [badgeImage drawInRect:badgeRect
			 fromRect:NSMakeRect(0.0, 0.0, [badgeImage size].width, [badgeImage size].height)
			operation:NSCompositeSourceOver
			 fraction:1.0];
    
	[image unlockFocus];
    
	return [image autorelease];
    
    
}



- (NSImage *)scaledImageWithSize:(NSSize)size {
	NSAffineTransform   *transform;
	NSImage				*image;
	NSImageRep			*imageRep;
	NSSize				imageSize, scaledSize;
	CGFloat				scale, height, width;
	
	imageRep = [[self representations] objectAtIndex:0];
	imageSize = [self size];
	height = size.height / imageSize.height;
	width = size.width / imageSize.width;
	scale = height > width ? width : height;
	
	if(scale >= 1.0)
		return self;
	
	transform = [NSAffineTransform transform];
	[transform scaleBy:scale];
	scaledSize = [transform transformSize:imageSize];
	
	image = [[NSImage alloc] initWithSize:size];
	[image lockFocus];
	[imageRep drawInRect:NSMakeRect((size.width - scaledSize.width) / 2.0, (size.height - scaledSize.height) / 2.0, scaledSize.width, scaledSize.height)];
	[image unlockFocus];

	return [image autorelease];
}



- (NSImage *)mirroredImage {
	NSAffineTransform			*transform;
	NSAffineTransformStruct		flip = { -1.0, 0.0, 0.0, 1.0, [self size].width, 0.0 };

	transform = [NSAffineTransform transform];
	[transform setTransformStruct:flip];

	return [self imageWithAffineTransform:transform action:@selector(concat)];
}



- (NSImage *)imageBySuperimposingImage:(NSImage *)image {
	NSImage			*newImage;
	NSSize			size;

	size = [self size];
	[image setSize:size];
	
	newImage = [[NSImage alloc] initWithSize:size];
	[newImage lockFocus];

	[self drawAtPoint:NSZeroPoint
			 fromRect:NSMakeRect(0.0, 0.0, size.width, size.height)
			operation:NSCompositeSourceOver
			 fraction:1.0];

	[image drawAtPoint:NSZeroPoint
			 fromRect:NSMakeRect(0.0, 0.0, size.width, size.height)
			operation:NSCompositeSourceOver
			 fraction:1.0];

	[newImage unlockFocus];

	return [newImage autorelease];
}



#pragma mark -

- (NSImage *)imageWithAffineTransform:(NSAffineTransform *)transform action:(SEL)action {
	NSImage		*image;
	NSSize		size;

	size = [self size];
	image = [[NSImage alloc] initWithSize:size];

	[image lockFocus];
	[transform performSelector:action];
	[self drawAtPoint:NSZeroPoint
			 fromRect:NSMakeRect(0.0, 0.0, size.width, size.height)
			operation:NSCompositeCopy
			 fraction:1.0];
	[image unlockFocus];

	return [image autorelease];
}

@end
