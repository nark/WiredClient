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

#import <WiredFoundation/WITimeIntervalFormatter.h>

@implementation WITimeIntervalFormatter

- (NSString *)stringFromTimeInterval:(NSTimeInterval)interval {
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



- (NSString *)stringFromTimeIntervalSinceDate:(NSDate *)date {
	return [self stringFromTimeInterval:[[NSDate date] timeIntervalSinceDate:date]];
}



- (NSString *)stringFromNumber:(NSNumber *)number {
	return [self stringFromTimeInterval:[number doubleValue]];
}



- (NSString *)stringForObjectValue:(id)object {
	return [self stringFromTimeInterval:[object doubleValue]];
}

@end
