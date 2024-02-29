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

#include <stdlib.h>
#include <stdarg.h>
#include <unistd.h>
#include <string.h>

#include <wired/wi-array.h>
#include <wired/wi-assert.h>
#include <wired/wi-enumerator.h>
#include <wired/wi-lock.h>
#include <wired/wi-macros.h>
#include <wired/wi-private.h>
#include <wired/wi-runtime.h>
#include <wired/wi-set.h>
#include <wired/wi-string.h>
#include <wired/wi-system.h>

#define _WI_SET_MIN_COUNT				11
#define _WI_SET_MAX_COUNT				16777213

#define _WI_SET_CHECK_RESIZE(set)										\
	WI_STMT_START														\
		if((set->buckets_count >= 3 * set->data_count &&				\
		    set->buckets_count >  set->min_count) ||					\
		   (set->data_count    >= 3 * set->buckets_count &&				\
			set->buckets_count <  _WI_SET_MAX_COUNT))					\
			_wi_set_resize(set);										\
	WI_STMT_END

#define _WI_SET_RETAIN(set, data)										\
	((set)->callbacks.retain											\
		? (*(set)->callbacks.retain)((data))							\
		: (data))

#define _WI_SET_RELEASE(set, data)										\
	WI_STMT_START														\
		if((set)->callbacks.release)									\
			(*(set)->callbacks.release)((data));						\
	WI_STMT_END

#define _WI_SET_HASH(set, data)											\
	((set)->callbacks.hash												\
		? (*(set)->callbacks.hash)((data))								\
		: wi_hash_pointer((data)))

#define _WI_SET_IS_EQUAL(set, data1, data2)								\
	(((set)->callbacks.is_equal &&										\
	  (*(set)->callbacks.is_equal)((data1), (data2))) ||				\
	 (!(set)->callbacks.is_equal &&										\
	  (data1) == (data2)))


struct _wi_set_bucket {
	void								*data;
	wi_uinteger_t						count;

	struct _wi_set_bucket				*next, *link;
};
typedef struct _wi_set_bucket			_wi_set_bucket_t;


struct _wi_set {
	wi_runtime_base_t					base;
	
	wi_set_callbacks_t					callbacks;
	
	wi_boolean_t						counted;

	_wi_set_bucket_t					**buckets;
	wi_uinteger_t						buckets_count;
	wi_uinteger_t						min_count;
	wi_uinteger_t						data_count;
	
	wi_rwlock_t							*lock;
	
	_wi_set_bucket_t					**bucket_chunks;
	wi_uinteger_t						bucket_chunks_count;
	wi_uinteger_t						bucket_chunks_offset;

	_wi_set_bucket_t					*bucket_free_list;
};


static void								_wi_set_dealloc(wi_runtime_instance_t *);
static wi_runtime_instance_t *			_wi_set_copy(wi_runtime_instance_t *);
static wi_boolean_t						_wi_set_is_equal(wi_runtime_instance_t *, wi_runtime_instance_t *);
static wi_string_t *					_wi_set_description(wi_runtime_instance_t *);
static wi_hash_code_t					_wi_set_hash(wi_runtime_instance_t *);

static void								_wi_set_resize(wi_set_t *);

static _wi_set_bucket_t *				_wi_set_bucket_create(wi_set_t *);
static _wi_set_bucket_t *				_wi_set_bucket_for_data(wi_set_t *, void *, wi_uinteger_t);
static void								_wi_set_bucket_remove(wi_set_t *, _wi_set_bucket_t *);

static void								_wi_set_add_data(wi_set_t *, void *);
static void								_wi_set_add_data_from_array(wi_set_t *, wi_array_t *);
static void								_wi_set_remove_all_data(wi_set_t *);


const wi_set_callbacks_t				wi_set_default_callbacks = {
	wi_retain,
	wi_release,
	wi_is_equal,
	wi_description,
	wi_hash
};

const wi_set_callbacks_t				wi_set_null_callbacks = {
	NULL,
	NULL,
	NULL,
	NULL,
	NULL
};

static wi_uinteger_t					_wi_set_buckets_per_page;

