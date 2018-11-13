/* $Id$ */

/*
 *  Copyright (c) 2008-2009 Axel Andersson
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

#import <WiredNetworking/NSNumber-WINetworking.h>
#import <WiredNetworking/NSString-WINetworking.h>
#import <WiredNetworking/WIP7Message.h>
#import <WiredNetworking/WIP7Spec.h>
#import <WiredNetworking/WIP7Socket.h>

@implementation WIP7Message

+ (void)initialize {
	wi_p7_message_debug = true;
}



#pragma mark -

+ (id)messageWithName:(NSString *)name spec:(WIP7Spec *)spec {
	return [[[self alloc] initWithName:name spec:spec] autorelease];
}



+ (id)messageWithMessage:(wi_p7_message_t *)message spec:(WIP7Spec *)spec {
	return [[[self alloc] initWithMessage:message spec:spec] autorelease];
}



#pragma mark -

- (id)initWithName:(NSString *)name spec:(WIP7Spec *)spec {
	wi_string_t		*string;
	
	self = [super init];
	
	string = wi_string_init_with_cstring(wi_string_alloc(), [name UTF8String]);
	_message = wi_p7_message_init_with_name(wi_p7_message_alloc(), string, [spec spec]);
	wi_release(string);
	
	_name = [name retain];
	_spec = [spec retain];
	
	return self;
}



- (id)initWithMessage:(wi_p7_message_t *)message spec:(WIP7Spec *)spec {
	self = [super init];
	
	_message = wi_retain(message);
	_name = [[NSString alloc] initWithWiredString:wi_p7_message_name(message)];
	_spec = [spec retain];
	
	return self;
}



- (void)dealloc {
	wi_release(_message);
	
	[_name release];
	[_spec release];
	
	[super dealloc];
}



- (NSString *)description {
	NSMutableString		*description;
	NSEnumerator		*enumerator;
	NSDictionary		*fields;
	NSString			*name, *value;
	
	fields			= [self fields];
	description		= [NSMutableString stringWithFormat:@"%@ = {%@", [self name], ([fields count] > 0) ? @"\n" : @" "];
	enumerator		= [[[fields allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] objectEnumerator];
	
	while((name = [enumerator nextObject])) {
		value = [fields objectForKey:name];
		
		[description appendFormat:@"\t%@ = %@\n", name, value];
	}
	
	[description appendString:@"}"];
	
	return description;
}



#pragma mark -

- (NSString *)name {
	return _name;
}



- (wi_p7_message_t *)message {
	return _message;
}



#pragma mark -

- (NSDictionary *)fields {
	NSMutableDictionary		*dictionary;
	wi_pool_t				*pool;
	wi_enumerator_t			*enumerator;
	wi_dictionary_t			*fields;
	wi_string_t				*name, *value;
	
	pool			= wi_pool_init(wi_pool_alloc());
	dictionary		= [NSMutableDictionary dictionary];
	fields			= wi_p7_message_fields(_message);
	enumerator		= wi_dictionary_key_enumerator(fields);
	
	while((name = wi_enumerator_next_data(enumerator))) {
		value = wi_dictionary_data_for_key(fields, name);
		
		[dictionary setObject:[NSString stringWithWiredString:value] forKey:[NSString stringWithWiredString:name]];
	}
	
	wi_release(pool);
	
	return dictionary;
}



#pragma mark -

- (void)setContextInfo:(void *)contextInfo {
	_contextInfo = contextInfo;
}



- (void *)contextInfo {
	return _contextInfo;
}



#pragma mark -

- (BOOL)getBool:(WIP7Bool *)value forName:(NSString *)name {
	return wi_p7_message_get_bool_for_name(_message, value, [_spec fieldNameForName:name]);
}



- (BOOL)setBool:(WIP7Bool)value forName:(NSString *)name {
	return wi_p7_message_set_bool_for_name(_message, value, [_spec fieldNameForName:name]);
}



- (BOOL)getEnum:(WIP7Enum *)value forName:(NSString *)name {
	return wi_p7_message_get_enum_for_name(_message, value, [_spec fieldNameForName:name]);
}



- (BOOL)setEnum:(WIP7Enum)value forName:(NSString *)name {
	return wi_p7_message_set_enum_for_name(_message, value, [_spec fieldNameForName:name]);
}



- (BOOL)getInt32:(WIP7Int32 *)value forName:(NSString *)name {
	return wi_p7_message_get_int32_for_name(_message, value, [_spec fieldNameForName:name]);
}



- (BOOL)setInt32:(WIP7Int32)value forName:(NSString *)name {
	return wi_p7_message_set_int32_for_name(_message, value, [_spec fieldNameForName:name]);
}



- (BOOL)getUInt32:(WIP7UInt32 *)value forName:(NSString *)name {
	return wi_p7_message_get_uint32_for_name(_message, value, [_spec fieldNameForName:name]);
}



- (BOOL)setUInt32:(WIP7UInt32)value forName:(NSString *)name {
	return wi_p7_message_set_uint32_for_name(_message, value, [_spec fieldNameForName:name]);
}



- (BOOL)getInt64:(WIP7Int64 *)value forName:(NSString *)name {
	return wi_p7_message_get_int64_for_name(_message, value, [_spec fieldNameForName:name]);
}



- (BOOL)setInt64:(WIP7Int64)value forName:(NSString *)name {
	return wi_p7_message_set_int64_for_name(_message, value, [_spec fieldNameForName:name]);
}



- (BOOL)getUInt64:(WIP7UInt64 *)value forName:(NSString *)name {
	return wi_p7_message_get_uint64_for_name(_message, value, [_spec fieldNameForName:name]);
}



- (BOOL)setUInt64:(WIP7UInt64)value forName:(NSString *)name {
	return wi_p7_message_set_uint64_for_name(_message, value, [_spec fieldNameForName:name]);
}



- (BOOL)getDouble:(WIP7Double *)value forName:(NSString *)name {
	return wi_p7_message_get_double_for_name(_message, value, [_spec fieldNameForName:name]);
}



- (BOOL)setDouble:(WIP7Double)value forName:(NSString *)name {
	return wi_p7_message_set_double_for_name(_message, value, [_spec fieldNameForName:name]);
}



- (BOOL)getOOBData:(WIP7OOBData *)value forName:(NSString *)name {
	return wi_p7_message_get_oobdata_for_name(_message, value, [_spec fieldNameForName:name]);
}



- (BOOL)setOOBData:(WIP7OOBData)value forName:(NSString *)name {
	return wi_p7_message_set_oobdata_for_name(_message, value, [_spec fieldNameForName:name]);
}



#pragma mark -

- (BOOL)setString:(NSString *)string forName:(NSString *)name {
	const char		*buffer;
	NSUInteger		length;
	
	buffer = [string UTF8String];
	length = strlen(buffer);
	
	return wi_p7_message_write_binary(_message, buffer, (WIP7UInt32)(length + 1), [_spec fieldIDForName:name]);
}



- (NSString *)stringForName:(NSString *)name {
	unsigned char		*binary;
	uint32_t			length;
	
	if(!wi_p7_message_read_binary(_message, &binary, &length, [_spec fieldIDForName:name]))
		return NULL;
	
	return [NSString stringWithUTF8String:(char *) binary];
}



- (BOOL)setData:(NSData *)data forName:(NSString *)name {
	return wi_p7_message_write_binary(_message, [data bytes], (WIP7UInt32)[data length], [_spec fieldIDForName:name]);
}



- (NSData *)dataForName:(NSString *)name {
	unsigned char		*binary;
	uint32_t			length;
	
	if(!wi_p7_message_read_binary(_message, &binary, &length, [_spec fieldIDForName:name]))
		return NULL;
	
	return [NSData dataWithBytes:binary length:length];
}



- (BOOL)setNumber:(NSNumber *)number forName:(NSString *)name {
	wi_pool_t			*pool;
	BOOL				result = NO;
	
	pool = wi_pool_init(wi_pool_alloc());
	
	result = wi_p7_message_set_number_for_name(_message, [number wiredNumber], [name wiredString]);
	
	wi_release(pool);
	
	return result;
}



- (NSNumber *)numberForName:(NSString *)name {
	NSNumber			*number;
	wi_pool_t			*pool;
	
	pool = wi_pool_init(wi_pool_alloc());
	
	number = [NSNumber numberWithWiredNumber:wi_p7_message_number_for_name(_message, [_spec fieldNameForName:name])];
	
	wi_release(pool);
	
	return number;
}



- (BOOL)setEnumName:(NSString *)enumName forName:(NSString *)name {
	return wi_p7_message_set_enum_name_for_name(_message, [enumName wiredString], [_spec fieldNameForName:name]);
}



- (NSString *)enumNameForName:(NSString *)name {
	NSString		*enumName;
	wi_pool_t		*pool;
	wi_string_t		*string;
	
	pool = wi_pool_init(wi_pool_alloc());
	
	string = wi_p7_message_enum_name_for_name(_message, [_spec fieldNameForName:name]);
	
	if(string)
		enumName = [NSString stringWithWiredString:string];
	else
		enumName = NULL;
	
	wi_release(pool);
	
	return enumName;
}



- (BOOL)setDate:(NSDate *)date forName:(NSString *)name {
	return [self setDouble:[date timeIntervalSince1970] forName:name];
;
}



- (NSDate *)dateForName:(NSString *)name {
	NSTimeInterval		interval;
	
	if(![self getDouble:&interval forName:name])
		return NULL;
	    
	return [NSDate dateWithTimeIntervalSince1970:interval];
}



- (BOOL)setUUID:(NSString *)string forName:(NSString *)name {
	wi_pool_t			*pool;
	wi_uuid_t			*uuid;
	BOOL				result = NO;
	
	pool = wi_pool_init(wi_pool_alloc());
	
	uuid = wi_uuid_with_string([string wiredString]);
	
	if(uuid)
		result = wi_p7_message_set_uuid_for_name(_message, uuid, [name wiredString]);
	else
		result = NO;
	
	wi_release(pool);
	
	return result;
}



- (NSString *)UUIDForName:(NSString *)name {
	NSString			*string;
	wi_pool_t			*pool;
	wi_uuid_t			*uuid;
	
	pool = wi_pool_init(wi_pool_alloc());
	
	uuid = wi_p7_message_uuid_for_name(_message, [name wiredString]);
	string = uuid ? [NSString stringWithWiredString:wi_uuid_string(uuid)] : NULL;
	
	wi_release(pool);
	
	return string;
}



- (BOOL)setList:(NSArray *)list forName:(NSString *)name {
	NSEnumerator			*enumerator;
	wi_pool_t				*pool;
	wi_mutable_array_t		*array;
	wi_runtime_instance_t	*instance;
	id						object;
	BOOL					result;
	
	pool = wi_pool_init(wi_pool_alloc());
	array = wi_array_init(wi_mutable_array_alloc());
	
	enumerator = [list objectEnumerator];
	
	while((object = [enumerator nextObject])) {
		
		if([object isKindOfClass:[NSString class]])
			instance = [object wiredString];
		else
			instance = NULL;
		
		if(instance)
			wi_mutable_array_add_data(array, instance);
	}
	
	result = wi_p7_message_set_list_for_name(_message, array, [_spec fieldNameForName:name]);

	wi_release(array);
	wi_release(pool);
	
	return result;
}



- (NSArray *)listForName:(NSString *)name {
	NSMutableArray			*list;
	wi_pool_t				*pool;
	wi_array_t				*array;
	wi_runtime_instance_t	*instance;
	id						object;
	wi_uinteger_t			i, count;
	
	pool = wi_pool_init(wi_pool_alloc());
	array = wi_p7_message_list_for_name(_message, [_spec fieldNameForName:name]);
	
	if(array) {
		list = [NSMutableArray array];
		count = wi_array_count(array);
		
		for(i = 0; i < count; i++) {
			instance = WI_ARRAY(array, i);
			
			if(wi_runtime_id(instance) == wi_string_runtime_id())
				object = [NSString stringWithWiredString:instance];
			else
				object = NULL;
			
			if(object)
				[list addObject:object];
		}
	} else {
		list = NULL;
	}
	
	wi_release(pool);

	return list;
}

@end
