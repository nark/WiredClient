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

#import <WiredNetworking/NSString-WINetworking.h>
#import <WiredNetworking/WIError.h>
#import <WiredNetworking/WIP7Message.h>
#import <WiredNetworking/WIP7Spec.h>

@interface WIP7Spec(Private)

- (void)_setSpec:(wi_p7_spec_t *)spec;

@end


@interface WIP7SpecType(Private)

- (id)_initWithType:(wi_p7_spec_type_t *)type;

@end


@interface WIP7SpecField(Private)

- (id)_initWithField:(wi_p7_spec_field_t *)field;

@end


@interface WIP7SpecMessage(Private)

- (id)_initWithMessage:(wi_p7_spec_message_t *)message;

@end


@interface WIP7SpecParameter(Private)

- (id)_initWithParameter:(wi_p7_spec_parameter_t *)parameter;

@end



@implementation WIP7Spec(Private)

- (void)_setSpec:(wi_p7_spec_t *)spec {
	NSString			*name;
	wi_enumerator_t		*enumerator;
	wi_array_t			*array;
	wi_p7_spec_field_t	*field;
	
	_spec			= wi_retain(spec);
	
	array			= wi_p7_spec_fields(_spec);
	enumerator		= wi_array_data_enumerator(array);
	
	_fieldNames		= CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, NULL);
	_fieldIDs		= CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, NULL);
	
	while((field = wi_enumerator_next_data(enumerator))) {
		name = [NSString stringWithWiredString:wi_p7_spec_field_name(field)];
		
		CFDictionarySetValue(_fieldNames, name, wi_p7_spec_field_name(field));
		CFDictionarySetValue(_fieldIDs, name, (void *) wi_p7_spec_field_id(field));
	}
}

@end



@implementation WIP7Spec

- (id)initWithPath:(NSString *)path originator:(WIP7Originator)originator error:(WIError **)error {
	wi_p7_spec_t		*spec;
	wi_pool_t			*pool;
	wi_string_t			*string;
	
	self = [super init];
	
	pool	= wi_pool_init(wi_pool_alloc());
	string	= wi_string_with_cstring([path fileSystemRepresentation]);
	spec	= wi_p7_spec_init_with_file(wi_p7_spec_alloc(), string, originator);
	
	if(!spec) {
		if(error) {
			*error = [WIError errorWithDomain:WIWiredNetworkingErrorDomain
										 code:WIP7SpecLoadFailed
									 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
										 [WIError errorWithDomain:WILibWiredErrorDomain],
											 WILibWiredErrorKey,
										 path,
											 WIArgumentErrorKey,
										 NULL]];
		}
		
		wi_release(pool);

		[self release];
		
		return NULL;
	}
	
	[self _setSpec:spec];
	
	wi_release(spec);
	wi_release(pool);

	return self;
}



- (id)initWithString:(NSString *)string originator:(WIP7Originator)originator error:(WIError **)error {
	wi_p7_spec_t		*spec;
	wi_pool_t			*pool;
	
	self = [super init];
	
	pool = wi_pool_init(wi_pool_alloc());
	spec = wi_p7_spec_init_with_string(wi_p7_spec_alloc(), [string wiredString], (enum _wi_p7_originator)originator);
	
	if(!spec) {
		if(error) {
			*error = [WIError errorWithDomain:WIWiredNetworkingErrorDomain
										 code:WIP7SpecLoadFailed
									 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
										 [WIError errorWithDomain:WILibWiredErrorDomain],
											 WILibWiredErrorKey,
										 NULL]];
		}
		
		wi_release(pool);

		[self release];
		
		return NULL;
	}
	
	[self _setSpec:spec];
	
	wi_release(spec);
	wi_release(pool);

	return self;
}



- (void)dealloc {
	wi_release(_spec);
	
	if(_fieldNames)
		CFRelease(_fieldNames);
	
	if(_fieldIDs)
		CFRelease(_fieldIDs);
	
	[_fields release];
	[_messages release];
	[_parameters release];
	
	[super dealloc];
}



#pragma mark -

- (wi_p7_spec_t *)spec {
	return _spec;
}



- (NSString *)protocolName {
	return [NSString stringWithWiredString:wi_p7_spec_name(_spec)];
}



- (NSString *)protocolVersion {
	return [NSString stringWithWiredString:wi_p7_spec_version(_spec)];
}



