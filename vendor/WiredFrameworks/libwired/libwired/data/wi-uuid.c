/* $Id$ */

/*
 *  Copyright (c) 2006-2009 Axel Andersson
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

/*
 * Copyright (C) 1996, 1997, 1998, 1999 Theodore Ts'o.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, and the entire permission notice in its entirety,
 *    including the disclaimer of warranties.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote
 *    products derived from this software without specific prior
 *    written permission.
 * 
 * THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, ALL OF
 * WHICH ARE HEREBY DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
 * OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
 * BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF NOT ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */

#include "config.h"

#include <sys/types.h>
#include <sys/socket.h>
#include <sys/ioctl.h>

#ifdef HAVE_SYS_SOCKIO_H
#include <sys/sockio.h>
#endif

#include <unistd.h>
#include <stdlib.h>
#include <fcntl.h>
#include <string.h>
#include <netinet/in.h>
#include <net/if.h>
#include <inttypes.h>

#ifdef HAVE_NET_IF_DL_H
#include <net/if_dl.h>
#endif

#include <wired/wi-compat.h>
#include <wired/wi-macros.h>
#include <wired/wi-lock.h>
#include <wired/wi-pool.h>
#include <wired/wi-private.h>
#include <wired/wi-runtime.h>
#include <wired/wi-string.h>
#include <wired/wi-uuid.h>

#define _WI_UUID_NODE_SIZE				6
#define _WI_UUID_CLOCK_MAX_ADJUSTMENT	10

#ifdef HAVE_STRUCT_SOCKADDR_SA_LEN
#define _WI_UUID_IFREQ_SIZE(i) \
	WI_MAX(sizeof(struct ifreq), sizeof((i).ifr_name) + (i).ifr_addr.sa_len)
#else
#define _WI_UUID_IFREQ_SIZE(i) \
	sizeof(struct ifreq)
#endif


struct _wi_uuid {
	wi_runtime_base_t					base;
	
	unsigned char						buffer[WI_UUID_BUFFER_SIZE];
	
	wi_string_t							*string;

	uint32_t							time_low;
	uint16_t							time_mid;
	uint16_t							time_hi_and_version;
	uint16_t							clock_seq;
	uint8_t								node[_WI_UUID_NODE_SIZE];
};


static void								_wi_uuid_dealloc(wi_runtime_instance_t *);
static wi_boolean_t						_wi_uuid_is_equal(wi_runtime_instance_t *, wi_runtime_instance_t *);
static wi_hash_code_t					_wi_uuid_hash(wi_runtime_instance_t *);
static wi_string_t *					_wi_uuid_description(wi_runtime_instance_t *);

static wi_string_t *					_wi_uuid_string(wi_uuid_t *);
static void								_wi_uuid_pack_buffer(wi_uuid_t *);
static void								_wi_uuid_get_random_buffer(void *, size_t);
static wi_boolean_t						_wi_uuid_get_node(unsigned char *);
static void								_wi_uuid_get_clock(uint32_t *, uint32_t *, uint16_t *);


static wi_lock_t						*_wi_uuid_clock_lock;
static unsigned char					_wi_uuid_node[_WI_UUID_NODE_SIZE];

static wi_runtime_id_t					_wi_uuid_runtime_id = WI_RUNTIME_ID_NULL;
static wi_runtime_class_t				_wi_uuid_runtime_class = {
	"wi_uuid_t",
	_wi_uuid_dealloc,
	NULL,
	_wi_uuid_is_equal,
	_wi_uuid_description,
	_wi_uuid_hash
};



void wi_uuid_register(void) {
	_wi_uuid_runtime_id = wi_runtime_register_class(&_wi_uuid_runtime_class);
}



void wi_uuid_initialize(void) {
	_wi_uuid_clock_lock = wi_lock_init(wi_lock_alloc());
	
	if(!_wi_uuid_get_node(_wi_uuid_node)) {
		_wi_uuid_get_random_buffer(_wi_uuid_node, sizeof(_wi_uuid_node));
		
		_wi_uuid_node[0] |= 0x01;
	}
}



#pragma mark -

