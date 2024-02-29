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

#include "config.h"

#include <wired/wi-private.h>
#include <wired/wi-speed-calculator.h>
#include <wired/wi-system.h>

struct _wi_speed_calculator {
	wi_runtime_base_t					base;
	
	wi_uinteger_t						*bytes;
	wi_time_interval_t					*times;
	
	wi_uinteger_t						index;
	wi_uinteger_t						length;
};


static void								_wi_speed_calculator_dealloc(wi_runtime_instance_t *);

static wi_runtime_id_t					_wi_speed_calculator_runtime_id = WI_RUNTIME_ID_NULL;
static wi_runtime_class_t				_wi_speed_calculator_runtime_class = {
	"wi_speed_calculator_t",
	_wi_speed_calculator_dealloc,
	NULL,
	NULL,
	NULL,
	NULL
};



#pragma mark - Class functions

void wi_speed_calculator_register(void) {
	_wi_speed_calculator_runtime_id = wi_runtime_register_class(&_wi_speed_calculator_runtime_class);
}



void wi_speed_calculator_initialize(void) {
}



#pragma mark - Runtime functions

wi_runtime_id_t wi_speed_calculator_runtime_id(void) {
	return _wi_speed_calculator_runtime_id;
}



#pragma mark - Instance lifecycle functions

wi_speed_calculator_t * wi_speed_calculator_alloc(void) {
	return wi_runtime_create_instance(wi_speed_calculator_runtime_id(), sizeof(wi_speed_calculator_t));
}



wi_speed_calculator_t * wi_speed_calculator_init_with_capacity(wi_speed_calculator_t *speed_calculator, wi_uinteger_t capacity) {
	speed_calculator->length		= capacity;
	speed_calculator->bytes			= wi_malloc(capacity * sizeof(*speed_calculator->bytes));
	speed_calculator->times			= wi_malloc(capacity * sizeof(*speed_calculator->times));

	return speed_calculator;
}



static void _wi_speed_calculator_dealloc(wi_runtime_instance_t *instance) {
	wi_speed_calculator_t		*speed_calculator = instance;
	
	wi_free(speed_calculator->bytes);
	wi_free(speed_calculator->times);
}



#pragma mark - Core functions

void wi_speed_calculator_add_bytes_at_time(wi_speed_calculator_t *speed_calculator, wi_uinteger_t bytes, wi_time_interval_t time) {
	speed_calculator->bytes[speed_calculator->index] = bytes;
	speed_calculator->times[speed_calculator->index] = time;
	
	speed_calculator->index++;
	
	if(speed_calculator->index == speed_calculator->length)
		speed_calculator->index = 0;
}



double wi_speed_calculator_speed(wi_speed_calculator_t *speed_calculator) {
	wi_uinteger_t			i, index, bytes;
	wi_time_interval_t		time, previousTime;
	
	bytes			= 0;
	time			= 0.0;
	previousTime	= 0.0;
	
	for(i = speed_calculator->index, index = 0; index < speed_calculator->length; index++) {
		bytes += speed_calculator->bytes[i];
		
		if(speed_calculator->times[i] > 0.0 && previousTime > 0.0)
			time += speed_calculator->times[i] - previousTime;
		
		previousTime = speed_calculator->times[i];
		
		i = (i == speed_calculator->length - 1) ? 0 : i + 1;
	}
	
	return ((double) bytes / time);
}
