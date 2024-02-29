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

#ifndef WI_RSA_H
#define WI_RSA_H 1

#include <wired/wi-base.h>
#include <wired/wi-data.h>
#include <wired/wi-runtime.h>

typedef struct _wi_rsa					wi_rsa_t;


WI_EXPORT wi_runtime_id_t				wi_rsa_runtime_id(void);

WI_EXPORT wi_rsa_t *					wi_rsa_alloc(void);
WI_EXPORT wi_rsa_t *					wi_rsa_init_with_bits(wi_rsa_t *, wi_uinteger_t);
WI_EXPORT wi_rsa_t *					wi_rsa_init_with_rsa(wi_rsa_t *, void *);
WI_EXPORT wi_rsa_t *					wi_rsa_init_with_pem_file(wi_rsa_t *, wi_string_t *);
WI_EXPORT wi_rsa_t *					wi_rsa_init_with_private_key(wi_rsa_t *, wi_data_t *);
WI_EXPORT wi_rsa_t *					wi_rsa_init_with_public_key(wi_rsa_t *, wi_data_t *);

WI_EXPORT void *						wi_rsa_rsa(wi_rsa_t *);
WI_EXPORT wi_data_t *					wi_rsa_public_key(wi_rsa_t *);
WI_EXPORT wi_data_t *					wi_rsa_private_key(wi_rsa_t *);
WI_EXPORT wi_uinteger_t					wi_rsa_bits(wi_rsa_t *);

WI_EXPORT wi_data_t *					wi_rsa_encrypt(wi_rsa_t *, wi_data_t *);
WI_EXPORT wi_boolean_t					wi_rsa_encrypt_bytes(wi_rsa_t *, const void *, wi_uinteger_t, void **, wi_uinteger_t *);
WI_EXPORT wi_data_t *					wi_rsa_decrypt(wi_rsa_t *, wi_data_t *);
WI_EXPORT wi_boolean_t					wi_rsa_decrypt_bytes(wi_rsa_t *, const void *, wi_uinteger_t, void **, wi_uinteger_t *);

#endif /* WI_RSA_H */