wi_runtime_id_t wi_uuid_runtime_id(void) {
	return _wi_uuid_runtime_id;
}



#pragma mark -

wi_uuid_t * wi_uuid(void) {
	return wi_autorelease(wi_uuid_init(wi_uuid_alloc()));
}



wi_uuid_t * wi_uuid_with_string(wi_string_t *string) {
	return wi_autorelease(wi_uuid_init_with_string(wi_uuid_alloc(), string));
}



wi_uuid_t * wi_uuid_with_bytes(const void *bytes) {
	return wi_autorelease(wi_uuid_init_with_bytes(wi_uuid_alloc(), bytes));
}



#pragma mark -

wi_uuid_t * wi_uuid_alloc(void) {
	return wi_runtime_create_instance_with_options(_wi_uuid_runtime_id, sizeof(wi_uuid_t), WI_RUNTIME_OPTION_IMMUTABLE);
}



wi_uuid_t * wi_uuid_init(wi_uuid_t *uuid) {
	return wi_uuid_init_from_random_data(uuid);
}



wi_uuid_t * wi_uuid_init_from_random_data(wi_uuid_t *uuid) {
	unsigned char		buffer[WI_UUID_BUFFER_SIZE];
	
	_wi_uuid_get_random_buffer(buffer, sizeof(buffer));
	
	uuid = wi_uuid_init_with_bytes(uuid, buffer);

	uuid->time_hi_and_version	= (uuid->time_hi_and_version & 0x0FFF) | 0x4000;
	uuid->clock_seq				= (uuid->clock_seq & 0x3FFF) | 0x8000;
	
	_wi_uuid_pack_buffer(uuid);
	
	return uuid;
}



wi_uuid_t * wi_uuid_init_from_time(wi_uuid_t *uuid) {
	uint32_t		time_mid, time_low;
	uint16_t		clock_seq;
	
	_wi_uuid_get_clock(&time_mid, &time_low, &clock_seq);

	uuid->time_low				= time_low;
	uuid->time_mid				= (uint16_t) time_mid;
	uuid->time_hi_and_version	= ((time_mid >> 16) & 0x0FFFF) | 0x1000;
	uuid->clock_seq				= clock_seq | 0x8000;
	
	memcpy(uuid->node, _wi_uuid_node, sizeof(uuid->node));

	_wi_uuid_pack_buffer(uuid);

	return uuid;
}



wi_uuid_t * wi_uuid_init_with_string(wi_uuid_t *uuid, wi_string_t *string) {
	uint32_t		time_low, time_mid, time_hi_and_version, clock_seq_high, clock_seq_low;
	uint32_t		node[6];
	
	if(sscanf(wi_string_cstring(string), "%08X-%04X-%04X-%02X%02X-%02X%02X%02X%02X%02X%02X",
			  &time_low,
			  &time_mid,
			  &time_hi_and_version,
			  &clock_seq_high,
			  &clock_seq_low,
			  &node[0],
			  &node[1],
			  &node[2],
			  &node[3],
			  &node[4],
			  &node[5]) != 11) {
		wi_release(uuid);
		
		return NULL;
	}
	
	uuid->time_low				= time_low;
	uuid->time_mid				= (uint16_t) time_mid;
	uuid->time_hi_and_version	= (uint16_t) time_hi_and_version;
	uuid->clock_seq				= (clock_seq_high << 8) + (clock_seq_low & 0xFF);
	uuid->node[0]				= (uint8_t) node[0];
	uuid->node[1]				= (uint8_t) node[1];
	uuid->node[2]				= (uint8_t) node[2];
	uuid->node[3]				= (uint8_t) node[3];
	uuid->node[4]				= (uint8_t) node[4];
	uuid->node[5]				= (uint8_t) node[5];
	
	_wi_uuid_pack_buffer(uuid);
	
	return uuid;
}



