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

#import <WiredAppKit/NSAttributedString-WIAppKit.h>
#import <WiredAppKit/NSFont-WIAppKit.h>

NSString * WIStringFromFont(NSFont *font) {
	return [NSSWF:@"NSFont %@ %f", [font fontName], [font pointSize]];
}



NSFont * WIFontFromString(NSString *string) {
	NSArray		*array;
	NSFont		*font;
	
	array = [string componentsSeparatedByString:@" "];
	
	if([array count] != 3 || ![[array objectAtIndex:0] isEqualToString:@"NSFont"])
		return NULL;
	
	font = [NSFont fontWithName:[array objectAtIndex:1] size:[[array objectAtIndex:2] doubleValue]];
	
	if(!font)
		font = [NSFont systemFontOfSize:[[array objectAtIndex:2] doubleValue]];
	
	return font;
}



@implementation NSFont(WIAppKit)

+ (NSFont *)systemFont {
	return [self systemFontOfSize:0.0];
}



+ (NSFont *)smallSystemFont {
	return [self systemFontOfSize:[self smallSystemFontSize]];
}



+ (NSFont *)boldSystemFont {
	return [self boldSystemFontOfSize:0.0];
}



+ (NSFont *)smallBoldSystemFont {
	return [self boldSystemFontOfSize:[self smallSystemFontSize]];
}



+ (NSFont *)menuFont {
	return [self menuFontOfSize:0.0];
}



+ (NSFont *)titleBarFont {
	return [self titleBarFontOfSize:0.0];
}



#pragma mark -

- (NSFont *)fontByAddingTrait:(NSFontTraitMask)fontTrait {
	return [[NSFontManager sharedFontManager] convertFont:self toHaveTrait:fontTrait];
}



- (NSFont *)boldFont {
	return [self fontByAddingTrait:NSBoldFontMask];
}



- (NSFont *)italicFont {
	return [self fontByAddingTrait:NSItalicFontMask];
}



#pragma mark -

- (NSString *)displayNameWithSize {
	return [NSSWF:@"%@ %.1f", [self displayName], [self pointSize]];
}



- (NSSize)sizeOfString:(NSString *)string {
	static NSTextStorage	*textStorage;
	static NSLayoutManager  *layoutManager;
	static NSTextContainer  *textContainer;
	NSAttributedString		*attributedString;
	NSDictionary			*attributes;

	if(!textStorage) {
		textStorage = [[NSTextStorage alloc] init];

		layoutManager = [[NSLayoutManager alloc] init];
		[textStorage addLayoutManager:layoutManager];

		textContainer = [[NSTextContainer alloc] initWithContainerSize:NSMakeSize(100000, 100000)];
		[textContainer setLineFragmentPadding:0];
		[layoutManager addTextContainer:textContainer];
	}

	attributes = [NSDictionary dictionaryWithObject:self forKey:NSFontAttributeName];
	attributedString = [NSAttributedString attributedStringWithString:string attributes:attributes];
	[textStorage setAttributedString:attributedString];
	
	(void) [layoutManager glyphRangeForTextContainer:textContainer];
	
	return [layoutManager usedRectForTextContainer:textContainer].size;
}

@end
