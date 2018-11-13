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

#ifndef HAVE_OPENSSL_SHA_H

int wi_rsa_dummy = 0;

#else

#include <wired/wi-data.h>
#include <wired/wi-private.h>
#include <wired/wi-rsa.h>
#include <wired/wi-string.h>
#include <wired/wi-system.h>

#include <openssl/pem.h>
#include <openssl/rand.h>
#include <openssl/rsa.h>

struct _wi_rsa {
	wi_runtime_base_t					base;
	
	RSA									*rsa;
	wi_data_t							*public_key;
	wi_data_t							*private_key;
};

static void								_wi_rsa_dealloc(wi_runtime_instance_t *);
static wi_runtime_instance_t *			_wi_rsa_copy(wi_runtime_instance_t *);
static wi_string_t *					_wi_rsa_description(wi_runtime_instance_t *);

static wi_runtime_id_t					_wi_rsa_runtime_id = WI_RUNTIME_ID_NULL;
static wi_runtime_class_t				_wi_rsa_runtime_class = {
	"wi_rsa_t",
	_wi_rsa_dealloc,
	_wi_rsa_copy,
	NULL,
	_wi_rsa_description,
	NULL
};



void wi_rsa_register(void) {
	_wi_rsa_runtime_id = wi_runtime_register_class(&_wi_rsa_runtime_class);
}



void wi_rsa_initialize(void) {
}



#pragma mark -

wi_runtime_id_t wi_rsa_runtime_id(void) {
	return _wi_rsa_runtime_id;
}



#pragma mark -

wi_rsa_t * wi_rsa_alloc(void) {
	return wi_runtime_create_instance(_wi_rsa_runtime_id, sizeof(wi_rsa_t));
}



wi_rsa_t * wi_rsa_init_with_bits(wi_rsa_t *rsa, wi_uinteger_t size) {
	rsa->rsa = RSA_generate_key((int)size, RSA_F4, NULL, NULL);
	if(!rsa->rsa) {
		wi_release(rsa);
		
		return NULL;
	}
	
	return rsa;
}



wi_rsa_t * wi_rsa_init_with_rsa(wi_rsa_t *rsa, void *_rsa) {
	rsa->rsa = _rsa;
	
	return rsa;
}



wi_rsa_t * wi_rsa_init_with_pem_file(wi_rsa_t *rsa, wi_string_t *path) {
	FILE		*fp;
	
	fp = fopen(wi_string_cstring(path), "r");
	
	if(!fp) {
		wi_error_set_errno(errno);
		
		wi_release(rsa);
		
		return NULL;
	}
	
	rsa->rsa = PEM_read_RSAPrivateKey(fp, NULL, NULL, NULL);
	
	fclose(fp);
	
	if(!rsa->rsa) {
		wi_error_set_openssl_error();
		
		wi_release(rsa);
		
		return NULL;
	}
	
	return rsa;
}



wi_rsa_t * wi_rsa_init_with_private_key(wi_rsa_t *rsa, wi_data_t *data) {
	const unsigned char	*buffer;
	long				length;
	
	buffer = wi_data_bytes(data);
	length = wi_data_length(data);
	
	rsa->rsa = d2i_RSAPrivateKey(NULL, &buffer, length);

	if(!rsa->rsa) {
		wi_error_set_openssl_error();
		
		wi_release(rsa);
		
		return NULL;
	}
	
	rsa->private_key = wi_retain(data);
	
	return rsa;
}



wi_rsa_t * wi_rsa_init_with_public_key(wi_rsa_t *rsa, wi_data_t *data) {
	const unsigned char	*buffer;
	long				length;
	
	buffer = wi_data_bytes(data);
	length = wi_data_length(data);
	
	rsa->rsa = d2i_RSAPublicKey(NULL, (const unsigned char **) &buffer, length);

	if(!rsa->rsa) {
		wi_error_set_openssl_error();
		
		wi_release(rsa);
		
		return NULL;
	}
	
	rsa->public_key = wi_retain(data);
	
	return rsa;
}



static void _wi_rsa_dealloc(wi_runtime_instance_t *instance) {
	wi_rsa_t		*rsa = instance;
	
	RSA_free(rsa->rsa);
	
	wi_release(rsa->public_key);
	wi_release(rsa->private_key);
}



static wi_runtime_instance_t * _wi_rsa_copy(wi_runtime_instance_t *instance) {
	wi_rsa_t		*rsa = instance;
	
	return wi_rsa_init_with_private_key(wi_rsa_alloc(), wi_rsa_private_key(rsa));
}