static wi_runtime_id_t					_wi_set_runtime_id = WI_RUNTIME_ID_NULL;
static wi_runtime_class_t				_wi_set_runtime_class = {
	"wi_set_t",
	_wi_set_dealloc,
	_wi_set_copy,
	_wi_set_is_equal,
	_wi_set_description,
	_wi_set_hash
};



void wi_set_register(void) {
	_wi_set_runtime_id = wi_runtime_register_class(&_wi_set_runtime_class);
}



void wi_set_initialize(void) {
	_wi_set_buckets_per_page = wi_page_size() / sizeof(_wi_set_bucket_t);
}



#pragma mark -

wi_runtime_id_t wi_set_runtime_id(void) {
	return _wi_set_runtime_id;
}



#pragma mark -

wi_set_t * wi_set(void) {
	return wi_autorelease(wi_set_init(wi_set_alloc()));
}



wi_set_t * wi_set_with_data(void *data0, ...) {
	wi_set_t	*set;
	void		*data;
	va_list		ap;
	
	set = wi_set_init_with_capacity(wi_set_alloc(), 0, false);
	
	_wi_set_add_data(set, data0);
	
	va_start(ap, data0);
	while((data = va_arg(ap, void *)))
		_wi_set_add_data(set, data);
	va_end(ap);
	
	return wi_autorelease(set);
}



wi_mutable_set_t * wi_mutable_set(void) {
	return wi_autorelease(wi_set_init(wi_mutable_set_alloc()));
}



#pragma mark -

wi_set_t * wi_set_alloc(void) {
	return wi_runtime_create_instance_with_options(_wi_set_runtime_id, sizeof(wi_set_t), WI_RUNTIME_OPTION_IMMUTABLE);
}



wi_mutable_set_t * wi_mutable_set_alloc(void) {
	return wi_runtime_create_instance_with_options(_wi_set_runtime_id, sizeof(wi_set_t), WI_RUNTIME_OPTION_MUTABLE);
}



wi_set_t * wi_set_init(wi_set_t *set) {
	return wi_set_init_with_capacity(set, 0, false);
}



wi_set_t * wi_set_init_with_capacity(wi_set_t *set, wi_uinteger_t capacity, wi_boolean_t counted) {
	return wi_set_init_with_capacity_and_callbacks(set, capacity, counted, wi_set_default_callbacks);
}



wi_set_t * wi_set_init_with_capacity_and_callbacks(wi_set_t *instance, wi_uinteger_t capacity, wi_boolean_t counted, wi_set_callbacks_t callbacks) {
	wi_set_t					*set = instance;

	set->callbacks				= callbacks;
	set->bucket_chunks_offset	= _wi_set_buckets_per_page;
	set->min_count				= WI_MAX(wi_exp2m1(wi_log2(capacity) + 1), _WI_SET_MIN_COUNT);
	set->buckets_count			= set->min_count;
	set->buckets				= wi_malloc(set->buckets_count * sizeof(_wi_set_bucket_t *));
	set->lock					= wi_rwlock_init(wi_rwlock_alloc());
	set->counted				= counted;
	
	return set;
}



wi_set_t * wi_set_init_with_data(wi_set_t *set, ...) {
	void			*data;
	va_list			ap;

	set = wi_set_init_with_capacity(set, 0, false);

	va_start(ap, set);
	while((data = va_arg(ap, void *)))
		_wi_set_add_data(set, data);
	va_end(ap);
	
	return set;
}



wi_set_t * wi_set_init_with_array(wi_set_t *set, wi_array_t *array) {
	set = wi_set_init_with_capacity(set, wi_array_count(array), false);
	
	_wi_set_add_data_from_array(set, array);
	
	return set;
}



static void _wi_set_dealloc(wi_runtime_instance_t *instance) {
	wi_set_t			*set = instance;
	_wi_set_bucket_t	*bucket;
	wi_uinteger_t		i;

	for(i = 0; i < set->buckets_count; i++) {
		for(bucket = set->buckets[i]; bucket; bucket = bucket->next)
			_WI_SET_RELEASE(set, bucket->data);
	}

	if(set->bucket_chunks) {
		for(i = 0; i < set->bucket_chunks_count; i++)
			wi_free(set->bucket_chunks[i]);

		wi_free(set->bucket_chunks);
	}
	
	wi_free(set->buckets);

	wi_release(set->lock);
}



