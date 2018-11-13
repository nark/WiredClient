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

#include <wired/wi-data.h>
#include <wired/wi-digest.h>
#include <wired/wi-private.h>
#include <wired/wi-string.h>
#include <wired/wi-system.h>

#if defined(HAVE_OPENSSL_SHA_H) || defined(HAVE_COMMONCRYPTO_COMMONDIGEST_H)

#ifdef HAVE_COMMONCRYPTO_COMMONDIGEST_H
#define WI_DIGEST_COMMONCRYPTO			1
#else
#define WI_DIGEST_OPENSSL				1
#endif

#include <string.h>

#ifdef HAVE_OPENSSL_SHA_H
#include <openssl/md5.h>
#include <openssl/sha.h>
#endif

#ifdef HAVE_COMMONCRYPTO_COMMONDIGEST_H
#include <CommonCrypto/CommonDigest.h>
#endif


#define _WI_DIGEST_ASSERT_OPEN(digest) \
	WI_ASSERT(!(digest)->closed, "%@ has been closed", (digest))

#define _WI_DIGEST_ASSERT_CLOSED(digest) \
	WI_ASSERT((digest)->closed, "%@ is open", (digest))


struct _wi_md5_ctx {
#ifdef WI_DIGEST_OPENSSL
	MD5_CTX								openssl_ctx;
#endif
	
#ifdef WI_DIGEST_COMMONCRYPTO
	CC_MD5_CTX							commondigest_ctx;
#endif
};
typedef struct _wi_md5_ctx				_wi_md5_ctx_t;


struct _wi_sha1_ctx {
#ifdef WI_DIGEST_OPENSSL
	SHA_CTX								openssl_ctx;
#endif
	
#ifdef WI_DIGEST_COMMONCRYPTO
	CC_SHA1_CTX							commondigest_ctx;
#endif
};
typedef struct _wi_sha1_ctx				_wi_sha1_ctx_t;


struct _wi_sha256_ctx {
#ifdef WI_DIGEST_OPENSSL
	SHA256_CTX							openssl_ctx;
#endif
	
#ifdef WI_DIGEST_COMMONCRYPTO
	CC_SHA256_CTX						commondigest_ctx;
#endif
};
typedef struct _wi_sha256_ctx			_wi_sha256_ctx_t;




struct _wi_md5 {
	wi_runtime_base_t					base;
	
	_wi_md5_ctx_t						ctx;
	
	unsigned char						buffer[WI_MD5_DIGEST_LENGTH];
	
	wi_boolean_t						closed;
};


struct _wi_sha1 {
	wi_runtime_base_t					base;
	
	_wi_sha1_ctx_t						ctx;
	
	unsigned char						buffer[WI_SHA1_DIGEST_LENGTH];
	
	wi_boolean_t						closed;
};


struct _wi_sha256 {
	wi_runtime_base_t					base;
	
	_wi_sha256_ctx_t					ctx;
	
	unsigned char						buffer[WI_SHA256_DIGEST_LENGTH];
	
	wi_boolean_t						closed;
};




static void								_wi_md5_ctx_init(_wi_md5_ctx_t *);
static void								_wi_md5_ctx_update(_wi_md5_ctx_t *, const void *, unsigned long);
static void								_wi_md5_ctx_final(unsigned char *, _wi_md5_ctx_t *);


static wi_runtime_id_t					_wi_md5_runtime_id = WI_RUNTIME_ID_NULL;
static wi_runtime_class_t				_wi_md5_runtime_class = {
	"wi_md5_t",
	NULL,
	NULL,
	NULL,
	NULL,
	NULL
};

static wi_runtime_id_t					_wi_sha1_runtime_id = WI_RUNTIME_ID_NULL;
static wi_runtime_class_t				_wi_sha1_runtime_class = {
	"wi_sha1_t",
	NULL,
	NULL,
	NULL,
	NULL,
	NULL
};

static wi_runtime_id_t					_wi_sha256_runtime_id = WI_RUNTIME_ID_NULL;
static wi_runtime_class_t				_wi_sha256_runtime_class = {
	"wi_sha256_t",
	NULL,
	NULL,
	NULL,
	NULL,
	NULL
};





