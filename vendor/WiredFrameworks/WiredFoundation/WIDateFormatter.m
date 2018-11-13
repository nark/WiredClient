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

#import <WiredFoundation/WIDateFormatter.h>

@interface WIDateFormatter(Private)

- (BOOL)_isRFC3339;
- (void)_setRFC3339:(BOOL)value;

@end


@implementation WIDateFormatter(Private)

- (BOOL)_isRFC3339 {
	return _rfc3339;
}



- (void)_setRFC3339:(BOOL)value {
	_rfc3339 = value;
}

@end



@implementation WIDateFormatter

+ (WIDateFormatter *)dateFormatterForRFC3339 {
	static WIDateFormatter		*dateFormatter;
	
	if(!dateFormatter) {
		dateFormatter = [[self alloc] init];
		[dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
		[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZ"];
		[dateFormatter _setRFC3339:YES];
	}
	
	return dateFormatter;
}



#pragma mark -

- (void)setNaturalLanguageStyle:(WIDateFormatterNaturalLanguageStyle)style {
	_naturalLanguageStyle = style;
}



- (WIDateFormatterNaturalLanguageStyle)naturalLanguageStyle {
	return _naturalLanguageStyle;
}



#pragma mark -

- (NSString *)stringFromDate:(NSDate *)date {
	NSMutableString			*string;
	NSString				*timeString, *dateString;
	NSDateFormatterStyle	style;
	NSUInteger				day, today;
	
	if(_naturalLanguageStyle != WIDateFormatterNoNaturalLanguageStyle) {
		day = [[NSCalendar currentCalendar] ordinalityOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitYear forDate:date];
		today = [[NSCalendar currentCalendar] ordinalityOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitYear forDate:[NSDate date]];
		
		if(day == today)
			dateString = WILS(@"today", @"WIDateFormatter: this day");
		else if(day == today - 1)
			dateString = WILS(@"yesterday", @"WIDateFormatter: prior day");
		else if(day == today + 1)
			dateString = WILS(@"tomorrow", @"WIDateFormatter: next day");
		else
			return [super stringFromDate:date];
		
		if(_naturalLanguageStyle == WIDateFormatterCapitalizedNaturalLanguageStyle)
			dateString = [dateString capitalizedString];
		else
			dateString = [dateString lowercaseString];
		
		style = [self dateStyle];
		[self setDateStyle:NSDateFormatterNoStyle];
		timeString = [super stringFromDate:date];
		[self setDateStyle:style];
		
		return [NSSWF:@"%@ %@", dateString, timeString];
	}
	
	if([self _isRFC3339]) {
		string = [[super stringFromDate:date] mutableCopy];
		
		[string insertString:@":" atIndex:22];
		
		return [string autorelease];
	}
	
	return [super stringFromDate:date];
}

@end
