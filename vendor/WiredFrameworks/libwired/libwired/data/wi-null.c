/* $Id$ */

/*
 *  Copyright (c) 2009 Axel Andersson
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

#include <wired/wi-null.h>
#include <wired/wi-private.h>

struct _wi_null {
	wi_runtime_base_t					base;
};


static wi_runtime_instance_t *			_wi_null_copy(wi_runtime_instance_t *);


static wi_null_t						*_wi_null;

static wi_runtime_id_t					_wi_null_runtime_id = WI_RUNTIME_ID_NULL;
static wi_runtime_class_t				_wi_null_runtime_class = {
	"wi_null_t",
	NULL,
	_wi_null_copy,
	NULL,
	NULL,
	NULL
};



void wi_null_register(void) {
	_wi_null_runtime_id = wi_runtime_register_class(&_wi_null_runtime_class);
}



void wi_null_initialize(void) {
	_wi_null = wi_runtime_create_instance(_wi_null_runtime_id, sizeof(wi_null_t));
}



#pragma mark -

wi_runtime_id_t wi_null_runtime_id(void) {
	return _wi_null_runtime_id;
}



#pragma mark -

wi_runtime_instance_t * wi_null(void) {
	return _wi_null;
}



#pragma mark -

static wi_runtime_instance_t * _wi_null_copy(wi_runtime_instance_t *instance) {
	return wi_retain(_wi_null);
}
