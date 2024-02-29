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
#include <unistd.h>
#include <string.h>

#include <wired/wi-assert.h>
#include <wired/wi-file.h>
#include <wired/wi-lock.h>
#include <wired/wi-private.h>
#include <wired/wi-runtime.h>
#include <wired/wi-socket.h>
#include <wired/wi-string.h>
#include <wired/wi-system.h>

#define _WI_RUNTIME_RELEASED_MAGIC		0xDEADC0DE
#define _WI_RUNTIME_CLASS_TABLE_SIZE	512

#define _WI_RUNTIME_ASSERT_MAGIC(instance)										\
	WI_STMT_START																\
		if(WI_RUNTIME_BASE((instance))->magic != WI_RUNTIME_MAGIC)				\
			_wi_runtime_invalid_abort((instance));								\
	WI_STMT_END

#define _WI_RUNTIME_ASSERT_ZOMBIE(instance)										\
	WI_STMT_START																\
		if(WI_RUNTIME_BASE((instance))->options & WI_RUNTIME_OPTION_ZOMBIE)		\
			_wi_runtime_zombie_abort((instance));								\
	WI_STMT_END


static void								_wi_runtime_null_abort(wi_runtime_instance_t *);
static void								_wi_runtime_zombie_abort(wi_runtime_instance_t *);
static void								_wi_runtime_invalid_abort(wi_runtime_instance_t *);


static wi_boolean_t						_wi_zombie_enabled = false;

static wi_runtime_class_t				*_wi_runtime_class_table[_WI_RUNTIME_CLASS_TABLE_SIZE];
static wi_uinteger_t					_wi_runtime_class_table_count = 0;

static wi_recursive_lock_t				*_wi_runtime_retain_count_lock;

static wi_runtime_id_t					_wi_runtime_null_id = WI_RUNTIME_ID_NULL;
static wi_runtime_class_t				_wi_runtime_null_class = {
	"wi_runtime_null_class",
	(void *) _wi_runtime_null_abort,
	(void *) _wi_runtime_null_abort,
	(void *) _wi_runtime_null_abort,
	(void *) _wi_runtime_null_abort,
	(void *) _wi_runtime_null_abort
};



void wi_runtime_register(void) {
	_wi_runtime_null_id = wi_runtime_register_class(&_wi_runtime_null_class);
}



void wi_runtime_initialize(void) {
	char	*env;
	
	_wi_runtime_retain_count_lock = wi_recursive_lock_init(wi_recursive_lock_alloc());
	
	env = getenv("wi_zombie_enabled");
	
	if(env) {
		_wi_zombie_enabled = (strcmp(env, "0") != 0);
		
		printf("*** wi_runtime_initialize(): wi_zombie_enabled = %u\n", _wi_zombie_enabled);
	}
}



#pragma mark -

wi_runtime_id_t wi_runtime_register_class(wi_runtime_class_t *class) {
	_wi_runtime_class_table[_wi_runtime_class_table_count++] = class;
	
	return _wi_runtime_class_table_count - 1;
}



wi_runtime_instance_t * wi_runtime_create_instance(wi_runtime_id_t id, size_t size) {
	return wi_runtime_create_instance_with_options(id, size, 0);
}



wi_runtime_instance_t * wi_runtime_create_instance_with_options(wi_runtime_id_t id, size_t size, uint8_t options) {
	wi_runtime_instance_t	*instance;
	
    /**** This is absolutely INSANE, this code should not be commented !!!
     * NOTE: This is currently due to a bug in the wi_speed_calculator class registration onto the runtime
     
        WI_ASSERT(id > 0 && id < _wi_runtime_class_table_count,
            "attempting to allocate unregistered class id %u", id);	
     */

	instance = wi_malloc(size);
	
	WI_RUNTIME_BASE(instance)->magic = WI_RUNTIME_MAGIC;
	WI_RUNTIME_BASE(instance)->id = id;
	WI_RUNTIME_BASE(instance)->retain_count = 1;
	WI_RUNTIME_BASE(instance)->options = options;
	
	return instance;
}



#pragma mark -

wi_runtime_class_t * wi_runtime_class_with_name(wi_string_t *name) {
	wi_runtime_class_t	*class;
	const char			*cname;
	wi_uinteger_t		i;
	
	cname = wi_string_cstring(name);
	
	for(i = 0; i < _wi_runtime_class_table_count; i++) {
		class = _wi_runtime_class_table[i];
		
		if(strcmp(class->name, cname) == 0)
			return class;
	}
	
	return NULL;
}



wi_runtime_class_t * wi_runtime_class_with_id(wi_runtime_id_t id) {
	if(id < _wi_runtime_class_table_count)
		return _wi_runtime_class_table[id];
	
	return NULL;
}



