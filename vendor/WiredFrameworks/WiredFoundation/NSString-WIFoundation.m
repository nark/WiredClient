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

#import <WiredFoundation/NSScanner-WIFoundation.h>
#import <WiredFoundation/NSString-WIFoundation.h>

@implementation NSString(WIFoundation)

+ (id)stringWithFormat:(NSString *)format arguments:(va_list)arguments {
	return [[[self alloc] initWithFormat:format arguments:arguments] autorelease];
}



+ (id)stringWithData:(NSData *)data encoding:(NSStringEncoding)encoding {
	return [[[self alloc] initWithData:data encoding:encoding] autorelease];
}



+ (id)stringWithBytes:(const void *)bytes length:(NSUInteger)length encoding:(NSStringEncoding)encoding {
	return [[[self alloc] initWithBytes:bytes length:length encoding:encoding] autorelease];
}



+ (id)stringWithRandomCharactersFromString:(NSString *)characters length:(NSUInteger)length {
	NSMutableString		*string;
	NSUInteger			count;
	
	string = [NSMutableString string];
	count = [characters length];
	
	while(length > 0) {
		[string appendFormat:@"%C", [characters characterAtIndex:random() % count]];
		
		length--;
	}
	
	return string;
}



+ (id)UUIDString { 
	NSString		*string;
	CFUUIDRef		uuidRef;
	CFStringRef		stringRef;

	uuidRef = CFUUIDCreate(NULL);
	stringRef = CFUUIDCreateString(NULL, uuidRef);
	CFRelease(uuidRef);
	
	string = [[self alloc] initWithString:(NSString *) stringRef];
	
	CFRelease(stringRef);
	
	return [string autorelease];
}



#pragma mark -

+ (NSString *)URLRegex {
	return @"(?:[a-zA-Z0-9\\-]+)"								/* Scheme */
    @"://"														/* "://" */
    @"(?:(?:\\S+?)(?::(?:\\S+?))?@)?"							/* Password and user */
    @"(?:[a-zA-Z0-9\\-.]+)"										/* Host name */
    @"(?::(?:\\d+))?"											/* Port */
    @"(?:(?:/[a-zA-Z0-9\\-._\\?,'+\\&;%#$=~*!():@\\\\]*)+)?";	/* Path */
}


+ (NSString *)fileURLRegex {
	return @"(?:[a-zA-Z0-9\\-]+)"								/* Scheme */
    @":///"														/* ":///" */
    @"?(?:(?:/[a-zA-Z0-9\\-._\\?,'+\\&;%#$=~*!():@\\\\]*)+)?";	/* Path */
}



+ (NSString *)schemelessURLRegex {
	return @"(?:www\\.[a-zA-Z0-9\\-.]+)"						/* Host name */
    @"(?::(?:\\d+))?"											/* Port */
    @"(?:(?:/[a-zA-Z0-9\\-._?,'+\\&;%#$=~*!():@\\\\]*)+)?";		/* Path */
}



+ (NSString *)mailtoURLRegex {
	return @"(?:[a-zA-Z0-9%_.+\\-]+)"							/* User */
    @"@"														/* "@" */
    @"(?:[a-zA-Z0-9.\\-]+?\\.[a-zA-Z]{2,6})";					/* Host name */
}


+ (NSString *)htmlRegex {
	return @"<([A-Z][A-Z0-9]*)\b[^>]*>(.*?)</\1>";				/* Any HTML tag */
}




#pragma mark -

- (NSUInteger)UTF8StringLength {
	return strlen([self UTF8String]);
}



- (unsigned long long)unsignedLongLongValue {
	return (unsigned long long) [self longLongValue];
}



- (unsigned int)unsignedIntValue {
	return (unsigned int) [self intValue];
}



- (NSUInteger)unsignedIntegerValue {
	return (NSUInteger) [self integerValue];
}



#pragma mark -

- (BOOL)containsSubstring:(NSString *)string {
	return ([self rangeOfString:string].location != NSNotFound);
}
 

- (BOOL)containsSubstring:(NSString *)string options:(NSUInteger)options {
	return ([self rangeOfString:string options:options].location != NSNotFound);
}
 

