/* $Id$ */

/*
 *  Copyright (c) 2009 Axel Andersson
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

#import <WiredFoundation/WISizeFormatter.h>

@implementation WISizeFormatter

- (id)init {
	self = [super init];
	
	if(self) {
		_numberFormatter = [[NSNumberFormatter alloc] init];
		[_numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
		[_numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
		[_numberFormatter setMaximumFractionDigits:1];
		
		_rawNumberFormatter = [[NSNumberFormatter alloc] init];
		[_rawNumberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
		[_rawNumberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
	}
	
	return self;
}



- (void)dealloc {
	[_numberFormatter release];
	[_rawNumberFormatter release];
	
	[super dealloc];
}



#pragma mark -

- (void)setSizeStyle:(WISizeFormatterStyle)sizeStyle {
	_sizeStyle = sizeStyle;
}



- (WISizeFormatterStyle)sizeStyle {
	return _sizeStyle;
}



- (void)setAppendsRawNumber:(BOOL)appendsRawNumber {
	_appendsRawNumber = appendsRawNumber;
}



- (BOOL)appendsRawNumber {
	return _appendsRawNumber;
}



#pragma mark -

- (NSString *)stringFromSize:(unsigned long long)size {
	NSString		*string, *unit;
	double			kb, mb, gb, tb, pb;
	
	kb = (double) size / 1024.0;
	mb = (double) kb   / 1024.0;
	gb = (double) mb   / 1024.0;
	tb = (double) gb   / 1024.0;
	pb = (double) tb   / 1024.0;

	if(size < 1000) {
		if([self sizeStyle] == WISizeFormatterStyleBytes) {
			if(size == 1)
				unit = WILS(@"byte", @"WISizeFormatter: byte size strings");
			else
				unit = WILS(@"bytes", @"WISizeFormatter: byte size strings");
		} else {
			if(size == 1)
				unit = WILS(@"bit", @"WISizeFormatter: bit size strings");
			else
				unit = WILS(@"bits", @"WISizeFormatter: bit size strings");
		}

		string = [NSSWF:@"%llu %@", size, unit];
	}
	else if(kb < 1000.0) {
		if([self sizeStyle] == WISizeFormatterStyleBytes)
			unit = WILS(@"KB", @"WISizeFormatter: byte size strings");
		else
			unit = WILS(@"Kbit", @"WISizeFormatter: byte size strings");
		
		string = [NSSWF:@"%@ %@", [_numberFormatter stringFromNumber:[NSNumber numberWithDouble:kb]], unit];
	}
	else if(mb < 1000.0) {
		if([self sizeStyle] == WISizeFormatterStyleBytes)
			unit = WILS(@"MB", @"WISizeFormatter: byte size strings");
		else
			unit = WILS(@"Mbit", @"WISizeFormatter: byte size strings");
		
		string = [NSSWF:@"%@ %@", [_numberFormatter stringFromNumber:[NSNumber numberWithDouble:mb]], unit];
	}
	else if(gb < 1000.0) {
		if([self sizeStyle] == WISizeFormatterStyleBytes)
			unit = WILS(@"GB", @"WISizeFormatter: byte size strings");
		else
			unit = WILS(@"Gbit", @"WISizeFormatter: byte size strings");
		
		string = [NSSWF:@"%@ %@", [_numberFormatter stringFromNumber:[NSNumber numberWithDouble:gb]], unit];
	}
	else if(tb < 1000.0) {
		if([self sizeStyle] == WISizeFormatterStyleBytes)
			unit = WILS(@"TB", @"WISizeFormatter: byte size strings");
		else
			unit = WILS(@"Tbit", @"WISizeFormatter: byte size strings");
		
		string = [NSSWF:@"%@ %@", [_numberFormatter stringFromNumber:[NSNumber numberWithDouble:tb]], unit];
	}
	else {
		if([self sizeStyle] == WISizeFormatterStyleBytes)
			unit = WILS(@"PB", @"WISizeFormatter: byte size strings");
		else
			unit = WILS(@"Pbit", @"WISizeFormatter: byte size strings");
		
		string = [NSSWF:@"%@ %@", [_numberFormatter stringFromNumber:[NSNumber numberWithDouble:pb]], unit];
	}
	
	if([self appendsRawNumber]) {
		if([self sizeStyle] == WISizeFormatterStyleBytes) {
			if(size == 1)
				unit = WILS(@"byte", @"WISizeFormatter: byte size strings");
			else
				unit = WILS(@"bytes", @"WISizeFormatter: byte size strings");
		} else {
			if(size == 1)
				unit = WILS(@"bit", @"WISizeFormatter: bit size strings");
			else
				unit = WILS(@"bits", @"WISizeFormatter: bit size strings");
		}
		
		string = [string stringByAppendingFormat:@" (%@ %@)",
			[_rawNumberFormatter stringFromNumber:[NSNumber numberWithUnsignedLongLong:size]],
			unit];
	}
	
	return string;
}



- (NSString *)stringFromNumber:(NSNumber *)number {
	return [self stringFromSize:[number unsignedLongLongValue]];
}



- (NSString *)stringForObjectValue:(id)object {
	return [self stringFromSize:[object unsignedLongLongValue]];
}

@end
