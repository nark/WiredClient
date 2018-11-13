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

int wi_p7_spec_dummy = 0;

#else

#include <libxml/tree.h>
#include <libxml/parser.h>
#include <libxml/xmlerror.h>
#include <libxml/xpath.h>
#include <string.h>

#include <wired/wi-array.h>
#include <wired/wi-byteorder.h>
#include <wired/wi-dictionary.h>
#include <wired/wi-libxml2.h>
#include <wired/wi-log.h>
#include <wired/wi-p7-message.h>
#include <wired/wi-p7-spec.h>
#include <wired/wi-p7-private.h>
#include <wired/wi-private.h>
#include <wired/wi-set.h>
#include <wired/wi-string.h>

typedef struct _wi_p7_spec_collection		_wi_p7_spec_collection_t;
typedef struct _wi_p7_spec_transaction		_wi_p7_spec_transaction_t;
typedef struct _wi_p7_spec_broadcast		_wi_p7_spec_broadcast_t;
typedef struct _wi_p7_spec_andor			_wi_p7_spec_andor_t;
typedef struct _wi_p7_spec_reply			_wi_p7_spec_reply_t;


struct _wi_p7_spec_type {
	wi_runtime_base_t						base;
	
	wi_string_t								*name;
	wi_uinteger_t							size;
	wi_uinteger_t							id;
};

static wi_p7_spec_type_t *					_wi_p7_spec_type_with_node(wi_p7_spec_t *, xmlNodePtr);
static void									_wi_p7_spec_type_dealloc(wi_runtime_instance_t *);
static wi_string_t *						_wi_p7_spec_type_description(wi_runtime_instance_t *);

static wi_runtime_id_t						_wi_p7_spec_type_runtime_id = WI_RUNTIME_ID_NULL;
static wi_runtime_class_t					_wi_p7_spec_type_runtime_class = {
    "wi_p7_spec_type_t",
    _wi_p7_spec_type_dealloc,
    NULL,
    NULL,
    _wi_p7_spec_type_description,
    NULL
};



struct _wi_p7_spec_field {
	wi_runtime_base_t						base;
	
	wi_string_t								*name;
	wi_uinteger_t							id;
	wi_p7_spec_type_t						*type;
	wi_p7_spec_type_t						*listtype;
	wi_mutable_dictionary_t					*enums_name;
	wi_mutable_dictionary_t					*enums_value;
};

static wi_p7_spec_field_t *					_wi_p7_spec_field_with_node(wi_p7_spec_t *, xmlNodePtr);
static void									_wi_p7_spec_field_dealloc(wi_runtime_instance_t *);
static wi_string_t *						_wi_p7_spec_field_description(wi_runtime_instance_t *);

static wi_runtime_id_t						_wi_p7_spec_field_runtime_id = WI_RUNTIME_ID_NULL;
static wi_runtime_class_t					_wi_p7_spec_field_runtime_class = {
    "wi_p7_spec_field_t",
    _wi_p7_spec_field_dealloc,
    NULL,
    NULL,
    _wi_p7_spec_field_description,
    NULL
};



struct _wi_p7_spec_collection {
	wi_runtime_base_t						base;
	
	wi_string_t								*name;
	wi_mutable_array_t						*fields;
};

static _wi_p7_spec_collection_t *			_wi_p7_spec_collection_with_node(wi_p7_spec_t *, xmlNodePtr);
static void									_wi_p7_spec_collection_dealloc(wi_runtime_instance_t *);
static wi_string_t *						_wi_p7_spec_collection_description(wi_runtime_instance_t *);

static wi_runtime_id_t						_wi_p7_spec_collection_runtime_id = WI_RUNTIME_ID_NULL;
static wi_runtime_class_t					_wi_p7_spec_collection_runtime_class = {
    "_wi_p7_spec_collection_t",
    _wi_p7_spec_collection_dealloc,
    NULL,
    NULL,
    _wi_p7_spec_collection_description,
    NULL
};



struct _wi_p7_spec_message {
	wi_runtime_base_t						base;
	
	wi_string_t								*name;
	wi_uinteger_t							id;
	wi_array_t								*parameters;
	wi_mutable_dictionary_t					*parameters_name;
	wi_mutable_dictionary_t					*parameters_id;
	wi_uinteger_t							required_parameters;
};

static wi_p7_spec_message_t *				_wi_p7_spec_message_with_node(wi_p7_spec_t *, xmlNodePtr);
static void									_wi_p7_spec_message_dealloc(wi_runtime_instance_t *);
static wi_string_t *						_wi_p7_spec_message_description(wi_runtime_instance_t *);

static wi_runtime_id_t						_wi_p7_spec_message_runtime_id = WI_RUNTIME_ID_NULL;
static wi_runtime_class_t					_wi_p7_spec_message_runtime_class = {
    "wi_p7_spec_message_t",
    _wi_p7_spec_message_dealloc,
    NULL,
    NULL,
    _wi_p7_spec_message_description,
    NULL
};



struct _wi_p7_spec_parameter {
	wi_runtime_base_t						base;
	
	wi_p7_spec_field_t						*field;
	wi_boolean_t							required;
};

static wi_p7_spec_parameter_t *				_wi_p7_spec_parameter_with_node(wi_p7_spec_t *, xmlNodePtr, wi_p7_spec_message_t *);
static wi_p7_spec_parameter_t *				_wi_p7_spec_parameter_with_field(wi_p7_spec_t *, wi_p7_spec_message_t *, wi_p7_spec_field_t *);
static void									_wi_p7_spec_parameter_dealloc(wi_runtime_instance_t *);
static wi_string_t *						_wi_p7_spec_parameter_description(wi_runtime_instance_t *);

static wi_runtime_id_t						_wi_p7_spec_parameter_runtime_id = WI_RUNTIME_ID_NULL;
static wi_runtime_class_t					_wi_p7_spec_parameter_runtime_class = {
    "wi_p7_spec_parameter_t",
    _wi_p7_spec_parameter_dealloc,
    NULL,
    NULL,
    _wi_p7_spec_parameter_description,
    NULL
};



struct _wi_p7_spec_transaction {
	wi_runtime_base_t						base;

	wi_p7_spec_message_t					*message;
	wi_p7_originator_t						originator;
	wi_boolean_t							required;
	_wi_p7_spec_andor_t						*andor;
};

static _wi_p7_spec_transaction_t *			_wi_p7_spec_transaction_with_node(wi_p7_spec_t *, xmlNodePtr);
static void									_wi_p7_spec_transaction_dealloc(wi_runtime_instance_t *);
static wi_string_t *						_wi_p7_spec_transaction_description(wi_runtime_instance_t *);

static wi_runtime_id_t						_wi_p7_spec_transaction_runtime_id = WI_RUNTIME_ID_NULL;
static wi_runtime_class_t					_wi_p7_spec_transaction_runtime_class = {
    "_wi_p7_spec_transaction_t",
    _wi_p7_spec_transaction_dealloc,
    NULL,
    NULL,
    _wi_p7_spec_transaction_description,
    NULL
};



struct _wi_p7_spec_broadcast {
	wi_runtime_base_t						base;

	wi_p7_spec_message_t					*message;
	wi_boolean_t							required;
};

static _wi_p7_spec_broadcast_t *			_wi_p7_spec_broadcast_with_node(wi_p7_spec_t *, xmlNodePtr);
static void									_wi_p7_spec_broadcast_dealloc(wi_runtime_instance_t *);
static wi_string_t *						_wi_p7_spec_broadcast_description(wi_runtime_instance_t *);

static wi_runtime_id_t						_wi_p7_spec_broadcast_runtime_id = WI_RUNTIME_ID_NULL;
static wi_runtime_class_t					_wi_p7_spec_broadcast_runtime_class = {
    "_wi_p7_spec_broadcast_t",
    _wi_p7_spec_broadcast_dealloc,
    NULL,
    NULL,
    _wi_p7_spec_broadcast_description,
    NULL
};



enum _wi_p7_spec_andor_type {
	_WI_P7_SPEC_AND,
	_WI_P7_SPEC_OR
};
typedef enum _wi_p7_spec_andor_type			_wi_p7_spec_andor_type_t;

struct _wi_p7_spec_andor {
	wi_runtime_base_t						base;

	_wi_p7_spec_andor_type_t				type;
	wi_mutable_array_t						*children;
	wi_mutable_array_t						*replies_array;
	wi_mutable_dictionary_t					*replies_dictionary;
};

static _wi_p7_spec_andor_t *				_wi_p7_spec_andor(_wi_p7_spec_andor_type_t, wi_p7_spec_t *, xmlNodePtr, _wi_p7_spec_transaction_t *);
static void									_wi_p7_spec_andor_dealloc(wi_runtime_instance_t *);
static wi_string_t *						_wi_p7_spec_andor_description(wi_runtime_instance_t *);

static wi_runtime_id_t						_wi_p7_spec_andor_runtime_id = WI_RUNTIME_ID_NULL;
static wi_runtime_class_t					_wi_p7_spec_andor_runtime_class = {
    "_wi_p7_spec_andor_t",
    _wi_p7_spec_andor_dealloc,
    NULL,
    NULL,
    _wi_p7_spec_andor_description,
    NULL
};



#define _WI_P7_SPEC_REPLY_ONE_OR_ZERO		-1
#define _WI_P7_SPEC_REPLY_ZERO_OR_MORE		-2
#define _WI_P7_SPEC_REPLY_ONE_OR_MORE		-3

struct _wi_p7_spec_reply {
	wi_runtime_base_t						base;

	wi_p7_spec_message_t					*message;
	wi_integer_t							count;
	wi_boolean_t							required;
};

static _wi_p7_spec_reply_t *				_wi_p7_spec_reply_with_node(wi_p7_spec_t *, xmlNodePtr, _wi_p7_spec_transaction_t *);
static wi_string_t *						_wi_p7_spec_reply_count(_wi_p7_spec_reply_t *);
static void									_wi_p7_spec_reply_dealloc(wi_runtime_instance_t *);
static wi_string_t *						_wi_p7_spec_reply_description(wi_runtime_instance_t *);

static wi_runtime_id_t						_wi_p7_spec_reply_runtime_id = WI_RUNTIME_ID_NULL;
static wi_runtime_class_t					_wi_p7_spec_reply_runtime_class = {
    "_wi_p7_spec_reply_t",
    _wi_p7_spec_reply_dealloc,
    NULL,
    NULL,
    _wi_p7_spec_reply_description,
    NULL
};



struct _wi_p7_spec {
	wi_runtime_base_t						base;
	
	wi_string_t								*xml;
	
	wi_string_t								*filename;
	wi_string_t								*name;
	wi_string_t								*version;
	wi_p7_originator_t						originator;
	
	wi_array_t								*messages;
	wi_mutable_dictionary_t					*messages_name, *messages_id;
	wi_array_t								*fields;
	wi_mutable_dictionary_t					*fields_name, *fields_id;
	wi_mutable_dictionary_t					*collections_name;
	wi_mutable_dictionary_t					*types_name, *types_id;
	wi_mutable_dictionary_t					*transactions_name;
	wi_mutable_dictionary_t					*broadcasts_name;
};

static wi_string_t *						_wi_p7_spec_originator(wi_p7_originator_t);

static wi_p7_spec_t *						_wi_p7_spec_init(wi_p7_spec_t *, wi_p7_originator_t);
static wi_p7_spec_t *						_wi_p7_spec_init_builtin_spec(wi_p7_spec_t *);

static void									_wi_p7_spec_dealloc(wi_runtime_instance_t *);
static wi_runtime_instance_t *				_wi_p7_spec_copy(wi_runtime_instance_t *);
static wi_string_t *						_wi_p7_spec_description(wi_runtime_instance_t *);

static wi_boolean_t							_wi_p7_spec_load_builtin(wi_p7_spec_t *);
static wi_boolean_t							_wi_p7_spec_load_file(wi_p7_spec_t *, wi_string_t *);
static wi_boolean_t							_wi_p7_spec_load_string(wi_p7_spec_t *, wi_string_t *);
static wi_boolean_t							_wi_p7_spec_load_spec(wi_p7_spec_t *, xmlDocPtr);
static wi_boolean_t							_wi_p7_spec_load_types(wi_p7_spec_t *, xmlNodePtr);
static wi_boolean_t							_wi_p7_spec_load_fields(wi_p7_spec_t *, xmlNodePtr);
static wi_boolean_t							_wi_p7_spec_load_collections(wi_p7_spec_t *, xmlNodePtr);
static wi_boolean_t							_wi_p7_spec_load_messages(wi_p7_spec_t *, xmlNodePtr);
static wi_boolean_t							_wi_p7_spec_load_transactions(wi_p7_spec_t *, xmlNodePtr);
static wi_boolean_t							_wi_p7_spec_load_broadcasts(wi_p7_spec_t *, xmlNodePtr);

