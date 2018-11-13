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

#import <WiredNetworking/WIP7Message.h>

enum _WIP7Originator {
	WIP7Both						= WI_P7_BOTH,
	WIP7Client						= WI_P7_CLIENT,
	WIP7Server						= WI_P7_SERVER
};
typedef enum _WIP7Originator		WIP7Originator;


@class WIP7SpecMessage, WIP7Message, WIError;

@interface WIP7Spec : WIObject	{
	wi_p7_spec_t					*_spec;
	
	CFMutableDictionaryRef			_fieldNames;
	CFMutableDictionaryRef			_fieldIDs;
	
	NSMutableArray					*_fields;
	NSMutableArray					*_messages;
	NSMutableDictionary				*_parameters;
}

- (id)initWithPath:(NSString *)path originator:(WIP7Originator)originator error:(WIError **)error;
- (id)initWithString:(NSString *)string originator:(WIP7Originator)originator error:(WIError **)error;

- (wi_p7_spec_t *)spec;
- (NSString *)protocolName;
- (NSString *)protocolVersion;

- (wi_string_t *)fieldNameForName:(NSString *)name;
- (NSUInteger)fieldIDForName:(NSString *)name;

- (NSArray *)fields;
- (NSArray *)messages;
- (WIP7SpecMessage *)messageWithName:(NSString *)name;

- (BOOL)verifyMessage:(WIP7Message *)message error:(WIError **)error;

@end


@interface WIP7SpecType : WIObject {
	wi_p7_spec_type_t					*_type;
	NSString							*_name;
	WIP7Type							_id;
}

- (NSComparisonResult)compare:(WIP7SpecType *)type;

- (wi_p7_spec_type_t *)type;
- (NSString *)name;
- (WIP7Type)ID;

@end


@interface WIP7SpecField : WIObject {
	wi_p7_spec_field_t					*_field;
	NSString							*_name;
	NSUInteger							_id;
	WIP7SpecType						*_type;
	NSMutableDictionary					*_enumsByName;
	NSMutableDictionary					*_enumsByValue;
}

- (NSComparisonResult)compare:(WIP7SpecField *)field;

- (wi_p7_spec_field_t *)field;
- (NSString *)name;
- (NSUInteger)ID;
- (WIP7SpecType *)type;
- (NSDictionary *)enumsByName;
- (NSDictionary *)enumsByValue;

@end


@interface WIP7SpecMessage : WIObject {
	wi_p7_spec_message_t				*_message;
	NSString							*_name;
	NSUInteger							_id;
	NSMutableArray						*_parameters;
}

- (NSComparisonResult)compare:(WIP7SpecMessage *)message;

- (wi_p7_spec_message_t *)message;
- (NSString *)name;
- (NSUInteger)ID;
- (NSArray *)parameters;

@end


@interface WIP7SpecParameter : WIObject {
	wi_p7_spec_parameter_t				*_parameter;
	WIP7SpecField						*_field;
	BOOL								_required;
}

- (NSComparisonResult)compare:(WIP7SpecParameter *)parameter;

- (wi_p7_spec_parameter_t *)parameter;
- (WIP7SpecField *)field;
- (BOOL)isRequired;

@end
