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

#ifndef WI_CIPHER_H
#define WI_CIPHER_H 1

#include <wired/wi-base.h>
#include <wired/wi-data.h>
#include <wired/wi-runtime.h>

enum _wi_cipher_type {
	WI_CIPHER_AES128,
	WI_CIPHER_AES192,
	WI_CIPHER_AES256,
	WI_CIPHER_BF128,
	WI_CIPHER_3DES192,
};
typedef enum _wi_cipher_type			wi_cipher_type_t;


typedef struct _wi_cipher				wi_cipher_t;


WI_EXPORT wi_runtime_id_t				wi_cipher_runtime_id(void);

WI_EXPORT wi_cipher_t *					wi_cipher_alloc(void);
WI_EXPORT wi_cipher_t *					wi_cipher_init_with_key(wi_cipher_t *, wi_cipher_type_t, wi_data_t *, wi_data_t *);
WI_EXPORT wi_cipher_t *					wi_cipher_init_with_random_key(wi_cipher_t *, wi_cipher_type_t);

WI_EXPORT wi_data_t *					wi_cipher_key(wi_cipher_t *);
WI_EXPORT wi_data_t *					wi_cipher_iv(wi_cipher_t *);
WI_EXPORT wi_cipher_type_t				wi_cipher_type(wi_cipher_t *);
WI_EXPORT wi_string_t *					wi_cipher_name(wi_cipher_t *);
WI_EXPORT wi_uinteger_t					wi_cipher_bits(wi_cipher_t *);
WI_EXPORT wi_uinteger_t					wi_cipher_block_size(wi_cipher_t *);

WI_EXPORT wi_data_t *					wi_cipher_encrypt(wi_cipher_t *, wi_data_t *);
WI_EXPORT wi_integer_t					wi_cipher_encrypt_bytes(wi_cipher_t *, const void *, wi_uinteger_t, void *);
WI_EXPORT wi_data_t *					wi_cipher_decrypt(wi_cipher_t *, wi_data_t *);
WI_EXPORT wi_integer_t					wi_cipher_decrypt_bytes(wi_cipher_t *, const void *, wi_uinteger_t, void *);

#endif /* WI_CIPHER_H */
