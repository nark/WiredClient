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

#import <WiredAppKit/WITextAttachment.h>
#import <WiredAppKit/NSAttributedString-WIAppKit.h>

@implementation NSAttributedString(WIAppKit)

+ (id)attributedString {
	return [[[self alloc] initWithString:@""] autorelease];
}



+ (id)attributedStringWithString:(NSString *)string {
	return [[[self alloc] initWithString:string] autorelease];
}



+ (id)attributedStringWithString:(NSString *)string attributes:(NSDictionary *)attributes {
	return [[[self alloc] initWithString:string attributes:attributes] autorelease];
}



#pragma mark -

- (NSAttributedString *)attributedStringByApplyingFilter:(WITextFilter *)filter {
	NSMutableAttributedString	*string;
	
	string = [self mutableCopy];
	[string applyFilter:filter];
	
	return [string autorelease];
}



- (NSAttributedString *)attributedStringByReplacingAttachmentsWithStrings {
	NSMutableAttributedString	*string;
	
	string = [self mutableCopy];
	[string replaceAttachmentsWithStrings];
	
	return [string autorelease];
}

@end



@implementation NSMutableAttributedString(WIAppKit)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"

- (void)addAttribute:(NSString *)name value:(id)value {
	[self addAttribute:name value:value range:NSMakeRange(0, [self length])];
}



#pragma mark -

- (void)applyFilter:(WITextFilter *)filter {
	[filter performSelector:@selector(filter:) withObject:self];
}



#pragma mark -

- (void)replaceAttachmentsWithStrings {
	NSString		*string, *markerString;
	id				attachment;
	NSRange			range, searchRange;
	
	if(![self containsAttachments])
		return;
	
	markerString			= [NSString stringWithFormat:@"%C", (unichar)NSAttachmentCharacter];
	searchRange.location	= 0;
	searchRange.length		= [self length];
	
	while((range = [[self string] rangeOfString:markerString options:NSLiteralSearch range:searchRange]).location != NSNotFound) {
		attachment = [self attribute:NSAttachmentAttributeName
							 atIndex:range.location
					  effectiveRange:nil];
		
		[attachment retain];
		
		if([attachment isKindOfClass:[WITextAttachment class]])
			string = [attachment string];
		else
			string = @"<<attachment>>";
		
		[self removeAttribute:NSAttachmentAttributeName range:range];
		[self replaceCharactersInRange:range withString:string];
		
		searchRange.location	= range.location + [string length];
		searchRange.length		= [self length] - searchRange.location;
		
		[attachment release];
	}
}

#pragma clang diagnostic pop

@end
