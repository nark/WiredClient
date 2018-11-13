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

#ifndef HAVE_LIBXML_PARSER_H

int wi_xml_dummy = 0;

#else

#include <wired/wi-libxml2.h>
#include <wired/wi-macros.h>
#include <wired/wi-private.h>
#include <wired/wi-runtime.h>
#include <wired/wi-string.h>

#include <string.h>

#include <libxml/tree.h>

wi_string_t * wi_xml_node_name(void *node) {
	return wi_string_with_cstring((const char *) ((xmlNodePtr) node)->name);
}



void * wi_xml_node_child_with_name(void *node, wi_string_t *name) {
	xmlNodePtr		found_node = NULL;
	xmlChar			*prop;
	const char		*string;
	
	string = wi_string_cstring(name);
	
	for(node = ((xmlNodePtr) node)->children; node != NULL; node = ((xmlNodePtr) node)->next) {
		if(((xmlNodePtr) node)->type == XML_ELEMENT_NODE) {
			prop = xmlGetProp(node, (xmlChar *) "name");
			
			if(prop) {
				if(strcmp((const char *) prop, string) == 0)
					found_node = node;
				
				xmlFree(prop);
			}
			
			if(found_node)
				return found_node;
		}
	}
	
	return NULL;
}



wi_string_t * wi_xml_node_attribute_with_name(void *node, wi_string_t *attribute) {
	xmlChar			*prop;
	
	prop = xmlGetProp(node, (xmlChar *) wi_string_cstring(attribute));
	
	if(!prop)
		return NULL;
	
	return wi_string_with_cstring_no_copy((char *) prop, true);
}



wi_integer_t wi_xml_node_integer_attribute_with_name(void *node, wi_string_t *attribute) {
	wi_string_t		*string;
	
	string = wi_xml_node_attribute_with_name(node, attribute);
	
	if(!string)
		return 0;
	
	return wi_string_integer(string);
}



void wi_xml_node_set_content(void *node, wi_string_t *string) {
	xmlNodeSetContent(node, (xmlChar *) wi_string_cstring(string));
}



wi_string_t * wi_xml_node_content(void *node) {
	xmlChar			*content;
	
	content = xmlNodeGetContent(node);
	
	if(!content)
		return NULL;
	
	return wi_string_with_cstring_no_copy((char *) content, true);
}



void * wi_xml_node_new_child(void *node, wi_string_t *name, wi_string_t *content) {
	return xmlNewTextChild(node, NULL, (xmlChar *) wi_string_cstring(name), content ? (xmlChar *) wi_string_cstring(content) : NULL);
}

#endif