void wi_digest_register(void) {
	_wi_md5_runtime_id		= wi_runtime_register_class(&_wi_md5_runtime_class);
	_wi_sha1_runtime_id		= wi_runtime_register_class(&_wi_sha1_runtime_class);
	_wi_sha256_runtime_id	= wi_runtime_register_class(&_wi_sha256_runtime_class);
}



void wi_digest_initialize(void) {
}



#pragma mark -

static void _wi_md5_ctx_init(_wi_md5_ctx_t *ctx) {
#ifdef WI_DIGEST_OPENSSL
	MD5_Init(&ctx->openssl_ctx);
#endif

#ifdef WI_DIGEST_COMMONCRYPTO
	CC_MD5_Init(&ctx->commondigest_ctx);
#endif
}



static void _wi_md5_ctx_update(_wi_md5_ctx_t *ctx, const void *data, unsigned long length) {
#ifdef WI_DIGEST_OPENSSL
	MD5_Update(&ctx->openssl_ctx, data, length);
#endif

#ifdef WI_DIGEST_COMMONCRYPTO
	CC_MD5_Update(&ctx->commondigest_ctx, data, length);
#endif
}



static void _wi_md5_ctx_final(unsigned char *buffer, _wi_md5_ctx_t *ctx) {
#ifdef WI_DIGEST_OPENSSL
	MD5_Final(buffer, &ctx->openssl_ctx);
#endif
	
#ifdef WI_DIGEST_COMMONCRYPTO
	CC_MD5_Final(buffer, &ctx->commondigest_ctx);
#endif
}



#pragma mark -

static void _wi_sha1_ctx_init(_wi_sha1_ctx_t *ctx) {
#ifdef WI_DIGEST_OPENSSL
	SHA1_Init(&ctx->openssl_ctx);
#endif

#ifdef WI_DIGEST_COMMONCRYPTO
	CC_SHA1_Init(&ctx->commondigest_ctx);
#endif
}



static void _wi_sha1_ctx_update(_wi_sha1_ctx_t *ctx, const void *data, unsigned long length) {
#ifdef WI_DIGEST_OPENSSL
	SHA1_Update(&ctx->openssl_ctx, data, length);
#endif

#ifdef WI_DIGEST_COMMONCRYPTO
	CC_SHA1_Update(&ctx->commondigest_ctx, data, length);
#endif
}



static void _wi_sha1_ctx_final(unsigned char *buffer, _wi_sha1_ctx_t *ctx) {
#ifdef WI_DIGEST_OPENSSL
	SHA1_Final(buffer, &ctx->openssl_ctx);
#endif

#ifdef WI_DIGEST_COMMONCRYPTO
	CC_SHA1_Final(buffer, &ctx->commondigest_ctx);
#endif
}



#pragma mark -

static void _wi_sha256_ctx_init(_wi_sha256_ctx_t *ctx) {
#ifdef WI_DIGEST_OPENSSL
	SHA256_Init(&ctx->openssl_ctx);
#endif

#ifdef WI_DIGEST_COMMONCRYPTO
	CC_SHA256_Init(&ctx->commondigest_ctx);
#endif
}



static void _wi_sha256_ctx_update(_wi_sha256_ctx_t *ctx, const void *data, unsigned long length) {
#ifdef WI_DIGEST_OPENSSL
	SHA256_Update(&ctx->openssl_ctx, data, length);
#endif

#ifdef WI_DIGEST_COMMONCRYPTO
	CC_SHA256_Update(&ctx->commondigest_ctx, data, length);
#endif
}



static void _wi_sha256_ctx_final(unsigned char *buffer, _wi_sha256_ctx_t *ctx) {
#ifdef WI_DIGEST_OPENSSL
	SHA256_Final(buffer, &ctx->openssl_ctx);
#endif

#ifdef WI_DIGEST_COMMONCRYPTO
	CC_SHA256_Final(buffer, &ctx->commondigest_ctx);
#endif
}





#pragma mark -

