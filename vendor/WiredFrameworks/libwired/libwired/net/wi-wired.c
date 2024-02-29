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

#include <stdio.h>

#include <wired/wi-array.h>
#include <wired/wi-string.h>
#include <wired/wi-system.h>
#include <wired/wi-wired.h>

#define _WI_WIRED_MESSAGE_SEPARATOR				"\4"
#define _WI_WIRED_FIELD_SEPARATOR				"\34"


void wi_parse_wire_command(wi_string_t *buffer, wi_string_t **out_command, wi_string_t **out_arguments) {
	wi_uinteger_t	index;
	
	index = wi_string_index_of_string(buffer, WI_STR(" "), 0);
	
	if(index != WI_NOT_FOUND) {
		*out_command	= wi_string_substring_to_index(buffer, index);
		*out_arguments	= wi_string_substring_from_index(buffer, index + 1);
	} else {
		*out_command	= wi_autorelease(wi_copy(buffer));
		*out_arguments	= wi_string();
	}
	
	if(wi_string_has_prefix(*out_command, WI_STR("/")))
		*out_command = wi_string_by_deleting_characters_to_index(*out_command, 1);
}



void wi_parse_wired_command(wi_string_t *buffer, wi_string_t **out_command, wi_array_t **out_arguments) {
	wi_string_t		*string, *substring;
	wi_uinteger_t	index;
	
	index = wi_string_index_of_string(buffer, WI_STR(_WI_WIRED_MESSAGE_SEPARATOR), WI_STRING_BACKWARDS);
	
	if(index != WI_NOT_FOUND)
		string = wi_string_by_deleting_characters_from_index(buffer, index);
	else
		string = wi_autorelease(wi_copy(buffer));
	
	index = wi_string_index_of_string(string, WI_STR(" "), 0);
	
	if(index != WI_NOT_FOUND) {
		*out_command	= wi_string_substring_to_index(string, index);
		substring		= wi_string_substring_from_index(string, index + 1);
		*out_arguments	= wi_string_components_separated_by_string(substring, WI_STR(_WI_WIRED_FIELD_SEPARATOR));
	} else {
		*out_command	= string;
		*out_arguments	= wi_array();
	}
}



void wi_parse_wired_message(wi_string_t *buffer, uint32_t *out_message, wi_array_t **out_arguments) {
	wi_string_t		*string, *substring;
	wi_uinteger_t	index;
	
	index = wi_string_index_of_string(buffer, WI_STR(_WI_WIRED_MESSAGE_SEPARATOR), WI_STRING_BACKWARDS);
	
	if(index != WI_NOT_FOUND)
		string = wi_string_by_deleting_characters_from_index(buffer, index);
	else
		string = wi_autorelease(wi_copy(buffer));
	
	index = wi_string_index_of_string(string, WI_STR(" "), 0);
	
	if(index != WI_NOT_FOUND) {
		substring		= wi_string_substring_to_index(string, index);
		*out_message	= wi_string_uint32(substring);
		substring		= wi_string_substring_from_index(string, index + 1);
		*out_arguments	= wi_string_components_separated_by_string(substring, WI_STR(_WI_WIRED_FIELD_SEPARATOR));
	} else {
		*out_message	= wi_string_uint32(string);
		*out_arguments	= wi_array();
	}
}