- (BOOL)containsCharactersFromSet:(NSCharacterSet *)set {
	return ([self rangeOfCharacterFromSet:set].location != NSNotFound);
}



- (BOOL)isComposedOfCharactersFromSet:(NSCharacterSet *)set {
	return ![self containsCharactersFromSet:[set invertedSet]];
}



#pragma mark -

- (NSArray *)componentsSeparatedByCharactersFromSet:(NSCharacterSet *)set {
	NSScanner		*scanner;
	NSMutableArray	*components;
	NSCharacterSet	*invertedSet;
	NSString		*string;

	if([self length] == 0)
		return NULL;

	if(![self containsCharactersFromSet:set])
		return [NSArray arrayWithObject:self];

	scanner = [NSScanner scannerWithString:self];
	components = [NSMutableArray array];
	invertedSet = [set invertedSet];
		
	while(![scanner isAtEnd]) {
		[scanner scanUpToCharactersFromSet:set intoString:&string];
		[scanner scanUpToCharactersFromSet:invertedSet intoString:NULL];
		
		if([string length] > 0)
			[components addObject:string];
	}

	return components;
}



#pragma mark -

- (NSString *)stringByReplacingOccurencesOfString:(NSString *)target withString:(NSString *)replacement {
	NSMutableString		*string;

	string = [self mutableCopy];

	[string replaceOccurrencesOfString:target
							withString:replacement
							   options:0
								 range:NSMakeRange(0, [string length])];

	return [string autorelease];
}



- (NSString *)stringByReplacingOccurencesOfStrings:(NSArray *)targets withString:(NSString *)replacement {
	NSMutableString		*string;
	NSEnumerator		*enumerator;
	NSString			*target;

	string = [self mutableCopy];
	enumerator = [targets objectEnumerator];

	while((target = [enumerator nextObject])) {
		[string replaceOccurrencesOfString:target
								withString:replacement
								   options:0
									 range:NSMakeRange(0, [string length])];
	}

	return [string autorelease];
}



#pragma mark -

- (NSString *)stringByAddingPercentEscapesUsingEncoding:(NSStringEncoding)encoding charactersToLeaveUnescaped:(NSString *)charactersToLeaveUnescaped {
	return [(NSString *) CFURLCreateStringByAddingPercentEscapes(NULL,
																 (CFStringRef) self,
																 (CFStringRef) charactersToLeaveUnescaped,
																 NULL,
																 CFStringConvertNSStringEncodingToEncoding(encoding)) autorelease];
}



- (NSString *)stringByAddingPercentEscapesUsingEncoding:(NSStringEncoding)encoding legalURLCharactersToBeEscaped:(NSString *)legalURLCharactersToBeEscaped {
	return [(NSString *) CFURLCreateStringByAddingPercentEscapes(NULL,
																 (CFStringRef) self,
																 NULL,
																 (CFStringRef) legalURLCharactersToBeEscaped,
																 CFStringConvertNSStringEncodingToEncoding(encoding)) autorelease];
}



#pragma mark -

- (NSString *)stringByReplacingPathExtensionWithExtension:(NSString *)extension {
	return [[self stringByDeletingPathExtension] stringByAppendingPathExtension:extension];
}



#pragma mark -

- (NSString *)stringByApplyingFilter:(WITextFilter *)filter {
	NSMutableString	*string;
	
	string = [self mutableCopy];
	[string applyFilter:filter];
	
	return [string autorelease];
}



#pragma mark -

- (NSComparisonResult)caseInsensitiveAndNumericCompare:(NSString *)string { 
	return [self compare:string
				 options:NSCaseInsensitiveSearch | NSNumericSearch
				   range:NSMakeRange(0, [self length])
				  locale:[NSLocale currentLocale]];
}



- (NSComparisonResult)finderCompare:(NSString *)string { 
	return [self compare:string
				 options:NSCaseInsensitiveSearch | NSNumericSearch | 256 /* NSWidthInsensitiveSearch */ | 512 /* NSForcedOrderingSearch */
				   range:NSMakeRange(0, [self length])
				  locale:[NSLocale currentLocale]];
}