wi_uuid_t * wi_uuid_init_with_bytes(wi_uuid_t *uuid, const void *bytes) {
	const unsigned char		*p;
	uint32_t				i;
	
	memcpy(uuid->buffer, bytes, WI_UUID_BUFFER_SIZE);
	
	p = bytes;
	
	i = *p++;
	i = (i << 8) | *p++;
	i = (i << 8) | *p++;
	i = (i << 8) | *p++;
	uuid->time_low = i;
	
	i = *p++;
	i = (i << 8) | *p++;
	uuid->time_mid = i;
	
	i = *p++;
	i = (i << 8) | *p++;
	uuid->time_hi_and_version = i;

	i = *p++;
	i = (i << 8) | *p++;
	uuid->clock_seq = i;

	memcpy(uuid->node, p, sizeof(uuid->node));

	return uuid;
}



static void _wi_uuid_dealloc(wi_runtime_instance_t *instance) {
	wi_uuid_t		*uuid = instance;
	
	wi_release(uuid->string);
}



static wi_boolean_t _wi_uuid_is_equal(wi_runtime_instance_t *instance1, wi_runtime_instance_t *instance2) {
	wi_uuid_t		*uuid1 = instance1;
	wi_uuid_t		*uuid2 = instance2;
	
	return (memcmp(uuid1->buffer, uuid2->buffer, WI_UUID_BUFFER_SIZE) == 0);
}



static wi_string_t * _wi_uuid_description(wi_runtime_instance_t *instance) {
	wi_uuid_t		*uuid = instance;

	return wi_string_with_format(WI_STR("<%@ %p>{string = %@}"),
		wi_runtime_class_name(uuid),
		uuid,
		_wi_uuid_string(uuid));
}



static wi_hash_code_t _wi_uuid_hash(wi_runtime_instance_t *instance) {
	wi_uuid_t		*uuid = instance;
	
	return wi_hash(_wi_uuid_string(uuid));
}



#pragma mark -

static wi_string_t * _wi_uuid_string(wi_uuid_t *uuid) {
	if(!uuid->string) {
		uuid->string = wi_string_init_with_format(wi_string_alloc(), WI_STR("%08X-%04X-%04X-%02X%02X-%02X%02X%02X%02X%02X%02X"),
			uuid->time_low,
			uuid->time_mid,
			uuid->time_hi_and_version,
			uuid->clock_seq >> 8,
			uuid->clock_seq & 0xFF,
			uuid->node[0],
			uuid->node[1],
			uuid->node[2],
			uuid->node[3],
			uuid->node[4],
			uuid->node[5]);
	}
	
	return uuid->string;
}



static void _wi_uuid_pack_buffer(wi_uuid_t *uuid) {
	unsigned char		*p;
	uint32_t			i;
	
	p = uuid->buffer;
	
    i = uuid->time_low;
    p[3] = (unsigned char) i;
    i >>= 8;
    p[2] = (unsigned char) i;
    i >>= 8;
    p[1] = (unsigned char) i;
    i >>= 8;
    p[0] = (unsigned char) i;

    i = uuid->time_mid;
    p[5] = (unsigned char) i;
    i >>= 8;
    p[4] = (unsigned char) i;

    i = uuid->time_hi_and_version;
    p[7] = (unsigned char) i;
    i >>= 8;
    p[6] = (unsigned char) i;

    i = uuid->clock_seq;
    p[9] = (unsigned char) i;
    i >>= 8;
    p[8] = (unsigned char) i;

    memcpy(p + 10, uuid->node, _WI_UUID_NODE_SIZE);
}



static void _wi_uuid_get_random_buffer(void *buffer, size_t size) {
	wi_data_t			*data;
	
	data = wi_data_init_with_random_bytes(wi_data_alloc(), size);
	memcpy(buffer, wi_data_bytes(data), size);
	wi_release(data);
}



