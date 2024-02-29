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

#include "config.h"

#ifndef WI_PLIST

int wi_plist_dummy = 0;

#else

#include <string.h>

#include <wired/wi-data.h>
#include <wired/wi-date.h>
#include <wired/wi-dictionary.h>
#include <wired/wi-libxml2.h>
#include <wired/wi-macros.h>
#include <wired/wi-number.h>
#include <wired/wi-plist.h>
#include <wired/wi-private.h>
#include <wired/wi-runtime.h>
#include <wired/wi-string.h>

#include <libxml/tree.h>
#include <libxml/parser.h>
#include <libxml/xmlerror.h>
#include <libxml/xpath.h>

static wi_runtime_instance_t *			_wi_plist_instance_for_document(xmlDocPtr);
static wi_runtime_instance_t *			_wi_plist_instance_for_node(xmlNodePtr);
static wi_boolean_t						_wi_plist_read_node_to_instance(xmlNodePtr, wi_runtime_instance_t *);
static wi_boolean_t						_wi_plist_write_instance_to_node(wi_runtime_instance_t *, xmlNodePtr);


wi_runtime_instance_t * wi_plist_read_instance_from_file(wi_string_t *path) {
	wi_runtime_instance_t	*instance;
	xmlDocPtr				doc;
	
	doc = xmlReadFile(wi_string_cstring(path), NULL, 0);
	
	if(!doc) {
		wi_error_set_libxml2_error();
		
		return NULL;
	}
	
	instance = _wi_plist_instance_for_document(doc);
	
	xmlFreeDoc(doc);
	
	return instance;
}



wi_runtime_instance_t * wi_plist_instance_for_string(wi_string_t *string) {
	wi_runtime_instance_t	*instance;
	xmlDocPtr				doc;
	
	doc = xmlReadMemory(wi_string_cstring(string), wi_string_length(string), NULL, NULL, 0);
	
	if(!doc) {
		wi_error_set_libxml2_error();
		
		return NULL;
	}
	
	instance = _wi_plist_instance_for_document(doc);
	
	xmlFreeDoc(doc);
	
	return instance;
}



#pragma mark -

wi_boolean_t wi_plist_write_instance_to_file(wi_runtime_instance_t *instance, wi_string_t *path) {
	wi_string_t		*string;
	
	string = wi_plist_string_for_instance(instance);
	
	if(!string)
		return false;
	
	return wi_string_write_to_file(string, path);
}



wi_string_t * wi_plist_string_for_instance(wi_runtime_instance_t *instance) {
	wi_string_t			*string = NULL;
	xmlDocPtr			doc;
	xmlDtdPtr			dtd;
	xmlNodePtr			root_node;
	xmlChar				*buffer;
	int					length;

	doc = xmlNewDoc((xmlChar *) "1.0");

	dtd = xmlNewDtd(doc, (xmlChar *) "plist", (xmlChar *) "-//Apple//DTD PLIST 1.0//EN", (xmlChar *) "http://www.apple.com/DTDs/PropertyList-1.0.dtd");
	xmlAddChild((xmlNodePtr) doc, (xmlNodePtr) dtd);
	
	root_node = xmlNewNode(NULL, (xmlChar *) "plist");
	xmlSetProp(root_node, (xmlChar *) "version", (xmlChar *) "1.0");
	xmlDocSetRootElement(doc, root_node);
	
	if(_wi_plist_write_instance_to_node(instance, root_node)) {
		xmlDocDumpFormatMemoryEnc(doc, &buffer, &length, "UTF-8", 1);
	
		string = wi_string_with_bytes(buffer, length);
		
		xmlFree(buffer);
	}
	
	xmlFreeDoc(doc);
	
	return string;
}



#pragma mark -

static wi_runtime_instance_t * _wi_plist_instance_for_document(xmlDocPtr doc) {
	wi_runtime_instance_t	*instance;
	wi_string_t				*version;
	xmlNodePtr				root_node, content_node = NULL, node;
	
	root_node = xmlDocGetRootElement(doc);
	
	if(!wi_is_equal(wi_xml_node_name(root_node), WI_STR("plist"))) {
		wi_error_set_libwired_error_with_format(WI_ERROR_PLIST_READFAILED,
			WI_STR("Root node \"%@\" is not equal to \"plist\""),
			wi_xml_node_name(root_node));
		
		return NULL;
	}
	
	version = wi_xml_node_attribute_with_name(root_node, WI_STR("version"));
	
	if(!version) {
		wi_error_set_libwired_error_with_format(WI_ERROR_PLIST_READFAILED,
			WI_STR("No version attribute on \"plist\""));
		
		return NULL;
	}
	
	if(!wi_is_equal(version, WI_STR("1.0"))) {
		wi_error_set_libwired_error_with_format(WI_ERROR_PLIST_READFAILED,
			WI_STR("Unhandled version \"%@\""), version);
		
		return NULL;
	}
	
	for(node = root_node->children; node != NULL; node = node->next) {
		if(node->type == XML_ELEMENT_NODE) {
			content_node = node;
			
			break;
		}
	}
	
	if(!content_node) {
		wi_error_set_libwired_error_with_format(WI_ERROR_PLIST_READFAILED,
			WI_STR("No content"));
		
		return NULL;
	}
	
	instance = _wi_plist_instance_for_node(content_node);
	
	if(!_wi_plist_read_node_to_instance(content_node, instance))
		return NULL;
	
	return instance;
}