static wi_string_t * _wi_rsa_description(wi_runtime_instance_t *instance) {
	wi_rsa_t		*rsa = instance;
	
	return wi_string_with_format(WI_STR("<%@ %p>{key = %p, bits = %lu}"),
        wi_runtime_class_name(rsa),
		rsa,
		rsa->rsa,
		wi_rsa_bits(rsa));
}



#pragma mark -

void * wi_rsa_rsa(wi_rsa_t *rsa) {
	return rsa->rsa;
}



wi_data_t * wi_rsa_public_key(wi_rsa_t *rsa) {
	unsigned char	*buffer;
	int				length;

	if(!rsa->public_key) {
		buffer = NULL;
		length = i2d_RSAPublicKey(rsa->rsa, &buffer);
		
		if(length <= 0) {
			wi_error_set_openssl_error();
			
			return NULL;
		}
		
		rsa->public_key = wi_data_init_with_bytes(wi_data_alloc(), buffer, length);

		OPENSSL_free(buffer);
	}
	
	return rsa->public_key;
}



wi_data_t * wi_rsa_private_key(wi_rsa_t *rsa) {
	unsigned char	*buffer;
	int				length;

	if(!rsa->private_key) {
		buffer = NULL;
		length = i2d_RSAPrivateKey(rsa->rsa, &buffer);
		
		if(length <= 0) {
			wi_error_set_openssl_error();
			
			return NULL;
		}
		
		rsa->private_key = wi_data_init_with_bytes(wi_data_alloc(), buffer, length);

		OPENSSL_free(buffer);
	}
	
	return rsa->private_key;
}



wi_uinteger_t wi_rsa_bits(wi_rsa_t *rsa) {
	return RSA_size(rsa->rsa) * 8;
}



#pragma mark -

wi_data_t * wi_rsa_encrypt(wi_rsa_t *rsa, wi_data_t *decrypted_data) {
	const void		*decrypted_buffer;
	void			*encrypted_buffer;
	wi_uinteger_t	decrypted_length, encrypted_length;
	
	decrypted_buffer = wi_data_bytes(decrypted_data);
	decrypted_length = wi_data_length(decrypted_data);
	
	if(!wi_rsa_encrypt_bytes(rsa, decrypted_buffer, decrypted_length, &encrypted_buffer, &encrypted_length))
		return NULL;
	
	return wi_data_with_bytes_no_copy(encrypted_buffer, encrypted_length, true);
}



wi_boolean_t wi_rsa_encrypt_bytes(wi_rsa_t *rsa, const void *decrypted_buffer, wi_uinteger_t decrypted_length, void **out_buffer, wi_uinteger_t *out_length) {
	void		*encrypted_buffer;
	int32_t		encrypted_length;

	encrypted_buffer = wi_malloc(RSA_size(rsa->rsa));
	encrypted_length = RSA_public_encrypt((int)decrypted_length, decrypted_buffer, encrypted_buffer, rsa->rsa, RSA_PKCS1_OAEP_PADDING);
	
	if(encrypted_length == -1) {
		wi_error_set_openssl_error();
		
		wi_free(encrypted_buffer);
		
		return false;
	}
	
	*out_buffer = encrypted_buffer;
	*out_length = encrypted_length;

	return true;
}



wi_data_t * wi_rsa_decrypt(wi_rsa_t *rsa, wi_data_t *encrypted_data) {
	const void		*encrypted_buffer;
	void			*decrypted_buffer;
	wi_uinteger_t	encrypted_length, decrypted_length;
	
	encrypted_buffer = wi_data_bytes(encrypted_data);
	encrypted_length = wi_data_length(encrypted_data);
	
	if(!wi_rsa_decrypt_bytes(rsa, encrypted_buffer, encrypted_length, &decrypted_buffer, &decrypted_length))
		return NULL;
	
	return wi_data_with_bytes_no_copy(decrypted_buffer, decrypted_length, true);
}



wi_boolean_t wi_rsa_decrypt_bytes(wi_rsa_t *rsa, const void *encrypted_buffer, wi_uinteger_t encrypted_length, void **out_buffer, wi_uinteger_t *out_length) {
	void		*decrypted_buffer;
	int32_t		decrypted_length;
	
	decrypted_buffer = wi_malloc(RSA_size(rsa->rsa));
	decrypted_length = RSA_private_decrypt(encrypted_length, encrypted_buffer, decrypted_buffer, rsa->rsa, RSA_PKCS1_OAEP_PADDING);

	if(decrypted_length == -1) {
		wi_error_set_openssl_error();
		
		wi_free(decrypted_buffer);

		return false;
	}
	
	*out_buffer = decrypted_buffer;
	*out_length = decrypted_length;

	return true;
}

#endif
