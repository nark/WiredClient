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

#ifndef WI_P7_PRIVATE_H
#define WI_P7_PRIVATE_H 1

#include <wired/wi-base.h>
#include <wired/wi-p7-message.h>
#include <libxml/tree.h>

#define WI_P7_MESSAGE_BINARY_HEADER_SIZE	4


struct _wi_p7_message {
	wi_runtime_base_t						base;
	
	wi_p7_spec_t							*spec;
	
	wi_string_t								*name;

	unsigned char							*binary_buffer;
	uint32_t								binary_capacity;
	uint32_t								binary_size;
	uint32_t								binary_id;
	
	xmlChar									*xml_buffer;
	int										xml_length;
	wi_mutable_string_t						*xml_string;
};


wi_p7_message_t *							wi_p7_message_init(wi_p7_message_t *, wi_p7_spec_t *);
WI_EXPORT void								wi_p7_message_serialize(wi_p7_message_t *, wi_p7_serialization_t);
WI_EXPORT void								wi_p7_message_deserialize(wi_p7_message_t *, wi_p7_serialization_t);

WI_EXPORT wi_boolean_t						wi_p7_spec_is_compatible_with_protocol(wi_p7_spec_t *, wi_string_t *, wi_string_t *);

#endif /* WI_P7_PRIVATE_H */