#pragma mark -

- (wi_string_t *)fieldNameForName:(NSString *)name {
	return (wi_string_t *) CFDictionaryGetValue(_fieldNames, name);
}



- (NSUInteger)fieldIDForName:(NSString *)name {
	return (NSUInteger) CFDictionaryGetValue(_fieldIDs, name);
}



#pragma mark -

- (NSArray *)fields {
	wi_pool_t				*pool;
	wi_enumerator_t			*enumerator;
	wi_p7_spec_field_t		*field;
	wi_array_t				*array;
	
	if(!_fields) {
		pool = wi_pool_init(wi_pool_alloc());
		
		array = wi_p7_spec_fields(_spec);
		enumerator = wi_array_data_enumerator(array);
		
		_fields = [[NSMutableArray alloc] initWithCapacity:wi_array_count(array)];
		
		while((field = wi_enumerator_next_data(enumerator)))
			[_fields addObject:[[[WIP7SpecField alloc] _initWithField:field] autorelease]];
		
		[_fields sortUsingSelector:@selector(compare:)];
		
		wi_release(pool);
	}
	
	return _fields;
}



- (NSArray *)messages {
	wi_pool_t				*pool;
	wi_enumerator_t			*enumerator;
	wi_p7_spec_message_t	*message;
	wi_array_t				*array;
	
	if(!_messages) {
		pool = wi_pool_init(wi_pool_alloc());
		
		array = wi_p7_spec_messages(_spec);
		enumerator = wi_array_data_enumerator(array);
		
		_messages = [[NSMutableArray alloc] initWithCapacity:wi_array_count(array)];
		
		while((message = wi_enumerator_next_data(enumerator)))
			[_messages addObject:[[[WIP7SpecMessage alloc] _initWithMessage:message] autorelease]];
		
		[_messages sortUsingSelector:@selector(compare:)];
		
		wi_release(pool);
	}
	
	return _messages;
}



- (WIP7SpecMessage *)messageWithName:(NSString *)name {
	NSEnumerator		*enumerator;
	WIP7SpecMessage		*message;
	
	enumerator = [[self messages] objectEnumerator];
	
	while((message = [enumerator nextObject])) {
		if([name isEqualToString:[message name]])
			return message;
	}
	
	return NULL;
}



#pragma mark -

- (BOOL)verifyMessage:(WIP7Message *)message error:(WIError **)error {
	wi_pool_t		*pool;
	wi_boolean_t	result;
	
	pool = wi_pool_init(wi_pool_alloc());
	result = wi_p7_spec_verify_message(_spec, [message message]);
	wi_release(pool);
	
	if(!result) {
		if(error)
			*error = [WIError errorWithDomain:WILibWiredErrorDomain];
		
		return NO;
	}
	
	return YES;
}

@end



@implementation WIP7SpecType(Private)

- (id)_initWithType:(wi_p7_spec_type_t *)type {
	self = [super init];
	
	_type		= wi_retain(type);
	_name		= [[NSString alloc] initWithWiredString:wi_p7_spec_type_name(_type)];
	_id			= (WIP7Type) wi_p7_spec_type_id(_type);
	
	return self;
}

@end



@implementation WIP7SpecType

- (void)dealloc {
	[_name release];
	
	wi_release(_type);
	
	[super dealloc];
}



#pragma mark -

- (NSComparisonResult)compare:(WIP7SpecType *)type {
	if([self ID] < [type ID])
		return NSOrderedAscending;
    else if([self ID] > [type ID])
        return NSOrderedDescending;
	
    return NSOrderedSame;
}



#pragma mark -

- (wi_p7_spec_type_t *)type {
	return _type;
}



- (NSString *)name {
	return _name;
}



- (WIP7Type)ID {
	return _id;
}

@end



@implementation WIP7SpecField(Private)