static wi_boolean_t							_wi_p7_spec_transaction_is_compatible(wi_p7_spec_t *, _wi_p7_spec_transaction_t *, _wi_p7_spec_transaction_t *);
static wi_boolean_t							_wi_p7_spec_broadcast_is_compatible(wi_p7_spec_t *, _wi_p7_spec_broadcast_t *, _wi_p7_spec_broadcast_t *);
static wi_boolean_t							_wi_p7_spec_andor_is_compatible(wi_p7_spec_t *, _wi_p7_spec_transaction_t *, _wi_p7_spec_andor_t *, _wi_p7_spec_andor_t *);
static wi_boolean_t							_wi_p7_spec_replies_are_compatible(wi_p7_spec_t *, _wi_p7_spec_transaction_t *, _wi_p7_spec_andor_t *, _wi_p7_spec_andor_t *, wi_boolean_t);
static wi_boolean_t							_wi_p7_spec_reply_is_compatible(wi_p7_spec_t *, _wi_p7_spec_transaction_t *, _wi_p7_spec_reply_t *, _wi_p7_spec_reply_t *, wi_boolean_t);
static wi_boolean_t							_wi_p7_spec_message_is_compatible(wi_p7_spec_t *, wi_p7_spec_message_t *, wi_p7_spec_message_t *);

static wi_p7_spec_t							*_wi_p7_spec_builtin_spec;

static xmlChar								_wi_p7_spec_builtin[] =
	"<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
	"<p7:protocol xmlns:p7=\"http://www.zankasoftware.com/P7/Specification\""
	"			 xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\""
	"			 xsi:schemaLocation=\"http://www.zankasoftware.com/P7/Specification p7-specification.xsd\""
	"			 name=\"P7\" version=\"1.0\">"
	"	<p7:types>"
	"		<p7:type name=\"bool\" id=\"1\" size=\"1\" />"
	"		<p7:type name=\"enum\" id=\"2\" size=\"4\" />"
	"		<p7:type name=\"int32\" id=\"3\" size=\"4\" />"
	"		<p7:type name=\"uint32\" id=\"4\" size=\"4\" />"
	"		<p7:type name=\"int64\" id=\"5\" size=\"8\" />"
	"		<p7:type name=\"uint64\" id=\"6\" size=\"8\" />"
	"		<p7:type name=\"double\" id=\"7\" size=\"8\" />"
	"		<p7:type name=\"string\" id=\"8\" />"
	"		<p7:type name=\"uuid\" id=\"9\" size=\"16\" />"
	"		<p7:type name=\"date\" id=\"10\" size=\"8\" />"
	"		<p7:type name=\"data\" id=\"11\" />"
	"		<p7:type name=\"oobdata\" id=\"12\" size=\"8\" />"
	"		<p7:type name=\"list\" id=\"13\" />"
	"	</p7:types>"
	""
	"	<p7:fields>"
	"		<p7:field name=\"p7.handshake.version\" type=\"string\" id=\"1\" />"
	"		<p7:field name=\"p7.handshake.protocol.name\" type=\"string\" id=\"2\" />"
	"		<p7:field name=\"p7.handshake.protocol.version\" type=\"string\" id=\"3\" />"
	"		<p7:field name=\"p7.handshake.compression\" type=\"enum\" id=\"4\">"
	"			<p7:enum name=\"p7.handshake.compression.deflate\" value=\"0\" />"
	"		</p7:field>"
	"		<p7:field name=\"p7.handshake.encryption\" type=\"enum\" id=\"5\">"
	"			<p7:enum name=\"p7.handshake.encryption.rsa_aes128_sha1\" value=\"0\" />"
	"			<p7:enum name=\"p7.handshake.encryption.rsa_aes192_sha1\" value=\"1\" />"
	"			<p7:enum name=\"p7.handshake.encryption.rsa_aes256_sha1\" value=\"2\" />"
	"			<p7:enum name=\"p7.handshake.encryption.rsa_bf128_sha1\" value=\"3\" />"
	"			<p7:enum name=\"p7.handshake.encryption.rsa_3des192_sha1\" value=\"4\" />"
	"			<p7:enum name=\"p7.handshake.encryption.rsa_aes256_sha256\" value=\"5\" />"
	"		</p7:field>"
	"		<p7:field name=\"p7.handshake.checksum\" type=\"enum\" id=\"6\">"
	"			<p7:enum name=\"p7.handshake.checksum.sha1\" value=\"0\" />"
	"			<p7:enum name=\"p7.handshake.checksum.sha256\" value=\"1\" />"
	"		</p7:field>"
	"		<p7:field name=\"p7.handshake.compatibility_check\" type=\"bool\" id=\"7\" />"
	""
	"		<p7:field name=\"p7.encryption.public_key\" id=\"9\" type=\"data\" />"
	"		<p7:field name=\"p7.encryption.cipher.key\" id=\"10\" type=\"data\" />"
	"		<p7:field name=\"p7.encryption.cipher.iv\" id=\"11\" type=\"data\" />"
	"		<p7:field name=\"p7.encryption.username\" id=\"12\" type=\"data\" />"
	"		<p7:field name=\"p7.encryption.client_password\" id=\"13\" type=\"data\" />"
	"		<p7:field name=\"p7.encryption.server_password\" id=\"14\" type=\"data\" />"
	""
	"		<p7:field name=\"p7.compatibility_check.specification\" id=\"15\" type=\"string\" />"
	"		<p7:field name=\"p7.compatibility_check.status\" id=\"16\" type=\"bool\" />"
	"	</p7:fields>"
	""
	"	<p7:messages>"
	"		<p7:message name=\"p7.handshake.client_handshake\" id=\"1\">"
	"			<p7:parameter field=\"p7.handshake.version\" use=\"required\" />"
	"			<p7:parameter field=\"p7.handshake.protocol.name\" use=\"required\" />"
	"			<p7:parameter field=\"p7.handshake.protocol.version\" use=\"required\" />"
	"			<p7:parameter field=\"p7.handshake.encryption\" />"
	"			<p7:parameter field=\"p7.handshake.compression\" />"
	"			<p7:parameter field=\"p7.handshake.checksum\" />"
	"		</p7:message>"
	""
	"		<p7:message name=\"p7.handshake.server_handshake\" id=\"2\">"
	"			<p7:parameter field=\"p7.handshake.version\" use=\"required\" />"
	"			<p7:parameter field=\"p7.handshake.protocol.name\" use=\"required\" />"
	"			<p7:parameter field=\"p7.handshake.protocol.version\" use=\"required\" />"
	"			<p7:parameter field=\"p7.handshake.encryption\" />"
	"			<p7:parameter field=\"p7.handshake.compression\" />"
	"			<p7:parameter field=\"p7.handshake.checksum\" />"
	"			<p7:parameter field=\"p7.handshake.compatibility_check\" />"
	"		</p7:message>"
	""
	"		<p7:message name=\"p7.handshake.acknowledge\" id=\"3\">"
	"			<p7:parameter field=\"p7.handshake.compatibility_check\" />"
	"		</p7:message>"
	""
	"		<p7:message name=\"p7.encryption.server_key\" id=\"4\">"
	"			<p7:parameter field=\"p7.encryption.public_key\" use=\"required\" />"
	"		</p7:message>"
	""
	"		<p7:message name=\"p7.encryption.client_key\" id=\"5\">"
	"			<p7:parameter field=\"p7.encryption.cipher.key\" use=\"required\" />"
	"			<p7:parameter field=\"p7.encryption.cipher.iv\" />"
	"			<p7:parameter field=\"p7.encryption.username\" use=\"required\" />"
	"			<p7:parameter field=\"p7.encryption.client_password\" use=\"required\" />"
	"		</p7:message>"
	""
	"		<p7:message name=\"p7.encryption.acknowledge\" id=\"6\">"
	"			<p7:parameter field=\"p7.encryption.server_password\" use=\"required\" />"
	"		</p7:message>"
	""
	"		<p7:message name=\"p7.encryption.authentication_error\" id=\"7\" />"
	""
	"		<p7:message name=\"p7.compatibility_check.specification\" id=\"8\">"
	"			<p7:parameter field=\"p7.compatibility_check.specification\" use=\"required\" />"
	"		</p7:message>"
	"		"
	"		<p7:message name=\"p7.compatibility_check.status\" id=\"9\">"
	"			<p7:parameter field=\"p7.compatibility_check.status\" use=\"required\" />"
	"		</p7:message>"
	"	</p7:messages>"
	""
	"	<p7:transactions>"
	"		<p7:transaction message=\"p7.handshake.client_handshake\" originator=\"client\" use=\"required\">"
	"			<p7:reply message=\"p7.handshake.server_handshake\" count=\"1\" use=\"required\" />"
	"		</p7:transaction>"
	""
	"		<p7:transaction message=\"p7.handshake.server_handshake\" originator=\"server\" use=\"required\">"
	"			<p7:reply message=\"p7.handshake.acknowledge\" count=\"1\" use=\"required\" />"
	"		</p7:transaction>"
	""
	"		<p7:transaction message=\"p7.encryption.server_key\" originator=\"server\" use=\"required\">"
	"			<p7:reply message=\"p7.encryption.client_key\" count=\"1\" use=\"required\" />"
	"		</p7:transaction>"
	""
	"		<p7:transaction message=\"p7.encryption.client_key\" originator=\"client\" use=\"required\">"
	"			<p7:or>"
	"				<p7:reply message=\"p7.encryption.acknowledge\" count=\"1\" use=\"required\" />"
	"				<p7:reply message=\"p7.encryption.authentication_error\" count=\"1\" use=\"required\" />"
	"			</p7:or>"
	"		</p7:transaction>"
	""
	"		<p7:transaction message=\"p7.compatibility_check.specification\" originator=\"both\" use=\"required\">"
	"			<p7:reply message=\"p7.compatibility_check.status\" count=\"1\" use=\"required\" />"
	"		</p7:transaction>"
	"	</p7:transactions>"
	"</p7:protocol>";

static wi_runtime_id_t						_wi_p7_spec_runtime_id = WI_RUNTIME_ID_NULL;
static wi_runtime_class_t					_wi_p7_spec_runtime_class = {
    "wi_p7_spec_t",
    _wi_p7_spec_dealloc,
    _wi_p7_spec_copy,
    NULL,
    _wi_p7_spec_description,
    NULL
};



void wi_p7_spec_register(void) {
    _wi_p7_spec_runtime_id = wi_runtime_register_class(&_wi_p7_spec_runtime_class);
    _wi_p7_spec_type_runtime_id = wi_runtime_register_class(&_wi_p7_spec_type_runtime_class);
    _wi_p7_spec_field_runtime_id = wi_runtime_register_class(&_wi_p7_spec_field_runtime_class);
    _wi_p7_spec_collection_runtime_id = wi_runtime_register_class(&_wi_p7_spec_collection_runtime_class);
    _wi_p7_spec_message_runtime_id = wi_runtime_register_class(&_wi_p7_spec_message_runtime_class);
    _wi_p7_spec_parameter_runtime_id = wi_runtime_register_class(&_wi_p7_spec_parameter_runtime_class);
    _wi_p7_spec_transaction_runtime_id = wi_runtime_register_class(&_wi_p7_spec_transaction_runtime_class);
    _wi_p7_spec_broadcast_runtime_id = wi_runtime_register_class(&_wi_p7_spec_broadcast_runtime_class);
    _wi_p7_spec_andor_runtime_id = wi_runtime_register_class(&_wi_p7_spec_andor_runtime_class);
    _wi_p7_spec_reply_runtime_id = wi_runtime_register_class(&_wi_p7_spec_reply_runtime_class);
}



void wi_p7_spec_initialize(void) {
	xmlInitParser();
}



#pragma mark -

wi_runtime_id_t wi_p7_spec_runtime_id(void) {
    return _wi_p7_spec_runtime_id;
}



#pragma mark -