void wi_md5_digest(const void *data, wi_uinteger_t length, unsigned char *buffer) {
	_wi_md5_ctx_t		c;

	_wi_md5_ctx_init(&c);
	_wi_md5_ctx_update(&c, data, length);
	_wi_md5_ctx_final(buffer, &c);
}



wi_string_t * wi_md5_digest_string(wi_data_t *data) {
	wi_md5_t	*md5;
	
	md5 = wi_md5();
	
	wi_md5_update(md5, wi_data_bytes(data), wi_data_length(data));
	wi_md5_close(md5);
	
	return wi_md5_string(md5);
}



#pragma mark -

wi_md5_t * wi_md5(void) {
	return wi_autorelease(wi_md5_init(wi_md5_alloc()));
}



#pragma mark -

wi_md5_t * wi_md5_alloc(void) {
	return wi_runtime_create_instance_with_options(_wi_md5_runtime_id, sizeof(wi_md5_t), 0);
}



wi_md5_t * wi_md5_init(wi_md5_t *md5) {
	_wi_md5_ctx_init(&md5->ctx);
	
	return md5;
}



#pragma mark -

void wi_md5_update(wi_md5_t *md5, const void *data, wi_uinteger_t length) {
	_WI_DIGEST_ASSERT_OPEN(md5);
	
	_wi_md5_ctx_update(&md5->ctx, data, length);
}



void wi_md5_close(wi_md5_t *md5) {
	_WI_DIGEST_ASSERT_OPEN(md5);
	
	_wi_md5_ctx_final(md5->buffer, &md5->ctx);
	
	md5->closed = true;
}



#pragma mark -

void wi_md5_get_data(wi_md5_t *md5, unsigned char *buffer) {
	_WI_DIGEST_ASSERT_CLOSED(md5);
	
	memcpy(buffer, md5->buffer, sizeof(md5->buffer));
}



wi_data_t * wi_md5_data(wi_md5_t *md5) {
	_WI_DIGEST_ASSERT_CLOSED(md5);
	
	return wi_data_with_bytes(md5->buffer, sizeof(md5->buffer));
}



wi_string_t * wi_md5_string(wi_md5_t *md5) {
	static unsigned char	hex[] = "0123456789abcdef";
	char					md5_hex[sizeof(md5->buffer) * 2 + 1];
	wi_uinteger_t			i;

	_WI_DIGEST_ASSERT_CLOSED(md5);
	
	for(i = 0; i < sizeof(md5->buffer); i++) {
		md5_hex[i+i]	= hex[md5->buffer[i] >> 4];
		md5_hex[i+i+1]	= hex[md5->buffer[i] & 0x0F];
	}

	md5_hex[i+i] = '\0';

	return wi_string_with_cstring(md5_hex);
}



#pragma mark -

void wi_sha1_digest(const void *data, wi_uinteger_t length, unsigned char *buffer) {
	_wi_sha1_ctx_t			c;

	_wi_sha1_ctx_init(&c);
	_wi_sha1_ctx_update(&c, data, length);
	_wi_sha1_ctx_final(buffer, &c);
}



wi_string_t * wi_sha1_digest_string(wi_data_t *data) {
	wi_sha1_t	*sha1;
	
	sha1 = wi_sha1();
	
	wi_sha1_update(sha1, wi_data_bytes(data), wi_data_length(data));
	wi_sha1_close(sha1);
	
	return wi_sha1_string(sha1);
}



#pragma mark -

wi_sha1_t * wi_sha1(void) {
	return wi_autorelease(wi_sha1_init(wi_sha1_alloc()));
}



#pragma mark -

wi_sha1_t * wi_sha1_alloc(void) {
	return wi_runtime_create_instance_with_options(_wi_sha1_runtime_id, sizeof(wi_sha1_t), 0);
}



wi_sha1_t * wi_sha1_init(wi_sha1_t *sha1) {
	_wi_sha1_ctx_init(&sha1->ctx);
	
	return sha1;
}



#pragma mark -

void wi_sha1_update(wi_sha1_t *sha1, const void *data, wi_uinteger_t length) {
	_WI_DIGEST_ASSERT_OPEN(sha1);
	
	_wi_sha1_ctx_update(&sha1->ctx, data, length);
}