static wi_boolean_t _wi_uuid_get_node(unsigned char *node) {
	struct ifconf		ifc;
	struct ifreq		ifr, *ifrp;
#if !defined(SIOCGIFHWADDR) && !defined(SIOCGENADDR) && defined(HAVE_NET_IF_DL_H)
	struct sockaddr_dl	*sdlp;
#endif
	char				buffer[1024];
	unsigned char		*a;
	int					sd = -1, i;
	wi_boolean_t		result = false;

#if !defined(SIOCGIFHWADDR) && !defined(SIOCGENADDR) && !defined(HAVE_NET_IF_DL_H)
	goto end;
#endif
	
	sd = socket(AF_INET, SOCK_DGRAM, IPPROTO_IP);
	
	if(sd < 0)
		goto end;

	memset(buffer, 0, sizeof(buffer));
	ifc.ifc_len = sizeof(buffer);
	ifc.ifc_buf = buffer;

	if(ioctl(sd, SIOCGIFCONF, (char *) &ifc) < 0)
		goto end;

	for(i = 0; i < ifc.ifc_len; i += _WI_UUID_IFREQ_SIZE(*ifrp)) {
		ifrp = (struct ifreq *) ((char *) ifc.ifc_buf + i);

		wi_strlcpy(ifr.ifr_name, ifrp->ifr_name, IFNAMSIZ);

#if defined(SIOCGIFHWADDR)
		if(ioctl(sd, SIOCGIFHWADDR, &ifr) < 0)
			continue;
		
		a = (unsigned char *) &ifr.ifr_hwaddr.sa_data;
#elif defined(SIOCGENADDR)
		if(ioctl(sd, SIOCGENADDR, &ifr) < 0)
			continue;
		
		a = (unsigned char *) ifr.ifr_enaddr;
#elif defined(HAVE_NET_IF_DL_H)
		sdlp = (struct sockaddr_dl *) &ifrp->ifr_addr;
		
		if(sdlp->sdl_family != AF_LINK || sdlp->sdl_alen != _WI_UUID_NODE_SIZE)
			continue;

		a = (unsigned char *) &sdlp->sdl_data[sdlp->sdl_nlen];
#endif
		
		if(!a[0] && !a[1] && !a[2] && !a[3] && !a[4] && !a[5])
			continue;

		memcpy(_wi_uuid_node, a, sizeof(_wi_uuid_node));
		
		result = true;
		
		goto end;
	}

end:
	if(sd >= 0)
		close(sd);
	
	return result;
}



static void _wi_uuid_get_clock(uint32_t *clock_high, uint32_t *clock_low, uint16_t *clock_seq) {
	static struct timeval	lasttv;
	static uint32_t			adjustment;
	static uint16_t			sequence;
	uint64_t				clock_reg;
	struct timeval 			tv;
	wi_boolean_t			tryagain;
	
	wi_lock_lock(_wi_uuid_clock_lock);
	
	do {
		tryagain = false;
		
		gettimeofday(&tv, 0);
		
		if(lasttv.tv_sec == 0 && lasttv.tv_usec == 0) {
			_wi_uuid_get_random_buffer(&sequence, sizeof(sequence));
			sequence &= 0x3FFF;
			lasttv = tv;
			lasttv.tv_sec--;
		}
		
		if(tv.tv_sec < lasttv.tv_sec || (tv.tv_sec == lasttv.tv_sec && tv.tv_usec < lasttv.tv_usec)) {
			sequence = (sequence + 1) & 0x3FFF;
			adjustment = 0;
			lasttv = tv;
		}
		else if(tv.tv_sec == lasttv.tv_sec && tv.tv_usec == lasttv.tv_usec) {
			if(adjustment >= _WI_UUID_CLOCK_MAX_ADJUSTMENT) {
				tryagain = true;

				continue;
			}
			
			adjustment++;
		} else {
			adjustment = 0;
			lasttv = tv;
		}
	} while(tryagain);

	wi_lock_unlock(_wi_uuid_clock_lock);
		
	clock_reg	= (tv.tv_usec * 10) + adjustment;
	clock_reg	+= ((uint64_t) tv.tv_sec) * 10000000;
	clock_reg	+= (((uint64_t) 0x01B21DD2) << 32) + 0x13814000;

	*clock_high	= clock_reg >> 32;
	*clock_low	= clock_reg;
	*clock_seq	= sequence;
}



#pragma mark -

wi_string_t * wi_uuid_string(wi_uuid_t *uuid) {
	return _wi_uuid_string(uuid);
}



void wi_uuid_get_bytes(wi_uuid_t *uuid, void *bytes) {
	memcpy(bytes, uuid->buffer, WI_UUID_BUFFER_SIZE);
}