wi_p7_spec_t * wi_p7_spec_builtin_spec(void) {
	if(!_wi_p7_spec_builtin_spec) {
		_wi_p7_spec_builtin_spec = _wi_p7_spec_init_builtin_spec(wi_p7_spec_alloc());
		
		if(!_wi_p7_spec_builtin_spec)
			wi_log_fatal(WI_STR("Could not load builtin P7 spec: %m"));
	}
	
	return _wi_p7_spec_builtin_spec;
}



wi_p7_originator_t wi_p7_spec_opposite_originator(wi_p7_originator_t originator) {
	switch(originator) {
		case WI_P7_SERVER:	return WI_P7_BOTH;		break;
		case WI_P7_CLIENT:	return WI_P7_SERVER;	break;
		case WI_P7_BOTH:	return WI_P7_BOTH;		break;
	}
	
	return WI_P7_BOTH;
}



static wi_string_t * _wi_p7_spec_originator(wi_p7_originator_t originator) {
	switch(originator) {
		case WI_P7_CLIENT:	return WI_STR("client");	break;
		case WI_P7_SERVER:	return WI_STR("server");	break;
		case WI_P7_BOTH:	return WI_STR("both");		break;
	}
	
	return NULL;
}



#pragma mark -

wi_p7_spec_t * wi_p7_spec_alloc(void) {
    return wi_runtime_create_instance(_wi_p7_spec_runtime_id, sizeof(wi_p7_spec_t));
}



static wi_p7_spec_t * _wi_p7_spec_init(wi_p7_spec_t *p7_spec, wi_p7_originator_t originator) {
	p7_spec->originator				= originator;

	p7_spec->messages_name			= wi_dictionary_init_with_capacity(wi_mutable_dictionary_alloc(), 500);
	p7_spec->messages_id			= wi_dictionary_init_with_capacity_and_callbacks(wi_mutable_dictionary_alloc(),
		500, wi_dictionary_null_key_callbacks, wi_dictionary_default_value_callbacks);

	p7_spec->fields_name			= wi_dictionary_init_with_capacity(wi_mutable_dictionary_alloc(), 500);
	p7_spec->fields_id				= wi_dictionary_init_with_capacity_and_callbacks(wi_mutable_dictionary_alloc(),
		500, wi_dictionary_null_key_callbacks, wi_dictionary_default_value_callbacks);

	p7_spec->collections_name		= wi_dictionary_init_with_capacity(wi_mutable_dictionary_alloc(), 20);

	p7_spec->types_name				= wi_dictionary_init_with_capacity(wi_mutable_dictionary_alloc(), 20);
	p7_spec->types_id				= wi_dictionary_init_with_capacity_and_callbacks(wi_mutable_dictionary_alloc(),
		20, wi_dictionary_null_key_callbacks, wi_dictionary_default_value_callbacks);

	p7_spec->transactions_name		= wi_dictionary_init_with_capacity(wi_mutable_dictionary_alloc(), 20);
	p7_spec->broadcasts_name		= wi_dictionary_init_with_capacity(wi_mutable_dictionary_alloc(), 20);

	return p7_spec;
}



static wi_p7_spec_t * _wi_p7_spec_init_builtin_spec(wi_p7_spec_t *p7_spec) {
	p7_spec = _wi_p7_spec_init(p7_spec, WI_P7_BOTH);
	p7_spec->filename = wi_retain(WI_STR("(builtin)"));

	if(!_wi_p7_spec_load_builtin(p7_spec)) {
		wi_release(p7_spec);
		
		return NULL;
	}
	
	return p7_spec;
}



wi_p7_spec_t * wi_p7_spec_init_with_file(wi_p7_spec_t *p7_spec, wi_string_t *path, wi_p7_originator_t originator) {
		
	(void) wi_p7_spec_builtin_spec();
	
	p7_spec = _wi_p7_spec_init(p7_spec, originator);
	p7_spec->filename = wi_retain(wi_string_last_path_component(path));
	
	if(!_wi_p7_spec_load_file(p7_spec, path)) {
		wi_release(p7_spec);
		
		return NULL;
	}

	return p7_spec;
}



wi_p7_spec_t * wi_p7_spec_init_with_string(wi_p7_spec_t *p7_spec, wi_string_t *string, wi_p7_originator_t originator) {
	
	(void) wi_p7_spec_builtin_spec();
	
	p7_spec = _wi_p7_spec_init(p7_spec, originator);
	
	if(!_wi_p7_spec_load_string(p7_spec, string)) {
		wi_release(p7_spec);
		
		return NULL;
	}

	return p7_spec;
}



static void _wi_p7_spec_dealloc(wi_runtime_instance_t *instance) {
	wi_p7_spec_t		*p7_spec = instance;
	
	wi_release(p7_spec->xml);

	wi_release(p7_spec->filename);
	wi_release(p7_spec->name);
	wi_release(p7_spec->version);
	
	wi_release(p7_spec->messages);
	wi_release(p7_spec->messages_name);
	wi_release(p7_spec->messages_id);
	
	wi_release(p7_spec->fields);
	wi_release(p7_spec->fields_name);
	wi_release(p7_spec->fields_id);
	
	wi_release(p7_spec->collections_name);
	
	wi_release(p7_spec->types_name);
	wi_release(p7_spec->types_id);

	wi_release(p7_spec->transactions_name);
	wi_release(p7_spec->broadcasts_name);
}



static wi_runtime_instance_t * _wi_p7_spec_copy(wi_runtime_instance_t *instance) {
	wi_p7_spec_t		*p7_spec = instance, *p7_spec_copy;
	
	p7_spec_copy = _wi_p7_spec_init(wi_p7_spec_alloc(), p7_spec->originator);
	
	p7_spec_copy->xml					= wi_copy(p7_spec->xml);
	
	p7_spec_copy->filename				= wi_copy(p7_spec->filename);
	p7_spec_copy->name					= wi_copy(p7_spec->name);
	p7_spec_copy->version				= wi_copy(p7_spec->version);

	p7_spec_copy->messages				= wi_copy(p7_spec->messages);
	p7_spec_copy->messages_name			= wi_mutable_copy(p7_spec->messages_name);
	p7_spec_copy->messages_id			= wi_mutable_copy(p7_spec->messages_id);
	p7_spec_copy->fields				= wi_copy(p7_spec->fields);
	p7_spec_copy->fields_name			= wi_mutable_copy(p7_spec->fields_name);
	p7_spec_copy->fields_id				= wi_mutable_copy(p7_spec->fields_id);
	p7_spec_copy->collections_name		= wi_mutable_copy(p7_spec->collections_name);
	p7_spec_copy->types_name			= wi_mutable_copy(p7_spec->types_name);
	p7_spec_copy->types_id				= wi_mutable_copy(p7_spec->types_id);
	p7_spec_copy->transactions_name		= wi_mutable_copy(p7_spec->transactions_name);
	p7_spec_copy->broadcasts_name		= wi_mutable_copy(p7_spec->broadcasts_name);

	return p7_spec_copy;
}



static wi_string_t * _wi_p7_spec_description(wi_runtime_instance_t *instance) {
	wi_p7_spec_t		*p7_spec = instance;
	
	return wi_string_with_format(WI_STR("<%@ %p>{name = %@, version = %@, types = %@, fields = %@, messages = %@}"),
		wi_runtime_class_name(p7_spec),
		p7_spec,
		p7_spec->name,
		p7_spec->version,
		p7_spec->types_name,
		p7_spec->fields_name,
		p7_spec->messages_name);
}



#pragma mark -

static wi_boolean_t _wi_p7_spec_load_builtin(wi_p7_spec_t *p7_spec) {
	xmlDocPtr		doc;
		
	doc = xmlParseDoc(_wi_p7_spec_builtin);
	
	if(!doc) {
		wi_error_set_libxml2_error();
		
		return false;
	}
	
	if(!_wi_p7_spec_load_spec(p7_spec, doc)) {
		wi_log_info(WI_STR("no spec loaded"));
		
		xmlFreeDoc(doc);
		
		return false;
	}

	xmlFreeDoc(doc);
	
	return true;
}



static wi_boolean_t _wi_p7_spec_load_file(wi_p7_spec_t *p7_spec, wi_string_t *path) {
	xmlDocPtr	doc;
	xmlChar		*buffer;
	int			length;
	
	doc = xmlReadFile(wi_string_cstring(path), NULL, 0);
	
	if(!doc) {
		wi_error_set_libxml2_error();
		
		return false;
	}
	
	if(!_wi_p7_spec_load_spec(p7_spec, doc)) {
		xmlFreeDoc(doc);

		return false;
	}
	
	xmlDocDumpMemory(doc, &buffer, &length);
	
	p7_spec->xml = wi_string_init_with_bytes(wi_string_alloc(), (const char *) buffer, length);
	
	xmlFreeDoc(doc);
	xmlFree(buffer);

	return true;
}



static wi_boolean_t _wi_p7_spec_load_string(wi_p7_spec_t *p7_spec, wi_string_t *string) {
	xmlDocPtr	doc;
	xmlChar		*buffer;
	int			length;
	
	doc = xmlReadMemory(wi_string_cstring(string), wi_string_length(string), NULL, NULL, 0);
	
	if(!doc) {
		wi_error_set_libxml2_error();

		return false;
	}
	
	if(!_wi_p7_spec_load_spec(p7_spec, doc)) {
		xmlFreeDoc(doc);

		return false;
	}
	
	xmlDocDumpMemory(doc, &buffer, &length);
	
	p7_spec->xml = wi_string_init_with_bytes(wi_string_alloc(), (const char *) buffer, length);
	
	xmlFree(buffer);
	xmlFreeDoc(doc);

	return true;
}



static wi_boolean_t _wi_p7_spec_load_spec(wi_p7_spec_t *p7_spec, xmlDocPtr doc) {
	xmlNodePtr		root_node, node, next_node;
	
	root_node = xmlDocGetRootElement(doc);
	
	if(strcmp((const char *) root_node->name, "protocol") != 0) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
			WI_STR("Expected \"protocol\" node but got \"%s\""),
			root_node->name);
		
		return false;
	}

	p7_spec->name = wi_retain(wi_xml_node_attribute_with_name(root_node, WI_STR("name")));

	if(!p7_spec->name) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
			WI_STR("Protocol has no \"name\""));
		
		return false;
	}
	
	p7_spec->version = wi_retain(wi_xml_node_attribute_with_name(root_node, WI_STR("version")));
	
	if(!p7_spec->version) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
			WI_STR("Protocol has no \"version\""));
		
		return false;
	}

	for(node = root_node->children; node != NULL; node = next_node) {
		next_node = node->next;
		
		if(node->type == XML_ELEMENT_NODE) {
			if(strcmp((const char *) node->name, "documentation") == 0) {
				xmlUnlinkNode(node);
				xmlFreeNode(node);
				
				continue;
			}

			if(strcmp((const char *) node->name, "types") == 0) {
				if(!_wi_p7_spec_load_types(p7_spec, node))
					return false;
			}
			else if(strcmp((const char *) node->name, "fields") == 0) {
				if(!_wi_p7_spec_load_fields(p7_spec, node))
					return false;
			}
			else if(strcmp((const char *) node->name, "collections") == 0) {
				if(!_wi_p7_spec_load_collections(p7_spec, node))
					return false;
			}
			else if(strcmp((const char *) node->name, "messages") == 0) {
				if(!_wi_p7_spec_load_messages(p7_spec, node))
					return false;
			}
			else if(strcmp((const char *) node->name, "transactions") == 0) {
				if(!_wi_p7_spec_load_transactions(p7_spec, node))
					return false;
			}
			else if(strcmp((const char *) node->name, "broadcasts") == 0) {
				if(!_wi_p7_spec_load_broadcasts(p7_spec, node))
					return false;
			}
			else {
				wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
					WI_STR("Expected \"types\", \"fields\", \"collections\", \"messages\", \"transactions\" or \"broadcasts\" node but got \"%s\""),
					node->name);
				
				return false;
			}
		}
	}
	
	return true;
}