static wi_runtime_instance_t * _wi_set_copy(wi_runtime_instance_t *instance) {
	wi_set_t			*set = instance, *set_copy;
	_wi_set_bucket_t	*bucket;
	wi_uinteger_t		i, j;
	
	set_copy = wi_set_init_with_capacity_and_callbacks(wi_set_alloc(), set->data_count, set->counted, set->callbacks);
	
	for(i = 0; i < set->buckets_count; i++) {
		for(bucket = set->buckets[i]; bucket; bucket = bucket->next) {
			for(j = 0; j < bucket->count; j++)
				_wi_set_add_data(set_copy, bucket->data);
		}
	}
	
	return set_copy;
}



static wi_boolean_t _wi_set_is_equal(wi_runtime_instance_t *instance1, wi_runtime_instance_t *instance2) {
	wi_set_t			*set1 = instance1;
	wi_set_t			*set2 = instance2;
	_wi_set_bucket_t	*bucket;
	wi_uinteger_t		i;
	
	if(set1->data_count != set2->data_count)
		return false;
	
	for(i = 0; i < set1->buckets_count; i++) {
		for(bucket = set1->buckets[i]; bucket; bucket = bucket->next) {
			if(!wi_set_contains_data(set2, bucket->data))
				return false;
		}
	}
	
	return true;
}



static wi_string_t * _wi_set_description(wi_runtime_instance_t *instance) {
	wi_set_t				*set = instance;
	_wi_set_bucket_t		*bucket;
	wi_mutable_string_t		*string;
	wi_string_t				*description;
	wi_uinteger_t			i;

	string = wi_mutable_string_with_format(WI_STR("<%@ %p>{count = %lu, mutable = %u, values = (\n"),
		wi_runtime_class_name(set),
		set,
		set->data_count,
		wi_runtime_options(set) & WI_RUNTIME_OPTION_MUTABLE ? 1 : 0);

	for(i = 0; i < set->buckets_count; i++) {
		for(bucket = set->buckets[i]; bucket; bucket = bucket->next) {
			if(set->callbacks.description)
				description = (*set->callbacks.description)(bucket->data);
			else
				description = wi_string_with_format(WI_STR("%p"), bucket->data);

			wi_mutable_string_append_format(string, WI_STR("    %@\n"), description);
		}
	}
	
	wi_mutable_string_append_string(string, WI_STR(")}"));
	
	wi_runtime_make_immutable(string);

	return string;
}



static wi_hash_code_t _wi_set_hash(wi_runtime_instance_t *instance) {
	wi_set_t	*set = instance;
	
	return set->data_count;
}


#pragma mark -

void wi_set_wrlock(wi_mutable_set_t *set) {
	WI_RUNTIME_ASSERT_MUTABLE(set);
	
	wi_rwlock_wrlock(set->lock);
}



wi_boolean_t wi_set_trywrlock(wi_mutable_set_t *set) {
	WI_RUNTIME_ASSERT_MUTABLE(set);
	
	return wi_rwlock_trywrlock(set->lock);
}



void wi_set_rdlock(wi_set_t *set) {
	wi_rwlock_rdlock(set->lock);
}



wi_boolean_t wi_set_tryrdlock(wi_set_t *set) {
	return wi_rwlock_tryrdlock(set->lock);
}



void wi_set_unlock(wi_set_t *set) {
	wi_rwlock_unlock(set->lock);
}



#pragma mark -

wi_uinteger_t wi_set_count(wi_set_t *set) {
	return set->data_count;
}



wi_array_t * wi_set_all_data(wi_set_t *set) {
	wi_array_t				*array;
	_wi_set_bucket_t		*bucket;
	wi_array_callbacks_t	callbacks;
	wi_uinteger_t			i;
	
	callbacks.retain		= set->callbacks.retain;
	callbacks.release		= set->callbacks.release;
	callbacks.is_equal		= set->callbacks.is_equal;
	callbacks.description	= set->callbacks.description;
	array					= wi_array_init_with_capacity_and_callbacks(wi_mutable_array_alloc(), set->data_count, callbacks);

	for(i = 0; i < set->buckets_count; i++) {
		for(bucket = set->buckets[i]; bucket; bucket = bucket->next)
			wi_mutable_array_add_data(array, bucket->data);
	}
	
	wi_runtime_make_immutable(array);

	return wi_autorelease(array);
}