wi_runtime_id_t wi_runtime_id_for_class(wi_runtime_class_t *class) {
	wi_uinteger_t		i;
	
	for(i = 0; i < _wi_runtime_class_table_count; i++) {
		if(_wi_runtime_class_table[i] == class)
			return i;
	}
	
	return WI_RUNTIME_ID_NULL;
}



#pragma mark -

wi_runtime_class_t * wi_runtime_class(wi_runtime_instance_t *instance) {
	if(WI_RUNTIME_BASE(instance)->magic == WI_RUNTIME_MAGIC)
		return _wi_runtime_class_table[WI_RUNTIME_BASE(instance)->id];
	
	return NULL;
}



wi_string_t * wi_runtime_class_name(wi_runtime_instance_t *instance) {
	wi_runtime_class_t		*class;
	
	class = wi_runtime_class(instance);
	
	if(class)
		return wi_string_with_cstring(class->name);
	
	return NULL;
}



wi_runtime_id_t wi_runtime_id(wi_runtime_instance_t *instance) {
	if(WI_RUNTIME_BASE(instance)->magic == WI_RUNTIME_MAGIC)
		return WI_RUNTIME_BASE(instance)->id;
	
	return WI_RUNTIME_ID_NULL;
}



uint8_t wi_runtime_options(wi_runtime_instance_t *instance) {
	return WI_RUNTIME_BASE(instance)->options;
}



#pragma mark -

void wi_runtime_make_immutable(wi_runtime_instance_t *instance) {
	if(instance && WI_RUNTIME_BASE(instance)->options & WI_RUNTIME_OPTION_MUTABLE) {
		WI_RUNTIME_BASE(instance)->options &= ~WI_RUNTIME_OPTION_MUTABLE;
		WI_RUNTIME_BASE(instance)->options |= WI_RUNTIME_OPTION_IMMUTABLE;
	}
}



#pragma mark -

static void _wi_runtime_null_abort(wi_runtime_instance_t *instance) {
	WI_ASSERT(0, "%p has no associated class", instance);
}



static void _wi_runtime_zombie_abort(wi_runtime_instance_t *instance) {
	wi_pool_t		*pool;
	
	pool = wi_pool_init(wi_pool_alloc());
	WI_ASSERT(0, "%p %@ is a deallocated instance", instance, instance);
	wi_release(pool);
}



static void _wi_runtime_invalid_abort(wi_runtime_instance_t *instance) {
	WI_ASSERT(0, "%p is not a valid instance: magic=0x%x, id=%u",
		instance, WI_RUNTIME_BASE(instance)->magic, WI_RUNTIME_BASE(instance)->id);
}



#pragma mark -

wi_runtime_instance_t * wi_retain(wi_runtime_instance_t *instance) {
	if(!instance)
		return NULL;

	_WI_RUNTIME_ASSERT_MAGIC(instance);
	_WI_RUNTIME_ASSERT_ZOMBIE(instance);

	wi_recursive_lock_lock(_wi_runtime_retain_count_lock);
	
	WI_RUNTIME_BASE(instance)->retain_count++;
	
	wi_recursive_lock_unlock(_wi_runtime_retain_count_lock);
	
	return instance;
}



uint16_t wi_retain_count(wi_runtime_instance_t *instance) {
	if(!instance)
		return 0;

	_WI_RUNTIME_ASSERT_MAGIC(instance);
	_WI_RUNTIME_ASSERT_ZOMBIE(instance);
	
	return WI_RUNTIME_BASE(instance)->retain_count;
}



void wi_release(wi_runtime_instance_t *instance) {
	wi_runtime_class_t		*class;
	
	if(!instance)
		return;
	
	_WI_RUNTIME_ASSERT_MAGIC(instance);
	_WI_RUNTIME_ASSERT_ZOMBIE(instance);
	
	wi_recursive_lock_lock(_wi_runtime_retain_count_lock);
	
	if(--WI_RUNTIME_BASE(instance)->retain_count == 0) {
		if(_wi_zombie_enabled && WI_RUNTIME_BASE(instance)->id != wi_pool_runtime_id()) {
			WI_RUNTIME_BASE(instance)->retain_count++;

			if(WI_RUNTIME_BASE(instance)->id == wi_file_runtime_id())
				wi_file_close((wi_file_t *) instance);
			else if(WI_RUNTIME_BASE(instance)->id == wi_socket_runtime_id())
				wi_socket_close((wi_socket_t *) instance);

			WI_RUNTIME_BASE(instance)->options |= WI_RUNTIME_OPTION_ZOMBIE;
			
			wi_recursive_lock_unlock(_wi_runtime_retain_count_lock);
		} else {
			wi_recursive_lock_unlock(_wi_runtime_retain_count_lock);
			
			class = _wi_runtime_class_table[WI_RUNTIME_BASE(instance)->id];
			
			if(class->dealloc)
				class->dealloc(instance);

			WI_RUNTIME_BASE(instance)->magic = _WI_RUNTIME_RELEASED_MAGIC;
			
			wi_free((void *) instance);
		}
	} else {
		wi_recursive_lock_unlock(_wi_runtime_retain_count_lock);
	}
}