static wi_boolean_t _wi_p7_spec_load_types(wi_p7_spec_t *p7_spec, xmlNodePtr node) {
	wi_p7_spec_type_t		*type;
	xmlNodePtr				type_node, next_node;
	
	for(type_node = node->children; type_node != NULL; type_node = next_node) {
		next_node = type_node->next;
		
		if(type_node->type == XML_ELEMENT_NODE) {
			if(strcmp((const char *) type_node->name, "type") != 0) {
				wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
					WI_STR("Expected \"type\" node but got \"%s\""),
					type_node->name);
				
				return false;
			}
			
			type = _wi_p7_spec_type_with_node(p7_spec, type_node);
			
			if(!type)
				return false;
			
			if(wi_dictionary_data_for_key(p7_spec->types_name, type->name)) {
				wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
					WI_STR("Type with name \"%@\" already exists"),
					type->name);
	
				return false;
			}

			if(wi_dictionary_data_for_key(p7_spec->types_id, (void *) type->id)) {
				wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
					WI_STR("Type with id %lu (name \"%@\") already exists"),
					type->name, type->id);
				
				return false;
			}
			
			wi_mutable_dictionary_set_data_for_key(p7_spec->types_name, type, type->name);
			wi_mutable_dictionary_set_data_for_key(p7_spec->types_id, type, (void *) type->id);
		}
	}
	
	return true;
}



static wi_boolean_t _wi_p7_spec_load_fields(wi_p7_spec_t *p7_spec, xmlNodePtr node) {
	wi_p7_spec_field_t		*field;
	xmlNodePtr				field_node, next_node;
	
	for(field_node = node->children; field_node != NULL; field_node = next_node) {
		next_node = field_node->next;
		
		if(field_node->type == XML_ELEMENT_NODE) {
			if(strcmp((const char *) field_node->name, "field") != 0) {
				wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
					WI_STR("Expected \"field\" node but got \"%s\""),
					field_node->name);
				
				return false;
			}
			
			field = _wi_p7_spec_field_with_node(p7_spec, field_node);
			
			if(!field)
				return false;
			
			if(wi_dictionary_data_for_key(p7_spec->fields_name, field->name)) {
				wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
					WI_STR("Field with name \"%@\" already exists"),
					field->name);
				
				return false;
			}
			
			if(wi_dictionary_data_for_key(p7_spec->fields_id, (void *) field->id)) {
				wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
					WI_STR("Field with id %lu (name \"%@\") already exists"),
					field->id, field->name);
				
				return false;
			}
			
			if(_wi_p7_spec_builtin_spec) {
				if(wi_dictionary_data_for_key(_wi_p7_spec_builtin_spec->fields_name, field->name)) {
					wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
						WI_STR("Field with name \"%@\" already exists"),
						field->name);
					
					return false;
				}
				
				if(wi_dictionary_data_for_key(_wi_p7_spec_builtin_spec->fields_id, (void *) field->id)) {
					wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
						WI_STR("Field with id %lu (name \"%@\") already exists"),
						field->id, field->name);
					
					return false;
				}
			}

			wi_mutable_dictionary_set_data_for_key(p7_spec->fields_name, field, field->name);
			wi_mutable_dictionary_set_data_for_key(p7_spec->fields_id, field, (void *) field->id);
		}
	}
	
	return true;
}



static wi_boolean_t _wi_p7_spec_load_collections(wi_p7_spec_t *p7_spec, xmlNodePtr node) {
	_wi_p7_spec_collection_t	*collection;
	xmlNodePtr					collection_node, next_node;
	
	for(collection_node = node->children; collection_node != NULL; collection_node = next_node) {
		next_node = collection_node->next;
		
		if(collection_node->type == XML_ELEMENT_NODE) {
			if(strcmp((const char *) collection_node->name, "collection") != 0) {
				wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
					WI_STR("Expected \"collection\" node but got \"%s\""),
					collection_node->name);
				
				return false;
			}
			
			collection = _wi_p7_spec_collection_with_node(p7_spec, collection_node);
			
			if(!collection)
				return false;
			
			if(wi_dictionary_data_for_key(p7_spec->collections_name, collection->name)) {
				wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
					WI_STR("Collection with name \"%@\" already exists"),
					collection->name);
				
				return false;
			}
			
			wi_mutable_dictionary_set_data_for_key(p7_spec->collections_name, collection, collection->name);
		}
	}
	
	return true;
}



static wi_boolean_t _wi_p7_spec_load_messages(wi_p7_spec_t *p7_spec, xmlNodePtr node) {
	wi_p7_spec_message_t	*message;
	xmlNodePtr				message_node, next_node;
	
	for(message_node = node->children; message_node != NULL; message_node = next_node) {
		next_node = message_node->next;
		
		if(message_node->type == XML_ELEMENT_NODE) {
			if(strcmp((const char *) message_node->name, "message") != 0) {
				wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
					WI_STR("Expected \"message\" node but got \"%s\""),
					message_node->name);
				
				return false;
			}
			
			message = _wi_p7_spec_message_with_node(p7_spec, message_node);
			
			if(!message)
				return false;
			
			if(wi_dictionary_data_for_key(p7_spec->messages_name, message->name)) {
				wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
					WI_STR("Message with name \"%@\" already exists"),
					message->name);
				
				return false;
			}
			
			if(wi_dictionary_data_for_key(p7_spec->messages_id, (void *) message->id)) {
				wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
					WI_STR("Message with id %lu (name \"%@\") already exists"),
					message->id, message->name);
				
				return false;
			}
			
			if(_wi_p7_spec_builtin_spec) {
				if(wi_dictionary_data_for_key(_wi_p7_spec_builtin_spec->messages_name, message->name)) {
					wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
						WI_STR("Message with name \"%@\" already exists"),
						message->name);
					
					return false;
				}
				
				if(wi_dictionary_data_for_key(_wi_p7_spec_builtin_spec->messages_id, (void *) message->id)) {
					wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
						WI_STR("Message with id %lu (name \"%@\") already exists"),
						message->id, message->name);
					
					return false;
				}
			}

			wi_mutable_dictionary_set_data_for_key(p7_spec->messages_name, message, message->name);
			wi_mutable_dictionary_set_data_for_key(p7_spec->messages_id, message, (void *) message->id);
		}
	}
	
	return true;
}



static wi_boolean_t _wi_p7_spec_load_transactions(wi_p7_spec_t *p7_spec, xmlNodePtr node) {
	_wi_p7_spec_transaction_t	*transaction;
	xmlNodePtr					transaction_node, next_node;
	
	for(transaction_node = node->children; transaction_node != NULL; transaction_node = next_node) {
		next_node = transaction_node->next;
		
		if(transaction_node->type == XML_ELEMENT_NODE) {
			if(strcmp((const char *) transaction_node->name, "transaction") != 0) {
				wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
					WI_STR("Expected \"transaction\" node but got \"%s\""),
					transaction_node->name);
				
				return false;
			}
			
			transaction = _wi_p7_spec_transaction_with_node(p7_spec, transaction_node);
			
			if(!transaction)
				return false;
			
			if(wi_dictionary_data_for_key(p7_spec->transactions_name, transaction->message->name)) {
				wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
					WI_STR("Transaction with message \"%@\" already exists"),
					transaction->message->name);
				
				return false;
			}

			wi_mutable_dictionary_set_data_for_key(p7_spec->transactions_name, transaction, transaction->message->name);
		}
	}
	
	return true;
}



static wi_boolean_t _wi_p7_spec_load_broadcasts(wi_p7_spec_t *p7_spec, xmlNodePtr node) {
	_wi_p7_spec_broadcast_t		*broadcast;
	xmlNodePtr					broadcast_node, next_node;
	
	for(broadcast_node = node->children; broadcast_node != NULL; broadcast_node = next_node) {
		next_node = broadcast_node->next;
		
		if(broadcast_node->type == XML_ELEMENT_NODE) {
			if(strcmp((const char *) broadcast_node->name, "broadcast") != 0) {
				wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
					WI_STR("Expected \"broadcast\" node but got \"%s\""),
					broadcast_node->name);
				
				return false;
			}
			
			broadcast = _wi_p7_spec_broadcast_with_node(p7_spec, broadcast_node);
			
			if(!broadcast)
				return false;
			
			if(wi_dictionary_data_for_key(p7_spec->broadcasts_name, broadcast->message->name)) {
				wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
					WI_STR("Broadcast with message \"%@\" already exists"),
					broadcast->message->name);
				
				return false;
			}

			wi_mutable_dictionary_set_data_for_key(p7_spec->broadcasts_name, broadcast, broadcast->message->name);
		}
	}
	
	return true;
}



#pragma mark -

wi_boolean_t wi_p7_spec_is_compatible_with_protocol(wi_p7_spec_t *p7_spec, wi_string_t *name, wi_string_t *version) {
	return (wi_is_equal(p7_spec->name, name) && wi_is_equal(p7_spec->version, version));
}



wi_boolean_t wi_p7_spec_is_compatible_with_spec(wi_p7_spec_t *p7_spec, wi_p7_spec_t *other_p7_spec) {
	wi_enumerator_t				*enumerator;
	wi_string_t					*key;
	_wi_p7_spec_transaction_t	*transaction, *other_transaction;
	_wi_p7_spec_broadcast_t		*broadcast, *other_broadcast;
	
	enumerator = wi_dictionary_key_enumerator(p7_spec->transactions_name);
	
	while((key = wi_enumerator_next_data(enumerator))) {
		transaction			= wi_dictionary_data_for_key(p7_spec->transactions_name, key);
		other_transaction	= wi_dictionary_data_for_key(other_p7_spec->transactions_name, key);
		
		if(!_wi_p7_spec_transaction_is_compatible(p7_spec, transaction, other_transaction))
			return false;
	}
	
	enumerator = wi_dictionary_key_enumerator(p7_spec->broadcasts_name);
	
	while((key = wi_enumerator_next_data(enumerator))) {
		broadcast			= wi_dictionary_data_for_key(p7_spec->broadcasts_name, key);
		other_broadcast		= wi_dictionary_data_for_key(other_p7_spec->broadcasts_name, key);
		
		if(!_wi_p7_spec_broadcast_is_compatible(p7_spec, broadcast, other_broadcast))
			return false;
	}
	
	return true;
}



static wi_boolean_t _wi_p7_spec_transaction_is_compatible(wi_p7_spec_t *p7_spec, _wi_p7_spec_transaction_t *transaction, _wi_p7_spec_transaction_t *other_transaction) {
	if(transaction->required) {
		if(!other_transaction || !other_transaction->required) {
			if(!other_transaction) {
				wi_error_set_libwired_error_with_format(WI_ERROR_P7_INCOMPATIBLESPEC,
					WI_STR("Transaction \"%@\" is required, but peer lacks it"),
					transaction->message->name);
			} else {
				wi_error_set_libwired_error_with_format(WI_ERROR_P7_INCOMPATIBLESPEC,
					WI_STR("Transaction \"%@\" is required, but peer has it optional"),
					transaction->message->name);
			}
			
			return false;
		}
	}
	
	if(other_transaction) {
		if(transaction->originator != other_transaction->originator) {
			wi_error_set_libwired_error_with_format(WI_ERROR_P7_INCOMPATIBLESPEC,
				WI_STR("Transaction \"%@\" should be sent by %@, but peer sends it by %@"),
				transaction->message->name,
				_wi_p7_spec_originator(transaction->originator),
				_wi_p7_spec_originator(other_transaction->originator));

			return false;
		}
		
		if(!_wi_p7_spec_message_is_compatible(p7_spec, transaction->message, other_transaction->message))
			return false;
		
		if(!_wi_p7_spec_andor_is_compatible(p7_spec, transaction, transaction->andor, other_transaction->andor))
			return false;
	}
	
	return true;
}



static wi_boolean_t _wi_p7_spec_broadcast_is_compatible(wi_p7_spec_t *p7_spec, _wi_p7_spec_broadcast_t *broadcast, _wi_p7_spec_broadcast_t *other_broadcast) {
	if(broadcast->required) {
		if(!other_broadcast || !other_broadcast->required) {
			if(!other_broadcast) {
				wi_error_set_libwired_error_with_format(WI_ERROR_P7_INCOMPATIBLESPEC,
					WI_STR("Broadcast \"%@\" is required, but peer lacks it"),
					broadcast->message->name);
			} else {
				wi_error_set_libwired_error_with_format(WI_ERROR_P7_INCOMPATIBLESPEC,
					WI_STR("Broadcast \"%@\" is required, but peer has it optional"),
					broadcast->message->name);
			}
			
			return false;
		}
	}
	
	if(other_broadcast) {
		if(!_wi_p7_spec_message_is_compatible(p7_spec, broadcast->message, other_broadcast->message))
			return false;
	}
	
	return true;
}



