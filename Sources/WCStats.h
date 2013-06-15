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

extern NSString * const WCStatsDownloaded;
extern NSString * const WCStatsUploaded;
extern NSString * const WCStatsChat;
extern NSString * const WCStatsOnline;
extern NSString * const WCStatsMessagesSent;
extern NSString * const WCStatsMessagesReceived;


@interface WCStats : WIObject {
	NSMutableDictionary					*_stats;
	NSDate								*_date;
	NSRecursiveLock						*_lock;
	NSUInteger							_connections;
	
	WISizeFormatter						*_sizeFormatter;
	WITimeIntervalFormatter				*_timeIntervalFormatter;
	
	EventHandlerRef						_eventHandlerRef;
}

+ (WCStats *)stats;

- (unsigned int)unsignedIntForKey:(id)key;
- (unsigned long long)unsignedLongLongForKey:(id)key;
- (void)setUnsignedInt:(unsigned int)number forKey:(id)key;
- (void)setUnsignedLongLong:(unsigned long long)number forKey:(id)key;
- (void)addUnsignedInt:(unsigned int)number forKey:(id)key;
- (void)addUnsignedLongLong:(unsigned long long)number forKey:(id)key;

- (NSString *)stringValue;

@end
