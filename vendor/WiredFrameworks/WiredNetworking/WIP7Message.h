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

typedef wi_p7_boolean_t				WIP7Bool;
typedef wi_p7_enum_t				WIP7Enum;
typedef wi_p7_int32_t				WIP7Int32;
typedef wi_p7_uint32_t				WIP7UInt32;
typedef wi_p7_int64_t				WIP7Int64;
typedef wi_p7_uint64_t				WIP7UInt64;
typedef wi_p7_double_t				WIP7Double;
typedef wi_p7_oobdata_t				WIP7OOBData;


enum _WIP7Type {
	WIP7BoolType					= WI_P7_BOOL,
	WIP7EnumType					= WI_P7_ENUM,
	WIP7Int32Type					= WI_P7_INT32,
	WIP7UInt32Type					= WI_P7_UINT32,
	WIP7Int64Type					= WI_P7_INT64,
	WIP7UInt64Type					= WI_P7_UINT64,
	WIP7DoubleType					= WI_P7_DOUBLE,
	WIP7StringType					= WI_P7_STRING,
	WIP7UUIDType					= WI_P7_UUID,
	WIP7DateType					= WI_P7_DATE,
	WIP7DataType					= WI_P7_DATA,
	WIP7OOBDataType					= WI_P7_OOBDATA,
	WIP7ListType					= WI_P7_LIST
};
typedef enum _WIP7Type				WIP7Type;

enum _WIP7Serialization {
	WIP7Unknown						= WI_P7_UNKNOWN,
	WIP7XML							= WI_P7_XML,
	WIP7Binary						= WI_P7_BINARY
};
typedef enum _WIP7Serialization		WIP7Serialization;


@class WIP7Socket, WIP7Spec;

@interface WIP7Message : WIObject {
	wi_p7_message_t					*_message;
	NSString						*_name;
	WIP7Spec						*_spec;
	void							*_contextInfo;
}

+ (id)messageWithName:(NSString *)name spec:(WIP7Spec *)spec;
+ (id)messageWithMessage:(wi_p7_message_t *)message spec:(WIP7Spec *)spec;

- (id)initWithName:(NSString *)name spec:(WIP7Spec *)spec;
- (id)initWithMessage:(wi_p7_message_t *)message spec:(WIP7Spec *)spec;

- (NSString *)name;
- (wi_p7_message_t *)message;

- (void)setContextInfo:(void *)contextInfo;
- (void *)contextInfo;

- (NSDictionary *)fields;

- (BOOL)getBool:(WIP7Bool *)value forName:(NSString *)name;
- (BOOL)setBool:(WIP7Bool)value forName:(NSString *)name;
- (BOOL)getEnum:(WIP7Enum *)value forName:(NSString *)name;
- (BOOL)setEnum:(WIP7Enum)value forName:(NSString *)name;
- (BOOL)getInt32:(WIP7Int32 *)value forName:(NSString *)name;
- (BOOL)setInt32:(WIP7Int32)value forName:(NSString *)name;
- (BOOL)getUInt32:(WIP7UInt32 *)value forName:(NSString *)name;
- (BOOL)setUInt32:(WIP7UInt32)value forName:(NSString *)name;
- (BOOL)getInt64:(WIP7Int64 *)value forName:(NSString *)name;
- (BOOL)setInt64:(WIP7Int64)value forName:(NSString *)name;
- (BOOL)getUInt64:(WIP7UInt64 *)value forName:(NSString *)name;
- (BOOL)setUInt64:(WIP7UInt64)value forName:(NSString *)name;
- (BOOL)getDouble:(WIP7Double *)value forName:(NSString *)name;
- (BOOL)setDouble:(WIP7Double)value forName:(NSString *)name;
- (BOOL)getOOBData:(WIP7OOBData *)value forName:(NSString *)name;
- (BOOL)setOOBData:(WIP7OOBData)value forName:(NSString *)name;

- (BOOL)setString:(NSString *)string forName:(NSString *)name;
- (NSString *)stringForName:(NSString *)name;
- (BOOL)setData:(NSData *)data forName:(NSString *)name;
- (NSData *)dataForName:(NSString *)name;
- (BOOL)setNumber:(NSNumber *)number forName:(NSString *)name;
- (NSNumber *)numberForName:(NSString *)name;
- (BOOL)setEnumName:(NSString *)enumName forName:(NSString *)name;
- (NSString *)enumNameForName:(NSString *)name;
- (BOOL)setDate:(NSDate *)date forName:(NSString *)name;
- (NSDate *)dateForName:(NSString *)name;
- (BOOL)setUUID:(NSString *)string forName:(NSString *)name;
- (NSString *)UUIDForName:(NSString *)name;
- (BOOL)setList:(NSArray *)list forName:(NSString *)name;
- (NSArray *)listForName:(NSString *)name;

@end
