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

#import <WiredFoundation/NSObject-WIFoundation.h>
#import <WiredFoundation/NSNumber-WIFoundation.h>
#import <WiredFoundation/WISettings.h>

@interface WISettings(Private)

- (id)_initWithIdentifier:(NSString *)identifier;

@end


@implementation WISettings(Private)

- (id)_initWithIdentifier:(NSString *)identifier {
	self = [super init];

	if([identifier length] > 0) {
		_identifier		= [identifier retain];
		_defaults		= [[[NSUserDefaults standardUserDefaults] persistentDomainForName:_identifier] mutableCopy];

		if(!_defaults)
			_defaults	= [[NSMutableDictionary alloc] init];
	} else {
		_defaults		= [[NSUserDefaults standardUserDefaults] retain];
	}
	
	_defaultValues		= [[self defaults] retain];

	return self;
}

@end



@implementation WISettings

+ (id)settings {
	return [self settingsWithIdentifier:@""];
}



+ (id)settingsWithIdentifier:(NSString *)identifier {
	static NSMutableDictionary		*dictionary;
	id								settings;
	
	if(!dictionary)
		dictionary = [[NSMutableDictionary alloc] init];
	
	settings = [dictionary objectForKey:identifier];
	
	if(!settings) {
		settings = [[[self alloc] _initWithIdentifier:identifier] autorelease];
		
		[dictionary setObject:settings forKey:identifier];
	}
	
	return settings;
}



#pragma mark -

- (NSDictionary *)defaults {
	return [NSDictionary dictionary];
}



#pragma mark -

- (BOOL)synchronize {
	NSUserDefaults		*defaults;
	
	defaults = [NSUserDefaults standardUserDefaults];
	
	if(_identifier) {
		[defaults removePersistentDomainForName:_identifier];
		[defaults setPersistentDomain:_defaults forName:_identifier];
	}
	
	return [defaults synchronize];
}



#pragma mark -

- (void)dealloc {
	[_identifier release];
	[_defaultValues release];
	[_defaults release];
	
	[super dealloc];
}



#pragma mark -

- (void)setObject:(id)object forKey:(id)key {
	[_defaults setObject:object forKey:key];

	[self performSelectorOnce:@selector(synchronize) withObject:NULL afterDelay:1.0];
}



- (id)objectForKey:(id)key {
	id		object;
	
	object = [_defaults objectForKey:key];

	if(object)
		return object;
	
	return [_defaultValues objectForKey:key];
}



- (void)removeObjectForKey:(id)key {
	[_defaults removeObjectForKey:key];
}



- (void)setString:(NSString *)object forKey:(id)key {
	[self setObject:object forKey:key];
}



- (NSString *)stringForKey:(id)key {
	return [self objectForKey:key];
}



- (void)setBool:(BOOL)value forKey:(id)key {
	[self setObject:[NSNumber numberWithBool:value] forKey:key];
}



- (BOOL)boolForKey:(id)key {
	return [[self objectForKey:key] boolValue];
}



- (void)setInt:(int)value forKey:(id)key {
	[self setObject:[NSNumber numberWithInt:value] forKey:key];
}



- (int)intForKey:(id)key {
	return [[self objectForKey:key] intValue];
}



- (void)setInteger:(NSInteger)value forKey:(id)key {
	[self setObject:[NSNumber numberWithInteger:value] forKey:key];
}



- (NSInteger)integerForKey:(id)key {
	return [[self objectForKey:key] integerValue];
}



- (void)setFloat:(float)value forKey:(id)key {
	[self setObject:[NSNumber numberWithFloat:value] forKey:key];
}



- (float)floatForKey:(id)key {
	return [[self objectForKey:key] floatValue];
}



- (void)setDouble:(double)value forKey:(id)key {
	[self setObject:[NSNumber numberWithDouble:value] forKey:key];
}



- (double)doubleForKey:(id)key {
	return [[self objectForKey:key] doubleValue];
}



#pragma mark -

- (void)addObject:(id)object toArrayForKey:(id)arrayKey {
	NSMutableArray		*array;
	
	array = [[[self objectForKey:arrayKey] mutableCopy] autorelease];
	[array addObject:object];
	[self setObject:array forKey:arrayKey];
}



- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)object inArrayForKey:(id)arrayKey {
	NSMutableArray		*array;
	
	array = [[[self objectForKey:arrayKey] mutableCopy] autorelease];
	[array replaceObjectAtIndex:index withObject:object];
	[self setObject:array forKey:arrayKey];
}



- (void)removeObjectAtIndex:(NSUInteger)index fromArrayForKey:(id)arrayKey {
	NSMutableArray		*array;
	
	array = [[[self objectForKey:arrayKey] mutableCopy] autorelease];
	[array removeObjectAtIndex:index];
	[self setObject:array forKey:arrayKey];
}


- (void)removeObject:(id)object fromArrayForKey:(id)arrayKey {
	NSMutableArray		*array;
    NSInteger           index;
    
    index = [[self objectForKey:arrayKey] indexOfObject:object];
    array = [[[self objectForKey:arrayKey] mutableCopy] autorelease];
    
	[array removeObjectAtIndex:index];
	[self setObject:array forKey:arrayKey];
}



#pragma mark -

- (void)setObject:(id)object forKey:(id)key inDictionaryForKey:(id)dictionaryKey {
	NSMutableDictionary		*dictionary;
	
	dictionary = [[[self objectForKey:dictionaryKey] mutableCopy] autorelease];
    
    if(!dictionary)
        dictionary = [NSMutableDictionary dictionary];
    
	[dictionary setObject:object forKey:key];
	[self setObject:dictionary forKey:dictionaryKey];
}



- (void)removeObjectForKey:(id)key inDictionaryForKey:(id)dictionaryKey {
	NSMutableDictionary		*dictionary;
	
	dictionary = [[[self objectForKey:dictionaryKey] mutableCopy] autorelease];
	[dictionary removeObjectForKey:key];
	[self setObject:dictionary forKey:dictionaryKey];
}


- (NSInteger)indexOfObject:(id)object inArrayForKey:(id)arrayKey {
    NSMutableArray		*array;
	
	array = [[[self objectForKey:arrayKey] mutableCopy] autorelease];
    return [array indexOfObject:object];
}

@end
