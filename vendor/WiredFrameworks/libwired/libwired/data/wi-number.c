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

#include "config.h"

#include <sys/time.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>
#include <inttypes.h>
#include <time.h>
#include <ctype.h>

#include <wired/wi-number.h>
#include <wired/wi-pool.h>
#include <wired/wi-private.h>
#include <wired/wi-runtime.h>
#include <wired/wi-string.h>

union _wi_number_value {
	int8_t								i8;
	int16_t								i16;
	int32_t								i32;
	int64_t								i64;
	float								f;
	double								d;
};
typedef union _wi_number_value			_wi_number_value_t;


struct _wi_number {
	wi_runtime_base_t					base;

	wi_number_type_t					type;
	wi_number_storage_type_t			storage_type;
	
	_wi_number_value_t					value;
};


static wi_runtime_instance_t *			_wi_number_copy(wi_runtime_instance_t *);
static wi_boolean_t						_wi_number_is_equal(wi_runtime_instance_t *, wi_runtime_instance_t *);
static wi_hash_code_t					_wi_number_hash(wi_runtime_instance_t *);
static wi_string_t *					_wi_number_description(wi_runtime_instance_t *);

static wi_boolean_t						_wi_number_is_float(wi_number_t *);
static wi_number_storage_type_t			_wi_number_storage_type(wi_number_type_t);


static wi_runtime_id_t					_wi_number_runtime_id = WI_RUNTIME_ID_NULL;
static wi_runtime_class_t				_wi_number_runtime_class = {
	"wi_number_t",
	NULL,
	_wi_number_copy,
	_wi_number_is_equal,
	_wi_number_description,
	_wi_number_hash
};



void wi_number_register(void) {
	_wi_number_runtime_id = wi_runtime_register_class(&_wi_number_runtime_class);
}



void wi_number_initialize(void) {
}



#pragma mark -

wi_runtime_id_t wi_number_runtime_id(void) {
	return _wi_number_runtime_id;
}



#pragma mark -

wi_number_t * wi_number_with_value(wi_number_type_t type, const void *value) {
	return wi_autorelease(wi_number_init_with_value(wi_number_alloc(), type, value));
}



wi_number_t * wi_number_with_bool(wi_boolean_t value) {
	return wi_autorelease(wi_number_init_with_bool(wi_number_alloc(), value));
}



wi_number_t * wi_number_with_char(char value) {
	return wi_autorelease(wi_number_init_with_char(wi_number_alloc(), value));
}



wi_number_t * wi_number_with_short(short value) {
	return wi_autorelease(wi_number_init_with_short(wi_number_alloc(), value));
}



wi_number_t * wi_number_with_int(int value) {
	return wi_autorelease(wi_number_init_with_int(wi_number_alloc(), value));
}



wi_number_t * wi_number_with_int32(int32_t value) {
	return wi_autorelease(wi_number_init_with_int32(wi_number_alloc(), value));
}



wi_number_t * wi_number_with_int64(int64_t value) {
	return wi_autorelease(wi_number_init_with_int64(wi_number_alloc(), value));
}



wi_number_t * wi_number_with_integer(wi_integer_t value) {
	return wi_autorelease(wi_number_init_with_integer(wi_number_alloc(), value));
}



wi_number_t * wi_number_with_long(long value) {
	return wi_autorelease(wi_number_init_with_long(wi_number_alloc(), value));
}



wi_number_t * wi_number_with_long_long(long long value) {
	return wi_autorelease(wi_number_init_with_long_long(wi_number_alloc(), value));
}



wi_number_t * wi_number_with_float(float value) {
	return wi_autorelease(wi_number_init_with_float(wi_number_alloc(), value));
}



wi_number_t * wi_number_with_double(double value) {
	return wi_autorelease(wi_number_init_with_double(wi_number_alloc(), value));
}



#pragma mark -

wi_number_t * wi_number_alloc(void) {
	return wi_runtime_create_instance(_wi_number_runtime_id, sizeof(wi_number_t));
}