#pragma mark -

wi_enumerator_t * wi_set_data_enumerator(wi_set_t *set) {
	return wi_autorelease(wi_enumerator_init_with_collection(wi_enumerator_alloc(), set, wi_enumerator_set_data_enumerator));
}



void * wi_enumerator_set_data_enumerator(wi_runtime_instance_t *instance, wi_enumerator_context_t *context) {
	wi_set_t				*set = instance;
	_wi_set_bucket_t		*bucket;
	
	bucket = context->bucket;
	
	if(bucket) {
		if(bucket->next) {
			bucket = bucket->next;
			context->bucket = bucket;
			
			return bucket->data;
		} else {
			context->index++;
			context->bucket = NULL;
		}
	}
	
	while(context->index < set->buckets_count) {
		bucket = set->buckets[context->index];
		
		if(bucket) {
			context->bucket = bucket;
			
			return bucket->data;
		}
		
		context->index++;
	}
	
	return NULL;
}



#pragma mark -

static void _wi_set_resize(wi_set_t *set) {
	_wi_set_bucket_t	**buckets, *bucket, *next_bucket;
	wi_uinteger_t		i, index, capacity, buckets_count;

	capacity		= wi_exp2m1(wi_log2(set->data_count) + 1);
	buckets_count	= WI_CLAMP(capacity, set->min_count, _WI_SET_MAX_COUNT);
	buckets			= wi_malloc(buckets_count * sizeof(_wi_set_bucket_t *));

	for(i = 0; i < set->buckets_count; i++) {
		for(bucket = set->buckets[i]; bucket; bucket = next_bucket) {
			next_bucket		= bucket->next;
			index			= _WI_SET_HASH(set, bucket->data) % buckets_count;
			bucket->next	= buckets[index];
			buckets[index]	= bucket;
		}
	}

	wi_free(set->buckets);

	set->buckets		= buckets;
	set->buckets_count	= buckets_count;
}



#pragma mark -

static _wi_set_bucket_t * _wi_set_bucket_create(wi_set_t *set) {
	_wi_set_bucket_t	*bucket, *bucket_block;
	size_t				size;

	if(!set->bucket_free_list) {
		if(set->bucket_chunks_offset == _wi_set_buckets_per_page) {
			set->bucket_chunks_count++;

			size = set->bucket_chunks_count * sizeof(_wi_set_bucket_t *);
			set->bucket_chunks = wi_realloc(set->bucket_chunks, size);

			size = _wi_set_buckets_per_page * sizeof(_wi_set_bucket_t);
			set->bucket_chunks[set->bucket_chunks_count - 1] = wi_malloc(size);

			set->bucket_chunks_offset = 0;
		}

		bucket_block = set->bucket_chunks[set->bucket_chunks_count - 1];
		set->bucket_free_list = &bucket_block[set->bucket_chunks_offset++];
		set->bucket_free_list->link = NULL;
	}

	bucket = set->bucket_free_list;
	set->bucket_free_list = bucket->link;

	return bucket;
}



static _wi_set_bucket_t * _wi_set_bucket_for_data(wi_set_t *set, void *data, wi_uinteger_t index) {
	_wi_set_bucket_t	*bucket;
	
	bucket = set->buckets[index];

	if(!bucket)
		return NULL;

	for(; bucket; bucket = bucket->next) {
		if(_WI_SET_IS_EQUAL(set, bucket->data, data))
			return bucket;
	}
		
	return NULL;
}



static void _wi_set_bucket_remove(wi_set_t *set, _wi_set_bucket_t *bucket) {
	_WI_SET_RELEASE(set, bucket->data);
	
	bucket->link = set->bucket_free_list;
	set->bucket_free_list = bucket;

	set->data_count--;
}



#pragma mark -

static void _wi_set_add_data(wi_set_t *set, void *data) {
	_wi_set_bucket_t	*bucket;
	wi_uinteger_t		index;
	
	index = _WI_SET_HASH(set, data) % set->buckets_count;
	bucket = _wi_set_bucket_for_data(set, data, index);

	if(bucket) {
		bucket->count++;
	} else {
		bucket				= _wi_set_bucket_create(set);
		bucket->next		= set->buckets[index];
		bucket->data		= _WI_SET_RETAIN(set, data);
		bucket->count		= 1;

		set->data_count++;
		set->buckets[index] = bucket;
	}

	_WI_SET_CHECK_RESIZE(set);
}