static wi_runtime_instance_t * _wi_plist_instance_for_node(xmlNodePtr node) {
	wi_string_t		*name;
	
	name = wi_xml_node_name(node);

	if(wi_is_equal(name, WI_STR("dict")))
		return wi_mutable_dictionary();
	else if(wi_is_equal(name, WI_STR("array")))
		return wi_mutable_array();

	wi_error_set_libwired_error_with_format(WI_ERROR_PLIST_READFAILED,
		WI_STR("Content \"%@\" is not \"dict\" or \"array\""), name);
	
	return NULL;
}



static wi_boolean_t _wi_plist_read_node_to_instance(xmlNodePtr content_node, wi_runtime_instance_t *collection) {
	xmlNodePtr				node;
	wi_string_t				*key = NULL;
	wi_runtime_instance_t	*instance = NULL;
	wi_boolean_t			dictionary;
	
	dictionary = (wi_runtime_id(collection) == wi_dictionary_runtime_id());
	
	for(node = content_node->children; node != NULL; node = node->next) {
		if(node->type == XML_ELEMENT_NODE) {
			if(strcmp((const char *) node->name, "key") == 0)
				key = wi_xml_node_content(node);
			else if(strcmp((const char *) node->name, "string") == 0)
				instance = wi_xml_node_content(node);
			else if(strcmp((const char *) node->name, "integer") == 0)
				instance = wi_number_with_integer(wi_string_integer(wi_xml_node_content(node)));
			else if(strcmp((const char *) node->name, "real") == 0)
				instance = wi_number_with_double(wi_string_double(wi_xml_node_content(node)));
			else if(strcmp((const char *) node->name, "true") == 0)
				instance = wi_number_with_bool(true);
			else if(strcmp((const char *) node->name, "false") == 0)
				instance = wi_number_with_bool(false);
			else if(strcmp((const char *) node->name, "date") == 0)
				instance = wi_date_with_rfc3339_string(wi_xml_node_content(node));
			else if(strcmp((const char *) node->name, "data") == 0)
				instance = wi_data_with_base64(wi_xml_node_content(node));
			else if(strcmp((const char *) node->name, "dict") == 0) {
				instance = wi_mutable_dictionary();
				
				if(!_wi_plist_read_node_to_instance(node, instance))
					return false;
			}
			else if(strcmp((const char *) node->name, "array") == 0) {
				instance = wi_mutable_array();
				
				if(!_wi_plist_read_node_to_instance(node, instance))
					return false;
			}
			else {
				wi_error_set_libwired_error_with_format(WI_ERROR_PLIST_READFAILED,
					WI_STR("Unhandled node \"%s\""), node->name);
				
				return false;
			}
		}
			
		if(instance) {
			if(dictionary)
				wi_mutable_dictionary_set_data_for_key(collection, instance, key);
			else
				wi_mutable_array_add_data(collection, instance);
			
			instance = NULL;
			key = NULL;
		}
	}
	
	return true;
}



static wi_boolean_t _wi_plist_write_instance_to_node(wi_runtime_instance_t *instance, xmlNodePtr node) {
	wi_enumerator_t			*enumerator;
	wi_mutable_array_t		*keys;
	wi_runtime_instance_t	*value;
	xmlNodePtr				child_node;
	void					*key;
	wi_runtime_id_t			id;
	wi_number_type_t		type;
	wi_uinteger_t			i, count;
	
	id = wi_runtime_id(instance);
	
	if(id == wi_string_runtime_id()) {
		wi_xml_node_new_child(node, WI_STR("string"), instance);
	}
	else if(id == wi_number_runtime_id()) {
		type = wi_number_type(instance);
		
		if(type == WI_NUMBER_BOOL) {
			if(wi_number_bool(instance))
				wi_xml_node_new_child(node, WI_STR("true"), NULL);
			else
				wi_xml_node_new_child(node, WI_STR("false"), NULL);
		} else {
			if(type == WI_NUMBER_FLOAT || type == WI_NUMBER_DOUBLE)
				wi_xml_node_new_child(node, WI_STR("real"), wi_number_string(instance));
			else
				wi_xml_node_new_child(node, WI_STR("integer"), wi_number_string(instance));
		}
	}
	else if(id == wi_data_runtime_id()) {
		wi_xml_node_new_child(node, WI_STR("data"), wi_data_base64(instance));
	}
	else if(id == wi_date_runtime_id()) {
		wi_xml_node_new_child(node, WI_STR("date"), wi_date_string_with_format(instance, WI_STR("%Y-%m-%dT%H:%M:%SZ")));
	}
	else if(id == wi_dictionary_runtime_id()) {
		child_node = wi_xml_node_new_child(node, WI_STR("dict"), NULL);
		
		keys = wi_mutable_array();
		
		enumerator = wi_dictionary_key_enumerator(instance);
		
		while((key = wi_enumerator_next_data(enumerator)))
			wi_mutable_array_add_data_sorted(keys, key, wi_string_compare);
		
		count = wi_array_count(keys);
		
		for(i = 0; i < count; i++) {
			key		= WI_ARRAY(keys, i);
			value	= wi_dictionary_data_for_key(instance, key);
			
			wi_xml_node_new_child(child_node, WI_STR("key"), key);
			
			if(!_wi_plist_write_instance_to_node(value, child_node))
				return false;
		}
	}
	else if(id == wi_array_runtime_id()) {
		child_node = wi_xml_node_new_child(node, WI_STR("array"), NULL);
		
		xmlAddChild(node, child_node);
		
		enumerator = wi_array_data_enumerator(instance);
		
		while((value = wi_enumerator_next_data(enumerator))) {
			if(!_wi_plist_write_instance_to_node(value, child_node))
				return false;
		}
	}
	else {
		wi_error_set_libwired_error_with_format(WI_ERROR_PLIST_WRITEFAILED,
			WI_STR("Unhandled class %@"), wi_runtime_class_name(instance));
		
		return false;
	}
	
	return true;
}

#endif