static wi_boolean_t _wi_p7_spec_andor_is_compatible(wi_p7_spec_t *p7_spec, _wi_p7_spec_transaction_t *transaction, _wi_p7_spec_andor_t *andor, _wi_p7_spec_andor_t *other_andor) {
	wi_uinteger_t		i, count, other_count;
	
	if(andor->type != other_andor->type)
		return false;
	
	if(!_wi_p7_spec_replies_are_compatible(p7_spec, transaction, andor, other_andor, false) ||
	   !_wi_p7_spec_replies_are_compatible(p7_spec, transaction, other_andor, andor, true))
		return false;
	
	count = wi_array_count(andor->children);
	other_count = wi_array_count(other_andor->children);
	
	if(count != other_count) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_INCOMPATIBLESPEC,
			WI_STR("Transaction \"%@\" should have %lu %@, but peer has %lu"),
			transaction->message->name,
			count,
			count == 1
				? WI_STR("child")
				: WI_STR("children"),
			other_count);
		
		return false;
	}
	
	for(i = 0; i < count; i++) {
		if(!_wi_p7_spec_andor_is_compatible(p7_spec, transaction, WI_ARRAY(andor->children, i), WI_ARRAY(other_andor->children, i)))
			return false;
	}
	
	return true;
}



static wi_boolean_t _wi_p7_spec_replies_are_compatible(wi_p7_spec_t *p7_spec, _wi_p7_spec_transaction_t *transaction, _wi_p7_spec_andor_t *andor, _wi_p7_spec_andor_t *other_andor, wi_boolean_t commutativity) {
	wi_enumerator_t			*enumerator;
	_wi_p7_spec_reply_t		*reply, *other_reply, *each_reply;
	wi_uinteger_t			i, count, index;
	
	if(andor->type != other_andor->type)
		return false;
	
	enumerator		= wi_array_data_enumerator(andor->replies_array);
	count			= wi_array_count(other_andor->replies_array);
	index			= 0;
	
	while((reply = wi_enumerator_next_data(enumerator))) {
		if(reply->required) {
			other_reply = NULL;
			
			for(i = index; i < count; i++) {
				each_reply = WI_ARRAY(other_andor->replies_array, i);
				
				if(each_reply->required) {
					other_reply = each_reply;
					
					break;
				}
			}
			
			index = i + 1;
			
			if(!_wi_p7_spec_reply_is_compatible(p7_spec, transaction, reply, other_reply, commutativity))
				return false;
		} else {
			other_reply = wi_dictionary_data_for_key(other_andor->replies_dictionary, reply->message->name);
			
			if(!_wi_p7_spec_reply_is_compatible(p7_spec, transaction, reply, other_reply, commutativity))
				return false;
		}
	}
	
	return true;
}



static wi_boolean_t _wi_p7_spec_reply_is_compatible(wi_p7_spec_t *p7_spec, _wi_p7_spec_transaction_t *transaction, _wi_p7_spec_reply_t *reply, _wi_p7_spec_reply_t *other_reply, wi_boolean_t commutativity) {
	wi_boolean_t	compatible;
	
	if(reply->required) {
		if(!other_reply || !other_reply->required) {
			if(!other_reply) {
				wi_error_set_libwired_error_with_format(WI_ERROR_P7_INCOMPATIBLESPEC,
					WI_STR("Reply \"%@\" in transaction \"%@\" is required, but peer lacks it"),
					reply->message->name, transaction->message->name);
			} else {
				wi_error_set_libwired_error_with_format(WI_ERROR_P7_INCOMPATIBLESPEC,
					WI_STR("Reply \"%@\" in transaction \"%@\" is required, but peer has it optional"),
					reply->message->name, transaction->message->name);
			}

			return false;
		}
	}
	
	if(!commutativity) {
		if(other_reply) {
			if(reply->count == _WI_P7_SPEC_REPLY_ONE_OR_ZERO)
				compatible = (other_reply->count == _WI_P7_SPEC_REPLY_ONE_OR_ZERO);
			else if(reply->count == _WI_P7_SPEC_REPLY_ZERO_OR_MORE)
				compatible = (other_reply->count == _WI_P7_SPEC_REPLY_ONE_OR_ZERO || other_reply->count == _WI_P7_SPEC_REPLY_ZERO_OR_MORE);
			else if(reply->count == _WI_P7_SPEC_REPLY_ONE_OR_MORE)
				compatible = (other_reply->count == _WI_P7_SPEC_REPLY_ONE_OR_MORE || other_reply->count > 0);
			else
				compatible = (reply->count == other_reply->count);
			
			if(!compatible) {
				wi_error_set_libwired_error_with_format(WI_ERROR_P7_INCOMPATIBLESPEC,
					WI_STR("Reply \"%@\" in transaction \"%@\" should be sent %@, but peer sends it %@"),
					reply->message->name,
					transaction->message->name,
					_wi_p7_spec_reply_count(reply),
					_wi_p7_spec_reply_count(other_reply));
				
				return false;
			}
			
			if(!_wi_p7_spec_message_is_compatible(p7_spec, reply->message, other_reply->message))
				return false;
		}
	}
	
	return true;
}

	
	
static wi_boolean_t _wi_p7_spec_message_is_compatible(wi_p7_spec_t *p7_spec, wi_p7_spec_message_t *message, wi_p7_spec_message_t *other_message) {
	wi_enumerator_t			*enumerator, *enum_enumerator;
	wi_string_t				*key, *name;
	wi_p7_spec_parameter_t	*parameter, *other_parameter;
	wi_p7_spec_field_t		*field, *other_field;
	wi_uinteger_t			value, other_value;
	
	if(!wi_is_equal(message->name, other_message->name)) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_INCOMPATIBLESPEC,
			WI_STR("Message should be \"%@\", but peer has \"%@\""),
				message->name, other_message->name);
		
		return false;
	}
	
	if(message->id != other_message->id) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_INCOMPATIBLESPEC,
			WI_STR("Message should have id %lu, but peer has id %lu"),
			message->id, other_message->id);
		
		return false;
	}
	
	enumerator = wi_dictionary_key_enumerator(message->parameters_name);
	
	while((key = wi_enumerator_next_data(enumerator))) {
		parameter = wi_dictionary_data_for_key(message->parameters_name, key);
		other_parameter = wi_dictionary_data_for_key(other_message->parameters_name, key);
		
		if(parameter->required) {
			if(!other_parameter || !other_parameter->required) {
				if(!other_parameter) {
					wi_error_set_libwired_error_with_format(WI_ERROR_P7_INCOMPATIBLESPEC,
						WI_STR("Parameter \"%@\" in message \"%@\" is required, but peer lacks it"),
						parameter->field->name, message->name);
				} else {
					wi_error_set_libwired_error_with_format(WI_ERROR_P7_INCOMPATIBLESPEC,
						WI_STR("Parameter \"%@\" in message \"%@\" is required, but peer has it optional"),
						parameter->field->name, message->name);
				}
				
				return false;
			}
		}
			
		if(other_parameter) {
			field			= parameter->field;
			other_field		= other_parameter->field;
			
			if(field->id != other_field->id) {
				wi_error_set_libwired_error_with_format(WI_ERROR_P7_INCOMPATIBLESPEC,
					WI_STR("Field in parameter \"%@\" in message \"%@\" should have id %lu, but peer has id %lu"),
					parameter->field->name, message->name, field->id, other_field->id);
				
				return false;
			}
			
			if(field->type->id != other_field->type->id) {
				wi_error_set_libwired_error_with_format(WI_ERROR_P7_INCOMPATIBLESPEC,
					WI_STR("Parameter \"%@\" in message \"%@\" should be of type \"%@\", but peer has it as \"%@\""),
					parameter->field->name, message->name, field->type->name, other_field->type->name);

				return false;
			}
			
			if(field->type->id == WI_P7_ENUM) {
				enum_enumerator = wi_dictionary_key_enumerator(field->enums_name);
				
				while((name = wi_enumerator_next_data(enum_enumerator))) {
					value			= (wi_uinteger_t) wi_dictionary_data_for_key(field->enums_name, name);
					other_value		= (wi_uinteger_t) wi_dictionary_data_for_key(other_field->enums_name, name);
					
					if(value != other_value) {
						wi_error_set_libwired_error_with_format(WI_ERROR_P7_INCOMPATIBLESPEC,
							WI_STR("Enumeration \"%@\" in parameter \"%@\" in message \"%@\" should have value %lu, but peer has value %lu"),
							name, parameter->field->name, message->name, value, other_value);
						
						return false;
					}
				}
			}
		}
	}
	
	return true;
}



void wi_p7_spec_merge_with_spec(wi_p7_spec_t *p7_spec, wi_p7_spec_t *other_p7_spec) {
	wi_enumerator_t			*enumerator;
	wi_p7_spec_message_t	*message;
	wi_p7_spec_field_t		*field, *other_field;
	wi_uinteger_t			id;
	wi_boolean_t			modified;
	
	modified	= false;
	enumerator	= wi_dictionary_key_enumerator(other_p7_spec->messages_id);
	
	while((id = (wi_uinteger_t) wi_enumerator_next_data(enumerator))) {
		if(!wi_dictionary_data_for_key(p7_spec->messages_id, (void *) id)) {
			message = wi_dictionary_data_for_key(other_p7_spec->messages_id, (void *) id);
			
			wi_mutable_dictionary_set_data_for_key(p7_spec->messages_id, message, (void *) message->id);
			wi_mutable_dictionary_set_data_for_key(p7_spec->messages_name, message, message->name);
			
			modified = true;
		}
	}
	
	if(modified) {
		wi_release(p7_spec->messages);
		p7_spec->messages = NULL;
	}
	
	modified	= false;
	enumerator	= wi_dictionary_key_enumerator(other_p7_spec->fields_id);
	
	while((id = (wi_uinteger_t) wi_enumerator_next_data(enumerator))) {
		field			= wi_dictionary_data_for_key(p7_spec->fields_id, (void *) id);
		other_field		= wi_dictionary_data_for_key(other_p7_spec->fields_id, (void *) id);
		
		if(field) {
			if(field->type->id == WI_P7_ENUM) {
				if(!wi_is_equal(field->enums_name, other_field->enums_name)) {
					wi_mutable_dictionary_set_dictionary(field->enums_name, other_field->enums_name);
					wi_mutable_dictionary_set_dictionary(field->enums_value, other_field->enums_value);
					
					modified = true;
				}
			}
		} else {
			wi_mutable_dictionary_set_data_for_key(p7_spec->fields_id, other_field, (void *) other_field->id);
			wi_mutable_dictionary_set_data_for_key(p7_spec->fields_name, other_field, other_field->name);
			
			modified = true;
		}
	}
	
	if(modified) {
		wi_release(p7_spec->fields);
		p7_spec->fields = NULL;
	}
}



#pragma mark -

wi_string_t * wi_p7_spec_name(wi_p7_spec_t *p7_spec) {
	return p7_spec->name;
}



wi_string_t * wi_p7_spec_version(wi_p7_spec_t *p7_spec) {
	return p7_spec->version;
}



wi_p7_originator_t wi_p7_spec_originator(wi_p7_spec_t *p7_spec) {
	return p7_spec->originator;
}



wi_string_t * wi_p7_spec_xml(wi_p7_spec_t *p7_spec) {
	return p7_spec->xml;
}



wi_p7_spec_type_t * wi_p7_spec_type_with_name(wi_p7_spec_t *p7_spec, wi_string_t *type_name) {
	wi_p7_spec_type_t		*type;
	
	type = wi_dictionary_data_for_key(p7_spec->types_name, type_name);
	
	if(!type && _wi_p7_spec_builtin_spec)
		type = wi_dictionary_data_for_key(_wi_p7_spec_builtin_spec->types_name, type_name);
	
	return type;
}



wi_p7_spec_type_t * wi_p7_spec_type_with_id(wi_p7_spec_t *p7_spec, wi_uinteger_t type_id) {
	wi_p7_spec_type_t		*type;
	
	type = wi_dictionary_data_for_key(p7_spec->types_id, (void *) type_id);
	
	if(!type && _wi_p7_spec_builtin_spec)
		type = wi_dictionary_data_for_key(_wi_p7_spec_builtin_spec->types_id, (void *) type_id);
	
	return type;
}



wi_array_t * wi_p7_spec_fields(wi_p7_spec_t *p7_spec) {
	if(!p7_spec->fields)
		p7_spec->fields = wi_retain(wi_dictionary_all_values(p7_spec->fields_id));
	
	return p7_spec->fields;
}