#pragma mark -

wi_runtime_instance_t * wi_copy(wi_runtime_instance_t *instance) {
	wi_runtime_class_t		*class;
	
	if(!instance)
		return NULL;
	
	_WI_RUNTIME_ASSERT_MAGIC(instance);
	_WI_RUNTIME_ASSERT_ZOMBIE(instance);
	
	if(WI_RUNTIME_BASE(instance)->options & WI_RUNTIME_OPTION_IMMUTABLE)
		return wi_retain(instance);

	class = _wi_runtime_class_table[WI_RUNTIME_BASE(instance)->id];
	
	if(class->copy)
		return class->copy(instance);
	
	WI_ASSERT(0, "%@ does not implement wi_copy()", instance);

	return NULL;
}



wi_runtime_instance_t * wi_mutable_copy(wi_runtime_instance_t *instance) {
	wi_runtime_class_t		*class;
	wi_runtime_instance_t	*copy;

	if(!instance)
		return NULL;

	_WI_RUNTIME_ASSERT_MAGIC(instance);
	_WI_RUNTIME_ASSERT_ZOMBIE(instance);

	WI_ASSERT(WI_RUNTIME_BASE(instance)->options & WI_RUNTIME_OPTION_IMMUTABLE ||
			  WI_RUNTIME_BASE(instance)->options & WI_RUNTIME_OPTION_MUTABLE,
			  "%@ does not implement wi_mutable_copy()",
			  instance);

	class = _wi_runtime_class_table[WI_RUNTIME_BASE(instance)->id];

	if(class->copy) {
		copy = class->copy(instance);

		WI_RUNTIME_BASE(copy)->options &= ~WI_RUNTIME_OPTION_IMMUTABLE;
		WI_RUNTIME_BASE(copy)->options |= WI_RUNTIME_OPTION_MUTABLE;

		return copy;
	}

	WI_ASSERT(0, "%@ does not implement wi_copy()", instance);

	return NULL;
}



wi_boolean_t wi_is_equal(wi_runtime_instance_t *instance1, wi_runtime_instance_t *instance2) {
	wi_runtime_class_t		*class1, *class2;

	if(instance1 == instance2)
		return true;
	
	if(!instance1 || !instance2)
		return false;

	_WI_RUNTIME_ASSERT_MAGIC(instance1);
	_WI_RUNTIME_ASSERT_MAGIC(instance2);
	_WI_RUNTIME_ASSERT_ZOMBIE(instance1);
	_WI_RUNTIME_ASSERT_ZOMBIE(instance2);
	
	class1 = _wi_runtime_class_table[WI_RUNTIME_BASE(instance1)->id];
	class2 = _wi_runtime_class_table[WI_RUNTIME_BASE(instance2)->id];

	if(class1 != class2)
		return false;

	if(class1->is_equal)
		return class1->is_equal(instance1, instance2);
	
	return false;
}



wi_string_t * wi_description(wi_runtime_instance_t *instance) {
	wi_runtime_class_t		*class;
	
	if(!instance)
		return NULL;
	
	_WI_RUNTIME_ASSERT_MAGIC(instance);
	
	class = _wi_runtime_class_table[WI_RUNTIME_BASE(instance)->id];

	if(class->description)
		return class->description(instance);

	return wi_string_with_format(WI_STR("<%s %p>"), class->name, instance);
}



wi_hash_code_t wi_hash(wi_runtime_instance_t *instance) {
	wi_runtime_class_t		*class;
	
	if(!instance)
		return 0;
	
	_WI_RUNTIME_ASSERT_MAGIC(instance);
	_WI_RUNTIME_ASSERT_ZOMBIE(instance);
	 
	class = _wi_runtime_class_table[WI_RUNTIME_BASE(instance)->id];
	
	if(class->hash)
		return class->hash(instance);
	
	return wi_hash_pointer(instance);
}



#pragma mark -

void wi_show(wi_runtime_instance_t *instance) {
	wi_pool_t		*pool;
	wi_boolean_t	value;
	
	pool = wi_pool_init(wi_pool_alloc());
	value = wi_log_stdout;
	wi_log_stdout = true;
	wi_log_info(WI_STR("%@"), instance);
	wi_log_stdout = value;
	wi_release(pool);
}