void wi_sha1_close(wi_sha1_t *sha1) {
	_WI_DIGEST_ASSERT_OPEN(sha1);
	
	_wi_sha1_ctx_final(sha1->buffer, &sha1->ctx);
	
	sha1->closed = true;
}



#pragma mark -

void wi_sha1_get_data(wi_sha1_t *sha1, unsigned char *buffer) {
	_WI_DIGEST_ASSERT_CLOSED(sha1);
	
	memcpy(buffer, sha1->buffer, sizeof(sha1->buffer));
}



wi_data_t * wi_sha1_data(wi_sha1_t *sha1) {
	_WI_DIGEST_ASSERT_CLOSED(sha1);
	
	return wi_data_with_bytes(sha1->buffer, sizeof(sha1->buffer));
}



wi_string_t * wi_sha1_string(wi_sha1_t *sha1) {
	static unsigned char	hex[] = "0123456789abcdef";
	char					sha1_hex[sizeof(sha1->buffer) * 2 + 1];
	wi_uinteger_t			i;

	_WI_DIGEST_ASSERT_CLOSED(sha1);
	
	for(i = 0; i < sizeof(sha1->buffer); i++) {
		sha1_hex[i+i]	= hex[sha1->buffer[i] >> 4];
		sha1_hex[i+i+1]	= hex[sha1->buffer[i] & 0x0F];
	}

	sha1_hex[i+i] = '\0';

	return wi_string_with_cstring(sha1_hex);
}



#pragma mark -

void wi_sha256_digest(const void *data, wi_uinteger_t length, unsigned char *buffer) {
	_wi_sha256_ctx_t 	c;

	_wi_sha256_ctx_init(&c);
	_wi_sha256_ctx_update(&c, data, length);
	_wi_sha256_ctx_final(buffer, &c);
}



wi_string_t * wi_sha256_digest_string(wi_data_t *data) {
	wi_sha256_t	*sha256;
	
	sha256 = wi_sha256();
	
	wi_sha256_update(sha256, wi_data_bytes(data), wi_data_length(data));
	wi_sha256_close(sha256);
	
	return wi_sha256_string(sha256);
}



#pragma mark -

wi_sha256_t * wi_sha256(void) {
	return wi_autorelease(wi_sha256_init(wi_sha256_alloc()));
}



#pragma mark -

wi_sha256_t * wi_sha256_alloc(void) {
	return wi_runtime_create_instance_with_options(_wi_sha256_runtime_id, sizeof(wi_sha256_t), 0);
}



wi_sha256_t * wi_sha256_init(wi_sha256_t *sha256) {
	_wi_sha256_ctx_init(&sha256->ctx);
	
	return sha256;
}



#pragma mark -

void wi_sha256_update(wi_sha256_t *sha256, const void *data, wi_uinteger_t length) {
	_WI_DIGEST_ASSERT_OPEN(sha256);
	
	_wi_sha256_ctx_update(&sha256->ctx, data, length);
}



void wi_sha256_close(wi_sha256_t *sha256) {
	_WI_DIGEST_ASSERT_OPEN(sha256);
	
	_wi_sha256_ctx_final(sha256->buffer, &sha256->ctx);
	
	sha256->closed = true;
}



#pragma mark -

void wi_sha256_get_data(wi_sha256_t *sha256, unsigned char *buffer) {
	_WI_DIGEST_ASSERT_CLOSED(sha256);
	
	memcpy(buffer, sha256->buffer, sizeof(sha256->buffer));
}



wi_data_t * wi_sha256_data(wi_sha256_t *sha256) {
	_WI_DIGEST_ASSERT_CLOSED(sha256);
	
	return wi_data_with_bytes(sha256->buffer, sizeof(sha256->buffer));
}



wi_string_t * wi_sha256_string(wi_sha256_t *sha256) {
	static unsigned char	hex[] = "0123456789abcdef";
	char					sha256_hex[sizeof(sha256->buffer) * 2 + 1];
	wi_uinteger_t			i;

	_WI_DIGEST_ASSERT_CLOSED(sha256);
	
	for(i = 0; i < sizeof(sha256->buffer); i++) {
		sha256_hex[i+i]	= hex[sha256->buffer[i] >> 4];
		sha256_hex[i+i+1] = hex[sha256->buffer[i] & 0x0F];
	}

	sha256_hex[i+i] = '\0';

	return wi_string_with_cstring(sha256_hex);
}


