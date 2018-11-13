/* $Id$ */

/*
 *  Copyright (c) 2005-2009 Axel Andersson
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
#include <wired/wi-dictionary.h>
#include <wired/wi-lock.h>
#include <wired/wi-macros.h>
#include <wired/wi-plist.h>
#include <wired/wi-private.h>
#include <wired/wi-runtime.h>
#include <wired/wi-string.h>
#include <wired/wi-system.h>

#if defined(HAVE_QSORT_R) && !defined(HAVE_GLIBC)
#define _WI_DICTIONARY_USE_QSORT_R
#endif

#define _WI_DICTIONARY_MIN_COUNT				11
#define _WI_DICTIONARY_MAX_COUNT				16777213

#define _WI_DICTIONARY_CHECK_RESIZE(dictionary)								\
	WI_STMT_START															\
		if((dictionary->buckets_count >= 3 * dictionary->key_count &&		\
		    dictionary->buckets_count >  dictionary->min_count) ||			\
		   (dictionary->key_count     >= 3 * dictionary->buckets_count &&	\
			dictionary->buckets_count <  _WI_DICTIONARY_MAX_COUNT))			\
			_wi_dictionary_resize(dictionary);								\
	WI_STMT_END

#define _WI_DICTIONARY_KEY_RETAIN(dictionary, key)							\
	((dictionary)->key_callbacks.retain										\
		? (*(dictionary)->key_callbacks.retain)((key))						\
		: (key))

#define _WI_DICTIONARY_KEY_RELEASE(dictionary, key)							\
	WI_STMT_START															\
		if((dictionary)->key_callbacks.release)								\
			(*(dictionary)->key_callbacks.release)((key));					\
	WI_STMT_END

#define _WI_DICTIONARY_KEY_HASH(dictionary, key)							\
	((dictionary)->key_callbacks.hash										\
		? (*(dictionary)->key_callbacks.hash)((key))						\
		: wi_hash_pointer((key)))

#define _WI_DICTIONARY_KEY_IS_EQUAL(dictionary, key1, key2)					\
	(((dictionary)->key_callbacks.is_equal &&								\
	  (*(dictionary)->key_callbacks.is_equal)((key1), (key2))) ||			\
	 (!(dictionary)->key_callbacks.is_equal &&								\
	  (key1) == (key2)))

#define _WI_DICTIONARY_VALUE_RETAIN(dictionary, value)						\
	((dictionary)->value_callbacks.retain									\
		? (*(dictionary)->value_callbacks.retain)((value))					\
		: (value))

#define _WI_DICTIONARY_VALUE_RELEASE(dictionary, value)						\
	WI_STMT_START															\
		if((dictionary)->value_callbacks.release)							\
			(*(dictionary)->value_callbacks.release)((value));				\
	WI_STMT_END

#define _WI_DICTIONARY_VALUE_IS_EQUAL(dictionary, value1, value2)			\
	(((dictionary)->value_callbacks.is_equal &&								\
	  (*(dictionary)->value_callbacks.is_equal)((value1), (value2))) ||		\
	 (!(dictionary)->value_callbacks.is_equal &&							\
	  (value1) == (value2)))


struct _wi_dictionary_bucket {
	void								*key;
	void								*data;

	struct _wi_dictionary_bucket		*next, *link;
};
typedef struct _wi_dictionary_bucket	_wi_dictionary_bucket_t;


struct _wi_dictionary {
	wi_runtime_base_t					base;
	
	wi_dictionary_key_callbacks_t		key_callbacks;
	wi_dictionary_value_callbacks_t		value_callbacks;

	_wi_dictionary_bucket_t				**buckets;
	wi_uinteger_t						buckets_count;
	wi_uinteger_t						min_count;
	wi_uinteger_t						key_count;
	
	wi_rwlock_t							*lock;
	
	_wi_dictionary_bucket_t				**bucket_chunks;
	wi_uinteger_t						bucket_chunks_count;
	wi_uinteger_t						bucket_chunks_offset;

	_wi_dictionary_bucket_t				*bucket_free_list;
};


static void								_wi_dictionary_dealloc(wi_runtime_instance_t *);
static wi_runtime_instance_t *			_wi_dictionary_copy(wi_runtime_instance_t *);
static wi_boolean_t						_wi_dictionary_is_equal(wi_runtime_instance_t *, wi_runtime_instance_t *);
static wi_string_t *					_wi_dictionary_description(wi_runtime_instance_t *);
static wi_hash_code_t					_wi_dictionary_hash(wi_runtime_instance_t *);

static _wi_dictionary_bucket_t *		_wi_enumerator_dictionary_enumerator(wi_runtime_instance_t *, wi_enumerator_context_t *);

static void								_wi_dictionary_resize(wi_dictionary_t *);

static _wi_dictionary_bucket_t *		_wi_dictionary_bucket_create(wi_dictionary_t *);
static _wi_dictionary_bucket_t *		_wi_dictionary_bucket_for_key(wi_dictionary_t *, void *, wi_uinteger_t);
static void								_wi_dictionary_bucket_remove(wi_dictionary_t *, _wi_dictionary_bucket_t *);
static void								_wi_dictionary_set_data_for_key(wi_mutable_dictionary_t *, void *, void *);
static void								_wi_dictionary_remove_data_for_key(wi_mutable_dictionary_t *, void *);
static void								_wi_dictionary_remove_all_data(wi_mutable_dictionary_t *);

#ifdef _WI_DICTIONARY_USE_QSORT_R
static int								_wi_dictionary_compare_buckets(void *, const void *, const void *);
#else
static int								_wi_dictionary_compare_buckets(const void *, const void *);
#endif


const wi_dictionary_key_callbacks_t		wi_dictionary_default_key_callbacks = {
	wi_copy,
	wi_release,
	wi_is_equal,
	wi_description,
	wi_hash
};

const wi_dictionary_key_callbacks_t		wi_dictionary_null_key_callbacks = {
	NULL,
	NULL,
	NULL,
	NULL,
	NULL
};

const wi_dictionary_value_callbacks_t	wi_dictionary_default_value_callbacks = {
	wi_retain,
	wi_release,
	wi_is_equal,
	wi_description
};

const wi_dictionary_value_callbacks_t	wi_dictionary_null_value_callbacks = {
	NULL,
	NULL,
	NULL,
	NULL
};

static wi_dictionary_t					*_wi_dictionary0;

static wi_uinteger_t					_wi_dictionary_buckets_per_page;

#ifndef _WI_DICTIONARY_USE_QSORT_R
static wi_lock_t						*_wi_dictionary_sort_lock;
static wi_compare_func_t				*_wi_dictionary_sort_function;
#endif

static wi_runtime_id_t					_wi_dictionary_runtime_id = WI_RUNTIME_ID_NULL;
static wi_runtime_class_t				_wi_dictionary_runtime_class = {
	"wi_dictionary_t",
	_wi_dictionary_dealloc,
	_wi_dictionary_copy,
	_wi_dictionary_is_equal,
	_wi_dictionary_description,
	_wi_dictionary_hash
};



void wi_dictionary_register(void) {
	_wi_dictionary_runtime_id = wi_runtime_register_class(&_wi_dictionary_runtime_class);
}



void wi_dictionary_initialize(void) {
	_wi_dictionary_buckets_per_page = wi_page_size() / sizeof(_wi_dictionary_bucket_t);

#ifndef _WI_DICTIONARY_USE_QSORT_R
	_wi_dictionary_sort_lock = wi_lock_init(wi_lock_alloc());
#endif
	
	_wi_dictionary0 = wi_dictionary_init(wi_dictionary_alloc());
}



#pragma mark -

wi_runtime_id_t wi_dictionary_runtime_id(void) {
	return _wi_dictionary_runtime_id;
}



#pragma mark -

wi_dictionary_t * wi_dictionary(void) {
	return _wi_dictionary0;
}



wi_dictionary_t * wi_dictionary_with_data_and_keys(void *data0, void *key0, ...) {
	wi_dictionary_t		*dictionary;
	void				*data, *key;
	va_list				ap;

	dictionary = wi_dictionary_init(wi_dictionary_alloc());
	
	_wi_dictionary_set_data_for_key(dictionary, data0, key0);

	va_start(ap, key0);
	while((data = va_arg(ap, void *))) {
		key = va_arg(ap, void *);
		
		_wi_dictionary_set_data_for_key(dictionary, data, key);   
	}
	va_end(ap);
	
	return wi_autorelease(dictionary);
}



#ifdef WI_PLIST

wi_dictionary_t * wi_dictionary_with_plist_file(wi_string_t *path) {
	return wi_autorelease(wi_dictionary_init_with_plist_file(wi_dictionary_alloc(), path));
}

#endif



wi_mutable_dictionary_t * wi_mutable_dictionary(void) {
	return wi_autorelease(wi_dictionary_init(wi_mutable_dictionary_alloc()));
}



wi_mutable_dictionary_t * wi_mutable_dictionary_with_data_and_keys(void *data0, void *key0, ...) {
	wi_dictionary_t		*dictionary;
	void				*data, *key;
	va_list				ap;

	dictionary = wi_dictionary_init(wi_mutable_dictionary_alloc());
	
	_wi_dictionary_set_data_for_key(dictionary, data0, key0);

	va_start(ap, key0);
	while((data = va_arg(ap, void *))) {
		key = va_arg(ap, void *);
		
		_wi_dictionary_set_data_for_key(dictionary, data, key);   
	}
	va_end(ap);
	
	return wi_autorelease(dictionary);
}



#pragma mark -

wi_dictionary_t * wi_dictionary_alloc(void) {
	return wi_runtime_create_instance_with_options(_wi_dictionary_runtime_id, sizeof(wi_dictionary_t), WI_RUNTIME_OPTION_IMMUTABLE);
}



wi_mutable_dictionary_t * wi_mutable_dictionary_alloc(void) {
	return wi_runtime_create_instance_with_options(_wi_dictionary_runtime_id, sizeof(wi_dictionary_t), WI_RUNTIME_OPTION_MUTABLE);
}



wi_dictionary_t * wi_dictionary_init(wi_dictionary_t *dictionary) {
	return wi_dictionary_init_with_capacity(dictionary, 0);
}



wi_dictionary_t * wi_dictionary_init_with_capacity(wi_dictionary_t *dictionary, wi_uinteger_t capacity) {
	return wi_dictionary_init_with_capacity_and_callbacks(dictionary, capacity,
		wi_dictionary_default_key_callbacks, wi_dictionary_default_value_callbacks);
}



wi_dictionary_t * wi_dictionary_init_with_capacity_and_callbacks(wi_dictionary_t *dictionary, wi_uinteger_t capacity, wi_dictionary_key_callbacks_t key_callbacks, wi_dictionary_value_callbacks_t value_callbacks) {
	dictionary->key_callbacks			= key_callbacks;
	dictionary->value_callbacks			= value_callbacks;
	dictionary->bucket_chunks_offset	= _wi_dictionary_buckets_per_page;
	dictionary->min_count				= WI_MAX(wi_exp2m1(wi_log2(capacity) + 1), _WI_DICTIONARY_MIN_COUNT);
	dictionary->buckets_count			= dictionary->min_count;
	dictionary->buckets					= wi_malloc(dictionary->buckets_count * sizeof(_wi_dictionary_bucket_t *));
	dictionary->lock					= wi_rwlock_init(wi_rwlock_alloc());
	
	return dictionary;
}



wi_dictionary_t * wi_dictionary_init_with_data_and_keys(wi_dictionary_t *dictionary, ...) {
	void			*data, *key;
	va_list			ap;

	dictionary = wi_dictionary_init_with_capacity(dictionary, 0);

	va_start(ap, dictionary);
	while((data = va_arg(ap, void *))) {
		key = va_arg(ap, void *);
		
		_wi_dictionary_set_data_for_key(dictionary, data, key);   
	}
	va_end(ap);
	
	return dictionary;
}



#ifdef WI_PLIST

wi_dictionary_t * wi_dictionary_init_with_plist_file(wi_dictionary_t *dictionary, wi_string_t *path) {
	wi_runtime_instance_t	*instance;
	
	wi_release(dictionary);
	
	instance = wi_plist_read_instance_from_file(path);
	
	if(!instance)
		return NULL;
	
	if(wi_runtime_id(instance) != wi_dictionary_runtime_id())
		return NULL;
	
	return wi_retain(instance);
}

#endif



static wi_runtime_instance_t * _wi_dictionary_copy(wi_runtime_instance_t *instance) {
	wi_dictionary_t				*dictionary = instance, *dictionary_copy;
	_wi_dictionary_bucket_t		*bucket;
	wi_uinteger_t				i;
	
	dictionary_copy = wi_dictionary_init_with_capacity_and_callbacks(wi_dictionary_alloc(), dictionary->key_count,
		dictionary->key_callbacks, dictionary->value_callbacks);
	
	for(i = 0; i < dictionary->buckets_count; i++) {
		for(bucket = dictionary->buckets[i]; bucket; bucket = bucket->next)
			_wi_dictionary_set_data_for_key(dictionary_copy, bucket->data, bucket->key);
	}
	
	return dictionary_copy;
}



static void _wi_dictionary_dealloc(wi_runtime_instance_t *instance) {
	wi_dictionary_t				*dictionary = instance;
	_wi_dictionary_bucket_t		*bucket;
	wi_uinteger_t				i;
	
	for(i = 0; i < dictionary->buckets_count; i++) {
		for(bucket = dictionary->buckets[i]; bucket; bucket = bucket->next) {
			_WI_DICTIONARY_VALUE_RELEASE(dictionary, bucket->data);
			_WI_DICTIONARY_KEY_RELEASE(dictionary, bucket->key);
		}
	}

	if(dictionary->bucket_chunks) {
		for(i = 0; i < dictionary->bucket_chunks_count; i++)
			wi_free(dictionary->bucket_chunks[i]);

		wi_free(dictionary->bucket_chunks);
	}
	
	wi_free(dictionary->buckets);

	wi_release(dictionary->lock);
}



static wi_boolean_t _wi_dictionary_is_equal(wi_runtime_instance_t *instance1, wi_runtime_instance_t *instance2) {
	wi_dictionary_t				*dictionary1 = instance1;
	wi_dictionary_t				*dictionary2 = instance2;
	_wi_dictionary_bucket_t		*bucket;
	wi_uinteger_t				i;

	if(dictionary1->key_count != dictionary2->key_count)
		return false;
	
	if(dictionary1->value_callbacks.is_equal != dictionary2->value_callbacks.is_equal)
		return false;
	
	for(i = 0; i < dictionary1->buckets_count; i++) {
		for(bucket = dictionary1->buckets[i]; bucket; bucket = bucket->next) {
			if(!_WI_DICTIONARY_VALUE_IS_EQUAL(dictionary1, bucket->data, wi_dictionary_data_for_key(dictionary2, bucket->key)))
				return false;
		}
	}
	
	return true;
}



static wi_string_t * _wi_dictionary_description(wi_runtime_instance_t *instance) {
	wi_dictionary_t				*dictionary = instance;
	_wi_dictionary_bucket_t		*bucket;
	wi_mutable_string_t			*string;
	wi_string_t					*key_description, *value_description;
	wi_uinteger_t				i;

	string = wi_mutable_string_with_format(WI_STR("<%@ %p>{count = %lu, mutable = %u, values = (\n"),
		wi_runtime_class_name(dictionary),
		dictionary,
		dictionary->key_count,
		wi_runtime_options(dictionary) & WI_RUNTIME_OPTION_MUTABLE ? 1 : 0);

	for(i = 0; i < dictionary->buckets_count; i++) {
		for(bucket = dictionary->buckets[i]; bucket; bucket = bucket->next) {
			if(dictionary->key_callbacks.description)
				key_description = (*dictionary->key_callbacks.description)(bucket->key);
			else
				key_description = wi_string_with_format(WI_STR("%p"), bucket->key);

			if(dictionary->value_callbacks.description)
				value_description = (*dictionary->value_callbacks.description)(bucket->data);
			else
				value_description = wi_string_with_format(WI_STR("%p"), bucket->data);
			
			wi_mutable_string_append_format(string, WI_STR("    %@: %@\n"), key_description, value_description);
		}
	}
	
	wi_mutable_string_append_string(string, WI_STR(")}"));
	
	wi_runtime_make_immutable(string);

	return string;
}



static wi_hash_code_t _wi_dictionary_hash(wi_runtime_instance_t *instance) {
	wi_dictionary_t		*dictionary = instance;
	
	return dictionary->key_count;
}


#pragma mark -

void wi_dictionary_wrlock(wi_mutable_dictionary_t *dictionary) {
	WI_RUNTIME_ASSERT_MUTABLE(dictionary);

	wi_rwlock_wrlock(dictionary->lock);
}



wi_boolean_t wi_dictionary_trywrlock(wi_mutable_dictionary_t *dictionary) {
	WI_RUNTIME_ASSERT_MUTABLE(dictionary);

	return wi_rwlock_trywrlock(dictionary->lock);
}



void wi_dictionary_rdlock(wi_dictionary_t *dictionary) {
	wi_rwlock_rdlock(dictionary->lock);
}



wi_boolean_t wi_dictionary_tryrdlock(wi_dictionary_t *dictionary) {
	return wi_rwlock_tryrdlock(dictionary->lock);
}



void wi_dictionary_unlock(wi_dictionary_t *dictionary) {
	wi_rwlock_unlock(dictionary->lock);
}



#pragma mark -

wi_uinteger_t wi_dictionary_count(wi_dictionary_t *dictionary) {
	return dictionary->key_count;
}



void * wi_dictionary_data_for_key(wi_dictionary_t *dictionary, void *key) {
	_wi_dictionary_bucket_t		*bucket;
	wi_uinteger_t				index;

	index = _WI_DICTIONARY_KEY_HASH(dictionary, key) % dictionary->buckets_count;
	bucket = _wi_dictionary_bucket_for_key(dictionary, key, index);
	
	if(bucket)
		return bucket->data;
	
	return NULL;
}



#pragma mark -

wi_boolean_t wi_dictionary_contains_key(wi_dictionary_t *dictionary, void *key) {
	_wi_dictionary_bucket_t		*bucket;
	wi_uinteger_t				index;

	index = _WI_DICTIONARY_KEY_HASH(dictionary, key) % dictionary->buckets_count;
	bucket = _wi_dictionary_bucket_for_key(dictionary, key, index);
	
	return (bucket != NULL);
}



wi_array_t * wi_dictionary_all_keys(wi_dictionary_t *dictionary) {
	wi_mutable_array_t			*array;
	_wi_dictionary_bucket_t		*bucket;
	wi_array_callbacks_t		callbacks;
	wi_uinteger_t				i;
	
	callbacks.retain			= dictionary->key_callbacks.retain;
	callbacks.release			= dictionary->key_callbacks.release;
	callbacks.is_equal			= dictionary->key_callbacks.is_equal;
	callbacks.description		= dictionary->key_callbacks.description;
	array						= wi_array_init_with_capacity_and_callbacks(wi_mutable_array_alloc(), dictionary->key_count, callbacks);

	for(i = 0; i < dictionary->buckets_count; i++) {
		for(bucket = dictionary->buckets[i]; bucket; bucket = bucket->next)
			wi_mutable_array_add_data(array, bucket->key);
	}
	
	wi_runtime_make_immutable(array);

	return wi_autorelease(array);
}



wi_array_t * wi_dictionary_all_values(wi_dictionary_t *dictionary) {
	wi_array_t					*array;
	_wi_dictionary_bucket_t		*bucket;
	wi_array_callbacks_t		callbacks;
	wi_uinteger_t				i;
	
	callbacks.retain			= dictionary->value_callbacks.retain;
	callbacks.release			= dictionary->value_callbacks.release;
	callbacks.is_equal			= dictionary->value_callbacks.is_equal;
	callbacks.description		= dictionary->value_callbacks.description;
	array						= wi_array_init_with_capacity_and_callbacks(wi_mutable_array_alloc(), dictionary->key_count, callbacks);

	for(i = 0; i < dictionary->buckets_count; i++) {
		for(bucket = dictionary->buckets[i]; bucket; bucket = bucket->next)
			wi_mutable_array_add_data(array, bucket->data);
	}
	
	wi_runtime_make_immutable(array);

	return wi_autorelease(array);
}



#ifdef _WI_DICTIONARY_USE_QSORT_R

static int _wi_dictionary_compare_buckets(void *context, const void *p1, const void *p2) {
	return (int)(*(wi_compare_func_t *) context)((*(_wi_dictionary_bucket_t **) p1)->data, (*(_wi_dictionary_bucket_t **) p2)->data);
}

#else

static int _wi_dictionary_compare_buckets(const void *p1, const void *p2) {
	return (*_wi_dictionary_sort_function)((*(_wi_dictionary_bucket_t **) p1)->data, (*(_wi_dictionary_bucket_t **) p2)->data);
}

#endif



wi_array_t * wi_dictionary_keys_sorted_by_value(wi_dictionary_t *dictionary, wi_compare_func_t *compare) {
	wi_mutable_array_t			*array, *buckets;
	_wi_dictionary_bucket_t		*bucket;
	wi_array_callbacks_t		callbacks;
	void						**data;
	wi_uinteger_t				i;
	
	if(dictionary->key_count == 0)
		return wi_autorelease(wi_array_init(wi_array_alloc()));
	
	callbacks.retain		= NULL;
	callbacks.release		= NULL;
	callbacks.is_equal		= NULL;
	callbacks.description	= NULL;
	buckets					= wi_array_init_with_capacity_and_callbacks(wi_mutable_array_alloc(), dictionary->key_count, callbacks);

	for(i = 0; i < dictionary->buckets_count; i++) {
		for(bucket = dictionary->buckets[i]; bucket; bucket = bucket->next)
			wi_mutable_array_add_data(buckets, bucket);
	}
	
	data = wi_malloc(sizeof(void *) * dictionary->key_count);
	wi_array_get_data(buckets, data);
	
#ifdef _WI_DICTIONARY_USE_QSORT_R
	qsort_r(data, dictionary->key_count, sizeof(void *), compare, _wi_dictionary_compare_buckets);
#else
	wi_lock_lock(_wi_dictionary_sort_lock);
	_wi_dictionary_sort_function = compare;
	qsort(data, dictionary->key_count, sizeof(void *), _wi_dictionary_compare_buckets);
	wi_lock_unlock(_wi_dictionary_sort_lock);
#endif
	
	callbacks.retain		= dictionary->key_callbacks.retain;
	callbacks.release		= dictionary->key_callbacks.release;
	callbacks.is_equal		= dictionary->key_callbacks.is_equal;
	callbacks.description	= dictionary->key_callbacks.description;
	array					= wi_array_init_with_capacity_and_callbacks(wi_mutable_array_alloc(), dictionary->key_count, callbacks);

	for(i = 0; i < dictionary->key_count; i++)
		wi_mutable_array_add_data(array, ((_wi_dictionary_bucket_t *) data[i])->key);
	
	wi_free(data);
	wi_release(buckets);

	wi_runtime_make_immutable(array);

	return wi_autorelease(array);
}



#pragma mark -

wi_enumerator_t * wi_dictionary_key_enumerator(wi_dictionary_t *dictionary) {
	return wi_autorelease(wi_enumerator_init_with_collection(wi_enumerator_alloc(), dictionary, wi_enumerator_dictionary_key_enumerator));
}



wi_enumerator_t * wi_dictionary_data_enumerator(wi_dictionary_t *dictionary) {
	return wi_autorelease(wi_enumerator_init_with_collection(wi_enumerator_alloc(), dictionary, wi_enumerator_dictionary_data_enumerator));
}



static _wi_dictionary_bucket_t * _wi_enumerator_dictionary_enumerator(wi_runtime_instance_t *instance, wi_enumerator_context_t *context) {
	wi_dictionary_t				*dictionary = instance;
	_wi_dictionary_bucket_t		*bucket;
	
	bucket = context->bucket;
	
	if(bucket) {
		if(bucket->next) {
			bucket = bucket->next;
			context->bucket = bucket;
			
			return bucket;
		} else {
			context->index++;
			context->bucket = NULL;
		}
	}
	
	while(context->index < dictionary->buckets_count) {
		bucket = dictionary->buckets[context->index];
		
		if(bucket) {
			context->bucket = bucket;
			
			return bucket;
		}
		
		context->index++;
	}
	
	return NULL;
}



void * wi_enumerator_dictionary_key_enumerator(wi_runtime_instance_t *instance, wi_enumerator_context_t *context) {
	_wi_dictionary_bucket_t		*bucket;
	
	bucket = _wi_enumerator_dictionary_enumerator(instance, context);
	
	if(bucket)
		return bucket->key;
	
	return NULL;
}



void * wi_enumerator_dictionary_data_enumerator(wi_runtime_instance_t *instance, wi_enumerator_context_t *context) {
	_wi_dictionary_bucket_t		*bucket;
	
	bucket = _wi_enumerator_dictionary_enumerator(instance, context);
	
	if(bucket)
		return bucket->data;
	
	return NULL;
}


#pragma mark -

wi_boolean_t wi_dictionary_write_to_file(wi_dictionary_t *dictionary, wi_string_t *path) {
#ifdef WI_PLIST
	return wi_plist_write_instance_to_file(dictionary, path);
#else
	return false;
#endif
}




#pragma mark -

static void _wi_dictionary_resize(wi_dictionary_t *dictionary) {
	_wi_dictionary_bucket_t		**buckets, *bucket, *next_bucket;
	wi_uinteger_t				i, index, capacity, buckets_count;

	capacity		= wi_exp2m1(wi_log2(dictionary->key_count) + 1);
	buckets_count	= WI_CLAMP(capacity, dictionary->min_count, _WI_DICTIONARY_MAX_COUNT);
	buckets			= wi_malloc(buckets_count * sizeof(_wi_dictionary_bucket_t *));

	for(i = 0; i < dictionary->buckets_count; i++) {
		for(bucket = dictionary->buckets[i]; bucket; bucket = next_bucket) {
			next_bucket		= bucket->next;
			index			= _WI_DICTIONARY_KEY_HASH(dictionary, bucket->key) % buckets_count;
			bucket->next	= buckets[index];
			buckets[index]	= bucket;
		}
	}

	wi_free(dictionary->buckets);

	dictionary->buckets			= buckets;
	dictionary->buckets_count	= buckets_count;
}



#pragma mark -

static _wi_dictionary_bucket_t * _wi_dictionary_bucket_create(wi_dictionary_t *dictionary) {
	_wi_dictionary_bucket_t		*bucket, *bucket_block;
	size_t						size;

	if(!dictionary->bucket_free_list) {
		if(dictionary->bucket_chunks_offset == _wi_dictionary_buckets_per_page) {
			dictionary->bucket_chunks_count++;

			size = dictionary->bucket_chunks_count * sizeof(_wi_dictionary_bucket_t *);
			dictionary->bucket_chunks = wi_realloc(dictionary->bucket_chunks, size);

			size = _wi_dictionary_buckets_per_page * sizeof(_wi_dictionary_bucket_t);
			dictionary->bucket_chunks[dictionary->bucket_chunks_count - 1] = wi_malloc(size);

			dictionary->bucket_chunks_offset = 0;
		}

		bucket_block = dictionary->bucket_chunks[dictionary->bucket_chunks_count - 1];
		dictionary->bucket_free_list = &bucket_block[dictionary->bucket_chunks_offset++];
		dictionary->bucket_free_list->link = NULL;
	}

	bucket = dictionary->bucket_free_list;
	dictionary->bucket_free_list = bucket->link;

	return bucket;
}



static _wi_dictionary_bucket_t * _wi_dictionary_bucket_for_key(wi_dictionary_t *dictionary, void *key, wi_uinteger_t index) {
	_wi_dictionary_bucket_t		*bucket;
	
	bucket = dictionary->buckets[index];

	if(!bucket)
		return NULL;

	for(; bucket; bucket = bucket->next) {
		if(_WI_DICTIONARY_KEY_IS_EQUAL(dictionary, bucket->key, key))
			return bucket;
	}
		
	return NULL;
}



static void _wi_dictionary_bucket_remove(wi_dictionary_t *dictionary, _wi_dictionary_bucket_t *bucket) {
	_WI_DICTIONARY_VALUE_RELEASE(dictionary, bucket->data);
	_WI_DICTIONARY_KEY_RELEASE(dictionary, bucket->key);
	
	bucket->link = dictionary->bucket_free_list;
	dictionary->bucket_free_list = bucket;

	dictionary->key_count--;
}



static void _wi_dictionary_set_data_for_key(wi_mutable_dictionary_t *dictionary, void *data, void *key) {
	_wi_dictionary_bucket_t		*bucket;
	void						*new_key, *new_data;
	wi_uinteger_t				index;
	
	new_key				= _WI_DICTIONARY_KEY_RETAIN(dictionary, key);
	new_data			= _WI_DICTIONARY_VALUE_RETAIN(dictionary, data);
	index				= _WI_DICTIONARY_KEY_HASH(dictionary, key) % dictionary->buckets_count;
	bucket				= _wi_dictionary_bucket_for_key(dictionary, key, index);

	if(bucket) {
		_WI_DICTIONARY_KEY_RELEASE(dictionary, bucket->key);
		_WI_DICTIONARY_VALUE_RELEASE(dictionary, bucket->data);
	} else {
		bucket			= _wi_dictionary_bucket_create(dictionary);
		bucket->next	= dictionary->buckets[index];

		dictionary->key_count++;
		dictionary->buckets[index] = bucket;
	}
	
	bucket->key			= new_key;
	bucket->data		= new_data;

	_WI_DICTIONARY_CHECK_RESIZE(dictionary);
}



static void _wi_dictionary_remove_data_for_key(wi_mutable_dictionary_t *dictionary, void *key) {
	_wi_dictionary_bucket_t		*bucket, *previous_bucket;
	wi_uinteger_t				index;

	index = _WI_DICTIONARY_KEY_HASH(dictionary, key) % dictionary->buckets_count;
	bucket = dictionary->buckets[index];

	if(bucket) {
		previous_bucket = NULL;
		
		for(; bucket; bucket = bucket->next) {
			if(_WI_DICTIONARY_KEY_IS_EQUAL(dictionary, bucket->key, key)) {
				if(bucket == dictionary->buckets[index])
					dictionary->buckets[index] = bucket->next;
				
				if(previous_bucket)
					previous_bucket->next = bucket->next;
				
				_wi_dictionary_bucket_remove(dictionary, bucket);
				break;
			}
			
			previous_bucket = bucket;
		}
	}
	
	_WI_DICTIONARY_CHECK_RESIZE(dictionary);
}



static void _wi_dictionary_remove_all_data(wi_mutable_dictionary_t *dictionary) {
	_wi_dictionary_bucket_t		*bucket;
	wi_uinteger_t				i;
	
	for(i = 0; i < dictionary->buckets_count; i++) {
		for(bucket = dictionary->buckets[i]; bucket; bucket = bucket->next)
			_wi_dictionary_bucket_remove(dictionary, bucket);

		dictionary->buckets[i] = NULL;
	}

	_WI_DICTIONARY_CHECK_RESIZE(dictionary);
}



#pragma mark -

void wi_mutable_dictionary_set_data_for_key(wi_mutable_dictionary_t *dictionary, void *data, void *key) {
	WI_RUNTIME_ASSERT_MUTABLE(dictionary);

	if(dictionary->value_callbacks.retain == wi_retain) {
		WI_ASSERT(data != NULL,
			"attempt to insert NULL data in %@",
			dictionary);
	}

	if(dictionary->key_callbacks.retain == wi_retain) {
		WI_ASSERT(key != NULL,
			"attempt to insert NULL key in %@",
			dictionary);
	}

	_wi_dictionary_set_data_for_key(dictionary, data, key);
}



void wi_mutable_dictionary_add_entries_from_dictionary(wi_mutable_dictionary_t *dictionary, wi_dictionary_t *otherdictionary) {
	_wi_dictionary_bucket_t		*bucket;
	wi_uinteger_t				i;

	WI_RUNTIME_ASSERT_MUTABLE(dictionary);

	for(i = 0; i < otherdictionary->buckets_count; i++) {
		for(bucket = otherdictionary->buckets[i]; bucket; bucket = bucket->next)
			_wi_dictionary_set_data_for_key(dictionary, bucket->data, bucket->key);
	}
}



void wi_mutable_dictionary_set_dictionary(wi_mutable_dictionary_t *dictionary, wi_dictionary_t *otherdictionary) {
	WI_RUNTIME_ASSERT_MUTABLE(dictionary);

	_wi_dictionary_remove_all_data(dictionary);
	wi_mutable_dictionary_add_entries_from_dictionary(dictionary, otherdictionary);
}



#pragma mark -

void wi_mutable_dictionary_remove_data_for_key(wi_mutable_dictionary_t *dictionary, void *key) {
	WI_RUNTIME_ASSERT_MUTABLE(dictionary);
	
	if(dictionary->key_callbacks.release == wi_release) {
		WI_ASSERT(key != NULL,
			"attempt to remove data for NULL key in %@",
			dictionary);
	}
	
	_wi_dictionary_remove_data_for_key(dictionary, key);
}



void wi_mutable_dictionary_remove_all_data(wi_mutable_dictionary_t *dictionary) {
	WI_RUNTIME_ASSERT_MUTABLE(dictionary);
	
	_wi_dictionary_remove_all_data(dictionary);
}