@end



@implementation NSString(WIStringChecksumming)

- (NSString *)SHA1 {
	CC_SHA1_CTX				c;
	static unsigned char	hex[] = "0123456789abcdef";
	unsigned char			sha[CC_SHA1_DIGEST_LENGTH];
	char					text[CC_SHA1_DIGEST_LENGTH * 2 + 1];
	NSUInteger				i;
	
	CC_SHA1_Init(&c);
	CC_SHA1_Update(&c, [self UTF8String], (CC_LONG)[self UTF8StringLength]);
	CC_SHA1_Final(sha, &c);
	
	for(i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
		text[i + i]			= hex[sha[i] >> 4];
		text[i + i + 1]		= hex[sha[i] & 0x0F];
	}
	
	text[i + i] = '\0';
	
	return [NSString stringWithUTF8String:text];
}

@end



@implementation NSString(WIHumanReadableStringFormatting)

+ (NSString *)humanReadableStringForTimeInterval:(NSTimeInterval)interval {
	NSString		*string;
	NSUInteger		days, hours, minutes, seconds;
	BOOL			past = NO;

	interval = rint(interval);

	if(interval < 0) {
		past = YES;
		interval = -interval;
	}

	days = interval / 86400;
	interval -= days * 86400;

	hours = interval / 3600;
	interval -= hours * 3600;

	minutes = interval / 60;
	interval -= minutes * 60;

	seconds = interval;

	if(days > 0) {
		string = [NSSWF:
			WILS(@"%lu:%0.2lu:%0.2lu:%0.2lu days", @"NSString-WIFoundation: time strings (days, hours, minutes, seconds)"),
			days, hours, minutes, seconds];
	}
	else if(hours > 0) {
		string = [NSSWF:
			WILS(@"%0.2lu:%0.2lu:%0.2lu hours", @"NSString-WIFoundation: time strings (hours, minutes, seconds)"),
			hours, minutes, seconds];
	}
	else if(minutes > 0) {
		string = [NSSWF:
			WILS(@"%0.2lu:%0.2lu minutes", @"NSString-WIFoundation: time strings (minutes, seconds)"),
			minutes, seconds];
	}
	else {
		string = [NSSWF:
			WILS(@"00:%0.2lu seconds", @"NSString-WIFoundation: time string (minutes, seconds)"),
			seconds];
	}

	if(past)
		string = [NSSWF:WILS(@"%@ ago", @"NSString-WIFoundation: time string"), string];

	return string;
}