wi_p7_spec_field_t * wi_p7_spec_field_with_name(wi_p7_spec_t *p7_spec, wi_string_t *field_name) {
	wi_p7_spec_field_t		*field;
	
	field = wi_dictionary_data_for_key(p7_spec->fields_name, field_name);
	
	if(!field && _wi_p7_spec_builtin_spec)
		field = wi_dictionary_data_for_key(_wi_p7_spec_builtin_spec->fields_name, field_name);
	
	return field;
}



wi_p7_spec_field_t * wi_p7_spec_field_with_id(wi_p7_spec_t *p7_spec, wi_uinteger_t field_id) {
	wi_p7_spec_field_t		*field;
	
	field = wi_dictionary_data_for_key(p7_spec->fields_id, (void *) field_id);
	
	if(!field && _wi_p7_spec_builtin_spec)
		field = wi_dictionary_data_for_key(_wi_p7_spec_builtin_spec->fields_id, (void *) field_id);
	
	return field;
}



wi_array_t * wi_p7_spec_messages(wi_p7_spec_t *p7_spec) {
	if(!p7_spec->messages)
		p7_spec->messages = wi_retain(wi_dictionary_all_values(p7_spec->messages_id));
	
	return p7_spec->messages;
}



wi_p7_spec_message_t * wi_p7_spec_message_with_name(wi_p7_spec_t *p7_spec, wi_string_t *message_name) {
	wi_p7_spec_message_t	*message;
	
	message = wi_dictionary_data_for_key(p7_spec->messages_name, message_name);
	
	if(!message && _wi_p7_spec_builtin_spec)
		message = wi_dictionary_data_for_key(_wi_p7_spec_builtin_spec->messages_name, message_name);
	
	return message;
}



wi_p7_spec_message_t * wi_p7_spec_message_with_id(wi_p7_spec_t *p7_spec, wi_uinteger_t message_id) {
	wi_p7_spec_message_t	*message;
	
	message = wi_dictionary_data_for_key(p7_spec->messages_id, (void *) message_id);
	
	if(!message && _wi_p7_spec_builtin_spec)
		message = wi_dictionary_data_for_key(_wi_p7_spec_builtin_spec->messages_id, (void *) message_id);
	
	return message;
}



#pragma mark -

wi_boolean_t wi_p7_spec_verify_message(wi_p7_spec_t *p7_spec, wi_p7_message_t *p7_message) {
	wi_p7_spec_message_t	*message;
	wi_p7_spec_field_t		*field;
	wi_p7_spec_parameter_t	*parameter;
	unsigned char			*buffer, *start;
	wi_uinteger_t			required_parameters = 0;
	uint32_t				message_size, field_id, field_size;
	
	message = wi_dictionary_data_for_key(p7_spec->messages_id, (void *) (intptr_t) p7_message->binary_id);
	
	if(!message) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_UNKNOWNMESSAGE,
			WI_STR("Message with id %u not recognized"),
			p7_message->binary_id);
		
		return false;
	}

	message_size = p7_message->binary_size - WI_P7_MESSAGE_BINARY_HEADER_SIZE;
	buffer = start = p7_message->binary_buffer + WI_P7_MESSAGE_BINARY_HEADER_SIZE;

	while((uint32_t) (buffer - start) < message_size) {
		field_id	= wi_read_swap_big_to_host_int32(buffer, 0);
		buffer		+= sizeof(field_id);
		field		= wi_p7_spec_field_with_id(p7_spec, field_id);
	
		if(!field)
			continue;

		field_size	= wi_p7_spec_field_size(field);
		
		if(field_size == 0) {
			field_size = wi_read_swap_big_to_host_int32(buffer, 0);
			
			buffer += sizeof(field_size);
		}
		
		parameter = wi_dictionary_data_for_key(message->parameters_id, (void *) (intptr_t) field_id);
		
		if(parameter && parameter->required)
			required_parameters++;
		
		buffer += field_size;
	}
	
	if(required_parameters != message->required_parameters) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDMESSAGE,
			WI_STR("%u out of %u required parameters in message \"%@\""),
			required_parameters, message->required_parameters, message->name);
		
		return false;
	}
	
	return true;
}



#pragma mark -

wi_runtime_id_t wi_p7_spec_type_runtime_id(void) {
	return _wi_p7_spec_type_runtime_id;
}



#pragma mark -

static wi_p7_spec_type_t * _wi_p7_spec_type_with_node(wi_p7_spec_t *p7_spec, xmlNodePtr type_node) {
	wi_p7_spec_type_t		*type;
	
    type = wi_autorelease(wi_runtime_create_instance(_wi_p7_spec_type_runtime_id, sizeof(wi_p7_spec_type_t)));
	type->name = wi_retain(wi_xml_node_attribute_with_name(type_node, WI_STR("name")));
	
	if(!type->name) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
			WI_STR("Type has no \"name\""));
		
		return NULL;
	}
	
	type->id = wi_xml_node_integer_attribute_with_name(type_node, WI_STR("id"));
	
	if(type->id == 0) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
			WI_STR("Type \"%@\" has no \"id\""),
			type->name);
		
		return NULL;
	}
	
	type->size = wi_xml_node_integer_attribute_with_name(type_node, WI_STR("size"));

	return type;
}



static void _wi_p7_spec_type_dealloc(wi_runtime_instance_t *instance) {
	wi_p7_spec_type_t		*type = instance;
	
	wi_release(type->name);
}



static wi_string_t * _wi_p7_spec_type_description(wi_runtime_instance_t *instance) {
	wi_p7_spec_type_t		*type = instance;
	
	return wi_string_with_format(WI_STR("<%@ %p>{name = %@, id = %lu, size = %lu}"),
        wi_runtime_class_name(type),
		type,
		type->name,
		type->id,
		type->size);
}



#pragma mark -

wi_string_t * wi_p7_spec_type_name(wi_p7_spec_type_t *type) {
	return type->name;
}



wi_uinteger_t wi_p7_spec_type_id(wi_p7_spec_type_t *type) {
	return type->id;
}



wi_uinteger_t wi_p7_spec_type_size(wi_p7_spec_type_t *type) {
	return type->size;
}



#pragma mark -

wi_runtime_id_t wi_p7_spec_field_runtime_id(void) {
	return _wi_p7_spec_field_runtime_id;
}



#pragma mark -

static wi_p7_spec_field_t * _wi_p7_spec_field_with_node(wi_p7_spec_t *p7_spec, xmlNodePtr node) {
	xmlNodePtr					enum_node, next_node;
	wi_p7_spec_field_t			*field;
	wi_string_t					*type, *listtype, *name;
	wi_integer_t				value;
	
    field = wi_autorelease(wi_runtime_create_instance(_wi_p7_spec_field_runtime_id, sizeof(wi_p7_spec_field_t)));
	field->name = wi_retain(wi_xml_node_attribute_with_name(node, WI_STR("name")));

	if(!field->name) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
			WI_STR("Field has no \"name\""));

		return NULL;
	}
	
	type = wi_xml_node_attribute_with_name(node, WI_STR("type"));

	if(!type) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
			WI_STR("Field \"%@\" has no \"type\""),
			field->name);

		return NULL;
	}
	
	field->type = wi_retain(wi_dictionary_data_for_key(p7_spec->types_name, type));
	
	if(!field->type && _wi_p7_spec_builtin_spec)
		field->type = wi_retain(wi_dictionary_data_for_key(_wi_p7_spec_builtin_spec->types_name, type));
	
	if(!field->type) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
			WI_STR("Field \"%@\" has an invalid \"type\" (\"%@\")"),
			field->name, type);

		return NULL;
	}
	
	listtype = wi_xml_node_attribute_with_name(node, WI_STR("listtype"));
	
	if(listtype) {
		field->listtype = wi_retain(wi_dictionary_data_for_key(p7_spec->types_name, listtype));
		
		if(!field->listtype && _wi_p7_spec_builtin_spec)
			field->listtype = wi_retain(wi_dictionary_data_for_key(_wi_p7_spec_builtin_spec->types_name, listtype));
		
		if(!field->listtype) {
			wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
				WI_STR("Field \"%@\" has an invalid \"listtype\" (\"%@\")"),
				field->name, listtype);

			return NULL;
		}
	}
	
	field->id = wi_xml_node_integer_attribute_with_name(node, WI_STR("id"));
	
	if(field->id == 0) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
			WI_STR("Field \"%@\" has no \"id\""),
			field->name);

		return NULL;
	}
	
	if(field->type->id == WI_P7_ENUM) {
		field->enums_name = wi_dictionary_init_with_capacity_and_callbacks(wi_mutable_dictionary_alloc(),
			20, wi_dictionary_default_key_callbacks, wi_dictionary_null_value_callbacks);
		field->enums_value = wi_dictionary_init_with_capacity_and_callbacks(wi_mutable_dictionary_alloc(),
			20, wi_dictionary_null_key_callbacks, wi_dictionary_default_value_callbacks);
	}
		
	for(enum_node = node->children; enum_node != NULL; enum_node = next_node) {
		next_node = enum_node->next;
		
		if(enum_node->type == XML_ELEMENT_NODE) {
			if(strcmp((const char *) enum_node->name, "documentation") == 0) {
				xmlUnlinkNode(enum_node);
				xmlFreeNode(enum_node);
				
				continue;
			}
			
			if(field->type->id != WI_P7_ENUM) {
				wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
					WI_STR("Expected no more nodes but got \"%s\""),
					enum_node->name);
				
				return NULL;
			}
			
			if(strcmp((const char *) enum_node->name, "enum") != 0) {
				wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
					WI_STR("Expected \"enum\" node but got \"%s\""),
					enum_node->name);
				
				return NULL;
			}
			
			name = wi_xml_node_attribute_with_name(enum_node, WI_STR("name"));
			
			if(!name) {
				wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
					WI_STR("Field \"%@\" enum has no \"name\""),
					field->name);
				
				return NULL;
			}
			
			value = wi_xml_node_integer_attribute_with_name(enum_node, WI_STR("value"));
			
			if(wi_dictionary_data_for_key(field->enums_name, name)) {
				wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
					WI_STR("Enum with name \"%@\" in field \"%@\" already exists"),
					name, field->name);
				
				return NULL;
			}
			
			if(wi_dictionary_data_for_key(field->enums_value, (void *) value)) {
				wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
					WI_STR("Enum with value %lu (name \"%@\") in field \"%@\" already exists"),
					value, name, field->name);
				
				return NULL;
			}
			
			wi_mutable_dictionary_set_data_for_key(field->enums_name, (void *) value, name);
			wi_mutable_dictionary_set_data_for_key(field->enums_value, name, (void *) value);
		}
	}
	
	return field;
}



static void _wi_p7_spec_field_dealloc(wi_runtime_instance_t *instance) {
	wi_p7_spec_field_t		*field = instance;

	wi_release(field->name);
	wi_release(field->type);
	wi_release(field->enums_name);
	wi_release(field->enums_value);
}



static wi_string_t * _wi_p7_spec_field_description(wi_runtime_instance_t *instance) {
	wi_p7_spec_field_t		*field = instance;
	
	return wi_string_with_format(WI_STR("<%@ %p>{name = %@, id = %lu, type = %@}"),
        wi_runtime_class_name(field),
		field,
		field->name,
		field->id,
		field->type);
}



#pragma mark -

wi_string_t * wi_p7_spec_field_name(wi_p7_spec_field_t *field) {
	return field->name;
}



wi_uinteger_t wi_p7_spec_field_id(wi_p7_spec_field_t *field) {
	return field->id;
}



wi_uinteger_t wi_p7_spec_field_size(wi_p7_spec_field_t *field) {
	return field->type->size;
}



wi_p7_spec_type_t * wi_p7_spec_field_type(wi_p7_spec_field_t *field) {
	return field->type;
}



wi_p7_spec_type_t * wi_p7_spec_field_listtype(wi_p7_spec_field_t *field) {
	return field->listtype;
}



wi_dictionary_t * wi_p7_spec_field_enums_by_name(wi_p7_spec_field_t *field) {
	return field->enums_name;
}



wi_dictionary_t * wi_p7_spec_field_enums_by_value(wi_p7_spec_field_t *field) {
	return field->enums_value;
}



#pragma mark -

