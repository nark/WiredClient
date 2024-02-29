/* $Id$ */

/*
 *  Copyright (c) 2007-2009 Axel Andersson
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

#ifndef WI_P7

int wi_p7_message_dummy = 0;

#else

#include <wired/wi-assert.h>
#include <wired/wi-byteorder.h>
#include <wired/wi-dictionary.h>
#include <wired/wi-libxml2.h>
#include <wired/wi-p7-message.h>
#include <wired/wi-p7-socket.h>
#include <wired/wi-p7-spec.h>
#include <wired/wi-p7-private.h>
#include <wired/wi-private.h>
#include <wired/wi-string.h>
#include <wired/wi-system.h>

#include <libxml/tree.h>
#include <libxml/parser.h>
#include <string.h>

#define _WI_P7_MESSAGE_BINARY_BUFFER_INITIAL_SIZE	8192


static void											_wi_p7_message_dealloc(wi_runtime_instance_t *);
static wi_string_t *								_wi_p7_message_description(wi_runtime_instance_t *);

static wi_string_t *								_wi_p7_message_field_string_value(wi_p7_message_t *, wi_p7_spec_field_t *);
static wi_boolean_t									_wi_p7_message_get_binary_buffer_for_reading_for_id(wi_p7_message_t *, uint32_t, unsigned char **, uint32_t *);
static wi_boolean_t									_wi_p7_message_get_binary_buffer_for_reading_for_name(wi_p7_message_t *, wi_string_t *, unsigned char **, uint32_t *);
static wi_boolean_t									_wi_p7_message_get_binary_buffer_for_writing_for_id(wi_p7_message_t *, uint32_t, uint32_t, unsigned char **);
static wi_boolean_t									_wi_p7_message_get_binary_buffer_for_writing_for_name(wi_p7_message_t *, wi_string_t *, uint32_t, unsigned char **, uint32_t *);


wi_boolean_t										wi_p7_message_debug;

static wi_runtime_id_t								_wi_p7_message_runtime_id = WI_RUNTIME_ID_NULL;
static wi_runtime_class_t							_wi_p7_message_runtime_class = {
    "wi_p7_message_t",
    _wi_p7_message_dealloc,
    NULL,
    NULL,
    _wi_p7_message_description,
    NULL
};



void wi_p7_message_register(void) {
    _wi_p7_message_runtime_id = wi_runtime_register_class(&_wi_p7_message_runtime_class);
}



void wi_p7_message_initialize(void) {
}



#pragma mark -

wi_runtime_id_t wi_p7_message_runtime_id(void) {
    return _wi_p7_message_runtime_id;
}



#pragma mark -

wi_p7_message_t * wi_p7_message_with_name(wi_string_t *message_name, wi_p7_spec_t *p7_spec) {
	return wi_autorelease(wi_p7_message_init_with_name(wi_p7_message_alloc(), message_name, p7_spec));
}



wi_p7_message_t * wi_p7_message_with_data(wi_data_t *data, wi_p7_serialization_t serialization, wi_p7_spec_t *p7_spec) {
	return wi_autorelease(wi_p7_message_init_with_data(wi_p7_message_alloc(), data, serialization, p7_spec));
}



wi_p7_message_t * wi_p7_message_with_bytes(const void *bytes, wi_uinteger_t length, wi_p7_serialization_t serialization, wi_p7_spec_t *p7_spec) {
	return wi_autorelease(wi_p7_message_init_with_bytes(wi_p7_message_alloc(), bytes, length, serialization, p7_spec));
}



#pragma mark -

wi_p7_message_t * wi_p7_message_alloc(void) {
    return wi_runtime_create_instance(_wi_p7_message_runtime_id, sizeof(wi_p7_message_t));
}



wi_p7_message_t * wi_p7_message_init(wi_p7_message_t *p7_message, wi_p7_spec_t *p7_spec) {
	p7_message->spec = wi_retain(p7_spec);

	return p7_message;
}



wi_p7_message_t * wi_p7_message_init_with_name(wi_p7_message_t *p7_message, wi_string_t *message_name, wi_p7_spec_t *p7_spec) {
	p7_message->spec			= wi_retain(p7_spec);
	p7_message->binary_capacity	= _WI_P7_MESSAGE_BINARY_BUFFER_INITIAL_SIZE;
	p7_message->binary_buffer	= wi_malloc(p7_message->binary_capacity);
	p7_message->binary_size		= WI_P7_MESSAGE_BINARY_HEADER_SIZE;
	
	if(!wi_p7_message_set_name(p7_message, message_name)) {
		wi_release(p7_message);
		
		return NULL;
	}
	
	return p7_message;
}



wi_p7_message_t * wi_p7_message_init_with_data(wi_p7_message_t *p7_message, wi_data_t *data, wi_p7_serialization_t serialization, wi_p7_spec_t *p7_spec) {
	return wi_p7_message_init_with_bytes(p7_message, wi_data_bytes(data), wi_data_length(data), serialization, p7_spec);
}



wi_p7_message_t * wi_p7_message_init_with_bytes(wi_p7_message_t *p7_message, const void *bytes, wi_uinteger_t length, wi_p7_serialization_t serialization, wi_p7_spec_t *p7_spec) {
	p7_message->spec			= wi_retain(p7_spec);

	p7_message->binary_size		= length;
	p7_message->binary_capacity	= p7_message->binary_size;
	p7_message->binary_buffer	= wi_malloc(p7_message->binary_capacity);
	
	memcpy(p7_message->binary_buffer, bytes, p7_message->binary_size);
	
	wi_p7_message_deserialize(p7_message, WI_P7_BINARY);
	
	if(!p7_message->name) {
		wi_error_set_libwired_error(WI_ERROR_P7_UNKNOWNMESSAGE);
		
		wi_release(p7_message);
		
		return NULL;
	}

	return p7_message;
}



static void _wi_p7_message_dealloc(wi_runtime_instance_t *instance) {
	wi_p7_message_t		*p7_message = instance;
	
	wi_release(p7_message->spec);
	wi_release(p7_message->name);
	
	if(p7_message->binary_buffer)
		wi_free(p7_message->binary_buffer);

	if(p7_message->xml_buffer)
		xmlFree(p7_message->xml_buffer);
	
	wi_release(p7_message->xml_string);
}



static wi_string_t * _wi_p7_message_description(wi_runtime_instance_t *instance) {
	wi_p7_message_t			*p7_message = instance;
	wi_enumerator_t			*enumerator;
	wi_dictionary_t			*fields;
	wi_mutable_string_t		*string;
	wi_string_t				*field_name, *field_value;
	
	string = wi_mutable_string_with_format(WI_STR("<%@ %p>{name = %@, buffer = %@, fields = (\n"),
        wi_runtime_class_name(p7_message),
        p7_message,
		p7_message->name,
		wi_data_with_bytes_no_copy(p7_message->binary_buffer, p7_message->binary_size, false));
	
	fields		= wi_p7_message_fields(p7_message);
	enumerator	= wi_dictionary_key_enumerator(fields);
	
	while((field_name = wi_enumerator_next_data(enumerator))) {
		field_value = wi_dictionary_data_for_key(fields, field_name);

		wi_mutable_string_append_format(string, WI_STR("    %@ = %@\n"),
			field_name, field_value);
	}
	
	wi_mutable_string_append_string(string, WI_STR(")}"));
	
	wi_runtime_make_immutable(string);
	
	return string;
}



#pragma mark -

static wi_string_t * _wi_p7_message_field_string_value(wi_p7_message_t *p7_message, wi_p7_spec_field_t *field) {
	wi_string_t				*field_name, *field_value = NULL;
	wi_uuid_t				*uuid;
	wi_date_t				*date;
	wi_p7_boolean_t			p7_bool;
	wi_p7_enum_t			p7_enum;
	wi_p7_int32_t			p7_int32;
	wi_p7_uint32_t			p7_uint32;
	wi_p7_int64_t			p7_int64;
	wi_p7_uint64_t			p7_uint64;
	wi_p7_double_t			p7_double;
	wi_p7_oobdata_t			p7_oobdata;
	wi_string_t				*string;
	wi_data_t				*data;
	wi_array_t				*list;
	
	field_name = wi_p7_spec_field_name(field);
	
	switch(wi_p7_spec_type_id(wi_p7_spec_field_type(field))) {
		case WI_P7_BOOL:
			if(wi_p7_message_get_bool_for_name(p7_message, &p7_bool, field_name))
				field_value = wi_string_with_format(WI_STR("%@"), p7_bool ? WI_STR("true") : WI_STR("false"));
			break;
			
		case WI_P7_ENUM:
			if(wi_p7_message_get_enum_for_name(p7_message, &p7_enum, field_name))
				field_value = wi_dictionary_data_for_key(wi_p7_spec_field_enums_by_value(field), (void *) (intptr_t) p7_enum);
			break;
			
		case WI_P7_INT32:
			if(wi_p7_message_get_int32_for_name(p7_message, &p7_int32, field_name))
				field_value = wi_string_with_format(WI_STR("%d"), p7_int32);
			break;
			
		case WI_P7_UINT32:
			if(wi_p7_message_get_uint32_for_name(p7_message, &p7_uint32, field_name))
				field_value = wi_string_with_format(WI_STR("%u"), p7_uint32);
			break;
			
		case WI_P7_INT64:
			if(wi_p7_message_get_int64_for_name(p7_message, &p7_int64, field_name))
				field_value = wi_string_with_format(WI_STR("%lld"), p7_int64);
			break;
			
		case WI_P7_UINT64:
			if(wi_p7_message_get_uint64_for_name(p7_message, &p7_uint64, field_name))
				field_value = wi_string_with_format(WI_STR("%llu"), p7_uint64);
			break;
			
		case WI_P7_DOUBLE:
			if(wi_p7_message_get_double_for_name(p7_message, &p7_double, field_name))
				field_value = wi_string_with_format(WI_STR("%0.16f"), p7_double);
			break;
			
		case WI_P7_STRING:
			string = wi_p7_message_string_for_name(p7_message, field_name);
			
			if(string)
				field_value = wi_string_with_format(WI_STR("\"%@\""), string);
			break;
		
		case WI_P7_UUID:
			uuid = wi_p7_message_uuid_for_name(p7_message, field_name);
			
			if(uuid)
				field_value = wi_string_with_format(WI_STR("%@"), wi_uuid_string(uuid));
			break;
		
		case WI_P7_DATE:
			date = wi_p7_message_date_for_name(p7_message, field_name);
			
			if(date)
				field_value = wi_string_with_format(WI_STR("%@"), wi_date_string_with_format(date, WI_STR("%Y-%m-%d %H:%M:%S %z")));
			break;
			
		case WI_P7_DATA:
			data = wi_p7_message_data_for_name(p7_message, field_name);
			
			if(data)
				field_value = wi_string_with_format(WI_STR("%@"), data);
			break;
			
		case WI_P7_OOBDATA:
			if(wi_p7_message_get_oobdata_for_name(p7_message, &p7_oobdata, field_name))
				field_value = wi_string_with_format(WI_STR("%llu"), p7_oobdata);
			break;
		
		case WI_P7_LIST:
			list = wi_p7_message_list_for_name(p7_message, field_name);
			
			if(list)
				field_value = wi_array_components_joined_by_string(list, WI_STR(", "));
			break;
	}
	
	return field_value;
}



static wi_boolean_t _wi_p7_message_get_binary_buffer_for_reading_for_id(wi_p7_message_t *p7_message, uint32_t in_field_id, unsigned char **out_buffer, uint32_t *out_field_size) {
	wi_p7_spec_field_t		*field;
	unsigned char			*buffer, *start;
	uint32_t				message_size, field_id, field_size;
	
	message_size = p7_message->binary_size - WI_P7_MESSAGE_BINARY_HEADER_SIZE;
	buffer = start = p7_message->binary_buffer + WI_P7_MESSAGE_BINARY_HEADER_SIZE;
	
	while((uint32_t) (buffer - start) < message_size) {
		field_id	= wi_read_swap_big_to_host_int32(buffer, 0);
		field		= wi_p7_spec_field_with_id(p7_message->spec, field_id);
		
		if(!field) {
			wi_error_set_libwired_error_with_format(WI_ERROR_P7_UNKNOWNFIELD,
				WI_STR("No field found for ID %u"), field_id);
			
			if(wi_p7_message_debug)
				wi_log_debug(WI_STR("_wi_p7_message_get_binary_buffer_for_reading_for_id: %m"));
			
			break;
		}
		
		if((uint32_t) (buffer - start) + message_size < sizeof(field_id))
			break;

		buffer		+= sizeof(field_id);
		field_size	= wi_p7_spec_field_size(field);
	
		if(field_size == 0) {
			field_size = wi_read_swap_big_to_host_int32(buffer, 0);
			
			if((uint32_t) (buffer - start) + message_size < sizeof(field_size))
				break;
			
			buffer += sizeof(field_size);
		}
		
		if(field_id == in_field_id) {
			if(out_buffer)
				*out_buffer = buffer;
			
			if(out_field_size)
				*out_field_size = field_size;
			
			return true;
		}
		
		if((uint32_t) (buffer - start) + message_size < field_size)
			break;
		
		buffer += field_size;
	}
	
	return false;
}



static wi_boolean_t _wi_p7_message_get_binary_buffer_for_reading_for_name(wi_p7_message_t *p7_message, wi_string_t *field_name, unsigned char **out_buffer, uint32_t *out_field_size) {
	wi_p7_spec_field_t	*field;
	uint32_t			field_id;
	
	field = wi_p7_spec_field_with_name(p7_message->spec, field_name);
	
	if(!field) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_UNKNOWNFIELD,
			WI_STR("No id found for field \"%@\""), field_name);

		if(wi_p7_message_debug)
			wi_log_debug(WI_STR("_wi_p7_message_get_binary_buffer_for_reading_for_name: %m"));
		
		return false;
	}
	
	field_id = wi_p7_spec_field_id(field);

	return _wi_p7_message_get_binary_buffer_for_reading_for_id(p7_message, field_id, out_buffer, out_field_size);
}



static wi_boolean_t _wi_p7_message_get_binary_buffer_for_writing_for_id(wi_p7_message_t *p7_message, uint32_t field_id, uint32_t length, unsigned char **out_buffer) {
	wi_p7_spec_field_t	*field;
	uint32_t			field_size, new_size;
	
	new_size	= sizeof(field_id);
	field		= wi_p7_spec_field_with_id(p7_message->spec, field_id);
	field_size	= wi_p7_spec_field_size(field);
	
	if(field_size == 0) {
		field_size = length;
		new_size += sizeof(uint32_t);
	}
	
	new_size += field_size;
	
	if(_wi_p7_message_get_binary_buffer_for_reading_for_id(p7_message, field_id, NULL, NULL))
		return false;
	
	if(p7_message->binary_size + new_size > p7_message->binary_capacity) {
		p7_message->binary_capacity	= p7_message->binary_size + new_size;
		p7_message->binary_buffer	= wi_realloc(p7_message->binary_buffer, p7_message->binary_capacity);
	}

	if(out_buffer)
		*out_buffer = p7_message->binary_buffer + p7_message->binary_size;
	
	p7_message->binary_size += new_size;
	
	return true;
}



static wi_boolean_t _wi_p7_message_get_binary_buffer_for_writing_for_name(wi_p7_message_t *p7_message, wi_string_t *field_name, uint32_t length, unsigned char **out_buffer, uint32_t *out_field_id) {
	wi_p7_spec_field_t	*field;
	uint32_t			field_id;
	
	field = wi_p7_spec_field_with_name(p7_message->spec, field_name);

	if(!field) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_UNKNOWNFIELD,
			WI_STR("No id found for field \"%@\""), field_name);
		
		if(wi_p7_message_debug)
			wi_log_debug(WI_STR("_wi_p7_message_get_binary_buffer_for_writing_for_name: %m"));
		
		return false;
	}
	
	field_id = wi_p7_spec_field_id(field);
	
	if(out_field_id)
		*out_field_id = field_id;

	return _wi_p7_message_get_binary_buffer_for_writing_for_id(p7_message, field_id, length, out_buffer);
}



#pragma mark -

void wi_p7_message_serialize(wi_p7_message_t *p7_message, wi_p7_serialization_t serialization) {
	xmlDocPtr				doc;
	xmlNsPtr				ns;
	xmlNodePtr				root_node, list_node, item_node;
	wi_p7_spec_field_t		*field;
	wi_p7_spec_type_t		*type;
	wi_runtime_instance_t	*instance;
	wi_string_t				*field_name, *field_value;
	unsigned char			*buffer, *start;
	wi_uuid_t				*uuid;
	wi_date_t				*date;
	wi_p7_boolean_t			p7_bool;
	wi_p7_int32_t			p7_int32;
	wi_p7_uint32_t			p7_uint32;
	wi_p7_int64_t			p7_int64;
	wi_p7_uint64_t			p7_uint64;
	wi_p7_double_t			p7_double;
	wi_p7_oobdata_t			p7_oobdata;
	wi_string_t				*string;
	wi_data_t				*data;
	wi_array_t				*list;
	wi_uinteger_t			i, count;
	uint32_t				message_size, field_id, field_size;
	
	if(serialization == WI_P7_XML && !p7_message->xml_buffer) {
		doc			= xmlNewDoc((xmlChar *) "1.0");
		root_node	= xmlNewNode(NULL, (xmlChar *) "message");
		
		xmlDocSetRootElement(doc, root_node);
		
		ns = xmlNewNs(root_node, (xmlChar *) "http://www.zankasoftware.com/P7/Message", (xmlChar *) "p7");
		xmlSetNs(root_node, ns);
		
		xmlSetProp(root_node, (xmlChar *) "name", (xmlChar *) wi_string_cstring(p7_message->name));
		
		message_size = p7_message->binary_size - WI_P7_MESSAGE_BINARY_HEADER_SIZE;
		buffer = start = p7_message->binary_buffer + WI_P7_MESSAGE_BINARY_HEADER_SIZE;
		
		while((uint32_t) (buffer - start) < message_size) {
			field_id		= wi_read_swap_big_to_host_int32(buffer, 0);
			buffer			+= sizeof(field_id);
			field			= wi_p7_spec_field_with_id(p7_message->spec, field_id);

			if(!field)
				continue;
			
			field_size		= wi_p7_spec_field_size(field);
			
			if(field_size == 0) {
				field_size = wi_read_swap_big_to_host_int32(buffer, 0);
				
				buffer += sizeof(field_size);
			}
			
			field_name		= wi_p7_spec_field_name(field);
			field_value		= NULL;
			type			= wi_p7_spec_field_type(field);

			switch(wi_p7_spec_type_id(type)) {
				case WI_P7_BOOL:
					if(wi_p7_message_get_bool_for_name(p7_message, &p7_bool, field_name))
						field_value = wi_string_with_format(WI_STR("%u"), p7_bool ? 1 : 0);
					break;
					
				case WI_P7_ENUM:
					string = wi_p7_message_enum_name_for_name(p7_message, field_name);
					
					if(string)
						field_value = string;
					break;
					
				case WI_P7_INT32:
					if(wi_p7_message_get_int32_for_name(p7_message, &p7_int32, field_name))
						field_value = wi_string_with_format(WI_STR("%u"), p7_int32);
					break;
					
				case WI_P7_UINT32:
					if(wi_p7_message_get_uint32_for_name(p7_message, &p7_uint32, field_name))
						field_value = wi_string_with_format(WI_STR("%u"), p7_uint32);
					break;
					
				case WI_P7_INT64:
					if(wi_p7_message_get_int64_for_name(p7_message, &p7_int64, field_name))
						field_value = wi_string_with_format(WI_STR("%lld"), p7_int64);
					break;
					
				case WI_P7_UINT64:
					if(wi_p7_message_get_uint64_for_name(p7_message, &p7_uint64, field_name))
						field_value = wi_string_with_format(WI_STR("%llu"), p7_uint64);
					break;
					
				case WI_P7_DOUBLE:
					if(wi_p7_message_get_double_for_name(p7_message, &p7_double, field_name))
						field_value = wi_string_with_format(WI_STR("%f"), p7_double);
					break;
					
				case WI_P7_STRING:
					string = wi_p7_message_string_for_name(p7_message, field_name);
					
					if(string)
						field_value = string;
					break;
					
				case WI_P7_UUID:
					uuid = wi_p7_message_uuid_for_name(p7_message, field_name);
					
					if(uuid)
						field_value = wi_uuid_string(uuid);
					break;
					
				case WI_P7_DATE:
					date = wi_p7_message_date_for_name(p7_message, field_name);
					
					if(date)
						field_value = wi_string_with_format(WI_STR("%f"), wi_date_time_interval(date));
					break;
					
				case WI_P7_DATA:
					data = wi_p7_message_data_for_name(p7_message, field_name);
					
					if(data)
						field_value = wi_data_base64(data);
					break;
					
				case WI_P7_OOBDATA:
					if(wi_p7_message_get_oobdata_for_name(p7_message, &p7_oobdata, field_name))
						field_value = wi_string_with_format(WI_STR("%llu"), p7_oobdata);
					break;
					
				case WI_P7_LIST:
					list = wi_p7_message_list_for_name(p7_message, field_name);
					
					if(list) {
						list_node = wi_xml_node_child_with_name(root_node, field_name);
						
						if(!list_node) {
							list_node = xmlNewNode(ns, (xmlChar *) "field");
							xmlSetProp(list_node, (xmlChar *) "name", (xmlChar *) wi_string_cstring(field_name));
							xmlAddChild(root_node, list_node);
						}
						
						count = wi_array_count(list);
						
						for(i = 0; i < count; i++) {
							item_node = xmlNewNode(ns, (xmlChar *) "item");
							instance = WI_ARRAY(list, i);

							if(wi_runtime_id(instance) == wi_string_runtime_id())
								xmlNodeSetContent(item_node, (xmlChar *) wi_string_cstring(instance));
							
							xmlAddChild(list_node, item_node);
						}
					}
					break;
			}
			
			if(field_value) {
				item_node = wi_xml_node_child_with_name(root_node, field_name);
				
				if(!item_node) {
					item_node = xmlNewNode(ns, (xmlChar *) "field");
					xmlSetProp(item_node, (xmlChar *) "name", (xmlChar *) wi_string_cstring(field_name));
					xmlAddChild(root_node, item_node);
				}
				
				xmlNodeSetContent(item_node, (xmlChar *) wi_string_cstring(field_value));

			}
			
			buffer += field_size;
		}
		
		xmlDocDumpMemoryEnc(doc, &p7_message->xml_buffer, &p7_message->xml_length, "UTF-8");
		xmlFreeDoc(doc);
	}
}



void wi_p7_message_deserialize(wi_p7_message_t *p7_message, wi_p7_serialization_t serialization) {
	xmlDocPtr					doc;
	xmlNodePtr					root_node, field_node;
	wi_string_t					*field_name, *field_value;
	wi_p7_spec_message_t		*message;
	wi_p7_spec_field_t			*field;
	wi_uuid_t					*uuid;
	wi_date_t					*date;
	wi_data_t					*data;
	
	if(serialization == WI_P7_BINARY) {
		p7_message->binary_id = wi_read_swap_big_to_host_int32(p7_message->binary_buffer, 0);
		
		message = wi_p7_spec_message_with_id(p7_message->spec, p7_message->binary_id);
		
		if(message)
			p7_message->name = wi_retain(wi_p7_spec_message_name(message));
	} else {
		p7_message->binary_capacity	= _WI_P7_MESSAGE_BINARY_BUFFER_INITIAL_SIZE;
		p7_message->binary_buffer	= wi_malloc(p7_message->binary_capacity);
		p7_message->binary_size		= WI_P7_MESSAGE_BINARY_HEADER_SIZE;
		
		doc							= xmlParseDoc((xmlChar *) wi_string_cstring(p7_message->xml_string));
		root_node					= xmlDocGetRootElement(doc);
		
		if(root_node) {
			wi_p7_message_set_name(p7_message, wi_xml_node_attribute_with_name(root_node, WI_STR("name")));
			
			for(field_node = root_node->children; field_node != NULL; field_node = field_node->next) {
				if(field_node->type == XML_ELEMENT_NODE) {
					if(wi_is_equal(wi_xml_node_name(field_node), WI_STR("field"))) {
						field_name		= wi_xml_node_attribute_with_name(field_node, WI_STR("name"));
						field_value		= wi_xml_node_content(field_node);
						field			= wi_p7_spec_field_with_name(p7_message->spec, field_name);
						
						if(!field_name || !field_value || !field)
							continue;
						
						switch(wi_p7_spec_type_id(wi_p7_spec_field_type(field))) {
							case WI_P7_BOOL:
								wi_p7_message_set_bool_for_name(p7_message, wi_string_bool(field_value), field_name);
								break;
								
							case WI_P7_ENUM:
								wi_p7_message_set_enum_for_name(p7_message, wi_string_uint32(field_value), field_name);
								break;
								
							case WI_P7_INT32:
								wi_p7_message_set_int32_for_name(p7_message, wi_string_int32(field_value), field_name);
								break;
								
							case WI_P7_UINT32:
								wi_p7_message_set_uint32_for_name(p7_message, wi_string_uint32(field_value), field_name);
								break;
								
							case WI_P7_INT64:
								wi_p7_message_set_int64_for_name(p7_message, wi_string_int64(field_value), field_name);
								break;
								
							case WI_P7_UINT64:
								wi_p7_message_set_uint64_for_name(p7_message, wi_string_uint64(field_value), field_name);
								break;
								
							case WI_P7_DOUBLE:
								wi_p7_message_set_double_for_name(p7_message, wi_string_double(field_value), field_name);
								break;
								
							case WI_P7_STRING:
								wi_p7_message_set_string_for_name(p7_message, field_value, field_name);
								break;
								
							case WI_P7_UUID:
								uuid = wi_uuid_with_string(field_value);

								if(uuid)
									wi_p7_message_set_uuid_for_name(p7_message, uuid, field_name);
								break;
								
							case WI_P7_DATE:
								date = wi_date_with_rfc3339_string(field_value);
								
								if(date)
									wi_p7_message_set_date_for_name(p7_message, date, field_name);
								break;
								
							case WI_P7_DATA:
								data = wi_autorelease(wi_data_init_with_base64(wi_data_alloc(), field_value));
								
								if(data)
									wi_p7_message_set_data_for_name(p7_message, data, field_name);
								break;
							
							case WI_P7_OOBDATA:
								wi_p7_message_set_oobdata_for_name(p7_message, wi_string_uint64(field_value), field_name);
								break;
							
							case WI_P7_LIST:
								WI_ASSERT(0, "Can't deserialize XML with lists at the moment");
								break;
						}
					}
				}
			}
		}
		
		xmlFreeDoc(doc);
	}
}



#pragma mark -

wi_boolean_t wi_p7_message_set_name(wi_p7_message_t *p7_message, wi_string_t *name) {
	wi_p7_spec_message_t		*message;
	
	message = wi_p7_spec_message_with_name(p7_message->spec, name);

	if(!message) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_UNKNOWNMESSAGE,
			WI_STR("No id found for message \"%@\""), name);
		
		if(wi_p7_message_debug)
			wi_log_debug(WI_STR("wi_p7_message_set_name: %m"));

		return false;
	}
	
	p7_message->binary_id = wi_p7_spec_message_id(message);
	
	wi_write_swap_host_to_big_int32(p7_message->binary_buffer, 0, p7_message->binary_id);
	
	wi_retain(name);
	wi_release(p7_message->name);
	
	p7_message->name = name;
	
	return true;
}



wi_string_t * wi_p7_message_name(wi_p7_message_t *p7_message) {
	return p7_message->name;
}



#pragma mark -

wi_dictionary_t * wi_p7_message_fields(wi_p7_message_t *p7_message) {
	wi_p7_spec_field_t			*field;
	wi_mutable_dictionary_t		*fields;
	wi_string_t					*field_name, *field_value;
	unsigned char				*buffer, *start;
	uint32_t					message_size, field_id, field_size;
	
	fields = wi_dictionary_init(wi_mutable_dictionary_alloc());

	message_size = p7_message->binary_size - WI_P7_MESSAGE_BINARY_HEADER_SIZE;
	buffer = start = p7_message->binary_buffer + WI_P7_MESSAGE_BINARY_HEADER_SIZE;
	
	while((uint32_t) (buffer - start) < message_size) {
		field_id	= wi_read_swap_big_to_host_int32(buffer, 0);
		buffer		+= sizeof(field_id);
		field		= wi_p7_spec_field_with_id(p7_message->spec, field_id);

		if(!field)
			continue;
		
		field_size	= wi_p7_spec_field_size(field);
		
		if(field_size == 0) {
			field_size = wi_read_swap_big_to_host_int32(buffer, 0);
			
			buffer += sizeof(field_size);
		}
		
		field_name		= wi_p7_spec_field_name(field);
		field_value		= _wi_p7_message_field_string_value(p7_message, field);
		
		if(!field_name)
			field_name = WI_STR("<unknown field>");
		
		if(!field_value)
			field_value = WI_STR("<unknown value>");

		wi_mutable_dictionary_set_data_for_key(fields, field_value, field_name);

		buffer += field_size;
	}
	
	return wi_autorelease(fields);
}



wi_data_t * wi_p7_message_data_with_serialization(wi_p7_message_t *p7_message, wi_p7_serialization_t serialization) {
	wi_p7_message_serialize(p7_message, serialization);
	
	if(serialization == WI_P7_BINARY)
		return wi_data_with_bytes(p7_message->binary_buffer, p7_message->binary_size);
	else
		return wi_data_with_bytes(p7_message->xml_buffer, p7_message->xml_length);
}



#pragma mark -

wi_boolean_t wi_p7_message_set_bool_for_name(wi_p7_message_t *p7_message, wi_p7_boolean_t value, wi_string_t *field_name) {
	unsigned char	*binary;
	uint32_t		field_id;

	if(!_wi_p7_message_get_binary_buffer_for_writing_for_name(p7_message, field_name, 0, &binary, &field_id))
		return false;
	
	wi_write_swap_host_to_big_int32(binary, 0, field_id);
	
	binary[4] = value ? 1 : 0;
	
	return true;
}



wi_boolean_t wi_p7_message_get_bool_for_name(wi_p7_message_t *p7_message, wi_p7_boolean_t *value, wi_string_t *field_name) {
	unsigned char	*binary;
	
	if(!_wi_p7_message_get_binary_buffer_for_reading_for_name(p7_message, field_name, &binary, NULL))
		return false;
	
	*value = (binary[0] == 1) ? true : false;
	
	return true;
}



wi_boolean_t wi_p7_message_set_enum_for_name(wi_p7_message_t *p7_message, wi_p7_enum_t value, wi_string_t *field_name) {
	return wi_p7_message_set_uint32_for_name(p7_message, (wi_p7_uint32_t) value, field_name);
}



wi_boolean_t wi_p7_message_get_enum_for_name(wi_p7_message_t *p7_message, wi_p7_enum_t *value, wi_string_t *field_name) {
	wi_p7_uint32_t	p7_uint32;
	
	if(!wi_p7_message_get_uint32_for_name(p7_message, &p7_uint32, field_name))
		return false;
	
	*value = (wi_p7_enum_t) p7_uint32;
	
	return true;
}



wi_boolean_t wi_p7_message_set_int32_for_name(wi_p7_message_t *p7_message, wi_p7_int32_t value, wi_string_t *field_name) {
	unsigned char	*binary;
	uint32_t		field_id;

	if(!_wi_p7_message_get_binary_buffer_for_writing_for_name(p7_message, field_name, 0, &binary, &field_id))
		return false;
	
	wi_write_swap_host_to_big_int32(binary, 0, field_id);
	wi_write_swap_host_to_big_int32(binary, 4, value);
	
	return true;
}



wi_boolean_t wi_p7_message_get_int32_for_name(wi_p7_message_t *p7_message, wi_p7_int32_t *value, wi_string_t *field_name) {
	unsigned char	*binary;
	
	if(!_wi_p7_message_get_binary_buffer_for_reading_for_name(p7_message, field_name, &binary, NULL))
		return false;
	
	*value = wi_read_swap_big_to_host_int32(binary, 0);
	
	return true;
}



wi_boolean_t wi_p7_message_set_uint32_for_name(wi_p7_message_t *p7_message, wi_p7_uint32_t value, wi_string_t *field_name) {
	return wi_p7_message_set_int32_for_name(p7_message, (wi_p7_int32_t) value, field_name);
}



wi_boolean_t wi_p7_message_get_uint32_for_name(wi_p7_message_t *p7_message, wi_p7_uint32_t *value, wi_string_t *field_name) {
	wi_p7_int32_t	p7_int32;
	
	if(!wi_p7_message_get_int32_for_name(p7_message, &p7_int32, field_name))
		return false;
	
	*value = (wi_p7_uint32_t) p7_int32;
	
	return true;
}



wi_boolean_t wi_p7_message_set_int64_for_name(wi_p7_message_t *p7_message, wi_p7_int64_t value, wi_string_t *field_name) {
	unsigned char	*binary;
	uint32_t		field_id;

	if(!_wi_p7_message_get_binary_buffer_for_writing_for_name(p7_message, field_name, 0, &binary, &field_id))
		return false;
	
	wi_write_swap_host_to_big_int32(binary, 0, field_id);
	wi_write_swap_host_to_big_int64(binary, 4, value);
	
	return true;
}



wi_boolean_t wi_p7_message_get_int64_for_name(wi_p7_message_t *p7_message, wi_p7_int64_t *value, wi_string_t *field_name) {
	unsigned char	*binary;
	
	if(!_wi_p7_message_get_binary_buffer_for_reading_for_name(p7_message, field_name, &binary, NULL))
		return false;
	
	*value = wi_read_swap_big_to_host_int64(binary, 0);
	
	return true;
}



wi_boolean_t wi_p7_message_set_uint64_for_name(wi_p7_message_t *p7_message, wi_p7_uint64_t value, wi_string_t *field_name) {
	return wi_p7_message_set_int64_for_name(p7_message, (wi_p7_int64_t) value, field_name);
}



wi_boolean_t wi_p7_message_get_uint64_for_name(wi_p7_message_t *p7_message, wi_p7_uint64_t *value, wi_string_t *field_name) {
	wi_p7_int64_t	p7_int64;
	
	if(!wi_p7_message_get_int64_for_name(p7_message, &p7_int64, field_name))
		return false;
	
	*value = (wi_p7_uint64_t) p7_int64;
	
	return true;
}



wi_boolean_t wi_p7_message_set_double_for_name(wi_p7_message_t *p7_message, wi_p7_double_t value, wi_string_t *field_name) {
	unsigned char	*binary;
	uint32_t		field_id;

	if(!_wi_p7_message_get_binary_buffer_for_writing_for_name(p7_message, field_name, 0, &binary, &field_id))
		return false;
	
	wi_write_swap_host_to_big_int32(binary, 0, field_id);
	wi_write_double_to_ieee754(binary, 4, value);

	return true;
}



wi_boolean_t wi_p7_message_get_double_for_name(wi_p7_message_t *p7_message, wi_p7_double_t *value, wi_string_t *field_name) {
	unsigned char	*binary;
	
	if(!_wi_p7_message_get_binary_buffer_for_reading_for_name(p7_message, field_name, &binary, NULL))
		return false;
	
	*value = wi_read_double_from_ieee754(binary, 0);
	
	return true;
}



wi_boolean_t wi_p7_message_set_oobdata_for_name(wi_p7_message_t *p7_message, wi_p7_oobdata_t value, wi_string_t *field_name) {
	unsigned char	*binary;
	uint32_t		field_id;

	if(!_wi_p7_message_get_binary_buffer_for_writing_for_name(p7_message, field_name, 0, &binary, &field_id))
		return false;
	
	wi_write_swap_host_to_big_int32(binary, 0, field_id);
	wi_write_swap_host_to_big_int64(binary, 4, value);
	
	return true;
}



wi_boolean_t wi_p7_message_get_oobdata_for_name(wi_p7_message_t *p7_message, wi_p7_oobdata_t *value, wi_string_t *field_name) {
	unsigned char	*binary;
	
	if(!_wi_p7_message_get_binary_buffer_for_reading_for_name(p7_message, field_name, &binary, NULL))
		return false;
	
	*value = wi_read_swap_big_to_host_int64(binary, 0);
	
	return true;
}



#pragma mark -

wi_boolean_t wi_p7_message_set_string_for_name(wi_p7_message_t *p7_message, wi_string_t *string, wi_string_t *field_name) {
	unsigned char	*binary;
	uint32_t		field_size, field_id;
	
	if(!string)
		string = WI_STR("");
	
	field_size = wi_string_length(string) + 1;
	
	if(!_wi_p7_message_get_binary_buffer_for_writing_for_name(p7_message, field_name, field_size, &binary, &field_id))
		return false;
	
	wi_write_swap_host_to_big_int32(binary, 0, field_id);
	wi_write_swap_host_to_big_int32(binary, 4, field_size);
	
	memcpy(binary + 8, wi_string_cstring(string), field_size);
	
	return true;
}



wi_string_t * wi_p7_message_string_for_name(wi_p7_message_t *p7_message, wi_string_t *field_name) {
	unsigned char	*binary;
	uint32_t		field_size;
	
	if(!_wi_p7_message_get_binary_buffer_for_reading_for_name(p7_message, field_name, &binary, &field_size))
		return NULL;
	
	return wi_string_with_bytes(binary, field_size - 1);
}



wi_boolean_t wi_p7_message_set_data_for_name(wi_p7_message_t *p7_message, wi_data_t *data, wi_string_t *field_name) {
	unsigned char	*binary;
	uint32_t		field_size, field_id;
	
	if(!data)
		data = wi_data();
	
	field_size = wi_data_length(data);
	
	if(!_wi_p7_message_get_binary_buffer_for_writing_for_name(p7_message, field_name, field_size, &binary, &field_id))
		return false;
	
	wi_write_swap_host_to_big_int32(binary, 0, field_id);
	wi_write_swap_host_to_big_int32(binary, 4, field_size);
	
	memcpy(binary + 8, wi_data_bytes(data), field_size);
	
	return true;
}



wi_data_t * wi_p7_message_data_for_name(wi_p7_message_t *p7_message, wi_string_t *field_name) {
	unsigned char	*binary;
	uint32_t		field_size;
	
	if(!_wi_p7_message_get_binary_buffer_for_reading_for_name(p7_message, field_name, &binary, &field_size))
		return NULL;
	
	return wi_data_with_bytes(binary, field_size);
}



wi_boolean_t wi_p7_message_set_number_for_name(wi_p7_message_t *p7_message, wi_number_t *number, wi_string_t *field_name) {
	wi_p7_spec_field_t		*field;
	wi_p7_spec_type_t		*type;
	
	if(!number)
		number = wi_number_with_int32(0);
	
	field = wi_p7_spec_field_with_name(p7_message->spec, field_name);
	
	if(!field) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_UNKNOWNFIELD,
			WI_STR("No id found for field \"%@\""), field_name);
		
		return false;
	}
	
	type = wi_p7_spec_field_type(field);
	
	if(!type) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_UNKNOWNFIELD,
			WI_STR("No type found for field \"%@\""), field_name);
		
		return false;
	}
	
	switch(wi_p7_spec_type_id(type)) {
		case WI_P7_BOOL:
			return wi_p7_message_set_bool_for_name(p7_message, wi_number_bool(number), field_name);
			break;
			
		case WI_P7_ENUM:
			return wi_p7_message_set_enum_for_name(p7_message, wi_number_int32(number), field_name);
			break;
			
		case WI_P7_INT32:
			return wi_p7_message_set_int32_for_name(p7_message, wi_number_int32(number), field_name);
			break;
			
		case WI_P7_UINT32:
			return wi_p7_message_set_uint32_for_name(p7_message, wi_number_int32(number), field_name);
			break;
			
		case WI_P7_INT64:
			return wi_p7_message_set_int64_for_name(p7_message, wi_number_int64(number), field_name);
			break;
			
		case WI_P7_UINT64:
			return wi_p7_message_set_uint64_for_name(p7_message, wi_number_int64(number), field_name);
			break;
			
		case WI_P7_DOUBLE:
			return wi_p7_message_set_double_for_name(p7_message, wi_number_double(number), field_name);
			break;
			
		default:
			wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDARGUMENT,
				WI_STR("Field \"%@\" is not a number"), field_name);
			break;
	}

	return false;
}



wi_number_t * wi_p7_message_number_for_name(wi_p7_message_t *p7_message, wi_string_t *field_name) {
	wi_p7_spec_field_t		*field;
	wi_p7_spec_type_t		*type;
	wi_p7_boolean_t			p7_bool;
	wi_p7_enum_t			p7_enum;
	wi_p7_int32_t			p7_int32;
	wi_p7_uint32_t			p7_uint32;
	wi_p7_int64_t			p7_int64;
	wi_p7_uint64_t			p7_uint64;
	wi_p7_double_t			p7_double;
	
	field = wi_p7_spec_field_with_name(p7_message->spec, field_name);
	
	if(!field) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_UNKNOWNFIELD,
			WI_STR("No id found for field \"%@\""), field_name);
		
		return NULL;
	}
	
	type = wi_p7_spec_field_type(field);
	
	if(!type) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_UNKNOWNFIELD,
			WI_STR("No type found for field \"%@\""), field_name);
		
		return NULL;
	}
	
	switch(wi_p7_spec_type_id(type)) {
		case WI_P7_BOOL:
			if(wi_p7_message_get_bool_for_name(p7_message, &p7_bool, field_name))
				return wi_number_with_bool(p7_bool);
			break;
		
		case WI_P7_ENUM:
			if(wi_p7_message_get_enum_for_name(p7_message, &p7_enum, field_name))
				return wi_number_with_int32(p7_enum);
			break;
			
		case WI_P7_INT32:
			if(wi_p7_message_get_int32_for_name(p7_message, &p7_int32, field_name))
				return wi_number_with_int32(p7_int32);
			break;
		
		case WI_P7_UINT32:
			if(wi_p7_message_get_uint32_for_name(p7_message, &p7_uint32, field_name))
				return wi_number_with_int32(p7_uint32);
			break;
		
		case WI_P7_INT64:
			if(wi_p7_message_get_int64_for_name(p7_message, &p7_int64, field_name))
				return wi_number_with_int64(p7_int64);
			break;
		
		case WI_P7_UINT64:
			if(wi_p7_message_get_uint64_for_name(p7_message, &p7_uint64, field_name))
				return wi_number_with_int64(p7_uint64);
			break;
		
		case WI_P7_DOUBLE:
			if(wi_p7_message_get_double_for_name(p7_message, &p7_double, field_name))
				return wi_number_with_double(p7_double);
			break;
		
		default:
			wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDARGUMENT,
				WI_STR("Field \"%@\" is not a number"), field_name);
			break;
	}
	
	return NULL;
}



wi_boolean_t wi_p7_message_set_enum_name_for_name(wi_p7_message_t *p7_message, wi_string_t *enum_name, wi_string_t *field_name) {
	wi_p7_spec_field_t	*field;
	wi_dictionary_t		*enums;
	wi_p7_enum_t		enum_value;
	
	field = wi_p7_spec_field_with_name(p7_message->spec, field_name);
	
	if(!field) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_UNKNOWNFIELD,
			WI_STR("No id found for field \"%@\""), field_name);
		
		if(wi_p7_message_debug)
			wi_log_debug(WI_STR("wi_p7_message_set_enum_name_for_name: %m"));
		
		return false;
	}
	
	enums = wi_p7_spec_field_enums_by_name(field);
	
	if(!wi_dictionary_contains_key(enums, enum_name)) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_UNKNOWNFIELD,
			WI_STR("No value found for enum \"%@\""), enum_name);
		
		if(wi_p7_message_debug)
			wi_log_debug(WI_STR("wi_p7_message_set_enum_name_for_name: %m"));
		
		return false;
	}
	
	enum_value = (wi_p7_enum_t) (intptr_t) wi_dictionary_data_for_key(enums, enum_name);
	
	return wi_p7_message_set_enum_for_name(p7_message, enum_value, field_name);
}



wi_string_t * wi_p7_message_enum_name_for_name(wi_p7_message_t *p7_message, wi_string_t *field_name) {
	wi_p7_spec_field_t	*field;
	wi_dictionary_t		*enums;
	wi_p7_enum_t		enum_value;
	
	if(!wi_p7_message_get_enum_for_name(p7_message, &enum_value, field_name))
		return NULL;
	
	field = wi_p7_spec_field_with_name(p7_message->spec, field_name);
	enums = wi_p7_spec_field_enums_by_value(field);
	
	if(!wi_dictionary_contains_key(enums, (void *) (intptr_t) enum_value)) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_UNKNOWNFIELD,
			WI_STR("No name found for enum \"%u\""), enum_value);
		
		if(wi_p7_message_debug)
			wi_log_debug(WI_STR("wi_p7_message_enum_name_for_name: %m"));
		
		return NULL;
	}
	
	return wi_dictionary_data_for_key(enums, (void *) (intptr_t) enum_value);
}



wi_boolean_t wi_p7_message_set_uuid_for_name(wi_p7_message_t *p7_message, wi_uuid_t *uuid, wi_string_t *field_name) {
	unsigned char	*binary;
	uint32_t		field_id;
	
	if(!uuid)
		return false;
	
	if(!_wi_p7_message_get_binary_buffer_for_writing_for_name(p7_message, field_name, 0, &binary, &field_id))
		return false;
	
	wi_write_swap_host_to_big_int32(binary, 0, field_id);
	
	wi_uuid_get_bytes(uuid, binary + 4);
	
	return true;
}



wi_uuid_t * wi_p7_message_uuid_for_name(wi_p7_message_t *p7_message, wi_string_t *field_name) {
	unsigned char	*binary;
	
	if(!_wi_p7_message_get_binary_buffer_for_reading_for_name(p7_message, field_name, &binary, NULL))
		return false;
	
	return wi_uuid_with_bytes(binary);
	
	return NULL;
}



wi_boolean_t wi_p7_message_set_date_for_name(wi_p7_message_t *p7_message, wi_date_t *date, wi_string_t *field_name) {
	wi_time_interval_t	interval;
	
	if(!date)
		date = wi_date();
	
	interval = wi_date_time_interval(date);
	
	return wi_p7_message_set_double_for_name(p7_message, interval, field_name);
}



wi_date_t * wi_p7_message_date_for_name(wi_p7_message_t *p7_message, wi_string_t *field_name) {
	wi_time_interval_t	interval;
	
	if(!wi_p7_message_get_double_for_name(p7_message, &interval, field_name))
		return NULL;
	
	return wi_date_with_time_interval(interval);
}



wi_boolean_t wi_p7_message_set_list_for_name(wi_p7_message_t *p7_message, wi_array_t *list, wi_string_t *field_name) {
	wi_runtime_instance_t	*instance;
	unsigned char			*binary;
	wi_runtime_id_t			first_id, id;
	wi_uinteger_t			i, count, offset;
	uint32_t				field_id, field_size, string_size;
	
	count = wi_array_count(list);
	field_size = 0;
	
	if(count > 0) {
		first_id = wi_runtime_id(wi_array_first_data(list));
	
		for(i = 0; i < count; i++) {
			instance = WI_ARRAY(list, i);
			id = wi_runtime_id(instance);
			
			if(id != first_id) {
				wi_error_set_libwired_error_with_format(WI_ERROR_P7_UNKNOWNFIELD,
					WI_STR("Mixed types in list"));
				
				return false;
			}
			
			if(id == wi_string_runtime_id()) {
				field_size += 4 + wi_string_length(instance) + 1;
			} else {
				wi_error_set_libwired_error_with_format(WI_ERROR_P7_UNKNOWNFIELD,
					WI_STR("Unhandled type %@ in list"), wi_runtime_class_name(instance));
				
				return false;
			}
		}
	}
	
	if(!_wi_p7_message_get_binary_buffer_for_writing_for_name(p7_message, field_name, field_size, &binary, &field_id))
		return false;
	
	wi_write_swap_host_to_big_int32(binary, 0, field_id);
	wi_write_swap_host_to_big_int32(binary, 4, field_size);
	
	offset = 8;
	
	for(i = 0; i < count; i++) {
		instance = WI_ARRAY(list, i);
		
		if(wi_runtime_id(instance) == wi_string_runtime_id()) {
			string_size = wi_string_length(instance) + 1;
			
			wi_write_swap_host_to_big_int32(binary, offset, string_size);
			
			offset += 4;
			
			memcpy(binary + offset, wi_string_cstring(instance), string_size);
			
			offset += string_size;
		}
	}

	return true;
}



wi_array_t * wi_p7_message_list_for_name(wi_p7_message_t *p7_message, wi_string_t *field_name) {
	wi_p7_spec_field_t		*field;
	wi_p7_spec_type_t		*listtype;
	wi_array_t				*list;
	wi_runtime_instance_t	*instance;
	unsigned char			*binary;
	wi_p7_type_t			listtype_id;
	uint32_t				field_size, list_size, string_size;
	
	field = wi_p7_spec_field_with_name(p7_message->spec, field_name);
	
	if(!field) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_UNKNOWNFIELD,
			WI_STR("No id found for field \"%@\""), field_name);
		
		if(wi_p7_message_debug)
			wi_log_debug(WI_STR("wi_p7_message_list_for_name: %m"));
		
		return NULL;
	}
	
	listtype		= wi_p7_spec_field_listtype(field);
	listtype_id		= wi_p7_spec_type_id(listtype);

	if(listtype_id != WI_P7_STRING) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_UNKNOWNFIELD,
			WI_STR("Unhandled type %@ in list"), wi_p7_spec_type_name(listtype));
		
		if(wi_p7_message_debug)
			wi_log_debug(WI_STR("wi_p7_message_list_for_name: %m"));
		
		return NULL;
	}
	
	list = wi_mutable_array();
		
	if(!_wi_p7_message_get_binary_buffer_for_reading_for_name(p7_message, field_name, &binary, &field_size))
		return NULL;
	
	list_size = 0;
	
	while(list_size < field_size) {
		if(listtype_id == WI_P7_STRING) {
			string_size = wi_read_swap_big_to_host_int32(binary, list_size);
			
			list_size += 4;
			
			instance = wi_string_with_bytes(binary + list_size, string_size - 1);
			
			list_size += string_size;
		}
		
		wi_mutable_array_add_data(list, instance);
	}
	
	wi_runtime_make_immutable(list);
	
	return list;
}



#pragma mark -

wi_boolean_t wi_p7_message_write_binary(wi_p7_message_t *p7_message, const void *buffer, uint32_t field_size, wi_uinteger_t field_id) {
	wi_p7_spec_field_t	*field;
	unsigned char		*binary;
	
	if(!_wi_p7_message_get_binary_buffer_for_writing_for_id(p7_message, field_id, field_size, &binary))
		return false;

	wi_write_swap_host_to_big_int32(binary, 0, field_id);
	
	field = wi_p7_spec_field_with_id(p7_message->spec, field_id);

	if(wi_p7_spec_field_size(field) > 0) {
		memcpy(binary + 4, buffer, field_size);
	} else {
		wi_write_swap_host_to_big_int32(binary, 4, field_size);
		
		memcpy(binary + 8, buffer, field_size);
	}

	return true;
}



wi_boolean_t wi_p7_message_read_binary(wi_p7_message_t *p7_message, unsigned char **buffer, uint32_t *field_size, wi_uinteger_t field_id) {
	return _wi_p7_message_get_binary_buffer_for_reading_for_id(p7_message, field_id, buffer, field_size);
}

#endif