+ (NSString *)humanReadableStringForSizeInBytes:(unsigned long long)size {
	static NSNumberFormatter	*formatter;
	double						kb, mb, gb, tb, pb;

	if(!formatter) {
		formatter = [[NSNumberFormatter alloc] init];
		[formatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
		[formatter setNumberStyle:NSNumberFormatterDecimalStyle];
		[formatter setMaximumFractionDigits:1];
	}

	if(size < 1000) {
		return [NSSWF:WILS(@"%llu bytes", @"NSString-WIFoundation: byte size strings"),
			size];
	}

	kb = (double) size / 1024.0;

	if(kb < 1000) {
		return [NSSWF:WILS(@"%@ KB", @"NSString-WIFoundation: byte size strings"),
			[formatter stringForObjectValue:[NSNumber numberWithDouble:kb]]];
	}

	mb = (double) kb / 1024.0;

	if(mb < 1000) {
		return [NSSWF:WILS(@"%@ MB", @"NSString-WIFoundation: byte size strings"),
			[formatter stringForObjectValue:[NSNumber numberWithDouble:mb]]];
	}

	gb = (double) mb / 1024.0;

	if(gb < 1000) {
		return [NSSWF:WILS(@"%@ GB", @"NSString-WIFoundation: byte size strings"),
			[formatter stringForObjectValue:[NSNumber numberWithDouble:gb]]];
	}

	tb = (double) gb / 1024.0;

	if(tb < 1000) {
		return [NSSWF:WILS(@"%@ TB", @"NSString-WIFoundation: byte size strings"),
			[formatter stringForObjectValue:[NSNumber numberWithDouble:tb]]];
	}

	pb = (double) tb / 1024.0;

	if(pb < 1000) {
		return [NSSWF:WILS(@"%@ PB", @"NSString-WIFoundation: byte size strings"),
			[formatter stringForObjectValue:[NSNumber numberWithDouble:pb]]];
	}

	return NULL;
}



+ (NSString *)humanReadableStringForSizeInBytes:(unsigned long long)size withBytes:(BOOL)bytes {
	static NSNumberFormatter   *formatter;
	NSString					*string;

	string = [NSString humanReadableStringForSizeInBytes:size];

	if(size > 1024 && bytes) {
		if(!formatter) {
			formatter = [[NSNumberFormatter alloc] init];
			[formatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
			[formatter setNumberStyle:NSNumberFormatterDecimalStyle];
		}

		string = [NSSWF:@"%@ (%@ %@)",
			string,
			[formatter stringForObjectValue:[NSNumber numberWithUnsignedLongLong:size]],
			size == 1
				? WILS(@"byte", @"NSString-WIFoundation: 'byte' singular")
				: WILS(@"bytes", @"NSString-WIFoundation: 'byte' plural")];
	}

	return string;
}



+ (NSString *)humanReadableStringForSizeInBits:(unsigned long long)size {
	static NSNumberFormatter	*formatter;
	double						kb, mb, gb, tb, pb;
	
	if(!formatter) {
		formatter = [[NSNumberFormatter alloc] init];
		[formatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
		[formatter setNumberStyle:NSNumberFormatterDecimalStyle];
		[formatter setMaximumFractionDigits:1];
	}
	
	if(size < 1000) {
		return [NSSWF:WILS(@"%llu bits", @"NSString-WIFoundation: bit size strings"),
			size];
	}
	
	kb = (double) size / 1024.0;
	
	if(kb < 1000) {
		return [NSSWF:WILS(@"%@ kbit", @"NSString-WIFoundation: bit size strings"),
			[formatter stringForObjectValue:[NSNumber numberWithDouble:kb]]];
	}
	
	mb = (double) kb / 1024.0;
	
	if(mb < 1000) {
		return [NSSWF:WILS(@"%@ Mbit", @"NSString-WIFoundation: bit size strings"),
			[formatter stringForObjectValue:[NSNumber numberWithDouble:mb]]];
	}
	
	gb = (double) mb / 1024.0;
	
	if(gb < 1000) {
		return [NSSWF:WILS(@"%@ Gbit", @"NSString-WIFoundation: bit size strings"),
			[formatter stringForObjectValue:[NSNumber numberWithDouble:gb]]];
	}
	
	tb = (double) gb / 1024.0;
	
	if(tb < 1000) {
		return [NSSWF:WILS(@"%@ Tbit", @"NSString-WIFoundation: bit size strings"),
			[formatter stringForObjectValue:[NSNumber numberWithDouble:tb]]];
	}
	
	pb = (double) tb / 1024.0;
	
	if(pb < 1000) {
		return [NSSWF:WILS(@"%@ Pbit", @"NSString-WIFoundation: bit size strings"),
			[formatter stringForObjectValue:[NSNumber numberWithDouble:pb]]];
	}
	
	return NULL;
}



+ (NSString *)humanReadableStringForBandwidth:(NSUInteger)speed {
	if(speed > 0) {
		if(speed <= 3600)
			return WILS(@"28.8k Modem", @"NSString-WIFoundation: bandwidth strings");
		else if(speed <= 4200)
			return WILS(@"33.6k Modem", @"NSString-WIFoundation: bandwidth strings");
		else if(speed <= 7000)
			return WILS(@"56k Modem", @"NSString-WIFoundation: bandwidth strings");
		else if(speed <= 8000)
			return WILS(@"64k ISDN", @"NSString-WIFoundation: bandwidth strings");
		else if(speed <= 16000)
			return WILS(@"128k ISDN/DSL", @"NSString-WIFoundation: bandwidth strings");
		else if(speed <= 32000)
			return WILS(@"256k DSL/Cable", @"NSString-WIFoundation: bandwidth strings");
		else if(speed <= 48000)
			return WILS(@"384k DSL/Cable", @"NSString-WIFoundation: bandwidth strings");
		else if(speed <= 64000)
			return WILS(@"512k DSL/Cable", @"NSString-WIFoundation: bandwidth strings");
		else if(speed <= 96000)
			return WILS(@"768k DSL/Cable", @"NSString-WIFoundation: bandwidth strings");
		else if(speed <= 128000)
			return WILS(@"1M DSL/Cable", @"NSString-WIFoundation: bandwidth strings");
		else if(speed <= 256000)
			return WILS(@"2M DSL/Cable", @"NSString-WIFoundation: bandwidth strings");
		else if(speed <= 1280000)
			return WILS(@"10M LAN", @"NSString-WIFoundation: bandwidth strings");
		else if(speed <= 12800000)
			return WILS(@"100M LAN", @"NSString-WIFoundation: bandwidth strings");
	}
	
	return WILS(@"Unknown", @"NSString-WIFoundation: bandwidth strings");
}

@end



@implementation NSString(WIWiredVersionStringFormatting)

- (NSString *)wiredVersion {
	NSString			*unknown, *client, *clientVersion, *os, *osVersion, *arch;
	NSScanner			*scanner;
	const NXArchInfo	*info;

	// "Wired Client/1.0 (Darwin; 7.3.0; powerpc) (OpenSSL 0.9.6i Feb 19 2003; CoreFoundation 299.3; AppKit 743.20)"

	unknown = WILS(@"Unknown", @"NSString-WIFoundation: unknown Wired client");
	scanner = [NSScanner scannerWithString:self];
	[scanner setCharactersToBeSkipped:NULL];

	if(![scanner scanUpToString:@"/" intoString:&client])
		return unknown;

	if(![scanner scanString:@"/" intoString:NULL])
		return unknown;

	if(![scanner scanUpToString:@" " intoString:&clientVersion])
		return unknown;

	if(![scanner scanString:@" (" intoString:NULL])
		return unknown;

	if(![scanner scanUpToString:@";" intoString:&os])
		return unknown;

	if(![scanner scanString:@"; " intoString:NULL])
		return unknown;

	if(![scanner scanUpToString:@";" intoString:&osVersion])
		return unknown;

	if(![scanner scanString:@"; " intoString:NULL])
		return unknown;

	if(![scanner scanUpToString:@")" intoString:&arch])
		return unknown;

	if([arch isEqualToString:@"powerpc"])
		arch = @"ppc";
	
	info = NXGetArchInfoFromName([arch UTF8String]);
	
	if(info)
		arch = [NSSWF:@"%s", info->description];

	return [NSSWF:
		WILS(@"%@ %@ on %@ %@ (%@)", @"NSString-WIFoundation: Wired client version (client, client version, os, os version, architecture)"),
		client, clientVersion, os, osVersion, arch];
}

@end


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"

@implementation NSMutableString(WIFoundation)

- (void)deleteCharactersToIndex:(NSUInteger)index {
	[self deleteCharactersInRange:NSMakeRange(0, index)];
}



- (void)deleteCharactersFromIndex:(NSUInteger)index {
	[self deleteCharactersInRange:NSMakeRange(index, [self length] - index)];
}



- (NSUInteger)replaceOccurrencesOfString:(NSString *)target withString:(NSString *)replacement {
	return [self replaceOccurrencesOfString:target withString:replacement options:0 range:NSMakeRange(0, [self length])];
}



- (NSUInteger)replaceOccurrencesOfString:(NSString *)target withString:(NSString *)replacement options:(NSUInteger)options {
	return [self replaceOccurrencesOfString:target withString:replacement options:options range:NSMakeRange(0, [self length])];
}



- (void)trimCharactersInSet:(NSCharacterSet *)characterSet {
	[self setString:[self stringByTrimmingCharactersInSet:characterSet]];
}



- (void)applyFilter:(WITextFilter *)filter {
    [filter performSelector:@selector(filter:) withObject:self];
}

#pragma clang diagnostic pop

@end