static _wi_p7_spec_collection_t * _wi_p7_spec_collection_with_node(wi_p7_spec_t *p7_spec, xmlNodePtr node) {
	xmlNodePtr					member_node, next_node;
	_wi_p7_spec_collection_t	*collection;
	wi_p7_spec_field_t			*field;
	wi_string_t					*field_name;
	
    collection = wi_autorelease(wi_runtime_create_instance(_wi_p7_spec_collection_runtime_id, sizeof(_wi_p7_spec_collection_t)));
	collection->name = wi_retain(wi_xml_node_attribute_with_name(node, WI_STR("name")));

	if(!collection->name) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
			WI_STR("Collection has no \"name\""));

		return NULL;
	}
	
	collection->fields = wi_array_init(wi_mutable_array_alloc());
	
	for(member_node = node->children; member_node != NULL; member_node = next_node) {
		next_node = member_node->next;
		
		if(member_node->type == XML_ELEMENT_NODE) {
			if(strcmp((const char *) member_node->name, "documentation") == 0) {
				xmlUnlinkNode(member_node);
				xmlFreeNode(member_node);
				
				continue;
			}
			
			if(strcmp((const char *) member_node->name, "member") != 0) {
				wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
					WI_STR("Expected \"member\" node but got \"%s\""),
					member_node->name);
				
				return false;
			}
			
			field_name = wi_xml_node_attribute_with_name(member_node, WI_STR("field"));
			
			if(!field_name) {
				wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
					WI_STR("Member in collection \"%@\" has no \"field\""),
					collection->name);
				
				return NULL;
			}
			
			field = wi_dictionary_data_for_key(p7_spec->fields_name, field_name);
			
			if(!field && _wi_p7_spec_builtin_spec)
				field = wi_dictionary_data_for_key(_wi_p7_spec_builtin_spec->fields_name, field_name);
			
			if(!field) {
				wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
					WI_STR("Member in collection \"%@\" has an invalid \"field\" (\"%@\")"),
					collection->name, field_name);
				
				return NULL;
			}
			
			wi_mutable_array_add_data(collection->fields, field);
		}
	}
	
	return collection;
}



static void _wi_p7_spec_collection_dealloc(wi_runtime_instance_t *instance) {
	_wi_p7_spec_collection_t		*collection = instance;

	wi_release(collection->name);
	wi_release(collection->fields);
}



static wi_string_t * _wi_p7_spec_collection_description(wi_runtime_instance_t *instance) {
	_wi_p7_spec_collection_t		*collection = instance;
	
	return wi_string_with_format(WI_STR("<%@ %p>{name = %@, fields = %@}"),
        wi_runtime_class_name(collection),
		collection,
		collection->name,
		collection->fields);
}



#pragma mark -

wi_runtime_id_t wi_p7_spec_message_runtime_id(void) {
	return _wi_p7_spec_message_runtime_id;
}



#pragma mark -

static wi_p7_spec_message_t * _wi_p7_spec_message_with_node(wi_p7_spec_t *p7_spec, xmlNodePtr node) {
	wi_enumerator_t				*enumerator;
	wi_string_t					*field_name, *collection_name, *use;
	xmlNodePtr					parameter_node, next_node;
	wi_p7_spec_message_t		*message;
	wi_p7_spec_parameter_t		*parameter;
	_wi_p7_spec_collection_t	*collection;
	wi_p7_spec_field_t			*field;
	wi_boolean_t				required;

    message = wi_autorelease(wi_runtime_create_instance(_wi_p7_spec_message_runtime_id, sizeof(wi_p7_spec_message_t)));
	message->name = wi_retain(wi_xml_node_attribute_with_name(node, WI_STR("name")));

	if(!message->name) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
			WI_STR("Message has no name"));
		
		return NULL;
	}
	
	message->id	= wi_xml_node_integer_attribute_with_name(node, WI_STR("id"));
	
	if(message->id == 0) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
			WI_STR("Message \"%@\" has no \"id\""),
			message->name);

		return NULL;
	}
	
	message->parameters_name	= wi_dictionary_init_with_capacity(wi_mutable_dictionary_alloc(), 20);
	message->parameters_id		= wi_dictionary_init_with_capacity_and_callbacks(wi_mutable_dictionary_alloc(),
		20, wi_dictionary_null_key_callbacks, wi_dictionary_default_value_callbacks);

	for(parameter_node = node->children; parameter_node != NULL; parameter_node = next_node) {
		next_node = parameter_node->next;
		
		if(parameter_node->type == XML_ELEMENT_NODE) {
			if(strcmp((const char *) parameter_node->name, "documentation") == 0) {
				xmlUnlinkNode(parameter_node);
				xmlFreeNode(parameter_node);
				
				continue;
			}
			
			if(strcmp((const char *) parameter_node->name, "parameter") != 0) {
				wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
					WI_STR("Expected \"parameter\" node but got \"%s\""),
					parameter_node->name);
				
				return false;
			}
			
			field_name			= wi_xml_node_attribute_with_name(parameter_node, WI_STR("field"));
			collection_name		= wi_xml_node_attribute_with_name(parameter_node, WI_STR("collection"));
			
			if(field_name) {
				parameter = _wi_p7_spec_parameter_with_node(p7_spec, parameter_node, message);

				if(!parameter)
					return NULL;
				
				if(wi_dictionary_data_for_key(message->parameters_name, parameter->field->name)) {
					wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
						WI_STR("Message \"%@\" has a duplicate field \"%@\""),
						message->name, parameter->field->name);
					
					return NULL;
				}
				
				wi_mutable_dictionary_set_data_for_key(message->parameters_name, parameter, parameter->field->name);
				wi_mutable_dictionary_set_data_for_key(message->parameters_id, parameter, (void *) parameter->field->id);
				
				if(parameter->required)
					message->required_parameters++;
			}
			else if(collection_name) {
				collection = wi_dictionary_data_for_key(p7_spec->collections_name, collection_name);
				
				if(!collection) {
					wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
						WI_STR("Parameter in message \"%@\" has an invalid \"collection\" (\"%@\")"),
						message->name, collection_name);
					
					return NULL;
				}

				required = false;
				use = wi_xml_node_attribute_with_name(parameter_node, WI_STR("use"));

				if(use) {
					if(wi_string_case_insensitive_compare(use, WI_STR("required")) != 0 &&
					   wi_string_case_insensitive_compare(use, WI_STR("optional")) != 0) {
						wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
							WI_STR("Parameter \"%@\" in message \"%@\" has an invalid \"use\" (\"%@\")"),
							collection_name, message->name, use);
						
						return NULL;
					}

					required = (wi_string_case_insensitive_compare(use, WI_STR("required")) == 0);
				}
				
				enumerator = wi_array_data_enumerator(collection->fields);
				
				while((field = wi_enumerator_next_data(enumerator))) {
					parameter = _wi_p7_spec_parameter_with_field(p7_spec, message, field);
					
					if(!parameter)
						return NULL;

					if(wi_dictionary_data_for_key(message->parameters_name, parameter->field->name)) {
						wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
							WI_STR("Message \"%@\" has a duplicate field \"%@\""),
							message->name, parameter->field->name);
						
						return NULL;
					}
					
					wi_mutable_dictionary_set_data_for_key(message->parameters_name, parameter, parameter->field->name);
					wi_mutable_dictionary_set_data_for_key(message->parameters_id, parameter, (void *) parameter->field->id);
					
					parameter->required = required;
					
					if(parameter->required)
						message->required_parameters++;
				}
			}
			else {
				wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
					WI_STR("Parameter in message \"%@\" has no \"field\" or \"collection\""),
					message->name);
				
				return NULL;
			}
		}
	}
	
	return message;
}



static void _wi_p7_spec_message_dealloc(wi_runtime_instance_t *instance) {
	wi_p7_spec_message_t		*message = instance;
	
	wi_release(message->name);
	wi_release(message->parameters);
	wi_release(message->parameters_name);
	wi_release(message->parameters_id);
}



static wi_string_t * _wi_p7_spec_message_description(wi_runtime_instance_t *instance) {
	wi_p7_spec_message_t		*message = instance;
	
	return wi_string_with_format(WI_STR("<%@ %p>{name = %@, id = %lu, parameters = %@}"),
        wi_runtime_class_name(message),
		message,
		message->name,
		message->id,
		message->parameters_name);
}



#pragma mark -

wi_runtime_id_t wi_p7_spec_parameter_runtime_id(void) {
	return _wi_p7_spec_parameter_runtime_id;
}



#pragma mark -

wi_string_t * wi_p7_spec_message_name(wi_p7_spec_message_t *message) {
	return message->name;
}



wi_uinteger_t wi_p7_spec_message_id(wi_p7_spec_message_t *message) {
	return message->id;
}



wi_array_t * wi_p7_spec_message_parameters(wi_p7_spec_message_t *message) {
	if(!message->parameters)
		message->parameters = wi_retain(wi_dictionary_all_values(message->parameters_id));
	
	return message->parameters;
}



#pragma mark -

static wi_p7_spec_parameter_t * _wi_p7_spec_parameter_with_node(wi_p7_spec_t *p7_spec, xmlNodePtr node, wi_p7_spec_message_t *message) {
	wi_p7_spec_parameter_t	*parameter;
	wi_string_t				*field, *use;

    parameter = wi_autorelease(wi_runtime_create_instance(_wi_p7_spec_parameter_runtime_id, sizeof(wi_p7_spec_parameter_t)));
	field = wi_xml_node_attribute_with_name(node, WI_STR("field"));

	if(!field) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
			WI_STR("Parameter in message \"%@\" has no \"field\""),
			message->name);
		
		return NULL;
	}
	
	parameter->field = wi_retain(wi_dictionary_data_for_key(p7_spec->fields_name, field));
	
	if(!parameter->field && _wi_p7_spec_builtin_spec)
		parameter->field = wi_retain(wi_dictionary_data_for_key(_wi_p7_spec_builtin_spec->fields_name, field));
	
	if(!parameter->field) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
			WI_STR("Parameter in message \"%@\" has an invalid \"field\" (\"%@\")"),
			message->name, field);
		
		return NULL;
	}
	
	use = wi_xml_node_attribute_with_name(node, WI_STR("use"));

	if(use) {
		if(wi_string_case_insensitive_compare(use, WI_STR("required")) != 0 &&
		   wi_string_case_insensitive_compare(use, WI_STR("optional")) != 0) {
			wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
				WI_STR("Parameter \"%@\" in message \"%@\" has an invalid \"use\" (\"%@\")"),
				parameter->field->name, message->name, use);
			
			return NULL;
		}

		parameter->required = (wi_string_case_insensitive_compare(use, WI_STR("required")) == 0);
	}

	return parameter;
}



static wi_p7_spec_parameter_t * _wi_p7_spec_parameter_with_field(wi_p7_spec_t *p7_spec, wi_p7_spec_message_t *message, wi_p7_spec_field_t *field) {
	wi_p7_spec_parameter_t	*parameter;

    parameter = wi_autorelease(wi_runtime_create_instance(_wi_p7_spec_parameter_runtime_id, sizeof(wi_p7_spec_parameter_t)));
	parameter->field = wi_retain(field);

	return parameter;
}



static void _wi_p7_spec_parameter_dealloc(wi_runtime_instance_t *instance) {
	wi_p7_spec_parameter_t		*parameter = instance;
	
	wi_release(parameter->field);
}



static wi_string_t * _wi_p7_spec_parameter_description(wi_runtime_instance_t *instance) {
	wi_p7_spec_parameter_t		*parameter = instance;
	
	return wi_string_with_format(WI_STR("<%@ %p>{field = %@, required = %@}"),
        wi_runtime_class_name(parameter),
		parameter,
		parameter->field,
		parameter->required ? WI_STR("true") : WI_STR("false"));
}



#pragma mark -

wi_p7_spec_field_t * wi_p7_spec_parameter_field(wi_p7_spec_parameter_t *parameter) {
	return parameter->field;
}



wi_boolean_t wi_p7_spec_parameter_required(wi_p7_spec_parameter_t *parameter) {
	return parameter->required;
}



#pragma mark -

