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

@class WITextFilter;

@interface NSString(WIFoundation)

+ (id)stringWithFormat:(NSString *)format arguments:(va_list)arguments;
+ (id)stringWithData:(NSData *)data encoding:(NSStringEncoding)encoding;
+ (id)stringWithBytes:(const void *)bytes length:(NSUInteger)length encoding:(NSStringEncoding)encoding;
+ (id)stringWithRandomCharactersFromString:(NSString *)string length:(NSUInteger)length;

+ (id)UUIDString;

+ (NSString *)URLRegex;
+ (NSString *)fileURLRegex;
+ (NSString *)schemelessURLRegex;
+ (NSString *)mailtoURLRegex;
+ (NSString *)htmlRegex;

- (NSUInteger)UTF8StringLength;
- (unsigned long long)unsignedLongLongValue;
- (unsigned int)unsignedIntValue;
- (NSUInteger)unsignedIntegerValue;

- (BOOL)containsSubstring:(NSString *)string;
- (BOOL)containsSubstring:(NSString *)string options:(NSUInteger)options;
- (BOOL)containsCharactersFromSet:(NSCharacterSet *)set;
- (BOOL)isComposedOfCharactersFromSet:(NSCharacterSet *)characterSet;

- (NSArray *)componentsSeparatedByCharactersFromSet:(NSCharacterSet *)characterSet;

- (NSString *)stringByReplacingOccurencesOfString:(NSString *)target withString:(NSString *)replacement;
- (NSString *)stringByReplacingOccurencesOfStrings:(NSArray *)targets withString:(NSString *)replacement;

- (NSString *)stringByAddingPercentEscapesUsingEncoding:(NSStringEncoding)encoding charactersToLeaveUnescaped:(NSString *)charactersToLeaveUnescaped;
- (NSString *)stringByAddingPercentEscapesUsingEncoding:(NSStringEncoding)encoding legalURLCharactersToBeEscaped:(NSString *)legalURLCharactersToBeEscaped;

- (NSString *)stringByReplacingPathExtensionWithExtension:(NSString *)extension;

- (NSString *)stringByApplyingFilter:(WITextFilter *)filter;

- (NSComparisonResult)caseInsensitiveAndNumericCompare:(NSString *)string;
- (NSComparisonResult)finderCompare:(NSString *)string;

@end


@interface NSString(WIStringChecksumming)

- (NSString *)SHA1;

@end


@interface NSString(WIHumanReadableStringFormatting)

+ (NSString *)humanReadableStringForTimeInterval:(NSTimeInterval)interval;
+ (NSString *)humanReadableStringForSizeInBytes:(unsigned long long)size;
+ (NSString *)humanReadableStringForSizeInBytes:(unsigned long long)size withBytes:(BOOL)bytes;
+ (NSString *)humanReadableStringForSizeInBits:(unsigned long long)size;
+ (NSString *)humanReadableStringForBandwidth:(NSUInteger)speed;

@end


@interface NSString(WIWiredVersionStringFormatting)

- (NSString *)wiredVersion;

@end


@interface NSMutableString(WIFoundation)

- (void)deleteCharactersToIndex:(NSUInteger)index;
- (void)deleteCharactersFromIndex:(NSUInteger)index;

//- (void)replaceOccurrencesOfCharactersSet:(NSCharacterSet *)set withString:(NSString *)target;
- (NSUInteger)replaceOccurrencesOfString:(NSString *)target withString:(NSString *)replacement;
- (NSUInteger)replaceOccurrencesOfString:(NSString *)target withString:(NSString *)replacement options:(NSUInteger)options;

- (void)trimCharactersInSet:(NSCharacterSet *)characterSet;

- (void)applyFilter:(WITextFilter *)filter;

@end
