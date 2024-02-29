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

@interface WISettings : WIObject {
	NSString						*_identifier;
	id								_defaults;
	NSDictionary					*_defaultValues;
}

+ (id)settings;
+ (id)settingsWithIdentifier:(NSString *)identifier;

- (NSDictionary *)defaults;

- (BOOL)synchronize;

- (void)setObject:(id)object forKey:(id)key;
- (id)objectForKey:(id)key;
- (void)removeObjectForKey:(id)key;
- (void)setString:(NSString *)string forKey:(id)key;
- (NSString *)stringForKey:(id)key;
- (void)setBool:(BOOL)value forKey:(id)key;
- (BOOL)boolForKey:(id)key;
- (void)setInt:(int)value forKey:(id)key;
- (int)intForKey:(id)key;
- (void)setInteger:(NSInteger)value forKey:(id)key;
- (NSInteger)integerForKey:(id)key;
- (void)setFloat:(float)value forKey:(id)key;
- (float)floatForKey:(id)key;
- (void)setDouble:(double)value forKey:(id)key;
- (double)doubleForKey:(id)key;

- (void)addObject:(id)object toArrayForKey:(id)arrayKey;
- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)object inArrayForKey:(id)arrayKey;
- (void)removeObjectAtIndex:(NSUInteger)index fromArrayForKey:(id)arrayKey;
- (void)removeObject:(id)object fromArrayForKey:(id)arrayKey;

- (void)setObject:(id)object forKey:(id)key inDictionaryForKey:(id)dictionaryKey;
- (void)removeObjectForKey:(id)key inDictionaryForKey:(id)dictionaryKey;

- (NSInteger)indexOfObject:(id)object inArrayForKey:(id)arrayKey;

@end
