/* $Id$ */

/*
 *  Copyright (c) 2006-2009 Axel Andersson
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

#include <sys/fcntl.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>

#include <wired/wi-data.h>
#include <wired/wi-digest.h>
#include <wired/wi-file.h>
#include <wired/wi-fs.h>
#include <wired/wi-macros.h>
#include <wired/wi-private.h>
#include <wired/wi-random.h>
#include <wired/wi-runtime.h>
#include <wired/wi-string.h>
#include <wired/wi-system.h>

#define _WI_DATA_MIN_SIZE				128


struct _wi_data {
	wi_runtime_base_t					base;
	
	void								*bytes;
	wi_uinteger_t						length;
	wi_uinteger_t						capacity;
	wi_boolean_t						free;
};


static void								_wi_data_dealloc(wi_runtime_instance_t *);
static wi_runtime_instance_t *			_wi_data_copy(wi_runtime_instance_t *);
static wi_boolean_t						_wi_data_is_equal(wi_runtime_instance_t *, wi_runtime_instance_t *);
static wi_string_t *					_wi_data_description(wi_runtime_instance_t *);
static wi_hash_code_t					_wi_data_hash(wi_runtime_instance_t *);

static void								_wi_data_append_bytes(wi_mutable_data_t *, const void *, wi_uinteger_t);


static wi_runtime_id_t					_wi_data_runtime_id = WI_RUNTIME_ID_NULL;
static wi_runtime_class_t				_wi_data_runtime_class = {
	"wi_data_t",
	_wi_data_dealloc,
	_wi_data_copy,
	_wi_data_is_equal,
	_wi_data_description,
	_wi_data_hash
};



void wi_data_register(void) {
	_wi_data_runtime_id = wi_runtime_register_class(&_wi_data_runtime_class);
}



void wi_data_initialize(void) {
}



#pragma mark -

wi_runtime_id_t wi_data_runtime_id(void) {
	return _wi_data_runtime_id;
}



#pragma mark -

wi_data_t * wi_data(void) {
	return wi_autorelease(wi_data_init(wi_data_alloc()));
}



wi_data_t * wi_data_with_bytes(const void *bytes, wi_uinteger_t length) {
	return wi_autorelease(wi_data_init_with_bytes(wi_data_alloc(), bytes, length));
}



wi_data_t * wi_data_with_bytes_no_copy(void *bytes, wi_uinteger_t length, wi_boolean_t free) {
	return wi_autorelease(wi_data_init_with_bytes_no_copy(wi_data_alloc(), bytes, length, free));
}



wi_data_t * wi_data_with_random_bytes(wi_uinteger_t length) {
	return wi_autorelease(wi_data_init_with_random_bytes(wi_data_alloc(), length));
}



wi_data_t * wi_data_with_base64(wi_string_t *base64) {
	return wi_autorelease(wi_data_init_with_base64(wi_data_alloc(), base64));
}



wi_data_t * wi_data_with_contents_of_file(wi_string_t *base64) {
	return wi_autorelease(wi_data_init_with_contents_of_file(wi_data_alloc(), base64));
}



wi_mutable_data_t * wi_mutable_data(void) {
	return wi_autorelease(wi_data_init(wi_mutable_data_alloc()));
}



#pragma mark -

wi_data_t * wi_data_alloc(void) {
	return wi_runtime_create_instance_with_options(_wi_data_runtime_id, sizeof(wi_data_t), WI_RUNTIME_OPTION_IMMUTABLE);
}



wi_mutable_data_t * wi_mutable_data_alloc(void) {
	return wi_runtime_create_instance_with_options(_wi_data_runtime_id, sizeof(wi_data_t), WI_RUNTIME_OPTION_MUTABLE);
}



wi_data_t * wi_data_init(wi_data_t *data) {
	return wi_data_init_with_capacity(data, 0);
}



wi_data_t * wi_data_init_with_capacity(wi_data_t *data, wi_uinteger_t capacity) {
	data->capacity	= WI_MAX(wi_exp2m1(wi_log2(capacity) + 1), _WI_DATA_MIN_SIZE);
	data->bytes		= wi_malloc(data->capacity);
	data->free		= true;
	
	return data;
}



wi_data_t * wi_data_init_with_bytes(wi_data_t *data, const void *bytes, wi_uinteger_t length) {
	data = wi_data_init_with_capacity(data, length);

	memcpy(data->bytes, bytes, length);
	
	data->length = length;

	return data;
}



wi_data_t * wi_data_init_with_bytes_no_copy(wi_data_t *data, void *bytes, wi_uinteger_t length, wi_boolean_t free) {
	data->bytes		= bytes;
	data->capacity	= length;
	data->length	= length;
	data->free		= free;
	
	return data;
}



wi_data_t * wi_data_init_with_random_bytes(wi_data_t *data, wi_uinteger_t length) {
	data = wi_data_init_with_capacity(data, length);
	
	wi_random_get_bytes(data->bytes, length);
	
	data->length = length;
	
	return data;
}



wi_data_t * wi_data_init_with_base64(wi_data_t *data, wi_string_t *string) {
	wi_release(data);
	
	data = wi_data_from_base64_string(string);
	
	return wi_retain(data);
}



wi_data_t * wi_data_init_with_contents_of_file(wi_data_t *data, wi_string_t *path) {
	wi_file_t		*file;
	wi_fs_stat_t	sb;
	char			buffer[WI_FILE_BUFFER_SIZE];
	wi_integer_t	bytes;
	
	if(!wi_fs_stat_path(path, &sb)) {
		wi_release(data);
		
		return NULL;
	}
	
	file = wi_file_for_reading(path);
	
	if(!file) {
		wi_release(data);
		
		return NULL;
	}
	
	data = wi_data_init_with_capacity(data, sb.size);
	
	while((bytes = wi_file_read_buffer(file, buffer, sizeof(buffer))))
		_wi_data_append_bytes(data, buffer, bytes);
	
	return data;
}



static void _wi_data_dealloc(wi_runtime_instance_t *instance) {
	wi_data_t		*data = instance;
	
	if(data->free)
		wi_free(data->bytes);
}



static wi_runtime_instance_t * _wi_data_copy(wi_runtime_instance_t *instance) {
	wi_data_t		*data = instance;
	
	return wi_data_init_with_bytes(wi_data_alloc(), data->bytes, data->length);
}



static wi_boolean_t _wi_data_is_equal(wi_runtime_instance_t *instance1, wi_runtime_instance_t *instance2) {
	wi_data_t		*data1 = instance1;
	wi_data_t		*data2 = instance2;
	
	if(data1->length != data2->length)
		return false;
	
	return (memcmp(data1->bytes, data2->bytes, data1->length) == 0);
}



static wi_string_t * _wi_data_description(wi_runtime_instance_t *instance) {
	wi_data_t				*data = instance;
	wi_mutable_string_t		*string;
	const unsigned char		*bytes;
	wi_uinteger_t			i;
	
	string		= wi_mutable_string();
	bytes		= data->bytes;
	
	for(i = 0; i < data->length; i++) {
		if(i > 0 && i % 4 == 0)
			wi_mutable_string_append_string(string, WI_STR(" "));

		wi_mutable_string_append_format(string, WI_STR("%02X"), bytes[i]);
	}
	
	wi_runtime_make_immutable(string);
	
	return string;
}



static wi_hash_code_t _wi_data_hash(wi_runtime_instance_t *instance) {
	wi_data_t		*data = instance;
	
	return wi_hash_data(data->bytes, WI_MIN(data->length, 16));
}



#pragma mark -

const void * wi_data_bytes(wi_data_t *data) {
	return data->bytes;
}



wi_uinteger_t wi_data_length(wi_data_t *data) {
	return data->length;
}



void wi_data_get_bytes(wi_data_t *data, void *bytes, wi_uinteger_t length) {
	memcpy(bytes, data->bytes, length);
}



#pragma mark -

static void _wi_data_append_bytes(wi_mutable_data_t *data, const void *bytes, wi_uinteger_t length) {
	if(data->length + length > data->capacity) {
		data->capacity		= data->length + length;
		data->bytes			= wi_realloc(data->bytes, data->capacity);
	}
	
	memcpy(data->bytes + data->length, bytes, length);

	data->length += length;
}



#pragma mark -

wi_data_t * wi_data_by_appending_data(wi_data_t *data, wi_data_t *append_data) {
	wi_mutable_data_t		*newdata;
	
	newdata = wi_mutable_copy(data);
	wi_mutable_data_append_bytes(newdata, append_data->bytes, append_data->length);
	
	wi_runtime_make_immutable(data);
	
	return wi_autorelease(newdata);
}



wi_data_t * wi_data_by_appending_bytes(wi_data_t *data, const void *bytes, wi_uinteger_t length) {
	wi_mutable_data_t		*newdata;
	
	newdata = wi_copy(data);
	wi_mutable_data_append_bytes(newdata, bytes, length);
	
	wi_runtime_make_immutable(data);

	return wi_autorelease(newdata);
}



#pragma mark -

#ifdef WI_DIGESTS

wi_string_t * wi_data_md5(wi_data_t *data) {
	return wi_md5_digest_string(data);
}



wi_string_t * wi_data_sha1(wi_data_t *data) {
	return wi_sha1_digest_string(data);
}

wi_string_t * wi_data_sha256(wi_data_t *data) {
    return wi_sha256_digest_string(data);
}

wi_string_t * wi_data_sha512(wi_data_t *data) {
    return wi_sha512_digest_string(data);
}


#endif



wi_string_t * wi_data_base64(wi_data_t *data) {
	return wi_base64_string_from_data(data);
}



#pragma mark -

wi_boolean_t wi_data_write_to_file(wi_data_t *data, wi_string_t *path) {
	FILE			*fp;
	wi_string_t		*fullpath;
	
	fullpath = wi_string_by_appending_string(path, WI_STR("~"));
	
	fp = fopen(wi_string_cstring(fullpath), "w");

	if(!fp) {
		wi_error_set_errno(errno);

		return false;
	}
	
	fwrite(data->bytes, 1, data->length, fp);
	fclose(fp);
	
	if(!wi_fs_rename_path(fullpath, path)) {
		wi_fs_delete_path(fullpath);
		
		return false;
	}
	
	return true;
}



#pragma mark -

void wi_mutable_data_append_data(wi_mutable_data_t *data, wi_data_t *append_data) {
	WI_RUNTIME_ASSERT_MUTABLE(data);
	
	_wi_data_append_bytes(data, append_data->bytes, append_data->length);
}



void wi_mutable_data_append_bytes(wi_mutable_data_t *data, const void *bytes, wi_uinteger_t length) {
	WI_RUNTIME_ASSERT_MUTABLE(data);
	
	_wi_data_append_bytes(data, bytes, length);
}
