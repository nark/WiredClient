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

#import <WiredFoundation/NSDate-WIFoundation.h>

@implementation NSDate(WIFoundation)

+ (NSDate *)dateAtStartOfCurrentDay {
	return [[NSDate date] dateAtStartOfDay];
}



+ (NSDate *)dateAtStartOfCurrentWeek {
	return [[NSDate date] dateAtStartOfWeek];
}



+ (NSDate *)dateAtStartOfCurrentMonth {
	return [[NSDate date] dateAtStartOfMonth];
}



+ (NSDate *)dateAtStartOfCurrentYear {
	return [[NSDate date] dateAtStartOfYear];
}



#pragma mark -

- (NSDate *)dateAtStartOfDay {
	NSDateComponents	*components;
	
	components = [[NSCalendar currentCalendar] components:NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:self];
	
	[components setHour:-[components hour]];
	[components setMinute:-[components minute]];
	[components setSecond:-[components second]];
	
	return [[NSCalendar currentCalendar] dateByAddingComponents:components toDate:self options:0];
}



- (NSDate *)dateAtStartOfWeek {
	NSDate				*date;
	NSDateComponents	*components;
	NSInteger			firstWeekday;
	
	date			= [self dateAtStartOfDay];
	firstWeekday	= [[NSCalendar currentCalendar] firstWeekday];
	components		= [[NSCalendar currentCalendar] components:NSCalendarUnitWeekday fromDate:date];
	
	if([components weekday] < firstWeekday)
		[components setWeekday:-[components weekday] + firstWeekday - 7];
	else
		[components setWeekday:-[components weekday] + firstWeekday];
	
	return [[NSCalendar currentCalendar] dateByAddingComponents:components toDate:date options:0];
}



- (NSDate *)dateAtStartOfMonth {
	NSDate				*date;
	NSDateComponents	*components;
	
	date			= [self dateAtStartOfDay];
	components		= [[NSCalendar currentCalendar] components:NSCalendarUnitDay fromDate:date];
	
	[components setDay:-[components day] + 1];
	
	return [[NSCalendar currentCalendar] dateByAddingComponents:components toDate:date options:0];
}



- (NSDate *)dateAtStartOfYear {
	NSDate				*date;
	NSDateComponents	*components;
	
	date			= [self dateAtStartOfMonth];
	components		= [[NSCalendar currentCalendar] components:NSCalendarUnitMonth fromDate:date];
	
	[components setMonth:-[components month] + 1];
	
	return [[NSCalendar currentCalendar] dateByAddingComponents:components toDate:date options:0];
}



#pragma mark -

- (BOOL)isAtBeginningOfAnyEpoch {
	return ([self isEqualToDate:[NSDate dateWithTimeIntervalSince1970:0.0]] ||
			[self isEqualToDate:[NSDate dateWithTimeIntervalSinceReferenceDate:0.0]]);
}



- (NSDate *)dateByAddingDays:(NSInteger)days {
	NSDateComponents	*components;
	
	components = [[[NSDateComponents alloc] init] autorelease];
	[components setDay:days];
	
	return [[NSCalendar currentCalendar] dateByAddingComponents:components toDate:self options:0];
}

@end





@implementation NSDate (Javascript)

- (NSString *)JSDate {
    NSDateFormatter     *dateFormatter;
    NSCalendar          *calendar;
    NSString            *result;
    
    dateFormatter   = [[[NSDateFormatter alloc] init] autorelease];
    calendar        = [[[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian] autorelease];
    
    [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    [dateFormatter setCalendar:calendar];
    
    result = [dateFormatter stringFromDate:self];
    
    return (result ? result : @"");
}

@end