- (id)_initWithField:(wi_p7_spec_field_t *)field {
	NSString			*name;
	NSNumber			*value;
	wi_enumerator_t		*enumerator;
	wi_dictionary_t		*dictionary;
	void				*key;

	self = [self init];
	
	_field			= wi_retain(field);
	_name			= [[NSString alloc] initWithWiredString:wi_p7_spec_field_name(_field)];
	_id				= wi_p7_spec_field_id(_field);
	_type			= [[WIP7SpecType alloc] _initWithType:wi_p7_spec_field_type(_field)];
	
	if([_type ID] == WIP7EnumType) {
		_enumsByName	= [[NSMutableDictionary alloc] init];
		_enumsByValue	= [[NSMutableDictionary alloc] init];
		dictionary		= wi_p7_spec_field_enums_by_name(_field);
		enumerator		= wi_dictionary_key_enumerator(dictionary);
		
		while((key = wi_enumerator_next_data(enumerator))) {
			name		= [NSString stringWithWiredString:key];
			value		= [NSNumber numberWithUnsignedInteger:(wi_uinteger_t) wi_dictionary_data_for_key(dictionary, key)];
			
			[_enumsByName setObject:value forKey:name];
			[_enumsByValue setObject:name forKey:value];
		}
	}
	
	return self;
}

@end



@implementation WIP7SpecField

- (void)dealloc {
	[_name release];
	[_type release];
	[_enumsByName release];
	[_enumsByValue release];
	
	wi_release(_field);
	
	[super dealloc];
}



#pragma mark -

- (NSComparisonResult)compare:(WIP7SpecField *)field {
	if([self ID] < [field ID])
		return NSOrderedAscending;
    else if([self ID] > [field ID])
        return NSOrderedDescending;
	
    return NSOrderedSame;
}



#pragma mark -

- (wi_p7_spec_field_t *)field {
	return _field;
}



- (NSString *)name {
	return _name;
}



- (NSUInteger)ID {
	return _id;
}



- (WIP7SpecType *)type {
	return _type;
}



- (NSDictionary *)enumsByName {
	return _enumsByName;
}



- (NSDictionary *)enumsByValue {
	return _enumsByValue;
}

@end



@implementation WIP7SpecMessage(Private)

- (id)_initWithMessage:(wi_p7_spec_message_t *)message {
	wi_enumerator_t			*enumerator;
	wi_p7_spec_parameter_t	*parameter;
	
	self = [self init];
	
	_message	= wi_retain(message);
	_name		= [[NSString alloc] initWithWiredString:wi_p7_spec_message_name(_message)];
	_id			= wi_p7_spec_message_id(_message);
	_parameters	= [[NSMutableArray alloc] init];
	
	enumerator = wi_array_data_enumerator(wi_p7_spec_message_parameters(_message));
	
	while((parameter = wi_enumerator_next_data(enumerator)))
		[_parameters addObject:[[[WIP7SpecParameter alloc] _initWithParameter:parameter] autorelease]];
	
	[_parameters sortUsingSelector:@selector(compare:)];

	return self;
}

@end



@implementation WIP7SpecMessage

- (void)dealloc {
	[_name release];
	[_parameters release];
	
	wi_release(_message);
	
	[super dealloc];
}



#pragma mark -

- (NSComparisonResult)compare:(WIP7SpecMessage *)message {
	if([self ID] < [message ID])
		return NSOrderedAscending;
    else if([self ID] > [message ID])
        return NSOrderedDescending;
	
    return NSOrderedSame;
}



#pragma mark -

- (wi_p7_spec_message_t *)message {
	return _message;
}



- (NSString *)name {
	return _name;
}



- (NSUInteger)ID {
	return _id;
}



- (NSArray *)parameters {
	return _parameters;
}

@end



@implementation WIP7SpecParameter(Private)

- (id)_initWithParameter:(wi_p7_spec_parameter_t *)parameter {
	self = [self init];
	
	_parameter	= wi_retain(parameter);
	_field		= [[WIP7SpecField alloc] _initWithField:wi_p7_spec_parameter_field(parameter)];	
	_required	= wi_p7_spec_parameter_required(parameter);
	
	return self;
}

@end



@implementation WIP7SpecParameter

- (void)dealloc {
	[_field release];
	
	wi_release(_parameter);
	
	[super dealloc];
}



#pragma mark -

- (NSComparisonResult)compare:(WIP7SpecParameter *)parameter {
	if([self isRequired] && ![parameter isRequired])
		return NSOrderedAscending;
	else if(![self isRequired] && [parameter isRequired])
        return NSOrderedDescending;
	
	return [[[self field] name] caseInsensitiveCompare:[[parameter field] name]];
}



#pragma mark -

- (wi_p7_spec_parameter_t *)parameter {
	return _parameter;
}



- (WIP7SpecField *)field {
	return _field;
}



- (BOOL)isRequired {
	return _required;
}

@end
