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

#ifndef HAVE_OPENSSL_SHA_H

int wi_x509_dummy = 0;

#else

#include <wired/wi-data.h>
#include <wired/wi-private.h>
#include <wired/wi-string.h>
#include <wired/wi-system.h>
#include <wired/wi-x509.h>

#include <openssl/pem.h>
#include <openssl/rand.h>
#include <openssl/rsa.h>
#include <openssl/x509.h>

struct _wi_x509 {
	wi_runtime_base_t					base;
	
	X509								*x509;
};

static void								_wi_x509_dealloc(wi_runtime_instance_t *);
static wi_string_t *					_wi_x509_description(wi_runtime_instance_t *);

static wi_runtime_id_t					_wi_x509_runtime_id = WI_RUNTIME_ID_NULL;
static wi_runtime_class_t				_wi_x509_runtime_class = {
	"wi_x509_t",
	_wi_x509_dealloc,
	NULL,
	NULL,
	_wi_x509_description,
	NULL
};



void wi_x509_register(void) {
	_wi_x509_runtime_id = wi_runtime_register_class(&_wi_x509_runtime_class);
}



void wi_x509_initialize(void) {
}



#pragma mark -

wi_runtime_id_t wi_x509_runtime_id(void) {
	return _wi_x509_runtime_id;
}



#pragma mark -

wi_x509_t * wi_x509_alloc(void) {
	return wi_runtime_create_instance_with_options(_wi_x509_runtime_id, sizeof(wi_x509_t), WI_RUNTIME_OPTION_IMMUTABLE);
}



wi_x509_t * wi_x509_init_with_common_name(wi_x509_t *x509, wi_rsa_t *rsa, wi_string_t *common_name) {
	X509_REQ		*req;
	EVP_PKEY		*pkey = NULL;
	X509_NAME		*name = NULL;
	BIGNUM			*bn = NULL;
	
	req = X509_REQ_new();
	
	if(!req)
		goto err;

	if(X509_REQ_set_version(req, 0) != 1)
		goto err;
	
	name = X509_NAME_new();
	
	if(X509_NAME_add_entry_by_NID(name,
								  NID_commonName,
								  MBSTRING_ASC,
								  (unsigned char *) wi_string_cstring(common_name),
								  -1,
								  -1,
								  0) != 1)
		goto err;

	if(X509_REQ_set_subject_name(req, name) != 1)
		goto err;

	pkey = EVP_PKEY_new();
	EVP_PKEY_set1_RSA(pkey, wi_rsa_rsa(rsa));
	
	if(X509_REQ_set_pubkey(req, pkey) != 1)
		goto err;
	
	x509->x509 = X509_new();
	
	if(!x509->x509)
		goto err;
	
	bn = BN_new();
	
	if(!bn)
		goto err;
	
	if(BN_pseudo_rand(bn, 64, 0, 0) != 1)
		goto err;
	
	if(!BN_to_ASN1_INTEGER(bn, X509_get_serialNumber(x509->x509)))
		goto err;
	
	if(X509_set_issuer_name(x509->x509, X509_REQ_get_subject_name(req)) != 1)
		goto err;

	if(!X509_gmtime_adj(X509_get_notBefore(x509->x509), 0))
		goto err;

	if(!X509_gmtime_adj(X509_get_notAfter(x509->x509), 3600 * 24 * 365))
		goto err;

	if(X509_set_subject_name(x509->x509, X509_REQ_get_subject_name(req)) != 1)
		goto end;

	if(X509_set_pubkey(x509->x509, pkey) != 1)
		goto err;
	
	if(X509_sign(x509->x509, pkey, EVP_sha1()) == 0)
		goto err;
	
	goto end;
	
err:
	wi_error_set_openssl_error();

	wi_release(x509);

	x509 = NULL;
	
end:
	if(req)
		X509_REQ_free(req);
	
	if(pkey)
		EVP_PKEY_free(pkey);
	
	if(name)
		X509_NAME_free(name);

	if(bn)
		BN_free(bn);
	
	return x509;
}



wi_x509_t * wi_x509_init_with_pem_file(wi_x509_t *x509, wi_string_t *path) {
	FILE		*fp;
	
	fp = fopen(wi_string_cstring(path), "r");
	
	if(!fp) {
		wi_error_set_errno(errno);
		
		wi_release(x509);
		
		return NULL;
	}
	
	x509->x509 = PEM_read_X509(fp, NULL, NULL, NULL);
	
	fclose(fp);
	
	if(!x509->x509) {
		wi_error_set_openssl_error();
		
		wi_release(x509);
		
		return NULL;
	}
	
	return x509;
}



static void _wi_x509_dealloc(wi_runtime_instance_t *instance) {
	wi_x509_t		*x509 = instance;
	
	X509_free(x509->x509);
}



static wi_string_t * _wi_x509_description(wi_runtime_instance_t *instance) {
	wi_x509_t		*x509 = instance;
	
	return wi_string_with_format(WI_STR("<%@ %p>{x509 = %p}"),
        wi_runtime_class_name(x509),
		x509,
		x509->x509);
}



#pragma mark -

void * wi_x509_x509(wi_x509_t *x509) {
	return x509->x509;
}

#endif