wi_number_t * wi_number_init_with_value(wi_number_t *number, wi_number_type_t type, const void *value) {
	number->type			= type;
	number->storage_type	= _wi_number_storage_type(number->type);
	
	switch(number->storage_type) {
		case WI_NUMBER_STORAGE_INT8:		number->value.i8	= *(int8_t *) value;			break;
		case WI_NUMBER_STORAGE_INT16:		number->value.i16	= *(int16_t *) value;			break;
		case WI_NUMBER_STORAGE_INT32:		number->value.i32	= *(int32_t *) value;			break;
		case WI_NUMBER_STORAGE_INT64:		number->value.i64	= *(int64_t *) value;			break;
		case WI_NUMBER_STORAGE_FLOAT:		number->value.f		= *(float *) value;				break;
		case WI_NUMBER_STORAGE_DOUBLE:		number->value.d		= *(double *) value;			break;
	}
	
	return number;
}



wi_number_t * wi_number_init_with_bool(wi_number_t *number, wi_boolean_t value) {
	return wi_number_init_with_value(number, WI_NUMBER_BOOL, &value);
}



wi_number_t * wi_number_init_with_char(wi_number_t *number, char value) {
	return wi_number_init_with_value(number, WI_NUMBER_CHAR, &value);
}



wi_number_t * wi_number_init_with_short(wi_number_t *number, short value) {
	return wi_number_init_with_value(number, WI_NUMBER_SHORT, &value);
}



wi_number_t * wi_number_init_with_int(wi_number_t *number, int value) {
	return wi_number_init_with_value(number, WI_NUMBER_INT, &value);
}



wi_number_t * wi_number_init_with_int32(wi_number_t *number, int32_t value) {
	return wi_number_init_with_value(number, WI_NUMBER_INT32, &value);
}



wi_number_t * wi_number_init_with_int64(wi_number_t *number, int64_t value) {
	return wi_number_init_with_value(number, WI_NUMBER_INT64, &value);
}



wi_number_t * wi_number_init_with_integer(wi_number_t *number, wi_integer_t value) {
#if WI_32
	return wi_number_init_with_value(number, WI_NUMBER_INT32, &value);
#else
	return wi_number_init_with_value(number, WI_NUMBER_INT64, &value);
#endif
}



wi_number_t * wi_number_init_with_long(wi_number_t *number, long value) {
	return wi_number_init_with_value(number, WI_NUMBER_LONG, &value);
}



wi_number_t * wi_number_init_with_long_long(wi_number_t *number, long long value) {
	return wi_number_init_with_value(number, WI_NUMBER_LONG_LONG, &value);
}



wi_number_t * wi_number_init_with_float(wi_number_t *number, float value) {
	return wi_number_init_with_value(number, WI_NUMBER_FLOAT, &value);
}



wi_number_t * wi_number_init_with_double(wi_number_t *number, double value) {
	return wi_number_init_with_value(number, WI_NUMBER_DOUBLE, &value);
}



static wi_runtime_instance_t * _wi_number_copy(wi_runtime_instance_t *instance) {
	return wi_retain(instance);
}



static wi_boolean_t _wi_number_is_equal(wi_runtime_instance_t *instance1, wi_runtime_instance_t *instance2) {
	return (wi_number_compare(instance1, instance2) == 0);
}



static wi_string_t * _wi_number_description(wi_runtime_instance_t *instance) {
	wi_number_t				*number = instance;
	wi_mutable_string_t		*string;
	
	string = wi_mutable_string_with_format(WI_STR("<%@ %p>{value = "),
		wi_runtime_class_name(number),
		number);
	
	if(_wi_number_is_float(number))
		wi_mutable_string_append_format(string, WI_STR("%f"), wi_number_double(number));
	else
		wi_mutable_string_append_format(string, WI_STR("%lld"), wi_number_int64(number));
	
	wi_mutable_string_append_string(string, WI_STR("}"));
	
	wi_runtime_make_immutable(string);
	
	return string;
}