#endif



#pragma mark -

wi_string_t * wi_base64_string_from_data(wi_data_t *data) {
	static char				base64_table[] =
		"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
	wi_mutable_string_t		*base64;
	const unsigned char		*bytes;
	unsigned char			inbuffer[3], outbuffer[4];
	wi_uinteger_t			i, length, count, position, remaining;
	size_t					size;

	position		= 0;
	length			= wi_data_length(data);
	size			= (length * (4.0 / 3.0)) + 3;
	bytes			= wi_data_bytes(data);
	base64			= wi_string_init_with_capacity(wi_mutable_string_alloc(), size);
	
	while(position < length) {
		for(i = 0; i < 3; i++) {
			if(position + i < length)
				inbuffer[i] = bytes[position + i];
			else
				inbuffer[i] = '\0';
		}

		outbuffer[0] =  (inbuffer[0] & 0xFC) >> 2;
		outbuffer[1] = ((inbuffer[0] & 0x03) << 4) | ((inbuffer[1] & 0xF0) >> 4);
		outbuffer[2] = ((inbuffer[1] & 0x0F) << 2) | ((inbuffer[2] & 0xC0) >> 6);
		outbuffer[3] =   inbuffer[2] & 0x3F;

		remaining = length - position;
		
		if(remaining == 1)
			count = 2;
		else if(remaining == 2)
			count = 3;
		else
			count = 4;

		for(i = 0; i < count; i++)
			wi_mutable_string_append_bytes(base64, &base64_table[outbuffer[i]], 1);

		for(i = count; i < 4; i++)
			wi_mutable_string_append_bytes(base64, "=", 1);

		position += 3;
	}
	
	wi_runtime_make_immutable(base64);
	
	return wi_autorelease(base64);
}



wi_data_t * wi_data_from_base64_string(wi_string_t *string) {
	wi_mutable_data_t	*data;
	const char			*buffer;
	char				ch, inbuffer[4], outbuffer[3];
	wi_uinteger_t		length, count, i, position, offset;
	wi_boolean_t		ignore, stop, end;
	
	length			= wi_string_length(string);
	buffer			= wi_string_cstring(string);
	position		= 0;
	offset			= 0;
	data			= wi_data_init_with_capacity(wi_mutable_data_alloc(), length);
	
	while(position < length) {
		ignore = end = false;
		ch = buffer[position++];
		
		if(ch >= 'A' && ch <= 'Z')
			ch = ch - 'A';
		else if(ch >= 'a' && ch <= 'z')
			ch = ch - 'a' + 26;
		else if(ch >= '0' && ch <= '9')
			ch = ch - '0' + 52;
		else if(ch == '+')
			ch = 62;
		else if(ch == '=')
			end = true;
		else if(ch == '/')
			ch = 63;
		else
			ignore = true;
		
		if(!ignore) {
			count = 3;
			stop = false;
			
			if(end) {
				if(offset == 0)
					break;
				else if(offset == 1 || offset == 2)
					count = 1;
				else
					count = 2;
				
				offset = 3;
				stop = true;
			}
			
			inbuffer[offset++] = ch;
			
			if(offset == 4) {
				outbuffer[0] =  (inbuffer[0]         << 2) | ((inbuffer[1] & 0x30) >> 4);
				outbuffer[1] = ((inbuffer[1] & 0x0F) << 4) | ((inbuffer[2] & 0x3C) >> 2);
				outbuffer[2] = ((inbuffer[2] & 0x03) << 6) |  (inbuffer[3] & 0x3F);
				
				for(i = 0; i < count; i++)
					wi_mutable_data_append_bytes(data, &outbuffer[i], 1);

				offset = 0;
			}
			
			if(stop)
				break;
		}
	}
	
	wi_runtime_make_immutable(data);
	
	return wi_autorelease(data);
}
