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

#include <fcntl.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>

#ifdef HAVE_OPENSSL_SHA_H
#include <openssl/rand.h>
#endif

#include <wired/wi-private.h>
#include <wired/wi-random.h>

#ifdef HAVE_SRANDOM
#define _WI_DATA_SRANDOM(n)				srandom((n))
#define _WI_DATA_RANDOM()				random()
#else
#define _WI_DATA_SRANDOM(n)				srand(n)
#define _WI_DATA_RANDOM()				rand()
#endif


static int								_wi_data_random_fd;


void wi_random_register(void) {
}



void wi_random_initialize(void) {
	struct timeval		tv;
	wi_uinteger_t		i;
	
	_wi_data_random_fd = open("/dev/urandom", O_RDONLY);
	
	if(_wi_data_random_fd < 0)
		_wi_data_random_fd = open("/dev/random", O_RDONLY | O_NONBLOCK);
	
	gettimeofday(&tv, NULL);
	
	_WI_DATA_SRANDOM((getpid() << 16) ^ getuid() ^ tv.tv_sec ^ tv.tv_usec);
	
	for(i = (tv.tv_sec ^ tv.tv_usec) & 0x1F; i > 0; i--)
		_WI_DATA_RANDOM();
}



#pragma mark -

void wi_random_get_bytes(void *buffer, wi_uinteger_t length) {
#ifndef HAVE_OPENSSL_SHA_H
	unsigned char		*p;
	uint32_t			i;
#endif
	
#ifdef HAVE_OPENSSL_SHA_H
	RAND_bytes(buffer, length);
#else
	if(_wi_data_random_fd >= 0)
		read(_wi_data_random_fd, buffer, length);
	else
		memset(buffer, 0, length);
	
	for(p = buffer, i = 0; i < length; i++)
		*p++ ^= (_WI_DATA_RANDOM() >> 7) & 0xFF;
#endif
}