static wi_hash_code_t _wi_number_hash(wi_runtime_instance_t *instance) {
	wi_number_t		*number = instance;
	
	switch(number->storage_type) {
		case WI_NUMBER_STORAGE_INT8:		return wi_hash_int(number->value.i8);		break;
		case WI_NUMBER_STORAGE_INT16:		return wi_hash_int(number->value.i16);		break;
		case WI_NUMBER_STORAGE_INT32:		return wi_hash_int(number->value.i32);		break;
		case WI_NUMBER_STORAGE_INT64:		return wi_hash_double(number->value.i64);	break;
		case WI_NUMBER_STORAGE_FLOAT:		return wi_hash_double(number->value.f);		break;
		case WI_NUMBER_STORAGE_DOUBLE:		return wi_hash_double(number->value.d);		break;
		default:							return 0;									break;
	}
}



#pragma mark -

wi_integer_t wi_number_compare(wi_runtime_instance_t *instance1, wi_runtime_instance_t *instance2) {
	wi_number_t		*number1 = instance1;
	wi_number_t		*number2 = instance2;

	if(_wi_number_is_float(number1) || _wi_number_is_float(number2)) {
		double		d1, d2;
		
		wi_number_get_value(number1, WI_NUMBER_DOUBLE, &d1);
		wi_number_get_value(number2, WI_NUMBER_DOUBLE, &d2);

	    return (d1 > d2) ? 1 : ((d1 < d2) ? -1 : 0);
	} else {
		int64_t		l1, l2;
		
		wi_number_get_value(number1, WI_NUMBER_INT64, &l1);
		wi_number_get_value(number2, WI_NUMBER_INT64, &l2);
		
	    return (l1 > l2) ? 1 : ((l1 < l2) ? -1 : 0);
	}
}



#pragma mark -

static wi_boolean_t _wi_number_is_float(wi_number_t *number) {
	return (number->storage_type == WI_NUMBER_STORAGE_FLOAT ||
			number->storage_type == WI_NUMBER_STORAGE_DOUBLE);
}



static wi_number_storage_type_t _wi_number_storage_type(wi_number_type_t type) {
	switch(type) {
		case WI_NUMBER_BOOL:		return WI_NUMBER_STORAGE_INT32;			break;
		case WI_NUMBER_CHAR:		return WI_NUMBER_STORAGE_INT8;			break;
		case WI_NUMBER_SHORT:		return WI_NUMBER_STORAGE_INT16;			break;
		case WI_NUMBER_INT:			return WI_NUMBER_STORAGE_INT32;			break;
		case WI_NUMBER_INT8:		return WI_NUMBER_STORAGE_INT8;			break;
		case WI_NUMBER_INT16:		return WI_NUMBER_STORAGE_INT16;			break;
		case WI_NUMBER_INT32:		return WI_NUMBER_STORAGE_INT32;			break;
		case WI_NUMBER_INT64:		return WI_NUMBER_STORAGE_INT64;			break;
		case WI_NUMBER_LONG:		return WI_NUMBER_STORAGE_INT64;			break;
		case WI_NUMBER_LONG_LONG:	return WI_NUMBER_STORAGE_INT64;			break;
		case WI_NUMBER_FLOAT:		return WI_NUMBER_STORAGE_FLOAT;			break;
		case WI_NUMBER_DOUBLE:		return WI_NUMBER_STORAGE_DOUBLE;		break;
	}
	
	return WI_NUMBER_STORAGE_INT32;
}



#pragma mark -

wi_number_type_t wi_number_type(wi_number_t *number) {
	return number->type;
}



wi_number_storage_type_t wi_number_storage_type(wi_number_t *number) {
	return number->storage_type;
}