static void _wi_set_add_data_from_array(wi_set_t *set, wi_array_t *array) {
	wi_uinteger_t	i, count;
	
	count = wi_array_count(array);
	
	for(i = 0; i < count; i++)
		_wi_set_add_data(set, WI_ARRAY(array, i));
}



static void _wi_set_remove_all_data(wi_set_t *set) {
	_wi_set_bucket_t	*bucket;
	wi_uinteger_t		i;

	for(i = 0; i < set->buckets_count; i++) {
		for(bucket = set->buckets[i]; bucket; bucket = bucket->next)
			_wi_set_bucket_remove(set, bucket);

		set->buckets[i] = NULL;
	}

	_WI_SET_CHECK_RESIZE(set);
}



#pragma mark -

wi_boolean_t wi_set_contains_data(wi_set_t *set, void *data) {
	_wi_set_bucket_t	*bucket;
	wi_uinteger_t		index;
	
	index = _WI_SET_HASH(set, data) % set->buckets_count;
	bucket = _wi_set_bucket_for_data(set, data, index);
	
	return (bucket != NULL);
}



wi_uinteger_t wi_set_count_for_data(wi_set_t *set, void *data) {
	_wi_set_bucket_t	*bucket;
	wi_uinteger_t		index;
	
	index = _WI_SET_HASH(set, data) % set->buckets_count;
	bucket = _wi_set_bucket_for_data(set, data, index);
	
	if(!bucket)
		return 0;
	
	return bucket->count;
}



#pragma mark -

void wi_mutable_set_add_data(wi_mutable_set_t *set, void *data) {
	WI_RUNTIME_ASSERT_MUTABLE(set);
	
	if(set->callbacks.retain == wi_retain) {
		WI_ASSERT(data != NULL,
			"attempt to insert NULL data in %@",
			set);
	}

	_wi_set_add_data(set, data);
}



void wi_mutable_set_add_data_from_array(wi_mutable_set_t *set, wi_array_t *array) {
	WI_RUNTIME_ASSERT_MUTABLE(set);
	
	_wi_set_add_data_from_array(set, array);
}



void wi_mutable_set_set_set(wi_mutable_set_t *set, wi_set_t *otherset) {
	_wi_set_bucket_t	*bucket;
	wi_uinteger_t		i;

	WI_RUNTIME_ASSERT_MUTABLE(set);

	_wi_set_remove_all_data(set);

	for(i = 0; i < otherset->buckets_count; i++) {
		for(bucket = otherset->buckets[i]; bucket; bucket = bucket->next)
			_wi_set_add_data(set, bucket->data);
	}
}



#pragma mark -

void wi_mutable_set_remove_data(wi_mutable_set_t *set, void *data) {
	_wi_set_bucket_t	*bucket, *previous_bucket;
	wi_uinteger_t		index;
	wi_boolean_t		remove = false;

	WI_RUNTIME_ASSERT_MUTABLE(set);

	if(set->callbacks.release == wi_release) {
		WI_ASSERT(data != NULL,
			"attempt to remove NULL data in %@",
			set);
	}

	index = _WI_SET_HASH(set, data) % set->buckets_count;
	bucket = set->buckets[index];

	if(bucket) {
		previous_bucket = NULL;
		
		for(; bucket; bucket = bucket->next) {
			if(_WI_SET_IS_EQUAL(set, bucket->data, data)) {
				if(set->counted) {
					if(--bucket->count == 0)
						remove = true;
				} else {
					remove = true;
				}
				
				if(remove) {
					if(bucket == set->buckets[index])
						set->buckets[index] = bucket->next;
					
					if(previous_bucket)
						previous_bucket->next = bucket->next;
					
					_wi_set_bucket_remove(set, bucket);
				}
				break;
			}
			
			previous_bucket = bucket;
		}
	}
	
	_WI_SET_CHECK_RESIZE(set);
}



void wi_mutable_set_remove_all_data(wi_mutable_set_t *set) {
	WI_RUNTIME_ASSERT_MUTABLE(set);
	
	_wi_set_remove_all_data(set);
}