static _wi_p7_spec_transaction_t * _wi_p7_spec_transaction_with_node(wi_p7_spec_t *p7_spec, xmlNodePtr node) {
	wi_string_t					*message, *originator, *use;
	_wi_p7_spec_transaction_t	*transaction;

    transaction = wi_autorelease(wi_runtime_create_instance(_wi_p7_spec_transaction_runtime_id, sizeof(_wi_p7_spec_transaction_t)));
	message = wi_xml_node_attribute_with_name(node, WI_STR("message"));
	
	if(!message) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
			WI_STR("Transaction has no \"message\""));
		
		return NULL;
	}

	transaction->message = wi_retain(wi_dictionary_data_for_key(p7_spec->messages_name, message));

	if(!transaction->message && _wi_p7_spec_builtin_spec)
		transaction->message = wi_retain(wi_dictionary_data_for_key(_wi_p7_spec_builtin_spec->messages_name, message));
	
	if(!transaction->message) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
			WI_STR("Transaction has an invalid \"message\" (\"%@\")"),
			message);
		
		return NULL;
	}
	
	originator = wi_xml_node_attribute_with_name(node, WI_STR("originator"));

	if(!originator) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
			WI_STR("Transaction \"%@\" has no \"originator\""),
			transaction->message->name);
		
		return NULL;
	}

	if(wi_string_case_insensitive_compare(originator, WI_STR("client")) != 0 &&
	   wi_string_case_insensitive_compare(originator, WI_STR("server")) != 0 &&
	   wi_string_case_insensitive_compare(originator, WI_STR("both")) != 0) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
			WI_STR("Transaction \"%@\" has an invalid \"originator\" (\"%@\")"),
			transaction->message->name, originator);
		
		return NULL;
	}

	if(wi_string_case_insensitive_compare(originator, WI_STR("client")) == 0)
		transaction->originator = WI_P7_CLIENT;
	else if(wi_string_case_insensitive_compare(originator, WI_STR("server")) == 0)
		transaction->originator = WI_P7_SERVER;
	else
		transaction->originator = WI_P7_BOTH;
	
	use = wi_xml_node_attribute_with_name(node, WI_STR("use"));

	if(use) {
		if(wi_string_case_insensitive_compare(use, WI_STR("required")) != 0 &&
		   wi_string_case_insensitive_compare(use, WI_STR("optional"))) {
			wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
				WI_STR("Transaction \"%@\" has an invalid \"use\" (\"%@\")"),
				transaction->message->name, use);
			
			return NULL;
		}

		transaction->required = (wi_string_case_insensitive_compare(use, WI_STR("required")) == 0);
	}

	transaction->andor = wi_retain(_wi_p7_spec_andor(_WI_P7_SPEC_AND, p7_spec, node, transaction));
	
	if(!transaction->andor)
		return NULL;
	
	return transaction;
}



static void _wi_p7_spec_transaction_dealloc(wi_runtime_instance_t *instance) {
	_wi_p7_spec_transaction_t		*transaction = instance;
	
	wi_release(transaction->message);
	wi_release(transaction->andor);
}



static wi_string_t * _wi_p7_spec_transaction_description(wi_runtime_instance_t *instance) {
	_wi_p7_spec_transaction_t		*transaction = instance;
	
	return wi_string_with_format(WI_STR("<%@ %p>{message = %@, required = %@, andor = %@}"),
        wi_runtime_class_name(transaction),
		transaction,
		transaction->message ? transaction->message->name : NULL,
		transaction->required ? WI_STR("true") : WI_STR("false"),
		transaction->andor);
}



#pragma mark -

static _wi_p7_spec_broadcast_t * _wi_p7_spec_broadcast_with_node(wi_p7_spec_t *p7_spec, xmlNodePtr node) {
	xmlNodePtr					broadcast_node, next_node;
	wi_string_t					*message;
	_wi_p7_spec_broadcast_t		*broadcast;

    broadcast = wi_autorelease(wi_runtime_create_instance(_wi_p7_spec_broadcast_runtime_id, sizeof(_wi_p7_spec_broadcast_t)));
	message = wi_xml_node_attribute_with_name(node, WI_STR("message"));
	
	if(!message) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
			WI_STR("Broadcast has no \"message\""));
		
		return NULL;
	}

	broadcast->message = wi_retain(wi_dictionary_data_for_key(p7_spec->messages_name, message));

	if(!broadcast->message && _wi_p7_spec_builtin_spec)
		broadcast->message = wi_retain(wi_dictionary_data_for_key(_wi_p7_spec_builtin_spec->messages_name, message));
	
	if(!broadcast->message) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
			WI_STR("Broadcast has an invalid \"message\" (\"%@\")"),
			message);
		
		return NULL;
	}
	
	for(broadcast_node = node->children; broadcast_node != NULL; broadcast_node = next_node) {
		next_node = broadcast_node->next;
		
		if(broadcast_node->type == XML_ELEMENT_NODE) {
			if(strcmp((const char *) broadcast_node->name, "documentation") == 0) {
				xmlUnlinkNode(broadcast_node);
				xmlFreeNode(broadcast_node);
				
				continue;
			}
		}
	}
	
	return broadcast;
}



static void _wi_p7_spec_broadcast_dealloc(wi_runtime_instance_t *instance) {
	_wi_p7_spec_broadcast_t		*broadcast = instance;
	
	wi_release(broadcast->message);
}



static wi_string_t * _wi_p7_spec_broadcast_description(wi_runtime_instance_t *instance) {
	_wi_p7_spec_broadcast_t		*broadcast = instance;
	
	return wi_string_with_format(WI_STR("<%@ %p>{message = %@}"),
        wi_runtime_class_name(broadcast),
		broadcast,
		broadcast->message ? broadcast->message->name : NULL);
}



#pragma mark -

static _wi_p7_spec_andor_t * _wi_p7_spec_andor(_wi_p7_spec_andor_type_t type, wi_p7_spec_t *p7_spec, xmlNodePtr node, _wi_p7_spec_transaction_t *transaction) {
	xmlNodePtr				andor_node, next_node;
	_wi_p7_spec_andor_t		*andor, *child_andor;
	_wi_p7_spec_reply_t		*reply;

    andor						= wi_autorelease(wi_runtime_create_instance(_wi_p7_spec_andor_runtime_id, sizeof(_wi_p7_spec_andor_t)));
	andor->type					= type;
	andor->children				= wi_array_init_with_capacity(wi_mutable_array_alloc(), 10);
	andor->replies_array		= wi_array_init_with_capacity(wi_mutable_array_alloc(), 10);
	andor->replies_dictionary	= wi_dictionary_init_with_capacity(wi_mutable_dictionary_alloc(), 10);

	for(andor_node = node->children; andor_node != NULL; andor_node = next_node) {
		next_node = andor_node->next;
		
		if(andor_node->type == XML_ELEMENT_NODE) {
			if(strcmp((const char *) andor_node->name, "documentation") == 0) {
				xmlUnlinkNode(andor_node);
				xmlFreeNode(andor_node);
				
				continue;
			}
			
			if(strcmp((const char *) andor_node->name, "reply") == 0) {
				reply = _wi_p7_spec_reply_with_node(p7_spec, andor_node, transaction);

				if(!reply)
					return NULL;
				
				if(wi_dictionary_data_for_key(andor->replies_dictionary, reply->message->name)) {
					wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
						WI_STR("Transaction \"%@\" has a duplicate reply \"%@\""),
						transaction->message->name, reply->message->name);
					
					return NULL;
				}
				
				wi_mutable_array_add_data(andor->replies_array, reply);
				wi_mutable_dictionary_set_data_for_key(andor->replies_dictionary, reply, reply->message->name);
			} else {
				if(strcmp((const char *) andor_node->name, "and") == 0) {
					child_andor = _wi_p7_spec_andor(_WI_P7_SPEC_AND, p7_spec, andor_node, transaction);
				}
				else if(strcmp((const char *) andor_node->name, "or") == 0) {
					child_andor = _wi_p7_spec_andor(_WI_P7_SPEC_OR, p7_spec, andor_node, transaction);
				}
				else {
					wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
						WI_STR("Expected \"and\" or \"or\" node but got \"%s\""),
						andor_node->name);
					
					return false;
				}
				
				if(!child_andor)
					return NULL;
				
				wi_mutable_array_add_data(andor->children, child_andor);
			}
		}
	}
	
	return andor;
}



static void _wi_p7_spec_andor_dealloc(wi_runtime_instance_t *instance) {
	_wi_p7_spec_andor_t		*andor = instance;
	
	wi_release(andor->children);
	wi_release(andor->replies_dictionary);
	wi_release(andor->replies_array);
}



static wi_string_t * _wi_p7_spec_andor_description(wi_runtime_instance_t *instance) {
	_wi_p7_spec_andor_t		*andor = instance;
	
	return wi_string_with_format(WI_STR("<%@ %p>{type = %@, replies = %@, children = %@}"),
        wi_runtime_class_name(andor),
		andor,
		andor->type == _WI_P7_SPEC_AND ? WI_STR("and") : WI_STR("or"),
		andor->replies_array,
		andor->children);
}



#pragma mark -

static _wi_p7_spec_reply_t * _wi_p7_spec_reply_with_node(wi_p7_spec_t *p7_spec, xmlNodePtr node, _wi_p7_spec_transaction_t *transaction) {
	_wi_p7_spec_reply_t		*reply;
	wi_string_t				*message, *use, *count;

    reply = wi_autorelease(wi_runtime_create_instance(_wi_p7_spec_reply_runtime_id, sizeof(_wi_p7_spec_reply_t)));
	message = wi_xml_node_attribute_with_name(node, WI_STR("message"));

	if(!message) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
			WI_STR("Reply in transaction \"%@\" has no \"message\""),
			transaction->message->name);
		
		return NULL;
	}
	
	reply->message = wi_retain(wi_dictionary_data_for_key(p7_spec->messages_name, message));
	
	if(!reply->message && _wi_p7_spec_builtin_spec)
		reply->message = wi_retain(wi_dictionary_data_for_key(_wi_p7_spec_builtin_spec->messages_name, message));
	
	if(!reply->message) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
			WI_STR("Reply in transaction \"%@\" has an invalid \"message\" (\"%@\")"),
			transaction->message->name, message);
		
		return NULL;
	}

	use = wi_xml_node_attribute_with_name(node, WI_STR("use"));

	if(use) {
		if(wi_string_case_insensitive_compare(use, WI_STR("required")) != 0 &&
		   wi_string_case_insensitive_compare(use, WI_STR("optional"))) {
			wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
				WI_STR("Reply \"%@\" in transaction \"%@\" has an invalid \"use\" (\"%@\")"),
				reply->message->name, transaction->message->name, use);
		
			return NULL;
		}

		reply->required = (wi_string_case_insensitive_compare(use, WI_STR("required")) == 0);
	}
	
	count = wi_xml_node_attribute_with_name(node, WI_STR("count"));
	
	if(!count) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
			WI_STR("Reply in transaction \"%@\" has no \"count\""),
			transaction->message->name);
		
		return NULL;
	}
	
	if(wi_string_compare(count, WI_STR("?")) == 0)
		reply->count = _WI_P7_SPEC_REPLY_ONE_OR_ZERO;
	else if(wi_string_compare(count, WI_STR("*")) == 0)
		reply->count = _WI_P7_SPEC_REPLY_ZERO_OR_MORE;
	else if(wi_string_compare(count, WI_STR("+")) == 0)
		reply->count = _WI_P7_SPEC_REPLY_ONE_OR_MORE;
	else
		reply->count = wi_string_integer(count);
	
	if(reply->count == 0) {
		wi_error_set_libwired_error_with_format(WI_ERROR_P7_INVALIDSPEC,
			WI_STR("Reply in transaction \"%@\" has an invalid \"count\" (\"%@\")"),
			transaction->message->name, count);
		
		return NULL;
	}

	return reply;
}



static wi_string_t * _wi_p7_spec_reply_count(_wi_p7_spec_reply_t *reply) {
	if(reply->count == _WI_P7_SPEC_REPLY_ONE_OR_ZERO)
		return WI_STR("one or zero times");
	if(reply->count == _WI_P7_SPEC_REPLY_ZERO_OR_MORE)
		return WI_STR("zero or more times");
	else if(reply->count == _WI_P7_SPEC_REPLY_ONE_OR_MORE)
		return WI_STR("one or more times");

	return wi_string_with_format(WI_STR("%lu %@"), reply->count, (reply->count == 1) ? WI_STR("time") : WI_STR("times"));
}



static void _wi_p7_spec_reply_dealloc(wi_runtime_instance_t *instance) {
	_wi_p7_spec_reply_t		*reply = instance;
	
	wi_release(reply->message);
}



static wi_string_t * _wi_p7_spec_reply_description(wi_runtime_instance_t *instance) {
	_wi_p7_spec_reply_t		*reply = instance;
	
	return wi_string_with_format(WI_STR("<%@ %p>{message = %@, count = %lu, required = %@}"),
        wi_runtime_class_name(reply),
		reply,
		reply->message ? reply->message->name : NULL,
		reply->count,
		reply->required ? WI_STR("true") : WI_STR("false"));
}

#endif