#define WI_NUMBER_GET_VALUE(value, storage_type, outvalue)									\
	switch(storage_type) {																	\
		case WI_NUMBER_STORAGE_INT8:	*(int8_t *) outvalue	= (int8_t) value;	break;	\
		case WI_NUMBER_STORAGE_INT16:	*(int16_t *) outvalue	= (int16_t) value;	break;	\
		case WI_NUMBER_STORAGE_INT32:	*(int32_t *) outvalue	= (int32_t) value;	break;	\
		case WI_NUMBER_STORAGE_INT64:	*(int64_t *) outvalue	= (int64_t) value;	break;	\
		case WI_NUMBER_STORAGE_FLOAT:	*(float *) outvalue		= (float) value;	break;	\
		case WI_NUMBER_STORAGE_DOUBLE:	*(double *) outvalue	= (double) value;	break;	\
	}



void wi_number_get_value(wi_number_t *number, wi_number_type_t type, void *value) {
	wi_number_storage_type_t	storage_type;

	storage_type = _wi_number_storage_type(type);

	switch(number->storage_type) {
		case WI_NUMBER_STORAGE_INT8:		WI_NUMBER_GET_VALUE(number->value.i8, storage_type, value);		break;
		case WI_NUMBER_STORAGE_INT16:		WI_NUMBER_GET_VALUE(number->value.i16, storage_type, value);	break;
		case WI_NUMBER_STORAGE_INT32:		WI_NUMBER_GET_VALUE(number->value.i32, storage_type, value);	break;
		case WI_NUMBER_STORAGE_INT64:		WI_NUMBER_GET_VALUE(number->value.i64, storage_type, value);	break;
		case WI_NUMBER_STORAGE_FLOAT:		WI_NUMBER_GET_VALUE(number->value.f, storage_type, value);		break;
		case WI_NUMBER_STORAGE_DOUBLE:		WI_NUMBER_GET_VALUE(number->value.d, storage_type, value);		break;
	}
}



wi_boolean_t wi_number_bool(wi_number_t *number) {
	wi_boolean_t		value;
	
	wi_number_get_value(number, WI_NUMBER_BOOL, &value);
	
	return value;
}



char wi_number_char(wi_number_t *number) {
	char		value;
	
	wi_number_get_value(number, WI_NUMBER_CHAR, &value);
	
	return value;
}



short wi_number_short(wi_number_t *number) {
	short		value;
	
	wi_number_get_value(number, WI_NUMBER_SHORT, &value);
	
	return value;
}



int wi_number_int(wi_number_t *number) {
	int		value;
	
	wi_number_get_value(number, WI_NUMBER_INT, &value);
	
	return value;
}



int32_t wi_number_int32(wi_number_t *number) {
	int32_t		value;
	
	wi_number_get_value(number, WI_NUMBER_INT32, &value);
	
	return value;
}



int64_t wi_number_int64(wi_number_t *number) {
	int64_t		value;
	
	wi_number_get_value(number, WI_NUMBER_INT64, &value);
	
	return value;
}



wi_integer_t wi_number_integer(wi_number_t *number) {
#if WI_32
	return wi_number_int32(number);
#else
	return wi_number_int64(number);
#endif
}



long wi_number_long(wi_number_t *number) {
	long		value;
	
	wi_number_get_value(number, WI_NUMBER_LONG, &value);
	
	return value;
}



long long wi_number_long_long(wi_number_t *number) {
	long long		value;
	
	wi_number_get_value(number, WI_NUMBER_LONG_LONG, &value);
	
	return value;
}



float wi_number_float(wi_number_t *number) {
	float		value;
	
	wi_number_get_value(number, WI_NUMBER_FLOAT, &value);
	
	return value;
}



double wi_number_double(wi_number_t *number) {
	double		value;
	
	wi_number_get_value(number, WI_NUMBER_DOUBLE, &value);
	
	return value;
}



#pragma mark -

wi_string_t * wi_number_string(wi_number_t *number) {
	if(_wi_number_is_float(number))
		return wi_string_with_format(WI_STR("%f"), wi_number_double(number));
	else
		return wi_string_with_format(WI_STR("%lld"), wi_number_int64(number));
}
